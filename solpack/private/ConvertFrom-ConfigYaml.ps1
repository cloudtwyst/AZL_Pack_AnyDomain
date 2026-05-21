function ConvertFrom-ConfigYaml {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Config file not found: $Path"
    }

    # Requires the 'powershell-yaml' module (Install-Module powershell-yaml).
    # Checked here so the error message is actionable rather than a bare method-not-found.
    if (-not (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
        throw "Required module 'powershell-yaml' is not installed. Run: Install-Module powershell-yaml -Scope CurrentUser"
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding utf8
    $parsed = ConvertFrom-Yaml -Yaml $raw -Ordered

    return $parsed
}
