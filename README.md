# ics-agents

Canonical **agent prompts**, **skills**, and **vault templates** for research workflows that use **ICS** (vault history via the `ics` CLI) and **Obsidian**.

**Repository:** https://github.com/Stratum-ICS/ics-agents

## Layout

| Path | Purpose |
|------|--------|
| `templates/instruction.md` | Copy beside each paper’s `hub.md`; human-facing rules for notes, tree, and commits. |
| `templates/hub.md.tpl` | Render to `hub.md` with `{{paper_id}}`, `{{pdf_rel_path}}`, `{{title_guess}}`. |
| `skills/analyze-n-research/` | analyzeNresearch skill (Cursor + Claude entrypoints). |
| `agents/` | Parent brief, peer pass, newcomer validator, and other prompt fragments. |

## Related repos

- **Obsidian plugin:** `ics-obsidian` — runs `ics` from the vault; commit template and log filter (see design spec there).
- **Design spec:** `ics-obsidian/docs/superpowers/specs/2026-05-06-analyzeNresearch-ics-skill-design.md`

## Conventions

- **Do not** duplicate `instruction.md` logic inside the plugin without a documented sync path from this repo.
- Bump templates here first; skills should embed or reference paths under this repo.
