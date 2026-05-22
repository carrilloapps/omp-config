#!/usr/bin/env bash
# omp-config installer for bash on Linux, WSL, and macOS.
# - Copies themes and refresh-stats.sh into ~/.config/oh-my-posh
# - Inserts an idempotent block into ~/.bashrc that picks a theme by distro
# - Best-effort auto-install of eza (icons for ls) and icons-in-terminal
#   (sebastiencs/icons-in-terminal). Both are optional — the prompt works
#   without them and the installer never fails because of them.

set -uo pipefail

CONF="$HOME/.config/oh-my-posh"
THEMES="$CONF/themes"
BASHRC="$HOME/.bashrc"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

START_MARKER="# >>> omp-config >>>"
END_MARKER="# <<< omp-config <<<"

# -----------------------------------------------------------------------------
# 1. Theme files + stats script
# -----------------------------------------------------------------------------
mkdir -p "$THEMES"
cp "$REPO_ROOT/themes/ubuntu.omp.json"  "$THEMES/ubuntu.omp.json"
cp "$REPO_ROOT/themes/mono.omp.json"    "$THEMES/mono.omp.json"
cp "$REPO_ROOT/scripts/refresh-stats.sh" "$CONF/refresh-stats.sh"
chmod +x "$CONF/refresh-stats.sh"
echo "[1/4] Installed themes + refresh-stats.sh under $CONF"

# -----------------------------------------------------------------------------
# 2. eza — modern ls with --icons support (uses the same Nerd Font as OMP)
# -----------------------------------------------------------------------------
echo "[2/4] Checking for eza (modern ls with NF icons)..."
if command -v eza >/dev/null 2>&1; then
    echo "      eza already installed: $(eza --version | head -1)"
else
    if command -v brew >/dev/null 2>&1; then
        brew install eza >/dev/null 2>&1 && echo "      Installed eza via brew" \
            || echo "      brew install eza failed; install manually"
    elif command -v apt-get >/dev/null 2>&1; then
        # apt may not have eza on older Ubuntu/Debian
        sudo apt-get install -y eza >/dev/null 2>&1 \
            && echo "      Installed eza via apt" \
            || echo "      eza not in apt repos; install via brew or cargo manually"
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm eza >/dev/null 2>&1 \
            && echo "      Installed eza via pacman" \
            || echo "      pacman install eza failed"
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y eza >/dev/null 2>&1 \
            && echo "      Installed eza via dnf" \
            || echo "      dnf install eza failed"
    elif command -v cargo >/dev/null 2>&1; then
        cargo install eza >/dev/null 2>&1 && echo "      Installed eza via cargo" \
            || echo "      cargo install eza failed"
    else
        echo "      No supported package manager found; install eza manually:"
        echo "        https://github.com/eza-community/eza/blob/main/INSTALL.md"
    fi
fi

# -----------------------------------------------------------------------------
# 3. icons-in-terminal — bash icon variables for scripts and prompts
# -----------------------------------------------------------------------------
echo "[3/4] Checking for icons-in-terminal..."
IIT_BASH="$HOME/.local/share/icons-in-terminal/icons_bash.sh"
if [ -r "$IIT_BASH" ]; then
    echo "      icons-in-terminal already installed at $IIT_BASH"
elif command -v git >/dev/null 2>&1 && command -v fc-cache >/dev/null 2>&1; then
    _iit_tmp=$(mktemp -d) || _iit_tmp=""
    if [ -n "$_iit_tmp" ]; then
        if git clone --depth 1 -q https://github.com/sebastiencs/icons-in-terminal.git \
                "$_iit_tmp/iit" 2>/dev/null; then
            (cd "$_iit_tmp/iit" && ./install.sh >/dev/null 2>&1) \
                && echo "      Installed icons-in-terminal at $HOME/.local/share/icons-in-terminal/" \
                || echo "      icons-in-terminal install script failed; clone manually:"
        else
            echo "      git clone of icons-in-terminal failed; install manually:"
            echo "        https://github.com/sebastiencs/icons-in-terminal"
        fi
        rm -rf "$_iit_tmp"
    fi
else
    echo "      Skipped: requires 'git' and 'fc-cache' (fontconfig). Install them and re-run."
fi

# -----------------------------------------------------------------------------
# 4. Inject idempotent block into ~/.bashrc
# -----------------------------------------------------------------------------
block=$(cat <<'EOF'
# >>> omp-config >>>
# Auto-pick OMP theme: Ubuntu palette for Ubuntu, monochrome for everything else.
_omp_bin=""
for _omp_candidate in \
    "$HOME/.local/bin/oh-my-posh" \
    "/opt/homebrew/bin/oh-my-posh" \
    "/usr/local/bin/oh-my-posh" \
    "/home/linuxbrew/.linuxbrew/bin/oh-my-posh"; do
    if [ -x "$_omp_candidate" ]; then _omp_bin="$_omp_candidate"; break; fi
done
[ -z "$_omp_bin" ] && _omp_bin=$(command -v oh-my-posh 2>/dev/null || true)

_omp_theme="$HOME/.config/oh-my-posh/themes/mono.omp.json"
if [ -r /etc/os-release ]; then
    _omp_distro_id=$(awk -F= '$1=="ID"{gsub(/"/,"",$2); print $2}' /etc/os-release)
    [ "$_omp_distro_id" = "ubuntu" ] && _omp_theme="$HOME/.config/oh-my-posh/themes/ubuntu.omp.json"
    unset _omp_distro_id
fi

if [ -n "$_omp_bin" ] && [ -x "$_omp_bin" ] && [ -r "$_omp_theme" ]; then
    eval "$("$_omp_bin" init bash --config "$_omp_theme")"
    PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND}; }source $HOME/.config/oh-my-posh/refresh-stats.sh"
fi
unset _omp_bin _omp_candidate _omp_theme

# icons-in-terminal (sebastiencs/icons-in-terminal) — exports 1400+ icon vars
for _iit_candidate in \
    "$HOME/.local/share/icons-in-terminal/icons_bash.sh" \
    "$HOME/.icons-in-terminal/icons_bash.sh" \
    "/usr/local/share/icons-in-terminal/icons_bash.sh"; do
    if [ -r "$_iit_candidate" ]; then . "$_iit_candidate"; break; fi
done
unset _iit_candidate

# eza (modern ls with Nerd Font --icons) — replace ls/ll/la/tree when present
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza --icons -la --group-directories-first'
    alias la='eza --icons -a --group-directories-first'
    alias lt='eza --icons --tree --level=2 --group-directories-first'
fi
# <<< omp-config <<<
EOF
)

# Idempotent block injection
if grep -q "$START_MARKER" "$BASHRC" 2>/dev/null; then
    # Rewrite between markers
    awk -v start="$START_MARKER" -v end="$END_MARKER" -v block="$block" '
        $0==start {print block; skip=1; next}
        $0==end   {skip=0; next}
        !skip     {print}
    ' "$BASHRC" > "$BASHRC.tmp" && mv "$BASHRC.tmp" "$BASHRC"
    echo "[4/4] Updated existing omp-config block in $BASHRC"
else
    printf '\n%s\n' "$block" >> "$BASHRC"
    echo "[4/4] Appended omp-config block to $BASHRC"
fi

echo
echo "Done. Open a new terminal or run: source ~/.bashrc"
echo "Requires: oh-my-posh, a Nerd Font configured in your terminal."
