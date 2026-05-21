#Requires -Version 7.0
#Requires -Modules Pester

BeforeAll {
    $PackRoot = (Resolve-Path "$PSScriptRoot\..\..\").Path
    Import-Module "$PackRoot\solpack\solpack.psm1" -Force
    $FixturesRoot = "$PackRoot\tests\fixtures"
}

Describe 'Get-SubstitutionMap' {

    BeforeAll {
        $minimalCfg = Test-SolpackConfig -Path "$FixturesRoot\minimal\customer-config.yaml" -PassThru
    }

    It 'returns an OrderedDictionary' {
        InModuleScope solpack -Parameters @{ cfg = $minimalCfg } {
            param($cfg)
            $map = Get-SubstitutionMap -Config $cfg
            $map | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        }
    }

    It 'contains CUSTOMER_NAME' {
        InModuleScope solpack -Parameters @{ cfg = $minimalCfg } {
            param($cfg)
            $map = Get-SubstitutionMap -Config $cfg
            $map['CUSTOMER_NAME'] | Should -Not -BeNullOrEmpty
        }
    }

    It 'SHORT_CODE matches CUSTOMER_SHORT_CODE' {
        InModuleScope solpack -Parameters @{ cfg = $minimalCfg } {
            param($cfg)
            $map = Get-SubstitutionMap -Config $cfg
            $map['SHORT_CODE'] | Should -Be $map['CUSTOMER_SHORT_CODE']
        }
    }

    It 'PAC_OWNER_ID is a valid GUID' {
        InModuleScope solpack -Parameters @{ cfg = $minimalCfg } {
            param($cfg)
            $map = Get-SubstitutionMap -Config $cfg
            $map['PAC_OWNER_ID'] | Should -Match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        }
    }

    It 'PAC_OWNER_ID is deterministic across calls' {
        InModuleScope solpack -Parameters @{ cfg = $minimalCfg } {
            param($cfg)
            $map1 = Get-SubstitutionMap -Config $cfg
            $map2 = Get-SubstitutionMap -Config $cfg
            $map2['PAC_OWNER_ID'] | Should -Be $map1['PAC_OWNER_ID']
        }
    }

    It 'EPAC_DEV_MG contains sandbox' {
        InModuleScope solpack -Parameters @{ cfg = $minimalCfg } {
            param($cfg)
            $map = Get-SubstitutionMap -Config $cfg
            $map['EPAC_DEV_MG'] | Should -Match 'sandbox'
        }
    }

    It 'EPAC_NONPROD_MG contains corp' {
        InModuleScope solpack -Parameters @{ cfg = $minimalCfg } {
            param($cfg)
            $map = Get-SubstitutionMap -Config $cfg
            $map['EPAC_NONPROD_MG'] | Should -Match 'corp'
        }
    }

    It 'EPAC_PROD_MG contains root' {
        InModuleScope solpack -Parameters @{ cfg = $minimalCfg } {
            param($cfg)
            $map = Get-SubstitutionMap -Config $cfg
            $map['EPAC_PROD_MG'] | Should -Match 'root'
        }
    }

    It 'RENDER_DATE matches yyyy-MM-dd' {
        InModuleScope solpack -Parameters @{ cfg = $minimalCfg } {
            param($cfg)
            $map = Get-SubstitutionMap -Config $cfg
            $map['RENDER_DATE'] | Should -Match '^\d{4}-\d{2}-\d{2}$'
        }
    }

    It 'PACK_VERSION is non-empty' {
        InModuleScope solpack -Parameters @{ cfg = $minimalCfg } {
            param($cfg)
            $map = Get-SubstitutionMap -Config $cfg
            $map['PACK_VERSION'] | Should -Not -BeNullOrEmpty
        }
    }

    It 'TENANT_ID is populated' {
        InModuleScope solpack -Parameters @{ cfg = $minimalCfg } {
            param($cfg)
            $map = Get-SubstitutionMap -Config $cfg
            $map['TENANT_ID'] | Should -Not -BeNullOrEmpty
        }
    }

    It 'GITHUB_ORG and GITHUB_REPO are populated' {
        InModuleScope solpack -Parameters @{ cfg = $minimalCfg } {
            param($cfg)
            $map = Get-SubstitutionMap -Config $cfg
            $map['GITHUB_ORG']  | Should -Not -BeNullOrEmpty
            $map['GITHUB_REPO'] | Should -Not -BeNullOrEmpty
        }
    }
}
