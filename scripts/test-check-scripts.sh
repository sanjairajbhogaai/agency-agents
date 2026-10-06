#!/usr/bin/env bash
# Unit tests for consistency and validation scripts in scripts/check-*.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

# --- 1. Test check-divisions.sh ---
echo "Testing check-divisions.sh on valid repo..."
"$SCRIPT_DIR/check-divisions.sh" > /dev/null || fail "check-divisions.sh failed on valid repository"

# --- 2. Test check-tools.sh ---
echo "Testing check-tools.sh on valid repo..."
"$SCRIPT_DIR/check-tools.sh" > /dev/null || fail "check-tools.sh failed on valid repository"

# --- 3. Test check-runbooks.sh ---
echo "Testing check-runbooks.sh on valid repo..."
"$SCRIPT_DIR/check-runbooks.sh" > /dev/null || fail "check-runbooks.sh failed on valid repository"

# --- 4. Test check-agent-originality.sh ---
echo "Testing check-agent-originality.sh on a real agent..."
"$SCRIPT_DIR/check-agent-originality.sh" "$REPO_ROOT/engineering/engineering-frontend-developer.md" > /dev/null || fail "check-agent-originality.sh failed on real agent"

# --- 5. Test check-agent-originality.sh failure on synthetic duplicate ---
tmp="$(mktemp -d "${TMPDIR:-/tmp}/agency-test-check-scripts.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

cp "$REPO_ROOT/engineering/engineering-frontend-developer.md" "$tmp/dup-frontend.md"
# Run originality check on candidate that is an exact copy of existing agent
if ORIGINALITY_FAIL=10 "$SCRIPT_DIR/check-agent-originality.sh" "$tmp/dup-frontend.md" > /dev/null 2>&1; then
  fail "check-agent-originality.sh passed on exact duplicate agent file"
fi

echo "PASS: check scripts tested successfully"
