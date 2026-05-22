#!/usr/bin/env bash
# omp-config installer for bash on Linux, WSL, and macOS.
# - Copies themes and refresh-stats.sh into ~/.config/oh-my-posh
# - Inserts an idempotent block into ~/.bashrc that picks a theme by distro
# - Auto-detects oh-my-posh binary across common install paths

set -euo pipefail

CONF="$HOME/.config/oh-my-posh"
THEMES="$CONF/themes"
BASHRC="$HOME/.bashrc"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

START_MARKER="# >>> omp-config >>>"
END_MARKER="# <<< omp-config <<<"

mkdir -p "$THEMES"
cp "$REPO_ROOT/themes/ubuntu.omp.json"  "$THEMES/ubuntu.omp.json"
cp "$REPO_ROOT/themes/mono.omp.json"    "$THEMES/mono.omp.json"
cp "$REPO_ROOT/scripts/refresh-stats.sh" "$CONF/refresh-stats.sh"
chmod +x "$CONF/refresh-stats.sh"
echo "Installed themes + refresh-stats.sh under $CONF"

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

# Optional: icons-in-terminal (sebastiencs/icons-in-terminal) — adds file/folder
# icon glyphs to ls and other tools. Sourced only when its bash integration is
# present. Install instructions: https://github.com/sebastiencs/icons-in-terminal
for _iit_candidate in \
    "$HOME/.local/share/icons-in-terminal/icons_bash.sh" \
    "$HOME/.icons-in-terminal/icons_bash.sh" \
    "/usr/local/share/icons-in-terminal/icons_bash.sh"; do
    if [ -r "$_iit_candidate" ]; then . "$_iit_candidate"; break; fi
done
unset _iit_candidate
# <<< omp-config <<<
EOF
)

# Idempotent block injection
if grep -q "$START_MARKER" "$BASHRC" 2>/dev/null; then
    # Already present — rewrite between markers
    awk -v start="$START_MARKER" -v end="$END_MARKER" -v block="$block" '
        $0==start {print block; skip=1; next}
        $0==end   {skip=0; next}
        !skip     {print}
    ' "$BASHRC" > "$BASHRC.tmp" && mv "$BASHRC.tmp" "$BASHRC"
    echo "Updated existing omp-config block in $BASHRC"
else
    printf '\n%s\n' "$block" >> "$BASHRC"
    echo "Appended omp-config block to $BASHRC"
fi

echo
echo "Done. Open a new terminal or run: source ~/.bashrc"
echo "Requires: oh-my-posh, a Nerd Font configured in your terminal."
