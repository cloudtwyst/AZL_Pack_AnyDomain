function Copy-PolicyDefinitions {
    <#
    .SYNOPSIS
        Copies policy definitions and initiatives from the pack catalog into the
        customer repo's Definitions/ directory, based on the selected initiatives
        in customer-config.yaml.
    .DESCRIPTION
        Reads the selected initiatives from the config, resolves the policy
        definitions referenced by each initiative, and copies both into the
        EPAC-standard Definitions/ layout:

            Definitions/
              policyDefinitions/    <- individual policy JSONC files
              policySetDefinitions/ <- initiative JSONC files
              policyAssignments/    <- rendered from assignment-templates/

        Only writes files when content has changed (idempotent).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config,

        [Parameter(Mandatory)]
        [string] $PackRoot,

        [Parameter(Mandatory)]
        [string] $DefinitionsPath,

        [Parameter(Mandatory)]
        [System.Collections.Specialized.OrderedDictionary] $SubstitutionMap
    )

    $catalogRoot      = Join-Path $PackRoot 'policy-catalog'
    $definitionsDir   = Join-Path $catalogRoot 'definitions'
    $initiativesDir   = Join-Path $catalogRoot 'initiatives'
    $assignmentTmplDir = Join-Path $catalogRoot 'assignment-templates'

    $outDefs        = Join-Path $DefinitionsPath 'policyDefinitions'
    $outInitiatives = Join-Path $DefinitionsPath 'policySetDefinitions'
    $outAssignments = Join-Path $DefinitionsPath 'policyAssignments'

    foreach ($d in @($outDefs, $outInitiatives, $outAssignments)) {
        New-Item -ItemType Directory -Force -Path $d | Out-Null
    }

    # ── Determine which initiatives to include ────────────────────────────────
    $initiativeKeys = [System.Collections.Generic.List[string]]::new()
    $initiativeKeys.Add('baseline-all-customers')

    $policyConfig = $Config['policy']['initiatives']

    foreach ($ind in ($policyConfig['industry'] ?? @())) {
        $initiativeKeys.Add("industry-$ind")
    }

    foreach ($fw in ($policyConfig['frameworks'] ?? @())) {
        $initiativeKeys.Add("framework-$fw")
    }

    # ── Copy initiatives + collect referenced policy names ────────────────────
    $referencedPolicies = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($key in $initiativeKeys) {
        $srcFile = Join-Path $initiativesDir "$key\initiative.jsonc"
        if (-not (Test-Path -LiteralPath $srcFile -PathType Leaf)) {
            Write-Warning "Initiative '$key' not found in catalog — skipping."
            continue
        }

        $content = Get-Content -LiteralPath $srcFile -Raw -Encoding utf8
        $dstFile = Join-Path $outInitiatives "$key.jsonc"

        # Write if changed
        $existing = if (Test-Path $dstFile) { (Get-Content $dstFile -Raw -Encoding utf8).TrimEnd("`r","`n") } else { $null }
        if ($content.TrimEnd("`r","`n") -ne $existing) {
            Set-Content -LiteralPath $dstFile -Value $content -Encoding utf8
            Write-Verbose "  wrote initiative $key"
        }

        # Parse policyDefinitionName references
        $matches = [regex]::Matches($content, '"policyDefinitionName"\s*:\s*"([^"]+)"')
        foreach ($m in $matches) {
            $null = $referencedPolicies.Add($m.Groups[1].Value)
        }
    }

    # ── Copy referenced policy definitions ────────────────────────────────────
    $allDefFiles = Get-ChildItem -Path $definitionsDir -Filter '*.jsonc' -Recurse |
                   Where-Object { $_.Name -ne '_metadata.jsonc' }

    foreach ($defFile in $allDefFiles) {
        $content = Get-Content -LiteralPath $defFile.FullName -Raw -Encoding utf8

        # Check if this file's "name" field is referenced
        $nameMatch = [regex]::Match($content, '"name"\s*:\s*"([^"]+)"')
        if (-not $nameMatch.Success) { continue }
        $policyName = $nameMatch.Groups[1].Value

        if ($policyName -notin $referencedPolicies) { continue }

        $dstFile = Join-Path $outDefs "$policyName.jsonc"
        $existing = if (Test-Path $dstFile) { (Get-Content $dstFile -Raw -Encoding utf8).TrimEnd("`r","`n") } else { $null }
        if ($content.TrimEnd("`r","`n") -ne $existing) {
            Set-Content -LiteralPath $dstFile -Value $content -Encoding utf8
            Write-Verbose "  wrote policy $policyName"
        }
    }

    # ── Render assignment templates ────────────────────────────────────────────
    $tmplFiles = Get-ChildItem -Path $assignmentTmplDir -Filter '*.jsonc' -ErrorAction SilentlyContinue
    foreach ($tmpl in $tmplFiles) {
        $rendered = Invoke-TemplateRender -TemplatePath $tmpl.FullName -SubstitutionMap $SubstitutionMap
        $dstFile  = Join-Path $outAssignments $tmpl.Name
        $existing = if (Test-Path $dstFile) { (Get-Content $dstFile -Raw -Encoding utf8).TrimEnd("`r","`n") } else { $null }
        if ($rendered.TrimEnd("`r","`n") -ne $existing) {
            Set-Content -LiteralPath $dstFile -Value $rendered -Encoding utf8
            Write-Verbose "  wrote assignment $($tmpl.Name)"
        }
    }

    Write-Information "Policy definitions copied: $($referencedPolicies.Count) definitions, $($initiativeKeys.Count) initiatives" -InformationAction Continue
}
