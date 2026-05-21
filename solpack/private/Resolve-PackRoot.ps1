function Resolve-PackRoot {
    <#
    .SYNOPSIS
        Finds the solution pack root directory from an arbitrary working location.
    .DESCRIPTION
        Walks up the directory tree looking for SOLUTION-PACK.md. Returns the
        directory path if found; throws if not found within 10 levels.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [string] $StartPath = $PSScriptRoot
    )

    $current = $StartPath
    $depth   = 0

    while ($depth -lt 10) {
        if (Test-Path -LiteralPath (Join-Path $current 'SOLUTION-PACK.md') -PathType Leaf) {
            return $current
        }
        $parent = Split-Path $current -Parent
        if (-not $parent -or $parent -eq $current) { break }
        $current = $parent
        $depth++
    }

    throw "Could not locate SOLUTION-PACK.md within 10 directory levels of '$StartPath'. " +
          "Run solpack commands from inside the azure-solution-pack repository."
}
