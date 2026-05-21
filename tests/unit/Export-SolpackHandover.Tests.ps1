#Requires -Version 7.0
#Requires -Modules Pester

BeforeAll {
    $PackRoot = (Resolve-Path "$PSScriptRoot\..\..\").Path
    Import-Module "$PackRoot\solpack\solpack.psm1" -Force
    $FixturesRoot = "$PackRoot\tests\fixtures"
}

Describe 'Export-SolpackHandover — minimal fixture' {

    BeforeAll {
        $RepoPath  = Join-Path $TestDrive 'handover-minimal-repo'
        $OutPath   = Join-Path $TestDrive 'handover-minimal-out'
        New-Item -ItemType Directory -Force -Path $RepoPath | Out-Null

        Export-SolpackHandover -RepoPath $RepoPath `
                               -ConfigPath "$FixturesRoot\minimal\customer-config.yaml" `
                               -PackRoot $PackRoot `
                               -OutputPath $OutPath
    }

    It 'creates the output directory' {
        $OutPath | Should -Exist
    }

    It 'renders handover-runbook.md' {
        "$OutPath\handover-runbook.md" | Should -Exist
    }

    It 'renders approved-azure-services.md' {
        "$OutPath\approved-azure-services.md" | Should -Exist
    }

    It 'renders approved-patterns.md' {
        "$OutPath\approved-patterns.md" | Should -Exist
    }

    It 'renders controls-development-process.md' {
        "$OutPath\controls-development-process.md" | Should -Exist
    }

    It 'renders security-baseline-per-service.md' {
        "$OutPath\security-baseline-per-service.md" | Should -Exist
    }

    It 'renders service-request-issue.md' {
        "$OutPath\service-request-issue.md" | Should -Exist
    }

    It 'substitutes CUSTOMER_NAME into handover-runbook.md' {
        $content = Get-Content "$OutPath\handover-runbook.md" -Raw
        $content | Should -Match 'Fabrikam'
    }

    It 'substitutes TENANT_ID into handover-runbook.md' {
        $content = Get-Content "$OutPath\handover-runbook.md" -Raw
        $content | Should -Match '10000000-0000-0000-0000-000000000001'
    }

    It 'does not leave unreplaced {{TOKENS}} in any rendered file' {
        $renderedFiles = Get-ChildItem $OutPath -Filter '*.md'
        foreach ($f in $renderedFiles) {
            $content = Get-Content $f.FullName -Raw
            $content | Should -Not -Match '\{\{[A-Z_]+\}\}' -Because "$($f.Name) should have all tokens replaced"
        }
    }
}

Describe 'Export-SolpackHandover — healthcare fixture' {

    BeforeAll {
        $RepoPath = Join-Path $TestDrive 'handover-healthcare-repo'
        $OutPath  = Join-Path $TestDrive 'handover-healthcare-out'
        New-Item -ItemType Directory -Force -Path $RepoPath | Out-Null

        Export-SolpackHandover -RepoPath $RepoPath `
                               -ConfigPath "$FixturesRoot\healthcare\customer-config.yaml" `
                               -PackRoot $PackRoot `
                               -OutputPath $OutPath
    }

    It 'creates handover-runbook.md with correct customer name' {
        $content = Get-Content "$OutPath\handover-runbook.md" -Raw
        $content | Should -Match 'Contoso'
    }

    It 'security-baseline mentions the correct SIEM (splunk for healthcare fixture)' {
        $content = Get-Content "$OutPath\security-baseline-per-service.md" -Raw
        $content | Should -Match 'splunk'
    }
}

Describe 'Export-SolpackHandover — idempotency' {

    BeforeAll {
        $RepoPath = Join-Path $TestDrive 'handover-idem-repo'
        $OutPath  = Join-Path $TestDrive 'handover-idem-out'
        New-Item -ItemType Directory -Force -Path $RepoPath | Out-Null

        # First render
        Export-SolpackHandover -RepoPath $RepoPath `
                               -ConfigPath "$FixturesRoot\minimal\customer-config.yaml" `
                               -PackRoot $PackRoot `
                               -OutputPath $OutPath

        $script:mtimes1 = Get-ChildItem $OutPath -Filter '*.md' |
            ForEach-Object { @{ Path = $_.FullName; Mtime = $_.LastWriteTimeUtc } }

        Start-Sleep -Milliseconds 100

        # Second render
        Export-SolpackHandover -RepoPath $RepoPath `
                               -ConfigPath "$FixturesRoot\minimal\customer-config.yaml" `
                               -PackRoot $PackRoot `
                               -OutputPath $OutPath

        $script:mtimes2 = Get-ChildItem $OutPath -Filter '*.md' |
            ForEach-Object { @{ Path = $_.FullName; Mtime = $_.LastWriteTimeUtc } }
    }

    It 'second render rewrites 0 files' {
        $rewrites = $script:mtimes1 | Where-Object {
            $path   = $_.Path
            $before = $_.Mtime
            $after  = ($script:mtimes2 | Where-Object { $_.Path -eq $path } | Select-Object -First 1).Mtime
            $after -and $after -ne $before
        }
        $rewrites | Should -BeNullOrEmpty
    }
}
