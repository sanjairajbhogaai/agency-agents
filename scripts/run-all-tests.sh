#!/usr/bin/env bash
#
# run-all-tests.sh — Unified test runner executing all unit and integration
# test suites in scripts/.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

failures=0
total=0

run_test() {
  local name="$1"
  shift
  total=$((total + 1))
  echo "=== Running $name ==="
  if "$@"; then
    echo "[OK] $name"
  else
    echo "[FAIL] $name"
    failures=$((failures + 1))
  fi
  echo ""
}

# 1. Shell unit and integration tests
for test_script in "$SCRIPT_DIR"/test-*.sh; do
  [[ -x "$test_script" || -f "$test_script" ]] || continue
  # Skip convert-outputs test if explicitly requested in fast mode, but default run it
  run_test "$(basename "$test_script")" bash "$test_script"
done

# 2. Python unit and regression tests
run_test "test-hermes-plugin.py" pytest "$SCRIPT_DIR/test-hermes-plugin.py"
run_test "check-hermes-config-rewrite.py" python3 "$SCRIPT_DIR/check-hermes-config-rewrite.py"

# 3. Repository consistency checks
run_test "check-divisions.sh" "$SCRIPT_DIR/check-divisions.sh"
run_test "check-tools.sh" "$SCRIPT_DIR/check-tools.sh"
run_test "check-runbooks.sh" "$SCRIPT_DIR/check-runbooks.sh"

echo "=================================================="
if [[ $failures -gt 0 ]]; then
  echo "FAILED: $failures / $total test suite(s) failed."
  exit 1
else
  echo "PASSED: All $total test suite(s) completed successfully."
  exit 0
fi
