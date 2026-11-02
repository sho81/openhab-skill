# Code & Security Review — openhab-skill

- **Date:** 2026-10-21 · **Last updated:** 2026-11-02 (added M6–M7 from the pre-publication audit; rename noted)
- **Scope:** all tracked files (`SKILL.md`, `README.md`, `_meta.json`, `references/api.md`, `scripts/oa.sh` — the script was renamed to `scripts/openhab.sh` on 2026-11-02; this report keeps the original name as historical record)
- **Method:** manual review + `bash -n` syntax check; follow-up fixes verified against a local mock openHAB server (no shellcheck available on this machine)
- **Companion document:** release-level findings (git-history secrets, PII, licensing/provenance, commit signing) are tracked in [SECURITY_AUDIT.md](SECURITY_AUDIT.md) and not repeated here.

## Summary

| Priority | Count | IDs |
|----------|-------|-----|
| P0 — High | 4 | H1–H4 |
| P1 — Medium | 7 | M1–M7 |
| P2 — Low | 8 | L1–L8 |

The skill is small and mostly documentation; the only executable code is `scripts/oa.sh`. The most important issues are that **the deleted token secret is still public via GitHub history** (H4), that **HTTP errors are reported as success** (H1), and that **docs default to plain HTTP for a Bearer-token API** (H2).

Work-specific tracking (commits, progress) lived in a local notes file (`WORK.md`), which is gitignored and not published.

---

## P0 — High

### H1. `on`/`off` report success on any HTTP error — FIXED
- **File:** `scripts/oa.sh` (on/off cases)
- **Category:** Bug / Security
- **Status:** Fixed 2026-10-23 — curl now captures the HTTP status code; non-2xx prints ✗ with the code to stderr and exits 1.
- **Issue:** curl was called without `-f`, so it exited 0 even on 4xx/5xx. The script then unconditionally printed `✓ $item turned on/off`. A 401 (expired token) or 404 (wrong item name) looked like success to the calling AI agent — which may believe a light is ON when it isn't.
- **Fix:** use `curl -sf` and only print the ✓ after checking the exit code; better, capture `-w '%{http_code}'` and surface non-2xx with a clear error message.

### H2. Plain HTTP recommended by default for a Bearer-token API — FIXED
- **File:** `README.md:20`, `SKILL.md:25` (examples use `http://…:8080`)
- **Category:** Security
- **Status:** Fixed 2026-10-23 — config examples now use HTTPS; added a TLS note to both docs (LAN-only HTTP acceptable if deliberate, `--cacert` for self-signed certs, warn against `-k`).
- **Issue:** The token and all smart-home state travel in cleartext. Fine on a trusted LAN, but the SKILL.md config example (`https://your-openhab-instance.duckdns.org`, line 17) implies internet exposure — where cleartext HTTP is much worse. No guidance anywhere on TLS or self-signed certs (users will reach for `curl -k`).
- **Fix:** recommend HTTPS as the default; document CA handling (`--cacert` / trust store); explicitly warn against `-k`; note that LAN-only HTTP is an acceptable trade-off if stated deliberately.

### H3. Token in plaintext config file, no permission guidance — FIXED
- **File:** `SKILL.md:14–20`, `README.md:16–23`
- **Category:** Security
- **Status:** Fixed 2026-10-23 — both docs now instruct `chmod 600 ~/.config/openhab/config.json`. (Optional `oa.sh` warning for group/world-readable config not implemented.)
- **Issue:** The recommended setup stores the long-lived token in `~/.config/openhab/config.json`. With a default umask of 022 that file is world-readable (644) — any local user can read the token. No `chmod 600` hint anywhere.
- **Fix:** document `chmod 600 ~/.config/openhab/config.json`; optionally have `oa.sh` warn when the config file is group/world readable.

### H4. Deleted token secret still recoverable from git history (public repo) — FIXED
- **File:** the tracked `token` file (introduced at init, removed when the secret was dropped)
- **Category:** Security
- **Status:** Fixed 2026-10-23 — token rotated in openHAB. History later scrubbed with `git filter-repo --replace-text`: in every commit the old value is replaced by a `REDACTED-ROTATED` placeholder, so it is no longer recoverable from the published history (the pre-rewrite commit hashes cited in earlier revisions of this report no longer exist). Force-push completed 2026-10-25; live-verified — see `SECURITY_AUDIT.md` S1.
- **Issue:** The long-lived openHAB access token was committed at init and is still present in the history of `origin/main`. Deleting the file only removes it from HEAD — anyone can recover it with `git show 908adce:token`. The remote (`github.com/sho81/openhab-skill`) answers 200 unauthenticated, i.e. it appears **public**, so the secret should be considered exposed until rotated.
- **Fix:** rotate now (create a new token in openHAB, update `~/.config/openhab/config.json` / env var); optionally scrub history with `git filter-repo --path token` and force-push if you want it fully gone; add `.gitignore` so local config files don't get re-added (see L7).

---

## P1 — Medium

### M1. Item name interpolated into URL without validation or encoding — FIXED
- **File:** `scripts/oa.sh` (state/attributes/on/off cases)
- **Category:** Security / Robustness
- **Status:** Fixed 2026-10-23 — item names are validated against `^[A-Za-z0-9_]+$`; anything else is rejected with ✗ + exit 1 before the request is made.
- **Issue:** `${item}` is pasted directly into the path (`…/rest/items/${item}/state`). openHAB item names are normally `[A-Za-z0-9_]+`, but an agent could pass `foo/../rules` or a name with spaces → wrong endpoint or broken request.
- **Fix:** validate against `^[A-Za-z0-9_]+$` (reject otherwise) or URL-encode the segment.

### M2. Token visible in local process list — FIXED
- **File:** `scripts/oa.sh` (all curl calls)
- **Category:** Security
- **Status:** Fixed 2026-10-23 — the Authorization header is written to a mode-600 temp file (`mktemp`) and passed via `-H @"$AUTH_FILE"` on all curl calls; removed from argv, cleaned up by `trap … EXIT`. Verified: mock server receives the correct Bearer token.
- **Issue:** `-H "Authorization: Bearer $OPENHAB_TOKEN"` puts the token into curl's argv, readable via `ps eww` / `/proc/*/cmdline` by other local users. Low impact on single-user machines, but this is an agent-facing CLI that may run unattended.
- **Fix:** pass the header from a 0600 temp file (`curl -H @file`) or via `--config`; at minimum document the exposure.

### M3. Webhooks promised in description but no longer documented — FIXED
- **File:** `SKILL.md:3`, `README.md:3`
- **Category:** Docs
- **Status:** Fixed 2026-10-23 — added a "Webhooks (Inbound)" section to both docs (openHAB rule → HTTP action POSTing JSON to the agent's endpoint).
- **Issue:** Both descriptions promise "receive webhook events / bidirectional communication", but after removing the Clawdbot section there is no setup instruction left anywhere in the repo. Dangling feature claim.
- **Fix:** add a short webhooks section (openHAB rule → HTTP action to the agent's endpoint) or soften the description until it exists.

### M4. `_meta.json` slug mismatch / registry metadata in git — FIXED
- **File:** `_meta.json:3`
- **Category:** Docs / Hygiene
- **Status:** Fixed 2026-10-23 — slug corrected to `openhab`. Later resolved fully: `_meta.json` removed from git and added to `.gitignore` (ClawHub-generated registry state, not source).
- **Issue:** `"slug": "home-assistant"` while the skill is named `openhab` — likely inherited from an upstream home-assistant skill this repo was forked from. Publishing under the wrong slug can shadow or conflict with another skill. `ownerId`/`publishedAt` are registry state; decide whether they belong in version control at all.
- **Fix:** set slug to `openhab`; move or regenerate registry metadata as appropriate for your publishing flow.

### M5. No curl timeouts — a hung openHAB blocks the CLI forever — FIXED
- **File:** `scripts/oa.sh` (all curl calls)
- **Category:** Robustness
- **Status:** Fixed 2026-10-23 — all curl calls use a shared `CURL_OPTS=(--connect-timeout 5 --max-time 10)`; verified against a black-hole IP (bails at ~5s with curl error 28).
- **Issue:** If the instance is up but not responding, every command hangs indefinitely; an agent waiting on it stalls too.
- **Fix:** add `--connect-timeout 5 --max-time 10` (or make it configurable via env var).

### M6. GET commands still reported success on HTTP errors (H1 class) — FIXED
- **File:** `scripts/oa.sh` (`state`/`attributes`/`thing-status` cases; now `scripts/openhab.sh`)
- **Category:** Bug / Security
- **Status:** Fixed 2026-10-25 — found during the pre-publication audit; GET commands capture `%{http_code}` like on/off (non-2xx → ✗ + exit 1), every curl call is silent (`-s`) and has a curl-error handler for network failures; verified against a mock server (404 → ✗, exit 1).
- **Issue:** The H1 fix covered only on/off. The GET commands piped raw bodies: a 404 (missing item) produced empty output with exit 0 — an agent could read "no state" as success — and a 401 printed the error body as if it were data.
- **Fix:** apply the on/off status-code pattern to all GETs; add `curl error` handling for connection failures.

### M7. `list <type>` plural normalization broken for "-es" words — FIXED
- **File:** `scripts/oa.sh` (`list` case; now `scripts/openhab.sh`)
- **Category:** Bug
- **Status:** Fixed 2026-10-25 — `-es` stems are stripped before a trailing `s` ("switches" → "switch"); mock-verified (`switches`/`switch`/`dimmers` all match their types).
- **Issue:** The code comment promised `switches -> switch`, but `${filter%s}` strips a single `s`, leaving `switche`, which matches no type — `list switches` silently returned nothing. Docs only showed singular forms, so this stayed unnoticed.
- **Fix:** strip `es` when present, otherwise `s`.

---

## P2 — Low

### L1. Dead code: unused `api()` function with wrong content type — FIXED
- **File:** `scripts/oa.sh`
- **Status:** Fixed 2026-10-23 — removed; each case builds its own curl call with the correct headers.
- **Issue:** `api()` is defined but never called; it also hardcodes `Content-Type: application/json`, which would be wrong for the text/plain commands. Remove it or actually use it (with per-call headers).

### L2. Copy-paste errors in comments and usage strings — FIXED
- **File:** `scripts/oa.sh`
- **Status:** Fixed 2026-10-23 — the `attributes` case now says `attributes`, the `off` branch now says `off`; stray spaces in usage strings removed.
- **Issue:** In the `attributes` case, comment says `oa.sh state living_room` and the error string says `Usage: oa.sh state <item_id>` (should be `attributes`). The `off` branch's comment/usage say `oa.sh on …` / `Usage: oa.sh on <item_id> }` (should be `off`; also stray space before `}`).

### L3. Dependencies (`jq`, `curl`) not declared or checked — FIXED
- **File:** `scripts/oa.sh`, `README.md`
- **Status:** Fixed 2026-10-23 — startup loop checks both deps and exits 1 with a clear ✗ message (verified: empty PATH → "✗ required dependency 'jq' not found in PATH"); README documents the requirement.
- **Issue:** Both are required, but nothing verifies them — the old clawdbot metadata used to declare `requires.bins`. A missing `jq` produces a confusing failure in `attributes`/`list`. Add a startup check with a clear error and/or document dependencies in README.

### L4. Documentation inconsistencies between SKILL.md and README.md — FIXED
- **File:** `SKILL.md`, `README.md:16`, `references/api.md`
- **Issue:** README mentions the `HA_CONFIG` override, SKILL.md doesn't; URL examples differ (`https://…duckdns.org` vs `http://localhost:8080`) without explaining when each applies; `api.md` hardcodes `http://localhost:8080` instead of using `${OPENHAB_URL}`.
- **Status:** Fixed 2026-10-23 — SKILL.md now documents the `HA_CONFIG` override, setup examples are identical across both files (HTTPS config / LAN env var), and all `api.md` examples use `${OPENHAB_URL}`.

### L5. Orphaned sentence fragment in SKILL.md — FIXED
- **File:** `SKILL.md:46`
- **Issue:** "Checking state of item_name" sat between the heading and the code block — leftover from an earlier edit; reads as a broken paragraph.
- **Status:** Fixed 2026-10-23 — fragment removed.

### L6. Style nits in oa.sh — FIXED
- **File:** `scripts/oa.sh` (trailing whitespace), inconsistent quoting (`-X 'POST'` vs `-X POST`) throughout.
- **Status:** Fixed 2026-10-23 — trailing whitespace removed, `-X POST` quoting unified (double quotes).

### L7. Repo hygiene: no LICENSE, no .gitignore — FIXED
- **File:** repo root
- **Status:** Fixed 2026-10-23 — added MIT `LICENSE` and `.gitignore` (ignores the old `token` file + OS cruft).
- **Issue:** No license file for a published skill; no `.gitignore` — the previously tracked `token` secret (see H4) shows how easily local files end up in git.

### L8. Least-privilege token guidance missing — FIXED
- **File:** `SKILL.md:34`, `README.md:39`
- **Issue:** Docs say "select a Token Scope" but don't recommend the minimal scope (e.g., Items only) or a dedicated non-admin user; no note about hardening if the instance is internet-exposed via duckdns (reverse proxy + TLS, consider IP allowlist).
- **Status:** Fixed 2026-10-23 — step 4 now recommends the narrowest scope (`Items`), plus a least-privilege/internet-exposure note in both docs.

---

## Suggested fix order

1. **H4** — rotate the openHAB token now (one-time action in the openHAB UI); the old one is public via GitHub history
2. **H1** — one-line change (`-f` + exit check), removes the false-success bug
3. **M5 + M1** — timeouts and item validation in `oa.sh` while touching it anyway
4. **H2 + H3 + L8** — doc pass on TLS, config permissions, token scope (one editing session)
5. **M3 + M4 + L4 + L5** — remaining doc consistency fixes
6. **L1–L3, L6–L7** — cleanup sweep
