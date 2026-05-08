# Autonomous Ingest — Design

**Date:** 2026-05-09
**Status:** Draft
**Parent:** `docs/superpowers/specs/2026-05-08-ics-agent-opportunities.md`

---

## Overview

Autonomous Ingest wraps the pdftoagent-mcp async job interface to extract text from a PDF and persist it in the vault. It is the first phase of the `analyze-n-research` skill.

**What it does:**
1. Detect the obsidian vault root (`VAULT_ROOT`)
2. Copy the PDF from its current location into the vault at `Research/papers/<paper_id>/paper.pdf`
3. Submit the PDF to pdftoagent-mcp as an async job
4. Poll until complete, then persist the extracted markdown to `Research/papers/<paper_id>/<paper_id>.md`
5. Write a sidecar JSON with structured metadata
6. ICS commit the result

---

## Output Contract

| File | Content |
|------|---------|
| `Research/papers/<paper_id>/paper.pdf` | PDF copied from original location |
| `Research/papers/<paper_id>/<paper_id>.md` | Extracted markdown; first line is `<!-- original_pdf: Research/papers/<paper_id>/paper.pdf -->` |
| `Research/papers/<paper_id>/<paper_id>.md.sidecar.json` | Structured metadata |

### Sidecar Schema

```json
{
  "paper_id": "s41534-021-00368-4",
  "pdf_rel_path": "Research/papers/s41534-021-00368-4/paper.pdf",
  "ingested_at": "2026-05-09T10:00:00Z",
  "page_count": 12,
  "had_fallback": false,
  "fallback_reason": null,
  "engine_used": "marker_chunked",
  "artifacts": {
    "markdown": "Research/papers/s41534-021-00368-4/s41534-021-00368-4.md",
    "manifest": ".artifacts/marker_chunked/manifest.json"
  }
}
```

---

## Data Flow

```
analyze-n-research skill
└── Phase 1: Ingest
    ├── Input: paper_id, pdf_rel_path (original PDF location)
    │
    ├── 1a. Detect VAULT_ROOT
    │       → From env or config (VAULT_ROOT env var or ~/.config/ics/settings.json)
    │
    ├── 1b. Copy PDF to vault
    │       Source: pdf_rel_path (absolute or relative to vault)
    │       Dest:   VAULT_ROOT/Research/papers/<paper_id>/paper.pdf
    │       Skip if dest already exists (idempotent)
    │
    ├── 1c. Check if already ingested
    │       Path: VAULT_ROOT/Research/papers/<paper_id>/<paper_id>.md
    │       If exists → skip with message "Ingest complete, skipping"
    │
    ├── 1d. Submit async job
    │       Call: mcp__pdftoagent-mcp__submit_pdf_quality(
    │         input_path=VAULT_ROOT/Research/papers/<paper_id>/paper.pdf,
    │         format="markdown",
    │         extract_images=true
    │       )
    │       Returns: job_id
    │
    ├── 1e. Poll for completion
    │       Poll: mcp__pdftoagent-mcp__get_job_status(job_id)
    │       Interval: exponential backoff 15s → 30s → 60s → 120s (max)
    │       Timeout: 30 minutes total
    │       On timeout → exit with error, human retries manually
    │
    ├── 1f. Retrieve markdown artifact
    │       When status == "complete":
    │         Call: mcp__pdftoagent-mcp__get_artifact(artifact_path)
    │         artifact_path comes from job_status["artifacts"]["markdown"]
    │
    ├── 1g. Write <paper_id>.md with inline PDF path comment
    │       Dest: VAULT_ROOT/Research/papers/<paper_id>/<paper_id>.md
    │       First line: <!-- original_pdf: Research/papers/<paper_id>/paper.pdf -->
    │       Body: markdown content from get_artifact
    │
    ├── 1h. Write sidecar JSON
    │       Dest: VAULT_ROOT/Research/papers/<paper_id>/<paper_id>.md.sidecar.json
    │       Fields: paper_id, pdf_rel_path, ingested_at, page_count,
    │               had_fallback, fallback_reason, engine_used, artifacts
    │
    └── 1i. ICS commit
            Message: [claude][research][PAPER_ID][ingest] extracted N pages [/fallback used]
```

---

## Quality Signals

- `had_fallback`: derived from `fallback_reason != null` in job result
- `fallback_reason`: string if docling was used as fallback after marker failed
- No additional token-density or language-check heuristics — trust pdftoagent-mcp signals
- Downstream phases (ELI5) surface quality issues if content is poor

---

## Idempotency

- If `<paper_id>.md` already exists: skip ingestion, log "Ingest complete, skipping"
- If PDF copy dest already exists: assume up-to-date, skip copy
- Re-ingest is always possible by deleting `<paper_id>.md` first

---

## Error Handling

| Failure mode | Behavior |
|---|---|
| PDF path does not exist | Fail fast with clear message: "PDF not found at <path>" |
| MCP server down | Retry N times with backoff, then exit error — human handles manually |
| Poll timeout (30 min) | Exit error: "Ingest timed out after 30 minutes" |
| Job status == "failed" | Exit error with reason from job status |
| get_artifact fails | Exit error, do not write partial content |
| ICS commit fails | Log warning, do not fail the phase (commit is best-effort) |

---

## ICS Commands Used

- `ics commit -m "..."` (best-effort after ingest complete or fallback used)

---

## Testing

- Fixture test: `scripts/test-fixture.sh` creates stub folder; BLOCKER if any required files missing
- End-to-end: run `analyze-n-research` on a real paper with a known PDF path
- MCP offline: verify clean error message, not a hang
- Re-ingest: run twice, verify second run skips without error

---

## Dependencies

- pdftoagent-mcp MCP tools (submit_pdf_quality, get_job_status, get_artifact)
- VAULT_ROOT environment variable or ics settings.json
- ics binary for commit

---

## File Changes

| File | Change |
|---|---|
| `agents/newcomer-path-validator.md` | Add ingest phase to validator rubric (optional: Phase 2 = <paper_id>.md exists) |
| `analyze-n-research/SKILL.md` | Integrate Phase 1 Ingest at top of skill steps |
| `docs/superpowers/specs/2026-05-09-autonomous-ingest-design.md` | New — this document |
