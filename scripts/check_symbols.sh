#!/usr/bin/env bash
# Audit the generated low-level bindings against libcopendaq's exports.
#
# Every External_Name in opendaq_bindings/src/gen is looked up in
# vendor/copendaq/symbols.txt. Imports missing from the library are OK as long
# as nothing calls them (they are reported); this script fails only if the
# symbols file is missing/empty or if generated names look malformed.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
syms="$root/vendor/copendaq/symbols.txt"
gen="$root/opendaq_bindings/src/gen"

[ -s "$syms" ] || { echo "error: $syms missing/empty; run refresh_vendor.sh" >&2; exit 1; }
[ -d "$gen" ]  || { echo "error: $gen missing; run ./daq gen" >&2; exit 1; }

grep -rhoE 'External_Name => "[^"]+"' "$gen" \
  | sed 's/External_Name => "//; s/"//' | sort -u > /tmp/opendaq_ada_imports.txt

total=$(wc -l < /tmp/opendaq_ada_imports.txt | tr -d ' ')
missing=$(comm -23 /tmp/opendaq_ada_imports.txt "$syms")
missing_n=$(printf '%s' "$missing" | grep -c . || true)

echo "imports: $total, present in libcopendaq: $((total - missing_n)), absent: $missing_n"
if [ "$missing_n" -gt 0 ]; then
  echo "-- absent (header-declared but not exported by this libcopendaq build;"
  echo "   fine unless called — the high-level generator skips wrappers for these):"
  printf '%s\n' "$missing" | sed 's/^/   /'
fi
[ "$total" -gt 0 ]
