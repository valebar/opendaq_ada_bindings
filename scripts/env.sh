# Resolves the openDAQ library directory for building and running.
# Source this; it exports COPENDAQ_LIB_DIR (and errors if none can be found).
#
# Precedence:
#   1. COPENDAQ_LIB_DIR already set in the environment
#   2. the vendor/copendaq/lib symlink (maintained by scripts/refresh_vendor.sh)

_repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -z "${COPENDAQ_LIB_DIR:-}" ]; then
  if [ -e "$_repo_root/vendor/copendaq/lib" ]; then
    COPENDAQ_LIB_DIR="$(cd "$_repo_root/vendor/copendaq/lib" && pwd)"
  fi
fi

if [ -z "${COPENDAQ_LIB_DIR:-}" ]; then
  echo "error: cannot locate libcopendaq; run scripts/refresh_vendor.sh <opendaq-build-dir>" >&2
  return 1 2>/dev/null || exit 1
fi

export COPENDAQ_LIB_DIR
