# omp-prompt

> A cross-platform [oh-my-posh](https://ohmyposh.dev) prompt configuration designed for developers. Three-line layout with adaptive width, system telemetry, music integration, and two color schemes (Ubuntu brand + monochrome) that switch automatically based on the host OS.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platforms](https://img.shields.io/badge/platforms-Linux%20%7C%20WSL%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)](#supported-platforms)
[![Shells](https://img.shields.io/badge/shells-bash%20%7C%20pwsh-success.svg)](#installation)

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Preview](#preview)
- [Supported Platforms](#supported-platforms)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [How It Works](#how-it-works)
- [Themes](#themes)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)
- [Acknowledgements](#acknowledgements)
- [Author](#author)
- [License](#license)

---

## Overview

`omp-prompt` is a thoughtfully composed [oh-my-posh](https://ohmyposh.dev) configuration that surfaces the information developers actually need without becoming visually noisy. It detects its environment (Ubuntu, macOS, Windows, etc.) and picks an appropriate color scheme automatically, while a companion stats script feeds platform-specific telemetry (RAM, CPU load, GPU utilization, battery, currently-playing Spotify track) into the prompt through environment variables.

The same JSON theme files work identically on every supported platform — platform-specific behavior is isolated to a small shell/PowerShell helper that runs once per prompt render.

## Features

- **Three-line developer layout**
  1. System telemetry (RAM, CPU, GPU, battery) with adaptive icons + Spotify/IP badge
  2. Identity, path, project name, git branch with ahead/behind/staged/working indicators, status icon, execution time, clock
  3. Bare `❯` prompt for command input
- **Adaptive width formatting** — above a configurable column threshold (default `130`), values render as `1.2G/31G (4%)`. Below that, only the percentage shows. The layout reflows on terminal resize.
- **System telemetry**
  - RAM usage in absolute + percentage (`/proc/meminfo`, `vm_stat`+`sysctl`, or `Win32_OperatingSystem` via CIM)
  - CPU load (`/proc/loadavg`, `sysctl vm.loadavg`, or `Win32_Processor`)
  - GPU memory and utilization via `nvidia-smi` (Linux, WSL, Windows) — cached 5 seconds
  - Battery percentage with state-aware icons: charging bolt, level (5 buckets), AC plug
- **Music integration** — reads the active Spotify track. WSL talks to the Windows host via `powershell.exe`. macOS uses `osascript`. Linux uses `playerctl` (MPRIS/D-Bus).
- **Public IP fallback** — when Spotify isn't playing, the badge shows your public IPv4 via oh-my-posh's `ipify` segment (cached 1 hour).
- **Runtime version detection** — Node, Python (with virtualenv), Go, Rust, Bun. Only rendered inside a project directory of that language.
- **Cloud and container context** — `kubectl` context/namespace, `aws` profile, `docker` context. All conditional — hidden when not configured. Docker context auto-hides when on the default `desktop-linux` Docker Desktop context.
- **Background jobs counter** — appears when there are suspended jobs.
- **Cross-platform safety** — platform-specific segments are guarded with `{{ if ne .OS "windows" }}` so the same JSON loads cleanly everywhere.
- **UTF-8 forced** on PowerShell to prevent Nerd Font glyphs from being re-encoded into mojibake by the legacy Windows console.
- **Two color schemes**
  - `ubuntu.omp.json` — official Ubuntu brand palette (orange `#E95420`, aubergine spectrum, warm grays). Auto-selected when `/etc/os-release` reports `ID=ubuntu`.
  - `mono.omp.json` — grayscale, with red and yellow reserved exclusively for warnings (low battery, error exit code, git divergence, offline state, available OMP upgrade).

## Preview

When Spotify is playing on a wide terminal:

```
 24.15.0   1.2G/31G (4%)   0.41 (3%)   1.2G/4G (30%)   79%                  ♫ The Cranberries — Promises 
 user@host  ~/project  proyecto v1.0.0   main ↑1                                              ✓  18:09:42
❯
```

When nothing is playing, the public IP fills the badge:

```
 24.15.0   1.2G/31G (4%)   0.41 (3%)   1.2G/4G (30%)   79%                                  191.92.219.243 
 user@host  ~/project  proyecto v1.0.0   main ↑1                                              ✓  18:09:42
❯
```

On a narrow terminal (below 130 columns), values collapse:

```
 24.15.0   4%   3%   30%   79%                                       ♫ The Cranberries… 
 user@host  ~/project  proyecto v1.0.0   main ↑1                              ✓  18:09:42
❯
```

## Supported Platforms

| Platform | Shell | Status |
|---|---|---|
| Ubuntu (any version) | bash | Full — Ubuntu theme auto-selected |
| Other Linux distros | bash | Full — monochrome theme |
| WSL2 (any distro) | bash | Full — talks to Windows host for Spotify |
| macOS | bash / zsh | Full (zsh untested but compatible) |
| Windows 11 / 10 | PowerShell 7 (`pwsh`) | Full |
| Windows PowerShell 5.1 | `powershell.exe` | Works after `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |

## Requirements

- [**oh-my-posh**](https://ohmyposh.dev/docs/installation/prompt) **v22 or newer**.
- A **Nerd Font** configured in your terminal application.
  - Recommended: `CaskaydiaCove Nerd Font Mono`, `FiraCode Nerd Font Mono`, `0xProto Nerd Font Mono`.
  - The `Mono` variants render icons constrained to a single cell, which is what this prompt is designed for.
- For GPU telemetry: an NVIDIA GPU with `nvidia-smi` available on PATH (or at `/usr/lib/wsl/lib/nvidia-smi` on WSL).
- For the Spotify badge: the desktop Spotify client running. On Linux, `playerctl` (`apt install playerctl` / `brew install playerctl`).

## Installation

### Linux, WSL, and macOS (bash)

```bash
git clone https://github.com/carrilloapps/omp-prompt.git
cd omp-prompt
bash install/install.sh
```

The installer will:

1. Create `~/.config/oh-my-posh/themes/` and copy both theme JSON files there.
2. Copy `scripts/refresh-stats.sh` to `~/.config/oh-my-posh/refresh-stats.sh`.
3. Inject an idempotent block (between `# >>> omp-prompt >>>` and `# <<< omp-prompt <<<` markers) into `~/.bashrc`. Re-running the installer rewrites the block in place — it does not duplicate.

Then open a new terminal or run `source ~/.bashrc`.

### Windows (PowerShell 7)

```powershell
git clone https://github.com/carrilloapps/omp-prompt.git
cd omp-prompt
.\install\install.ps1
```

The installer will:

1. Create `%USERPROFILE%\.config\oh-my-posh\themes\` and copy both theme JSON files there.
2. Copy `scripts\refresh-stats.ps1` to `%USERPROFILE%\.config\oh-my-posh\refresh-stats.ps1`.
3. Inject an idempotent block into `$PROFILE`. The block sets `[Console]::OutputEncoding = UTF8`, initializes oh-my-posh with the Ubuntu theme, dot-sources the stats script, and wraps the `prompt` function so stats refresh on every render.

Then open a new PowerShell window or run `. $PROFILE`.

## Configuration

### File layout after installation

```
~/.config/oh-my-posh/                     ← Linux / macOS / WSL bash
├── refresh-stats.sh
└── themes/
    ├── ubuntu.omp.json
    └── mono.omp.json

%USERPROFILE%\.config\oh-my-posh\         ← Windows pwsh
├── refresh-stats.ps1
└── themes\
    ├── ubuntu.omp.json
    └── mono.omp.json
```

### Theme auto-selection

The bash installer's injected block reads `/etc/os-release` and picks:

- `ubuntu.omp.json` if `ID=ubuntu`
- `mono.omp.json` for any other distro (Arch, Fedora, Debian, Alpine, macOS, etc.)

The PowerShell installer defaults to `ubuntu.omp.json`. Edit `$PROFILE` to point to `mono.omp.json` if you prefer grayscale on Windows.

## How It Works

### Environment-variable driven segments

oh-my-posh themes don't natively support shelling out to platform-specific commands. To keep the theme JSON portable, `omp-prompt` uses a companion script that publishes its values as environment variables which the theme reads via `{{ .Env.POSH_X }}` templates.

| Environment variable | Provided by | Read in template |
|---|---|---|
| `POSH_RAM` | `refresh-stats.sh` / `.ps1` | Yes |
| `POSH_CPU` | `refresh-stats.sh` / `.ps1` | Yes |
| `POSH_GPU` | `refresh-stats.sh` / `.ps1` | Yes |
| `POSH_SPOTIFY` | `refresh-stats.sh` / `.ps1` | Yes |

On bash, `refresh-stats.sh` is appended to `PROMPT_COMMAND` so it runs once per prompt render. On PowerShell, the script wraps the `prompt` function (`Set-PoshContext` is not reliably reachable from oh-my-posh's prompt scope in PowerShell 7).

### Caching

Slow lookups are cached to keep prompt latency below a perceptible threshold:

| Stat | Source command | Cache TTL |
|---|---|---|
| GPU | `nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu` | 5 s |
| Spotify | `powershell.exe`, `osascript`, or `playerctl` | 3 s |
| RAM | `/proc/meminfo`, `vm_stat`+`sysctl`, or CIM | none — cheap |
| CPU | `/proc/loadavg`+`nproc`, `sysctl`, or CIM | none — cheap |

Caches live in `/tmp` (Linux/WSL/macOS) or `%TEMP%` (Windows), keyed by user ID.

### Adaptive width

Formatting is re-derived from the cached raw values on every prompt, using the current terminal width (`$COLUMNS` in bash, `$Host.UI.RawUI.WindowSize.Width` in PowerShell). The threshold variable is exposed at the top of each stats script:

- Bash: `_OMP_WIDTH_FULL=130`
- PowerShell: `$script:OmpWidthFull = 130`

Below the threshold, values collapse to percent-only and the Spotify track is truncated to 25 characters with an ellipsis.

## Themes

### Ubuntu palette (`ubuntu.omp.json`)

Based on the [Ubuntu brand book](https://design.ubuntu.com/brand/) and the [Yaru GTK theme](https://github.com/ubuntu/yaru).

| Color | Hex | Usage |
|---|---|---|
| Ubuntu Orange | `#E95420` | Primary accent — OS icon, CPU, status check, prompt arrow, project on git-clean |
| Canonical Red | `#C7162B` | Errors, low battery, OFFLINE indicator |
| Ubuntu Green | `#0E8420` | Success check icon, Node runtime |
| Aubergine | `#77216F` | Reserved for variations |
| Aubergine Mid | `#5E2750` | Project name, Bun runtime |
| Aubergine Light | `#C25EAD` | GPU icon (high visibility on dark backgrounds) |
| Aubergine Dark | `#2C001E` | Spotify / IP badge background |
| Warm White | `#F7F7F7` | Username, host |
| Warm Gray | `#C7C2BC` | Path, RAM, time |
| Warm Dim | `#928B85` | Execution time |
| Blue | `#335280` | Python, Go, Docker |

### Monochrome (`mono.omp.json`)

Grayscale with color reserved exclusively for warnings:

| Trigger | Color |
|---|---|
| Exit code > 0 | Red |
| Battery ≤ 20% | Red |
| Battery 20–50% | Yellow |
| Git working/staged changes | Yellow |
| Git ahead AND behind (divergence) | Red |
| Background jobs > 0 | Yellow |
| Connection disconnected | Red |
| OMP upgrade available | Yellow |
| Charging | Bright white |

## Customization

### Change the active theme on Windows

Edit `$PROFILE` and replace `ubuntu.omp.json` with `mono.omp.json` in the `$ompTheme` line.

### Change the width threshold

Set a different value at the top of `refresh-stats.sh` (`_OMP_WIDTH_FULL=130`) or `refresh-stats.ps1` (`$script:OmpWidthFull = 130`).

### Change the Spotify-track truncation length

Inside `_omp_refresh_spotify` (bash) or `_Omp-RefreshSpotify` (PowerShell), the truncation helper is called with `25` as the max length. Adjust to taste.

### Swap NF icons

All icons are stored as explicit `\uXXXX` Unicode escapes in the JSON to survive Python heredoc edits. To change an icon, look up its Nerd Font codepoint at [nerdfonts.com/cheat-sheet](https://www.nerdfonts.com/cheat-sheet) and replace the escape in the appropriate segment's `template`.

### Disable a segment

Set the segment's `template` to an empty string `""`, or remove the segment object from the relevant block. Note: the `connection` segment is intentionally guarded with `{{ if ne .OS "windows" }}` — removing the guard will cause a template error on Windows because the field is not exposed there.

## Troubleshooting

**Icons appear as boxes, question marks, or invisible spaces.**
Your terminal font is not a Nerd Font (or is the non-`Mono` variant). Install one of the recommended Nerd Fonts and configure it in your terminal application.

**PowerShell shows `¯£ÿ` or similar gibberish where icons should be.**
UTF-8 encoding wasn't applied. Confirm `$PROFILE` contains the `[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)` line from the installer block.

**The cursor lands on a line below `❯` instead of next to it.**
This was historically caused by right-aligned segments on the prompt line confusing readline. The current layout places `❯` alone on its own line, with no right-aligned content. If the issue persists, check that you opened a fresh terminal after install.

**RAM / CPU / GPU values are empty.**
The stats refresher isn't running. On bash, check that `PROMPT_COMMAND` ends with `source ~/.config/oh-my-posh/refresh-stats.sh`. On PowerShell, verify the prompt was wrapped: `(Get-Command prompt).ScriptBlock.ToString()` should contain `Update-PoshStats`.

**`unable to create text based on template` appears in the prompt.**
A segment template referenced a field that doesn't exist on the current platform. Open an issue with the platform and a copy of your active theme JSON.

## Project Structure

```
omp-prompt/
├── README.md                ← this file
├── LICENSE                  ← MIT
├── .gitignore
├── install/
│   ├── install.sh           ← bash installer (Linux / WSL / macOS)
│   └── install.ps1          ← PowerShell installer (Windows)
├── scripts/
│   ├── refresh-stats.sh     ← stats helper for bash
│   └── refresh-stats.ps1    ← stats helper for PowerShell
└── themes/
    ├── ubuntu.omp.json      ← Ubuntu brand theme
    └── mono.omp.json        ← monochrome theme
```

## Acknowledgements

- [**oh-my-posh**](https://ohmyposh.dev) by [Jan De Dobbeleer](https://github.com/JanDeDobbeleer) — the prompt engine this project builds on.
- [**Ubuntu brand book**](https://design.ubuntu.com/brand/) and the [**Yaru theme**](https://github.com/ubuntu/yaru) — source of the Ubuntu palette.
- [**Nerd Fonts**](https://www.nerdfonts.com) by [Ryan L McIntyre](https://github.com/ryanoasis) — the patched fonts that supply every glyph in this prompt.
- [**Catppuccin Frappé**](https://github.com/catppuccin/catppuccin) — early inspiration for the layout (the original base theme).
- [**ipify**](https://www.ipify.org) — the public IP API used by the fallback badge.

## Author

**Junior Carrillo** — Tech Lead, Open Finance & Payments Expert, AI-Driven Architect.
Based in Medellín, Colombia.

- Website: [carrillo.app](https://carrillo.app)
- Email: [m@carrillo.app](mailto:m@carrillo.app)
- GitHub: [@carrilloapps](https://github.com/carrilloapps)
- LinkedIn: [in/carrilloapps](https://linkedin.com/in/carrilloapps)
- X (Twitter): [@carrilloapps](https://x.com/carrilloapps)
- Bluesky: [@carrilloapps.bsky.social](https://bsky.app/profile/carrilloapps.bsky.social)
- Dev.to: [@carrilloapps](https://dev.to/carrilloapps)
- Hashnode: [@carrilloapps](https://hashnode.com/@carrilloapps)
- Substack: [carrilloapps.substack.com](https://carrilloapps.substack.com)
- Stack Overflow: [user 14580648](https://stackoverflow.com/users/14580648)
- YouTube: [@carrilloapps](https://www.youtube.com/channel/UCIwxFli0q78RqlMOgByVe-g)

## License

Released under the [MIT License](LICENSE). See the `LICENSE` file for the full text.

You are free to use, modify, and redistribute this work in personal and commercial contexts, provided the copyright notice remains intact.
