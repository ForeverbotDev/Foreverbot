# PRIVACY POLICY & DATA PROTECTION CHARTER

**Effective Date:** November 2, 2026  
**Last Revised:** November 2, 2026  
**Applicability:** Global (GDPR, CCPA/CPRA, and PIPEDA Compliant)

---

## 1. COMMITMENT TO DATA PRIVACY

Foreverbot ("the Application", "we", "our") is an open-source, non-commercial Discord companion bot engineered with privacy-by-design principles. We do not sell personal data, do not monetize user interactions, and do not harvest telemetry.

This Privacy Policy governs the collection, storage, and erasure of information processed when you interact with Foreverbot across Discord guilds or local self-hosted instances.

---

## 2. CATEGORIES OF DATA PROCESSED

Foreverbot operates under strict **Data Minimization** standards (GDPR Art. 5(1)(c)). We process only the minimum dataset necessary to execute user-requested features:

### A. Information You Voluntarily Provide
1. **Character Armory Profiles (`/profile set`)**:
   - Discord User ID (numeric snowflake, e.g. `123456789012345678`);
   - In-game character name, class, race, level, and talent specification;
   - In-game primary professions and guild rank/role;
   - Player gear annotations and attunement status notes.
2. **Raid Attendance & Roster Board (`/signup`)**:
   - Discord User ID;
   - Discord Guild Display Name;
   - Selected raid combat role (`Tank`, `Melee`, `Caster`, `Healer`, or `Bench`);
   - Event identifier and signup timestamp.

### B. Anonymous Operational Metadata
- **AI Rate-Limiting & Quota Tracking:** An internal numeric counter tracking the number of daily AI queries made per user ID to mitigate denial-of-service attempts and control API quota consumption.
- **AI Prompt Caching:** Cryptographic SHA-256 hashes of natural language prompts mapped to generated responses. Cached responses are completely decoupled from user IDs and contain zero personal identifiers.

### C. Data We NEVER Collect or Store
- ❌ **No Private Message (DM) Monitoring:** We do not read, parse, or record direct messages or channel chat logs.
- ❌ **No Message Content Logging:** We do not log the text of general server messages.
- ❌ **No Hardware or Network Identifiers:** We do not capture IP addresses, MAC addresses, device fingerprints, or browser cookies.
- ❌ **No Financial or Payment Information:** Zero credit card numbers, billing addresses, or banking details.
- ❌ **No PII in Application Logs:** Command audit logs in stdout record only truncated user hashes (`...5678`) and command names (e.g. `/item`), with zero raw user parameters.

---

## 3. LAWFUL BASIS FOR PROCESSING (GDPR ART. 6 & PIPEDA)

We process personal data exclusively under the following legal bases:
1. **Consent (Art. 6(1)(a) GDPR):** You provide explicit affirmative consent by voluntarily running `/profile set` or interacting with raid signup buttons.
2. **Legitimate Interests (Art. 6(1)(f) GDPR):** Rate-limiting and prompt hashing are conducted to safeguard bot infrastructure against resource exhaustion and security vulnerabilities.

---

## 4. ARCHITECTURAL ISOLATION & STORAGE LOCATION

1. **Decoupled User Database (`user_data.db`):** All user character profiles, raid event rosters, and quota counts reside exclusively in a locally hosted, separate SQLite database file (`user_data.db`).
2. **Strict Version Control Exclusion:** `user_data.db` is permanently quarantined by `.gitignore` and is never committed to GitHub or public version control. Static game database updates (`wow_forever.db`) are completely decoupled, ensuring game catalog refreshes never overwrite, expose, or commingle user records.
3. **Local Self-Hosting:** Guild owners hosting their own bot instances retain complete, sovereign ownership of their local database with zero outbound user synchronization.

---

## 5. USER RIGHTS & SELF-SERVICE DATA ERASURE (GDPR ART. 17 & CCPA)

You retain unconditional sovereignty over your personal data. Foreverbot provides instant, self-service mechanisms to exercise your statutory rights:

### 1. Right to Erasure ("Right to be Forgotten")
- **Profile Deletion:** Execute `/profile delete` at any time to permanently wipe your character armory profile from the database.
- **Universal Data Purge (`/privacy`):** Execute `/privacy` and click the red **"Delete All My Data"** button. This permanently purges:
  - Your character armory profile;
  - All your signups across all active and historical raid boards;
  - All quota tracking and rate-limiting records.
  - Zero traces or residual metadata remain associated with your Discord account.

### 2. Right to Access and Rectification
- Run `/profile view` to inspect your stored armory record.
- Run `/profile set` at any time to update, modify, or overwrite your character details.

---

## 6. THIRD-PARTY DATA DISCLOSURE & SUB-PROCESSORS

Foreverbot does **not** sell, rent, monetize, or disclose your personal data to any third-party commercial brokers, advertisers, or analytics firms.

External services utilized during bot execution are strictly limited to:
- **Discord Gateway (Discord, Inc.):** Transmits slash command interactions across the Discord API under Discord’s Developer Terms of Service and Privacy Policy.
- **Google Gemini API (Google LLC):** When invoking AI assistance commands (`/ask`, `/macro`), the text prompt is transmitted via encrypted HTTPS to Google’s API for inference. No Discord usernames, user IDs, or guild identifiers are passed to Google.

---

## 7. RETENTION PERIOD

- **Character Profiles:** Stored until modified or deleted by the user via `/profile delete` or `/privacy`.
- **Raid Signups:** Maintained for the duration of the raid event, or until the user clicks `Leave` or triggers universal data erasure.
- **Quota Tracking:** Automatically resets at 00:00 UTC daily.

---

## 8. CHILDREN'S PRIVACY (COPPA / GDPR ART. 8)

Foreverbot is not directed toward children under the age of 13 (or under 16 within the European Economic Area). We do not knowingly collect personal data from minors. In accordance with Discord’s Terms of Service, all users must meet the minimum age required to access Discord in their jurisdiction.

---

## 9. CONTACT & DATA PROTECTION INQUIRIES

For questions regarding this policy or to request manual confirmation of data deletion, please contact the maintainers via our open GitHub repository:
- **Issue Tracker:** [https://github.com/ForeverbotDev/Foreverbot/issues](https://github.com/ForeverbotDev/Foreverbot/issues)
