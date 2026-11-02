# Security & Compliance Audit — openhab-skill

- **Date:** 2026-10-24/25 (pre-publication audit) · **Last updated:** 2026-11-02
- **Who:** repository owner, with an AI coding agent
- **Scope:** full git history (all commits/blobs), working tree, the published GitHub state (`sho81/openhab-skill`), licensing/provenance, data protection, commit signing. Per-file code findings are in [CODE_REVIEW.md](CODE_REVIEW.md) (H/M/L IDs) and are cross-referenced here, not repeated.
- **Method:** blob-by-blob pattern scan of the entire history (PEM/JWT/PAT/API-key/token patterns, hostnames, IPs, emails) · pickaxe search for the known leaked token value · live probes of the public repo (raw.githubusercontent, GitHub API) · SSH signature verification of every commit (`git verify-commit` with an `allowed_signers` file) · functional tests of the CLI against a mock openHAB server.

---

## Findings & resolution

### S1. Leaked access token reachable on the public remote — CLOSED
Code-side finding and remediation options: CODE_REVIEW.md **H4**. This entry records the release timeline and verification:
- **2026-10-23** token rotated in openHAB (primary mitigation).
- **2026-10-24** audit confirmed the *real* value was still being served publicly: `origin/main` still held the pre-rewrite history, `token` file present in every upstream commit, raw URL answered `200` with the live value.
- **2026-10-24** history scrubbed via `git filter-repo --replace-text` (value → `REDACTED-ROTATED` in every blob); follow-up rebase re-signed all owner commits — post-rewrite, **17/17 signatures verify**.
- **2026-10-25** `git push --force-with-lease`; afterward the public token URL returns `404` (live-verified). Full-history re-scan: zero occurrences of the real value, no other secrets (no PEM/JWT/PAT/API keys), no non-placeholder hostnames/IPs/emails in any blob.
- Residual: GitHub garbage collection may keep the old commit objects briefly reachable by direct SHA; impact nil because the token was rotated.

### S2. Fork provenance / missing upstream license — CLOSED
- Upstream `ElDuderinos/openhab-skill` is public **without any LICENSE file** (i.e. all-rights-reserved); this repo had carried no attribution, and `LICENSE` named a single copyright holder.
- **Resolution (2026-10-25):** README attributes the fork to @ElDuderinos; `LICENSE` changed to pseudonymous dual copyright (`ElDuderinos, sho81`). Upstream author informed — *still pending*.

### S3. Registry metadata with a foreign identity — CLOSED
- `_meta.json` carried an upstream ClawHub `ownerId` (not the publisher's) and a stale `publishedAt` (2026-01-28, predating the fork). Slug issue: CODE_REVIEW.md **M4**.
- **Resolution (2026-10-25):** file removed from git and `.gitignore`d — ClawHub generates registry state at publish/install time; it is not source.

### S4. `references/api.md` derived from openHAB's OpenAPI spec (EPL-2.0) — CLOSED
- **Resolution (2026-10-25):** explicit source credit added to the api.md header (“Based on the openHAB 5.2.1 REST API, OpenAPI 3.0.1 specification”).

### S5. Commit signing / integrity — VERIFIED
- All 17 owner commits are signed (FIDO `ED25519-SK` key) and verify after the history rewrite. The 4 upstream base commits are unsigned (as published upstream). Signing policy: SSH-format signatures, principal `sebastian.hornbostel@gmx.de`.

### S6. Personal data posture — ACCEPTED (deliberate)
- Tracked files contain **no** personal names, private e-mails, real hostnames or IPs (placeholder examples only); copyright/docs use GitHub handles.
- Commit metadata intentionally retains the author's real name and private e-mail (OSS convention; scrubbing would invalidate all signatures). A file named `token` remains in 5 historical trees with placeholder content only.
- `SKILL.md`/`README.md` carry an explicit scope note (no rule/automation execution) to avoid over-claimed capabilities.

---

## Open recommendations (not yet implemented)
1. **Inbound webhook hardening:** docs do not advise protecting the agent's webhook endpoint (shared secret / IP allowlist) — fake events are possible if it is reachable.
2. **Data-flow note:** no explicit statement that smart-home item names/states enter the agent/LLM context (third-party processing if the agent or model is cloud-hosted) — relevant for GDPR-conscious users.
3. Optional code niceties from CODE_REVIEW.md **H3** (warn on group/world-readable config) and trailing-slash normalization in the URL.

## Audit-cycle change log (repo-visible)
- **2026-10-25** compliance pass (attribution, pseudonymous copyright, `_meta.json` removal, “no automations” scope notes, api.md source credit) · GET status hardening + curl error handlers (M6) + `list` normalization fix (M7) · `.idea/` untracked and ignored.
- **2026-11-02** `scripts/oa.sh` → `scripts/openhab.sh`.
