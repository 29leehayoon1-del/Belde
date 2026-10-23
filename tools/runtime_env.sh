#!/usr/bin/env bash
# Source this file for workspace-contained Godot development state.
BELDE_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export BELDE_ROOT
export XDG_DATA_HOME="$BELDE_ROOT/.runtime-data"
export XDG_CACHE_HOME="$BELDE_ROOT/.runtime-cache"
export XDG_CONFIG_HOME="$BELDE_ROOT/.runtime-config"
mkdir -p "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"
if [ -d "$BELDE_ROOT/.tools/bin" ]; then
  export PATH="$BELDE_ROOT/.tools/bin:$PATH"
fi
