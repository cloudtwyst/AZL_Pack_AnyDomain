function New-SolpackCustomer {
    <#
    .SYNOPSIS
        Initialises a new customer platform repository from a validated customer-config.yaml.

    .DESCRIPTION
        Creates the full customer repo skeleton at OutputPath:

            {OutputPath}/
            ├── customer-config.yaml     <- copied from ConfigPath
            ├── CLAUDE.md                <- rendered from docs-templates/customer-claude.md.tmpl
            ├── decisions.md             <- blank decisions log
            ├── terraform/               <- empty; populated by Build-SolpackRepo
            ├── Definitions/
            │   ├── policyDefinitions/
            │   ├── policySetDefinitions/
            │   └── policyAssignments/
            ├── .github/workflows/       <- empty; populated by Build-SolpackRepo
            └── handover/                <- empty; populated by Export-SolpackHandover

        Validates the config before creating anything. Initialises a git repo
        unless -SkipGitInit is specified.

    .PARAMETER ConfigPath
        Path to the customer-config.yaml file.
        Defaults to customer-config.yaml in the current directory.

    .PARAMETER OutputPath
        Directory where the customer repo will be created.
        Defaults to ./{shortCode}-platform in the current directory.

    .PARAMETER PackRoot
        Root of the azure-solution-pack repo. Auto-detected when not specified.

    .PARAMETER Force
        Overwrite OutputPath if it already exists.

    .PARAMETER SkipGitInit
        Do not run git init after creating the repo structure.

    .EXAMPLE
        New-SolpackCustomer -ConfigPath ./customer-config.yaml

        Initialises a customer repo at ./contoso-platform.

    .EXAMPLE
        New-SolpackCustomer -ConfigPath ./customer-config.yaml -OutputPath C:\repos\contoso -Force

        Initialises at a custom path, overwriting any existing content.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]
    param(
        [Parameter(Position = 0)]
        [string] $ConfigPath = 'customer-config.yaml',

        [Parameter()]
        [string] $OutputPath,

        [Parameter()]
        [string] $PackRoot,

        [Parameter()]
        [switch] $Force,

        [Parameter()]
        [switch] $SkipGitInit
    )

    # 1. Validate config
    Write-Information "Validating $ConfigPath..." -InformationAction Continue
    $config = Test-SolpackConfig -Path $ConfigPath -PassThru
    if (-not $config) {
        Write-Error "Config validation failed. Fix errors before running init."
        return $null
    }

    # 2. Resolve paths
    if (-not $PackRoot) {
        $PackRoot = Resolve-PackRoot -StartPath $PSScriptRoot
    }

    $shortCode = $config['customer']['shortCode']

    if (-not $OutputPath) {
        $OutputPath = Join-Path (Get-Location) "$shortCode-platform"
    }

    if ((Test-Path -LiteralPath $OutputPath) -and -not $Force) {
        Write-Error "OutputPath '$OutputPath' already exists. Use -Force to overwrite."
        return $null
    }

    if (-not $PSCmdlet.ShouldProcess($OutputPath, 'Create customer repo')) {
        return $null
    }

    # 3. Create directory structure
    $dirs = @(
        $OutputPath,
        "$OutputPath\terraform",
        "$OutputPath\Definitions\policyDefinitions",
        "$OutputPath\Definitions\policySetDefinitions",
        "$OutputPath\Definitions\policyAssignments",
        "$OutputPath\.github\workflows",
        "$OutputPath\handover",
        "$OutputPath\reference\diagrams"
    )
    foreach ($d in $dirs) {
        New-Item -ItemType Directory -Force -Path $d | Out-Null
    }

    # 4. Copy customer-config.yaml
    Copy-Item -LiteralPath $ConfigPath -Destination "$OutputPath\customer-config.yaml" -Force

    # 5. Build substitution map
    $subMap = Get-SubstitutionMap -Config $config

    # 6. Render CLAUDE.md from template (fallback if template missing)
    $claudeTmpl = Join-Path $PackRoot 'docs-templates\customer-claude.md.tmpl'
    if (Test-Path -LiteralPath $claudeTmpl) {
        Invoke-TemplateRender -TemplatePath $claudeTmpl `
                              -OutputPath "$OutputPath\CLAUDE.md" `
                              -SubstitutionMap $subMap | Out-Null
    }
    else {
        $fallback = "# CLAUDE.md`n`nCustomer: $($config['customer']['name'])`nSee SOLUTION-PACK.md for working agreement."
        Set-Content "$OutputPath\CLAUDE.md" -Value $fallback -Encoding utf8
    }

    # 7. decisions.md skeleton
    $decisionsPath = "$OutputPath\decisions.md"
    if (-not (Test-Path -LiteralPath $decisionsPath)) {
        $today  = Get-Date -Format 'yyyy-MM-dd'
        $name   = $config['customer']['name']
        $ver    = $subMap['PACK_VERSION']
        $lines  = @(
            "# Decisions - $name",
            '',
            'Open and closed decisions for this customer deployment.',
            'Format: ## D{N} -- {title} then Status, Date, Decision, Reason.',
            '',
            '---',
            '',
            '## D1 -- Pack version',
            '',
            '- **Status:** Closed',
            "- **Date:** $today",
            "- **Decision:** Pack version $ver used for initial deployment.",
            '- **Reason:** Current stable version at time of onboarding.'
        )
        $lines -join "`n" | Set-Content $decisionsPath -Encoding utf8
    }

    # 8. .gitignore
    $gitignoreLines = @(
        '.terraform/',
        '*.tfstate',
        '*.tfstate.backup',
        '.terraform.lock.hcl',
        '*.tfvars.json'
    )
    $gitignoreLines -join "`n" | Set-Content "$OutputPath\.gitignore" -Encoding utf8

    # 9. Git init
    if (-not $SkipGitInit) {
        $null = & git -C $OutputPath init 2>&1
        $null = & git -C $OutputPath add . 2>&1
        $null = & git -C $OutputPath commit -m "chore: solpack init -- $shortCode platform repo" 2>&1
    }

    Write-Information "Customer repo initialised at: $OutputPath" -InformationAction Continue
    return $OutputPath
}
