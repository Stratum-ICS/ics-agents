# ics-agents

Canonical **agent prompts**, **skills**, and **vault templates** for research workflows that use **ICS** (vault history via the `ics` CLI) and **Obsidian**.

## Layout

| Path | Purpose |
|------|--------|
| `templates/instruction.md` | Copy or render beside each paper’s `hub.md`; human-facing rules for notes, tree, and commits. |
| `skills/analyze-n-research/` | analyzeNresearch skill (Cursor + Claude entrypoints). |
| `agents/` | Optional parent/peer subagent prompt fragments. |

## Related repos

- **Obsidian plugin:** `ics-obsidian` — runs `ics` from the vault; commit template and log filter (see design spec there).
- **Design spec:** `ics-obsidian/docs/superpowers/specs/2026-05-06-analyzeNresearch-ics-skill-design.md`

## Conventions

- **Do not** duplicate `instruction.md` logic inside the plugin without a documented sync path from this repo.
- Bump templates here first; skills should embed or reference paths under this repo.
