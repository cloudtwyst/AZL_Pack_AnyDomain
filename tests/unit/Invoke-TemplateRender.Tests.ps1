#Requires -Version 7.0
#Requires -Modules Pester

BeforeAll {
    $PackRoot = (Resolve-Path "$PSScriptRoot\..\..\").Path
    Import-Module "$PackRoot\solpack\solpack.psm1" -Force
}

Describe 'Invoke-TemplateRender' {

    BeforeAll {
        $script:map = [ordered]@{
            CUSTOMER_NAME = 'Acme Corp'
            SHORT_CODE    = 'acme'
            TENANT_ID     = '11111111-0000-0000-0000-000000000001'
        }
    }

    Context 'string rendering' {
        It 'replaces a single token' {
            InModuleScope solpack -Parameters @{ m = $script:map } {
                param($m)
                $result = Invoke-TemplateRender -Template 'Hello {{CUSTOMER_NAME}}' -SubstitutionMap $m
                $result | Should -Be 'Hello Acme Corp'
            }
        }

        It 'replaces multiple tokens' {
            InModuleScope solpack -Parameters @{ m = $script:map } {
                param($m)
                $result = Invoke-TemplateRender -Template '{{SHORT_CODE}} / {{TENANT_ID}}' -SubstitutionMap $m
                $result | Should -Be 'acme / 11111111-0000-0000-0000-000000000001'
            }
        }

        It 'leaves unknown tokens unchanged' {
            InModuleScope solpack -Parameters @{ m = $script:map } {
                param($m)
                $result = Invoke-TemplateRender -Template 'value: {{UNKNOWN_TOKEN}}' -SubstitutionMap $m
                $result | Should -Be 'value: {{UNKNOWN_TOKEN}}'
            }
        }

        It 'returns template unchanged when map is empty' {
            InModuleScope solpack -Parameters @{ m = $script:map } {
                param($m)
                $emptyMap = [ordered]@{}
                $result = Invoke-TemplateRender -Template 'no-tokens-here' -SubstitutionMap $emptyMap
                $result | Should -Be 'no-tokens-here'
            }
        }
    }

    Context 'file rendering' {
        It 'reads a template file and renders it' {
            InModuleScope solpack -Parameters @{ m = $script:map; td = $TestDrive } {
                param($m, $td)
                $tmplPath = Join-Path $td 'test.tmpl'
                'tenant: {{TENANT_ID}}' | Set-Content $tmplPath -Encoding utf8
                $result = Invoke-TemplateRender -TemplatePath $tmplPath -SubstitutionMap $m
                $result.Trim() | Should -Be 'tenant: 11111111-0000-0000-0000-000000000001'
            }
        }

        It 'throws when template file does not exist' {
            InModuleScope solpack -Parameters @{ m = $script:map; td = $TestDrive } {
                param($m, $td)
                { Invoke-TemplateRender -TemplatePath "$td\missing.tmpl" -SubstitutionMap $m } |
                    Should -Throw
            }
        }
    }

    Context 'file output and idempotency' {
        It 'writes output file and returns rendered content' {
            InModuleScope solpack -Parameters @{ m = $script:map; td = $TestDrive } {
                param($m, $td)
                $tmplPath = Join-Path $td 'out-test.tmpl'
                $outPath  = Join-Path $td 'out-test.txt'
                'hello {{SHORT_CODE}}' | Set-Content $tmplPath -Encoding utf8

                $result = Invoke-TemplateRender -TemplatePath $tmplPath -OutputPath $outPath -SubstitutionMap $m
                $result.Trim()  | Should -Be 'hello acme'
                $outPath        | Should -Exist
                (Get-Content $outPath -Raw).Trim() | Should -Be 'hello acme'
            }
        }

        It 'does not rewrite file when content is unchanged (idempotent)' {
            InModuleScope solpack -Parameters @{ m = $script:map; td = $TestDrive } {
                param($m, $td)
                $tmplPath = Join-Path $td 'idem.tmpl'
                $outPath  = Join-Path $td 'idem.txt'
                'idem-{{SHORT_CODE}}' | Set-Content $tmplPath -Encoding utf8

                # First render
                Invoke-TemplateRender -TemplatePath $tmplPath -OutputPath $outPath -SubstitutionMap $m | Out-Null
                $before = (Get-Item $outPath).LastWriteTime

                Start-Sleep -Milliseconds 50

                # Second render — should not touch the file
                Invoke-TemplateRender -TemplatePath $tmplPath -OutputPath $outPath -SubstitutionMap $m | Out-Null
                $after = (Get-Item $outPath).LastWriteTime

                $after | Should -Be $before
            }
        }
    }
}
