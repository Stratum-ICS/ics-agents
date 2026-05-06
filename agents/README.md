# Agent prompts (`agents/`)

All prompts here are designed to run as **forked / isolated** subagents so the parent session stays light at init.

1. Read **`forked-subagents.md`** first (dispatch contract).
2. Paste **`parent-brief.md`** context + **exactly one** of:
   - **`gap-peer-pass.md`** — adversarial gap review after ELI5 + gaps exist.
   - **`newcomer-path-validator.md`** — onboarding rubric from hub + linked notes only.

New agent files added to this folder **must** include a top-line **Dispatch** pointer to `forked-subagents.md`.
