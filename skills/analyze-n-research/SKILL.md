---
name: analyze-n-research
description: >-
  Use when a user wants a structured paper read-through in an ICS-backed Obsidian vault — ELI5
  segment notes, gap analysis (assumptions, untested claims, future work, fragility), peer subagent
  rounds, markdown outputs, and ICS commits with writer attribution. Requires pdftoagent-mcp for
  PDF text. Hub.md must carry a real title and “why we care” (not TBD-only) before bootstrap is
  considered done for team onboarding. Canonical templates live in the ics-agents repo.
---

# analyzeNresearch (ICS + Obsidian vault)

## When to use

- Deep read of a research paper with **team-shareable** markdown and **ICS** history.
- Onboarding path: newcomers start at **`hub.md`**, rules in **`instruction.md`** (same folder).

## Prerequisites

- Vault path (filesystem) known; **`ics`** initialized at vault root.
- PDF path **inside the vault**; `pdf_rel_path` is **vault-root-relative** and must match **exactly** in every note’s frontmatter and in `hub.md` (same string as used for the `[[wikilink]]` target).
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
| Forked subagents (Claude) | `agents/forked-subagents-claude-code.md` |

## Bootstrap (orchestrator)

1. Choose **`paper_id`** (e.g. journal id `s41534-021-00368-4`) and vault-root-relative **`pdf_rel_path`** (e.g. `papers/<paper_id>/<file>.pdf` **or** `my-paper.pdf` if the file lives at the vault root — **one convention only**).
2. Create folder `Research/papers/<paper_id>/`.
3. Copy **`templates/instruction.md`** → `Research/papers/<paper_id>/instruction.md` (no edits required unless team extends writers/phases). If the instruction’s example `pdf_rel_path` differs from yours, that is fine — **your** hub and notes must all use **your** chosen path string.
4. Render **`templates/hub.md.tpl`** → `Research/papers/<paper_id>/hub.md`:
   - Replace `{{paper_id}}`, `{{pdf_rel_path}}`.
   - Replace `{{title_guess}}` with a **real title** before finishing bootstrap (from PDF metadata, first page via **pdftoagent-mcp**, DOI landing page, or user message). **Do not** ship `TBD` for team onboarding.
   - Fill **`## Why we care`** on the hub with 1–3 bullets (team goal, decision this informs, or experiment milestone).
5. **Optional (recommended for newcomer visibility):** create `gaps/*.md` **stubs** (`phase: gaps`, body: “Not started — see SKILL gap pass”) and link them from the hub **Note index** using a status table (columns: Note | Topics | Status, initial value `stub`) so lenses exist before they are filled.
6. Ensure `Research/inbox/` exists; optional first inbox note with same `paper_id` in frontmatter.
7. **ICS commit** (human or agent):  
   `[WRITER][research][PAPER_ID][inbox] bootstrap hub + instruction`

## Ingest

- Call **pdftoagent-mcp** `convert_pdf_quality` with **`input_path`** = absolute filesystem path to the PDF (derive from vault root + `pdf_rel_path`). Use `format: markdown`; if the engine times out, retry with a higher `timeout_seconds` or accept the server’s docling fallback — still cite sections/pages from the returned text.
- Do not invent quotes; cite section/page in each note.

## ELI5 pass

- One note per major section (or per PDF chunk), under `Research/papers/<paper_id>/eli5/` (e.g. `01-abstract.md`).
- Each file: YAML with `paper_id`, `pdf_rel_path`, `phase: eli5`, optional `writer`; body = plain-language explanation + **quoted or cited** source passage.
- Link new notes from `hub.md` “Note index” and tick the ELI5 checklist when done.
- Commit after each section or logical batch: `[WRITER][research][PAPER_ID][eli5] …`

## Gap pass (four files)

Create under `Research/papers/<paper_id>/gaps/`:

| File | Lens |
|------|------|
| `assumptions.md` | What did they assume? |
| `not-tested.md` | What did they **not** test? |
| `future-work.md` | What did they claim future work would address? |
| `fragility.md` | What would break their result? |

Frontmatter: `phase: gaps` (or a more specific tag in body if needed). Link from `hub.md`. If stubs were created at bootstrap, replace “Not started” with real content.

## Peer subagents

- Before synthesis, run at least one pass using **`agents/gap-peer-pass.md`** (output under `peer/`).
- Use **`agents/parent-brief.md`** to pass vault paths and require reading `instruction.md` first.

## Parallel work — forked subagents (Claude Code)

Assume **forked** subagents (inherited parent context) are available — team default is on in `~/.claude/settings.json`. The orchestrator should **fan out** forks for independent deliverables instead of one serial mega-agent.

**Do this (parent stays in charge of merge + `hub.md`):**

1. After **ingest**, spawn **one fork per ELI5 target** (e.g. one note per major section), each with a paste from **`agents/parent-brief.md`** plus the exact section scope and any excerpt path.
2. After ELI5, spawn **up to four forks** for **`gaps/*.md`** (assumptions, not-tested, future-work, fragility) with disjoint prompts.
3. Spawn **fork(s)** for **`agents/gap-peer-pass.md`** and, when ready, **`agents/newcomer-path-validator.md`**.
4. **Throughput:** prefer many small forks over one long subagent; each fork writes only under `Research/papers/<paper_id>/` and uses the ICS commit line when committing.

**Hard rule:** A **fork must not spawn another fork** (product limitation). Nested work is serialized by the **parent** (or combined into one child prompt).

See **`agents/forked-subagents-claude-code.md`** for copy-paste orchestration wording.

## Synthesis

- Single `synthesis.md` in the paper folder with `phase: synthesis`; link prominently from `hub.md` and check off the synthesis phase.

## ICS commits

- Format: `[WRITER][research][PAPER_ID][PHASE] SUMMARY`
- Writers: `human`, `claude`, `cursor`, `ics-bot` — extend only with team agreement (document in `instruction.md`).
- Prefer **small, frequent** commits over one giant commit.

## Newcomer QA

Run **`agents/newcomer-path-validator.md`** as a **fresh subagent** after there is material to read (at minimum hub + instruction + linked notes).

**Rubric (fail → fix before closing the session):**

1. **Orientation** — From hub + links alone: paper topic, why the team cares, and which phases remain.
2. **Rules clarity** — A human can follow `instruction.md` for frontmatter, tree, and commit format.
3. **Friction** — Path should feel **less** ad hoc than reading the PDF in isolation; if not, improve hub structure and links.
4. **Gaps visibility** — Hub or index shows which gap lenses are **started vs empty** (stubs count). Use a status table in `hub.md` (columns: Note | Topics | Status with values `stub` / `draft` / `closed`) rather than a flat link list — a flat list makes all stubs look identically incomplete.

**Remediation:** If **orientation** fails, update **`hub.md` first** (title, **Why we care**, links) — do not only add ELI5 notes. If **gaps visibility** fails, add the status table to `hub.md` — do not change the gap files themselves.

## Recursive test loop (maintainers)

When changing this skill, run at least one full dry run on the **internal test fixture** (below): bootstrap → ingest (MCP) → one ELI5 note → gap stubs or one gap file → newcomer validator subagent → apply edits to **this SKILL** and templates if the validator surfaces systemic issues. Repeat until the newcomer path is acceptable.

## Platform install

- **Cursor:** Point a project/user skill at this folder or symlink `skills/analyze-n-research/`; enable **pdftoagent** MCP (`user-pdftoagent-mcp`).
- **Claude Code:** Install per host docs from `ics-agents/skills/analyze-n-research/`.

## Internal test fixture

- Vault: `/home/hahuy/Documents/obs-vault`; PDF: `s41534-021-00368-4.pdf` (vault-root-relative `pdf_rel_path` example: `s41534-021-00368-4.pdf`).
- Run: bootstrap (non-TBD title + Why we care) → `convert_pdf_quality` on absolute PDF path → one ELI5 + gap stubs → newcomer validator subagent.
