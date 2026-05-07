# Forked  subagents (required)

Use this contract whenever you spawn a **child agent** from `agents/` (peer pass, newcomer validator, future prompts). The goal is **low parent-session cost at init** and **no context snowballing**.

## Claude Code

- Prefer **forked** subagent or **Task** runs so the child does **not** merge its full transcript into the parent by default (use the product’s “forked subagents” / separate task flow when available).
- **Paste-only handoff:** give the child **only** the bullet list from `agents/parent-brief.md` (vault root, `PAPER_ID`, absolute paths, phase, PDF note) **plus** the **single** agent file they should follow (e.g. `gap-peer-pass.md`). Do **not** attach the entire `SKILL.md`, full vault listing, or raw PDF at spawn unless that agent’s prompt explicitly requires it.
- **One role per fork:** one subagent = one agent file. If you need peer + newcomer, run **two** forks sequentially, not one mega-prompt.

## Cursor

- Use the **Task** / subagent mechanism with the same **paste-only** brief; keep the parent context limited to orchestration, not every file the child touched.

## Anti-patterns

- Spawning a subagent with “read the whole repo / whole skill” in the first message.
- Nesting subagents that each re-import the full parent history (keep each fork shallow).

## Parent reminder

The orchestrator stays thin: bootstrap → hand off **minimal** context → merge results back into the vault as files; **ICS commits** stay on clear boundaries.
