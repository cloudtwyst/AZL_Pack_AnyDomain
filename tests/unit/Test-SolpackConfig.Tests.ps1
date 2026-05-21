#Requires -Version 7.0
#Requires -Modules Pester

BeforeAll {
    $PackRoot = (Resolve-Path "$PSScriptRoot\..\..\").Path
    Import-Module "$PackRoot\solpack\solpack.psm1" -Force
    $FixturesRoot = "$PackRoot\tests\fixtures"
}

Describe 'Test-SolpackConfig' {

    Context 'minimal valid fixture' {
        It 'returns a non-null ordered dictionary with -PassThru' {
            $cfg = Test-SolpackConfig -Path "$FixturesRoot\minimal\customer-config.yaml" -PassThru
            $cfg | Should -Not -BeNullOrEmpty
            $cfg | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        }

        It 'contains required top-level keys' {
            $cfg = Test-SolpackConfig -Path "$FixturesRoot\minimal\customer-config.yaml" -PassThru
            $cfg.Keys | Should -Contain 'customer'
            $cfg.Keys | Should -Contain 'azure'
            $cfg.Keys | Should -Contain 'monitoring'
            $cfg.Keys | Should -Contain 'policy'
        }
    }

    Context 'healthcare fixture' {
        It 'passes validation' {
            $cfg = Test-SolpackConfig -Path "$FixturesRoot\healthcare\customer-config.yaml" -PassThru
            $cfg | Should -Not -BeNullOrEmpty
        }

        It 'has healthcare industry set' {
            $cfg = Test-SolpackConfig -Path "$FixturesRoot\healthcare\customer-config.yaml" -PassThru
            $cfg['customer']['industry'] | Should -Be 'healthcare'
        }
    }

    Context 'finance fixture' {
        It 'passes validation' {
            $cfg = Test-SolpackConfig -Path "$FixturesRoot\finance\customer-config.yaml" -PassThru
            $cfg | Should -Not -BeNullOrEmpty
        }
    }

    Context 'invalid configs' {
        BeforeAll {
            $tmpDir = New-Item -ItemType Directory -Force -Path "$TestDrive\invalid-configs"
        }

        It 'returns false for missing required field (tenantId)' {
            $bad = @'
schemaVersion: "1.0"
packVersion: ">=0.1.0,<1.0.0"
customer:
  name: "Bad Corp"
  shortCode: "bad"
  industry: "other"
  primaryContact: "bad@bad.com"
azure:
  managementSubscriptionId: "00000000-0000-0000-0000-000000000099"
  regions:
    primary: "westeurope"
  managementGroups:
    layout: "caf"
    rootPrefix: "bad"
'@
            $badPath = Join-Path $tmpDir 'missing-tenant.yaml'
            $bad | Set-Content $badPath -Encoding utf8
            $result = Test-SolpackConfig -Path $badPath -PassThru -ErrorAction SilentlyContinue
            $result | Should -BeFalse
        }

        It 'returns false for shortCode that is too long (>8 chars)' {
            $bad = @'
schemaVersion: "1.0"
packVersion: ">=0.1.0,<1.0.0"
customer:
  name: "Bad Corp"
  shortCode: "toolongshortcode"
  industry: "other"
  primaryContact: "bad@bad.com"
azure:
  tenantId: "00000000-0000-0000-0000-000000000001"
  managementSubscriptionId: "00000000-0000-0000-0000-000000000099"
  regions:
    primary: "westeurope"
  managementGroups:
    layout: "caf"
    rootPrefix: "bad"
monitoring:
  siem: "sentinel"
  logAnalytics:
    topology: "global"
  eventHub:
    enabled: false
    maxThroughputUnits: 10
policy:
  pacOwnerIdSeed: "bad-2025"
  desiredStateStrategy: "ownedOnly"
  initiatives:
    industry: []
    frameworks: []
    exclusions: []
lifecycle:
  enableServiceRequestFlow: false
  infosecReviewers: []
  approvedServicesSeed: "minimal"
handover:
  generateRunbooks: true
  trainingSessions: 1
deployment:
  mode: "managed"
  github:
    org: "bad-org"
    repoName: "bad-repo"
    visibility: "private"
  approval:
    nonprod: false
    prod: true
'@
            $badPath = Join-Path $tmpDir 'long-shortcode.yaml'
            $bad | Set-Content $badPath -Encoding utf8
            $result = Test-SolpackConfig -Path $badPath -PassThru -ErrorAction SilentlyContinue
            $result | Should -BeFalse
        }

        It 'returns false for a file that does not exist' {
            $result = Test-SolpackConfig -Path "$tmpDir\does-not-exist.yaml" -PassThru -ErrorAction SilentlyContinue
            $result | Should -BeFalse
        }
    }
}
