# ics-agents Improvements — Design

**Date:** 2026-05-08
**Status:** Draft
**Owner:** ics-agents maintainers

---

## Context

ics-agents provides:

- `skills/analyze-n-research/` — paper read-through skill (bootstrap → ingest → ELI5 → gaps → peer → synthesis)
- `agents/gap-peer-pass.md` — adversarial challenge subagent
- `agents/newcomer-path-validator.md` — onboarding QA subagent
- `agents/forked-subagents.md` — dispatch contract (forked/isolated, paste-only handoff)
- `templates/instruction.md`, `templates/hub.md.tpl` — vault structure rules

**Goal:** Improve the existing skill/tooling, then use the improved foundation to discover and spec new agents through structured workflow analysis rather than preloaded assumptions.

---

## Item 1: Automated Test Fixture

### Problem

`SKILL.md` describes a "recursive test loop" but there is no script that runs it. The fixture vault (`/home/hahuy/Documents/obs-vault`) is real but manual — no CI gate, no repeatable pass/fail signal.

### What to build

`scripts/test-fixture.sh` — a shell script that exercises the full skill on the internal test fixture.

**Prerequisites:**
- Vault at `/home/hahuy/Documents/obs-vault`
- PDF fixture at vault root: `s41534-021-00368-4.pdf`
- `ics` on PATH
- `pdftoagent-mcp` available (via `mcp__pdftoagent-mcp__convert_pdf_quality`)

**Steps:**

```bash
#!/bin/bash
set -e

VAULT_ROOT="/home/hahuy/Documents/obs-vault"
PAPER_ID="s41534-021-00368-4"
PAPER_DIR="$VAULT_ROOT/Research/papers/$PAPER_ID"

# 1. Bootstrap
mkdir -p "$PAPER_DIR"
cp templates/instruction.md "$PAPER_DIR/instruction.md"
# Render hub.md.tpl with paper_id, pdf_rel_path, title_guess
# (title_guess from first page of PDF via pdftoagent-mcp or user-supplied)

# 2. ICS init if needed
cd "$VAULT_ROOT"
ics init 2>/dev/null || true

# 3. ICS commit bootstrap
ics commit -m "[human][research][$PAPER_ID][inbox] bootstrap hub + instruction"

# 4. PDF ingest via pdftoagent-mcp
# call: mcp__pdftoagent-mcp__convert_pdf_quality
# input_path = absolute path to PDF
# format = markdown, extract_images = true

# 5. Create one ELI5 note + gap stubs
mkdir -p "$PAPER_DIR/eli5" "$PAPER_DIR/gaps"
# Write eli5/01-abstract.md, gaps/assumptions.md stubs
# with correct frontmatter (paper_id, pdf_rel_path, phase, writer)

# 6. ICS commit
ics commit -m "[claude][research][$PAPER_ID][eli5] bootstrap test — abstract"

# 7. Run newcomer-validator as forked subagent
# Hand off agents/parent-brief.md bullets + agents/newcomer-path-validator.md
# Capture subagent output

# 8. Report rubric pass/fail
# Format: JSON or text with per-rubric result + any BLOCKERs
```

**Exit codes:**
- `0` — all BLOCKERs pass
- `1` — one or more BLOCKERs fail (with output explaining which rubric items failed)
- `2` — fixture setup or tool failure (ics not found, MCP unavailable, etc.)

**Output format:**
```
=== Fixture Test Report ===
Rubric: orientation      PASS / FAIL (BLOCKER) — <reason>
Rubric: rules_clarity    PASS / FAIL (WARN)    — <reason>
Rubric: friction         PASS / FAIL (WARN)     — <reason>
Rubric: gaps_visibility  PASS / FAIL (BLOCKER) — <reason>
=== Outcome: PASS / FAIL ===
```

### Vault fixture cleanup

After the test, the vault is left in the state of a real bootstrap + one ELI5 + gap stubs. This is intentional — it becomes a real example in the vault that humans can inspect.

### What this does NOT do

- It does NOT run pdftoagent-mCP against the full PDF every time (token expensive). Stub ELI5 notes are created manually in the script; the MCP call is optional/future.
- It does NOT run full peer pass subagents.
- It does NOT modify the fixture vault in a way that requires teardown.

---

## Item 2: Improved Newcomer-Validator Rubric

### Problem

The current validator (`agents/newcomer-path-validator.md`) is too rigid — it surfaces failures but gives no path to fix them. A human reading the output doesn't know what to change. Additionally, not all failures are equal: some block team onboarding, others are minor friction.

### Changes

**1. Distinguish BLOCKER from WARN**

| Level | Meaning | Script action |
|---|---|---|
| **BLOCKER** | Newcomer cannot orient or follow rules; must fix before the paper is readable | Exit code 1 on fixture script |
| **WARN** | Friction or incomplete info; should fix but doesn't block | Logged, no exit failure |

**2. Rubric item definitions with remediation hints**

| Rubric item | BLOCKER condition | WARN condition | Remediation hint |
|---|---|---|---|
| **Orientation** | `hub.md` has no title, no "Why we care", or no phase checklist | "Why we care" exists but is vague | "Fill hub.md ## Why we care with 1-3 bullets: team goal, decision this informs, or experiment milestone." |
| **Rules clarity** | `instruction.md` missing or unreadable; frontmatter template not present | Commit format not explained; path tree not shown | "Add missing sections to instruction.md or ensure the template copy succeeded." |
| **Friction** | `hub.md` has no linked notes and no explanation of what phases produce | Some links exist but don't match actual files | "Link at least one ELI5 note from hub.md, or add a stub with 'Not started — see SKILL gap pass'." |
| **Gaps visibility** | No status table in `hub.md`; cannot tell stubs from drafts | Status table exists but is incomplete | "Add hub.md status table: columns Note \| Topics \| Status, initial values stub." |

**3. Fail with file:line specificity**

When orientation fails, the validator output names the exact field:

```
BLOCKER: hub.md field "title_guess" is "{{title_guess}}" (not replaced).
Fix: Set a real paper title in hub.md before finishing bootstrap.
```

**4. Remediation output per BLOCKER**

Each BLOCKER line in the validator report ends with a concrete action:

```
Rubric: orientation    FAIL (BLOCKER)
  → hub.md "Why we care" is empty.
  → Action: Add 1-3 bullets to ## Why we care (team goal, decision this informs, or experiment milestone).
```

**5. Updated validator output format**

```markdown
## Validator Report

| Rubric | Result | Detail |
|--------|--------|--------|
| orientation | ✅ PASS / ❌ FAIL (BLOCKER) | ... |
| rules_clarity | ✅ PASS / ⚠️ WARN | ... |
| friction | ✅ PASS / ⚠️ WARN | ... |
| gaps_visibility | ✅ PASS / ❌ FAIL (BLOCKER) | ... |

### BLOCKERs (must fix before closing session)
1. [orientation] hub.md title_guess not replaced with real title
   → Action: Replace `{{title_guess}}` in hub.md with actual paper title

2. [gaps_visibility] no status table in hub.md
   → Action: Add table with columns Note | Topics | Status, values stub/draft/closed

### Warnings (should improve)
1. [friction] no ELI5 notes linked from hub.md
   → Suggestion: Link at least one ELI5 stub from hub.md Note index
```

### Changes to `agents/newcomer-path-validator.md`

- Add BLOCKER/WARN schema to the output section
- Add remediation hints to each rubric item
- Update the rubric item 3 (friction) to use status table rather than flat link list
- Add instruction that orientation failures should name the specific hub.md field

---

## Item 3: Agent Discovery Process

### Problem

The obs-vault docs mention "Paper Reader", "Idea Analyzer", and "Reviewer" as future agents, but these are names without behavior specs. We risk building the wrong agents, or building agents that don't fit the actual research workflow.

### Discovery methodology

Rather than spec agents directly, we map the researcher workflow and find **handoff points** — moments where a subagent would eliminate a bottleneck. The output of this item is a **workflow map + agent opportunity list**, not finished agent specs.

**Step 1 — Map the full researcher lifecycle**

Using the Data-Flow.md and existing docs, trace the path from paper arrival to synthesis to team knowledge. Identify:

- What humans do manually at each step
- What agents could do instead
- Where ics-cli commands are invoked today
- Where Stratum is (or should be) involved

**Step 2 — Identify handoff points**

A handoff point is a place where work could be delegated to a subagent if:
1. The work is **repetitive** (same structure every paper)
2. The work is **bounded** (clear inputs, clear outputs)
3. The work **requires reading** the paper or existing notes
4. The human currently **waits** for this step

**Step 3 — Draft opportunity cards**

For each handoff point, write a one-paragraph opportunity card:

```
## Opportunity: [short name]
**Today (human does):** ...
**Could be (agent does):** ...
**Trigger:** ...
**Output contract:** ...
**ics-cli commands used:** ...
**Risks / failure modes:** ...
```

These cards are the input to a follow-up brainstorming session where we decide which opportunities to spec into agents.

### What this item does NOT produce

- It does NOT write agent specs for Paper Reader / Idea Analyzer / Reviewer by default
- It does NOT build any agents
- It does NOT commit to a roadmap

### What this item DOES produce

- `docs/superpowers/specs/YYYY-MM-DD-ics-agent-opportunities.md` — workflow map + opportunity cards
- A discussion session with the team to rank opportunities

### Coordination with Items 1 and 2

The workflow map may reveal that the test fixture needs to cover more paths (e.g., Stratum push/pull). Item 1 should be runnable independently; the discovery process runs in parallel or after.

---

## File changes summary

| File | Change |
|---|---|
| `scripts/test-fixture.sh` | New — shell script fixture runner |
| `agents/newcomer-path-validator.md` | Update rubric with BLOCKER/WARN + remediation hints |
| `docs/superpowers/specs/YYYY-MM-DD-ics-agent-opportunities.md` | New — workflow map + opportunity cards |

---

## Open questions

1. Should `test-fixture.sh` run inside the real vault or a temp copy? (Real vault: changes persist as example; temp copy: clean but ephemeral)
2. Should the fixture script be runnable by CI (GitHub Actions), or only locally?
3. Should the discovery process (Item 3) produce a dedicated session/handoff doc, or just a list in the existing vault?
