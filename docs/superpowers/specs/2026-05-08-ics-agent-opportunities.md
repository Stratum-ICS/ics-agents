# ics-agent Opportunities — Discovery

**Date:** 2026-05-08
**Status:** Draft
**Input:** Data-Flow.md, ics-agents.md, analyze-n-research SKILL.md

---

## 1. Researcher Lifecycle — Current State

### Phase 0: Paper Arrives (Human Decision)

**Who does it today:** Human decides what to read. No agent involvement.

**Agent opportunity:** None. This is a judgment call only a human can make (relevance to current work, novelty, team priorities).

---

### Phase 1: Bootstrap

**Who does it today:** Human or agent (part of analyze-n-research skill).

**Steps:**
- Choose `paper_id`, `pdf_rel_path`
- Create `Research/papers/<paper_id>/` folder
- Copy `templates/instruction.md`
- Render `templates/hub.md.tpl` (replace `{{paper_id}}`, `{{pdf_rel_path}}`, `{{title_guess}}`)
- Fill "Why we care" in hub with real title + 1-3 bullets
- Create gap stub files linked from hub
- ICS commit: `[WRITER][research][PAPER_ID][inbox] bootstrap hub + instruction`

**Agent could do it:** Yes — all steps are templated and bounded.

**Bounded / Repetitive:** Yes. Same structure every paper; only the paper_id, pdf_rel_path, and title vary.

---

### Phase 2: Ingest (PDF → Text)

**Who does it today:** Human + agent collaborating. Agent calls `pdftoagent-mcp convert_pdf_quality`. Human may retry on timeout.

**Steps:**
- Agent calls `mcp__pdftoagent-mcp__convert_pdf_quality` with absolute PDF path
- `format: markdown`, `extract_images: true`
- On timeout: retry with higher `timeout_seconds` or accept server fallback
- Result: extracted markdown stored in `.artifacts/` or similar

**Agent could do it:** Yes — agent already does this, but retry/timeout handling is manual.

**Bounded / Repetitive:** Yes. Same MCP call structure every time.

---

### Phase 3: ELI5 Notes

**Who does it today:** Agent writes `eli5/*.md` notes from extracted text. One file per major section or PDF chunk.

**Steps:**
- Agent reads extracted markdown
- For each section: write `Research/papers/<paper_id>/eli5/XX-name.md`
- Frontmatter: `paper_id`, `pdf_rel_path`, `phase: eli5`, `writer`
- Body: plain-language explanation + cited source passage
- Link from hub.md "Note index"; tick ELI5 checklist
- ICS commit per batch: `[WRITER][research][PAPER_ID][eli5] ...`

**Agent could do it:** Yes — this is already agent's primary job.

**Bounded / Repetitive:** Yes. Same file structure, same frontmatter, same commit format every time.

---

### Phase 4: Gap Pass

**Who does it today:** Agent writes `gaps/*.md` files (assumptions, not-tested, future-work, fragility).

**Steps:**
- Agent reads extracted text or existing ELI5 notes
- Writes 4 files under `Research/papers/<paper_id>/gaps/`
- Frontmatter: `phase: gaps`
- Link from hub.md; replace stub content

**Agent could do it:** Yes — already agent's job in analyze-n-research.

**Bounded / Repetitive:** Yes. Four fixed lenses, same structure every paper.

---

### Phase 5: Peer Pass

**Who does it today:** Agent (gap-peer-pass.md subagent). One forked subagent per role, adversarial challenge round.

**Steps:**
- Fork subagent using `agents/forked-subagents.md`
- Hand off `agents/parent-brief.md` + `agents/gap-peer-pass.md`
- Output under `peer/` directory
- Human reviews before synthesis

**Agent could do it:** Yes — already a subagent. Opportunity is to run multiple passes automatically or chain peer agents.

**Bounded / Repetitive:** Partially. The pass structure is fixed, but the content is adversarial and varied.

---

### Phase 6: Synthesis

**Who does it today:** Human writes `synthesis.md` after reading all notes.

**Steps:**
- Human reads eli5/*.md, gaps/*.md, peer/*.md
- Writes `Research/papers/<paper_id>/synthesis.md`
- Frontmatter: `phase: synthesis`
- Links prominently from hub.md

**Agent could do it:** Yes — agent has all inputs needed. Could produce a draft for human review.

**Bounded / Repetitive:** Yes — same structure every time (summary of findings, gaps, peer challenges, open questions). Draft is bounded; final review remains human's job.

---

### Phase 7: Push to Stratum

**Who does it today:** Human runs `ics push` for affected note paths, then `ics proposal submit`.

**Steps:**
- Human runs `ics push Research/papers/<paper_id>/` (or specific paths)
- Human writes rationale (≥50 chars)
- Human runs `ics proposal submit --team-id N --note-ids X --rationale "..."`
- Server state machine: draft → submitted

**Agent could do it:** Yes — agent knows all paths, has all note IDs. Could run push + build rationale + submit.

**Bounded / Repetitive:** Yes. Same commands every time; rationale is the only creative part (but templateable from synthesis content).

---

## 2. Handoff Points Summary Table

| Phase | Who does it today | Agent could do it? | Bounded? | Repetitive? |
|---|---|---|---|---|
| 0: Paper arrives | Human | No | N/A | N/A |
| 1: Bootstrap | Human or agent | Yes | Yes | Yes |
| 2: Ingest | Agent (MCP call) | Yes (with better retry) | Yes | Yes |
| 3: ELI5 notes | Agent | Yes | Yes | Yes |
| 4: Gap pass | Agent | Yes | Yes | Yes |
| 5: Peer pass | Subagent (already agent) | Yes (chain/auto) | Partial | Partial |
| 6: Synthesis | Human | Yes (draft only) | Yes | Yes |
| 7: Push + submit | Human | Yes | Yes | Yes |

---

## 3. Opportunity Cards

### Opportunity: Autonomous Ingest

**Today (human does):** Agent calls `pdftoagent-mcp convert_pdf_quality` once; on timeout or failure, human must manually retry with higher timeout or fall back to partial extract. No automatic retry loop. No persistent storage of extracted text beyond the immediate session.

**Could be (agent does):** Agent wraps the MCP call in a retry loop with exponential backoff, configurable timeout ceiling, and graceful fallback to partial extract. Stores extracted markdown at a predictable path (`Research/papers/<paper_id>/.ingest/extracted.md`). Emits a structured result: `{path, page_count, chunk_count, had_timeout, fallback_used}` so downstream phases can branch.

**Trigger:** Human or orchestrator calls `analyze-n-research` skill on a paper that has passed Phase 0 and has a valid `pdf_rel_path`.

**Output contract:**
- File: `Research/papers/<paper_id>/.ingest/extracted.md`
- Frontmatter or sidecar JSON: `{paper_id, pdf_rel_path, ingested_at, page_count, had_timeout, fallback_used, chunks: [{start_page, end_page, path}]}`
- ICS commit: `[claude][research][PAPER_ID][ingest] extracted N pages / fallback used`

**ics-cli commands used:**
- `ics commit -m "..."` (after extract complete or fallback)

**Risks / failure modes:**
- PDF is password-protected or binary-scarred → fallback produces gibberish; agent must detect low token density and warn human rather than silently proceeding
- MCP server is down → agent retries N times then exits with error; human must manually handle
- PDF path is wrong (symlink, moved file) → agent must check path existence before calling MCP and fail fast with clear message
- Extracted text is huge (500+ pages) → chunking must be deterministic so ELI5 pass can resume from correct chunk

---

### Opportunity: Batch ELI5 Writer

**Today (human does):** Agent writes ELI5 notes one at a time or in small batches. Each note requires reading extracted text, identifying section boundaries, drafting plain-language explanation, and citing a source passage. Commit after each note or small batch.

**Could be (agent does):** Agent reads all extracted text (or all chunks from the ingest sidecar), identifies N major sections, and produces all `eli5/*.md` files in a single pass. Groups commit: one ICS commit for the full ELI5 batch rather than N individual commits. The agent still respects section boundaries and cites page numbers.

**Trigger:** Autonomous Ingest phase completes (`.ingest/extracted.md` exists and `had_timeout == false` or `fallback_used == true` with a warning).

**Output contract:**
- Files: `Research/papers/<paper_id>/eli5/01-abstract.md`, `02-intro.md`, ... one per major section
- Each file: correct frontmatter (`paper_id`, `pdf_rel_path`, `phase: eli5`, `writer: claude`), body with plain-language summary + cited source
- Hub.md updated: ELI5 notes linked in Note index, checklist ticked
- ICS commit: `[claude][research][PAPER_ID][eli5] batch write N sections`

**ics-cli commands used:**
- `ics commit -m "..."`

**Risks / failure modes:**
- Section boundary detection is noisy → some ELI5 notes may cover half a page or span two sections; acceptable at draft stage
- Chunked ingest (many small files) → agent must read all chunks in order; glob order must match page sequence
- Human already wrote some ELI5 notes manually → agent should not overwrite existing non-stub files without asking (or use a `--force` flag)
- Very long paper (100+ sections) → agent should cap at ~20 ELI5 notes and put remainder in a catch-all `NN-misc.md`

---

### Opportunity: Synthesis Drafter

**Today (human does):** Human reads all ELI5 notes, gap files, and peer notes, then writes `synthesis.md`. This is the most cognitively heavy phase — requires integrating multiple perspectives and identifying what the paper's findings mean for the team.

**Could be (agent does):** Agent reads all notes under `Research/papers/<paper_id>/` (eli5/*.md, gaps/*.md, peer/*.md), produces a `synthesis.md` draft with sections: Key Findings, Gap Summary, Peer Challenges, Open Questions, Relevance to Our Work. Draft is marked clearly as a draft (frontmatter `draft: true`). Human reviews, edits, removes the draft flag, and commits.

**Trigger:** Phases 3, 4, and 5 are complete (all eli5/*.md, gaps/*.md, peer/*.md exist).

**Output contract:**
- File: `Research/papers/<paper_id>/synthesis.md`
- Frontmatter: `paper_id`, `pdf_rel_path`, `phase: synthesis`, `draft: true`
- Sections: Key Findings, Gap Summary, Peer Challenges, Open Questions, Relevance to Our Work
- No ICS commit (human reviews first)

**ics-cli commands used:** None (draft only, human reviews before committing).

**Risks / failure modes:**
- Synthesis quality is only as good as the notes that feed it — if ELI5 notes are shallow, synthesis inherits the shallowness
- Agent may invent claims not in the paper → require citation in synthesis body (section/page references)
- Human may disagree with the framing → synthesis is explicitly a draft; agent should flag contested claims with `> [!caveat]` style callouts
- Agent may produce generic text that could apply to any paper → trigger a "specificity check": every Key Finding must contain at least one paper-specific term (method name, dataset, result statistic)

---

### Opportunity: Stratum Proposal Submitter

**Today (human does):** Human reviews completed synthesis, runs `ics push [paths]` for all notes in the paper folder, then manually writes a ≥50-char rationale and runs `ics proposal submit --team-id N --note-ids X --rationale "..."`.

**Could be (agent does):** After synthesis is committed and human approves it, agent:
1. Runs `ics push Research/papers/<paper_id>/**` (or specific paths: hub.md, synthesis.md, eli5/*.md, gaps/*.md)
2. Reads synthesis.md to extract a rationale (first two Key Findings sentences, or first 200 chars of Open Questions)
3. Expands rationale to ≥50 chars if needed (append "This paper informs [team goal].")
4. Runs `ics proposal submit --team-id N --note-ids X --rationale "..."`
5. Reports proposal ID and status

**Trigger:** `synthesis.md` exists with `phase: synthesis` and human has approved push (explicit confirmation step before the agent acts — this is a significant action).

**Output contract:**
- All notes pushed to Stratum (response logged)
- Proposal submitted; response includes `{id, status, conflict_hints}`
- Proposal ID and conflict hints reported to human in session
- No local commit until human confirms (human must see what will be submitted)

**ics-cli commands used:**
- `ics push [paths...]`
- `ics proposal submit --team-id N --note-ids X --rationale "..."`

**Risks / failure modes:**
- `ics push` fails for some paths (e.g., note was already pushed with different content) → agent should report partial push failure and list which paths failed
- Rationale extracted from synthesis is < 50 chars → agent must expand rather than fail
- Proposal submit fails (network, auth expired) → agent reports error; human must re-run manually
- Agent pushes notes that human did not intend to push → confirmation gate is critical; agent must list paths before pushing
- Team ID is wrong → agent should require team-id as explicit parameter, not guess

---

## 4. Follow-up

The four opportunity cards above are the raw output of the discovery pass. Before any spec work begins, run a brainstorming session to rank them.

**Ranking criteria:**
- **Value:** How much human time does this save? Is the phase a frequent bottleneck?
- **Risk:** How likely is the agent to produce wrong output? Can a human catch failures quickly?
- **Scope:** How many new tools/MCPs/ics-cli commands are required?
- **Reversibility:** If the agent does the wrong thing, can a human undo it cheaply?

**Suggested ranking (preliminary):**

| Opportunity | Value | Risk | Scope | Reversibility | Notes |
|---|---|---|---|---|---|
| Autonomous Ingest | High | Medium | Low (retry loop) | High (re-ingest) | Reduces manual retry burden; most predictable ROI |
| Batch ELI5 Writer | High | Low | Low (file writes) | High (overwrite) | Already agent's job; batch vs. incremental is a speedup |
| Synthesis Drafter | High | Medium | Medium (prompt) | Medium (edits needed) | Draft quality depends on upstream notes; human review required anyway |
| Stratum Proposal Submitter | Medium | High | Medium (ics push + submit) | Low (proposal on server) | Most irreversible; confirmation gate is essential; highest stakes |

**Recommended first spec:** Autonomous Ingest — lowest risk, bounded inputs/outputs, high reversibility, and it improves the reliability of all downstream phases.

**Next:** Batch ELI5 Writer — combines naturally with ingest, same agent can handle both, incremental improvement to existing workflow.

**Brainstorming session owner:** Schedule via `schedule` skill; invite: ics-agents maintainers.

---

## File Changes

| File | Change |
|---|---|
| `docs/superpowers/specs/2026-05-08-ics-agent-opportunities.md` | New — this document |
