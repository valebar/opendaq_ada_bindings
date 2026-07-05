#!/usr/bin/env bash
# Refresh the committed copendaq snapshot from an openDAQ build directory.
#
# Usage: scripts/refresh_vendor.sh <opendaq-build-dir>
#
# <opendaq-build-dir> must contain _deps/opendaq-src (the FetchContent checkout)
# and bin/libcopendaq.{dylib,so}. Headers, the exported-symbol list, and the
# VERSION stamp are committed; the lib dir is only a gitignored symlink.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="${1:?usage: refresh_vendor.sh <opendaq-build-dir>}"
build_dir="$(cd "$build_dir" && pwd)"

src="$build_dir/_deps/opendaq-src"
inc="$src/bindings/c/include"
[ -d "$inc" ] || { echo "error: $inc not found" >&2; exit 1; }

lib=""
for cand in "$build_dir/bin/libcopendaq.dylib" "$build_dir/bin/libcopendaq.so"; do
  [ -e "$cand" ] && lib="$cand" && break
done
[ -n "$lib" ] || { echo "error: libcopendaq not found under $build_dir/bin" >&2; exit 1; }

rsync -a --delete "$inc/" "$root/vendor/copendaq/include/"
ln -sfn "$build_dir/bin" "$root/vendor/copendaq/lib"

case "$lib" in
  *.dylib) nm -gU "$lib" ;;
  *)       nm -gD --defined-only "$lib" ;;
esac | awk '{print $3}' | sed 's/^_//' | grep -E '^(daq|DAQ_)' | sort -u \
  > "$root/vendor/copendaq/symbols.txt"

ver="$(cat "$src/opendaq_version" 2>/dev/null || echo unknown)"
sha="$(git -C "$src" rev-parse HEAD 2>/dev/null || echo unknown)"
echo "openDAQ $ver commit $sha" > "$root/vendor/copendaq/VERSION"

echo "vendor refreshed: $(find "$root/vendor/copendaq/include" -name '*.h' | wc -l | tr -d ' ') headers," \
     "$(wc -l < "$root/vendor/copendaq/symbols.txt" | tr -d ' ') exported daq symbols ($ver)"
echo "next: ./daq gen && ./daq build && ./daq check"
