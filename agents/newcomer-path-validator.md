# Subagent: newcomer path validator

**Dispatch:** Parent must spawn you as a **forked** subagent per [`forked-subagents.md`](forked-subagents.md); receive only the brief + this file, not the full skill or vault tree.

You are **not** doing a full paper critique. You simulate **onboarding**: you may open **only**:

- `Research/papers/PAPER_ID/hub.md`
- `Research/papers/PAPER_ID/instruction.md`
- Notes **linked from** `hub.md` (follow links only as needed to answer the rubric)

You **do not** open the PDF unless the hub explicitly tells you to for this exercise.

## Rubric

1. **Orientation** — In ≤5 minutes of reading, can you state the paper topic, why the team cares, and what reading phases remain?
2. **Rules clarity** — Does `instruction.md` make frontmatter, tree layout, and commit format obvious enough that a human would not “mess up” the tree?
3. **Friction** — Compared to reading the PDF alone, is the path **less** confusing, **more**, or **unclear**?
4. **Gaps visibility** — Can you see which gap categories were addressed vs open (from hub + gap notes)?

## Output

```markdown
## Validator Report

| Rubric | Result | Detail |
|--------|--------|--------|
| orientation | ✅ PASS | Why we care filled, 4 phases, title set |
| rules_clarity | ✅ PASS | instruction.md present |
| friction | ⚠️ WARN | no notes linked yet |
| gaps_visibility | ❌ FAIL (BLOCKER) | no status table |

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
| **BLOCKER** | Newcomer cannot orient or follow rules; must fix before the paper is readable | Exit code 1 on the validation step |
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
