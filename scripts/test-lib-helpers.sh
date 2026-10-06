#!/usr/bin/env bash
# Unit tests for core functions in scripts/lib.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/agency-test-lib.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }

# --- 1. Test slugify ---
[[ "$(slugify "Frontend Developer")" == "frontend-developer" ]] || fail "slugify simple string failed"
[[ "$(slugify "  AI / Machine  Learning Specialist! ")" == "ai-machine-learning-specialist" ]] || fail "slugify punctuation/spaces failed"
[[ "$(slugify "C++ & Rust Developer")" == "c-rust-developer" ]] || fail "slugify special characters failed"

# --- 2. Test incr ---
count=0
incr count
[[ "$count" -eq 1 ]] || fail "incr 0 failed"
incr count
[[ "$count" -eq 2 ]] || fail "incr 1 failed"

# --- 3. Test get_field ---
cat > "$tmp/agent1.md" <<'EOF'
---
name: Frontend Developer
description: Expert in React and Vue
color: "blue"
quoted_single: 'single quoted'
escaped_quote: "hello \"world\""
folded_description: A very long
  description that continues on
  the next lines.
---

Body content here.
EOF

[[ "$(get_field name "$tmp/agent1.md")" == "Frontend Developer" ]] || fail "get_field name failed"
[[ "$(get_field description "$tmp/agent1.md")" == "Expert in React and Vue" ]] || fail "get_field description failed"
[[ "$(get_field color "$tmp/agent1.md")" == "blue" ]] || fail "get_field double-quoted scalar failed"
[[ "$(get_field quoted_single "$tmp/agent1.md")" == "single quoted" ]] || fail "get_field single-quoted scalar failed"
[[ "$(get_field escaped_quote "$tmp/agent1.md")" == 'hello "world"' ]] || fail "get_field escaped quote failed"
[[ "$(get_field folded_description "$tmp/agent1.md")" == "A very long description that continues on the next lines." ]] || fail "get_field folded scalar failed"

# --- 4. Test agent_slug ---
[[ "$(agent_slug "$tmp/agent1.md")" == "frontend-developer" ]] || fail "agent_slug failed"

# --- 5. Test is_agent_file ---
cat > "$tmp/not_agent.md" <<'EOF'
# Just Markdown
No frontmatter here.
EOF

is_agent_file "$tmp/agent1.md" || fail "is_agent_file returned false for valid agent file"
! is_agent_file "$tmp/not_agent.md" || fail "is_agent_file returned true for non-agent file"
! is_agent_file "$tmp/nonexistent.md" || fail "is_agent_file returned true for missing file"

# --- 6. Test get_body ---
body="$(get_body "$tmp/agent1.md")"
[[ "$body" == *"Body content here."* ]] || fail "get_body missing body content"
[[ "$body" != *"Frontend Developer"* ]] || fail "get_body included frontmatter content"

cat > "$tmp/body_sep.md" <<'EOF'
---
name: Test
---
Header

---

Section after horizontal rule
EOF

sep_body="$(get_body "$tmp/body_sep.md")"
[[ "$sep_body" == *"Section after horizontal rule"* ]] || fail "get_body failed with body separator"

# --- 7. Test fence_open_p and fence_closes_p ---
fence_open_p '```bash' || fail "fence_open_p failed on backticks bash"
fence_open_p '  ~~~python' || fail "fence_open_p failed on indented tildes"
! fence_open_p '    ```' || fail "fence_open_p accepted 4-space indented fence"
! fence_open_p 'some text ```' || fail "fence_open_p accepted fence after text"

fence_open_p '```'
marker="${BASH_REMATCH[2]:0:1}"
len="${#BASH_REMATCH[2]}"
indent="${BASH_REMATCH[1]}"

fence_closes_p '```' "$marker" "$len" "$indent" || fail "fence_closes_p failed on matching backticks"
fence_closes_p '  ```  ' "$marker" "$len" "$indent" || fail "fence_closes_p failed on indented closing backticks"
! fence_closes_p '```python' "$marker" "$len" "$indent" || fail "fence_closes_p accepted text after closer"
! fence_closes_p '~~~' "$marker" "$len" "$indent" || fail "fence_closes_p accepted mismatched marker"

echo "PASS: lib.sh helpers tested successfully"
