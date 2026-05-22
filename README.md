<div align="center">

# omp-config

**A cross-platform [oh-my-posh](https://ohmyposh.dev) prompt for developers.**
Adaptive 3-line layout · system telemetry · music integration · brand-aware themes.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)
[![Platforms](https://img.shields.io/badge/platforms-linux%20%7C%20wsl%20%7C%20macos%20%7C%20windows-lightgrey.svg?style=flat-square)](#supported-platforms)
[![Shells](https://img.shields.io/badge/shells-bash%20%7C%20pwsh-success.svg?style=flat-square)](#installation)
[![oh-my-posh](https://img.shields.io/badge/oh--my--posh-v22%2B-E95420.svg?style=flat-square)](https://ohmyposh.dev)
[![GitHub stars](https://img.shields.io/github/stars/carrilloapps/omp-config?style=flat-square&color=2C001E)](https://github.com/carrilloapps/omp-config/stargazers)

</div>

---

```text
 24.15.0   1.2G/31G (4%)   0.41 (3%)   1.2G/4G (30%)   79%             ♫ The Cranberries — Promises
 user@host  ~/project  proyecto v1.0.0   main ↑1                                       ✓  18:09:42
❯
```

## Why

Most prompt configurations leak details from their host's OS, package manager, or shell. `omp-config` is one set of theme files that produces a coherent prompt on **Ubuntu, other Linux distros, WSL, macOS, and Windows** — picking the right palette and the right telemetry source automatically. Slow data (GPU memory, Spotify track) is cached. The layout reflows below a configurable column count so narrow terminals stay readable.

## Highlights

<table>
<tr>
<td width="50%" valign="top">

**Layout**

- Three lines: telemetry, identity + git, prompt
- Adaptive: `1.2G/31G (4%)` → `4%` below 130 cols
- Spotify badge replaced by public IP when no music

</td>
<td width="50%" valign="top">

**Telemetry**

- RAM, CPU load, GPU memory + utilization, battery
- Battery icons reflect state (5 levels + charging + AC plug)
- Cached lookups keep prompt latency imperceptible

</td>
</tr>
<tr>
<td valign="top">

**Context**

- Runtime versions (Node, Python, Go, Rust, Bun)
- Cloud (`kubectl`, `aws`, `docker`) — only when set
- Git: ahead/behind/staged/working indicators

</td>
<td valign="top">

**Cross-platform**

- Same JSON works on Linux, WSL, macOS, Windows
- `{{ if ne .OS "windows" }}` guards on host-specific fields
- UTF-8 forced on PowerShell to preserve Nerd Font glyphs

</td>
</tr>
</table>

## Table of Contents

- [Preview](#preview)
- [Supported Platforms](#supported-platforms)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Optional Integrations](#optional-integrations)
- [How It Works](#how-it-works)
- [Themes](#themes)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)
- [Acknowledgements](#acknowledgements)
- [Author](#author)
- [License](#license)

## Preview

<details open>
<summary><strong>Wide terminal, Spotify playing</strong></summary>

```text
 24.15.0   1.2G/31G (4%)   0.41 (3%)   1.2G/4G (30%)   79%             ♫ The Cranberries — Promises
 user@host  ~/project  proyecto v1.0.0   main ↑1                                       ✓  18:09:42
❯
```

</details>

<details>
<summary><strong>Wide terminal, no music — public IP fallback</strong></summary>

```text
 24.15.0   1.2G/31G (4%)   0.41 (3%)   1.2G/4G (30%)   79%                           191.92.219.243
 user@host  ~/project  proyecto v1.0.0   main ↑1                                       ✓  18:09:42
❯
```

</details>

<details>
<summary><strong>Narrow terminal, compact mode</strong></summary>

```text
 24.15.0   4%   3%   30%   79%                                ♫ The Cranberries…
 user@host  ~/project  main ↑1                                        ✓  18:09:42
❯
```

</details>

<details>
<summary><strong>Failed command (exit 42), slow command (2.3 s)</strong></summary>

```text
 24.15.0   1.2G/31G (4%)   0.41 (3%)   1.2G/4G (30%)   79%             ♫ The Cranberries — Promises
 user@host  ~/project  proyecto v1.0.0   main ↑1                ✗ 42   2.3s   18:09:42
❯
```

</details>

## Supported Platforms

| Platform | Shell | Status | Theme auto-selected |
|---|---|---|---|
| Ubuntu (any version) | bash | Full | `ubuntu.omp.json` |
| WSL2 (Ubuntu) | bash | Full | `ubuntu.omp.json` |
| WSL2 (Debian, Arch, etc.) | bash | Full | `mono.omp.json` |
| Other Linux (Arch, Fedora, Debian, Alpine…) | bash | Full | `mono.omp.json` |
| macOS | bash · zsh | Full | `mono.omp.json` |
| Windows 11 / 10 | PowerShell 7 (`pwsh`) | Full | `ubuntu.omp.json` (configurable) |
| Windows PowerShell 5.1 | `powershell.exe` | Works after enabling script execution policy | manual |

## Requirements

- [**oh-my-posh**](https://ohmyposh.dev/docs/installation/prompt) **v22 or newer**
- A **Nerd Font** configured in your terminal — `Mono` variants render icons in a single cell
  - Recommended: `CaskaydiaCove Nerd Font Mono`, `FiraCode Nerd Font Mono`, `0xProto Nerd Font Mono`, `MesloLGS NF`
  - These fonts also fully cover [Terminal-Icons](#optional-integrations) on Windows out of the box
- For GPU telemetry: NVIDIA GPU with `nvidia-smi` on PATH (or at `/usr/lib/wsl/lib/nvidia-smi` on WSL)
- For Spotify badge: the desktop Spotify client running
- For Linux desktop Spotify integration: `playerctl` (`apt install playerctl` · `pacman -S playerctl` · `brew install playerctl`)

## Installation

<details>
<summary><strong>Ubuntu (native Linux)</strong></summary>

```bash
git clone https://github.com/carrilloapps/omp-config.git
cd omp-config
bash install/install.sh
```

What it does:

1. Creates `~/.config/oh-my-posh/themes/` and copies both theme JSON files
2. Copies `scripts/refresh-stats.sh` to `~/.config/oh-my-posh/refresh-stats.sh`
3. Injects an idempotent block between `# >>> omp-config >>>` and `# <<< omp-config <<<` markers into `~/.bashrc`
4. The block reads `/etc/os-release`, finds `ID=ubuntu`, and loads `ubuntu.omp.json` automatically

Activate:

```bash
source ~/.bashrc
```

Or open a new terminal.

</details>

<details>
<summary><strong>WSL2 (Ubuntu, Debian, or any distro on Windows)</strong></summary>

The bash installer works identically inside WSL — but there are a few WSL-specific behaviors worth knowing.

**Install:**

```bash
git clone https://github.com/carrilloapps/omp-config.git
cd omp-config
bash install/install.sh
```

**WSL-specific behavior:**

- **Spotify integration:** when WSL is detected (`microsoft` in `/proc/version`), the stats refresher calls `powershell.exe Get-Process Spotify` to read the currently-playing track from the Windows host. The Spotify client must be running on Windows, not inside WSL.
- **GPU telemetry:** uses `/usr/lib/wsl/lib/nvidia-smi`, which Windows mounts into every WSL distro automatically when you have NVIDIA drivers installed on Windows.
- **Battery:** OMP reads `/sys/class/power_supply/BAT*`. WSL2 exposes battery state from the host, so the percentage and charging state work without extra setup.
- **Path display:** when launching pwsh from Windows Terminal into a WSL directory, the path shows as `\\wsl.localhost\Ubuntu\...` — that's expected.

**Theme:** Ubuntu WSL gets `ubuntu.omp.json`. Other distros on WSL (Debian, Arch, etc.) get `mono.omp.json` — both decided by `/etc/os-release` `ID=`.

Activate:

```bash
source ~/.bashrc
```

</details>

<details>
<summary><strong>Other Linux (Arch, Fedora, Debian, Alpine, openSUSE, …)</strong></summary>

```bash
git clone https://github.com/carrilloapps/omp-config.git
cd omp-config
bash install/install.sh
```

The installer reads `/etc/os-release`. Any value of `ID` other than `ubuntu` causes the `mono.omp.json` theme to load — grayscale with red and yellow reserved for warnings. If you prefer the Ubuntu palette anywhere, edit the block in `~/.bashrc` and change `mono.omp.json` to `ubuntu.omp.json`.

For Spotify on Linux desktops, install `playerctl`:

- Arch: `pacman -S playerctl`
- Fedora: `dnf install playerctl`
- Debian / Ubuntu: `apt install playerctl`
- openSUSE: `zypper install playerctl`

Activate:

```bash
source ~/.bashrc
```

</details>

<details>
<summary><strong>macOS (Intel and Apple Silicon)</strong></summary>

```bash
git clone https://github.com/carrilloapps/omp-config.git
cd omp-config
bash install/install.sh
```

The installer detects the oh-my-posh binary at `/opt/homebrew/bin/oh-my-posh` (Apple Silicon) or `/usr/local/bin/oh-my-posh` (Intel), and falls back to whatever `which oh-my-posh` returns.

**macOS-specific behavior:**

- **Spotify:** read via `osascript` against the Spotify.app process. No additional installation required.
- **GPU:** Apple Silicon Macs don't have an NVIDIA GPU, so the GPU segment is empty. This is expected.
- **RAM:** computed from `vm_stat` + `sysctl hw.memsize` (used = total − free − inactive − speculative).
- **CPU:** uses `sysctl vm.loadavg` for load and `sysctl hw.ncpu` for core count.

**zsh users:** the bash installer modifies `~/.bashrc`, but oh-my-posh works the same on zsh. To install for zsh manually, replace `bash` with `zsh` in the OMP init line:

```zsh
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/themes/ubuntu.omp.json)"
```

Activate:

```bash
source ~/.bashrc
```

Or open a new terminal.

</details>

<details>
<summary><strong>Windows 11 / 10 (PowerShell 7)</strong></summary>

```powershell
git clone https://github.com/carrilloapps/omp-config.git
cd omp-config
.\install\install.ps1
```

What it does:

1. Creates `%USERPROFILE%\.config\oh-my-posh\themes\` and copies both theme files
2. Copies `scripts\refresh-stats.ps1` to `%USERPROFILE%\.config\oh-my-posh\refresh-stats.ps1`
3. Injects an idempotent block between `# >>> omp-config >>>` and `# <<< omp-config <<<` markers into `$PROFILE`
4. The block sets `[Console]::OutputEncoding = UTF8`, initializes oh-my-posh with `ubuntu.omp.json`, dot-sources the stats script, and wraps the `prompt` function so stats refresh every render

To switch to the mono theme on Windows, edit `$PROFILE` and change `ubuntu.omp.json` to `mono.omp.json`.

Activate:

```powershell
. $PROFILE
```

Or open a new PowerShell window.

</details>

<details>
<summary><strong>Windows PowerShell 5.1 (legacy <code>powershell.exe</code>)</strong></summary>

PowerShell 5.1 ships with `Restricted` execution policy by default, which blocks loading scripts. Run this once:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

The profile path for Windows PowerShell 5.1 is different from PowerShell 7. After cloning, manually copy the contents of the installer block into:

```
%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
```

PowerShell 7 is strongly recommended — it has UTF-8 defaults, faster startup, and is the supported target of the installer.

</details>

<details>
<summary><strong>Manual install (any platform)</strong></summary>

If you'd rather not run the installer, copy the files yourself.

**bash:**

1. Copy `themes/ubuntu.omp.json` and `themes/mono.omp.json` to `~/.config/oh-my-posh/themes/`
2. Copy `scripts/refresh-stats.sh` to `~/.config/oh-my-posh/refresh-stats.sh` and `chmod +x`
3. Append to `~/.bashrc`:

```bash
eval "$(oh-my-posh init bash --config ~/.config/oh-my-posh/themes/ubuntu.omp.json)"
PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND}; }source $HOME/.config/oh-my-posh/refresh-stats.sh"
```

**PowerShell:**

1. Copy `themes\*.json` to `$env:USERPROFILE\.config\oh-my-posh\themes\`
2. Copy `scripts\refresh-stats.ps1` to `$env:USERPROFILE\.config\oh-my-posh\refresh-stats.ps1`
3. Append to `$PROFILE`:

```powershell
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
oh-my-posh init pwsh --config "$env:USERPROFILE\.config\oh-my-posh\themes\ubuntu.omp.json" | Invoke-Expression
. "$env:USERPROFILE\.config\oh-my-posh\refresh-stats.ps1"
```

</details>

## Configuration

### File layout after installation

```
~/.config/oh-my-posh/                     # Linux / macOS / WSL bash
├── refresh-stats.sh
└── themes/
    ├── ubuntu.omp.json
    └── mono.omp.json

%USERPROFILE%\.config\oh-my-posh\         # Windows pwsh
├── refresh-stats.ps1
└── themes\
    ├── ubuntu.omp.json
    └── mono.omp.json
```

### Theme auto-selection

The bash installer's injected block reads `/etc/os-release`:

- `ID=ubuntu` → `ubuntu.omp.json`
- anything else → `mono.omp.json`

PowerShell defaults to `ubuntu.omp.json`. Edit `$PROFILE` to switch.

## Optional Integrations

Beyond the prompt itself, `omp-config` ships with **automatic** integrations that add per-file icons to `ls` / `Get-ChildItem` output. The Unix installer auto-installs both `eza` and `icons-in-terminal`; the Windows installer auto-installs `Terminal-Icons`. None of them are required — if installation fails, the prompt still works.

| Tool | Platforms | Adds | Auto-installed by |
|---|---|---|---|
| [**eza**](https://github.com/eza-community/eza) | Linux · WSL · macOS | `--icons` flag for `ls`/`ll`/`la`/`lt` (uses your Nerd Font) | `install/install.sh` |
| [**icons-in-terminal**](https://github.com/sebastiencs/icons-in-terminal) | Linux · WSL · macOS | 1400+ shell variables (`$oct_*`, `$fa_*`, `$powerline_*`, …) for scripts | `install/install.sh` |
| [**Terminal-Icons**](https://github.com/devblackops/Terminal-Icons) | Windows · PowerShell | File/folder icons in `Get-ChildItem` | `install/install.ps1` |

<details>
<summary><strong>Terminal-Icons — Windows · PowerShell</strong></summary>

[devblackops/Terminal-Icons](https://github.com/devblackops/Terminal-Icons) is a PowerShell module that adds Nerd-Font icons to `Get-ChildItem` (`ls`, `dir`) based on file type and extension. It uses the same Nerd Font already required by `omp-config`, so there is no additional font installation.

**Automatic installation:** `install.ps1` checks for the module and installs it from the PowerShell Gallery when missing:

```powershell
Install-Module -Name Terminal-Icons -Scope CurrentUser -Force
```

The installer's `$PROFILE` block then imports it on every shell start:

```powershell
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
}
```

**Manual install:**

```powershell
Install-Module -Name Terminal-Icons -Scope CurrentUser
```

**Compatible fonts:** any Nerd Font Mono variant. The recommended fonts in the [Requirements](#requirements) section all work.

**Result:** `ls` shows folder/file icons colored by type:

```
   src/
   package.json
   tsconfig.json
   .env
   README.md
```

</details>

<details>
<summary><strong>eza — Linux · WSL · macOS · bash</strong></summary>

[eza](https://github.com/eza-community/eza) is a modern replacement for `ls` with native `--icons` support that reads from your Nerd Font. The installer detects your package manager and runs the right command:

| Detector | Command run |
|---|---|
| `brew` (macOS / Linuxbrew) | `brew install eza` |
| `apt-get` (Ubuntu / Debian) | `sudo apt-get install -y eza` |
| `pacman` (Arch) | `sudo pacman -S --noconfirm eza` |
| `dnf` (Fedora) | `sudo dnf install -y eza` |
| `cargo` (Rust) | `cargo install eza` |

After install, `install.sh` adds four aliases to the `~/.bashrc` block:

```bash
alias ls='eza --icons --group-directories-first'
alias ll='eza --icons -la --group-directories-first'
alias la='eza --icons -a --group-directories-first'
alias lt='eza --icons --tree --level=2 --group-directories-first'
```

Aliases are wrapped in `if command -v eza >/dev/null` so they only apply when eza is installed. If `eza` is uninstalled later, the aliases vanish on next shell start and `ls` falls back to coreutils.

</details>

<details>
<summary><strong>icons-in-terminal — Linux · WSL · macOS · bash</strong></summary>

[sebastiencs/icons-in-terminal](https://github.com/sebastiencs/icons-in-terminal) supplies its own icon font and shell scripts. It does NOT modify `ls` directly — instead it exports 1400+ shell variables (`$oct_git_branch`, `$fa_house`, `$powerline_branch`, …) that you embed in custom scripts and prompts.

**Automatic install:** `install.sh` clones the repo to a temp dir, runs its `./install.sh` (which installs `~/.fonts/icons-in-terminal.ttf`, generates `~/.config/fontconfig/conf.d/30-icons.conf`, copies bash helpers to `~/.local/share/icons-in-terminal/`, and runs `fc-cache`), then cleans up.

Requires `git` and `fc-cache` (fontconfig). On Debian/Ubuntu: `sudo apt install git fontconfig`.

**Auto-detection at shell start:** the `~/.bashrc` block sources `icons_bash.sh` from any of these locations:

```bash
~/.local/share/icons-in-terminal/icons_bash.sh   # default install
~/.icons-in-terminal/icons_bash.sh                # legacy
/usr/local/share/icons-in-terminal/icons_bash.sh  # system-wide
```

If you install icons-in-terminal *after* running `omp-config`'s installer, opening a new terminal picks it up automatically — no reinstall needed.

**Compatible fonts:** the project's `icons-in-terminal.ttf` is installed and registered with `fontconfig` automatically. Configure your terminal to use it as a fallback after your primary Nerd Font.

**Windows / PowerShell:** not supported (the project is Unix-only). Use [Terminal-Icons](#optional-integrations) instead.

</details>

<details>
<summary><strong>Choosing between Nerd Fonts and icons-in-terminal</strong></summary>

You can run both, but typically you pick one as your terminal's primary icon font.

| | Nerd Font (default for `omp-config`) | icons-in-terminal |
|---|---|---|
| Distribution | Single patched font replaces your existing terminal font | Separate icon-only font, set as fallback |
| Required by `omp-config` prompt | Yes — every glyph in the prompt is from Nerd Font ranges | No |
| Pairs with | Terminal-Icons (PowerShell) | Its own `icons_bash.sh` / `icons_zsh.sh` |
| Best when | You want one font that handles everything | You want a different icon set than NF, or already have your editor font set |

The prompt itself (`omp-config` themes) **requires Nerd Font**. `icons-in-terminal` only affects `ls` and similar commands — it never modifies the prompt.

</details>

## How It Works

### Environment-variable driven segments

oh-my-posh themes can't natively shell out to platform-specific commands. To keep the JSON portable, `omp-config` publishes values as environment variables that the theme reads through `{{ .Env.POSH_X }}` templates.

| Variable | Set by | Format (wide) | Format (compact) |
|---|---|---|---|
| `POSH_RAM` | `refresh-stats.{sh,ps1}` | `1.2G/31G (4%)` | `4%` |
| `POSH_CPU` | `refresh-stats.{sh,ps1}` | `0.41 (3%)` | `3%` |
| `POSH_GPU` | `refresh-stats.{sh,ps1}` | `1.2G/4G (30%)` | `30%` |
| `POSH_SPOTIFY` | `refresh-stats.{sh,ps1}` | full title | first 25 chars + `…` |

On bash, `refresh-stats.sh` is appended to `PROMPT_COMMAND`. On PowerShell, the script wraps the `prompt` function (the `Set-PoshContext` hook is not reliably reachable from user scope in PowerShell 7).

### Caching strategy

| Stat | Source | Cache TTL |
|---|---|---|
| GPU | `nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu` | 5 s |
| Spotify | `powershell.exe` (WSL→Win), `osascript` (macOS), `playerctl` (Linux) | 3 s |
| RAM | `/proc/meminfo`, `vm_stat`+`sysctl`, or `Win32_OperatingSystem` (CIM) | none — sub-millisecond |
| CPU | `/proc/loadavg`+`nproc`, `sysctl`, or `Win32_Processor` (CIM) | none — sub-millisecond |

Caches live under `/tmp` (or `%TEMP%` on Windows), keyed by user ID. Formatting is re-derived each prompt from the cached raw values using the current terminal width, so the layout reflows immediately on resize without re-running the slow command.

## Themes

<details>
<summary><strong>Ubuntu palette (<code>ubuntu.omp.json</code>)</strong></summary>

Based on the [Ubuntu brand book](https://design.ubuntu.com/brand/) and the [Yaru GTK theme](https://github.com/ubuntu/yaru).

| Color | Hex | Usage |
|---|---|---|
| Ubuntu Orange | `#E95420` | Primary accent — OS, CPU, status check, prompt arrow, git on clean |
| Canonical Red | `#C7162B` | Errors, low battery, OFFLINE |
| Ubuntu Green | `#0E8420` | Success check, Node runtime |
| Aubergine | `#77216F` | Reserved variations |
| Aubergine Mid | `#5E2750` | Project name, Bun runtime |
| Aubergine Light | `#C25EAD` | GPU icon (high visibility on dark) |
| Aubergine Dark | `#2C001E` | Spotify / IP badge background |
| Warm White | `#F7F7F7` | Username, host |
| Warm Gray | `#C7C2BC` | Path, RAM, time |
| Warm Dim | `#928B85` | Execution time |
| Blue | `#335280` | Python, Go, Docker |

</details>

<details>
<summary><strong>Monochrome (<code>mono.omp.json</code>)</strong></summary>

Grayscale base with color reserved exclusively for warnings.

| Trigger | Color |
|---|---|
| Exit code > 0 | Red |
| Battery ≤ 20% | Red |
| Battery 20–50% | Yellow |
| Git working / staged changes | Yellow |
| Git ahead AND behind (divergence) | Red |
| Background jobs > 0 | Yellow |
| Connection disconnected | Red |
| OMP upgrade available | Yellow |
| Charging | Bright white |

Everything else renders in `#FFFFFF` / `#E0E0E0` / `#A8A8A8` / `#787878` / `#3A3A3A`.

</details>

## Customization

<details>
<summary><strong>Change the active theme on Windows</strong></summary>

Edit `$PROFILE` and replace `ubuntu.omp.json` with `mono.omp.json` in the `$ompTheme` line.

</details>

<details>
<summary><strong>Change the width threshold</strong></summary>

Edit the variable at the top of the stats script:

- bash: `_OMP_WIDTH_FULL=130` in `~/.config/oh-my-posh/refresh-stats.sh`
- PowerShell: `$script:OmpWidthFull = 130` in `%USERPROFILE%\.config\oh-my-posh\refresh-stats.ps1`

</details>

<details>
<summary><strong>Change Spotify-track truncation length</strong></summary>

Inside `_omp_refresh_spotify` (bash) or `_Omp-RefreshSpotify` (PowerShell), the truncation helper is called with `25` as the max length. Adjust to taste.

</details>

<details>
<summary><strong>Swap a Nerd Font icon</strong></summary>

All icons are stored as explicit `\uXXXX` Unicode escapes in the JSON so they survive any source-code editing. Look up the codepoint you want at the [Nerd Fonts cheat sheet](https://www.nerdfonts.com/cheat-sheet) and replace the escape in the appropriate segment's `template`.

</details>

<details>
<summary><strong>Disable a segment</strong></summary>

Set the segment's `template` to `""`, or remove the segment object entirely.

Note: the `connection` segment uses a `{{ if ne .OS "windows" }}` guard. Don't remove it — the field doesn't exist on Windows and the template will error.

</details>

## Troubleshooting

<details>
<summary><strong>Icons appear as boxes, question marks, or invisible spaces</strong></summary>

Your terminal font isn't a Nerd Font (or it's the non-`Mono` variant). Install one of the recommended Nerd Fonts and select it in your terminal application's settings.

</details>

<details>
<summary><strong>PowerShell shows <code>¯£ÿ</code> or similar gibberish where icons should be</strong></summary>

UTF-8 encoding isn't applied. Verify your `$PROFILE` contains the `[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)` line. The installer adds it automatically — if you installed manually, add it at the top of the profile.

</details>

<details>
<summary><strong>The cursor lands on a line below <code>❯</code> instead of next to it</strong></summary>

This was historically caused by right-aligned segments on the prompt line confusing readline. The current layout places `❯` alone on its own line with no right-aligned content. Open a fresh terminal after install. If the issue persists, run `echo "$PS1"` (bash) or `$function:prompt` (PowerShell) and open an issue with the output.

</details>

<details>
<summary><strong>RAM / CPU / GPU values are empty</strong></summary>

The stats refresher isn't running.

- **bash:** check that `echo $PROMPT_COMMAND` ends with `source $HOME/.config/oh-my-posh/refresh-stats.sh`.
- **PowerShell:** verify the prompt was wrapped — `(Get-Command prompt).ScriptBlock.ToString()` should contain `Update-PoshStats`.

</details>

<details>
<summary><strong><code>unable to create text based on template</code> appears in the prompt</strong></summary>

A segment template referenced a field that doesn't exist on the current platform. Open an issue with the platform and a copy of your active theme JSON.

</details>

## Project Structure

```
omp-config/
├── README.md
├── LICENSE                  # MIT
├── .gitignore
├── install/
│   ├── install.sh           # bash installer
│   └── install.ps1          # PowerShell installer
├── scripts/
│   ├── refresh-stats.sh     # stats helper for bash
│   └── refresh-stats.ps1    # stats helper for PowerShell
└── themes/
    ├── ubuntu.omp.json      # Ubuntu brand theme
    └── mono.omp.json        # monochrome theme
```

## Acknowledgements

- [**oh-my-posh**](https://ohmyposh.dev) by [Jan De Dobbeleer](https://github.com/JanDeDobbeleer) — the prompt engine this builds on
- [**Ubuntu brand book**](https://design.ubuntu.com/brand/) and [**Yaru**](https://github.com/ubuntu/yaru) — source of the Ubuntu palette
- [**Nerd Fonts**](https://www.nerdfonts.com) by [Ryan L McIntyre](https://github.com/ryanoasis) — the patched fonts that supply every glyph
- [**Catppuccin Frappé**](https://github.com/catppuccin/catppuccin) — early layout inspiration
- [**ipify**](https://www.ipify.org) — the public IP API used by the fallback badge

## Author

<div align="center">

**Junior Carrillo**
Tech Lead · Open Finance & Payments Expert · AI-Driven Architect
Medellín, Colombia

[Website](https://carrillo.app) ·
[Email](mailto:m@carrillo.app) ·
[GitHub](https://github.com/carrilloapps) ·
[LinkedIn](https://linkedin.com/in/carrilloapps) ·
[X](https://x.com/carrilloapps) ·
[Bluesky](https://bsky.app/profile/carrillo.app)

[Dev.to](https://dev.to/carrilloapps) ·
[Hashnode](https://hashnode.com/@carrilloapps) ·
[Substack](https://carrilloapps.substack.com) ·
[Stack Overflow](https://stackoverflow.com/users/14580648) ·
[YouTube](https://www.youtube.com/channel/UCIwxFli0q78RqlMOgByVe-g)

</div>

## License

Released under the [MIT License](LICENSE).

You are free to use, modify, and redistribute this work in personal and commercial contexts, provided the copyright notice remains intact.
