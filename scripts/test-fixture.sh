#!/usr/bin/env bash
# scripts/test-fixture.sh — backup, bootstrap, and rubric-check a fresh paper folder
set -euo pipefail

# === Config ===
VAULT_ROOT="${VAULT_ROOT:-/home/hahuy/Documents/obs-vault}"
REPO_ROOT="${REPO_ROOT:-/home/hahuy/Documents/github/ics-agents}"
PAPER_ID="s41534-021-00368-4"
TEST_DIR_NAME="${PAPER_ID}-2nd"
SOURCE_DIR="${VAULT_ROOT}/Research/papers/${PAPER_ID}"
TEST_DIR="${VAULT_ROOT}/Research/papers/${TEST_DIR_NAME}"
BACKUP_DIR=""
ICS_BINARY="${HOME}/Documents/github/ics-cli/target/debug/ics"
SKIP_MCP=false

# === Parse flags ===
for arg in "$@"; do
  case $arg in
    --skip-mcp) SKIP_MCP=true ;;
    *) ;;
  esac
done

# === Helpers ===
log() { echo "[test-fixture] $*"; }
fail() { echo "[test-fixture] ERROR: $*" >&2; exit 2; }

timestamp() { date +%Y%m%d%H%M%S; }

render_template() {
  local tpl="$1"; local out="$2"
  sed -e "s/{{paper_id}}/${PAPER_ID}/g" \
      -e "s/{{pdf_rel_path}}/${PAPER_ID}.pdf/g" \
      -e "s/{{title_guess}}/PLACEHOLDER_TITLE/g" \
      "$tpl" > "$out"
}

# === Phase 1: Backup ===
if [[ -d "$SOURCE_DIR" ]]; then
  BACKUP_DIR="${SOURCE_DIR}-backup-$(timestamp)"
  log "Backing up $SOURCE_DIR → $BACKUP_DIR"
  cp -r "$SOURCE_DIR" "$BACKUP_DIR"
else
  log "No existing $SOURCE_DIR — no backup needed"
fi

# === Phase 2: Ensure PDF at vault root ===
PDF_AT_ROOT="${VAULT_ROOT}/${PAPER_ID}.pdf"
if [[ -f "$SOURCE_DIR/${PAPER_ID}.pdf" && ! -f "$PDF_AT_ROOT" ]]; then
  log "Copying PDF to vault root: $PDF_AT_ROOT"
  cp "$SOURCE_DIR/${PAPER_ID}.pdf" "$PDF_AT_ROOT"
fi

# === Phase 3: Create fresh test folder ===
log "Creating fresh test folder: $TEST_DIR"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"/eli5 "$TEST_DIR"/gaps

# instruction.md
cp "${REPO_ROOT}/templates/instruction.md" "$TEST_DIR/instruction.md"

# hub.md (rendered template)
render_template "${REPO_ROOT}/templates/hub.md.tpl" "$TEST_DIR/hub.md"

# eli5/01-abstract.md stub with frontmatter
cat > "$TEST_DIR/eli5/01-abstract.md" <<'EOF'
---
paper_id: s41534-021-00368-4
pdf_rel_path: s41534-021-00368-4.pdf
phase: eli5
writer: claude
---
# ELI5: Abstract

Stub — content pending.
EOF

# gap stubs
for stub in assumptions not-tested future-work fragility; do
  cat > "$TEST_DIR/gaps/${stub}.md" <<EOF
---
paper_id: s41534-021-00368-4
pdf_rel_path: s41534-021-00368-4.pdf
phase: gaps
writer: claude
---
# ${stub^}

Stub — content pending.
EOF
done

log "Test folder created with stubs"

# === Phase 4: ICS bootstrap ===
if [[ -x "$ICS_BINARY" ]]; then
  log "Running ics init + commit for bootstrap"
  cd "$VAULT_ROOT"
  "$ICS_BINARY" init 2>/dev/null || true
  "$ICS_BINARY" commit -m "[ics-bot][research][${PAPER_ID}][bootstrap] initial stubs" 2>/dev/null || true
else
  log "ics binary not found at $ICS_BINARY — skipping ICS commands"
fi

# === Phase 5: Run ics commit after stubs ===
if [[ -x "$ICS_BINARY" ]]; then
  log "Running ics commit after stubs"
  cd "$VAULT_ROOT"
  "$ICS_BINARY" commit -m "[ics-bot][research][${PAPER_ID}][stubs] eli5 + gaps stubs" 2>/dev/null || true
fi

# === Phase 6: Inline rubric check ===
cd "$REPO_ROOT"

PASSES=()
FAILS=()
WARNINGS=()

# --- orientation ---
orient_fail=""
if grep -q "PLACEHOLDER_TITLE" "$TEST_DIR/hub.md"; then
  orient_fail="title_guess is PLACEHOLDER_TITLE"
fi
# Check if ## Why we care has real content (not just placeholder text)
# The template produces a bullet with "1–3 bullets" or "do not leave empty" as placeholder
why_we_care_content=$(grep -A 5 "## Why we care" "$TEST_DIR/hub.md" | grep -v "^$" | grep -v "## Why we care" | grep -v "1–3 bullets" | grep -v "do not leave empty" | grep -v "PLACEHOLDER" | wc -l)
if (( why_we_care_content == 0 )); then
  orient_fail="${orient_fail:+$orient_fail; }## Why we care is empty"
fi
phase_count=$(grep -c -e "^- \[" "$TEST_DIR/hub.md" || true)
if (( phase_count < 4 )); then
  orient_fail="${orient_fail:+$orient_fail; }fewer than 4 phase checklist items (found $phase_count)"
fi

if [[ -n "$orient_fail" ]]; then
  FAILS+=("orientation|BLOCKER|${orient_fail}")
else
  PASSES+=("orientation|PASS|")
fi

# --- rules_clarity ---
if [[ ! -s "$TEST_DIR/instruction.md" ]]; then
  FAILS+=("rules_clarity|BLOCKER|instruction.md missing or empty")
else
  PASSES+=("rules_clarity|PASS|")
fi

# --- friction ---
if ! grep -q "\[\[" "$TEST_DIR/hub.md"; then
  WARNINGS+=("friction|no wikilinks in hub.md")
else
  PASSES+=("friction|PASS|")
fi

# --- gaps_visibility ---
if ! grep -q "^|" "$TEST_DIR/hub.md"; then
  FAILS+=("gaps_visibility|BLOCKER|no status table in hub.md")
else
  PASSES+=("gaps_visibility|PASS|")
fi

# === Phase 7: Report ===
echo ""
echo "=== Fixture Test Report ==="
echo "Backup:   ${BACKUP_DIR:-none}"
echo "Test dir: $TEST_DIR"
echo ""

echo ""
for entry in "${PASSES[@]}"; do
  IFS='|' read -r name result detail <<< "$entry"
  echo "Rubric: ${name}      ${result}${detail:+ — $detail}"
done

for entry in "${FAILS[@]}"; do
  IFS='|' read -r name severity detail <<< "$entry"
  echo "Rubric: ${name}      ${severity} — ${detail}"
done

for entry in "${WARNINGS[@]}"; do
  IFS='|' read -r name detail <<< "$entry"
  echo "Rubric: ${name}      WARN — ${detail}"
done

echo ""
echo "=== BLOCKERs ==="
blocker_count=0
for entry in "${FAILS[@]}"; do
  IFS='|' read -r name severity detail <<< "$entry"
  if [[ "$severity" == "BLOCKER" ]]; then
    blocker_count=$((blocker_count + 1))
    echo "${blocker_count}. [${name}] ${detail}"
    echo "   → Action: Fix ${name} in $TEST_DIR"
  fi
done
if (( blocker_count == 0 )); then
  echo "(none)"
fi

echo ""
echo "=== Warnings ==="
warn_count=0
for entry in "${WARNINGS[@]}"; do
  IFS='|' read -r name detail <<< "$entry"
  warn_count=$((warn_count + 1))
  echo "${warn_count}. [${name}] ${detail}"
done
if (( warn_count == 0 )); then
  echo "(none)"
fi

echo ""
if (( blocker_count > 0 )); then
  echo "=== Outcome: FAIL ==="
  exit 1
else
  echo "=== Outcome: PASS ==="
  exit 0
fi
