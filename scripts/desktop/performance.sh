#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091  # Resolved relative to this script at runtime.
source "$SCRIPT_DIR/lib.sh"

desktop_require_safe_home

printf '[performance snapshot]\n'
printf 'mode               single read; no polling or process arguments\n'
printf 'baseline status    invalid while protected or unrelated workloads are active\n'

if [[ -r /proc/loadavg ]]; then
  read -r load_1 load_5 load_15 _ </proc/loadavg
  printf 'load average       %s %s %s\n' "$load_1" "$load_5" "$load_15"
fi

if [[ -r /proc/meminfo ]]; then
  awk '
    /^MemTotal:/ { total = int($2 / 1024) }
    /^MemAvailable:/ { available = int($2 / 1024) }
    END {
      if (total > 0) {
        printf "memory             %d MiB used / %d MiB total\n", total - available, total
      }
    }
  ' /proc/meminfo
fi

printf '\n[desktop process rss]\n'
for process_name in Hyprland noctalia caelestia-shell qs; do
  matches=$(pgrep -x "$process_name" 2>/dev/null || true)
  count=0
  rss_kib=0

  if [[ -n $matches ]]; then
    while IFS= read -r pid; do
      [[ $pid =~ ^[0-9]+$ ]] || continue
      if [[ -r /proc/$pid/status ]]; then
        process_rss=$(awk '/^VmRSS:/ { print $2; exit }' "/proc/$pid/status")
        rss_kib=$((rss_kib + ${process_rss:-0}))
        count=$((count + 1))
      fi
    done <<<"$matches"
  fi

  if ((count > 0)); then
    printf '%-18s count=%d rss=%d MiB\n' "$process_name" "$count" "$((rss_kib / 1024))"
  else
    printf '%-18s unavailable\n' "$process_name"
  fi
done
unset count matches pid process_name process_rss rss_kib

printf '\n[gpu aggregate busy]\n'
shopt -s nullglob
gpu_busy_files=(/sys/class/drm/card*/device/gpu_busy_percent)
if ((${#gpu_busy_files[@]} == 0)); then
  printf 'unavailable\n'
else
  for busy_file in "${gpu_busy_files[@]}"; do
    card_name=${busy_file#/sys/class/drm/}
    card_name=${card_name%%/*}
    if read -r busy_percent <"$busy_file"; then
      printf '%-18s %s%%\n' "$card_name" "$busy_percent"
    fi
  done
fi
unset busy_file busy_percent card_name gpu_busy_files

printf '\nPerformance snapshot complete. No process or system state was changed.\n'
