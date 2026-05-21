#Requires -Version 7.0

$privateDir = Join-Path $PSScriptRoot 'private'
$publicDir  = Join-Path $PSScriptRoot 'public'

# Dot-source private helpers first (public functions depend on them)
Get-ChildItem -Path $privateDir -Filter '*.ps1' -Recurse |
    ForEach-Object { . $_.FullName }

# Dot-source public functions
Get-ChildItem -Path $publicDir -Filter '*.ps1' -Recurse |
    ForEach-Object { . $_.FullName }

# Export only the public surface
Export-ModuleMember -Function (
    Get-ChildItem -Path $publicDir -Filter '*.ps1' -Recurse |
        ForEach-Object { $_.BaseName }
)
