# Forked subagents — Claude Code (`CLAUDE_CODE_FORK_SUBAGENT=1`)

Use this when the product exposes **forked** subagents (env enabled). Plain “fresh subagent” prompts still apply; forks add **shared context** so you spend less time re-pasting vault state.

## Enable (human / team)

In **`~/.claude/settings.json`** (user or managed settings), under top-level **`env`**:

```json
"CLAUDE_CODE_FORK_SUBAGENT": "1"
```

Or export in the shell before `claude`: `export CLAUDE_CODE_FORK_SUBAGENT=1`.

## Orchestrator instructions (paste or paraphrase)

You are the **parent**. Fan out **forked** subagents for **disjoint** file outputs; you merge links and the hub status table.

1. For each fork, paste **`parent-brief.md`** context (vault root, `paper_id`, paths to `hub.md` / `instruction.md`, phase, PDF policy).
2. Give **one** deliverable per fork (e.g. “write only `eli5/03-results.md`” or “fill only `gaps/assumptions.md`”).
3. **Do not** ask a fork to spawn sub-forks; if you need chaining, the **parent** runs the next wave.
4. After forks finish, **you** update `hub.md` (Note index / status table), fix conflicts, and run **ICS** commits if batching.

## Good fork boundaries

| Wave | Typical forks |
|------|----------------|
| ELI5 | One fork per section note |
| Gaps | Up to four forks (one file each) |
| Peer | One fork for `gap-peer-pass.md` |
| QA | One fork for `newcomer-path-validator.md` |

## Anti-patterns

- One fork with “do ELI5 + all gaps + peer” — loses parallelism and blurs failure domains.
- Forks writing the **same** file without a merge plan — use disjoint paths or parent-owned merge.
