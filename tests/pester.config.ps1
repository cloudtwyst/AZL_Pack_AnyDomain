$config = New-PesterConfiguration

$config.Run.Path         = "$PSScriptRoot\unit"
$config.Run.Exit         = $true
$config.Output.Verbosity = 'Detailed'
$config.TestResult.Enabled       = $true
$config.TestResult.OutputPath    = "$PSScriptRoot\..\test-results\pester.xml"
$config.TestResult.OutputFormat  = 'JUnitXml'
$config.CodeCoverage.Enabled     = $false

return $config
