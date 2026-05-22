#!/usr/bin/env bash
# Cross-platform stats source for oh-my-posh prompt.
# Exports POSH_GPU, POSH_CPU, POSH_RAM, POSH_SPOTIFY with adaptive formatting
# based on terminal width and file-based caching for slow lookups.

_omp_platform() {
    case "$OSTYPE" in
        darwin*)   echo macos; return ;;
        linux*)    : ;;
        *)         echo unknown; return ;;
    esac
    if [ -r /proc/version ] && grep -qi microsoft /proc/version 2>/dev/null; then
        echo wsl
    else
        echo linux
    fi
}

_omp_mtime() {
    stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0
}

# Width threshold: at >= this many columns, show absolute+percent.
# Below, switch to compact percent-only.
_OMP_WIDTH_FULL=130

_omp_width() {
    # $COLUMNS updates on SIGWINCH in bash; tput is the portable fallback
    if [ -n "$COLUMNS" ] && [ "$COLUMNS" -gt 0 ] 2>/dev/null; then
        echo "$COLUMNS"
    else
        tput cols 2>/dev/null || echo 120
    fi
}

_omp_is_full() {
    [ "$(_omp_width)" -ge "$_OMP_WIDTH_FULL" ]
}

# Spotify track truncation (compact mode shrinks long titles)
_omp_truncate() {
    local s=$1 max=$2
    if [ "${#s}" -gt "$max" ]; then
        printf '%s' "${s:0:$((max-1))}…"
    else
        printf '%s' "$s"
    fi
}

_omp_refresh_gpu() {
    local cache="/tmp/.posh_gpu_${UID:-$(id -u)}"
    local ttl=5 now mtime raw=""
    now=$(date +%s)
    if [ -f "$cache" ]; then
        mtime=$(_omp_mtime "$cache")
        [ $((now - mtime)) -lt $ttl ] && raw=$(cat "$cache")
    fi
    if [ -z "$raw" ]; then
        local smi=""
        case "$(_omp_platform)" in
            wsl)   [ -x /usr/lib/wsl/lib/nvidia-smi ] && smi=/usr/lib/wsl/lib/nvidia-smi ;;
            linux) command -v nvidia-smi >/dev/null 2>&1 && smi=nvidia-smi ;;
            macos) : ;;
        esac
        if [ -n "$smi" ]; then
            raw=$("$smi" --query-gpu=memory.used,memory.total,utilization.gpu \
                         --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
            printf '%s' "$raw" > "$cache"
        fi
    fi
    local val="" full=$(_omp_is_full && echo 1 || echo 0)
    if [ -n "$raw" ]; then
        val=$(awk -F',' -v r="$raw" -v f="$full" 'BEGIN{
            split(r, a, ",");
            used_mb=a[1]+0; total_mb=a[2]+0; util=a[3]+0;
            if (total_mb > 0) {
                if (f == 1) printf "%.1fG/%.0fG (%d%%)", used_mb/1024, total_mb/1024, util;
                else        printf "%d%%", util;
            }
        }')
    fi
    export POSH_GPU="$val"
}

_omp_refresh_cpu() {
    local load1 cores util_pct val=""
    case "$(_omp_platform)" in
        macos)
            load1=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')
            cores=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
            ;;
        *)
            load1=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
            cores=$(nproc 2>/dev/null || echo 1)
            ;;
    esac
    if [ -n "$load1" ] && [ -n "$cores" ]; then
        util_pct=$(awk -v l="$load1" -v c="$cores" 'BEGIN{
            if (c > 0) { p = l*100/c; if (p > 100) p = 100; printf "%.0f", p }
            else print 0
        }')
        if _omp_is_full; then
            val="${load1} (${util_pct}%)"
        else
            val="${util_pct}%"
        fi
    fi
    export POSH_CPU="$val"
}

_omp_refresh_ram() {
    local val=""
    case "$(_omp_platform)" in
        macos)
            local total_b page_size pages_free pages_inactive pages_speculative
            total_b=$(sysctl -n hw.memsize 2>/dev/null)
            page_size=$(sysctl -n hw.pagesize 2>/dev/null)
            if [ -n "$total_b" ] && [ -n "$page_size" ]; then
                local vm_stat_out
                vm_stat_out=$(vm_stat 2>/dev/null)
                pages_free=$(echo "$vm_stat_out" | awk '/Pages free/{gsub(/\./,"",$3); print $3}')
                pages_inactive=$(echo "$vm_stat_out" | awk '/Pages inactive/{gsub(/\./,"",$3); print $3}')
                pages_speculative=$(echo "$vm_stat_out" | awk '/Pages speculative/{gsub(/\./,"",$3); print $3}')
                local avail_b=$(( (pages_free + pages_inactive + pages_speculative) * page_size ))
                local full=$(_omp_is_full && echo 1 || echo 0)
                val=$(awk -v t="$total_b" -v a="$avail_b" -v f="$full" 'BEGIN{
                    if (t > 0) {
                        if (f == 1) printf "%.1fG/%.0fG (%.0f%%)", (t-a)/1073741824, t/1073741824, (t-a)*100/t;
                        else        printf "%.0f%%", (t-a)*100/t;
                    }
                }')
            fi
            ;;
        *)
            if [ -r /proc/meminfo ]; then
                local full=$(_omp_is_full && echo 1 || echo 0)
                val=$(awk -v f="$full" '
                    /^MemTotal:/     {t=$2}
                    /^MemAvailable:/ {a=$2}
                    END             {
                        if (t > 0) {
                            if (f == 1) printf "%.1fG/%.0fG (%.0f%%)", (t-a)/1048576, t/1048576, (t-a)*100/t;
                            else        printf "%.0f%%", (t-a)*100/t;
                        }
                    }
                ' /proc/meminfo)
            fi
            ;;
    esac
    export POSH_RAM="$val"
}

_omp_refresh_spotify() {
    local cache="/tmp/.posh_spotify_${UID:-$(id -u)}"
    local ttl=3 now mtime val=""
    now=$(date +%s)
    if [ -f "$cache" ]; then
        mtime=$(_omp_mtime "$cache")
        if [ $((now - mtime)) -lt $ttl ]; then
            val=$(cat "$cache")
            # Apply current-width truncation and return
            if [ -n "$val" ] && ! _omp_is_full; then
                val=$(_omp_truncate "$val" 25)
            fi
            export POSH_SPOTIFY="$val"
            return
        fi
    fi
    case "$(_omp_platform)" in
        wsl)
            if command -v powershell.exe >/dev/null 2>&1; then
                local title
                title=$(powershell.exe -NoProfile -Command "(Get-Process Spotify -ErrorAction SilentlyContinue | Where-Object { \$_.MainWindowTitle -and \$_.MainWindowTitle -ne 'Spotify Premium' -and \$_.MainWindowTitle -ne 'Spotify Free' } | Select-Object -First 1).MainWindowTitle" 2>/dev/null | tr -d '\r\n')
                [ -n "$title" ] && val="$title"
            fi
            ;;
        macos)
            if osascript -e 'application "Spotify" is running' 2>/dev/null | grep -q true; then
                local state track artist
                state=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)
                if [ "$state" = "playing" ]; then
                    track=$(osascript -e 'tell application "Spotify" to name of current track' 2>/dev/null)
                    artist=$(osascript -e 'tell application "Spotify" to artist of current track' 2>/dev/null)
                    [ -n "$track" ] && val="$artist - $track"
                fi
            fi
            ;;
        linux)
            if command -v playerctl >/dev/null 2>&1; then
                local status
                status=$(playerctl --player=spotify status 2>/dev/null)
                if [ "$status" = "Playing" ]; then
                    val=$(playerctl --player=spotify metadata --format '{{artist}} - {{title}}' 2>/dev/null)
                fi
            fi
            ;;
    esac
    printf '%s' "$val" > "$cache"
    # Truncate in compact mode so the badge doesn't push other segments around
    if [ -n "$val" ] && ! _omp_is_full; then
        val=$(_omp_truncate "$val" 25)
    fi
    export POSH_SPOTIFY="$val"
}

_omp_refresh_gpu
_omp_refresh_cpu
_omp_refresh_ram
_omp_refresh_spotify
