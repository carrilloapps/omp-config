# omp-prompt

Cross-platform [oh-my-posh](https://ohmyposh.dev) prompt: a developer-focused 3-line layout that runs on **Linux, WSL, macOS, and Windows** with two color schemes (Ubuntu brand palette + monochrome) selected automatically by distro.

## Features

- **3-line layout**: system stats + Spotify badge / public IP, then identity + git + time, then `❯` for typing
- **Adaptive formatting**: above 130 columns shows `1.2G/31G (4%)`; below shows compact `4%` — auto-switches on terminal resize
- **System telemetry**: RAM, CPU load, GPU utilization (NVIDIA), battery with adaptive icons (full → empty + charging bolt + AC plug)
- **Spotify integration**: reads the currently-playing track via PowerShell on Windows (works through WSL too), `osascript` on macOS, `playerctl` on Linux. Falls back to public IP via `ipify` segment when nothing is playing.
- **Runtime detection**: node, python, go, rust, bun shown only inside project directories
- **Cloud context**: kubectl, AWS profile, docker context — render only when configured
- **Two themes**: `ubuntu.omp.json` (orange + aubergine brand) and `mono.omp.json` (grayscale with red/yellow for warnings only)
- **Cross-platform safe**: all platform-specific segments use `{{ if ne .OS "windows" }}` guards so the same JSON works everywhere
- **UTF-8 forced** on PowerShell so Nerd Font glyphs don't turn into mojibake

## Preview

```
 24.15.0   1.2G/31G (4%)   0.41 (3%)   1.2G/4G (30%)   79%                ♫ The Cranberries - Promises 
 user@host  ~/project  proyecto v1.0.0  main ↑1                                          ✓  18:09:42
❯
```

## Requirements

- [oh-my-posh](https://ohmyposh.dev/docs/installation/prompt) v22+
- A Nerd Font configured in your terminal (e.g. `CaskaydiaCove Nerd Font`, `FiraCode Nerd Font`, `0xProto Nerd Font Mono`)
- For GPU stats: NVIDIA GPU with `nvidia-smi` available
- For Spotify badge: the desktop Spotify client running (Windows / macOS / Linux MPRIS)

## Install

### Linux / WSL / macOS (bash)

```bash
git clone https://github.com/<your-user>/omp-prompt.git
cd omp-prompt
bash install/install.sh
```

This will:
1. Copy themes to `~/.config/oh-my-posh/themes/`
2. Copy `refresh-stats.sh` to `~/.config/oh-my-posh/`
3. Inject an idempotent block into `~/.bashrc`

Then open a new terminal.

### Windows (PowerShell 7)

```powershell
git clone https://github.com/<your-user>/omp-prompt.git
cd omp-prompt
.\install\install.ps1
```

This will:
1. Copy themes to `%USERPROFILE%\.config\oh-my-posh\themes\`
2. Copy `refresh-stats.ps1` to `%USERPROFILE%\.config\oh-my-posh\`
3. Inject an idempotent block into `$PROFILE`

Then open a new PowerShell window.

## Configuration

| File | Purpose |
|---|---|
| `themes/ubuntu.omp.json` | Ubuntu palette (orange + aubergine + warm gray). Auto-selected when `/etc/os-release` reports `ID=ubuntu` |
| `themes/mono.omp.json` | Grayscale + red/yellow for warnings (low battery, errors, git divergence) |
| `scripts/refresh-stats.sh` | Populates `POSH_RAM` / `POSH_CPU` / `POSH_GPU` / `POSH_SPOTIFY` env vars on bash |
| `scripts/refresh-stats.ps1` | Same, for PowerShell. Also wraps the `prompt` function so stats refresh on every render |

### Customizing the width threshold

In `refresh-stats.sh` and `refresh-stats.ps1`, the variable `$_OMP_WIDTH_FULL` / `$script:OmpWidthFull` (default `130`) controls when the prompt switches between full (`1.2G/31G (4%)`) and compact (`4%`) display.

### Switching to mono theme on Windows

Edit `$PROFILE` and change `ubuntu.omp.json` to `mono.omp.json`.

## How adaptive formatting works

Three caches in `/tmp` (or `%TEMP%`) keep slow lookups out of the prompt path:

| Stat | Source | Cache TTL |
|---|---|---|
| GPU | `nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu` | 5s |
| Spotify | `powershell.exe Get-Process Spotify` (WSL→Win), `osascript` (macOS), `playerctl` (Linux) | 3s |
| RAM | `/proc/meminfo` (Linux/WSL), `vm_stat`+`sysctl` (macOS), `Win32_OperatingSystem` (Windows) | none — cheap |
| CPU | `/proc/loadavg`+`nproc` (Linux/WSL), `sysctl` (macOS), `Win32_Processor` (Windows) | none — cheap |

Format is re-derived from cached raw values every prompt based on current `$COLUMNS`, so the layout reflows immediately on terminal resize.

## Acknowledgements

Built on top of [oh-my-posh](https://ohmyposh.dev) by Jan De Dobbeleer. Ubuntu colors based on the official [Yaru theme](https://github.com/ubuntu/yaru) and [Ubuntu brand book](https://design.ubuntu.com/brand/).

## License

MIT — see [LICENSE](LICENSE).
