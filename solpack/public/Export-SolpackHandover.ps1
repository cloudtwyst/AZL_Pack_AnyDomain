function Export-SolpackHandover {
    <#
    .SYNOPSIS
        Generates the handover bundle for a customer from docs-templates.

    .DESCRIPTION
        Renders every .tmpl file under docs-templates/ into the customer repo's
        handover/ directory, substituting {{PLACEHOLDER}} tokens from the config.

        If pandoc is available on PATH it will also produce a single PDF from
        the concatenated Markdown files.

        The output bundle contains:
          handover/approved-azure-services.md
          handover/approved-patterns.md
          handover/controls-development-process.md
          handover/security-baseline-per-service.md
          handover/handover-runbook.md
          handover/handover-bundle.pdf    (only when pandoc is available)

    .PARAMETER RepoPath
        Root of the customer platform repo.
        Defaults to the current directory.

    .PARAMETER ConfigPath
        Path to customer-config.yaml. Defaults to customer-config.yaml inside RepoPath.

    .PARAMETER PackRoot
        Root of the azure-solution-pack repo. Auto-detected when not specified.

    .PARAMETER OutputPath
        Directory where rendered docs are written.
        Defaults to {RepoPath}/handover.

    .EXAMPLE
        Export-SolpackHandover

        Generates the handover bundle from the current directory's config.

    .EXAMPLE
        Export-SolpackHandover -RepoPath ./contoso-platform -OutputPath ./deliverables/contoso

        Renders into a custom output path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string] $RepoPath = '.',

        [Parameter()]
        [string] $ConfigPath,

        [Parameter()]
        [string] $PackRoot,

        [Parameter()]
        [string] $OutputPath
    )

    $RepoPath = (Resolve-Path -LiteralPath $RepoPath).Path

    if (-not $ConfigPath) {
        $ConfigPath = Join-Path $RepoPath 'customer-config.yaml'
    }

    if (-not $OutputPath) {
        $OutputPath = Join-Path $RepoPath 'handover'
    }

    if (-not $PackRoot) {
        $PackRoot = Resolve-PackRoot -StartPath $PSScriptRoot
    }

    # Load + validate config
    $config = Test-SolpackConfig -Path $ConfigPath -PassThru
    if (-not $config) {
        Write-Error "Config validation failed. Fix errors before generating handover."
        return
    }

    $subMap = Get-SubstitutionMap -Config $config

    New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null

    $docsTmplDir = Join-Path $PackRoot 'docs-templates'
    $tmplFiles   = Get-ChildItem -Path $docsTmplDir -Filter '*.tmpl' -ErrorAction SilentlyContinue |
                   Where-Object { $_.Name -notlike 'customer-claude*' }

    $renderedFiles = [System.Collections.Generic.List[string]]::new()

    foreach ($tmpl in $tmplFiles) {
        $outName = $tmpl.Name -replace '\.tmpl$', ''
        $outPath = Join-Path $OutputPath $outName
        Invoke-TemplateRender -TemplatePath $tmpl.FullName `
                              -OutputPath $outPath `
                              -SubstitutionMap $subMap | Out-Null
        $renderedFiles.Add($outPath)
        Write-Verbose "  rendered $outName"
    }

    # If no templates yet, generate a minimal runbook from config data
    if ($renderedFiles.Count -eq 0) {
        Write-Warning "No docs-templates/*.tmpl files found. Generating minimal runbook."
        $runbookPath = Join-Path $OutputPath 'handover-runbook.md'
        $name    = $config['customer']['name']
        $tenant  = $config['azure']['tenantId']
        $region  = $config['azure']['regions']['primary']
        $lines   = @(
            "# Handover Runbook",
            '',
            "**Customer:** $name",
            "**Tenant ID:** $tenant",
            "**Primary region:** $region",
            "**Generated:** $(Get-Date -Format 'yyyy-MM-dd')",
            '',
            '## Day-2 Operations',
            '',
            '### Updating policy assignments',
            '1. Clone the platform repo.',
            '2. Edit `Definitions/policyAssignments/`.',
            "3. Run `Build-DeploymentPlans.ps1 -PacEnvironmentSelector epac-dev`.",
            '4. Review the plan and raise a PR.',
            '5. Merge triggers the CI/CD pipeline.',
            '',
            '### Upgrading the solution pack',
            '1. Update `packVersion` in `customer-config.yaml`.',
            "2. Run `solpack render` to re-render all artifacts.",
            '3. Review the diff and raise a PR.',
            '',
            '### Terraform state',
            ('Storage account: ' + $config['customer']['shortCode'] + 'tfstate'),
            'Container: tfstate',
            'Key: foundation.tfstate'
        )
        $lines -join "`n" | Set-Content $runbookPath -Encoding utf8
        $renderedFiles.Add($runbookPath)
    }

    # Optional: combine into PDF via pandoc
    if (Get-Command pandoc -ErrorAction SilentlyContinue) {
        $mdFiles  = $renderedFiles | Where-Object { $_ -like '*.md' }
        $pdfPath  = Join-Path $OutputPath 'handover-bundle.pdf'
        $shortCode = $config['customer']['shortCode']
        & pandoc @mdFiles -o $pdfPath `
            --metadata "title=Handover Bundle - $shortCode" `
            --metadata "date=$(Get-Date -Format 'yyyy-MM-dd')" 2>&1 |
            ForEach-Object { Write-Verbose "pandoc: $_" }
        if ($LASTEXITCODE -eq 0) {
            Write-Information "PDF generated: $pdfPath" -InformationAction Continue
        }
        else {
            Write-Warning "pandoc exited with code $LASTEXITCODE — PDF not generated."
        }
    }
    else {
        Write-Verbose "pandoc not found — PDF generation skipped."
    }

    Write-Information "Handover bundle written to: $OutputPath" -InformationAction Continue
}
