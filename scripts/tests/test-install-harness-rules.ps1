# Run with Windows PowerShell 5.1 or PowerShell 7; no network or Pester required.
$ErrorActionPreference = 'Stop'
$installer = Join-Path (Split-Path -Parent $PSScriptRoot) 'install-harness-rules.ps1'
$workDir = Join-Path ([IO.Path]::GetTempPath()) ('harness-rules-test-' + [guid]::NewGuid())
$envNames = @('HARNESS_ONLY', 'HARNESS_MIRROR', 'HARNESS_REF', 'HARNESS_OWNER',
    'HARNESS_REPO', 'HARNESS_BASE_GITHUB', 'HARNESS_BASE_JSDELIVR')
$savedEnv = @{}
$utf8 = New-Object System.Text.UTF8Encoding($true)
$testState = @{
    Attempts = New-Object 'System.Collections.Generic.List[string]'
    ExpectedUrls = @()
    RequestsPerFile = 1
}

# Mock downloads, checking URL construction and exercising every fallback.
function Invoke-WebRequest {
    param([string]$Uri, [string]$OutFile, [switch]$UseBasicParsing, [int]$TimeoutSec)
    $index = $testState.Attempts.Count
    if ($index -ge $testState.ExpectedUrls.Count -or $Uri -cne $testState.ExpectedUrls[$index]) {
        throw ('Unexpected download URL: ' + $Uri)
    }
    $testState.Attempts.Add($Uri)
    if (($testState.Attempts.Count % $testState.RequestsPerFile) -ne 0) {
        throw 'Simulated unavailable mirror'
    }
    [IO.File]::WriteAllText((Join-Path (Get-Location).Path $OutFile), "# Test harness rule`r`n", $utf8)
}

$base = 'https://raw.githubusercontent.com/Tairraos/harness-go/master/rules'
$cases = @(
    @{ Mirror = 'github'; Bases = @($base) },
    @{ Mirror = 'ghproxy'; Bases = @(
        ('https://ghproxy.net/' + $base),
        ('https://gh-proxy.com/' + $base)
    ) },
    @{ Mirror = 'jsdelivr'; Bases = @(
        'https://gcore.jsdelivr.net/gh/Tairraos/harness-go@master/rules',
        'https://cdn.jsdelivr.net/gh/Tairraos/harness-go@master/rules'
    ) },
    @{ Mirror = 'auto'; Bases = @(
        $base,
        ('https://ghproxy.net/' + $base),
        ('https://gh-proxy.com/' + $base),
        'https://gcore.jsdelivr.net/gh/Tairraos/harness-go@master/rules',
        'https://cdn.jsdelivr.net/gh/Tairraos/harness-go@master/rules'
    ) }
)

try {
    foreach ($name in $envNames) {
        $savedEnv[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        [Environment]::SetEnvironmentVariable($name, $null, 'Process')
    }
    New-Item -ItemType Directory -Path $workDir | Out-Null
    Push-Location $workDir
    try {
        foreach ($case in $cases) {
            foreach ($only in @('new', 'existing', 'all')) {
                $files = @()
                if ($only -ne 'existing') { $files += 'new-project-harness-rules.md' }
                if ($only -ne 'new') { $files += 'turn-project-to-harness-rules.md' }
                $testState.ExpectedUrls = @(
                    foreach ($file in $files) {
                        foreach ($source in $case.Bases) { $source + '/' + $file }
                    }
                )
                $testState.RequestsPerFile = $case.Bases.Count
                $testState.Attempts.Clear()
                if (Test-Path 'docs') { Remove-Item 'docs' -Recurse -Force }
                if ($case.Mirror -eq 'auto') {
                    # Exercise the default mirror selection used by the README command.
                    & $installer -Only $only
                } else {
                    & $installer -Only $only -Mirror $case.Mirror
                }
                if ($testState.Attempts.Count -ne $testState.ExpectedUrls.Count) {
                    throw ('Incorrect fallback count for ' + $case.Mirror + '/' + $only)
                }
                foreach ($file in $files) {
                    $path = Join-Path 'docs' $file
                    if (-not (Test-Path $path) -or (Get-Item $path).Length -eq 0) {
                        throw ('Missing downloaded rule: ' + $file)
                    }
                }
                if (@(Get-ChildItem 'docs' -File).Count -ne $files.Count) {
                    throw ('Incorrect downloaded file count for ' + $only)
                }
                Write-Host ('PASS: ' + $case.Mirror + '/' + $only)
            }
        }
    } finally {
        Pop-Location
    }
} finally {
    foreach ($name in $savedEnv.Keys) {
        [Environment]::SetEnvironmentVariable($name, $savedEnv[$name], 'Process')
    }
    if (Test-Path $workDir) { Remove-Item $workDir -Recurse -Force }
}
Write-Host 'All 12 installer regression cases passed.'
