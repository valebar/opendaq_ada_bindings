#!/usr/bin/env bash
# Refresh the committed RTGen JSON interface model (model/*.json).
#
# Usage:
#   scripts/refresh_model.sh --copy MODEL_DIR   # copy the *.json model files from a directory
#   scripts/refresh_model.sh --rtgen            # regenerate with mono + rtgen (not yet wired)
#
# The model is the semantic side of the bindings (out-params, ownership,
# getters/setters, base types); the C headers are the ABI side. Keep both
# refreshed from the same openDAQ version where possible — the generator
# reconciles small skews by skipping model entries with no matching C symbol.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
mode="${1:---copy}"

case "$mode" in
  --copy)
    model_src="${2:?usage: refresh_model.sh --copy MODEL_DIR}"
    [ -d "$model_src" ] || { echo "error: $model_src not found" >&2; exit 1; }
    rm -f "$root/model"/*.json
    cp "$model_src"/*.json "$root/model/"
    echo "RTGen model copied $(date +%Y-%m-%d)" > "$root/model/VERSION"
    echo "model refreshed: $(ls "$root/model"/*.json | wc -l | tr -d ' ') files"
    ;;
  --rtgen)
    # Drive mono + rtgen.exe -v over openDAQ's bindings/c/run_rtgen.sh
    # interface list and drop the JSON here.
    echo "error: --rtgen mode not wired yet; extract the JSON with openDAQ's RTGen and use --copy" >&2
    exit 1
    ;;
  *)
    echo "usage: refresh_model.sh [--copy MODEL_DIR | --rtgen]" >&2
    exit 1
    ;;
esac
