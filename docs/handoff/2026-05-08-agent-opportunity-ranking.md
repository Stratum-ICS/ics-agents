# Handoff Document

**Created:** 2026-05-08
**Topic:** ics-agents improvements — Agent opportunity ranking
**Status:** Ready for next session

---

## Context Summary

We completed the ics-agents improvements implementation plan and reviewed pdftoagent-mcp. The next step is to rank the 4 agent opportunity cards (from `docs/superpowers/specs/2026-05-08-ics-agent-opportunities.md`) with the user to decide which to spec first.

---

## Completed Work

- [x] `scripts/test-fixture.sh` — automated fixture runner with inline rubric check, exit 0/1/2
- [x] `agents/newcomer-path-validator.md` — BLOCKER/WARN rubric + remediation hints
- [x] `docs/superpowers/specs/2026-05-08-ics-agent-opportunities.md` — 4 opportunity cards written
- [x] `docs/superpowers/specs/2026-05-08-ics-agents-improvements-design.md` — design doc
- [x] `docs/superpowers/plans/2026-05-08-ics-agents-improvements-plan.md` — implementation plan
- [x] pdftoagent-mcp reviewed + fixed: format validation + pytest config
- [x] pdftoagent-mcp installed in `~/.venv`; MCP tools live in current session

---

## Pending Work

- [ ] **Agent opportunity ranking** — discuss and rank the 4 opportunity cards; pick first to spec
- [ ] `analyze-n-research/SKILL.md` — update to reference BLOCKER/WARN rubric
- [ ] Full fixture run with real `pdftoagent-mcp` extraction + BLOCKER fixes (interactive step)
- [ ] `ics` on PATH — may want `cargo install --path ~/Documents/github/ics-cli`

---

## Key Decisions Made

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| Test fixture creates `-2nd` folder | Fresh start each run; backup preserves original | Run in temp dir (rejected — ephemeral) |
| BLOCKER/WARN distinction | BLOCKERs block team onboarding; WARNs are friction | Treat all failures equally (rejected — too rigid) |
| pdftoagent-mcp validate format param | format was silently ignored | Silently default to markdown (rejected — silent failures bad) |

---

## Current State

### Files Modified
- `scripts/test-fixture.sh` — new
- `agents/newcomer-path-validator.md` — BLOCKER/WARN rubric
- `python/pdftoagent-mcp/src/pdftoagent_mcp/server.py` — format validation
- `python/pdftoagent-mcp/pyproject.toml` — pytest config
- `python/pdftoagent-mcp/tests/test_contract.py` — format validation test

### Files Created
- `docs/superpowers/specs/2026-05-08-ics-agents-improvements-design.md`
- `docs/superpowers/plans/2026-05-08-ics-agents-improvements-plan.md`
- `docs/superpowers/specs/2026-05-08-ics-agent-opportunities.md`
- `docs/handoff/2026-05-08-agent-opportunity-ranking.md`

### Vault State
- `/home/hahuy/Documents/obs-vault/Research/papers/s41534-021-00368-4-2nd/` — validated fixture with real title, Why we care, gaps status table; committed via `ics`

---

## Next Steps

1. **Read** `docs/superpowers/specs/2026-05-08-ics-agent-opportunities.md` — the 4 opportunity cards
2. **Discuss** with user to rank: Autonomous Ingest, Batch ELI5 Writer, Synthesis Drafter, Stratum Proposal Submitter
3. **Pick first** — highest value, lowest risk, best for onboarding
4. **Brainstorm** that agent's spec (per brainstorming skill)

---

## Important Notes

- pdftoagent-mcp MCP tools are live in this session — `mcp__pdftoagent-mcp__get_system_info` returns healthy
- The 4 opportunity cards are preliminary — the discovery doc recommends Autonomous Ingest as first spec (improves all downstream phases, bounded, reversible)
- Test fixture exit 1 = BLOCKERs found (expected on fresh stubs); exit 0 = all BLOCKERs resolved
- ics binary at `/home/hahuy/Documents/github/ics-cli/target/debug/ics` — not on PATH

---

## Resources

- Opportunity cards: `docs/superpowers/specs/2026-05-08-ics-agent-opportunities.md`
- Newcomer validator: `agents/newcomer-path-validator.md`
- Test fixture: `scripts/test-fixture.sh`
- pdftoagent-mcp: `/home/hahuy/Documents/github/pdf-to-agent/python/pdftoagent-mcp/`
