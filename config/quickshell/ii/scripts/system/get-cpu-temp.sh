#!/usr/bin/env bash
set -u

# Outputs: cpu_temp_c=<value>

trim() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }
kv() { printf '%s=%s\n' "$1" "$2"; }

read_temp_millic() {
  local path="$1"
  [[ -r "$path" ]] || return 1
  local v
  v="$(tr -dc '0-9' <"$path" | head -c 16)"
  [[ -n "$v" ]] || return 1
  awk -v v="$v" 'BEGIN{printf "%.1f", v/1000}'
}

pick_hwmon_temp() {
  # Args: hwmon_dir, preferred_label_regex (optional)
  local d="$1"
  local pref="${2:-}"
  local lab inp l

  if [[ -n "$pref" ]]; then
    for lab in "$d"/temp*_label; do
      [[ -r "$lab" ]] || continue
      l="$(cat "$lab" 2>/dev/null | trim)"
      [[ "$l" =~ $pref ]] || continue
      inp="${lab%_label}_input"
      read_temp_millic "$inp" && return 0
    done
  fi

  for inp in "$d"/temp*_input; do
    read_temp_millic "$inp" && return 0
  done
  return 1
}

cpu_temp_c=""

# Prefer common CPU hwmon names first
for want in k10temp coretemp zenpower; do
  for d in /sys/class/hwmon/hwmon*; do
    [[ -r "$d/name" ]] || continue
    [[ "$(cat "$d/name" 2>/dev/null | trim)" == "$want" ]] || continue
    if cpu_temp_c="$(pick_hwmon_temp "$d" 'Tctl|Package|CPU')"; then
      break 2
    fi
  done
done

# Fallback: try any hwmon with CPU-ish labels
if [[ -z "$cpu_temp_c" ]]; then
  for d in /sys/class/hwmon/hwmon*; do
    [[ -d "$d" ]] || continue
    if cpu_temp_c="$(pick_hwmon_temp "$d" 'Tctl|Package|CPU')"; then
      break
    fi
  done
fi

kv "cpu_temp_c" "${cpu_temp_c}"

