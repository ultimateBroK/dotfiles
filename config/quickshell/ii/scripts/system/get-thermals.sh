#!/usr/bin/env bash
set -u

# Outputs simple key=value lines for quick parsing in QML.
# Keys:
# - cpu_temp_c
# - gpu_kind (nvidia|amdgpu|intel|unknown|"")
# - gpu_name
# - gpu_util (0..1)
# - gpu_temp_c

trim() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }
kv() { printf '%s=%s\n' "$1" "$2"; }

cpu_temp_c=""
gpu_kind=""
gpu_name=""
gpu_util=""
gpu_temp_c=""

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

# ---- CPU temp (best effort) ----
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

# ---- GPU (prefer NVIDIA if available) ----
if command -v nvidia-smi >/dev/null 2>&1; then
  name="$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n1 | trim)"
  if [[ -n "$name" ]]; then
    gpu_kind="nvidia"
    gpu_name="$name"
    util="$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -dc '0-9.')"
    temp="$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -dc '0-9.')"
    if [[ -n "$util" ]]; then
      gpu_util="$(awk -v u="$util" 'BEGIN{printf "%.3f", u/100}')"
    fi
    if [[ -n "$temp" ]]; then
      gpu_temp_c="$temp"
    fi
  fi
fi

if [[ -z "$gpu_kind" ]]; then
  # AMD (amdgpu): gpu_busy_percent + hwmon temp
  for f in /sys/class/drm/card*/device/gpu_busy_percent; do
    [[ -r "$f" ]] || continue
    gpu_kind="amdgpu"
    util="$(tr -dc '0-9' <"$f" | head -c 8)"
    if [[ -n "$util" ]]; then
      gpu_util="$(awk -v u="$util" 'BEGIN{printf "%.3f", u/100}')"
    fi
    card_dir="${f%/device/gpu_busy_percent}"
    for t in "$card_dir"/device/hwmon/hwmon*/temp1_input; do
      if gpu_temp_c="$(read_temp_millic "$t")"; then
        break
      fi
    done
    break
  done
fi

if [[ -z "$gpu_kind" ]]; then
  # Intel (i915): gt_busy_percent (newer kernels) + hwmon temp (if exposed)
  for f in /sys/class/drm/card*/gt_busy_percent; do
    [[ -r "$f" ]] || continue
    gpu_kind="intel"
    util="$(tr -dc '0-9' <"$f" | head -c 8)"
    if [[ -n "$util" ]]; then
      gpu_util="$(awk -v u="$util" 'BEGIN{printf "%.3f", u/100}')"
    fi
    card_dir="${f%/gt_busy_percent}"
    for t in "$card_dir"/device/hwmon/hwmon*/temp1_input; do
      if gpu_temp_c="$(read_temp_millic "$t")"; then
        break
      fi
    done
    break
  done
fi

kv "cpu_temp_c" "${cpu_temp_c}"
kv "gpu_kind" "${gpu_kind}"
kv "gpu_name" "${gpu_name}"
kv "gpu_util" "${gpu_util}"
kv "gpu_temp_c" "${gpu_temp_c}"

