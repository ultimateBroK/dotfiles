#!/usr/bin/env bash
# Workspace switch/move helper (multi-monitor aware: Super+1 on ws 15 → ws 11).
#
# Hyprland 0.55+ Lua config: legacy `hyprctl dispatch workspace N` is broken
# (parsed as Lua). Use `hyprctl dispatch 'hl.dsp....'`.

curr_workspace="$(hyprctl activeworkspace -j | jq -r ".id")"
dispatcher="$1"
shift ## The target is now in $1, not $2

if [[ -z "${dispatcher}" || "${dispatcher}" == "--help" || "${dispatcher}" == "-h" || -z "$1" ]]; then
  echo "Usage: $0 <dispatcher> <target>"
  exit 1
fi

# Resolve relative / absolute workspace target (same logic as before)
if [[ "$1" == *"+"* || "$1" == *"-"* ]]; then
  target="$1"
elif [[ "$1" =~ ^[0-9]+$ ]]; then
  target=$((((curr_workspace - 1) / 10 ) * 10 + $1))
else
  target="$1"
fi

# Quote string targets for Lua (numbers stay bare)
lua_ws() {
  local t="$1"
  if [[ "$t" =~ ^-?[0-9]+$ ]]; then
    printf '%s' "$t"
  else
    # escape backslashes and quotes for Lua string
    t="${t//\\/\\\\}"
    t="${t//\"/\\\"}"
    printf '"%s"' "$t"
  fi
}

ws_lit="$(lua_ws "$target")"

case "$dispatcher" in
  workspace)
    hyprctl dispatch "hl.dsp.focus({ workspace = ${ws_lit} })"
    ;;
  movetoworkspacesilent)
    hyprctl dispatch "hl.dsp.window.move({ workspace = ${ws_lit}, silent = true })"
    ;;
  movetoworkspace)
    hyprctl dispatch "hl.dsp.window.move({ workspace = ${ws_lit} })"
    ;;
  *)
    # Best-effort fallback for other dispatchers (may fail on pure-Lua sessions)
    hyprctl dispatch "${dispatcher}" "${target}"
    exit $?
    ;;
esac
