function Build-SolpackRepo {
    <#
    .SYNOPSIS
        Renders all pack artifacts into an initialised customer platform repository.

    .DESCRIPTION
        Reads customer-config.yaml, then writes or updates:

          terraform/main.tf          Root module wiring all relevant sub-modules.
          terraform/terraform.tfvars Customer-specific variable values.
          Definitions/               EPAC policy definitions, initiatives, and
                                     rendered assignment templates.
          globalSettings.jsonc       EPAC pacEnvironments configuration.
          .github/workflows/         One workflow file per .tmpl in workflow-templates/.
          CLAUDE.md                  Re-rendered from docs-templates template.

        Idempotent: files are only written when content has changed, so re-running
        against an unchanged config produces no diff.

    .PARAMETER ConfigPath
        Path to the customer-config.yaml. Defaults to customer-config.yaml in the
        current directory.

    .PARAMETER RepoPath
        Root of the customer platform repo to render into.
        Defaults to the current directory.

    .PARAMETER PackRoot
        Root of the azure-solution-pack repo. Auto-detected when not specified.

    .EXAMPLE
        Build-SolpackRepo

        Renders into the current directory using customer-config.yaml.

    .EXAMPLE
        Build-SolpackRepo -ConfigPath ./customers/contoso/customer-config.yaml `
                          -RepoPath   ./customers/contoso/contoso-platform

        Renders a specific customer repo.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string] $ConfigPath = 'customer-config.yaml',

        [Parameter()]
        [string] $RepoPath = '.',

        [Parameter()]
        [string] $PackRoot
    )

    # 1. Validate and load config
    Write-Information "Loading $ConfigPath..." -InformationAction Continue
    $config = Test-SolpackConfig -Path $ConfigPath -PassThru
    if (-not $config) {
        Write-Error "Config validation failed. Fix errors before rendering."
        return
    }

    if (-not $PackRoot) {
        $PackRoot = Resolve-PackRoot -StartPath $PSScriptRoot
    }

    $subMap = Get-SubstitutionMap -Config $config

    $RepoPath = (Resolve-Path -LiteralPath $RepoPath).Path

    # 2. Render CLAUDE.md
    $claudeTmpl = Join-Path $PackRoot 'docs-templates\customer-claude.md.tmpl'
    if (Test-Path -LiteralPath $claudeTmpl) {
        Invoke-TemplateRender -TemplatePath $claudeTmpl `
                              -OutputPath "$RepoPath\CLAUDE.md" `
                              -SubstitutionMap $subMap | Out-Null
    }

    # 3. Render GitHub Actions workflow templates
    $wfTmplDir = Join-Path $PackRoot 'workflow-templates'
    $wfOutDir  = "$RepoPath\.github\workflows"
    New-Item -ItemType Directory -Force -Path $wfOutDir | Out-Null

    Get-ChildItem -Path $wfTmplDir -Filter '*.tmpl' -ErrorAction SilentlyContinue |
        ForEach-Object {
            $outName = $_.Name -replace '\.tmpl$', ''
            Invoke-TemplateRender -TemplatePath $_.FullName `
                                  -OutputPath "$wfOutDir\$outName" `
                                  -SubstitutionMap $subMap | Out-Null
        }

    # 4. Generate terraform/main.tf
    $tfMain = Build-TerraformMain -Config $config -SubstitutionMap $subMap
    $tfMainPath = "$RepoPath\terraform\main.tf"
    $existing = if (Test-Path $tfMainPath) { (Get-Content $tfMainPath -Raw -Encoding utf8).TrimEnd("`r","`n") } else { $null }
    if ($tfMain.TrimEnd("`r","`n") -ne $existing) {
        New-Item -ItemType Directory -Force "$RepoPath\terraform" | Out-Null
        Set-Content $tfMainPath -Value $tfMain -Encoding utf8
        Write-Verbose "  wrote terraform/main.tf"
    }

    # 5. Generate terraform/terraform.tfvars
    $tfVars = Build-TerraformTfvars -Config $config
    $tfVarsPath = "$RepoPath\terraform\terraform.tfvars"
    $existing = if (Test-Path $tfVarsPath) { (Get-Content $tfVarsPath -Raw -Encoding utf8).TrimEnd("`r","`n") } else { $null }
    if ($tfVars.TrimEnd("`r","`n") -ne $existing) {
        Set-Content $tfVarsPath -Value $tfVars -Encoding utf8
        Write-Verbose "  wrote terraform/terraform.tfvars"
    }

    # 6. Generate globalSettings.jsonc (EPAC)
    $gs = Build-EpacGlobalSettings -Config $config -SubstitutionMap $subMap
    $gsPath = "$RepoPath\Definitions\globalSettings.jsonc"
    New-Item -ItemType Directory -Force "$RepoPath\Definitions" | Out-Null
    $existing = if (Test-Path $gsPath) { (Get-Content $gsPath -Raw -Encoding utf8).TrimEnd("`r","`n") } else { $null }
    if ($gs.TrimEnd("`r","`n") -ne $existing) {
        Set-Content $gsPath -Value $gs -Encoding utf8
        Write-Verbose "  wrote Definitions/globalSettings.jsonc"
    }

    # 7. Copy policy definitions + render assignment templates
    Copy-PolicyDefinitions -Config $config `
                           -PackRoot $PackRoot `
                           -DefinitionsPath "$RepoPath\Definitions" `
                           -SubstitutionMap $subMap

    # 8. Lifecycle artifacts (CODEOWNERS + issue templates)
    if ($config['lifecycle']['enableServiceRequestFlow']) {
        Build-LifecycleArtifacts -Config $config `
                                 -PackRoot $PackRoot `
                                 -RepoPath $RepoPath `
                                 -SubstitutionMap $subMap
    }

    Write-Information "Render complete: $RepoPath" -InformationAction Continue
}

function Build-LifecycleArtifacts {
    param(
        [hashtable] $Config,
        [string] $PackRoot,
        [string] $RepoPath,
        [System.Collections.Specialized.OrderedDictionary] $SubstitutionMap
    )

    $reviewers = $Config['lifecycle']['infosecReviewers'] ?? @()

    # CODEOWNERS
    $coPath = "$RepoPath\CODEOWNERS"
    $coLines = [System.Collections.Generic.List[string]]::new()
    $coLines.Add('# CODEOWNERS — managed by solpack render.')
    $coLines.Add("# Re-run 'solpack render' to regenerate from customer-config.yaml.")
    $coLines.Add('')
    foreach ($rev in $reviewers) {
        $coLines.Add("Definitions/  $rev")
        $coLines.Add("handover/      $rev")
    }
    $coContent = $coLines -join "`n"
    $existing = if (Test-Path $coPath) { (Get-Content $coPath -Raw -Encoding utf8).TrimEnd("`r","`n") } else { $null }
    if ($coContent.TrimEnd("`r","`n") -ne $existing) {
        Set-Content $coPath -Value $coContent -Encoding utf8
        Write-Verbose "  wrote CODEOWNERS"
    }

    # GitHub issue templates
    $issueTmplDir = "$RepoPath\.github\ISSUE_TEMPLATE"
    New-Item -ItemType Directory -Force -Path $issueTmplDir | Out-Null

    $docsTmplDir = Join-Path $PackRoot 'docs-templates'
    foreach ($issueTmpl in @('service-request-issue.md.tmpl', 'policy-proposal-issue.md.tmpl')) {
        $srcPath = Join-Path $docsTmplDir $issueTmpl
        if (-not (Test-Path -LiteralPath $srcPath)) { continue }
        $outName = $issueTmpl -replace '\.tmpl$', ''
        Invoke-TemplateRender -TemplatePath $srcPath `
                              -OutputPath "$issueTmplDir\$outName" `
                              -SubstitutionMap $SubstitutionMap | Out-Null
    }
}

# ── Private helpers (build-time; not exported) ─────────────────────────────

function Build-TerraformMain {
    param([hashtable]$Config, [System.Collections.Specialized.OrderedDictionary]$SubstitutionMap)

    $c  = $Config['customer']
    $az = $Config['azure']
    $m  = $Config['monitoring']
    $prefix  = $c['shortCode']
    $region  = $az['regions']['primary']
    $layout  = $az['managementGroups']['layout']
    $ehEnabled = ($m['eventHub']['enabled']).ToString().ToLower()
    $ehMaxTU   = ($m['eventHub']['maxThroughputUnits'] ?? 10).ToString()
    $siem      = $m['siem']

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('terraform {')
    $lines.Add('  required_version = ">= 1.6.0"')
    $lines.Add('  required_providers {')
    $lines.Add('    azurerm = { source = "hashicorp/azurerm" version = "~> 4.0" }')
    $lines.Add('    azuread = { source = "hashicorp/azuread" version = "~> 2.50" }')
    $lines.Add('  }')
    $lines.Add('  backend "azurerm" {')
    $lines.Add("    resource_group_name  = `"$prefix-rg-tfstate`"")
    $lines.Add("    storage_account_name = `"$($prefix)tfstate`"")
    $lines.Add('    container_name       = "tfstate"')
    $lines.Add('    key                  = "foundation.tfstate"')
    $lines.Add('  }')
    $lines.Add('}')
    $lines.Add('')
    $lines.Add('provider "azurerm" { features {} }')
    $lines.Add('provider "azuread" {}')
    $lines.Add('')

    # management-groups
    $lines.Add('module "management_groups" {')
    $lines.Add('  source      = "../terraform-modules/management-groups"')
    $lines.Add("  root_prefix = `"$prefix`"")
    $lines.Add("  layout      = `"$layout`"")
    $lines.Add('}')
    $lines.Add('')

    # monitoring-backbone
    $lines.Add('resource "azurerm_resource_group" "monitoring" {')
    $lines.Add("  name     = `"$prefix-rg-monitoring`"")
    $lines.Add("  location = `"$region`"")
    $lines.Add('}')
    $lines.Add('')
    $lines.Add('module "monitoring_backbone" {')
    $lines.Add('  source              = "../terraform-modules/monitoring-backbone"')
    $lines.Add("  prefix              = `"$prefix`"")
    $lines.Add("  location            = `"$region`"")
    $lines.Add('  resource_group_name = azurerm_resource_group.monitoring.name')
    $lines.Add("  event_hub_enabled   = $ehEnabled")
    $lines.Add("  event_hub_max_throughput_units = $ehMaxTU")
    $lines.Add('}')
    $lines.Add('')

    # service-principals
    $lines.Add('module "service_principals" {')
    $lines.Add('  source                   = "../terraform-modules/service-principals"')
    $lines.Add("  prefix                   = `"$prefix`"")
    $lines.Add('  root_management_group_id = module.management_groups.root_management_group_id')
    $lines.Add("  github_org               = `"$($Config['deployment']['github']['org'])`"")
    $lines.Add("  github_repo              = `"$($Config['deployment']['github']['repoName'])`"")
    $lines.Add('}')
    $lines.Add('')

    # sentinel (conditional)
    if ($siem -eq 'sentinel') {
        $lines.Add('module "sentinel" {')
        $lines.Add('  source                       = "../terraform-modules/sentinel"')
        $lines.Add('  log_analytics_workspace_id   = module.monitoring_backbone.log_analytics_workspace_id')
        $lines.Add('}')
        $lines.Add('')
    }

    return $lines -join "`n"
}

function Build-TerraformTfvars {
    param([hashtable]$Config)

    $c  = $Config['customer']
    $az = $Config['azure']
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("# Auto-generated by solpack render. Do not edit manually.")
    $lines.Add("# Re-run 'solpack render' to regenerate from customer-config.yaml.")
    $lines.Add('')
    $lines.Add("customer_name   = `"$($c['name'])`"")
    $lines.Add("short_code      = `"$($c['shortCode'])`"")
    $lines.Add("tenant_id       = `"$($az['tenantId'])`"")
    $lines.Add("primary_region  = `"$($az['regions']['primary'])`"")
    return $lines -join "`n"
}

function Build-EpacGlobalSettings {
    param([hashtable]$Config, [System.Collections.Specialized.OrderedDictionary]$SubstitutionMap)

    $tenantId     = $Config['azure']['tenantId']
    $pacOwnerId   = $SubstitutionMap['PAC_OWNER_ID']
    $strategy     = $Config['policy']['desiredStateStrategy']
    $devMg        = $SubstitutionMap['EPAC_DEV_MG']
    $nonprodMg    = $SubstitutionMap['EPAC_NONPROD_MG']
    $prodMg       = $SubstitutionMap['EPAC_PROD_MG']

    $exclusions   = $Config['policy']['initiatives']['exclusions'] ?? @()
    $excludedJson = if ($exclusions.Count -gt 0) {
        $scopes = $exclusions | ForEach-Object { "                `"$($_['scope'])`"" }
        ",`n            `"excludedScopes`": [`n$($scopes -join ",`n")`n            ]"
    } else { '' }

    $lines = @(
        '{',
        '    "$schema": "https://raw.githubusercontent.com/Azure/enterprise-policy-as-code/main/Schemas/global-settings-schema.json",',
        "    `"pacOwnerId`": `"$pacOwnerId`",",
        '    "pacEnvironments": [',
        '        {',
        '            "pacSelector": "epac-dev",',
        '            "cloud": "AzureCloud",',
        "            `"tenantId`": `"$tenantId`",",
        "            `"deploymentRootScope`": `"/providers/Microsoft.Management/managementGroups/$devMg`",",
        '            "desiredState": {',
        '                "strategy": "ownedOnly",',
        '                "includeResourceGroups": false',
        '            }',
        '        },',
        '        {',
        '            "pacSelector": "epac-nonprod",',
        '            "cloud": "AzureCloud",',
        "            `"tenantId`": `"$tenantId`",",
        "            `"deploymentRootScope`": `"/providers/Microsoft.Management/managementGroups/$nonprodMg`",",
        '            "desiredState": {',
        "                `"strategy`": `"$strategy`",",
        '                "includeResourceGroups": false',
        "            }$excludedJson",
        '        },',
        '        {',
        '            "pacSelector": "epac-prod",',
        '            "cloud": "AzureCloud",',
        "            `"tenantId`": `"$tenantId`",",
        "            `"deploymentRootScope`": `"/providers/Microsoft.Management/managementGroups/$prodMg`",",
        '            "desiredState": {',
        "                `"strategy`": `"$strategy`",",
        '                "includeResourceGroups": true',
        "            }$excludedJson",
        '        }',
        '    ]',
        '}'
    )

    return $lines -join "`n"
}
