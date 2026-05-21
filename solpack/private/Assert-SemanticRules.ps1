function Assert-SemanticRules {
    <#
    .SYNOPSIS
        Runs semantic checks on a parsed customer config that cannot be expressed in JSON Schema.
    .DESCRIPTION
        Returns an array of [pscustomobject] with Severity ('Warning'|'Error') and Message.
        An empty array means no issues.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[pscustomobject]])]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    $findings = [System.Collections.Generic.List[pscustomobject]]::new()

    function Add-Finding {
        param([string]$Severity, [string]$Message)
        $findings.Add([pscustomobject]@{ Severity = $Severity; Message = $Message })
    }

    $policy     = $Config['policy']
    $monitoring = $Config['monitoring']
    $customer   = $Config['customer']
    $azure      = $Config['azure']

    # desiredStateStrategy=full with a regulated industry is high-risk
    if ($policy['desiredStateStrategy'] -eq 'full') {
        $regulatedIndustries = @('healthcare', 'finance', 'public-sector')
        $customerIndustry    = $customer['industry']
        if ($customerIndustry -in $regulatedIndustries) {
            Add-Finding -Severity Warning -Message (
                "desiredStateStrategy='full' will delete ALL policies not owned by this repo. " +
                "For industry='$customerIndustry' this may remove pre-existing regulatory controls. " +
                "Consider 'ownedOnly' unless you are certain no other policy repos target this tenant."
            )
        }

        $industryFrameworks = $policy['initiatives']['frameworks'] ?? @()
        if ($industryFrameworks.Count -gt 0) {
            Add-Finding -Severity Warning -Message (
                "desiredStateStrategy='full' combined with compliance frameworks [$($industryFrameworks -join ', ')] " +
                "means a misconfigured deploy could wipe framework assignments. " +
                "Ensure the e2e test runs in an ephemeral sub before targeting prod."
            )
        }
    }

    # HIPAA framework requires healthcare industry or an explicit exclusion acknowledgement
    $frameworks = $policy['initiatives']['frameworks'] ?? @()
    if ('hipaa' -in $frameworks -and $customer['industry'] -ne 'healthcare') {
        Add-Finding -Severity Warning -Message (
            "framework 'hipaa' is assigned but customer.industry is '$($customer['industry'])'. " +
            "Confirm HIPAA applicability with the customer before deploying."
        )
    }

    # PCI-DSS requires finance or retail industry
    if ('pci-dss-4.0' -in $frameworks -and $customer['industry'] -notin @('finance', 'retail')) {
        Add-Finding -Severity Warning -Message (
            "framework 'pci-dss-4.0' is assigned but customer.industry is '$($customer['industry'])'. " +
            "Confirm PCI-DSS scope with the customer."
        )
    }

    # industry initiatives must align with customer.industry
    $industryInitiatives = $policy['initiatives']['industry'] ?? @()
    foreach ($ind in $industryInitiatives) {
        if ($ind -ne $customer['industry']) {
            Add-Finding -Severity Warning -Message (
                "policy.initiatives.industry includes '$ind' but customer.industry is '$($customer['industry'])'. " +
                "Mismatched industry initiatives may assign irrelevant controls."
            )
        }
    }

    # Sentinel as SIEM: Event Hub is redundant (Sentinel has a native connector)
    if ($monitoring['siem'] -eq 'sentinel' -and $monitoring['eventHub']['enabled'] -eq $true) {
        Add-Finding -Severity Warning -Message (
            "monitoring.siem='sentinel' with eventHub.enabled=true deploys an Event Hub that Sentinel " +
            "won't use by default. Set eventHub.enabled=false unless another SIEM also consumes the hub."
        )
    }

    # custom MG layout but no customTree
    $mgLayout = $azure['managementGroups']['layout']
    $customTree = $azure['managementGroups']['customTree']
    if ($mgLayout -eq 'custom' -and (-not $customTree -or $customTree.Count -eq 0)) {
        Add-Finding -Severity Error -Message (
            "azure.managementGroups.layout='custom' requires a non-null azure.managementGroups.customTree."
        )
    }

    # shortCode uniqueness cannot be checked here (needs a registry), but flag placeholder GUIDs
    $tenantId = $azure['tenantId']
    if ($tenantId -match '^0{8}-0{4}-') {
        Add-Finding -Severity Error -Message (
            "azure.tenantId appears to be the placeholder GUID '$tenantId'. Replace with the real tenant ID."
        )
    }

    $mgmtSubId = $azure['managementSubscriptionId']
    if ($mgmtSubId -match '^0{8}-0{4}-') {
        Add-Finding -Severity Error -Message (
            "azure.managementSubscriptionId appears to be a placeholder GUID. Replace before deploying."
        )
    }

    # prod approval must be true (schema enforces const:true but belt-and-suspenders)
    if ($Config['deployment']['approval']['prod'] -ne $true) {
        Add-Finding -Severity Error -Message (
            "deployment.approval.prod must be true. It cannot be disabled."
        )
    }

    return $findings
}
