function Get-SubstitutionMap {
    <#
    .SYNOPSIS
        Builds a flat {{TOKEN}} -> value map from a parsed customer config hashtable.
    .DESCRIPTION
        Returns an ordered hashtable of token names (without braces) to their
        string values. Used by Invoke-TemplateRender and Build-SolpackRepo.

        Derived values:
          PAC_OWNER_ID   - deterministic GUID from policy.pacOwnerIdSeed (MD5-based)
          ROOT_MG_ID     - azure.managementGroups.rootPrefix + "-root"
          EPAC_DEV_MG    - rootPrefix + "-sandbox"
          EPAC_NONPROD_MG- rootPrefix + "-corp"
          EPAC_PROD_MG   - rootPrefix + "-root"
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    $c  = $Config['customer']
    $d  = $Config['deployment']
    $az = $Config['azure']
    $m  = $Config['monitoring']
    $p  = $Config['policy']
    $lc = $Config['lifecycle']

    $rootPrefix = $az['managementGroups']['rootPrefix']

    # Deterministic GUID from the pacOwnerIdSeed using MD5
    $md5    = [System.Security.Cryptography.MD5]::Create()
    $bytes  = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($p['pacOwnerIdSeed']))
    $pacOwnerGuid = [System.Guid]::new($bytes).ToString()

    $map = [ordered]@{
        # Customer
        CUSTOMER_NAME       = $c['name']
        CUSTOMER_SHORT_CODE = $c['shortCode']
        CUSTOMER_INDUSTRY   = $c['industry']
        PRIMARY_CONTACT     = $c['primaryContact']

        # Deployment
        GITHUB_ORG          = $d['github']['org']
        GITHUB_REPO         = $d['github']['repoName']
        GITHUB_VISIBILITY   = $d['github']['visibility']
        DEPLOY_MODE         = $d['mode']

        # Azure
        TENANT_ID                    = $az['tenantId']
        MANAGEMENT_SUBSCRIPTION_ID   = $az['managementSubscriptionId']
        PRIMARY_REGION               = $az['regions']['primary']

        # Management groups
        ROOT_MG_ID       = "$rootPrefix-root"
        PLATFORM_MG_ID   = "$rootPrefix-platform"
        LANDINGZONES_MG_ID = "$rootPrefix-landingzones"
        CORP_MG_ID       = "$rootPrefix-corp"
        ONLINE_MG_ID     = "$rootPrefix-online"
        SANDBOX_MG_ID    = "$rootPrefix-sandbox"
        DECOMMISSIONED_MG_ID = "$rootPrefix-decommissioned"
        EPAC_DEV_MG      = "$rootPrefix-sandbox"
        EPAC_NONPROD_MG  = "$rootPrefix-corp"
        EPAC_PROD_MG     = "$rootPrefix-root"

        # Monitoring
        SIEM                         = $m['siem']
        LAW_TOPOLOGY                 = $m['logAnalytics']['topology']
        EVENT_HUB_ENABLED            = ($m['eventHub']['enabled']).ToString().ToLower()
        EVENT_HUB_MAX_THROUGHPUT     = ($m['eventHub']['maxThroughputUnits'] ?? 10).ToString()

        # Policy
        PAC_OWNER_ID              = $pacOwnerGuid
        PAC_OWNER_ID_SEED         = $p['pacOwnerIdSeed']
        DESIRED_STATE_STRATEGY    = $p['desiredStateStrategy']

        # Pack metadata (filled at render time; some must be updated post-deploy)
        LOG_ANALYTICS_WORKSPACE_ID   = '# TODO: set after terraform apply (monitoring-backbone output)'
        EVENT_HUB_AUTH_RULE_ID       = '# TODO: set after terraform apply (monitoring-backbone output)'

        # Misc
        PACK_VERSION = '0.1.0'
        SCHEMA_VERSION = $Config['schemaVersion']
    }

    return $map
}
