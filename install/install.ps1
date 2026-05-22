# omp-config installer for PowerShell on Windows.
# - Copies themes and refresh-stats.ps1 into %USERPROFILE%\.config\oh-my-posh
# - Installs Terminal-Icons (devblackops/Terminal-Icons) for file/folder icons in ls
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

# Optional: Terminal-Icons (https://github.com/devblackops/Terminal-Icons).
# Adds file/folder icons to Get-ChildItem (`ls`). Requires a Nerd Font in the terminal.
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Write-Host "Installing Terminal-Icons module..."
    try {
        Install-Module -Name Terminal-Icons -Repository PSGallery -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "Terminal-Icons installed."
    } catch {
        Write-Warning "Could not auto-install Terminal-Icons: $($_.Exception.Message)"
        Write-Warning "Install manually: Install-Module -Name Terminal-Icons -Scope CurrentUser"
    }
} else {
    Write-Host "Terminal-Icons module already present."
}

$startMarker = '# >>> omp-config >>>'
$endMarker   = '# <<< omp-config <<<'

$block = @"
$startMarker
# Force UTF-8 so Nerd Font glyphs are not re-encoded into mojibake
`$OutputEncoding = [System.Text.UTF8Encoding]::new(`$false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new(`$false)
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new(`$false)

# Terminal-Icons (devblackops/Terminal-Icons): file/folder icons in Get-ChildItem
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
}

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
    $pattern = [regex]::Escape($startMarker) + '[\s\S]*?' + [regex]::Escape($endMarker)
    $updated = [regex]::Replace($existing, $pattern, [regex]::Escape($block) -replace '\\([\s\S])', '$1')
    Set-Content -Path $profilePath -Value $updated -NoNewline
    Write-Host "Updated existing omp-config block in $profilePath"
} else {
    Add-Content -Path $profilePath -Value "`n$block"
    Write-Host "Appended omp-config block to $profilePath"
}

Write-Host ""
Write-Host "Done. Open a new pwsh window or run: . `$PROFILE"
Write-Host "Requires: oh-my-posh, a Nerd Font configured in Windows Terminal."
