function Invoke-SolpackDeploy {
    <#
    .SYNOPSIS
        Orchestrates the phased deployment of a customer platform repo.

    .DESCRIPTION
        Runs deployment phases 0-8 in sequence (or a single specified phase).
        Phases map to the 2-4 week onboarding playbook:

          Phase 0  remote-state-bootstrap  (Terraform; local state only)
          Phase 1  management-groups       (Terraform)
          Phase 2  monitoring-backbone     (Terraform)
          Phase 3  EPAC scaffolding        (Deploy-PolicyPlan.ps1 on epac-dev)
          Phase 4  service-principals      (Terraform)
          Phase 5  GitHub workflows        (git push; wires CI/CD)
          Phase 6  DINE initiative         (Deploy-PolicyPlan.ps1 on epac-nonprod/prod)
          Phase 7  SIEM connection         (Manual verification step)
          Phase 8  Lifecycle docs          (solpack handover)

        This cmdlet is a thin orchestrator. It shells out to 'terraform' and
        EPAC's PowerShell scripts — it never reimplements their logic.

        Requires confirmation before running any phase against a non-epac-dev
        environment unless -Force is specified.

    .PARAMETER RepoPath
        Root of the rendered customer platform repo.
        Defaults to the current directory.

    .PARAMETER Phase
        Phase number (0-8) or 'all' to run all phases in sequence.
        Defaults to 'all'.

    .PARAMETER PacEnvironment
        EPAC environment selector used for EPAC phases (3, 6).
        Defaults to 'epac-dev'.

    .PARAMETER Force
        Skip confirmation prompts for non-dev environments.

    .PARAMETER WhatIf
        Show what would be deployed without making changes (passes -WhatIf
        to Terraform plan and EPAC's Build-DeploymentPlans.ps1 only; does
        not apply changes).

    .EXAMPLE
        Invoke-SolpackDeploy -Phase 0

        Bootstraps the Terraform remote state storage account.

    .EXAMPLE
        Invoke-SolpackDeploy -Phase 3 -PacEnvironment epac-dev

        Runs the EPAC policy scaffolding deploy on the dev environment.

    .EXAMPLE
        Invoke-SolpackDeploy -RepoPath ./contoso-platform -Phase all -Force

        Runs all phases non-interactively (use with caution).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)]
        [string] $RepoPath = '.',

        [Parameter()]
        [ValidateSet('0','1','2','3','4','5','6','7','8','all')]
        [string] $Phase = 'all',

        [Parameter()]
        [string] $PacEnvironment = 'epac-dev',

        [Parameter()]
        [switch] $Force
    )

    $RepoPath = (Resolve-Path -LiteralPath $RepoPath).Path
    $tfDir    = Join-Path $RepoPath 'terraform'

    $phases = if ($Phase -eq 'all') { 0..8 } else { [int]$Phase }

    # Non-dev environments require confirmation unless -Force
    $nonDevEnvs = @('epac-nonprod', 'epac-prod')
    $isNonDev   = $PacEnvironment -in $nonDevEnvs

    foreach ($p in $phases) {
        Write-Information "=== Phase $p ===" -InformationAction Continue

        switch ($p) {
            0 {
                # Bootstrap remote state — always runs with local state
                Invoke-TerraformPhase -WorkDir $tfDir `
                                      -Targets @('module.remote_state_bootstrap') `
                                      -UseLocalState `
                                      -WhatIf:$WhatIfPreference
            }
            1 {
                Invoke-TerraformPhase -WorkDir $tfDir `
                                      -Targets @('module.management_groups') `
                                      -WhatIf:$WhatIfPreference
            }
            2 {
                Invoke-TerraformPhase -WorkDir $tfDir `
                                      -Targets @('azurerm_resource_group.monitoring', 'module.monitoring_backbone') `
                                      -WhatIf:$WhatIfPreference
            }
            3 {
                # EPAC: build plan then deploy on epac-dev
                Invoke-EpacPhase -RepoPath $RepoPath `
                                  -PacEnvironment 'epac-dev' `
                                  -WhatIf:$WhatIfPreference
            }
            4 {
                Invoke-TerraformPhase -WorkDir $tfDir `
                                      -Targets @('module.service_principals') `
                                      -WhatIf:$WhatIfPreference
            }
            5 {
                Write-Information "Phase 5: Push the rendered workflows to GitHub to activate CI/CD." -InformationAction Continue
                Write-Information "         Run: git push origin main" -InformationAction Continue
            }
            6 {
                if ($isNonDev -and -not $Force) {
                    $msg = "Phase 6 will deploy the DINE initiative to '$PacEnvironment'. Confirm? [y/N]"
                    $answer = Read-Host $msg
                    if ($answer -notmatch '^[Yy]') {
                        Write-Information "Phase 6 skipped." -InformationAction Continue
                        continue
                    }
                }
                Invoke-EpacPhase -RepoPath $RepoPath `
                                  -PacEnvironment $PacEnvironment `
                                  -WhatIf:$WhatIfPreference
            }
            7 {
                Write-Information "Phase 7: Verify SIEM connection manually." -InformationAction Continue
                Write-Information "         Check Event Hub metrics in Azure Monitor." -InformationAction Continue
                Write-Information "         Confirm SIEM is receiving events before proceeding." -InformationAction Continue
            }
            8 {
                Write-Information "Phase 8: Generating handover bundle..." -InformationAction Continue
                Export-SolpackHandover -RepoPath $RepoPath
            }
        }
    }

    Write-Information "Deploy complete through phase(s): $Phase" -InformationAction Continue
}

function Invoke-TerraformPhase {
    param(
        [string]   $WorkDir,
        [string[]] $Targets,
        [switch]   $UseLocalState,
        [switch]   $WhatIf
    )

    if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
        Write-Error "terraform not found on PATH. Install Terraform >= 1.6.0."
        return
    }

    $initArgs = @('init', '-upgrade')
    if ($UseLocalState) { $initArgs += '-backend=false' }

    & terraform -chdir:$WorkDir @initArgs
    if ($LASTEXITCODE -ne 0) { Write-Error "terraform init failed."; return }

    $targetArgs = $Targets | ForEach-Object { "-target=$_" }

    if ($WhatIf) {
        & terraform -chdir:$WorkDir plan @targetArgs
    }
    else {
        & terraform -chdir:$WorkDir apply -auto-approve @targetArgs
        if ($LASTEXITCODE -ne 0) { Write-Error "terraform apply failed." }
    }
}

function Invoke-EpacPhase {
    param(
        [string] $RepoPath,
        [string] $PacEnvironment,
        [switch] $WhatIf
    )

    $buildScript = Join-Path $RepoPath 'Build-DeploymentPlans.ps1'
    if (-not (Test-Path -LiteralPath $buildScript)) {
        # Try EPAC module if installed
        if (-not (Get-Command Build-DeploymentPlans -ErrorAction SilentlyContinue)) {
            Write-Error "EPAC not found. Run: Install-Module EnterprisePolicyAsCode"
            return
        }
        & Build-DeploymentPlans -PacEnvironmentSelector $PacEnvironment -OutputFolder "$RepoPath\Output"
    }
    else {
        & $buildScript -PacEnvironmentSelector $PacEnvironment -OutputFolder "$RepoPath\Output"
    }

    if ($WhatIf) {
        Write-Information "WhatIf: skipping Deploy-PolicyPlan.ps1" -InformationAction Continue
        return
    }

    $deployScript = Join-Path $RepoPath 'Deploy-PolicyPlan.ps1'
    if (Test-Path -LiteralPath $deployScript) {
        & $deployScript -PacEnvironmentSelector $PacEnvironment -InputFolder "$RepoPath\Output"
    }
    elseif (Get-Command Deploy-PolicyPlan -ErrorAction SilentlyContinue) {
        & Deploy-PolicyPlan -PacEnvironmentSelector $PacEnvironment -InputFolder "$RepoPath\Output"
    }
    else {
        Write-Error "EPAC Deploy-PolicyPlan not found."
    }
}
