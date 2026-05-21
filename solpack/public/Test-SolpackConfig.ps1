function Test-SolpackConfig {
    <#
    .SYNOPSIS
        Validates a solpack customer-config.yaml file against the JSON Schema and semantic rules.

    .DESCRIPTION
        Performs two layers of validation:

        1. JSON Schema — loads schemas/customer-config.schema.json and runs PowerShell's
           built-in Test-Json against the serialised config (requires PS 7.1+).

        2. Semantic rules — checks that cannot be expressed in JSON Schema:
           - desiredStateStrategy=full with a regulated industry (Warning)
           - HIPAA/PCI-DSS framework vs industry mismatch (Warning)
           - Sentinel SIEM with redundant Event Hub (Warning)
           - Placeholder GUIDs in tenantId / managementSubscriptionId (Error)
           - custom MG layout without customTree (Error)

        Warnings are written via Write-Warning.
        Schema and semantic errors are written via Write-Error.

        Returns $true if validation passed (zero errors; warnings are non-blocking).
        Returns $false if any error was found.

        Use -PassThru to return the parsed config object on success instead of $true.

    .PARAMETER Path
        Path to the customer-config.yaml file to validate.
        Defaults to 'customer-config.yaml' in the current directory.

    .PARAMETER SchemaPath
        Path to the JSON Schema file.
        Defaults to schemas/customer-config.schema.json relative to the solpack module root.

    .PARAMETER PassThru
        When specified, returns the parsed config hashtable on success instead of $true.

    .PARAMETER TreatWarningsAsErrors
        When specified, semantic warnings are promoted to errors and cause the function to
        return $false.

    .EXAMPLE
        Test-SolpackConfig

        Validates customer-config.yaml in the current directory using the bundled schema.

    .EXAMPLE
        Test-SolpackConfig -Path ./customers/contoso/customer-config.yaml

        Validates a specific config file.

    .EXAMPLE
        $config = Test-SolpackConfig -PassThru
        if ($config) { Write-Information "Tenant: $($config.azure.tenantId)" -InformationAction Continue }

        Returns the parsed config on success, $false on failure.

    .EXAMPLE
        Test-SolpackConfig -TreatWarningsAsErrors

        Fails on any warning — useful in CI pipelines.
    #>
    [CmdletBinding()]
    [OutputType([bool], [hashtable])]
    param(
        [Parameter(Position = 0)]
        [string] $Path = 'customer-config.yaml',

        [Parameter()]
        [string] $SchemaPath,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [switch] $TreatWarningsAsErrors
    )

    $errorCount = 0

    # Resolve schema path: explicit arg → module-relative default
    if (-not $SchemaPath) {
        $SchemaPath = Join-Path $PSScriptRoot '..\..' 'schemas' 'customer-config.schema.json'
    }

    if (-not (Test-Path -LiteralPath $SchemaPath -PathType Leaf)) {
        Write-Error "Schema file not found: $SchemaPath"
        return $false
    }

    # ── 1. Parse YAML ────────────────────────────────────────────────────────
    Write-Verbose "Parsing $Path"
    try {
        $config = ConvertFrom-ConfigYaml -Path $Path
    }
    catch {
        Write-Error "Failed to parse YAML: $_"
        return $false
    }

    # ── 2. JSON Schema validation ─────────────────────────────────────────────
    Write-Verbose "Running JSON Schema validation"
    $schemaContent = Get-Content -LiteralPath $SchemaPath -Raw -Encoding utf8
    $configJson    = $config | ConvertTo-Json -Depth 20

    $schemaErrors = [System.Collections.Generic.List[string]]::new()
    $schemaValid  = Test-Json -Json $configJson -Schema $schemaContent -ErrorVariable schemaErrorVar -ErrorAction SilentlyContinue

    if (-not $schemaValid) {
        foreach ($e in $schemaErrorVar) {
            Write-Error "[Schema] $($e.Exception.Message)"
            $errorCount++
        }
    }

    # ── 3. Semantic checks (only when schema is valid) ───────────────────────
    Write-Verbose "Running semantic checks"
    if ($errorCount -gt 0) {
        Write-Information "Validation FAILED — $errorCount error(s) found in $Path" -InformationAction Continue
        return $false
    }
    $findings = Assert-SemanticRules -Config $config

    foreach ($f in $findings) {
        if ($f.Severity -eq 'Error') {
            Write-Error "[Semantic] $($f.Message)"
            $errorCount++
        }
        elseif ($TreatWarningsAsErrors) {
            Write-Error "[Semantic] $($f.Message)"
            $errorCount++
        }
        else {
            Write-Warning "[Semantic] $($f.Message)"
        }
    }

    # ── 4. Result ────────────────────────────────────────────────────────────
    if ($errorCount -gt 0) {
        Write-Information "Validation FAILED — $errorCount error(s) found in $Path" -InformationAction Continue
        return $false
    }

    Write-Information "Validation PASSED — $Path" -InformationAction Continue

    if ($PassThru) {
        return $config
    }
    return $true
}
