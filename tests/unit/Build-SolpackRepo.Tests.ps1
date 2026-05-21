#Requires -Version 7.0
#Requires -Modules Pester

BeforeAll {
    $PackRoot = (Resolve-Path "$PSScriptRoot\..\..\").Path
    Import-Module "$PackRoot\solpack\solpack.psm1" -Force
    $FixturesRoot = "$PackRoot\tests\fixtures"
}

Describe 'Build-SolpackRepo — minimal fixture' {

    BeforeAll {
        $RepoPath = Join-Path $TestDrive 'rendered-minimal'
        New-Item -ItemType Directory -Force -Path $RepoPath | Out-Null
        Build-SolpackRepo -ConfigPath "$FixturesRoot\minimal\customer-config.yaml" `
                          -RepoPath $RepoPath `
                          -PackRoot $PackRoot
    }

    It 'creates terraform/main.tf' {
        "$RepoPath\terraform\main.tf" | Should -Exist
    }

    It 'creates terraform/terraform.tfvars' {
        "$RepoPath\terraform\terraform.tfvars" | Should -Exist
    }

    It 'creates Definitions/globalSettings.jsonc' {
        "$RepoPath\Definitions\globalSettings.jsonc" | Should -Exist
    }

    It 'creates Definitions/policySetDefinitions/baseline-all-customers.jsonc' {
        "$RepoPath\Definitions\policySetDefinitions\baseline-all-customers.jsonc" | Should -Exist
    }

    It 'creates Definitions/policyAssignments/root-baseline.jsonc' {
        "$RepoPath\Definitions\policyAssignments\root-baseline.jsonc" | Should -Exist
    }

    It 'creates CLAUDE.md' {
        "$RepoPath\CLAUDE.md" | Should -Exist
    }

    It 'renders TENANT_ID into globalSettings.jsonc' {
        $content = Get-Content "$RepoPath\Definitions\globalSettings.jsonc" -Raw
        $content | Should -Match '10000000-0000-0000-0000-000000000001'
    }

    It 'renders tenant ID into workflow files' {
        $wfFiles = Get-ChildItem "$RepoPath\.github\workflows" -Filter '*.yml'
        $wfFiles.Count | Should -BeGreaterThan 0
        $content = Get-Content $wfFiles[0].FullName -Raw
        $content | Should -Match '10000000-0000-0000-0000-000000000001'
    }

    It 'does not leave unreplaced {{TOKENS}} in terraform/main.tf' {
        $content = Get-Content "$RepoPath\terraform\main.tf" -Raw
        $content | Should -Not -Match '\{\{[A-Z_]+\}\}'
    }

    It 'does not leave unreplaced {{TOKENS}} in globalSettings.jsonc' {
        $content = Get-Content "$RepoPath\Definitions\globalSettings.jsonc" -Raw
        $content | Should -Not -Match '\{\{[A-Z_]+\}\}'
    }
}

Describe 'Build-SolpackRepo — idempotency' {

    BeforeAll {
        $RepoPath = Join-Path $TestDrive 'rendered-idem'
        New-Item -ItemType Directory -Force -Path $RepoPath | Out-Null
        # First render
        Build-SolpackRepo -ConfigPath "$FixturesRoot\minimal\customer-config.yaml" `
                          -RepoPath $RepoPath `
                          -PackRoot $PackRoot

        # Capture write times
        $script:mtimes1 = Get-ChildItem $RepoPath -Recurse -File |
            Where-Object { $_.Extension -in '.tf', '.jsonc', '.md', '.yml' } |
            ForEach-Object { @{ Path = $_.FullName; Mtime = $_.LastWriteTimeUtc } }

        Start-Sleep -Milliseconds 100

        # Second render
        Build-SolpackRepo -ConfigPath "$FixturesRoot\minimal\customer-config.yaml" `
                          -RepoPath $RepoPath `
                          -PackRoot $PackRoot

        $script:mtimes2 = Get-ChildItem $RepoPath -Recurse -File |
            Where-Object { $_.Extension -in '.tf', '.jsonc', '.md', '.yml' } |
            ForEach-Object { @{ Path = $_.FullName; Mtime = $_.LastWriteTimeUtc } }
    }

    It 'second render rewrites 0 files' {
        $rewrites = $script:mtimes1 | Where-Object {
            $path = $_.Path
            $before = $_.Mtime
            $after = ($script:mtimes2 | Where-Object { $_.Path -eq $path } | Select-Object -First 1).Mtime
            $after -and $after -ne $before
        }
        $rewrites | Should -BeNullOrEmpty
    }
}

Describe 'Build-SolpackRepo — healthcare fixture' {

    BeforeAll {
        $RepoPath = Join-Path $TestDrive 'rendered-healthcare'
        New-Item -ItemType Directory -Force -Path $RepoPath | Out-Null
        Build-SolpackRepo -ConfigPath "$FixturesRoot\healthcare\customer-config.yaml" `
                          -RepoPath $RepoPath `
                          -PackRoot $PackRoot
    }

    It 'baseline initiative is present' {
        "$RepoPath\Definitions\policySetDefinitions\baseline-all-customers.jsonc" | Should -Exist
    }

    It 'healthcare industry initiative is present' {
        "$RepoPath\Definitions\policySetDefinitions\industry-healthcare.jsonc" | Should -Exist
    }
}
