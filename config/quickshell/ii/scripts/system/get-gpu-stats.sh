#!/usr/bin/env bash
set -u

# Outputs key=value lines:
# - gpu_kind (nvidia|amdgpu|intel|unknown|"")
# - gpu_name
# - gpu_util (0..1)
# - gpu_temp_c

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

gpu_kind=""
gpu_name=""
gpu_util=""
gpu_temp_c=""

# Prefer NVIDIA if nvidia-smi exists
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

kv "gpu_kind" "${gpu_kind}"
kv "gpu_name" "${gpu_name}"
kv "gpu_util" "${gpu_util}"
kv "gpu_temp_c" "${gpu_temp_c}"

