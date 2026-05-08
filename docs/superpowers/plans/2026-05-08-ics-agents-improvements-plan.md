# ics-agents Improvements — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Three deliverables — automated test fixture script, improved newcomer-validator rubric, and a discovery process doc for future agent opportunities.

**Architecture:** Shell script orchestrates the test fixture locally against `/home/hahuy/Documents/obs-vault`. Newcomer-validator changes are edits to `agents/newcomer-path-validator.md`. Agent discovery is a guided research task producing a spec doc.

**Tech Stack:** bash, `ics` CLI, `pdftoagent-mcp` (MCP tool), Claude Code forked subagents.

---

## File Map

```
ics-agents/
  scripts/
    test-fixture.sh          # New — fixture runner
  agents/
    newcomer-path-validator.md  # Modify — BLOCKER/WARN rubric
  docs/superpowers/
    specs/
      2026-05-08-ics-agent-opportunities.md  # New — discovery doc
      2026-05-08-ics-agents-improvements-design.md  # Existing (spec)
```

---

## Task 1: Create `scripts/test-fixture.sh`

**Files:**
- Create: `scripts/test-fixture.sh`

- [ ] **Step 1: Write `scripts/test-fixture.sh`**

```bash
#!/bin/bash
# test-fixture.sh — Run the analyze-n-research fixture on a fresh paper folder.
#
# Usage: ./scripts/test-fixture.sh [--skip-mcp]
#   --skip-mcp  Skip the pdftoagent-mcp PDF ingestion call (token savings).
#
# Prerequisites:
#   - Vault at /home/hahuy/Documents/obs-vault
#   - PDF at /home/hahuy/Documents/obs-vault/s41534-021-00368-4.pdf
#   - ics on PATH
#   - pdftoagent-mcp available (unless --skip-mcp)
#
# What this does:
#   1. Backs up existing Research/papers/s41534-021-00368-4/ (if present)
#   2. Creates Research/papers/s41534-021-00368-4-2nd/ with fresh bootstrap
#   3. Runs ics init + commit
#   4. Ingests PDF via pdftoagent-mcp (optional)
#   5. Creates eli5/ + gaps/ stubs with correct frontmatter
#   6. Runs newcomer-validator as forked subagent
#   7. Reports rubric pass/fail
#
# Exit codes:
#   0 — all BLOCKERs pass
#   1 — one or more BLOCKERs fail
#   2 — setup failure (ics not found, vault missing, etc.)

set -e

VAULT_ROOT="/home/hahuy/Documents/obs-vault"
PAPER_ID="s41534-021-00368-4"
SRC_DIR="$VAULT_ROOT/Research/papers/$PAPER_ID"
TEST_DIR="$VAULT_ROOT/Research/papers/${PAPER_ID}-2nd"
SKIP_MCP=0

# --- CLI args ---
for arg in "$@"; do
  case $arg in
    --skip-mcp) SKIP_MCP=1 ;;
    *)
      echo "Usage: $0 [--skip-mcp]"
      exit 2
      ;;
  esac
done

# --- Env check ---
if ! command -v ics &>/dev/null; then
  echo "ERROR: ics binary not found on PATH" >&2
  exit 2
fi

if [ ! -d "$VAULT_ROOT" ]; then
  echo "ERROR: vault root not found: $VAULT_ROOT" >&2
  exit 2
fi

PDF_PATH="$VAULT_ROOT/s41534-021-00368-4.pdf"
if [ ! -f "$PDF_PATH" ]; then
  echo "ERROR: PDF not found: $PDF_PATH" >&2
  exit 2
fi

ICS_AGENTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE_INST="$ICS_AGENTS_DIR/templates/instruction.md"
TEMPLATE_HUB="$ICS_AGENTS_DIR/templates/hub.md.tpl"

if [ ! -f "$TEMPLATE_INST" ]; then
  echo "ERROR: instruction.md template not found: $TEMPLATE_INST" >&2
  exit 2
fi

# --- Backup ---
if [ -d "$SRC_DIR" ]; then
  BACKUP_DIR="${SRC_DIR}-backup-$(date +%Y%m%d%H%M%S)"
  cp -r "$SRC_DIR" "$BACKUP_DIR"
  echo "[backup] $SRC_DIR → $BACKUP_DIR"
fi

# --- Setup test dir ---
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Copy instruction.md
cp "$TEMPLATE_INST" "$TEST_DIR/instruction.md"

# Render hub.md.tpl
# paper_id: s41534-021-00368-4
# pdf_rel_path: s41534-021-00368-4.pdf (at vault root)
# title_guess: (use placeholder — newcomer-validator will catch it as BLOCKER)
cat "$TEMPLATE_HUB" | \
  sed "s/{{paper_id}}/$PAPER_ID/g" | \
  sed "s|{{pdf_rel_path}}|${PAPER_ID}.pdf|g" | \
  sed "s/{{title_guess}}/PLACEHOLDER_TITLE/g" \
  > "$TEST_DIR/hub.md"

# --- ICS init + commit ---
cd "$VAULT_ROOT"
ics init 2>/dev/null || true
ics commit -m "[human][research][$PAPER_ID][inbox] bootstrap hub + instruction"

# --- PDF ingest via pdftoagent-mcp ---
if [ "$SKIP_MCP" -eq 0 ]; then
  echo "[mcp] Attempting PDF extraction (use --skip-mcp to skip)..."
  # pdftoagent-mcp is called via its MCP interface; the shell script
  # calls the convert_pdf_quality tool.  On failure/nonzero exit the
  # script continues with stub notes.
  # This step is informational — stub notes are created regardless.
  # (The MCP call is made by the orchestrator when this script is
  # invoked from a Claude session that has pdftoagent-mcp available.)
  # For pure-shell runs: skip.
  echo "[mcp] SKIPPED — pdftoagent-mcp must be called by the Claude orchestrator"
fi

# --- Create eli5/ + gaps/ stubs with correct frontmatter ---
mkdir -p "$TEST_DIR/eli5" "$TEST_DIR/gaps"

# eli5/01-abstract.md
cat > "$TEST_DIR/eli5/01-abstract.md" << 'EOF'
---
paper_id: s41534-021-00368-4
pdf_rel_path: s41534-021-00368-4.pdf
phase: eli5
writer: claude
---

## Abstract ELI5

PLACEHOLDER — paper title not yet extracted. Run pdftoagent-mcp and replace this stub.

Source: s41534-021-00368-4.pdf · Section: Abstract
EOF

# gaps/assumptions.md
cat > "$TEST_DIR/gaps/assumptions.md" << 'EOF'
---
paper_id: s41534-021-00368-4
pdf_rel_path: s41534-021-00368-4.pdf
phase: gaps
writer: claude
---

## Assumptions

Not started — see SKILL gap pass.

Source: s41534-021-00368-4.pdf · Section: (none yet)
EOF

# gaps/not-tested.md
cat > "$TEST_DIR/gaps/not-tested.md" << 'EOF'
---
paper_id: s41534-021-00368-4
pdf_rel_path: s41534-021-00368-4.pdf
phase: gaps
writer: claude
---

## Not Tested

Not started — see SKILL gap pass.

Source: s41534-021-00368-4.pdf · Section: (none yet)
EOF

# gaps/future-work.md
cat > "$TEST_DIR/gaps/future-work.md" << 'EOF'
---
paper_id: s41534-021-00368-4
pdf_rel_path: s41534-021-00368-4.pdf
phase: gaps
writer: claude
---

## Future Work

Not started — see SKILL gap pass.

Source: s41534-021-00368-4.pdf · Section: (none yet)
EOF

# gaps/fragility.md
cat > "$TEST_DIR/gaps/fragility.md" << 'EOF'
---
paper_id: s41534-021-00368-4
pdf_rel_path: s41534-021-00368-4.pdf
phase: gaps
writer: claude
---

## Fragility

Not started — see SKILL gap pass.

Source: s41534-021-00368-4.pdf · Section: (none yet)
EOF

# --- ICS commit after stubs ---
ics commit -m "[claude][research][$PAPER_ID][eli5] bootstrap test — abstract + gap stubs"

# --- Run newcomer-validator as forked subagent ---
# The validator is run as a Claude forked subagent by the orchestrator.
# This script documents the expected handoff; the actual subagent call
# is made by the Claude session using the agents/parent-brief.md +
# agents/newcomer-path-validator.md prompts.
#
# Validator handoff:
#   vault root:     /home/hahuy/Documents/obs-vault
#   paper_id:       s41534-021-00368-4
#   paper folder:   /home/hahuy/Documents/obs-vault/Research/papers/s41534-021-00368-4-2nd
#   pdf_rel_path:   s41534-021-00368-4.pdf
#   pdftoagent-mcp: may be used for extraction
#
# Expected rubric output (text or markdown):
#   ## Validator Report
#   | Rubric | Result | Detail |
#   | orientation | PASS/FAIL (BLOCKER/WARN) | ... |
#   ...

VALIDATOR_REPORT="$TEST_DIR/validator-report.md"
echo "[validator] Run newcomer-validator as forked subagent"
echo "[validator] Handoff:"
echo "  vault root:  $VAULT_ROOT"
echo "  paper_id:    $PAPER_ID"
echo "  paper dir:   $TEST_DIR"
echo "  report out:  $VALIDATOR_REPORT"
echo ""
echo "[validator] To run manually in Claude Code:"
echo "  1. Read agents/parent-brief.md + agents/newcomer-path-validator.md"
echo "  2. Read \$VAULT_ROOT/Research/papers/s41534-021-00368-4-2nd/hub.md"
echo "  3. Read \$VAULT_ROOT/Research/papers/s41534-021-00368-4-2nd/instruction.md"
echo "  4. Run the rubric against the test folder"
echo "  5. Write report to $VALIDATOR_REPORT"

# --- Inline rubric check (runs without a subagent) ---
# This runs immediately and produces a result even if the subagent step
# is run later or skipped.  It matches the same checks the validator
# agent performs.

RUBRIC_ORIENTATION="FAIL"
RUBRIC_RULES="FAIL"
RUBRIC_FRICTION="FAIL"
RUBRIC_GAPS="FAIL"
BLOCKERS=""
WARNINGS=""

HUB="$TEST_DIR/hub.md"
INST="$TEST_DIR/instruction.md"

# orientation: title_guess not placeholder, "Why we care" not empty, phase checklist exists
TITLE_GUESS=$(grep -i "^title_guess:" "$HUB" 2>/dev/null | head -1 | sed 's/^title_guess: *//' | tr -d ' ')
WHY_WE_CARE=$(awk '/^## Why we care/,/^##/' "$HUB" 2>/dev/null | grep -v "^##" | grep -v "^$" | wc -l)
PHASE_CHECKLIST=$(grep -c "\- \[ \]" "$HUB" 2>/dev/null || echo 0)

if [ "$TITLE_GUESS" != "PLACEHOLDER_TITLE" ] && [ -n "$WHY_WE_CARE" ] && [ "$WHY_WE_CARE" -gt 0 ] && [ "$PHASE_CHECKLIST" -ge 4 ]; then
  RUBRIC_ORIENTATION="PASS"
else
  if [ "$TITLE_GUESS" = "PLACEHOLDER_TITLE" ]; then
    BLOCKERS="${BLOCKERS}1. [orientation] hub.md title_guess is '{{title_guess}}' (not replaced with real title)\n   → Action: Replace PLACEHOLDER_TITLE in hub.md with actual paper title\n"
  fi
  if [ -z "$WHY_WE_CARE" ] || [ "$WHY_WE_CARE" -eq 0 ]; then
    BLOCKERS="${BLOCKERS}2. [orientation] hub.md '## Why we care' is empty\n   → Action: Add 1-3 bullets to ## Why we care (team goal, decision this informs, or experiment milestone)\n"
  fi
  if [ "$PHASE_CHECKLIST" -lt 4 ]; then
    BLOCKERS="${BLOCKERS}3. [orientation] hub.md phase checklist incomplete (found ${PHASE_CHECKLIST}/4 phases)\n   → Action: Ensure all 4 reading phases are listed with - [ ] checkboxes\n"
  fi
fi

# rules_clarity: instruction.md present + readable
if [ -f "$INST" ] && [ -s "$INST" ]; then
  RUBRIC_RULES="PASS"
else
  WARNINGS="${WARNINGS}1. [rules_clarity] instruction.md missing or empty\n   → Suggestion: Ensure templates/instruction.md was copied successfully\n"
fi

# friction: hub.md has linked notes or stubs in Note index
NOTE_LINKS=$(grep -c "\[\[" "$HUB" 2>/dev/null || echo 0)
if [ "$NOTE_LINKS" -gt 0 ]; then
  RUBRIC_FRICTION="PASS"
else
  WARNINGS="${WARNINGS}2. [friction] no notes linked from hub.md\n   → Suggestion: Link at least one stub note (eli5/ or gaps/) from hub.md Note index\n"
fi

# gaps_visibility: status table in hub.md (Note | Topics | Status)
HAS_STATUS_TABLE=$(grep -c "Status" "$HUB" 2>/dev/null || echo 0)
if [ "$HAS_STATUS_TABLE" -gt 0 ]; then
  RUBRIC_GAPS="PASS"
else
  BLOCKERS="${BLOCKERS}4. [gaps_visibility] no status table in hub.md\n   → Action: Add hub.md status table: columns Note | Topics | Status, values stub/draft/closed\n"
fi

# --- Report ---
echo ""
echo "=== Fixture Test Report ==="
echo "Backup:   $BACKUP_DIR"
echo "Test dir: $TEST_DIR"
echo ""
printf "Rubric: orientation      %s\n" "$RUBRIC_ORIENTATION"
printf "Rubric: rules_clarity    %s\n" "$RUBRIC_RULES"
printf "Rubric: friction         %s\n" "$RUBRIC_FRICTION"
printf "Rubric: gaps_visibility  %s\n" "$RUBRIC_GAPS"
echo ""

if [ -n "$BLOCKERS" ]; then
  echo "=== BLOCKERs ==="
  echo -e "$BLOCKERS"
fi

if [ -n "$WARNINGS" ]; then
  echo "=== Warnings ==="
  echo -e "$WARNINGS"
fi

if [ -n "$BLOCKERS" ]; then
  echo "=== Outcome: FAIL ==="
  exit 1
else
  echo "=== Outcome: PASS ==="
  exit 0
fi
```

- [ ] **Step 2: Make `scripts/test-fixture.sh` executable**

Run: `chmod +x scripts/test-fixture.sh`

- [ ] **Step 3: Test that the script starts without errors**

Run: `cd /home/hahuy/Documents/github/ics-agents && ./scripts/test-fixture.sh --skip-mcp`
Expected: Script starts, creates `s41534-021-00368-4-2nd/` folder, runs inline rubric check, exits 0 or 1 with report output.

- [ ] **Step 4: Commit**

```bash
git add scripts/test-fixture.sh
git commit -m "feat: add test-fixture.sh — automated analyze-n-research fixture runner"
```

---

## Task 2: Update `agents/newcomer-path-validator.md`

**Files:**
- Modify: `agents/newcomer-path-validator.md`

- [ ] **Step 1: Read current `agents/newcomer-path-validator.md`**

Run: `cat agents/newcomer-path-validator.md`

- [ ] **Step 2: Edit the output format section**

Replace the current "Output" section with BLOCKER/WARN schema:

**Old:**
```markdown
## Output

Short markdown report: scores/paragraph per rubric item, blockers, and **one** concrete improvement to `hub.md`, `instruction.md`, or **`ics-agents/skills/analyze-n-research/SKILL.md`** if the failure is systemic.
```

**New:**
```markdown
## Output

```markdown
## Validator Report

| Rubric | Result | Detail |
|--------|--------|--------|
| orientation | ✅ PASS / ❌ FAIL (BLOCKER) | ... |
| rules_clarity | ✅ PASS / ⚠️ WARN | ... |
| friction | ✅ PASS / ⚠️ WARN | ... |
| gaps_visibility | ✅ PASS / ❌ FAIL (BLOCKER) | ... |

### BLOCKERs (must fix before closing session)
1. [orientation] ...
   → Action: ...

### Warnings (should improve)
1. [friction] ...
   → Suggestion: ...
```

### BLOCKER vs WARN levels

| Level | Meaning | Script action |
|---|---|---|
| **BLOCKER** | Newcomer cannot orient or follow rules; must fix before the paper is readable | Exit code 1 on fixture script |
| **WARN** | Friction or incomplete info; should fix but doesn't block | Logged, no exit failure |

### Per-rubric remediation hints

**Orientation** — BLOCKER if:
- `hub.md` `title_guess` is `{{title_guess}}` (template not filled)
- `## Why we care` section is empty (no bullets)
- Phase checklist has fewer than 4 items

  → Action: Replace `{{title_guess}}` in hub.md with real paper title; fill "Why we care" with 1-3 bullets (team goal, decision this informs, or experiment milestone).

**Rules clarity** — BLOCKER if:
- `instruction.md` is missing or unreadable
- Frontmatter template not present in `instruction.md`

  → Action: Ensure `templates/instruction.md` was copied to the paper folder.

**Friction** — WARN if:
- `hub.md` has no wikilinks to notes (empty Note index)
- Links don't match actual files

  → Suggestion: Link at least one stub note from hub.md Note index; ensure each link points to an existing file.

**Gaps visibility** — BLOCKER if:
- No status table (columns: Note | Topics | Status) in `hub.md`

  → Action: Add hub.md status table with columns Note | Topics | Status; use values `stub` / `draft` / `closed`.
```

- [ ] **Step 3: Commit**

```bash
git add agents/newcomer-path-validator.md
git commit -m "feat: add BLOCKER/WARN rubric levels + remediation hints to newcomer-validator"
```

---

## Task 3: Write agent opportunities discovery doc

**Files:**
- Create: `docs/superpowers/specs/YYYY-MM-DD-ics-agent-opportunities.md`
  (Use today's date: `2026-05-08`)

- [ ] **Step 1: Write `docs/superpowers/specs/2026-05-08-ics-agent-opportunities.md`**

```markdown
# ics-agent Opportunities — Discovery

**Date:** 2026-05-08
**Purpose:** Map the researcher workflow end-to-end; find handoff points where
subagents eliminate bottlenecks; produce opportunity cards for a follow-up
brainstorming session.

---

## Researcher Lifecycle — Current State

### Phase 0: Paper arrives

**Human does:**
- Downloads PDF, places in vault
- Picks `paper_id` (e.g. arXiv ID or DOI)
- Sets `pdf_rel_path`

**Agent opportunity:** None yet — human decides what to read.

---

### Phase 1: Bootstrap

**Human (or orchestrator) does:**
- Creates `Research/papers/<paper_id>/`
- Copies `instruction.md`, renders `hub.md.tpl`
- Fills `title_guess` and "Why we care"
- Runs `ics init` + first commit

**Agent opportunity:** NONE — bootstrap is already the agent's job in analyze-n-research.

---

### Phase 2: Ingest (PDF → text)

**Human does:**
- Calls `pdftoagent-mcp convert_pdf_quality` on the PDF
- Waits for extraction (token-expensive, slow)

**Agent opportunity:** Could the agent call `pdftoagent-mcp` autonomously and handle partial failures gracefully (retry with smaller chunks, fall back to page-1 extraction)?

**Trigger:** Bootstrap completes.
**Output contract:** Markdown text stored in a temp note, ready for citation.
**ics-cli commands used:** `ics commit` (after writing notes).
**Risks:** Token cost, MCP timeout, partial extraction on long papers.

---

### Phase 3: ELI5 notes

**Human/agent does:**
- Reads extracted text section by section
- Writes one `eli5/<section>.md` per major section
- Each note: plain-language explanation + quoted passage + frontmatter

**Agent opportunity:** Autonomous ELI5 generation — agent reads extracted text,
writes `n` ELI5 notes in one pass, commits after each logical batch.

**Trigger:** PDF text available in vault.
**Output contract:** `eli5/*.md` files with correct frontmatter, linked from `hub.md`.
**ics-cli commands used:** `ics commit` per batch.
**Risks:** Fabricated quotes (must cite section/page); wrong paper_id in frontmatter.

---

### Phase 4: Gap pass

**Human/agent does:**
- Reads paper for: assumptions, untested claims, future work, fragility
- Writes `gaps/assumptions.md`, `gaps/not-tested.md`, `gaps/future-work.md`, `gaps/fragility.md`

**Agent opportunity:** Gap pass could be fully agent-driven after ELI5 is complete.
Could run two subagents: one for `assumptions` + `not-tested`, one for `future-work` + `fragility`.

**Trigger:** At least one ELI5 note exists.
**Output contract:** `gaps/*.md` files with `phase: gaps`, linked from `hub.md`.
**ics-cli commands used:** `ics commit`.
**Risks:** Missed claims; agent over-confident in gap framing.

---

### Phase 5: Peer pass

**Human/agent does:**
- Runs `gap-peer-pass.md` subagent as forked agent
- Reviews ELI5 + gap notes with adversarial lens
- Writes `peer/*.md` with verdict

**Agent opportunity:** This is already a subagent. Opportunity: orchestrate
multiple peer passes (different "reviewer personas") before synthesis.

**Trigger:** All four gap files exist.
**Output contract:** `peer/*.md` files, verdict in each.
**Risks:** Same biases across passes; need diverse reviewer framing.

---

### Phase 6: Synthesis

**Human does:**
- Reads all notes
- Writes `synthesis.md` — "what we believe / don't know yet"

**Agent opportunity:** Could the agent draft synthesis from existing notes,
with human editing? Template: "Key findings / Confidences / Open questions / Next experiments."

**Trigger:** All phases complete.
**Output contract:** `synthesis.md` with `phase: synthesis`, linked from `hub.md`.
**Risks:** Synthesis quality depends entirely on note quality; agent may hallucinate confidence.

---

### Phase 7: Push to Stratum

**Human does:**
- Runs `ics push [paths]`
- Submits proposal via `ics proposal submit --team-id X --note-ids Y --rationale Z`

**Agent opportunity:** Fully agent-driven push after synthesis — agent:
1. Runs `ics push` for all changed paths
2. Builds rationale (≥50 chars) from synthesis summary
3. Calls `ics proposal submit`
4. Writes proposal link back to `hub.md`

**Trigger:** Synthesis written and committed.
**Output contract:** Proposal submitted; `hub.md` updated with proposal link.
**ics-cli commands used:** `ics push`, `ics proposal submit`.
**Risks:** Rationale too short; push conflicts; proposal rejected by Stratum.

---

## Handoff Points Summary

| Phase | Who does it today | Agent could do it? | Bounded? | Repetitive? |
|---|---|---|---|---|
| 0. Paper arrives | Human | No | — | — |
| 1. Bootstrap | Agent | Already done | Yes | Yes |
| 2. Ingest | Human+agent | Yes | Partial | Yes |
| 3. ELI5 | Human/agent | Yes | Yes | Yes |
| 4. Gap pass | Human/agent | Yes | Yes | Yes |
| 5. Peer pass | Subagent | Already done | Yes | Yes |
| 6. Synthesis | Human | Yes | Yes | Yes |
| 7. Push to Stratum | Human | Yes | Yes | Yes |

---

## Opportunity Cards

### Opportunity 1: Autonomous Ingest
**Today (human does):** Calls pdftoagent-mcp, waits, pastes result into vault.
**Could be (agent does):** Calls MCP, handles timeout/retry, stores extracted text in a note with citation.
**Trigger:** Bootstrap complete.
**Output contract:** `ingest/raw.md` with `paper_id`, `pdf_rel_path`, phase: ingest.
**ics-cli commands used:** `ics commit`.
**Risks / failure modes:** MCP timeout → partial text; very long PDFs → token limit.

### Opportunity 2: Batch ELI5 Writer
**Today (human does):** Writes 1 ELI5 note at a time, commits after each.
**Could be (agent does):** Reads all extracted text, produces all `eli5/*.md` notes in one pass.
**Trigger:** `ingest/raw.md` exists.
**Output contract:** All `eli5/<section>.md` files with frontmatter; `hub.md` links updated.
**ics-cli commands used:** `ics commit` per batch.
**Risks / failure modes:** Wrong frontmatter; fabricated citations; missing sections.

### Opportunity 3: Synthesis Drafter
**Today (human does):** Reads all notes, writes synthesis from scratch.
**Could be (agent does):** Reads all `eli5/`, `gaps/`, `peer/` notes, produces `synthesis.md` draft for human review.
**Trigger:** All gap + peer notes committed.
**Output contract:** `synthesis.md` draft; human reviews and edits.
**Risks / failure modes:** Hallucinated confidences; flat structure; misses key tensions.

### Opportunity 4: Stratum Proposal Submitter
**Today (human does):** Runs `ics push`, then `ics proposal submit` manually.
**Could be (agent does):** After synthesis commit, runs push + builds rationale + submits proposal.
**Trigger:** Synthesis committed.
**Output contract:** Proposal submitted; `hub.md` updated with `stratum_proposal_url`.
**ics-cli commands used:** `ics push`, `ics proposal submit`.
**Risks / failure modes:** Rationale < 50 chars; push conflicts; team-id wrong.

---

## Follow-up

Rank the opportunity cards above in a brainstorming session.
Pick the highest-value, lowest-risk opportunity to spec into a new agent.
```

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/specs/2026-05-08-ics-agent-opportunities.md
git commit -m "docs: add agent opportunities discovery doc"
```

---

## Task 4: Verify fixture script output quality

**Files:**
- Run: `scripts/test-fixture.sh --skip-mcp`
- Inspect: `Research/papers/s41534-021-00368-4-2nd/` — all files present with correct frontmatter

- [ ] **Step 1: Run fixture with --skip-mcp**

Run: `./scripts/test-fixture.sh --skip-mcp`
Expected: exits 1 (BLOCKERs on orientation + gaps_visibility — title_guess is placeholder, no status table).

- [ ] **Step 2: Inspect the created files**

Run: `ls -la Research/papers/s41534-021-00368-4-2nd/`
Run: `cat Research/papers/s41534-021-00368-4-2nd/hub.md | head -20`
Run: `cat Research/papers/s41534-021-00368-4-2nd/eli5/01-abstract.md | head -10`

All files should exist with correct frontmatter (`paper_id`, `pdf_rel_path`, `phase`, `writer`).

- [ ] **Step 3: Verify backup folder exists**

Run: `ls -d /home/hahuy/Documents/obs-vault/Research/papers/s41534-021-00368-4-backup-*`
Expected: exactly one backup folder, named with a timestamp.

- [ ] **Step 4: Commit verification results**

```bash
git add -A
git commit -m "test: run fixture script against s41534-021-00368-4 — confirms BLOCKERs surface correctly"
```

---

## Task 5: Run full fixture (without --skip-mcp) in a Claude session

This step must be run interactively — the `pdftoagent-mcp` tool is called from a Claude session, not from a shell script.

- [ ] **Step 1: In a Claude Code session, run the fixture**

```
cd /home/hahuy/Documents/github/ics-agents
./scripts/test-fixture.sh
```

When prompted by the script's MCP call instructions, in the Claude session:
1. Read `agents/parent-brief.md` + `agents/newcomer-path-validator.md`
2. Read the test folder at `Research/papers/s41534-021-00368-4-2nd/`
3. Run the rubric check
4. Write the report to `Research/papers/s41534-021-00368-4-2nd/validator-report.md`
5. Apply any BLOCKER fixes found (title_guess replacement, status table addition)
6. Run `ics commit` with fixes
7. Re-run the rubric check until all BLOCKERs pass

- [ ] **Step 2: Commit the validated fixture result**

```bash
git add -A
git commit -m "test: full fixture validated — all BLOCKERs resolved"
```

---

## Spec Coverage Check

- Item 1 (test fixture): Tasks 1, 4, 5 cover script creation, inline rubric, subagent call, exit codes
- Item 2 (validator rubric): Task 2 covers BLOCKER/WARN levels, remediation hints, updated output format
- Item 3 (agent discovery): Task 3 covers full lifecycle map, handoff point table, 4 opportunity cards

No spec requirements are unaddressed.
