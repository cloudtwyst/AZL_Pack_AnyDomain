function Invoke-TemplateRender {
    <#
    .SYNOPSIS
        Renders a template string or file by replacing {{TOKEN}} placeholders.
    .DESCRIPTION
        Replaces every occurrence of {{TOKEN_NAME}} in the input with the
        corresponding value from the substitution map. Tokens not present in
        the map are left unchanged so callers can chain renders.

        Supports both in-memory string rendering and file-to-file rendering.
    .PARAMETER Template
        Raw template string to render.
    .PARAMETER TemplatePath
        Path to a .tmpl file to read and render.
    .PARAMETER OutputPath
        When specified, writes rendered output to this path.
        Creates parent directories if they do not exist.
        Only writes the file when content has changed (idempotency).
    .PARAMETER SubstitutionMap
        Ordered hashtable of TOKEN_NAME => value from Get-SubstitutionMap.
    .OUTPUTS
        [string] The rendered content (always returned, even when -OutputPath is set).
    #>
    [CmdletBinding(DefaultParameterSetName = 'String')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'String', Position = 0)]
        [string] $Template,

        [Parameter(Mandatory, ParameterSetName = 'File')]
        [string] $TemplatePath,

        [Parameter()]
        [string] $OutputPath,

        [Parameter(Mandatory)]
        [System.Collections.Specialized.OrderedDictionary] $SubstitutionMap
    )

    if ($PSCmdlet.ParameterSetName -eq 'File') {
        if (-not (Test-Path -LiteralPath $TemplatePath -PathType Leaf)) {
            throw "Template file not found: $TemplatePath"
        }
        $Template = Get-Content -LiteralPath $TemplatePath -Raw -Encoding utf8
    }

    $rendered = $Template
    foreach ($key in $SubstitutionMap.Keys) {
        $rendered = $rendered.Replace("{{$key}}", $SubstitutionMap[$key])
    }

    if ($OutputPath) {
        $dir = Split-Path $OutputPath -Parent
        if ($dir -and -not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
        }

        $existingContent = $null
        if (Test-Path -LiteralPath $OutputPath -PathType Leaf) {
            $existingContent = Get-Content -LiteralPath $OutputPath -Raw -Encoding utf8
        }

        # Normalise trailing whitespace before comparing so Set-Content's implicit
        # newline doesn't cause spurious rewrites on every render run.
        $normRendered  = $rendered.TrimEnd("`r", "`n")
        $normExisting  = if ($null -ne $existingContent) { $existingContent.TrimEnd("`r", "`n") } else { $null }

        if ($normRendered -ne $normExisting) {
            Set-Content -LiteralPath $OutputPath -Value $rendered -Encoding utf8
            Write-Verbose "  wrote $OutputPath"
        }
        else {
            Write-Verbose "  unchanged $OutputPath"
        }
    }

    return $rendered
}
