# Parent orchestrator brief (subagents)

**Dispatch:** Always use **forked** subagents per [`forked-subagents.md`](forked-subagents.md) so parent init and context stay small.

Give subagents **only** what they need; they do not inherit your full session.

## Required context (paste for every subagent)

1. **Vault root** — absolute filesystem path to the Obsidian vault (ICS runs here).
2. **`paper_id`** — stable id (e.g. `s41534-021-00368-4`).
3. **Paths** — absolute paths to:
   - `Research/papers/PAPER_ID/hub.md`
   - `Research/papers/PAPER_ID/instruction.md`
4. **Current phase** — `inbox` | `eli5` | `gaps` | `peer` | `synthesis`.
5. **PDF** — vault-relative `pdf_rel_path` and confirmation that **`pdftoagent-mcp`** may be used for extraction.

## Rules

- Subagents **must read `instruction.md` in full** before creating or moving files.
- New notes **must** include frontmatter per `instruction.md` (`paper_id`, `pdf_rel_path`, `phase`, optional `writer`).
- Prefer paths under `Research/papers/PAPER_ID/` for stable work; inbox only for quick capture with the same `paper_id` in frontmatter.
- **ICS commits** (if the subagent runs commits): use `[WRITER][research][PAPER_ID][PHASE] summary` with the correct writer (`claude`, `cursor`, `ics-bot`, or `human`).

## Outputs

- Write deliverables as markdown files; link them from `hub.md` when the phase completes.
