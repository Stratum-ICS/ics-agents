---
name: analyze-n-research
description: >-
  Use when a user wants a structured paper read-through in an ICS-backed Obsidian vault — ELI5
  segment notes, gap analysis (assumptions, untested claims, future work, fragility), peer subagent
  rounds, markdown outputs, and ICS commits with actor attribution. Requires pdftoagent-mcp for
  PDF text. Canonical templates live in the ics-agents repo (instruction.md next to hub.md).
---

# analyzeNresearch (ICS + Obsidian vault)

## When to use

- Deep read of a research paper with **team-shareable** markdown and **ICS** history.
- Onboarding path: newcomers start at **`hub.md`**, rules in **`instruction.md`** (same folder).

## Prerequisites

- Vault path (filesystem) known; **`ics`** initialized at vault root.
- PDF path **inside the vault**; `pdf_rel_path` set consistently with `instruction.md`.
- **`pdftoagent-mcp`** available for full-document extraction.

## Canonical repo

- **https://github.com/Stratum-ICS/ics-agents** — templates, this skill, agent prompts.

## Canonical assets (paths in repo)

| Asset | Path |
|-------|------|
| Human rules | `templates/instruction.md` |
| Hub scaffold | `templates/hub.md.tpl` |
| Parent brief | `agents/parent-brief.md` |
| Gap peer pass | `agents/gap-peer-pass.md` |
| Newcomer validator | `agents/newcomer-path-validator.md` |

## Bootstrap (orchestrator)

1. Choose **`paper_id`** (e.g. journal id `s41534-021-00368-4`) and vault-relative **`pdf_rel_path`** (e.g. `papers/<paper_id>/<file>.pdf`).
2. Create folder `Research/papers/<paper_id>/`.
3. Copy **`templates/instruction.md`** → `Research/papers/<paper_id>/instruction.md` (no edits required unless team extends actors/phases).
4. Render **`templates/hub.md.tpl`** → `Research/papers/<paper_id>/hub.md`:
   - Replace `{{paper_id}}`, `{{pdf_rel_path}}`, `{{title_guess}}` (use `TBD` if unknown).
5. Ensure `Research/inbox/` exists; optional first inbox note with same `paper_id` in frontmatter.
6. **ICS commit** (human or agent):  
   `[<actor>][research][<paper_id>][inbox] bootstrap hub + instruction`

## Ingest

- Run **pdftoagent-mcp** against the PDF at `pdf_rel_path`. Do not invent quotes; cite section/page in each note.

## ELI5 pass

- One note per major section (or per PDF chunk), under `Research/papers/<paper_id>/eli5/` (e.g. `01-abstract.md`).
- Each file: YAML with `paper_id`, `pdf_rel_path`, `phase: eli5`, optional `actor`; body = plain-language explanation + **quoted or cited** source passage.
- Link new notes from `hub.md` “Note index” and tick the ELI5 checklist when done.
- Commit after each section or logical batch: `[<actor>][research][<paper_id>][eli5] …`

## Gap pass (four files)

Create under `Research/papers/<paper_id>/gaps/`:

| File | Lens |
|------|------|
| `assumptions.md` | What did they assume? |
| `not-tested.md` | What did they **not** test? |
| `future-work.md` | What did they claim future work would address? |
| `fragility.md` | What would break their result? |

Frontmatter: `phase: gaps` (or a more specific tag in body if needed). Link from `hub.md`.

## Peer subagents

- Before synthesis, run at least one pass using **`agents/gap-peer-pass.md`** (output under `peer/`).
- Use **`agents/parent-brief.md`** to pass vault paths and require reading `instruction.md` first.

## Synthesis

- Single `synthesis.md` in the paper folder with `phase: synthesis`; link prominently from `hub.md` and check off the synthesis phase.

## ICS commits

- Format: `[<actor>][research][<paper_id>][<phase>] <summary>`
- Actors: `human`, `claude`, `cursor`, `ics-bot` — extend only with team agreement (document in `instruction.md`).
- Prefer **small, frequent** commits over one giant commit.

## Newcomer QA

- After notes exist, run **`agents/newcomer-path-validator.md`** as a fresh subagent using only `hub.md` + linked notes.

## Platform install

- **Cursor:** Point a project/user skill at this folder or symlink `skills/analyze-n-research/`; enable **pdftoagent** MCP.
- **Claude Code:** Install per host docs from `ics-agents/skills/analyze-n-research/`.

## Internal test fixture

- Vault: `/home/hahuy/Documents/obs-vault`; PDF: `s41534-021-00368-4.pdf` at vault-relative path per your layout; run bootstrap + one ELI5 + gap set + peer + newcomer validator.
