# Research folder rules

**Paper id:** set in every note’s `paper_id` field (this folder is `papers/<paper_id>/`).  
This file lives next to **`hub.md`**. Everyone (humans and agents) follows these rules so the vault stays navigable and **ICS** history stays readable.

## Tree (example)

Use your real `paper_id` in place of the example id.

```text
Research/
  inbox/
    2026-05-06-first-pass.md          # fast capture; still has paper_id in frontmatter
  papers/
    s41534-021-00368-4/
      hub.md                          # start here (newcomer map)
      instruction.md                  # this file
      s41534-021-00368-4.pdf          # optional: PDF co-located (or set pdf_rel_path elsewhere)
      eli5/
        01-abstract.md
        02-methods.md
      gaps/
        assumptions.md
        not-tested.md
        future-work.md
        fragility.md
      synthesis.md
```

- **Inbox** = quick thoughts; promote stable content into `papers/<paper_id>/` and link from `hub.md`.
- **One hub per paper** — do not create parallel “main” notes without linking them from `hub.md`.

## Frontmatter (required on every note)

```yaml
---
paper_id: s41534-021-00368-4
pdf_rel_path: papers/s41534-021-00368-4/s41534-021-00368-4.pdf
phase: eli5          # inbox | eli5 | gaps | peer | synthesis
actor: human         # optional: human | claude | cursor | ics-bot
---
```

Adjust `pdf_rel_path` if the PDF lives elsewhere in the vault.

## Note shapes

| `phase` | Purpose |
|---------|--------|
| `inbox` | Short bullets; no need for perfect structure. |
| `eli5` | Plain-language explanation + **quoted or cited** passage from the paper (section/page). |
| `gaps` | Answers to: assumptions; not tested; future work; what would break results. |
| `peer` | Subagent or human challenge pass; disagreements and resolutions. |
| `synthesis` | Single consolidated “what we believe / don’t know yet.” |

## ICS commit message template

**One line** (preferred):

```text
[<actor>][research][<paper_id>][<phase>] <short summary>
```

**Actors:** `human`, `claude`, `cursor`, `ics-bot` (add new labels only by team agreement and update this file).

**Examples:**

```text
[human][research][s41534-021-00368-4][inbox] first reactions after skim
[claude][research][s41534-021-00368-4][eli5] §2 methods — ELI5 steps
[ics-bot][research][s41534-021-00368-4][gaps] automated gap pass — assumptions
```

- Do **not** strip brackets to “save time” — that breaks filtering and reviewer scans of `ics log`.
- Prefer **many small commits** over one huge commit; match commit to one logical note or section update.

## PDF and MCP

- Paper text extraction for full reads: **`pdftoagent-mcp`** against the file at `pdf_rel_path`.
- If MCP is unavailable, paste excerpts into notes and cite location; do not invent quotes.

## Hub maintenance

- After adding notes, **update `hub.md`** links and the phase checklist.
- Before archiving a paper, ensure `synthesis.md` exists and gaps are either resolved or explicitly open.

---

*Template version: 2026-05-06 — source: `ics-agents/templates/instruction.md`*
