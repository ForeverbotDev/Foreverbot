# Privacy Policy for Foreverbot

**Effective Date:** October 30, 2026  
**Last Updated:** October 30, 2026

Foreverbot ("the Bot", "we", "our") is an open-source, non-commercial Discord companion bot built for the World of Warcraft: Forever player community. We are committed to transparency and respecting user privacy in compliance with applicable data protection regulations (including GDPR and CCPA).

---

## 1. Information We Collect

Foreverbot only stores data strictly required to deliver user-requested features:

1. **Character Profiles (`/profile set`)**:
   - Discord User ID (numeric snowflake)
   - In-game character name
   - Class, race, level, talent spec
   - In-game professions and guild rank/role
   - User-provided gear or attunement notes
2. **Raid Signups (`/signup`)**:
   - Discord User ID
   - Discord display name / username
   - Selected raid role (Tank, Melee DPS, Caster, Healer, Bench)
   - Event identifier and timestamp
3. **AI Quota Metrics**:
   - Daily count of AI queries per user ID to prevent spam, denial-of-service, and rate-limit exhaustion.

### What We DO NOT Collect:
- ❌ We do NOT read, store, or log private messages (DMs) or message history.
- ❌ We do NOT collect IP addresses, email addresses, or payment information.
- ❌ We do NOT track or store raw user query arguments in server logs.
- ❌ We do NOT sell, lease, or share any user data with advertisers, third-party analytics, or data brokers.

---

## 2. Where and How Data Is Stored

- **Separated User Database:** All user profile information, raid signups, and quota metrics are stored in a locally isolated SQLite database (`user_data.db`).
- **Isolation from Game Catalog:** User data is strictly separated from the read-only static game catalog (`wow_forever.db`), ensuring game updates and git synchronizations never expose, overwrite, or track user data in version control.
- **Data Minimization:** Cached AI responses are stored anonymously keyed by a cryptographic SHA-256 hash of the prompt without user attribution.

---

## 3. User Rights & Data Deletion (Right to Erasure)

You have full control over your data:

1. **Self-Service Profile Deletion:**
   - Execute `/profile delete` in any server where Foreverbot is present to immediately wipe your character profile.
2. **Global Data Erasure:**
   - Run `/privacy` and click the **"Delete All My Data"** button to permanently purge your character profile, all active raid event signups, and quota history from the bot's database.
3. **Manual Request:**
   - You may open an issue on our [GitHub Repository](https://github.com/ForeverbotDev/Foreverbot/issues) to request manual verification of deletion.

---

## 4. Third-Party Services

- **Discord API:** Standard message routing and interaction events are transmitted via the official Discord Gateway under Discord's Privacy Policy.
- **Google Gemini API:** When using natural language AI commands (such as `/ask` or `/macro`), the text prompt is sent to Google's Gemini API for processing. No Discord account metadata or personal identifiers are passed to Gemini.

---

## 5. Contact & Updates

Foreverbot is open source. If you have questions regarding this Privacy Policy, please open a GitHub Issue or submit a pull request on our repository.
