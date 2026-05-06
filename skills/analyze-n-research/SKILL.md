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

## Canonical assets

- **Design / behavior:** `ics-obsidian/docs/superpowers/specs/2026-05-06-analyzeNresearch-ics-skill-design.md`
- **Human rules template:** `ics-agents/templates/instruction.md` — copy to `Research/papers/<paper_id>/instruction.md` beside `hub.md` (replace `{{paper_id}}` if using templating).

## Workflow (orchestrator)

1. **Bootstrap** — Create `Research/papers/<paper_id>/hub.md` and **`instruction.md`** from the template; ensure inbox/hub links and frontmatter conventions match the template.
2. **Ingest** — Use **pdftoagent-mcp** on `pdf_rel_path`; do not invent quotes.
3. **ELI5 pass** — Section-by-section notes under agreed paths; each note: frontmatter + plain language + cited passage.
4. **Gap pass** — Four lenses (assumptions; not tested; future work; what would break results); separate notes under `gaps/` or equivalent.
5. **Peer subagents** — Spawn at least one review pass using `agents/` prompts; record in `phase: peer` notes.
6. **Synthesis** — One summary note; link from `hub.md`.
7. **ICS commits** — After each stable unit: `[<actor>][research][<paper_id>][<phase>] summary` (see `instruction.md`). Use `claude` vs `ics-bot` consistently for automation.

## Subagent brief

Pass: vault root, `paper_id`, absolute paths to `hub.md` and `instruction.md`, and current phase. Subagents **must** read `instruction.md` before creating files.

## Platform wrappers

- **Cursor:** Add user-rule or skill pointer to this file; ensure MCP `pdftoagent` enabled.
- **Claude Code:** Install skill from `ics-agents/skills/analyze-n-research/` per host docs.

## Testing (internal)

- Vault `/home/hahuy/Documents/obs-vault`, PDF `s41534-021-00368-4.pdf`; run full workflow; second subagent validates newcomer path from `hub.md` only.
