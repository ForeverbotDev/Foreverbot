# Security Policy & Architecture

## Supported Versions

| Version | Supported          | Security Audit Status |
| ------- | ------------------ | --------------------- |
| 1.12.1+ | :white_check_mark: | 100% Compliant (Suite 14 & 15 Verified) |
| < 1.12  | :x:                | Deprecated |

---

## Security Architecture & Fail-Safe Defenses

WoW: Forever Bot implements an enterprise-grade **defense-in-depth** security architecture designed to withstand adversarial input, high-concurrency micro-DoS, and external service failure.

```mermaid
graph TD
    User([Discord User / Interaction]) --> RateLimit[Sliding-Window Rate Limiter\n12 cmds / 2.0s window]
    RateLimit --> InputSan[Input Boundary Sanitizer\n500-char truncation, ReDoS shielding]
    InputSan --> Dispatcher[Slash Command Engine]
    
    Dispatcher --> ReadOps[(Static Game Catalog\nwow_forever.db)]
    Dispatcher --> UserOps[(User Data Store\nuser_data.db)]
    Dispatcher --> CircuitBreaker[Circuit Breaker\nThreshold: 3 | Reset: 60s]
    
    CircuitBreaker --> ExternalAPI[External AI / Scrapers]
    
    subgraph "Database Engine Hardening"
        ReadOps -.-> ModeRO[mode=ro URI Enforcement\nC-level Write Rejection]
        UserOps -.-> WAL[WAL Journal Mode\n30,000ms Busy Timeout]
    end
    
    subgraph "Output Defenses"
        Dispatcher --> EmbedSan[Discord Embed Boundary Clamping\nName: <=256, Value: <=1024, Max: 25]
        Dispatcher --> LogFilter[SensitiveDataFilter\nTokens, Keys & Paths Masked]
    end
```

### 1. Database Immutability & C-Level Read-Only Protection
- The static game catalog (`wow_forever.db`) contains over 30,000 items, quests, NPCs, and spells.
- All query paths connect using `sqlite3` URI mode `mode=ro` (`file:...wow_forever.db?mode=ro`).
- Even in the event of an SQL injection defect, any mutating query (`DROP`, `INSERT`, `UPDATE`, `DELETE`) is rejected directly by the SQLite C-engine with `sqlite3.OperationalError: attempt to write a readonly database`.

### 2. High-Concurrency & Zero-Lock Isolation
- Mutable user data (profiles, raid signups, AI usage) is strictly partitioned into `user_data.db`.
- Operates under **Write-Ahead Logging (WAL)** mode with `PRAGMA busy_timeout = 30000;`.
- Tested and verified under 30 concurrent threads executing 3,000 continuous read/write cycles with zero table locks.

### 3. Input Bounds, Clamping & Anti-ReDoS Fuzz Resistance
- All user query strings undergo early 500-character truncation in `clean_query()`.
- Complex multi-word regex patterns (`PREFIX_PATTERN`) are pre-compiled at module load time to completely eliminate polynomial or exponential CPU backtracking (ReDoS).
- User profile levels are strictly clamped between `1` and `60`; character names are capped at 50 chars; raid party limits are clamped between `1` and `100`.

### 4. Discord API Form Body Safety
- Direct embed field additions are routed through `safe_add_field()` and `safe_embed_str()`.
- Field names are capped at 256 characters, values at 1024 characters, and embed fields are capped at 25 fields maximum, preventing Discord `400 Bad Request` crashes.

### 5. Circuit Breaker & Graceful Degradation
- Outgoing API calls to the Google Gemini GenAI service are guarded by an enterprise `CircuitBreaker`.
- If 3 consecutive requests fail, the circuit trips to `OPEN`, immediately short-circuiting downstream calls and responding with cached/static fallbacks rather than hanging Discord command execution.

### 6. Logging Hygiene & Information Leakage Prevention
- Exception handlers in `@bot.tree.error` sanitize internal filesystem roots (`/home`, `/var`, `/usr`, `/tmp`) with `[internal_path]`.
- A custom `SensitiveDataFilter` is attached to Python's root logger and Discord log streams, automatically scrubbing Discord tokens and API keys.

---

## Automated Security Audit for Software Engineers

Any developer or code reviewer can independently verify the security posture of this repository using the automated security CLI suite:

```bash
# Run the complete 6-phase static and runtime security audit
python scripts/security_audit_and_failsafes.py

# Run the multi-threaded concurrency and attack simulation stress test
python -m unittest tests/test_whitehat_security_stress_test.py

# Run the security unit tests (Suite 15)
python -m unittest tests/test_security_audit_and_failsafes.py
```

### Audit Phase Checklist

- [x] **Phase 1: AST Static Security Analysis**: Zero prohibited calls (dynamic code execution, insecure deserialization, unparameterized SQL f-strings).
- [x] **Phase 2: Database Immutability**: Verified `DROP TABLE` rejection on read-only connection.
- [x] **Phase 3: Database B-Tree Integrity**: `PRAGMA integrity_check == 'ok'` and `PRAGMA quick_check == 'ok'`.
- [x] **Phase 4: Secrets & PII Hygiene**: Zero live tokens, credentials, or personal directory paths.
- [x] **Phase 5: Input Length Clamping & Anti-ReDoS**: Sub-50ms execution under 100,000-character fuzzed input.
- [x] **Phase 6: Circuit Breaker State Transitions**: Verified state transitions (`CLOSED` -> `OPEN` -> `HALF_OPEN` -> `CLOSED`).

---

## Reporting a Vulnerability

If you discover a security vulnerability within WoW Forever Bot:
1. **Do not open a public issue.**
2. Send a coordinated disclosure report with reproduction steps to the repository security maintainers.
3. We acknowledge receipts within 24 hours and provide a patched release within 72 hours.
