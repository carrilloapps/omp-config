# refresh-stats.ps1 — Windows native equivalent of refresh-stats.sh
# Sets POSH_RAM / POSH_CPU / POSH_GPU / POSH_SPOTIFY before each oh-my-posh prompt
# with adaptive formatting based on terminal width.

$script:OmpWidthFull = 130
$script:OmpGpuCache  = Join-Path $env:TEMP '.posh_gpu_cache.txt'
$script:OmpSpotifyCache = Join-Path $env:TEMP '.posh_spotify_cache.txt'

function _Omp-Width {
    try {
        $w = $Host.UI.RawUI.WindowSize.Width
        if ($w -gt 0) { return $w }
    } catch {}
    return 120
}

function _Omp-IsFull { (_Omp-Width) -ge $script:OmpWidthFull }

function _Omp-Truncate([string]$s, [int]$max) {
    if ([string]::IsNullOrEmpty($s)) { return '' }
    if ($s.Length -gt $max) { return $s.Substring(0, $max - 1) + [char]0x2026 }
    return $s
}

function _Omp-RefreshRam {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $totalKB = [double]$os.TotalVisibleMemorySize
        $freeKB  = [double]$os.FreePhysicalMemory
        if ($totalKB -le 0) { return }
        $usedKB = $totalKB - $freeKB
        $totalG = $totalKB / 1MB
        $usedG  = $usedKB  / 1MB
        $pct    = [int][math]::Round(($usedKB / $totalKB) * 100)
        if (_Omp-IsFull) {
            $env:POSH_RAM = ('{0:N1}G/{1:N0}G ({2}%)' -f $usedG, $totalG, $pct)
        } else {
            $env:POSH_RAM = ('{0}%' -f $pct)
        }
    } catch { $env:POSH_RAM = '' }
}

function _Omp-RefreshCpu {
    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop
        $util = [int](($cpu | Measure-Object -Property LoadPercentage -Average).Average)
        $cores = ($cpu | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
        if ($cores -lt 1) { $cores = 1 }
        $load1 = [math]::Round(($util * $cores) / 100, 2)
        if (_Omp-IsFull) {
            $env:POSH_CPU = ('{0} ({1}%)' -f $load1, $util)
        } else {
            $env:POSH_CPU = ('{0}%' -f $util)
        }
    } catch { $env:POSH_CPU = '' }
}

function _Omp-RefreshGpu {
    try {
        $smiCandidates = @(
            'C:\Windows\System32\nvidia-smi.exe',
            'C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe'
        )
        $smi = $smiCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
        if (-not $smi) { $smi = (Get-Command nvidia-smi -ErrorAction SilentlyContinue).Source }
        if (-not $smi) { $env:POSH_GPU = ''; return }

        $raw = $null
        if (Test-Path $script:OmpGpuCache) {
            $age = (Get-Date) - (Get-Item $script:OmpGpuCache).LastWriteTime
            if ($age.TotalSeconds -lt 5) { $raw = (Get-Content $script:OmpGpuCache -Raw).Trim() }
        }
        if (-not $raw) {
            $raw = (& $smi --query-gpu=memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits 2>$null | Select-Object -First 1)
            if ($raw) {
                $raw = $raw.Trim()
                Set-Content -Path $script:OmpGpuCache -Value $raw -NoNewline -ErrorAction SilentlyContinue
            }
        }
        if (-not $raw) { $env:POSH_GPU = ''; return }

        $parts = ($raw -split ',\s*')
        if ($parts.Count -lt 3) { $env:POSH_GPU = ''; return }
        $usedMB  = [double]$parts[0]
        $totalMB = [double]$parts[1]
        $util    = [int]$parts[2]
        if ($totalMB -le 0) { $env:POSH_GPU = ''; return }

        if (_Omp-IsFull) {
            $env:POSH_GPU = ('{0:N1}G/{1:N0}G ({2}%)' -f ($usedMB / 1024), ($totalMB / 1024), $util)
        } else {
            $env:POSH_GPU = ('{0}%' -f $util)
        }
    } catch { $env:POSH_GPU = '' }
}

function _Omp-RefreshSpotify {
    try {
        $val = ''
        if (Test-Path $script:OmpSpotifyCache) {
            $age = (Get-Date) - (Get-Item $script:OmpSpotifyCache).LastWriteTime
            if ($age.TotalSeconds -lt 3) { $val = (Get-Content $script:OmpSpotifyCache -Raw) }
        }
        if (-not $val) {
            $sp = Get-Process Spotify -ErrorAction SilentlyContinue |
                  Where-Object {
                      $_.MainWindowTitle -and
                      $_.MainWindowTitle -ne 'Spotify Premium' -and
                      $_.MainWindowTitle -ne 'Spotify Free'
                  } | Select-Object -First 1
            if ($sp) { $val = $sp.MainWindowTitle }
            Set-Content -Path $script:OmpSpotifyCache -Value $val -NoNewline -ErrorAction SilentlyContinue
        }
        if ($val -and -not (_Omp-IsFull)) { $val = _Omp-Truncate $val 25 }
        $env:POSH_SPOTIFY = $val
    } catch { $env:POSH_SPOTIFY = '' }
}

function Update-PoshStats {
    _Omp-RefreshRam
    _Omp-RefreshCpu
    _Omp-RefreshGpu
    _Omp-RefreshSpotify
}

# Wrap OMP's prompt function so Update-PoshStats runs before every render.
# (Set-PoshContext doesn't reliably propagate user-scope functions to OMP's prompt,
# so we wrap the prompt itself — idempotent guard prevents double-wrapping.)
if (-not (Test-Path Variable:Script:_OmpStatsWrapped)) {
    $Script:_OmpStatsWrapped = $true
    if (Get-Command prompt -ErrorAction SilentlyContinue) {
        $global:_omp_original_prompt = $function:prompt
        function global:prompt {
            Update-PoshStats
            & $global:_omp_original_prompt
        }
    }
}
