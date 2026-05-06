# Parent orchestrator brief (subagents)

Give subagents **only** what they need; they do not inherit your full session.

## Required context (paste for every subagent)

1. **Vault root** — absolute filesystem path to the Obsidian vault (ICS runs here).
2. **`paper_id`** — stable id (e.g. `s41534-021-00368-4`).
3. **Paths** — absolute paths to:
   - `Research/papers/<paper_id>/hub.md`
   - `Research/papers/<paper_id>/instruction.md`
4. **Current phase** — `inbox` | `eli5` | `gaps` | `peer` | `synthesis`.
5. **PDF** — vault-relative `pdf_rel_path` and confirmation that **`pdftoagent-mcp`** may be used for extraction.

## Rules

- Subagents **must read `instruction.md` in full** before creating or moving files.
- New notes **must** include frontmatter per `instruction.md` (`paper_id`, `pdf_rel_path`, `phase`, optional `actor`).
- Prefer paths under `Research/papers/<paper_id>/` for stable work; inbox only for quick capture with the same `paper_id` in frontmatter.
- **ICS commits** (if the subagent runs commits): use `[<actor>][research][<paper_id>][<phase>] summary` with the correct actor (`claude`, `cursor`, `ics-bot`, or `human`).

## Outputs

- Write deliverables as markdown files; link them from `hub.md` when the phase completes.
