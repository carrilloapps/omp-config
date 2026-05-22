# omp-prompt installer for PowerShell on Windows.
# - Copies themes and refresh-stats.ps1 into %USERPROFILE%\.config\oh-my-posh
# - Inserts an idempotent block into the PowerShell profile

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$confDir  = Join-Path $env:USERPROFILE ".config\oh-my-posh"
$themeDir = Join-Path $confDir "themes"
$profileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
if (-not (Test-Path $themeDir))   { New-Item -ItemType Directory -Path $themeDir   -Force | Out-Null }

Copy-Item (Join-Path $repoRoot 'themes\ubuntu.omp.json') $themeDir -Force
Copy-Item (Join-Path $repoRoot 'themes\mono.omp.json')   $themeDir -Force
Copy-Item (Join-Path $repoRoot 'scripts\refresh-stats.ps1') $confDir -Force
Write-Host "Installed themes + refresh-stats.ps1 under $confDir"

$startMarker = '# >>> omp-prompt >>>'
$endMarker   = '# <<< omp-prompt <<<'

$block = @"
$startMarker
# Force UTF-8 so Nerd Font glyphs are not re-encoded into mojibake
`$OutputEncoding = [System.Text.UTF8Encoding]::new(`$false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new(`$false)
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new(`$false)

`$ompTheme = "`$env:USERPROFILE\.config\oh-my-posh\themes\ubuntu.omp.json"
`$ompStats = "`$env:USERPROFILE\.config\oh-my-posh\refresh-stats.ps1"

if (Test-Path `$ompTheme) {
    oh-my-posh init pwsh --config `$ompTheme | Invoke-Expression
    if (Test-Path `$ompStats) { . `$ompStats }
}
$endMarker
"@

$profilePath = $PROFILE
$existing = if (Test-Path $profilePath) { Get-Content $profilePath -Raw } else { "" }

if ($existing -match [regex]::Escape($startMarker)) {
    # Replace existing block between markers
    $pattern = [regex]::Escape($startMarker) + '[\s\S]*?' + [regex]::Escape($endMarker)
    $updated = [regex]::Replace($existing, $pattern, [regex]::Escape($block) -replace '\\([\s\S])', '$1')
    Set-Content -Path $profilePath -Value $updated -NoNewline
    Write-Host "Updated existing omp-prompt block in $profilePath"
} else {
    Add-Content -Path $profilePath -Value "`n$block"
    Write-Host "Appended omp-prompt block to $profilePath"
}

Write-Host ""
Write-Host "Done. Open a new pwsh window or run: . `$PROFILE"
Write-Host "Requires: oh-my-posh, a Nerd Font configured in Windows Terminal."
