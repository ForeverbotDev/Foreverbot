# 🛡️ Foreverbot Autonomous Agent Rules & Guildie Engineering Protocol

This document defines mandatory operating rules, architectural constraints, and execution workflows for all coding agents working on the **Foreverbot** and **ForeverGuide** ecosystem.

---

## 🏛️ The 6-Phase Guildie Engineering Protocol

Every non-trivial feature, refactor, or release must strictly follow this lifecycle:

```
[Phase 1: Deep Research]
       │
       ▼
[Phase 2: Skills & Institutional Memory]
       │
       ▼
[Phase 3: Affirmative Vision & Autonomous Scope]
       │
       ▼
[Phase 4: Plan-as-Execution-Log (Markdown)]
       │
       ▼
[Phase 5: End-to-End Buildout (Deferred Testing)]
       │
       ▼
[Phase 6: Batch Verification & Text-Based Visual Pass]
```

### 1. Phase 1 — Deep Research First
- Never modify code blindly or make premature assumptions.
- Inspect the codebase, database schemas (`PRAGMA table_info`), existing utility patterns, and client runtime directories before authoring changes.
- Read existing issue trackers, commit logs, and docs to ensure full contextual awareness.

### 2. Phase 2 — Skills & Institutional Memory
- Record recurring workflows, specialized domain logic, and user preferences into formal Skills (`skills/<name>/SKILL.md` or `.agents/skills/`).
- Preserve institutional memory so subsequent tasks never regress or re-learn previous architectural lessons.

### 3. Phase 3 — Affirmative Vision & Autonomous Liberty
- Frame requirements affirmatively: focus on what to build, how it elevates the user experience, and how it matches the existing game theme.
- Grant autonomous agents creative liberty to architect elegant, cohesive solutions rather than constricting them with negative micro-rules.
- Rule of Evolution: *Changing existing functionality is encouraged whenever it matches the established theme and measurably enhances the solution.*

### 4. Phase 4 — Plan as Execution Log
- Before writing implementation code, create a clear, structured Markdown plan (e.g. `docs/plans/<feature>_plan.md` or artifact plan).
- Outline discrete, logical milestones with checkboxes.
- As steps complete, update the plan in real time so it serves as the live audit trail and execution log.

### 5. Phase 5 — End-to-End Buildout (Deferred Testing)
- Implement the feature end-to-end across all required layers (database, business logic, UI, commands, exporters) in a focused, uninterrupted pass.
- **Save testing for the end:** Avoid halting flow after every single line or function. Build out the complete cohesive system first, then enter the validation phase.
- If subagents are dispatched, delegate clearly bounded, modular sub-tasks with deterministic deliverables.

### 6. Phase 6 — Batch Verification & Text-Based Visual Pass
- Run comprehensive verification suites in batch:
  1. Static syntax & bracket integrity validation.
  2. Database consistency & schema regression checks.
  3. Fuzzing, boundary conditions, and concurrency stress tests.
- **Text-Based Visual Pass:** Conduct a terminal/text-rendered visual inspection of the user interface (ASCII layout preview, frame anchoring review, embed formatting inspection) in the local development environment before declaring the release complete.

---

## 🔒 Security & AI Safety Guardrails (Non-Negotiable)

### 1. Zero Unconstrained Loops
- Every `while` loop MUST have an explicit, immutable iteration ceiling or a strictly monotonic terminating condition.
- Infinite polling or sleep loops (`while True: pass`) without hard escape thresholds are strictly prohibited.

### 2. Strict Database & State Isolation
- **Static Game Catalog (`wow_forever.db`)**: Read-only distribution artifact containing items, quests, NPCs, and dungeons. NEVER commingle user data, raid rosters, or tokens in this file.
- **Dynamic User State (`user_data.db`)**: Local-only, uncommitted SQLite database for mutable state (raid signups, user profiles, AI cache, rate limits). Must remain in `.gitignore`.

### 3. SQL Injection Immunity
- 100% of SQL statements must use parameterized placeholders (`?`).
- String formatting (`f"SELECT ... {user_input}"`) or unescaped query assembly is completely forbidden.

### 4. AI Cost, Quota & Token Defense
- All LLM/AI query pathways must pass through `check_ai_rate_limit()`:
  - Per-user daily request caps (`AI_DAILY_CAP`).
  - Cooldown throttling (minimum 5 seconds between requests).
  - SHA-256 prompt hashing cache (`ai_cache`) to prevent redundant external API calls.
  - Fail-soft fallback messages when API quota or network fails.

### 5. Least-Privilege Permissions
- The Discord bot requests strictly necessary permissions (`Manage Channels`, `Manage Roles`, standard text permissions: integer `268812840`). Administrator permissions (`8`) are forbidden.
- In-game WoW addons strictly observe Blizzard UI policies (no out-of-game networking, no file-system access outside `SavedVariables`).

### 6. PII & Secret Scrubbing
- User IDs, server IDs, authorization tokens, and API keys must never be logged in raw form or committed to git.
- Log outputs must sanitize user input and strip sensitive auth tokens.

### 7. Non-Monetization & Legal Compliance
- Maintain strict compliance with Blizzard's Fan Content Policy and World of Warcraft AddOn Policy.
- Zero paywalls, donation solicitations, or commercial lockouts.
- Preserve all legal statutory citations in [`LEGAL.md`](LEGAL.md).
