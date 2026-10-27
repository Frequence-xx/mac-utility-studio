# Licensing, Updates and Release (Milestone 03) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Polar sandbox purchase activates, validates and deactivates Tegel Markdown Pro end to end. Sparkle updates 1.0.0-b1 → 1.0.0-b2 through a signed feed served locally (betas never reach the public R2 feed, K7). `scripts/release.sh` gives a notarised, stapled DMG that passes Gatekeeper on a clean Mac.

**Architecture:** TegelStore (second library in `Packages/TegelKit`) holds a pure grace policy, a URLSession Polar client, a Security.framework Keychain store and an `@Observable` `LicenseManager` that feeds the app's existing `isPro` seam. Polar values reach Info.plist through xcconfig (D16), and Sparkle 2.10.1 comes in over SPM. One bash release script runs native tools (xcodebuild, notarytool, stapler, hdiutil, codesign, spctl), then `generate_appcast`, then a curl SigV4 upload to R2's S3 endpoint (no npm code runs while the signing keys are unlocked).

**Tech Stack:** Swift 6 / SwiftPM tools 6.0, Swift Testing, Security.framework, URLSession, SwiftUI, XcodeGen 2.46, Sparkle 2.10.1, Polar customer-portal licence API, Cloudflare R2 through its S3 API with `curl --aws-sigv4` (curl ≥ 7.75; macOS 15 ships 8.x), bash.

**Spec:** `BUSINESS-PLAN.md` (§5 rules 3 and 5, §6.4, §7.3, §7.4, §13 risk 7); `docs/superpowers/plans/2026-10-27-00-master-roadmap.md` (Global constraints, Review focus 5, D5, D12, D14–D16, §3.3, §5 H2/H4/H5, §6); facts `docs/research/2026-10-27-technical-facts.md` [F#]; rules `CLAUDE.md`.

**When / where:** **W4, Tue 17 – Mon 23 Nov 2026**, on branch `m03-commerce-release` (created in Task 4). Earlier: Task 1 (W1; it owns the Polar sandbox, master H5), Task 2 (W3) and Task 3 Steps 1–4 (H2, done Tue 27 Oct).
**Assumed done:** plans 01–02, merged into `main`. They provide `project.yml` (App 1 + Quick Look extension), the `TegelKit` library, the `isPro` seam with a Debug override in `Apps/Markdown/App/ProGate.swift`, `Config/{Debug,Release}.xcconfig` and `ci.yml`. Plan 04 provides the Cloudflare account and the `tegelapps.com` zone.

## Global Constraints

Master "Global constraints", master §3.3 (the TegelStore contract) and CLAUDE.md apply. This plan's deltas:

- **Licence rules:** master GC (K5); Tasks 4–7 implement them; the app sends no API token.
- **Sandbox product:** $19, 2 Macs (the live $14 intro price is plan 05, D15). Polar can't toggle payment methods [F3g], so BNPL is inspected and recorded (product rule 7).
- **D5 entitlements:** `app-sandbox`, `files.user-selected.read-write`, `files.bookmarks.app-scope`, `network.client`, plus Sparkle's mach-lookup exception [F4]. The Quick Look extension gets no Sparkle and no TegelStore. `scripts/entitlements/<target>.plist` is the allowlist `release.sh` enforces (K7).
- **D16:** `Debug.xcconfig` → sandbox; `Release.xcconfig` → production (placeholder until plan 05). The Info.plist keys are exactly `TGPolarAPIBase`, `TGPolarOrganizationID`, `TGPolarCheckoutURL`, `TGPolarPortalURL`, `TGPolarBenefitID`.
- **Benefit binding (D1, ships in 1.0.0):** a key unlocks only the app whose Polar benefit issued it. `validate` sends `benefit_id`; `activate` checks `license_key.benefit_id`, and on a mismatch releases the activation and throws `PolarError.wrongProduct`. One benefit id per app.
- **D12 and Sparkle:** DMG via `hdiutil`; DMG and appcast on R2 bucket `tegel-downloads` behind `https://downloads.tegelapps.com`. **Sparkle 2.10.1 exactly** [F4]; `SUFeedURL` = `https://downloads.tegelapps.com/markdown/appcast.xml`; signed feed (`SURequireSignedFeed` and `SUVerifyUpdateBeforeExtraction` both true, K7); `SUEnableSystemProfiling` stays off.
- **Betas are private (K7):** b1 and b2 are `--sandbox --no-upload` builds, served to the test account from a local signed feed. Nothing beta ever reaches R2.
- **Keys at rest (K3):** the Keychain holds the Developer ID key, the `tegel-notary` profile and the Sparkle EdDSA key. After each one-time import, the plaintext key files move to the user's encrypted offline store and are deleted from `$HOME`. `.env` holds no key path.
- **Ask the user first:** enabling R2 (it may need a card), DNS on live `tegelapps.com`, any upload to R2, the sandbox close-out (Task 15), and anything in **production** Polar (untouched until plan 05).
- **MoR-agnostic (§13 risk 7):** only `PolarClient.swift` knows Polar. A Lemon Squeezy fallback rewrites that one file.

## Review Focus

Master Review focus 5 belongs to this plan. Most likely first:

1. **Offline at launch, or Polar 5xx** → Pro stays on within 30 days of the last 200, no launch error. Pinned by `refreshOfflineWithinGraceStaysPro`, `refresh5xxWithinGraceStaysPro`, `initAppliesPolicyToStoredLicence` (Task 7); Task 13 step 11.
2. **Polar 404** (retired API version, revoked key, activation removed in the portal) → exactly like offline: grace, key kept, a later 200 restores Pro. Pinned by `refresh404WithinGraceNeverLocks`, `refresh404AfterGraceIsLapsedAndKeepsKey`, `refreshAfterLapseWith200RestoresPro` (Task 7); Task 13 step 14.
3. **Clock moved backwards** (`now < lastValidatedAt`) → Pro within a 1-day skew; beyond it `.lapsed` until the next 200, and `lastValidatedAt` is never moved by a failure. Pinned by `smallBackwardSkewStaysPro`, `clockMovedBackwardsBeyondSkewIsLapsedWithoutMovingStamp`, `futureStampBeyondSkewIsLapsed` (Task 4), `refreshWithClockBackwardsKeepsLastValidatedAt` (Task 7).
4. **Activation limit reached, or an unknown key** → specific copy, state stays free, nothing stored. Pinned by `activateMapsErrors` (Task 5), `activateLimitReachedThrowsAndStaysFree` (Task 7); Task 13 step 13.
5. **Key pasted with spaces or newlines**, including a line break inside the key from a wrapped email → normalised before it is sent or stored. Pinned by `normalisedKeyStripsAllWhitespace`, `activateSendsNormalisedKeyAndModelLabelThenStores` (Task 7).

Also pinned:
- A 200 counts only with `status == "granted"` and the stored activation id; a block page, a stub or a drifted body is a failure that goes through grace (`validate200WithoutGrantedMatchingActivationIsFailure`).
- A deactivate racing a refresh can't resurrect a licence (`refreshDoesNotResurrectLicenceDeletedMidFlight`).
- A lapsed licence whose activation is gone can be removed from the Licence tab, so the key can be entered again (`lapsedLicenceCanBeRemoved`).
- One activate/deactivate at a time (`concurrentActivateSendsOneRequest`), and a Keychain save failure releases the new activation (`activateKeychainSaveFailureRollsBack`).
- A key for another Tegel app is rejected, its activation released and nothing stored (`activateWrongBenefitDeactivatesAndThrows`, `activateWrongProductThrowsAndStaysFree`; Task 13 step 13).
- The release guards (dirty tree, missing key, placeholder values, bad args, private betas, `--print-config` paths, `--from-dmg` checks including the app's identity, the entitlement allowlist, no store flag in the direct build, a locked screen, a version already published) are covered by `scripts/release_test.sh`.

## H2 dependency (Developer ID)

**H2 is done (Tue 27 Oct 2026):** the Developer ID certificate and the `tegel-notary` profile exist (Task 3 Steps 1–4, now verify-only). These steps needed it and are no longer blocked:
- Task 11 step 5 (signed archive check);
- Task 12 step 7 (first real `release.sh` run);
- all of Task 13 (the private b1/b2 builds, Gatekeeper, the Sparkle update, and the purchase on a notarised build).

Task 3 Step 5 (keys at rest, K3) still runs before them.

## Conventions used in every task

- **Shell:** every command runs from the repo root. Each Bash call is a fresh shell, so no block relies on a function or variable from another block.
- **`.env`:** any command that reads or writes `.env` starts with `. scripts/lib/env.sh` (plan 01 Task 1). It gives `envget KEY` (prints the value, so its output only ever goes into a variable or a pipe, never to the log), `envset KEY VALUE` (quoted, atomic, mode 600) and `need KEY…` (exit 1 with `missing .env key: KEY`; prints names only). "Saved" checks are `need KEY && echo saved`.
- **Swift tests:** `swift test --package-path Packages/TegelKit --filter <Suite>`.
- **Commits:** "Commit: `<paths>`, `<message>`" means `git add <paths> && git commit -m "<message>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`.

**GUI steps** are marked *(GUI)*. The user does them, or Claude does them through the computer-use skill. Playwright is used for web dashboards only.

---

### Task 1: Polar sandbox org, product, licence benefit, checkout link (W1, done by Mon 2 Nov)

Needs H3 (studio inbox) and H5 (sandbox org). Sandbox only, so no confirmation is needed.

**Files:**
- None in the repo. Writes `.env` keys and a gitignored screenshot `local-docs/m03/bnpl-sandbox.png`.

**Interfaces:**
- Consumes: `.env` `STUDIO_EMAIL` (H3).
- Produces these `.env` names, used by Tasks 8, 9, 13 and 15: `POLAR_EMAIL`, `POLAR_SANDBOX_ORGANIZATION_ID`, `POLAR_SANDBOX_BENEFIT_ID_MARKDOWN`, `POLAR_SANDBOX_PRODUCT_ID_MARKDOWN`, `POLAR_SANDBOX_CHECKOUT_URL_MARKDOWN`, `POLAR_SANDBOX_PORTAL_URL`, `POLAR_SANDBOX_TEST_LICENSE_KEY`, and `POLAR_SANDBOX_OTHER_LICENSE_KEY` (step 10, used by Task 13).

- [ ] **Step 1: Sign up.** Playwright `browser_navigate` to `https://sandbox.polar.sh/start` and sign up with the H3 inbox (`. scripts/lib/env.sh; envget STUDIO_EMAIL`); the **user** enters the emailed code. Then `. scripts/lib/env.sh; envset POLAR_EMAIL "$(envget STUDIO_EMAIL)"; need POLAR_EMAIL && echo saved` → `saved`.
- [ ] **Step 2: Create the org.** Name `Tegel`, slug `tegelapps` (or the nearest free slug). Copy the organization ID from org settings and `. scripts/lib/env.sh; envset POLAR_SANDBOX_ORGANIZATION_ID '<id>'`. Check that the saved id is well formed (step 9 proves it is the right org):
  ```bash
  . scripts/lib/env.sh
  curl -s -o /dev/null -w '%{http_code}\n' -X POST https://sandbox-api.polar.sh/v1/customer-portal/license-keys/validate \
    -H 'Content-Type: application/json' -d "{\"key\":\"NOPE\",\"organization_id\":\"$(envget POLAR_SANDBOX_ORGANIZATION_ID)\"}"
  ```
  Expected: `404` (key not found). `422` means the id was saved wrong.
- [ ] **Step 3: Create the benefit.** Benefits → New → type **License Keys**: description `Tegel Markdown licence`, no expiry, no usage limit, **activation limit 2**, **customer can deactivate activations ON** (`enable_customer_admin`) [F3e]. Then `. scripts/lib/env.sh; envset POLAR_SANDBOX_BENEFIT_ID_MARKDOWN '<id>'`.
- [ ] **Step 4: Create the product.** Products → New → `Tegel Markdown`, **one-time, $19 USD**, with the benefit from step 3 attached.
  - Description (states the limits before purchase, rule 5): `One-time purchase. One licence activates Tegel Markdown Pro on up to 2 Macs. 14-day refund.`
  - Then `. scripts/lib/env.sh; envset POLAR_SANDBOX_PRODUCT_ID_MARKDOWN '<id>'`.
- [ ] **Step 5: Create a checkout link** for the product, then `. scripts/lib/env.sh; envset POLAR_SANDBOX_CHECKOUT_URL_MARKDOWN '<url>'`. Check: `. scripts/lib/env.sh; curl -s -o /dev/null -w '%{http_code}\n' -L "$(envget POLAR_SANDBOX_CHECKOUT_URL_MARKDOWN)"` → `200`.
- [ ] **Step 6: Find the portal URL.** Polar documents `https://polar.sh/<slug>/portal` for production but no sandbox URL (polar.sh/docs/features/customer-portal/navigate-customers.md).
  - Test: `curl -s -o /dev/null -w '%{http_code}\n' https://sandbox.polar.sh/tegelapps/portal` → `200`, and Playwright shows an email sign-in form.
  - If it isn't 200, take the portal link from the dashboard's customer-portal settings instead.
  - Then `. scripts/lib/env.sh; envset POLAR_SANDBOX_PORTAL_URL '<url>'`.
- [ ] **Step 7: Test purchase, with a BNPL look.**
  - Open the checkout link in Playwright.
  - Email = the `POLAR_EMAIL` value. Sandbox emails reach org members only (polar.sh/docs/integrate/sandbox.md).
  - **Before paying**, set the billing country to **Netherlands**, then to **United States**, and list every payment method offered. Save `browser_take_screenshot` to `local-docs/m03/bnpl-sandbox.png`.
  - If any pay-later method appears (Klarna, Afterpay, Affirm, Riverty, "pay in 3"), **stop and tell the user** (product rule 7).
  - Pay with `4242 4242 4242 4242`, any future expiry, any CVC.
  - Result: the order shows in Sales.
- [ ] **Step 8: Get the key.**
  - Note whether the order email to `POLAR_EMAIL` contains the key; the docs only promise it in the portal (polar.sh/docs/features/benefits/license-keys.md).
  - Copy the key from the portal and `. scripts/lib/env.sh; envset POLAR_SANDBOX_TEST_LICENSE_KEY '<key>'`. Never echo it.
- [ ] **Step 9: Check that the 2-Mac limit is enforced server-side** [F3a, F3c, F3e]. The response bodies contain the key, so they go to a temp file that is deleted:
  ```bash
  . scripts/lib/env.sh
  O=$(envget POLAR_SANDBOX_ORGANIZATION_ID); K=$(envget POLAR_SANDBOX_TEST_LICENSE_KEY); A=https://sandbox-api.polar.sh/v1/customer-portal/license-keys; T=$(mktemp)
  act()   { curl -s -o "$T" -w '%{http_code}\n' -X POST "$A/activate" -H 'Content-Type: application/json' -d "{\"key\":\"$K\",\"organization_id\":\"$O\",\"label\":\"$1\"}"; }
  deact() { curl -s -o /dev/null -w '%{http_code}\n' -X POST "$A/deactivate" -H 'Content-Type: application/json' -d "{\"key\":\"$K\",\"organization_id\":\"$O\",\"activation_id\":\"$1\"}"; }
  act probe-1; I1=$(plutil -extract id raw -o - "$T"); act probe-2; I2=$(plutil -extract id raw -o - "$T"); act probe-3
  deact "$I1"; deact "$I2"; rm -f "$T"
  ```
  Expected: `200`, `200`, `403`, `204`, `204`.
- [ ] **Step 10: A key from another app (the D1 test fixture).** Task 13 step 13 uses it to prove the benefit binding.
  - Benefits → New → **License Keys**: description `Tegel Test Other licence`, activation limit 2, `enable_customer_admin` ON.
  - Products → New → `Tegel Test Other (not for sale)`, one-time $19, with only that benefit attached. Create a checkout link and buy it as in step 7 (test card; the BNPL look isn't repeated).
  - Copy the key from the portal and `. scripts/lib/env.sh; envset POLAR_SANDBOX_OTHER_LICENSE_KEY '<key>'`. Never echo it. Result: `. scripts/lib/env.sh; need POLAR_SANDBOX_OTHER_LICENSE_KEY && echo saved` → `saved`.

No commit: the outputs are gitignored. Task 4 adds the new key names to `.env.example`.

### Task 2: R2 bucket, `downloads.tegelapps.com`, scoped token (W3, by Mon 16 Nov)

Needs plan 04's Cloudflare account and the `tegelapps.com` zone, plus H4's card. **Enabling R2 may need a card, and the custom domain adds DNS on a live domain, so each gets its own ask first.**

**Files:**
- None in the repo; writes `.env` keys.

**Interfaces:**
- Produces these `.env` names, used by Task 12: `R2_BUCKET`, `R2_PUBLIC_BASE_URL`, `CLOUDFLARE_ACCOUNT_ID` (if plan 04 hasn't set it), `CLOUDFLARE_R2_API_TOKEN`, and the token's S3 credentials `R2_ACCESS_KEY_ID` and `R2_SECRET_ACCESS_KEY`.

- [ ] **Step 1: Enable R2** in the dashboard (Playwright).
  - Ask the user first: "Enable R2 on the Cloudflare account? It may ask for a card; our use stays inside the free tier."
  - After a yes, enable it. If it asks for a payment method and none is on file, that's H4 (user) [F8: unverified whether the free tier needs a card]. Result: the R2 Overview loads.
- [ ] **Step 2: Create the bucket** `tegel-downloads`: automatic location, Standard class, r2.dev public URL **left disabled**. Then `. scripts/lib/env.sh; envset R2_BUCKET tegel-downloads`.
- [ ] **Step 3: Connect the domain.**
  - Ask the user first: "Connect `downloads.tegelapps.com` to bucket `tegel-downloads` (adds a DNS record on tegelapps.com)?"
  - Then: bucket → Settings → Custom Domains → Connect → `downloads.tegelapps.com`, **minimum TLS 1.2** (the default is 1.0, per developers.cloudflare.com/workers/wrangler/commands/r2/).
  - `. scripts/lib/env.sh; envset R2_PUBLIC_BASE_URL https://downloads.tegelapps.com`.
  - Check: `dig +short downloads.tegelapps.com | head -1` prints an address, and the dashboard shows the domain as Active.
- [ ] **Step 4: Create the token.** R2 → Manage API tokens → Create:
  - permission **Object Read & Write**, applied to **`tegel-downloads` only**;
  - `. scripts/lib/env.sh; envset CLOUDFLARE_R2_API_TOKEN '<token>'`; then `. scripts/lib/env.sh; need CLOUDFLARE_ACCOUNT_ID && echo saved`, and if it exits 1, copy the id from the dashboard and `. scripts/lib/env.sh; envset CLOUDFLARE_ACCOUNT_ID '<id>'`.
  - The same page shows the token's **S3 credentials, once**: the Access Key ID and the Secret Access Key (developers.cloudflare.com/r2/api/tokens/; check the wording on the day). Copy each the moment it's shown and save it without it touching a command line: `. scripts/lib/env.sh && envset R2_ACCESS_KEY_ID "$(pbpaste)" && pbcopy </dev/null`, then the same with `R2_SECRET_ACCESS_KEY`. Check: `. scripts/lib/env.sh; need R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY && echo saved` → `saved`.
  - This bucket-scoped token, through those S3 credentials, is the only credential any R2 upload uses (K2). Plan 04's Pages deploy token has no R2 permission.
- [ ] **Step 5: Verify the S3 credentials with the release script's upload command.** `release.sh` uploads with `curl --aws-sigv4` against R2's S3 endpoint `https://<account id>.r2.cloudflarestorage.com`, region `auto` (developers.cloudflare.com/r2/api/s3/api/; check it on the day), so no npm code runs at release time. This probe uses the same command.
  - **Ask the user first** (Global Constraints: any upload to R2): "Upload one 2-byte test object `probe.txt` to `tegel-downloads`, read it back through `downloads.tegelapps.com`, then delete it?" Run the block only after a yes.
  ```bash
  . scripts/lib/env.sh
  KID=$(envget R2_ACCESS_KEY_ID); SEC=$(envget R2_SECRET_ACCESS_KEY); S3="https://$(envget CLOUDFLARE_ACCOUNT_ID).r2.cloudflarestorage.com/tegel-downloads"   # not exported
  curl --version | head -1
  T=$(mktemp); printf ok > "$T"
  curl -s -o /dev/null -w 'unsigned %{http_code}\n' -T "$T" "$S3/probe.txt"
  curl -s -o /dev/null -w 'put %{http_code}\n' --aws-sigv4 "aws:amz:auto:s3" --user "$KID:$SEC" -H 'Content-Type: text/plain' -H 'Cache-Control: no-store' -T "$T" "$S3/probe.txt"
  curl -sI https://downloads.tegelapps.com/probe.txt | grep -ciE '^(HTTP/2 200|content-type: text/plain|cache-control: no-store)'
  curl -s -o /dev/null -w 'tls1.1 %{http_code}\n' --tls-max 1.1 https://downloads.tegelapps.com/probe.txt
  curl -s -o /dev/null -w 'delete %{http_code}\n' --aws-sigv4 "aws:amz:auto:s3" --user "$KID:$SEC" -X DELETE "$S3/probe.txt"
  rm -f "$T"
  ```
  Expected: `curl 8.…` (anything ≥ 7.75.0, the first with `--aws-sigv4`), then `unsigned` with any code but `200` (watched failing: the upload needs the signature), `put 200`, `3` (the public HEAD returns the object with both headers R2 stored), `tls1.1 000`, `delete 204`.
  - If the signed `put` fails with a payload-hash error, add `-H 'x-amz-content-sha256: UNSIGNED-PAYLOAD'` here and to `release.sh`'s `r2put`, and record which form worked. If it fails with an auth error, **don't widen** the token to an account-level R2 token (K2 rejects that). Stop, record the error, and ask the user how to proceed.

No commit; Task 4 adds `CLOUDFLARE_R2_API_TOKEN`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET` and `R2_PUBLIC_BASE_URL` to `.env.example`.

### Task 3: Developer ID certificate and notarytool profile (H2)

**Status:** Steps 1–4 were **done on Tue 27 Oct 2026** (H2 landed early): the Developer ID Application certificate (G2 Sub-CA, expires **Fri 26 Nov 2027**), the `tegel-notary` profile and the `.env` keys. Each step below now only verifies. Step 5 (K3) is still to run, on Tue 17 Nov with the other Claude steps; Step 6 is the 2027 renewal.

**Files:** none in the repo; writes `.env` keys, the Keychain and the user's encrypted offline key store (K3).

**Interfaces:**
- Produces these `.env` names, used by Tasks 11–13: `APPLE_DEVELOPER_ID_IDENTITY`, `APPLE_TEAM_ID`, `ASC_API_KEY_ID`, `ASC_API_ISSUER_ID` (Team keys only), `NOTARY_KEYCHAIN_PROFILE`. No key path: `ASC_API_KEY_PATH` is set on 27 Oct and Step 5 empties it, because the `.p8` doesn't stay on disk.
- Keychain: the Developer ID identity and the `tegel-notary` profile.
- The offline key store, `TegelKeys` (default: an encrypted APFS image the user keeps on external media). Task 10 adds the Sparkle key to it.

- [ ] **Step 1: The certificate (done 27 Oct; verify).**
  - Run: `security find-identity -v -p codesigning | grep -c '"Developer ID Application:'; security find-certificate -c "Developer ID Application" -p | openssl x509 -noout -enddate`
  - Expected: `1`, then `notAfter=Nov 26 11:25:05 2027 GMT`. If the count is `0`, the identity is gone: re-import `~/.tegel-signing/devid-application.key` (`security import … -t priv -f openssl -T /usr/bin/codesign`) and the `.cer` beside it into the login Keychain, or after Step 5 the key from `TegelKeys`.
  - **First use (CR-P2-27):** the first `codesign` with this key (Task 11 step 5) raises a Keychain prompt, "codesign wants to sign using key …". The **user** types the login password and clicks **Always Allow**, once. Record the date in `docs/gates/m03-acceptance.md` (Task 13 step 16). Until then a non-interactive `release.sh` would stall on that prompt.
- [ ] **Step 2: The identity and team id in `.env` (done 27 Oct; verify without printing them).**
  ```bash
  . scripts/lib/env.sh
  need APPLE_DEVELOPER_ID_IDENTITY APPLE_TEAM_ID && echo saved
  ID=$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application: [^"]*\)"/\1/p' | head -1)
  [ "$(envget APPLE_DEVELOPER_ID_IDENTITY)" = "$ID" ] && [ "$(envget APPLE_TEAM_ID)" = "$(printf '%s' "$ID" | sed -n 's/.*(\([A-Z0-9]*\))$/\1/p')" ] && echo match; unset ID
  ```
  Expected: `saved`, then `match`. On a mismatch, `envset APPLE_DEVELOPER_ID_IDENTITY "$ID"` and `envset APPLE_TEAM_ID` with the id in its trailing parentheses (K1 quoting handles the spaces and parentheses).
- [ ] **Step 3: The App Store Connect API key (done 27 Oct; verify).** The `.p8` is in `~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8`, not in `~/.tegel-secrets/`; Step 5 moves it.
  - Run: `. scripts/lib/env.sh; need ASC_API_KEY_ID ASC_API_ISSUER_ID && test -f ~/.appstoreconnect/private_keys/"AuthKey_$(envget ASC_API_KEY_ID).p8" && echo ok`
  - Expected: `ok`.
- [ ] **Step 4: The notary credentials (done 27 Oct; verify).**
  - Run: `. scripts/lib/env.sh; [ "$(envget NOTARY_KEYCHAIN_PROFILE)" = tegel-notary ] && xcrun notarytool history --keychain-profile tegel-notary >/dev/null && echo notary-ok`
  - Expected: `notary-ok`.
  - Run it with the Mac **unlocked**: with the screen locked, the same command printed "No Keychain password item found for profile: tegel-notary" although the profile was intact (build Mac, 27 Oct). `release.sh` refuses to start on a locked screen (Task 12).
  - The profile holds the key's contents, not its path: with the `.p8` moved aside, `notarytool history --keychain-profile tegel-notary` still succeeded (build Mac, 27 Oct). So Step 5 can take the plaintext off disk without breaking notarisation.
  - If the profile is ever lost: `xcrun notarytool store-credentials tegel-notary --key <the .p8 from TegelKeys> --key-id "$KID" ${ISS:+--issuer "$ISS"}` (`--issuer` is "Required for Team API Keys. Do not provide for Individual API Keys", `xcrun notarytool store-credentials --help` on Xcode 26.3).
- [ ] **Step 5: Keys at rest (K3).** The Keychain holds both keys, so the plaintext files leave `$HOME`.
  1. **Gather the `.p8`, then watch the check fail first:**
     ```bash
     . scripts/lib/env.sh
     mkdir -p ~/.tegel-secrets && chmod 700 ~/.tegel-secrets
     mv ~/.appstoreconnect/private_keys/"AuthKey_$(envget ASC_API_KEY_ID).p8" ~/.tegel-secrets/ && chmod 600 ~/.tegel-secrets/*.p8
     find ~/.tegel-signing ~/.tegel-secrets -type f \( -name '*.key' -o -name '*.p8' -o -name '*.p12' \) 2>/dev/null
     ```
     Expected: two paths, `devid-application.key` and `AuthKey_<KEYID>.p8`. Only this app's key moves; any other `.p8` in `~/.appstoreconnect/private_keys/` isn't Tegel's and stays.
  2. **Ask the user where the encrypted store lives** (USER item K3). Default: an AES-256 encrypted APFS image on external media, with its passphrase in the user's password manager. For the default, the **user** runs this in Terminal, because both commands prompt for the passphrase:
     `hdiutil create -size 20m -fs APFS -encryption AES-256 -volname TegelKeys ~/TegelKeys.dmg && hdiutil attach ~/TegelKeys.dmg`
  3. Claude copies each file, checks the copy, deletes the original, empties the key path in `.env`, and confirms nothing broke:
     ```bash
     . scripts/lib/env.sh
     for f in $(find ~/.tegel-signing ~/.tegel-secrets -type f \( -name '*.key' -o -name '*.p8' -o -name '*.p12' \)); do
       cp -p "$f" /Volumes/TegelKeys/ && cmp -s "$f" "/Volumes/TegelKeys/${f##*/}" && rm "$f"
     done
     ls /Volumes/TegelKeys; hdiutil detach /Volumes/TegelKeys
     envset ASC_API_KEY_PATH ''
     find ~/.tegel-signing ~/.tegel-secrets -type f \( -name '*.key' -o -name '*.p8' -o -name '*.p12' \) 2>/dev/null | wc -l
     [ -z "$(envget ASC_API_KEY_PATH)" ] && echo no-path
     security find-identity -v -p codesigning | grep -c '"Developer ID Application:'
     xcrun notarytool history --keychain-profile tegel-notary >/dev/null && echo notary-ok
     ```
     Expected: the two file names, then `0`, `no-path`, `1`, `notary-ok`. Step 4 already showed the profile works without the `.p8` on disk; a `notary-ok` failure here is something else, so record the error and ask the user.
  4. The **user** moves `~/TegelKeys.dmg` to the external media and deletes the local copy.
- [ ] **Step 6: Renew the certificate by Fri 12 Nov 2027** (it expires Fri 26 Nov 2027, 11:25 UTC). Apps already signed and notarised keep opening after it expires, because their signatures are timestamped, but no new build can be signed, so a missed renewal blocks every update and release.
  - Make a new key and CSR without printing values:
    ```bash
    . scripts/lib/env.sh
    (umask 077; openssl req -new -newkey rsa:2048 -nodes -keyout ~/.tegel-signing/devid-application-2027.key -out ~/.tegel-signing/devid-application-2027.csr \
      -subj "/CN=$(envget APPLE_DEVELOPER_LEGAL_NAME)/emailAddress=$(envget APPLE_ACCOUNT_EMAIL)")
    ```
  - The **user** uploads the CSR as a new **Developer ID Application** certificate (G2 Sub-CA); Claude imports the key and the `.cer` as in Step 1.
  - Delete the old certificate in Keychain Access (sort by expiry date): two identities with one name make the name in `APPLE_DEVELOPER_ID_IDENTITY` ambiguous to `codesign`. Then Step 1's check prints `1` and the new `notAfter`, and Step 2 prints `match`.
  - Run Task 11 step 5's signed archive check. Then the **user** attaches `TegelKeys` (`hdiutil attach <path>/TegelKeys.dmg`) and Claude runs Step 5 item 3, which moves `devid-application-2027.key` into the store; the expected counts are the same.

No commit.

### Task 4: Branch, TegelStore target, value types, LicensePolicy (Tue 17 Nov)

**Files:**
- Modify: `.env.example` (new names; the two key-path lines go, K3)
- Modify: `Packages/TegelKit/Package.swift`
- Create: `Packages/TegelKit/Sources/TegelStore/License.swift`
- Create: `Packages/TegelKit/Tests/TegelStoreTests/TestSupport.swift`
- Test: `Packages/TegelKit/Tests/TegelStoreTests/LicensePolicyTests.swift`

**Interfaces:**
- Consumes: nothing. TegelStore does **not** depend on TegelKit, so a Mac App Store target can drop it.
- Produces (master §3.3, verbatim):
  ```swift
  public struct PolarConfig: Sendable { public let apiBase: URL; public let organizationID: String; public let checkoutURL: URL; public let portalURL: URL
                                        public let benefitID: String                     // Info.plist TGPolarBenefitID; keys bind to one app (D1)
                                        public static func fromInfoPlist(_ bundle: Bundle = .main) -> PolarConfig }
  public struct StoredLicense: Codable, Sendable, Equatable { public let key: String; public let activationID: String; public var lastValidatedAt: Date }
  public enum LicenseState: Sendable, Equatable { case free; case pro(StoredLicense); case lapsed(StoredLicense) }
  public enum LicensePolicy { public static let grace: TimeInterval = 30 * 86_400
                              public static func state(stored: StoredLicense?, now: Date) -> LicenseState }
                              // .pro iff -1 day ≤ now − lastValidatedAt ≤ grace; otherwise .lapsed (K5)
  ```
- New, internal: `static let skew: TimeInterval = 86_400` on `LicensePolicy` (no contract change).
- Test support: `let t0 = Date(timeIntervalSince1970: 1_800_000_000)` and `let lic = StoredLicense(key: "K-1", activationID: "act_1", lastValidatedAt: t0)`. Tests use the internal memberwise inits via `@testable import TegelStore`.

- [ ] **Step 1: Branch and env names.**
  - Run `git checkout main && git pull --ff-only origin main && git checkout -b m03-commerce-release`.
  - Add these names, without values, to `.env.example`:
    - under `# --- Polar`: `POLAR_SANDBOX_PRODUCT_ID_MARKDOWN`, `POLAR_SANDBOX_BENEFIT_ID_MARKDOWN`, `POLAR_SANDBOX_PORTAL_URL`, `POLAR_SANDBOX_TEST_LICENSE_KEY`, `POLAR_SANDBOX_OTHER_LICENSE_KEY`;
    - under `# --- Cloudflare`: `CLOUDFLARE_R2_API_TOKEN`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`, `R2_PUBLIC_BASE_URL`.
  - Remove the `ASC_API_KEY_PATH` and `SPARKLE_PRIVATE_KEY_BACKUP_PATH` lines: the key files live offline (K3).
  - Commit: `.env.example`, "chore(env): name the m03 Polar sandbox and R2 keys; drop key paths (K3)".
- [ ] **Step 2: Write the failing test.**
  ```swift
  import Foundation
  import Testing
  @testable import TegelStore

  @Suite struct LicensePolicyTests {
      @Test func graceIsThirtyDays() { #expect(LicensePolicy.grace == 2_592_000) }
      @Test func noStoredLicenceIsFree() { #expect(LicensePolicy.state(stored: nil, now: t0) == .free) }
      @Test func proAt29Days23Hours() { #expect(LicensePolicy.state(stored: lic, now: t0 + 29 * 86_400 + 23 * 3_600) == .pro(lic)) }
      @Test func proAtExactly30Days() { #expect(LicensePolicy.state(stored: lic, now: t0 + LicensePolicy.grace) == .pro(lic)) }
      @Test func lapsedAt30DaysPlusOneSecond() { #expect(LicensePolicy.state(stored: lic, now: t0 + LicensePolicy.grace + 1) == .lapsed(lic)) }
      @Test func smallBackwardSkewStaysPro() { #expect(LicensePolicy.state(stored: lic, now: t0 - 3_600) == .pro(lic)) }   // a Mac clock 1 h behind
      @Test func clockMovedBackwardsBeyondSkewIsLapsedWithoutMovingStamp() {   // K5
          let state = LicensePolicy.state(stored: lic, now: t0 - 400 * 86_400)
          #expect(state == .lapsed(lic))
          guard case .lapsed(let kept) = state else { return }
          #expect(kept.lastValidatedAt == t0)
      }
      @Test func futureStampBeyondSkewIsLapsed() {                           // a forged Keychain item with lastValidatedAt far ahead
          let forged = StoredLicense(key: "K-1", activationID: "act_1", lastValidatedAt: t0 + 86_401)
          #expect(LicensePolicy.state(stored: forged, now: t0) == .lapsed(forged))
      }
  }
  ```
  - Declare the folder in `Package.swift` as `.testTarget(name: "TegelStoreTests")`, with no dependencies yet: SwiftPM skips an undeclared test folder, and `--filter` then passes with 0 tests (checked on the build Mac).
- [ ] **Step 3: Run it to verify it fails.** `swift test --package-path Packages/TegelKit --filter LicensePolicyTests`. Expected: FAIL, `error: no such module 'TegelStore'`.
- [ ] **Step 4: Implement.**
  - `Package.swift`: add `.library(name: "TegelStore", targets: ["TegelStore"])` and `.target(name: "TegelStore")`, and give the test target `dependencies: ["TegelStore"]`.
  - `License.swift`: the four types above, plus the internal `skew`.
  - `state`:
    - `nil` → `.free`;
    - `let age = now.timeIntervalSince(stored.lastValidatedAt)`; `-skew <= age && age <= grace` → `.pro(stored)`;
    - otherwise `.lapsed(stored)`. Policy never changes the stamp; only a 200 in `LicenseManager.refresh` moves it, which also restores Pro.
  - `fromInfoPlist` reads the five `TG*` strings with `bundle.object(forInfoDictionaryKey:)`. It calls `preconditionFailure("Info.plist: <key> missing or not a URL")` on absence, and also on an empty `TGPolarBenefitID`: a build-config bug must fail loudly (Task 8 and `release.sh` check the values).
- [ ] **Step 5: Run it to verify it passes.** Same command. Expected: `✔ Test run with 8 tests … passed`.
- [ ] **Step 6: Watch the skew guard fail.** Temporarily drop the lower bound (`age <= grace` alone, the old rule) and re-run. Expected: 2 failures, `clockMovedBackwardsBeyondSkewIsLapsedWithoutMovingStamp` and `futureStampBeyondSkewIsLapsed`. Restore the bound; the run is back to 8 passed.
- [ ] **Step 7: Commit:** `Packages/TegelKit/Package.swift Packages/TegelKit/Sources/TegelStore/License.swift Packages/TegelKit/Tests/TegelStoreTests`, "feat(store): add TegelStore with LicensePolicy, 30-day grace and 1-day skew".

### Task 5: PolarClient (Tue 17 Nov)

**`Polar-Version` decision: omit the header.**
- "If the header is omitted, Polar uses Current", and "a malformed, unknown, or removed version returns `404 Not Found`" (polar.sh/docs/api-reference/2026-10/versioning.md).
- **Pinning** guarantees that every install that never updates gets 404 about 9 months after release. With the 30-day grace, that install then loses Pro: a broken perpetual licence.
- **Omitting** fails only if Polar changes these endpoints' fields in a new Current version. The client limits that exposure:
  - it reads only `id`, `license_key.benefit_id` (activate), and `status`, `activation.id` and `expires_at` (validate);
  - every failure path goes through grace, so a drift costs nothing for 30 days.
- **Validate decodes (K5):** a 200 counts only if `status == "granted"` (the schema's only value, polar.sh/docs/api-reference/customer-portal/license-keys/validate, checked 27 Oct) and `activation.id` equals the stored activation id. A proxy block page, a naive stub or a drifted body is a failure, never a success. The quarterly check below catches a rename before the 30 days run out.
- Each quarter, while the new version sits in "Next" for 3 months, run Task 1 step 9 with `-H 'Polar-Version: <Next>'` (master §10 P3).

**Files:**
- Create: `Packages/TegelKit/Sources/TegelStore/PolarClient.swift`
- Modify: `Packages/TegelKit/Tests/TegelStoreTests/TestSupport.swift`
- Test: `Packages/TegelKit/Tests/TegelStoreTests/PolarClientTests.swift`

**Interfaces:**
- Consumes: `PolarConfig` (Task 4).
- Produces (§3.3 verbatim):
  ```swift
  public struct PolarClient: Sendable { public init(config: PolarConfig, session: URLSession = .shared)
      public func activate(key: String, label: String) async throws -> String          // activation id; license_key.benefit_id ≠ config.benefitID
                                                                                       //   → deactivates that activation, throws .wrongProduct
      public func validate(key: String, activationID: String) async throws -> Date?     // body adds benefit_id; expires_at; throws PolarError
                                                                                       //   a 200 without status "granted" + this activation id → .http(200)
      public func deactivate(key: String, activationID: String) async throws }
  public enum PolarError: Error, Equatable { case limitReached, notFound, http(Int), network, wrongProduct }
  ```
- Test support, added to `TestSupport.swift`:
  ```swift
  typealias StubHandler = @Sendable (URLRequest, [String: String]) throws -> (Int, Data)   // gets request + decoded JSON body
  func respond(_ status: Int, _ body: String = "{}") -> StubHandler
  let offline: StubHandler                       // throws URLError(.notConnectedToInternet)
  final class StubURLProtocol: URLProtocol {
      static func session(host: String, _ handler: @escaping StubHandler) -> URLSession   // ephemeral config, protocolClasses = [Self]
      static func requests(host: String) -> [(URLRequest, [String: String])] }           // in arrival order
  func stubConfig(host: String) -> PolarConfig   // apiBase https://<host>, organizationID "org-1", benefitID "ben-1"
  func stubbedClient(_ handler: @escaping StubHandler) -> (PolarClient, String)   // client + unique host "<uuid>.test"
  ```
- Stub implementation notes:
  - Handlers and requests live in a static dictionary keyed by `request.url!.host!` behind an `NSLock` (`nonisolated(unsafe) static var`). A unique host per test keeps Swift Testing's parallel runs apart.
  - **Read the body from `request.httpBodyStream`**: URLSession hands URLProtocol a stream, not `httpBody`.

- [ ] **Step 1: Write the failing test.**
  ```swift
  import Foundation
  import Testing
  @testable import TegelStore

  @Suite struct PolarClientTests {
      @Test func activateSendsExactBodyAndReturnsActivationID() async throws {
          let (client, host) = stubbedClient(respond(200, #"{"id":"act_1","license_key_id":"lk_1","label":"Test Mac","license_key":{"benefit_id":"ben-1"}}"#))
          #expect(try await client.activate(key: "K-1", label: "Test Mac") == "act_1")
          let (req, body) = try #require(StubURLProtocol.requests(host: host).first)
          #expect(req.httpMethod == "POST")
          #expect(req.url?.path == "/v1/customer-portal/license-keys/activate")
          #expect(req.value(forHTTPHeaderField: "Content-Type") == "application/json")
          #expect(body == ["key": "K-1", "organization_id": "org-1", "label": "Test Mac"])
          #expect(req.value(forHTTPHeaderField: "Authorization") == nil)   // public client: no token, ever
          #expect(req.value(forHTTPHeaderField: "Polar-Version") == nil)   // decision above
      }
      @Test(arguments: [(403, PolarError.limitReached), (404, .notFound), (422, .http(422))])
      func activateMapsErrors(status: Int, expected: PolarError) async {
          let (client, _) = stubbedClient(respond(status))
          await #expect(throws: expected) { try await client.activate(key: "K-1", label: "Test Mac") }
      }
      @Test func activateRightBenefitReturnsID() async throws {           // D1: a key binds to this app's benefit
          let (client, host) = stubbedClient(respond(200, #"{"id":"act_1","license_key":{"benefit_id":"ben-1"}}"#))
          #expect(try await client.activate(key: "K-1", label: "Test Mac") == "act_1")
          #expect(StubURLProtocol.requests(host: host).count == 1)          // nothing deactivated
      }
      @Test func activateWrongBenefitDeactivatesAndThrows() async throws {
          let (client, host) = stubbedClient(respond(200, #"{"id":"act_1","license_key":{"benefit_id":"ben-other"}}"#))
          await #expect(throws: PolarError.wrongProduct) { try await client.activate(key: "K-1", label: "Test Mac") }
          let reqs = StubURLProtocol.requests(host: host)
          #expect(reqs.count == 2)
          #expect(reqs.last?.0.url?.path == "/v1/customer-portal/license-keys/deactivate")
          #expect(reqs.last?.1 == ["key": "K-1", "organization_id": "org-1", "activation_id": "act_1"])
      }
      @Test func activateWithoutBenefitIDReleasesAndIsHTTP200() async { // API drift fails closed, no slot leaked
          let (client, host) = stubbedClient(respond(200, #"{"id":"act_1"}"#))
          await #expect(throws: PolarError.http(200)) { try await client.activate(key: "K-1", label: "Test Mac") }
          let reqs = StubURLProtocol.requests(host: host)
          #expect(reqs.count == 2)
          #expect(reqs.last?.0.url?.path == "/v1/customer-portal/license-keys/deactivate")
      }
      @Test(arguments: ["2027-01-01T00:00:00.000000Z", "2027-01-01T00:00:00Z"])
      func validateSendsExactBodyAndReturnsExpiry(expiresAt: String) async throws {
          let (client, host) = stubbedClient(respond(200, #"{"status":"granted","activation":{"id":"act_1"},"expires_at":"\#(expiresAt)"}"#))
          #expect(try await client.validate(key: "K-1", activationID: "act_1") == Date(timeIntervalSince1970: 1_798_761_600))
          let (req, body) = try #require(StubURLProtocol.requests(host: host).first)
          #expect(req.url?.path == "/v1/customer-portal/license-keys/validate")
          #expect(body == ["key": "K-1", "organization_id": "org-1", "activation_id": "act_1", "benefit_id": "ben-1"])
      }
      @Test(arguments: [#"{"status":"granted","activation":{"id":"act_1"},"expires_at":null}"#,
                        #"{"status":"granted","activation":{"id":"act_1"}}"#])
      func validateGrantedWithoutExpiryReturnsNil(body: String) async throws {
          let (client, _) = stubbedClient(respond(200, body))
          #expect(try await client.validate(key: "K-1", activationID: "act_1") == nil)
      }
      @Test(arguments: ["not json",                                              // proxy block page
                        #"{"status":"granted"}"#,                                // no activation
                        #"{"status":"granted","activation":null}"#,
                        #"{"status":"granted","activation":{"id":"act_other"}}"#,
                        #"{"status":"revoked","activation":{"id":"act_1"}}"#,
                        #"{"activation":{"id":"act_1"}}"#])
      func validate200WithoutGrantedMatchingActivationIsFailure(body: String) async {   // K5: a failure goes through grace
          let (client, _) = stubbedClient(respond(200, body))
          await #expect(throws: PolarError.http(200)) { try await client.validate(key: "K-1", activationID: "act_1") }
      }
      @Test(arguments: [(404, PolarError.notFound), (500, .http(500))])
      func validateMapsErrors(status: Int, expected: PolarError) async {
          let (client, _) = stubbedClient(respond(status))
          await #expect(throws: expected) { try await client.validate(key: "K-1", activationID: "act_1") }
      }
      @Test func validateOfflineIsNetwork() async {
          let (client, _) = stubbedClient(offline)
          await #expect(throws: PolarError.network) { try await client.validate(key: "K-1", activationID: "act_1") }
      }
      @Test func deactivate204SendsExactBody() async throws {
          let (client, host) = stubbedClient(respond(204, ""))
          try await client.deactivate(key: "K-1", activationID: "act_1")
          let (req, body) = try #require(StubURLProtocol.requests(host: host).first)
          #expect(req.url?.path == "/v1/customer-portal/license-keys/deactivate")
          #expect(body == ["key": "K-1", "organization_id": "org-1", "activation_id": "act_1"])
      }
      @Test func deactivate404IsNotFound() async {
          let (client, _) = stubbedClient(respond(404))
          await #expect(throws: PolarError.notFound) { try await client.deactivate(key: "K-1", activationID: "act_1") }
      }
  }
  ```
- [ ] **Step 2: Run it to verify it fails.** `swift test --package-path Packages/TegelKit --filter PolarClientTests`. Expected: FAIL, `error: cannot find 'PolarClient' in scope`.
- [ ] **Step 3: Implement `PolarClient` and `PolarError`** in `PolarClient.swift`. The three calls share one private `post(_ path: String, _ body: [String: String]) async throws -> (Int, Data)`:
  - `POST apiBase/v1/customer-portal/license-keys/<activate|validate|deactivate>` with a JSON body, `Content-Type: application/json`, and `organization_id` from the config. Body fields exactly per [F3a–c].
  - A URLSession throw or a non-HTTP response → `.network`. `403` → `.limitReached`. `404` → `.notFound`. Any other non-2xx → `.http(code)`.
  - `activate` decodes `{id, license_key: {benefit_id}}`. A 200 without `id` → `.http(200)`. With an `id` but no `license_key.benefit_id` → `try? await deactivate(key:activationID:)` (best effort, so API drift never eats a device slot), then `.http(200)` (fails closed; the quarterly `Polar-Version` check above catches the drift). A `benefit_id` ≠ `config.benefitID` → the same best-effort deactivate, then throw `.wrongProduct`. `// ponytail: best-effort release, no retry queue; the user frees a stuck slot in the Polar portal.`
  - `validate` adds `"benefit_id": config.benefitID` to its body; Polar answers 404 on a mismatch (plan 06 DF6), which goes through grace like any 404.
  - `validate` decodes `{status, activation: {id}?, expires_at?}` from a 200. It returns only when `status == "granted"` and `activation?.id == activationID`; anything else, including a body that isn't JSON, throws `.http(200)`. It parses `expires_at` with `ISO8601DateFormatter` using `[.withInternetDateTime, .withFractionalSeconds]`, then falls back to the plain options (Polar returns microseconds; checked on the build Mac). An unparseable or absent value → `nil`.
- [ ] **Step 4: Run it to verify it passes.** Same command. Expected: `✔ Test run with 12 tests … passed`.
- [ ] **Step 5: Watch the decode guard fail.** Temporarily make `validate` return `nil` on any 200 (the old rule) and re-run. Expected: `validate200WithoutGrantedMatchingActivationIsFailure` fails for all 6 arguments. Restore; back to 12 passed.
- [ ] **Step 6: Commit:** `Packages/TegelKit/Sources/TegelStore/PolarClient.swift Packages/TegelKit/Tests/TegelStoreTests/TestSupport.swift Packages/TegelKit/Tests/TegelStoreTests/PolarClientTests.swift`, "feat(store): add PolarClient; validate requires status granted and the stored activation".

### Task 6: KeychainStore (Wed 18 Nov)

**Files:**
- Create: `Packages/TegelKit/Sources/TegelStore/KeychainStore.swift`
- Modify: `Packages/TegelKit/Tests/TegelStoreTests/TestSupport.swift` (add `func uniqueService() -> String`, returning `"com.tegelapps.tests.\(UUID().uuidString)"`)
- Test: `Packages/TegelKit/Tests/TegelStoreTests/KeychainStoreTests.swift`

**Interfaces:**
- Consumes: `StoredLicense`.
- Produces (§3.3 verbatim): `public struct KeychainStore: Sendable { public init(service: String); public func load() -> StoredLicense?; public func save(_ l: StoredLicense) throws; public func delete() throws }`.
- Errors are `NSError(domain: NSOSStatusErrorDomain, code: Int(status))`, so no new type.
- New, internal: `var failSaves = false`. When set, `save` throws `NSError(domain: NSOSStatusErrorDomain, code: Int(errSecInteractionNotAllowed))` without touching the Keychain. `// ponytail: test seam; nothing else makes SecItemAdd fail on demand` (Task 7's rollback test uses it).

- [ ] **Step 1: Write the failing test.**
  ```swift
  import Foundation
  import Testing
  @testable import TegelStore

  @Suite struct KeychainStoreTests {
      @Test func saveLoadOverwriteDelete() throws {
          let store = KeychainStore(service: uniqueService()); defer { try? store.delete() }
          #expect(store.load() == nil)
          try store.save(lic)
          #expect(store.load() == lic)
          var newer = lic; newer.lastValidatedAt = t0 + 60
          try store.save(newer)
          #expect(store.load() == newer)
          try store.delete()
          #expect(store.load() == nil)
          try store.delete()                       // deleting nothing is not an error
      }
      @Test func servicesAreIsolated() throws {
          let a = KeychainStore(service: uniqueService()), b = KeychainStore(service: uniqueService())
          defer { try? a.delete(); try? b.delete() }
          try a.save(lic)
          #expect(b.load() == nil)
      }
  }
  ```
- [ ] **Step 2: Run it to verify it fails.** `swift test --package-path Packages/TegelKit --filter KeychainStoreTests`. Expected: FAIL, `error: cannot find 'KeychainStore' in scope`.
- [ ] **Step 3: Implement `KeychainStore`.**
  - Item: `kSecClassGenericPassword`, `kSecAttrService` = service, `kSecAttrAccount` = `"licence"`, value = the JSON-encoded `StoredLicense`.
  - Use the file-based login keychain: the data-protection keychain needs a provisioning profile.
  - `save` = `SecItemAdd`; on `errSecDuplicateItem`, `SecItemUpdate` with the new value. Never delete first: a failed write must leave the stored licence in place (`refresh` saves with `try?`).
  - `load` = `SecItemCopyMatching` + decode. Any failure → `nil`.
  - `delete` treats `errSecItemNotFound` as success.
  - `failSaves` as in Interfaces.
- [ ] **Step 4: Run it to verify it passes, and check cleanup.**
  - Same command. Expected: `✔ Test run with 2 tests … passed`.
  - Then `security dump-keychain 2>/dev/null | grep -c 'com.tegelapps.tests'` → `0` (no leftovers; this prints attributes only, no secrets).
- [ ] **Step 5: Commit:** `Packages/TegelKit/Sources/TegelStore/KeychainStore.swift Packages/TegelKit/Tests/TegelStoreTests/TestSupport.swift Packages/TegelKit/Tests/TegelStoreTests/KeychainStoreTests.swift`, "feat(store): add KeychainStore for the stored licence".

### Task 7: LicenseManager (Wed 18 Nov)

**Files:**
- Create: `Packages/TegelKit/Sources/TegelStore/LicenseManager.swift`
- Test: `Packages/TegelKit/Tests/TegelStoreTests/LicenseManagerTests.swift`

**Interfaces:**
- Consumes: `PolarClient`, `PolarError`, `KeychainStore`, `LicensePolicy`, `StoredLicense`, `LicenseState`.
- Produces (§3.3 verbatim):
  ```swift
  @MainActor @Observable public final class LicenseManager { public private(set) var state: LicenseState; public var isPro: Bool
      public init(client: PolarClient, keychain: KeychainStore = .init(service: Bundle.main.bundleIdentifier ?? "tegel"))
      public func activate(key: String) async throws; public func deactivate() async throws; public func refresh(now: Date = .now) async }
  ```
  - `isPro` is computed: `true` only for `.pro`.
  - K5: one `activate`/`deactivate` at a time. A call made while another is in flight throws `CancellationError()` and sends nothing (the UI disables its buttons while busy, so only code can hit this).
- New, internal:
  - `static func normalisedKey(_ raw: String) -> String`. It removes **all** whitespace and newlines, not just the ends: Polar keys contain none, so this also fixes a key wrapped across lines in an email.
  - `static var modelLabel: String`, the activation label: the hardware model from `sysctlbyname("hw.model")`, such as `iMac19,1` (compiled and run with `swiftc -swift-version 6` on the build Mac, 27 Oct). Never the computer name: "<First name>'s MacBook Pro" would send personal data to Polar, which `/privacy/` doesn't disclose. Not `Host.current()` either, which does a blocking DNS lookup that can stall offline (CR-P2-26).
    ```swift
    static var modelLabel: String {
        var n = 0; sysctlbyname("hw.model", nil, &n, nil, 0)
        var b = [UInt8](repeating: 0, count: max(n, 1)); sysctlbyname("hw.model", &b, &n, nil, 0)
        let s = String(decoding: b.prefix { $0 != 0 }, as: UTF8.self); return s.isEmpty ? "Mac" : s }
    ```
  - `init(client: PolarClient, keychain: KeychainStore, now: Date)`, the designated init: it applies the policy at `now`. The §3.3 public init is a `convenience init` that passes `.now`, so the contract is unchanged. Tests pass a clock relative to `t0` (15 Jan 2027), so no test depends on today's date.
- Test helpers, in this test file:
  - `let granted = respond(200, #"{"status":"granted","activation":{"id":"act_1"}}"#)`, a validate 200 for `lic`.
  - `@MainActor func makeManager(stored: StoredLicense?, _ handler: @escaping StubHandler = respond(200, #"{"id":"act_1","license_key":{"benefit_id":"ben-1"}}"#), failSaves: Bool = false, now: Date = t0) throws -> (LicenseManager, KeychainStore, String)`. It uses a `uniqueService()` store with `failSaves` set, pre-saves `stored` (before setting the flag), builds the client with `stubbedClient`, and the manager with `LicenseManager(client:keychain:now:)`.

- [ ] **Step 1: Write the failing test.** Each test also deletes its Keychain store at the end (`defer { try? store.delete() }`, omitted below).
  ```swift
  import Foundation
  import Testing
  @testable import TegelStore

  @MainActor @Suite struct LicenseManagerTests {
      @Test func initAppliesPolicyToStoredLicence() throws {               // .pro and .lapsed can't both hold at one real date
          let (m, _, _) = try makeManager(stored: lic, now: t0 + 86_400)
          #expect(m.state == .pro(lic)); #expect(m.isPro)
          let (m2, _, _) = try makeManager(stored: lic, now: t0 + LicensePolicy.grace + 1)
          #expect(m2.state == .lapsed(lic)); #expect(!m2.isPro)
          let (m3, _, _) = try makeManager(stored: nil)
          #expect(m3.state == .free); #expect(!m3.isPro)
      }
      @Test func normalisedKeyStripsAllWhitespace() {
          #expect(LicenseManager.normalisedKey("  ABCD-1234 \n") == "ABCD-1234")
          #expect(LicenseManager.normalisedKey("ABCD-\r\n1234\t") == "ABCD-1234")
      }
      @Test func activateSendsNormalisedKeyAndModelLabelThenStores() async throws {
          let (m, store, host) = try makeManager(stored: nil, respond(200, #"{"id":"act_9","license_key":{"benefit_id":"ben-1"}}"#))
          try await m.activate(key: " K-1\n")
          let (_, body) = try #require(StubURLProtocol.requests(host: host).first)
          #expect(body["key"] == "K-1")
          #expect(body["label"]?.wholeMatch(of: #/[A-Za-z]+[0-9]+,[0-9]+/#) != nil)   // a model id such as "iMac19,1", never a computer name
          #expect(store.load()?.key == "K-1"); #expect(store.load()?.activationID == "act_9"); #expect(m.isPro)
      }
      @Test func concurrentActivateSendsOneRequest() async throws {           // K5: one mutation in flight
          let held: StubHandler = { _, _ in                                    // holds the first request so the second call lands mid-flight
              Thread.sleep(forTimeInterval: 0.2); return (200, Data(#"{"id":"act_1","license_key":{"benefit_id":"ben-1"}}"#.utf8)) }
          let (m, store, host) = try makeManager(stored: nil, held)
          async let a: Void = m.activate(key: "K-1")
          async let b: Void = m.activate(key: "K-1")
          var cancelled = 0
          do { try await a } catch is CancellationError { cancelled += 1 }
          do { try await b } catch is CancellationError { cancelled += 1 }
          #expect(cancelled == 1)
          #expect(StubURLProtocol.requests(host: host).count == 1)
          #expect(store.load()?.activationID == "act_1"); #expect(m.isPro)
      }
      @Test func activateKeychainSaveFailureRollsBack() async throws {         // K5: no orphaned slot when the save fails
          let (m, store, host) = try makeManager(stored: nil, respond(200, #"{"id":"act_9","license_key":{"benefit_id":"ben-1"}}"#), failSaves: true)
          await #expect(throws: (any Error).self) { try await m.activate(key: "K-1") }
          let reqs = StubURLProtocol.requests(host: host)
          #expect(reqs.map { $0.0.url?.lastPathComponent } == ["activate", "deactivate"])
          #expect(reqs.last?.1["activation_id"] == "act_9")
          #expect(m.state == .free); #expect(store.load() == nil)
      }
      @Test func activateLimitReachedThrowsAndStaysFree() async throws {
          let (m, store, _) = try makeManager(stored: nil, respond(403))
          await #expect(throws: PolarError.limitReached) { try await m.activate(key: "K-1") }
          #expect(m.state == .free); #expect(store.load() == nil)
      }
      @Test func activateWrongProductThrowsAndStaysFree() async throws {   // D1: another app's key
          let (m, store, _) = try makeManager(stored: nil, respond(200, #"{"id":"act_9","license_key":{"benefit_id":"ben-other"}}"#))
          await #expect(throws: PolarError.wrongProduct) { try await m.activate(key: "K-1") }
          #expect(m.state == .free); #expect(store.load() == nil)
      }
      @Test func refresh200StampsLastValidatedAt() async throws {
          let (m, store, _) = try makeManager(stored: lic, granted)
          await m.refresh(now: t0 + 10 * 86_400)
          #expect(store.load()?.lastValidatedAt == t0 + 10 * 86_400); #expect(m.isPro)
      }
      @Test func refresh404WithinGraceNeverLocks() async throws {          // [F3d]: 404 goes through grace exactly like offline
          let (m, store, _) = try makeManager(stored: lic, respond(404))
          await m.refresh(now: t0 + 29 * 86_400)
          #expect(m.state == .pro(lic)); #expect(store.load() == lic)       // key kept, stamp not moved
      }
      @Test(arguments: [500, 503]) func refresh5xxWithinGraceStaysPro(status: Int) async throws {
          let (m, store, _) = try makeManager(stored: lic, respond(status))
          await m.refresh(now: t0 + 29 * 86_400)
          #expect(m.state == .pro(lic)); #expect(store.load() == lic)
      }
      @Test func refreshOfflineWithinGraceStaysPro() async throws {
          let (m, store, _) = try makeManager(stored: lic, offline)
          await m.refresh(now: t0 + 29 * 86_400)
          #expect(m.state == .pro(lic)); #expect(store.load() == lic)
      }
      @Test func refresh404AfterGraceIsLapsedAndKeepsKey() async throws {
          let (m, store, _) = try makeManager(stored: lic, respond(404))
          await m.refresh(now: t0 + LicensePolicy.grace + 1)
          #expect(m.state == .lapsed(lic)); #expect(!m.isPro); #expect(store.load() == lic)
      }
      @Test func refreshAfterLapseWith200RestoresPro() async throws {
          let (m, _, _) = try makeManager(stored: lic, granted)
          await m.refresh(now: t0 + 40 * 86_400)
          #expect(m.state == .pro(StoredLicense(key: "K-1", activationID: "act_1", lastValidatedAt: t0 + 40 * 86_400)))
      }
      @Test func refreshWithClockBackwardsKeepsLastValidatedAt() async throws {   // within the 1-day skew
          let (m, store, _) = try makeManager(stored: lic, offline)
          await m.refresh(now: t0 - 3_600)
          #expect(m.state == .pro(lic)); #expect(store.load()?.lastValidatedAt == t0)
      }
      @Test func refreshWithoutLicenceMakesNoRequest() async throws {
          let (m, _, host) = try makeManager(stored: nil)
          await m.refresh(now: t0)
          #expect(m.state == .free); #expect(StubURLProtocol.requests(host: host).isEmpty)
      }
      @Test(arguments: [204, 404]) func deactivateDeletesLicence(status: Int) async throws {   // 404 = already removed in the portal
          let (m, store, host) = try makeManager(stored: lic, respond(status))
          try await m.deactivate()
          #expect(m.state == .free); #expect(store.load() == nil)
          #expect(StubURLProtocol.requests(host: host).first?.1["activation_id"] == "act_1")
      }
      @Test func deactivateOfflineKeepsLicence() async throws {
          let (m, store, _) = try makeManager(stored: lic, offline)
          await #expect(throws: PolarError.network) { try await m.deactivate() }
          #expect(store.load() == lic); #expect(m.isPro)
      }
      @Test func lapsedLicenceCanBeRemoved() async throws {               // activation removed in the portal: validate and deactivate both 404
          let (m, store, _) = try makeManager(stored: lic, respond(404), now: t0 + LicensePolicy.grace + 1)
          #expect(m.state == .lapsed(lic))
          try await m.deactivate()                                         // the Licence tab's "Remove Licence…" (Task 9)
          #expect(m.state == .free); #expect(store.load() == nil)
      }
      @Test func refreshDoesNotResurrectLicenceDeletedMidFlight() async throws {
          let service = uniqueService(), store = KeychainStore(service: service)
          try store.save(lic)
          let (client, _) = stubbedClient { _, _ in try? KeychainStore(service: service).delete(); return (200, Data(#"{"status":"granted","activation":{"id":"act_1"}}"#.utf8)) }
          let m = LicenseManager(client: client, keychain: store, now: t0)
          await m.refresh(now: t0 + 86_400)
          #expect(store.load() == nil); #expect(m.state == .free)
      }
  }
  ```
- [ ] **Step 2: Run it to verify it fails.** `swift test --package-path Packages/TegelKit --filter LicenseManagerTests`. Expected: FAIL, `error: cannot find 'LicenseManager' in scope`.
- [ ] **Step 3: Implement `LicenseManager`.**
  - **`init(client:keychain:now:)`:** `state = LicensePolicy.state(stored: keychain.load(), now: now)`. This is synchronous, so Pro is on at launch before any network call. The public init is `convenience init(client:keychain:)`, calling it with `now: .now`.
  - **Serialising (K5):** `private var mutating = false`. `activate` and `deactivate` start with `guard !mutating else { throw CancellationError() }; mutating = true; defer { mutating = false }`. Both run on the main actor, so the flag is set before the first `await`.
  - **`activate`:**
    1. Normalise the key.
    2. Call `client.activate(key:label:)` with `label: Self.modelLabel`.
    3. `keychain.save(StoredLicense(key:activationID:lastValidatedAt: .now))`, then `state = .pro`.
    4. If the save throws: `try? await client.deactivate(key:activationID:)` (best-effort rollback, so a failed save never eats a slot), then rethrow the save error. `// ponytail: no retry queue; a slot left by a failed rollback is freed in the Polar portal.`
    - Polar errors propagate unchanged, and nothing is stored on error. That includes `.wrongProduct`, whose activation `PolarClient` has already released.
  - **`refresh(now:)`:**
    1. With no stored licence: `state = .free`, no request.
    2. Otherwise call `validate`.
    3. After the `await`, check that `keychain.load()?.activationID` still equals the activation it started with. If not, a deactivate/activate ran mid-flight: set `state` from the current Keychain and return.
    4. On success (a decoded `granted` 200 for this activation): stamp `lastValidatedAt = now`, `try? save`, `state = .pro`. This is the only path that moves the stamp, and it restores Pro from `.lapsed`.
    5. On **any** error (404, 5xx, network, a 200 that fails the decode): `state = LicensePolicy.state(stored:now:)`, and **neither the Keychain nor the stamp is touched**.
    - `expires_at` is ignored: Polar 404s expired keys [F3b].
    - `refresh` takes no part in the `mutating` flag; step 3 already handles a mutation that lands mid-flight.
  - **`deactivate`:** call `client.deactivate`. Then `.notFound` and success both `keychain.delete()` and set `state = .free`. Every other error is rethrown, and the licence is kept.
- [ ] **Step 4: Run it to verify it passes.**
  - `swift test --package-path Packages/TegelKit --filter LicenseManagerTests`. Expected: `✔ Test run with 19 tests … passed`.
  - Then `swift test --package-path Packages/TegelKit --filter TegelStoreTests`. Expected: `41 tests … passed` (8 + 12 + 2 + 19).
- [ ] **Step 5: Watch the K5 guards, the injected clock and the lapsed removal fail.** One at a time, re-running `--filter LicenseManagerTests` after each, then restoring:
  - delete the `guard !mutating` line → `concurrentActivateSendsOneRequest` fails (2 requests, 0 cancelled);
  - delete the rollback `deactivate` → `activateKeychainSaveFailureRollsBack` fails (requests `["activate"]`);
  - make the designated `init` use `.now` instead of `now` → `initAppliesPolicyToStoredLicence` fails whatever today's date is (its `.pro` and `.lapsed` expectations need different real dates);
  - add `guard isPro else { return }` at the top of `deactivate` → `lapsedLicenceCanBeRemoved` fails (state stays `.lapsed`, the key stays stored);
  - make `modelLabel` return `"Jan's iMac"` (a computer name) → `activateSendsNormalisedKeyAndModelLabelThenStores` fails.
  - Restored: 19 passed.
- [ ] **Step 6: Commit:** `Packages/TegelKit/Sources/TegelStore/LicenseManager.swift Packages/TegelKit/Tests/TegelStoreTests/LicenseManagerTests.swift`, "feat(store): add LicenseManager; grace on every failure, serialised mutations, save rollback".

### Task 8: Polar values from xcconfig into Info.plist; link TegelStore (Thu 19 Nov)

**Files:**
- Create: `Config/PolarSandbox.xcconfig` (sandbox values; not secret per D16)
- Modify: `Config/Debug.xcconfig` (add `#include "PolarSandbox.xcconfig"`)
- Modify: `Config/Release.xcconfig` (production placeholders)
- Modify: `project.yml`:
  - `markdown` app target: `dependencies: - package: TegelKit, product: TegelStore`;
  - `info.properties`: the five `TG*` keys.

**Interfaces:**
- Consumes: `.env` `POLAR_SANDBOX_ORGANIZATION_ID`, `POLAR_SANDBOX_CHECKOUT_URL_MARKDOWN`, `POLAR_SANDBOX_PORTAL_URL`, `POLAR_SANDBOX_BENEFIT_ID_MARKDOWN` (Task 1).
- Produces:
  - build settings `TG_POLAR_API_BASE`, `TG_POLAR_ORGANIZATION_ID`, `TG_POLAR_CHECKOUT_URL_MARKDOWN`, `TG_POLAR_PORTAL_URL`, `TG_POLAR_BENEFIT_ID_MARKDOWN` (per-app names carry the `_MARKDOWN` suffix; plan 06 adds `_DATA`);
  - Info.plist `TGPolarAPIBase = $(TG_POLAR_API_BASE)`, `TGPolarOrganizationID = $(TG_POLAR_ORGANIZATION_ID)`, `TGPolarCheckoutURL = $(TG_POLAR_CHECKOUT_URL_MARKDOWN)`, `TGPolarPortalURL = $(TG_POLAR_PORTAL_URL)`, `TGPolarBenefitID = $(TG_POLAR_BENEFIT_ID_MARKDOWN)`;
  - the placeholder token `REPLACE_IN_PLAN_05` in four Release settings (`TG_POLAR_ORGANIZATION_ID`, `TG_POLAR_CHECKOUT_URL_MARKDOWN`, `TG_POLAR_PORTAL_URL`, `TG_POLAR_BENEFIT_ID_MARKDOWN`), which Task 12 and plan 05 key on.
- `release.sh --sandbox` reuses `Config/PolarSandbox.xcconfig` via `xcodebuild -xcconfig`.

- [ ] **Step 1: Write the failing check.** One self-contained block (`b` and `p` live only in this shell):
  ```bash
  . scripts/lib/env.sh
  xcodegen generate >/dev/null
  b() { xcodebuild build -scheme markdown -configuration "$1" -destination 'platform=macOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO -quiet "${@:2}"; }
  p() { /usr/libexec/PlistBuddy -c "Print :$2" "build/Build/Products/$1/Tegel Markdown.app/Contents/Info.plist"; }
  b Debug && p Debug TGPolarAPIBase && [ "$(p Debug TGPolarBenefitID)" = "$(envget POLAR_SANDBOX_BENEFIT_ID_MARKDOWN)" ] && echo benefit-ok
  b Release && p Release TGPolarAPIBase && p Release TGPolarOrganizationID && p Release TGPolarBenefitID
  b Release -xcconfig Config/PolarSandbox.xcconfig && p Release TGPolarAPIBase
  ```
- [ ] **Step 2: Run it to verify it fails.** Expected: FAIL, `Print: Entry, ":TGPolarAPIBase", Does Not Exist`.
- [ ] **Step 3: Implement.**
  - **`//` starts an xcconfig comment**, so write URLs as `https:/$()/host…`. Generate the sandbox file from `.env` without echoing values:
    ```bash
    . scripts/lib/env.sh
    u() { envget "$1" | sed 's|://|:/$()/|'; }
    printf 'TG_POLAR_API_BASE = https:/$()/sandbox-api.polar.sh\nTG_POLAR_ORGANIZATION_ID = %s\nTG_POLAR_CHECKOUT_URL_MARKDOWN = %s\nTG_POLAR_PORTAL_URL = %s\nTG_POLAR_BENEFIT_ID_MARKDOWN = %s\n' \
      "$(envget POLAR_SANDBOX_ORGANIZATION_ID)" "$(u POLAR_SANDBOX_CHECKOUT_URL_MARKDOWN)" "$(u POLAR_SANDBOX_PORTAL_URL)" "$(envget POLAR_SANDBOX_BENEFIT_ID_MARKDOWN)" > Config/PolarSandbox.xcconfig
    ```
  - In `Release.xcconfig`, set:
    - `TG_POLAR_API_BASE = https:/$()/api.polar.sh`;
    - `TG_POLAR_ORGANIZATION_ID = REPLACE_IN_PLAN_05`;
    - `TG_POLAR_CHECKOUT_URL_MARKDOWN = https:/$()/REPLACE_IN_PLAN_05.invalid`;
    - `TG_POLAR_PORTAL_URL = https:/$()/polar.sh/REPLACE_IN_PLAN_05/portal`;
    - `TG_POLAR_BENEFIT_ID_MARKDOWN = REPLACE_IN_PLAN_05`.
  - Add the dependency and the five `info.properties` to `project.yml`.
- [ ] **Step 4: Run it to verify it passes.** Same block. Expected, in order:
  1. `https://sandbox-api.polar.sh`
  2. `benefit-ok`
  3. `https://api.polar.sh`
  4. `REPLACE_IN_PLAN_05`
  5. `REPLACE_IN_PLAN_05`
  6. `https://sandbox-api.polar.sh`
  - Then `make check` still passes with the plan 01/02 baseline counts.
- [ ] **Step 5: Commit:** `Config/PolarSandbox.xcconfig Config/Debug.xcconfig Config/Release.xcconfig project.yml`, "build: feed Polar sandbox/production values into Info.plist via xcconfig (D16)".

### Task 9: App wiring: `isPro` from LicenseManager, Licence tab, refresh loop (Thu 19 Nov)

The licence logic is unit-tested in Tasks 4–7. Plan 02's `MarkdownAppTests` target runs through `make test-app`; its `LocalizationTests` check this task's new strings in NL/FR/AR. The rest is a Debug-build smoke test against the sandbox on the build Mac.

**Files:**
- Modify: the `@main` App struct from plan 01 (`grep -l '@main' Apps/Markdown/App/*.swift`, expected `Apps/Markdown/App/MarkdownApp.swift`)
- Create: `Apps/Markdown/App/LicenceSettingsView.swift`
- Modify: plan 02's Settings `TabView` (`grep -l 'TabView' Apps/Markdown/App/*.swift`)
- Modify: `Apps/Markdown/App/Localizable.xcstrings` (plan 02's catalogue; NL/FR/AR for every new string, D6)

**Interfaces:**
- Consumes:
  - `LicenseManager`, `PolarClient(config:)`, `PolarConfig.fromInfoPlist()`, `PolarError` (Tasks 4–7);
  - `EnvironmentValues.isPro` (plan 02, `ProGate.swift`).
- Produces:
  - `struct LicenceSettingsView: View { let proSummary: LocalizedStringKey }`, reading `@Environment(LicenseManager.self)`. `proSummary` is the text of its `.free` row: App 1 passes its sentence below, and plan 06's App 2 passes its own;
  - the App injects `.environment(license)` and `.environment(\.isPro, license.isPro)` (OR'd with plan 02's `#if DEBUG` override, which stays Debug-only) on every scene.

- [ ] **Step 1: Write the failing check (GUI).** Run `make build` (plan 01: Debug, ad-hoc signed) and open `build/Build/Products/Debug/Tegel Markdown.app`. Expected FAIL: Settings has no **Licence** tab, and Pro features follow only the Debug override.
- [ ] **Step 2: Implement.**
  - **App init:**
    - `let m = LicenseManager(client: PolarClient(config: .fromInfoPlist()))`, `_license = State(initialValue: m)`;
    - `Task { while !Task.isCancelled { await m.refresh(); try? await Task.sleep(for: .seconds(86_400)) } }`. This refreshes at launch, then every 24 h while running.
  - **LicenceSettingsView**, a `Form` with exactly this EN copy:

  | State | Content |
  |---|---|
  | `.free` | Text `proSummary`, which App 1 passes as "Pro adds folder mode with search and live reload, paginated PDF export and three themes. One-time purchase for up to 2 Macs, with a 14-day refund." · Button **"Buy Pro…"** → `openURL(config.checkoutURL)` · TextField "Licence key" + Button **"Activate"** (disabled while empty or busy) |
  | `.pro` | Text "Pro is active on this Mac." · Button **"Deactivate this Mac"** · Button **"Manage activations…"** → `openURL(config.portalURL)` |
  | `.lapsed` | Text "Tegel couldn't confirm your licence for more than 30 days. Connect to the internet, then click Check Again." · Button **"Check Again"** → `refresh()` · **"Manage activations…"** · Button **"Remove Licence…"** → a confirmation dialog "Remove the licence from this Mac?" with **"Remove Licence"** (destructive) and "Cancel" → `deactivate()`. A 404 (activation already removed in the portal) counts as done, so the `.free` row comes back and the key can be entered again; other errors show their copy below |
  | error `.limitReached` | "This key is already active on 2 Macs, or it is no longer valid. Free up a Mac in Manage activations, then try again." |
  | error `.notFound` | "That licence key wasn't found. Copy it again from your receipt or the customer portal." |
  | error `.network` | "Couldn't reach the licence server. Check your connection and try again." |
  | error `.http(n)` | "The licence server returned error \(n). Try again later." |
  | error `.wrongProduct` | "This key is for another Tegel app. Each app has its own key on your Polar purchases page." |
  | any other error (a Keychain save failure, whose activation `LicenseManager` has already released) | "Tegel couldn't save the licence on this Mac. Try again." |

  - A `CancellationError` shows nothing: it only means another licence action was already running.
  - The activation label is the hardware model (`hw.model`, such as `iMac19,1`), never the computer name; `LicenseManager` sends it (Task 7).
  - Add the tab `LicenceSettingsView(proSummary: "Pro adds folder mode with search and live reload, paginated PDF export and three themes. One-time purchase for up to 2 Macs, with a 14-day refund.")` with `.tabItem { Label("Licence", systemImage: "key") }` to the Settings `TabView`.
- [ ] **Step 3: Run the smoke test (GUI), on the build Mac with a Debug build against the sandbox.**
  1. `. scripts/lib/env.sh; envget POLAR_SANDBOX_TEST_LICENSE_KEY | sed 's/^/  /;s/$/\n/' | pbcopy`. This puts the key on the clipboard with leading spaces and a trailing newline, without printing it.
  2. Paste it, then click Activate. Expected: "Pro is active on this Mac", and folder mode is enabled.
  3. Sandbox dashboard → the order's licence key → activations. Expected: one activation whose label equals `sysctl -n hw.model` (`iMac19,1` here), not `scutil --get ComputerName`. This also confirms `sysctlbyname("hw.model")` works inside the sandbox.
  4. Disconnect the network, quit, relaunch. Expected: still Pro, no error. Reconnect.
  5. Deactivate this Mac. Expected: the free copy shows, and the dashboard shows 0 activations.
  6. Type the key `TEGEL-0000` and Activate. Expected: the `.notFound` copy.
  7. `make test-app ONLY=LocalizationTests`. Expected: `Executed 3 tests, with 0 failures` (every new string has NL/FR/AR). Then relaunch with `-AppleLanguages '(nl)'`, then `(fr)`, then `(ar)`. Expected: the Licence tab shows no English, and the AR layout is right-to-left.
- [ ] **Step 4: Run `make check`.** Expected: baseline + 41 TegelStore tests, all passing.
- [ ] **Step 5: Commit:** `Apps/Markdown/App/LicenceSettingsView.swift Apps/Markdown/App/MarkdownApp.swift Apps/Markdown/App/Localizable.xcstrings <settings-tabview-file>`, "feat(app): Licence settings tab; LicenseManager feeds isPro; 24 h refresh".

### Task 10: Sparkle 2.10.1 and EdDSA keys (Fri 20 Nov)

**Files:**
- Modify: `project.yml`:
  - `packages: Sparkle: {url: https://github.com/sparkle-project/Sparkle, exactVersion: 2.10.1}`, and the dependency `- package: Sparkle` on the `markdown` app target only;
  - `info.properties`: `SUFeedURL`, `SUPublicEDKey`, `SUEnableInstallerLauncherService: true`, `SUEnableAutomaticChecks: true`, `SURequireSignedFeed: true`, `SUVerifyUpdateBeforeExtraction: true` (K7; Sparkle 2.9+ and 2.7.3+ respectively, and the first needs the second, per sparkle-project.org/documentation/customization/ and `SPUUpdater.m` at 2.10.1);
  - `entitlements.properties`: `com.apple.security.temporary-exception.mach-lookup.global-name: ["$(PRODUCT_BUNDLE_IDENTIFIER)-spks", "$(PRODUCT_BUNDLE_IDENTIFIER)-spki"]` [F4]. It's a no-op if plan 01 already added it under D5.
- Modify: `Apps/Markdown/App/MarkdownApp.swift`
- Create: `Apps/Markdown/App/UpdatesSettingsView.swift`
- Modify: plan 02's Settings `TabView` (the file Task 9 changed)
- Modify: `Apps/Markdown/App/Localizable.xcstrings`

**Interfaces:**
- Consumes: plan 02's Settings `TabView`, with Task 9's Licence tab.
- Produces:
  - `let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)` in the App struct (sparkle-project.org/documentation/programmatic-setup/);
  - `struct UpdatesSettingsView: View` with `init(updater: SPUUpdater)`, the fourth Settings tab (General | Appearance | Licence | Updates). `LicenceSettingsView` stays as Task 9 left it and takes no updater, so App 2 can compile it by path (plan 06);
  - `.env` `SPARKLE_PUBLIC_ED_KEY` (no key path: the private-key backup lives only in the offline store, K3);
  - a Keychain item with account **`tegelapps`**, and its backup in `TegelKeys` (Task 3 step 5);
  - the Sparkle tools at `build/SourcePackages/artifacts/sparkle/Sparkle/bin` (`release.sh` uses its own copy under `build/release-dd/`).

- [ ] **Step 1: Write the failing check.**
  ```bash
  make build
  A="build/Build/Products/Debug/Tegel Markdown.app"
  for k in SUFeedURL SUEnableInstallerLauncherService SUEnableAutomaticChecks SURequireSignedFeed SUVerifyUpdateBeforeExtraction; do
    /usr/libexec/PlistBuddy -c "Print :$k" "$A/Contents/Info.plist"; done
  codesign -d --entitlements - --xml "$A" 2>/dev/null | grep -oE 'com\.tegelapps\.markdown-sp[ik]s|network\.client' | sort
  ```
- [ ] **Step 2: Run it to verify it fails.** Expected: FAIL, `Print: Entry, ":SUFeedURL", Does Not Exist` (and the same for the other four keys). The `-spks`/`-spki` lines already show if plan 01 added the pair under D5.
- [ ] **Step 3: Implement and generate the keys.**
  - Add the package and the `SUFeedURL`, flag and entitlement entries; then `xcodegen generate && xcodebuild -resolvePackageDependencies -derivedDataPath build | grep Sparkle`. Expected: `Sparkle: https://github.com/sparkle-project/Sparkle @ 2.10.1`.
  - Generate the keys. Flags were verified in Sparkle 2.10.1's `generate_keys/main.swift`: `--account`, `-p` prints the public key, `-x` exports the private key.
    ```bash
    . scripts/lib/env.sh
    SPARKLE_BIN=build/SourcePackages/artifacts/sparkle/Sparkle/bin
    "$SPARKLE_BIN/generate_keys" --account tegelapps >/dev/null
    envset SPARKLE_PUBLIC_ED_KEY "$("$SPARKLE_BIN/generate_keys" --account tegelapps -p)"
    need SPARKLE_PUBLIC_ED_KEY && echo saved
    ```
    Expected: `saved`.
  - **Back up the private key straight into the offline store (K3)**; it never lands in `$HOME`. Losing it means no more updates for every installed copy. The **user** connects the media and runs `hdiutil attach <path>/TegelKeys.dmg` (passphrase prompt). If Task 3 step 5 hasn't run yet, the store doesn't exist yet: the user first creates it with Task 3 step 5 item 2's command, and Task 3 later adds its two files to it. Then:
    ```bash
    build/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys --account tegelapps -x /Volumes/TegelKeys/sparkle-ed25519-tegelapps.key
    ls /Volumes/TegelKeys; hdiutil detach /Volumes/TegelKeys
    ```
    Expected: `sparkle-ed25519-tegelapps.key`, beside Task 3's `AuthKey_<KEYID>.p8` and `devid-application.key` once those exist. The user puts the media away.
  - Put the public key, which is public by design, into `project.yml` as `SUPublicEDKey`.
  - **App:** `CommandGroup(after: .appInfo) { Button("Check for Updates…") { updaterController.updater.checkForUpdates() } }`.
  - **Settings:** add the tab `UpdatesSettingsView(updater: updaterController.updater)` with `.tabItem { Label("Updates", systemImage: "arrow.triangle.2.circlepath") }` after Licence. Its `Form` holds (plan 09 Settings spec):
    - `Toggle("Check for updates automatically")` bound to `updater.automaticallyChecksForUpdates`. Use local `@State`, read on appear, and write in `onChange`. The runtime API is used only for user changes, per sparkle-project.org/documentation/customization/;
    - a **"Check Now"** button → `updater.checkForUpdates()`;
    - "Last checked: <relative date>" from `updater.lastUpdateCheckDate`, hidden while it is `nil`.
- [ ] **Step 4: Run it to verify it passes.**
  - Step 1's block. Expected:
    - `https://downloads.tegelapps.com/markdown/appcast.xml`, `true`, `true`, `true`, `true`;
    - after plan 07 G7 templates `SUEnableAutomaticChecks` from a build setting, its line reads the string `YES` (`NO` in a final build) instead of `true`; `YES` also passes;
    - then `com.tegelapps.markdown-spki`, `com.tegelapps.markdown-spks`, `network.client`.
  - `test -d "build/Build/Products/Debug/Tegel Markdown.app/Contents/Frameworks/Sparkle.framework" && echo embedded` → `embedded`.
  - `find ~/.tegel-signing ~/.tegel-secrets -type f \( -name '*.key' -o -name '*.p8' -o -name '*.p12' \) 2>/dev/null | wc -l` → `0`.
  - *(GUI)* The app menu has "Check for Updates…", and Settings shows the tabs General | Appearance | Licence | Updates, with the Licence tab unchanged. Until plan 05 publishes 1.0.0, Check Now reports an update error: the public appcast doesn't exist yet (betas use a local feed, Task 13).
  - `make check` passes, including `LocalizationTests` for the new strings.
  - The signed-feed guard is watched failing in Task 13 step 7 (a tampered feed offers no update).
- [ ] **Step 5: Commit:** `project.yml Apps/Markdown/App/MarkdownApp.swift Apps/Markdown/App/UpdatesSettingsView.swift Apps/Markdown/App/Localizable.xcstrings <settings-tabview-file>`, "feat(app): Sparkle 2.10.1 updater with signed feed, menu item and Updates settings tab".

### Task 11: Developer ID signing settings (Fri 20 Nov)

**Files:**
- Modify: `Config/Release.xcconfig`

**Interfaces:**
- Consumes: the project-level `configFiles` from plan 01, so the app **and** the Quick Look extension inherit these settings.
- Produces these Release settings:
  - `CODE_SIGN_STYLE = Manual`;
  - `CODE_SIGN_IDENTITY = Developer ID Application`: a selector. `release.sh` overrides it with the exact `APPLE_DEVELOPER_ID_IDENTITY` and `DEVELOPMENT_TEAM=$APPLE_TEAM_ID`; xcconfig can't read `.env`;
  - `ENABLE_HARDENED_RUNTIME = YES`;
  - `OTHER_CODE_SIGN_FLAGS = $(inherited) --timestamp`.

- [ ] **Step 1: Write the failing check.** It reads settings only, so it needs no certificate. It names the two signed targets, because `-alltargets` would also count `MarkdownAppTests` (CR-P2-20).
  ```bash
  xcodegen generate >/dev/null
  for t in markdown markdown.quicklook; do xcodebuild -project Tegel.xcodeproj -target "$t" -configuration Release -showBuildSettings 2>/dev/null; done \
    | grep -cE '^\s*(CODE_SIGN_STYLE = Manual|CODE_SIGN_IDENTITY = Developer ID Application|ENABLE_HARDENED_RUNTIME = YES|OTHER_CODE_SIGN_FLAGS = .*--timestamp)$'
  ```
- [ ] **Step 2: Run it to verify it fails.** Expected: FAIL, a count below `8`: `6` if plan 01's Release.xcconfig still sets three of the four, since `OTHER_CODE_SIGN_FLAGS` is missing on both targets.
- [ ] **Step 3: Implement** the four lines in `Config/Release.xcconfig`.
- [ ] **Step 4: Run it to verify it passes.** Expected: `8` (4 settings × 2 targets). Then `make check` passes: its builds use `CODE_SIGNING_ALLOWED=NO`, so they don't need the certificate.
- [ ] **Step 5: Signed archive check (needs Task 3, done 27 Oct).** The first `codesign` with the Developer ID key raises the Keychain prompt from Task 3 step 1: the **user** clicks **Always Allow** once (CR-P2-27). Note the date for `docs/gates/m03-acceptance.md`.
  ```bash
  . scripts/lib/env.sh
  xcodebuild archive -scheme markdown -configuration Release -destination 'generic/platform=macOS' -archivePath build/sig.xcarchive -quiet \
    CODE_SIGN_IDENTITY="$(envget APPLE_DEVELOPER_ID_IDENTITY)" DEVELOPMENT_TEAM="$(envget APPLE_TEAM_ID)"
  A=$(echo build/sig.xcarchive/Products/Applications/*.app)
  for c in "$A" "$A"/Contents/PlugIns/*.appex; do codesign -dvv "$c" 2>&1 | grep -cE '^Authority=Developer ID Application|^Timestamp=|flags=0x10000\(runtime\)'; done
  ```
  Expected: `3` and `3`. The app and the extension are each Developer ID signed, timestamped and hardened.
- [ ] **Step 6: Commit:** `Config/Release.xcconfig`, "build: Developer ID manual signing, hardened runtime, secure timestamp for Release".

### Task 12: `scripts/release.sh` (Fri 20 – Sat 21 Nov)

**Files:**
- Create: `scripts/release.sh` (chmod +x)
- Create: `scripts/entitlements/markdown.plist`, `scripts/entitlements/markdown.quicklook.plist`
- Test: `scripts/release_test.sh`
- Modify: `Makefile` (add a `test-release` target and include it in `check`)

**Interfaces:**
- Consumes:
  - `scripts/lib/env.sh` (plan 01 Task 1) and the `.env` keys `APPLE_TEAM_ID`, `APPLE_DEVELOPER_ID_IDENTITY`, `NOTARY_KEYCHAIN_PROFILE`, `CLOUDFLARE_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`;
  - `Config/PolarSandbox.xcconfig` (Task 8);
  - Sparkle Keychain account `tegelapps` (Task 10);
  - Release signing (Task 11).
- Produces:
  - **`scripts/release.sh <app> <version> [--sandbox] [--yes] [--no-upload] [--print-config] [--from-dmg <path>]`**:
    - `<app>` ∈ `markdown`. The `case` sets `SLUG`, `SCHEME`, `NAME` and `VOL`; **after the `case`, every path derives from `$SLUG`** and no line names an app (CR-P0-1). Plan 06 adds `data`; plan 07 adds `select` and `markdown-setapp`;
    - `<version>` matches `^[0-9]+\.[0-9]+\.[0-9]+(-(b|rc)[0-9]+)?$`, so `1.0.0`, `1.0.0-b1` and `1.0.0-rc1` (plans 05–07) all pass. A `-bN`/`-rcN` version requires `--no-upload`: no beta or RC reaches the public feed (K7);
    - `--sandbox` builds Release with the sandbox Polar values. It requires `--no-upload`: betas are private (K7);
    - `--yes` skips the publish prompt. **Claude passes `--yes` only after the user approved that exact version in chat**;
    - `--no-upload` stops after the notarised, stapled DMG passes Gatekeeper, and prints the DMG's absolute path as the last stdout line: no appcast, no R2, no prompt. Plans 05, 06 and 07 use it for RCs and pre-publish smoke tests;
    - `--print-config` prints the resolved paths and exits 0, before any guard (no `.env`, clean tree or build needed):
      ```
      out=dist-release/markdown/1.0.0
      dmg=TegelMarkdown-1.0.0.dmg
      feed=https://downloads.tegelapps.com/markdown/appcast.xml
      download_prefix=https://downloads.tegelapps.com/markdown/
      r2=$R2_BUCKET/markdown/
      ```
      (`$R2_BUCKET` is printed as written, never resolved);
    - `--from-dmg <path>` publishes a DMG that an earlier `--no-upload` run built and that was smoke-tested, with **no rebuild** (CR-P2-2). It checks the DMG, prints its `sha256`, then runs the appcast, confirm and upload steps. It can't be combined with `--no-upload`.
  - **Exit codes:** 2 = usage error, 1 = guard or step failure, 0 = published (or, with `--no-upload` or `--print-config`, done).
  - **Artefacts:**
    - `dist-release/$SLUG/<version>/` (gitignored);
    - `dist-release/$SLUG/appcast.xml`, a copy of the last published feed. It is the base of the next release's appcast; the public feed is never fetched back (K7);
    - public `https://downloads.tegelapps.com/$SLUG/<NAME>-<version>.dmg` and `…/$SLUG/appcast.xml`.
  - `scripts/entitlements/<target>.plist`: the allowed entitlements for each signed bundle, named by its bundle id minus `com.tegelapps.` (K7).
  - `check_ents <bundle> <expected.plist>`, `check_direct <settings>`, `check_unlocked`, `check_unpublished`, `check_app <app>` and `r2put <file> <key> <content-type> <cache-control>`, functions in `release.sh`. The script runs `main` only when executed, so `release_test.sh` can source it.

- [ ] **Step 1: Write the failing test** `scripts/release_test.sh`. It uses no network, no Developer ID and no build; the entitlement cases sign a copy of `/usr/bin/true` ad hoc.
  ```bash
  #!/usr/bin/env bash
  # Guard tests for release.sh. Runs it in throwaway clones so the real tree and .env are never touched.
  set -uo pipefail
  ROOT=$(git rev-parse --show-toplevel); pass=0; fail=0; tmps=(); trap 'rm -rf "${tmps[@]}"' EXIT
  X=$(mktemp -d); tmps+=("$X")                                # fixtures outside every clone
  KEYS="APPLE_TEAM_ID APPLE_DEVELOPER_ID_IDENTITY NOTARY_KEYCHAIN_PROFILE CLOUDFLARE_ACCOUNT_ID R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY R2_BUCKET"
  U="usage: scripts/release.sh <app> <version> [--sandbox] [--yes] [--no-upload] [--print-config] [--from-dmg <path>]"
  PC=$'out=dist-release/markdown/1.0.0\ndmg=TegelMarkdown-1.0.0.dmg\nfeed=https://downloads.tegelapps.com/markdown/appcast.xml\ndownload_prefix=https://downloads.tegelapps.com/markdown/\nr2=$R2_BUCKET/markdown/'
  commit() { git -C "$D" add -A && git -C "$D" -c user.name=t -c user.email=t@t commit -qm t; }
  fresh() { local t; t=$(mktemp -d); tmps+=("$t"); git clone -q "$ROOT" "$t"; D=$t
    cp "$ROOT/scripts/release.sh" "$D/scripts/" && echo 'TG_POLAR_ORGANIZATION_ID = REPLACE_IN_PLAN_05' >> "$D/Config/Release.xcconfig"
    commit; for k in $KEYS; do echo "$k=dummy-secret-value"; done > "$D/.env"; }
  check() { local name=$1 want=$2 sub=$3; shift 3; local out got
    out=$(cd "$D" && ./scripts/release.sh "$@" </dev/null 2>&1); got=$?
    if [[ $got == "$want" && $out == *"$sub"* && $out != *dummy-secret-value* ]]; then ((pass++)); else ((fail++)); echo "FAIL $name (exit $got): $out"; fi; }
  ents() { local name=$1 want=$2 bin=$3 out got
    out=$(bash -c '. "$1/scripts/release.sh"; check_ents "$2" "$3"' _ "$D" "$bin" "$X/ok.plist" 2>&1); got=$?
    if [[ $got == "$want" ]]; then ((pass++)); else ((fail++)); echo "FAIL $name (exit $got): $out"; fi; }
  fn() { local name=$1 want=$2 sub=$3 out got; shift 3   # runs one release.sh function; variables set on the call reach it
    out=$(bash -c '. "$1/scripts/release.sh"; shift; "$@"' _ "$D" "$@" 2>&1); got=$?
    if [[ $got == "$want" && $out == *"$sub"* ]]; then ((pass++)); else ((fail++)); echo "FAIL $name (exit $got): $out"; fi; }

  fresh; check usage            2 "$U"
         check unknown-app      2 "unknown app: nope"      nope 1.0.0
         check bad-version      2 "bad version: 1.0"       markdown 1.0
         check bad-flag         2 "$U"                     markdown 1.0.0 --bogus   # so no-upload below proves the flag is parsed
         check sandbox-public   2 "--sandbox builds are private: add --no-upload"  markdown 1.0.0-b1 --sandbox
         check rc-public        2 "pre-release builds are private: add --no-upload" markdown 1.0.0-rc1 --yes
         check from-dmg-no-path 2 "$U"                     markdown 1.0.0 --from-dmg
         check from-dmg-local   2 "--from-dmg publishes: drop --no-upload"         markdown 1.0.0 --from-dmg x.dmg --no-upload
         check print-config     0 "$PC"                    markdown 1.0.0 --print-config
  sed -i '' '/^APPLE_TEAM_ID=/d' "$D/.env"
         check missing-key      1 "missing .env key: APPLE_TEAM_ID" markdown 1.0.0
  fresh; touch "$D/stray.txt"
         check dirty-tree       1 "working tree is dirty"  markdown 1.0.0
  fresh; check placeholder      1 "Config/Release.xcconfig still has REPLACE_IN_PLAN_05" markdown 1.0.0
         check rc-version       1 "Config/Release.xcconfig still has REPLACE_IN_PLAN_05" markdown 1.0.0-rc1 --no-upload   # passes the version regex
         check no-upload        1 "Config/Release.xcconfig still has REPLACE_IN_PLAN_05" markdown 1.0.0 --no-upload
  fresh; sed -i '' 's/REPLACE_IN_PLAN_05/x/g' "$D/Config/Release.xcconfig"; commit; touch "$X/Other.dmg" "$X/TegelMarkdown-1.0.0.dmg"
         check from-dmg-missing 1 "no such DMG: $X/none/TegelMarkdown-1.0.0.dmg" markdown 1.0.0 --from-dmg "$X/none/TegelMarkdown-1.0.0.dmg"
         check from-dmg-name    1 "expected TegelMarkdown-1.0.0.dmg, got Other.dmg" markdown 1.0.0 --from-dmg "$X/Other.dmg"
         check from-dmg-stapled 1 "not notarised and stapled: TegelMarkdown-1.0.0.dmg" markdown 1.0.0 --from-dmg "$X/TegelMarkdown-1.0.0.dmg"
  # Entitlement allowlist (K7): the same set passes; one extra key fails.
  P=/usr/libexec/PlistBuddy
  $P -c 'Add :com.apple.security.app-sandbox bool true' "$X/ok.plist" >/dev/null
  cp "$X/ok.plist" "$X/extra.plist"; $P -c 'Add :com.apple.security.get-task-allow bool true' "$X/extra.plist"
  for v in ok extra; do cp /usr/bin/true "$X/$v"; codesign -f -s - --entitlements "$X/$v.plist" "$X/$v" 2>/dev/null; done
  ents ents-match 0 "$X/ok"
  ents ents-extra 1 "$X/extra"
  # No store flag in a direct build: plan 07's UNLOCKED/MAS there would ship Pro free.
  fn direct-clean       0 ""           check_direct $'    SWIFT_ACTIVE_COMPILATION_CONDITIONS = \n'
  fn direct-store-flag  1 "store flag" check_direct $'    SWIFT_ACTIVE_COMPILATION_CONDITIONS = MAS UNLOCKED\n'
  # A locked screen hides the notary profile (Task 3 Step 4); a stub ioreg reports one.
  mkdir -p "$X/bin"; printf '%s\n' '#!/bin/sh' "echo '\"CGSSessionScreenIsLocked\"=Yes'" > "$X/bin/ioreg"; chmod +x "$X/bin/ioreg"
  PATH="$X/bin:$PATH" fn locked 1 "unlock the Mac first" check_unlocked
  # A published version is never published again: named in the last feed, or already on R2 (file:// stands in for downloads.tegelapps.com).
  echo '<enclosure url="https://downloads.tegelapps.com/markdown/TegelMarkdown-1.0.1.dmg"/>' > "$X/feed.xml"
  PREV=$X/none.xml PREFIX=file://$X/ DMG_NAME=TegelMarkdown-1.0.2.dmg fn unpublished     0 ""                  check_unpublished
  PREV=$X/feed.xml PREFIX=file://$X/ DMG_NAME=TegelMarkdown-1.0.1.dmg fn already-in-feed 1 "already published" check_unpublished
  PREV=$X/none.xml PREFIX=file://$X/ DMG_NAME=TegelMarkdown-1.0.0.dmg fn already-on-r2   1 "already published" check_unpublished
  # --from-dmg: another app's DMG renamed to this app's name fails on its bundle id.
  mkdir -p "$X/Data.app/Contents"; $P -c 'Add :CFBundleIdentifier string com.tegelapps.data' "$X/Data.app/Contents/Info.plist" >/dev/null
  SLUG=markdown fn from-dmg-wrong-app 1 "expected com.tegelapps.markdown, got com.tegelapps.data" check_app "$X/Data.app"
  # An app with no extensions (App 3) checks only itself: the unmatched *.appex glob is skipped, so an ad hoc signed app reaches the benefit check.
  mkdir -p "$X/Select.app/Contents/MacOS" "$D/scripts/entitlements"; cp /usr/bin/true "$X/Select.app/Contents/MacOS/Select"
  $P -c 'Add :CFBundleIdentifier string com.tegelapps.select' -c 'Add :CFBundleExecutable string Select' "$X/Select.app/Contents/Info.plist" >/dev/null
  codesign -f -s - --entitlements "$X/ok.plist" "$X/Select.app" 2>/dev/null; cp "$X/ok.plist" "$D/scripts/entitlements/select.plist"
  cd "$D"; SLUG=select TEAM="not set" fn from-dmg-no-appex 1 "TGPolarBenefitID is not TG_POLAR_BENEFIT_ID_SELECT" check_app "$X/Select.app"; cd - >/dev/null
  echo "release_test: $pass passed, $fail failed"; [[ $fail == 0 ]]
  ```
- [ ] **Step 2: Run it to verify it fails.** `bash scripts/release_test.sh`. Expected: FAIL, `cp: …/scripts/release.sh: No such file or directory`, … `release_test: 0 passed, 27 failed`.
- [ ] **Step 3: Implement.**
  - **`scripts/entitlements/`** (the allowlist; any change to it is a reviewed commit, never generated from `project.yml`):
    ```bash
    P=/usr/libexec/PlistBuddy; A=scripts/entitlements/markdown.plist; Q=scripts/entitlements/markdown.quicklook.plist; G=com.apple.security.temporary-exception.mach-lookup.global-name
    mkdir -p scripts/entitlements
    for k in app-sandbox files.user-selected.read-write files.bookmarks.app-scope network.client; do $P -c "Add :com.apple.security.$k bool true" "$A"; done
    $P -c "Add :$G array" -c "Add :$G: string com.tegelapps.markdown-spks" -c "Add :$G: string com.tegelapps.markdown-spki" "$A"
    for k in app-sandbox network.client; do $P -c "Add :com.apple.security.$k bool true" "$Q"; done
    plutil -p "$A"; plutil -p "$Q"
    ```
    Expected: the app file holds D5's four keys plus the two mach-lookup names; the Quick Look file holds plan 01's Quick Look set after K4 (`app-sandbox`, `network.client`, no `files.absolute-path` exception). If plan 01's Quick Look set differs, copy plan 01's, never widen it here.
  - **`scripts/release.sh`** runs under `set -euo pipefail` and **never uses `set -x`**. Its last line is `if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi`. `check_ents` and the other checks are below (the new cases ran under `/bin/bash` 3.2 against these bodies on the build Mac, 27 Oct: 7 passed; with `check_unpublished`'s `die` removed, 2 failed; `from-dmg-no-appex` passed, and without `[ -e "$b" ] || continue` it failed with `Print: Entry, ":CFBundleIdentifier", Does Not Exist`):
    ```bash
    check_ents() {   # <bundle> <expected.plist>: the signed entitlements must equal the allowlist exactly
      diff <(codesign -d --entitlements - --xml "$1" 2>/dev/null | plutil -convert xml1 -o - -) <(plutil -convert xml1 -o - "$2") >/dev/null \
        || die 1 "entitlements of ${1##*/} differ from $2"; }
    check_direct() {   # <-showBuildSettings output>: a store flag (plan 07) in a direct build would ship Pro unlocked
      if grep -qE '^ *SWIFT_ACTIVE_COMPILATION_CONDITIONS = (.* )?(UNLOCKED|MAS)( |$)' <<<"$1"; then die 1 "direct build has a store flag (UNLOCKED or MAS)"; fi; }
    check_unlocked() {   # a locked screen hides the notary profile from notarytool (Task 3 Step 4)
      local r; r=$(ioreg -n Root -d1)
      if [[ $r == *'"CGSSessionScreenIsLocked"=Yes'* ]]; then die 1 "the screen is locked: unlock the Mac first"; fi; }
    check_unpublished() {   # the DMG is cached as immutable for a year, so a version is published once
      if { [ -f "$PREV" ] && grep -qF "$DMG_NAME" "$PREV"; } || curl -fsI "$PREFIX$DMG_NAME?probe=$$" >/dev/null 2>&1; then   # own cache key: a CDN-cached 404 must not reach step 15
        die 1 "$DMG_NAME already published; bump the version"; fi; }
    check_app() {   # <app>: a --from-dmg app is this app, signed by our team, with its allowlisted entitlements and benefit
      local p=/usr/libexec/PlistBuddy id b k w
      id=$($p -c 'Print :CFBundleIdentifier' "$1/Contents/Info.plist"); [ "$id" = "com.tegelapps.$SLUG" ] || die 1 "expected com.tegelapps.$SLUG, got $id"
      [ "$(codesign -dv "$1" 2>&1 | sed -n 's/^TeamIdentifier=//p')" = "$TEAM" ] || die 1 "${1##*/} is not signed by the APPLE_TEAM_ID team"
      for b in "$1" "$1"/Contents/PlugIns/*.appex; do [ -e "$b" ] || continue; id=$($p -c 'Print :CFBundleIdentifier' "$b/Contents/Info.plist"); check_ents "$b" "scripts/entitlements/${id#com.tegelapps.}.plist"; done
      k=TG_POLAR_BENEFIT_ID_$(printf %s "$SLUG" | tr a-z- A-Z_); w=$(sed -n "s/^$k *= *//p" Config/Release.xcconfig)
      [ -n "$w" ] && [ "$($p -c 'Print :TGPolarBenefitID' "$1/Contents/Info.plist")" = "$w" ] || die 1 "TGPolarBenefitID is not $k from Config/Release.xcconfig"; }
    r2put() {   # <file> <key> <content-type> <cache-control>: S3 SigV4 PUT to R2 with curl; no npm code at release time (K2)
      curl --fail -sS -o /dev/null --aws-sigv4 "aws:amz:auto:s3" --user "$R2_KEY_ID:$R2_SECRET" -H "Content-Type: $3" -H "Cache-Control: $4" \
        -T "$1" "https://$ACCOUNT.r2.cloudflarestorage.com/$R2_BUCKET/$2"; }
    ```
    - `check_app` expects bundle id `com.tegelapps.$SLUG` (master §3.1: prefix + target name) and the benefit from `TG_POLAR_BENEFIT_ID_<SLUG in capitals>`, so plan 06's `data` row needs no change.
    - `r2put` passes the S3 credentials in curl's argv; the master accepts that on the single-user build Mac. It is the command Task 2 Step 5 probed.
    `main`, in order:
    1. **Arguments.**
       - Parse. No args, an unknown flag or `--from-dmg` without a path → the usage line, exit 2.
       - `case $app in markdown) SLUG=markdown SCHEME=markdown NAME=TegelMarkdown VOL="Tegel Markdown";; *) die 2 "unknown app: $app";; esac`.
       - Version regex → `bad version: $V`, exit 2.
       - `--sandbox` without `--no-upload` → `--sandbox builds are private: add --no-upload`, exit 2. Then a `-bN`/`-rcN` version without `--no-upload` → `pre-release builds are private: add --no-upload`, exit 2 (this also stops `--from-dmg` on a pre-release). `--from-dmg` with `--no-upload` → `--from-dmg publishes: drop --no-upload`, exit 2.
       - Derived, from `$SLUG` only: `BASE=https://downloads.tegelapps.com`, `OUT=dist-release/$SLUG/$V`, `DMG_NAME=$NAME-$V.dmg`, `FEED=$BASE/$SLUG/appcast.xml`, `PREFIX=$BASE/$SLUG/`, `PREV=dist-release/$SLUG/appcast.xml`.
       - `--print-config` → print the five lines in Interfaces, exit 0.
    2. **Guards.**
       - `cd "$(git rev-parse --show-toplevel)"`, then `. scripts/lib/env.sh`;
       - `need` the seven keys (exit 1, `missing .env key: KEY`; only the name is printed). Values go into **unexported** shell variables with `envget` (`TEAM`, `IDENTITY`, `PROFILE`, `ACCOUNT`, `R2_KEY_ID`, `R2_SECRET`, `R2_BUCKET`), and each reaches only the commands that need it;
       - `[ -z "$(git status --porcelain)" ] || die 1 "working tree is dirty"`;
       - without `--sandbox`, `grep -q REPLACE_IN_PLAN_05 Config/Release.xcconfig` → `Config/Release.xcconfig still has REPLACE_IN_PLAN_05; pass --sandbox for a beta`, exit 1.
    3. **`--from-dmg <path>`** replaces steps 4–11 (each failure → exit 1):
       - `[ -f "$SRC" ] || die 1 "no such DMG: $SRC"`; `[ "${SRC##*/}" = "$DMG_NAME" ] || die 1 "expected $DMG_NAME, got ${SRC##*/}"`;
       - `xcrun stapler validate "$SRC" >/dev/null 2>&1 || die 1 "not notarised and stapled: $DMG_NAME"`, then step 11's `spctl -t open` check;
       - `hdiutil attach -nobrowse -readonly -mountpoint "$OUT/mnt" "$SRC"` (detached by a `trap`): the app's `CFBundleShortVersionString == $V`, `TGPolarAPIBase == https://api.polar.sh`, and `BUILD` = its `CFBundleVersion`;
       - `check_app "$OUT/mnt/"*.app`: the bundle id is this app's, the TeamIdentifier from `codesign -dv` is `APPLE_TEAM_ID`, the app and appex entitlements equal the allowlist, and `TGPolarBenefitID` equals this app's key in `Config/Release.xcconfig`. A renamed DMG of another app stops here, before its feed is signed;
       - print `sha256 $(shasum -a 256 "$SRC" | cut -d' ' -f1)`. Plan 05 compares it with the smoke-tested file's hash;
       - `$OUT` is **not** wiped (the DMG usually lives in it); `check_unlocked` (the appcast step uses the Sparkle key in the Keychain); go to step 12.
    4. **Set up:**
       - `check_unlocked`, first: a locked screen hides the notary profile (Task 3 Step 4). It sits here and at the end of item 3, before each path's first Keychain use, so `release_test.sh`'s full-script cases never depend on the screen;
       - `OUT` wiped; `BUILD=$(git rev-list --count HEAD)` (a monotonic `CFBundleVersion` that Sparkle compares); `xcodegen generate`;
       - `S=$(xcodebuild -project Tegel.xcodeproj -scheme "$SCHEME" -configuration Release -showBuildSettings 2>/dev/null)`, then `check_direct "$S"`: the direct build's `SWIFT_ACTIVE_COMPILATION_CONDITIONS` holds neither `UNLOCKED` nor `MAS` (plan 07's store flags; a leak would ship Pro free). Every app here is direct; plan 07's Setapp channel skips this line. A failing `xcodebuild` stops the script at the assignment (`set -e`), so the check never passes on empty output.
    5. **Archive:**
       ```
       xcodebuild archive -scheme $SCHEME -configuration Release -destination 'generic/platform=macOS' \
         -derivedDataPath build/release-dd -archivePath "$OUT/$SCHEME.xcarchive" \
         MARKETING_VERSION=$V CURRENT_PROJECT_VERSION=$BUILD \
         CODE_SIGN_IDENTITY="$IDENTITY" DEVELOPMENT_TEAM="$TEAM"
       ```
       Add `-xcconfig Config/PolarSandbox.xcconfig` when `--sandbox` is passed.
    6. **Export:** `ExportOptions.plist` generated in `$OUT` with `plutil -create xml1` + `-insert` (`method developer-id`, `signingStyle manual`, `signingCertificate "Developer ID Application"`, `teamID`; method names checked against `xcodebuild -help` on Xcode 26.3), then `xcodebuild -exportArchive … -exportPath "$OUT/export"`; `APP=$(echo "$OUT"/export/*.app)`.
    7. **Pre-notary checks** (each failure → exit 1):
       - PlistBuddy `CFBundleShortVersionString == $V` and `CFBundleVersion == $BUILD`;
       - `TGPolarAPIBase` == `https://sandbox-api.polar.sh` (`--sandbox`) or `https://api.polar.sh`; `TGPolarBenefitID` non-empty (D1);
       - `lipo -archs` on the app and appex executables contains both `x86_64` and `arm64`;
       - **entitlements (K7):** for `$APP` and each `$APP/Contents/PlugIns/*.appex` that exists (the same `[ -e "$b" ] || continue` loop as `check_app`: App 3 has no extension), `check_ents "$b" "scripts/entitlements/${id#com.tegelapps.}.plist"`, where `id` is the bundle's `CFBundleIdentifier`;
       - `codesign --verify --deep --strict --verbose=2 "$APP"`; `syspolicy_check notary-submission "$APP"`.
    8. **`notarize <file>`:** `xcrun notarytool submit "$1" --keychain-profile "$PROFILE" --wait --output-format json > "$OUT/notary-<n>.json"`; `plutil -extract status raw -o - <json>` must be `Accepted` (plutil reads JSON; checked on the build Mac), otherwise write `xcrun notarytool log <id> …` to `$OUT/notary-log.json` and exit 1.
    9. **App:** `ditto -c -k --keepParent "$APP" "$OUT/app.zip"` → `notarize` → `xcrun stapler staple "$APP"`.
    10. **DMG:** `ditto "$APP" "$OUT/dmg/${APP##*/}"`; `ln -s /Applications "$OUT/dmg/Applications"`; `hdiutil create -volname "$VOL" -srcfolder "$OUT/dmg" -format UDZO -ov "$OUT/$DMG_NAME"`; `codesign --sign "$IDENTITY" --timestamp` the DMG → `notarize` → `xcrun stapler staple`.
    11. **Gatekeeper.** All must pass; print the outputs:
        - `spctl -a -vvv -t exec "$APP"` → `accepted` + `source=Notarized Developer ID`;
        - `spctl -a -vvv -t open --context context:primary-signature "$OUT/$DMG_NAME"` → the same (`-t install` is for installer packages, `man spctl`);
        - `xcrun stapler validate "$OUT/$DMG_NAME"` → `The validate action worked!`; `syspolicy_check distribution "$APP"` → exit 0.
        - With `--no-upload`: `printf '%s\n' "$PWD/$OUT/$DMG_NAME"` as the last stdout line, then exit 0.
    12. **Appcast:**
        - `rm -rf "$OUT/feed"; mkdir -p "$OUT/feed"`; copy the DMG in;
        - `[ -f "$PREV" ] && cp "$PREV" "$OUT/feed/appcast.xml"`. The previous feed comes only from `dist-release/`, **never `curl`**: a tampered public feed must not flow into the next release (K7). The first release has none; generate_appcast keeps the existing items (`--maximum-versions` defaults to 3);
        - the Sparkle tools: `GA=build/release-dd/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast`; if absent (a `--from-dmg` run in a fresh checkout), `xcodegen generate && xcodebuild -resolvePackageDependencies -derivedDataPath build/release-dd >/dev/null` first;
        - `"$GA" --account tegelapps --download-url-prefix "$PREFIX" -o "$OUT/feed/appcast.xml" "$OUT/feed"`;
        - checks: `grep "$DMG_NAME" "$OUT/feed/appcast.xml" | grep -q 'sparkle:edSignature='` and `grep -q '<!-- sparkle-signatures:' "$OUT/feed/appcast.xml"` (generate_appcast signs the whole feed because the app's Info.plist sets `SURequireSignedFeed`; Sparkle 2.10.1 `generate_appcast/FeedXML.swift`), then print `appcast signatures present`.
    13. **Confirm.** First, always (with `--yes` too), `check_unpublished`: if `$PREV` already names `$DMG_NAME`, or `curl -fsI "$PREFIX$DMG_NAME?probe=$$"` succeeds, exit 1 with `<DMG> already published; bump the version`. The DMG is served `immutable` for a year, so re-signing the same version would leave cached users with a DMG that fails the new feed's signature. Then, unless `--yes`: print the DMG name, `du -h`, `shasum -a 256` and the two destination URLs; `read -r -p "Publish to downloads.tegelapps.com? [y/N] " a || a=`; anything but `y` → `aborted: nothing uploaded`, exit 1. With no TTY, `read` hits EOF and aborts.
    14. **Upload** with `r2put`, DMG first so the appcast never points at a missing file. The bucket-scoped token's S3 credentials go to this one command only (K2), and no npm dependency tree is fetched while codesign, the notary profile and the Sparkle key are usable without a prompt:
        - `r2put "$OUT/feed/$DMG_NAME" "$SLUG/$DMG_NAME" application/x-apple-diskimage "public, max-age=31536000, immutable"`;
        - then `r2put "$OUT/feed/appcast.xml" "$SLUG/appcast.xml" application/xml "public, max-age=300"`.
    15. **Post-upload:**
        - `curl -fsSI "$PREFIX$DMG_NAME?v=$BUILD" | head -1` → `HTTP/2 200` (a query unique to this run, as on the feed, so the CDN can't answer with the 404 it may have cached from step 13; R2 ignores the query); `curl -fsS "$FEED?v=$BUILD" | grep -c "$DMG_NAME"` ≥ 1 (a read-back check only);
        - `cp "$OUT/feed/appcast.xml" "$PREV"`, the base for the next release;
        - print `published $PREFIX$DMG_NAME`: the `downloadURL` that the publishing plan copies into `site/config.json` with the version (plan 05 for App 1, plan 06 for App 2; plan 04 CR-5).
  - **Makefile:** `test-release: ; bash scripts/release_test.sh`, and add `test-release` to `check`'s prerequisites.
- [ ] **Step 4: Run it to verify it passes.**
  - `bash scripts/release_test.sh`. Expected: `release_test: 27 passed, 0 failed`.
  - `bash -n scripts/release.sh && echo syntax-ok` → `syntax-ok`.
  - `make check` → the baseline, plus TegelStore, plus `release_test: 27 passed`.
- [ ] **Step 5: Watch the new guards fail.** One at a time, re-running `bash scripts/release_test.sh` after each, then restoring:
  - make `check_ents` `return 0` → `FAIL ents-extra (exit 0)`;
  - delete the `--sandbox` needs `--no-upload` rule → `FAIL sandbox-public` (it now meets the pre-release rule's message);
  - delete the pre-release needs `--no-upload` rule → `FAIL rc-public` (exit 1 at the placeholder guard);
  - delete the `stapler validate` line → `FAIL from-dmg-stapled` (the empty file then fails at `spctl`, with another message; `stapler` and `spctl` on an empty file exit 66 and 3, checked on the build Mac);
  - make `check_direct`, `check_unlocked` and `check_app` each `return 0` in turn → `FAIL direct-store-flag`, `FAIL locked`, `FAIL from-dmg-wrong-app`; drop `[ -e "$b" ] || continue` → `FAIL from-dmg-no-appex`;
  - delete `check_unpublished`'s `die` → `FAIL already-in-feed` and `FAIL already-on-r2`.
  - Restored: `27 passed, 0 failed`.
  - A `markdown/` literal can't be caught while `markdown` is the only app. Plan 06's `data` row adds the standing guard: a `print-config` case expecting `dist-release/data/<v>`, `…/data/appcast.xml` and `r2=$R2_BUCKET/data/`, watched failing (`unknown app: data`) before the row exists.
- [ ] **Step 6: Commit:** `scripts/release.sh scripts/release_test.sh scripts/entitlements Makefile`, "feat(release): release.sh archive→notarise→DMG→signed appcast→R2, with print-config, from-dmg and an entitlement allowlist".
- [ ] **Step 7: First real run (needs Task 3, done 27 Oct).** This is Task 13 step 1.

### Task 13: End-to-end acceptance on private betas, BNPL record (Sat 21 – Sun 22 Nov; needs Task 3)

**Machine:**
- Build Mac (Intel iMac19,1, macOS 15.7), in a **fresh admin user account `tegeltest`** that the user creates.
- The arm64 / macOS 27 leg runs on Scaleway M1 lease **L2 (Thu 26 Nov 09:00 → Fri 27 Nov 09:00)**, booked by plan 05. It is second in L2's order, after plan 05's macOS 27 matrix (see Hand-offs).

**Distribution (K7):** b1 and b2 never leave the machine. They are `--sandbox --no-upload` builds in `dist-release/markdown/beta-feed/`, served by `python3 -m http.server 8765 --bind 127.0.0.1 --directory dist-release/markdown/beta-feed`, which runs in the background from the main account.
- `tegeltest` reaches it at `http://localhost:8765/`. `localhost` is an unqualified name, which ATS still allows by default on macOS 14+; bare IP addresses it no longer allows (Apple's `NSAllowsLocalNetworking` reference, checked 27 Oct).
- The b1 app reads the local feed through `-SUFeedURL` at launch. Sparkle 2.10.1 reads `SUFeedURL` from user defaults, the argument domain included, before Info.plist (`SUHost objectForKey:`), and its own log calls such an override fine "for testing purposes" (`SPUUpdater.m`).

**Files:**
- Create: `docs/gates/m03-acceptance.md` (table: check | machine | date | result | evidence)
- Create: `docs/gates/bnpl.md`
- Create: `docs/reviews/m03.md` (the "Pre-b1" section; Task 14 adds the rest)

**Interfaces:**
- Consumes everything above.
- Produces the evidence for the milestone exit criterion, and `dist-release/markdown/beta-feed/` (the b1 and b2 DMGs and a signed `appcast.xml`), kept for the L2 leg until Task 15.

- [ ] **Step 0: Pre-b1 review** (master §11: stages 2, 3, 4 and 9 of Procedure P before cutting b1). b1 is the first signed build of the licensing code, `release.sh` and the signed feed. The full P still runs in Task 14.
  - `BASE=$(git merge-base HEAD main)`. Run stages 2, 3, 4 and 9 on `git diff $BASE...HEAD`, with Task 14's stage-4 scope. Where that scope inspects "the b2 app", use the app from `scripts/release.sh markdown 1.0.0-b1 --sandbox --no-upload`.
  - Fix every P0/P1 (failing test first), then re-run the stage that found it.
  - Record the results under "Pre-b1" in `docs/reviews/m03.md`. Commit: `docs/reviews/m03.md`, "docs(reviews): m03 pre-b1 stages 2, 3, 4, 9". `release.sh` needs a clean tree.
- [ ] **Step 1: Build b1 and serve it locally.** Nothing leaves the machine, so no ask.
  ```bash
  scripts/release.sh markdown 1.0.0-b1 --sandbox --no-upload
  F=dist-release/markdown/beta-feed; mkdir -p "$F" && cp dist-release/markdown/1.0.0-b1/TegelMarkdown-1.0.0-b1.dmg "$F/"
  ```
  - Expected: Task 12's Gatekeeper lines (step 3, item 11) all accepted, and the DMG path as the last line. This is the first real run of the entitlement allowlist on Developer ID bundles. If `check_ents` fails, stop and compare the signed set with D5; the allowlist changes only through a reviewed commit, never to make a build pass.
  - Start the server in the background (Bash `run_in_background`): `python3 -m http.server 8765 --bind 127.0.0.1 --directory dist-release/markdown/beta-feed`. Check: `curl -sI http://localhost:8765/TegelMarkdown-1.0.0-b1.dmg | head -1` → `HTTP/1.0 200 OK`.
- [ ] **Step 2 (user):** create the admin account `tegeltest` in System Settings → Users & Groups, and log in to it (fast user switching; the server keeps running).
- [ ] **Step 3 (GUI, tegeltest): download and mount.**
  - Safari → `http://localhost:8765/TegelMarkdown-1.0.0-b1.dmg`;
  - `xattr -p com.apple.quarantine ~/Downloads/TegelMarkdown-1.0.0-b1.dmg` prints a value (quarantine is set);
  - open it. The window shows the app and an Applications alias. Drag to Applications.
- [ ] **Step 4 (GUI): first launch.** Record the dialog text verbatim.
  - Pass = only the standard "…downloaded from the Internet. Are you sure you want to open it?" prompt.
  - Then `spctl -a -vvv -t exec "/Applications/Tegel Markdown.app"` → `accepted`, `source=Notarized Developer ID`.
- [ ] **Step 5:** add the b1 rows to `docs/gates/m03-acceptance.md`. Commit: `docs/gates/m03-acceptance.md`, "docs(gates): m03 b1 acceptance". This later commit gives b2 a higher `CFBundleVersion`.
- [ ] **Step 6: Build b2 and the signed local feed.**
  ```bash
  scripts/release.sh markdown 1.0.0-b2 --sandbox --no-upload
  F=dist-release/markdown/beta-feed; cp dist-release/markdown/1.0.0-b2/TegelMarkdown-1.0.0-b2.dmg "$F/"
  build/release-dd/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast --account tegelapps --download-url-prefix http://localhost:8765/ -o "$F/appcast.xml" "$F"
  grep -c '<item>' "$F/appcast.xml"; grep -c 'sparkle-signatures:' "$F/appcast.xml"
  ```
  Expected: `2`, then `1` (the feed is signed, because the apps set `SURequireSignedFeed`). The first `generate_appcast` run may raise a Keychain prompt for the Sparkle key: the **user** clicks **Always Allow**; record it.
- [ ] **Step 7 (GUI, tegeltest): the signed feed, watched failing, then the update.**
  1. Main account, tamper one byte: `F=dist-release/markdown/beta-feed; cp "$F/appcast.xml" "$F/appcast.good" && sed -i '' 's|<channel>|<channel> |' "$F/appcast.xml"`.
  2. tegeltest: quit the app, then `open -a "Tegel Markdown" --args -SUFeedURL http://localhost:8765/appcast.xml`, then Check for Updates…. Expected: **no update is offered**, and Sparkle reports an error. Record the text verbatim. This is `SURequireSignedFeed` failing as it should (K7).
  3. Main account: `mv dist-release/markdown/beta-feed/appcast.good dist-release/markdown/beta-feed/appcast.xml`. tegeltest: Check for Updates… → b2 is offered.
  4. For the Task 14 design review, before installing: `mkdir -p /Users/Shared/m03 && screencapture -x -w /Users/Shared/m03/sparkle-prompt-light.png` (click the prompt). Switch System Settings ▸ Appearance to Dark and capture `…-dark.png`; switch back. Click Remind Me Later, quit, `open -a "Tegel Markdown" --args -AppleLanguages '(ar)' -SUFeedURL http://localhost:8765/appcast.xml`, Check for Updates…, capture `…-ar.png`, then quit and relaunch with only the `-SUFeedURL` argument.
  5. Check for Updates… → Install and Relaunch. Then `defaults read "/Applications/Tegel Markdown.app/Contents/Info" CFBundleShortVersionString` → `1.0.0-b2`, and `spctl -a -vvv -t exec` again → `accepted`.
  - If step 2 or 3 fails with a connection or App Transport Security error instead, stop: record it and ask the user. Don't add an ATS exception to the shipping Info.plist.
- [ ] **Step 8 (GUI): purchase.**
  - Settings → Licence → Buy Pro… → the sandbox checkout opens;
  - pay as `POLAR_EMAIL` with `4242 4242 4242 4242`. Expected: the success page.
- [ ] **Step 9: Key email.** Record whether the email to `POLAR_EMAIL` contains the key. If it doesn't, take the key from the portal; that result feeds plan 05's FAQ.
- [ ] **Step 10 (GUI): activate.**
  - Paste the key with leading spaces and a trailing newline → Activate. Expected: "Pro is active on this Mac", and folder mode works.
  - Dashboard: the activation label = `sysctl -n hw.model`.
- [ ] **Step 11 (GUI): offline relaunch.** Disconnect the network, ⌘Q, relaunch. Expected: still Pro, no error dialog. Reconnect.
- [ ] **Step 12 (GUI): deactivate.** Deactivate this Mac. Expected: the free copy, and 0 activations in the dashboard.
- [ ] **Step 13: Error copy.**
  - Key `TEGEL-0000` → the `.notFound` copy.
  - Fill both slots of `POLAR_SANDBOX_TEST_LICENSE_KEY` (the activation ids go to a gitignored file, because the next block runs in another shell):
    ```bash
    . scripts/lib/env.sh
    O=$(envget POLAR_SANDBOX_ORGANIZATION_ID); K=$(envget POLAR_SANDBOX_TEST_LICENSE_KEY); A=https://sandbox-api.polar.sh/v1/customer-portal/license-keys; T=$(mktemp)
    for l in probe-1 probe-2; do
      curl -s -o "$T" -w '%{http_code}\n' -X POST "$A/activate" -H 'Content-Type: application/json' -d "{\"key\":\"$K\",\"organization_id\":\"$O\",\"label\":\"$l\"}"
      plutil -extract id raw -o - "$T" >> dist-release/m03-probe-ids
    done; rm -f "$T"
    ```
    Expected: `200`, `200`. Then paste the same key in the app and Activate → the `.limitReached` copy. Then free both slots:
    ```bash
    . scripts/lib/env.sh
    O=$(envget POLAR_SANDBOX_ORGANIZATION_ID); K=$(envget POLAR_SANDBOX_TEST_LICENSE_KEY); A=https://sandbox-api.polar.sh/v1/customer-portal/license-keys
    while read -r I; do curl -s -o /dev/null -w '%{http_code}\n' -X POST "$A/deactivate" -H 'Content-Type: application/json' \
      -d "{\"key\":\"$K\",\"organization_id\":\"$O\",\"activation_id\":\"$I\"}"; done < dist-release/m03-probe-ids
    rm dist-release/m03-probe-ids
    ```
    Expected: `204`, `204`.
  - **Another app's key is rejected (D1).** Paste `POLAR_SANDBOX_OTHER_LICENSE_KEY` (Task 1 step 10) as in step 10, then Activate → the `.wrongProduct` copy, and the app stays free. Then prove no activation was left on that key (its limit is 2): run Task 1 step 9's block with `K=$(envget POLAR_SANDBOX_OTHER_LICENSE_KEY)` and without `act probe-3`. Expected: `200`, `200`, `204`, `204`. A `403` on probe-2 means the app left an activation behind.
- [ ] **Step 14 (GUI): the 404 rule, live.**
  1. Activate in the app.
  2. Manage activations… opens the portal; sign in with the emailed code and deactivate this Mac there. This exercises `enable_customer_admin`.
  3. ⌘Q, then relaunch online. Expected: **still Pro** (validate 404 → grace).
  4. Deactivate this Mac. Expected: free (a 404 counts as already done).
- [ ] **Step 15 (GUI): auto-update toggle.**
  - In Settings ▸ Updates, turn "Check for updates automatically" off, ⌘Q, then `defaults read ~/Library/Containers/com.tegelapps.markdown/Data/Library/Preferences/com.tegelapps.markdown SUEnableAutomaticChecks` → `0`.
  - Turn it back on → `1`.
- [ ] **Step 16: Record and commit.**
  - Write all rows into `docs/gates/m03-acceptance.md`, each naming the machine (Intel iMac, macOS 15.7, `tegeltest`). Include the two Keychain "Always Allow" dates (codesign, Task 11 step 5; Sparkle key, step 6) and the tampered-feed error text (step 7).
  - Write `docs/gates/bnpl.md`: the W1 sandbox row (Task 1 step 7: date, checkout, countries tried, methods shown, BNPL present yes/no), plus a row "live checkout: pending plan 05 (W6)".
  - Leave the server running for the L2 leg only if it falls within the same session; otherwise stop it (`pkill -f 'http.server 8765'`). The feed folder stays until Task 15.
  - Commit: `docs/gates/m03-acceptance.md docs/gates/bnpl.md`, "docs(gates): m03 end-to-end acceptance (Intel, private betas) and sandbox BNPL record".

### Task 14: Procedure P, merge, push (Mon 23 Nov)

**Files:**
- Modify: `docs/reviews/m03.md` (created in Task 13 step 0)
- Modify: `.github/workflows/ci.yml` (plan 01)
- Create: `docs/reviews/m03-design/*.png` (design-review screenshots)
- Modify: whatever stage 7 patches

**Interfaces:**
- Consumes: the whole branch.
- Runs **Procedure P (master §11)** with id `m03`, branch `m03-commerce-release` and review file `docs/reviews/m03.md`. Only this plan's deltas follow.

- [ ] **Step 0: CI on release tags.** Plan 01's macOS job runs on `workflow_dispatch` only; release tags `v*` must run it too. The workflow's `on: { push: {}, … }` already fires on tag pushes (adding a `push: tags:` filter there would stop the js job on branch pushes), so widen the job's condition:
  - in `.github/workflows/ci.yml`, job `macos`: `if: github.event_name == 'workflow_dispatch' || startsWith(github.ref, 'refs/tags/v')`;
  - the proof is behavioural and comes with plan 05's first `v*` tag: its push shows the `macos` job running (no source grep, B16);
  - Commit: `.github/workflows/ci.yml`, "ci: run the macOS matrix on v* release tags".
- [ ] **Step 1: Run Procedure P** with these deltas.
  - **Stage 2 counts to record:** bun; swift (TegelKit + 41 TegelStore); `release_test: 27 passed`.
  - **Stage 4 `/cso` scope** (mandatory here: licensing, Keychain, entitlements, Sparkle, `release.sh`, `.env` handling):
    - **TegelStore:**
      - error → grace mapping (no 404 lock); the mid-flight race; key normalisation; no token or `Authorization` sent; HTTPS-only `apiBase`;
      - K5: the skew window (`-1 day ≤ age ≤ grace`); the validate decode (`granted` + the stored activation id); one mutation in flight; the save rollback;
      - the benefit binding: validate sends `benefit_id`; an activate mismatch releases the activation and throws `.wrongProduct`; a missing `benefit_id` fails closed; `TGPolarBenefitID` in the b2 app is the Markdown sandbox benefit.
    - **Keychain:** item attributes and ACL; nothing logged; `failSaves` is internal and only tests set it.
    - **Entitlements:** the b2 app's signed sets equal `scripts/entitlements/*.plist`, and those equal D5 plus the two mach-lookup names (app) and plan 01's Quick Look set.
    - **Sparkle:** `SUPublicEDKey` present; HTTPS feed; `SURequireSignedFeed` and `SUVerifyUpdateBeforeExtraction` true; `SUEnableSystemProfiling` absent; EdDSA on every enclosure and on the feed (Task 13 step 7 watched a tampered feed fail).
    - **`release.sh`:** quoting; no `set -x`; no value echoed; key values unexported; guard order; every path from `$SLUG`; the previous feed only from `dist-release/` (no `curl` fetches a feed to build on); the entitlement diff; `--sandbox` never publishes; the `--from-dmg` checks (`check_app`); no store flag in the direct build; the locked-screen guard; no republished version; the confirmation; upload order; only the bucket-scoped token's S3 credentials, uploaded by `curl` with no npm code (K2).
    - **`.env` (K1):** every block in this plan's code sources `scripts/lib/env.sh`; no `set -a`. **`.env.example`:** names only.
    - **Keys at rest (K3):** `find ~/.tegel-signing ~/.tegel-secrets -type f \( -name '*.key' -o -name '*.p8' -o -name '*.p12' \) 2>/dev/null` prints nothing (watched listing two files in Task 3 step 5).
    - **Debug override compiled out of Release:** plan 02's marker check (CR-P2-18: a key of at least 16 bytes, ≥ `1` on a Debug build, `0` on the b2 app).
    - **No secrets in history:** `git log -p $BASE..HEAD | grep -cE 'polar_oat_|BEGIN (EC |OPENSSH )?PRIVATE KEY|AuthKey_[A-Z0-9]+\.p8'` → `0`.
  - **Stage 5 prompt:** "Find a way a paying user loses Pro, a non-payer or another app's key gains Pro, an unsigned or unnotarised update installs, or a secret reaches the repo or a log."
  - **Design review shots** (against `DESIGN.md` and plan 09's Settings spec):
    - the Licence tab (free, Pro, and the `.wrongProduct` error) and the Updates tab, on a Debug build on the build Mac, each in light, dark (System Settings ▸ Appearance) and Arabic (`-AppleLanguages '(ar)'`): `screencapture -x -w docs/reviews/m03-design/<licence-free|licence-pro|licence-error|updates>-<light|dark|ar>.png`;
    - Sparkle's update prompt: copy Task 13 step 7's `/Users/Shared/m03/sparkle-prompt-*.png` into `docs/reviews/m03-design/`.
  - **Stage 7 extra:** if `release.sh`, the entitlements, Info.plist or TegelStore changed, build `1.0.0-b3 --sandbox --no-upload`, add it to `dist-release/markdown/beta-feed/`, re-run Task 13 step 6's `generate_appcast`, and repeat Task 13 steps 3–4, 7 and 11. It stays local, so no ask.
  - **Stage 9 output:** `cubic review -b "$BASE" -j > dist-release/cubic-<n>.json`.
  - **Before the merge:** Commit: `docs/reviews/m03.md docs/reviews/m03-design/`, "docs(reviews): m03 pipeline results".
  - **Merge message:** `merge: m03 licensing, updates, release`. Expected: `make check` matches the stage 2 counts, and the push succeeds.

### Task 15: Sandbox beta close-out (Fri 27 Nov, after the L2 leg)

**Files:** Modify `docs/gates/m03-acceptance.md` (on `main`).

- [ ] **Step 1: Ask the user** (K7): "Close the sandbox betas: revoke every Polar sandbox licence key and archive the sandbox products `Tegel Markdown` and `Tegel Test Other (not for sale)`?"
- [ ] **Step 2: Run the check while the key is still live**, so the later failure means something:
  ```bash
  . scripts/lib/env.sh
  for k in POLAR_SANDBOX_TEST_LICENSE_KEY POLAR_SANDBOX_OTHER_LICENSE_KEY; do
    curl -s -o /dev/null -w "$k %{http_code}\n" -X POST https://sandbox-api.polar.sh/v1/customer-portal/license-keys/validate -H 'Content-Type: application/json' \
      -d "{\"key\":\"$(envget $k)\",\"organization_id\":\"$(envget POLAR_SANDBOX_ORGANIZATION_ID)\"}"
  done
  ```
  Expected: `… 200` twice.
- [ ] **Step 3: After a yes** (Playwright, sandbox dashboard): revoke every licence key on the two products (the two Task 1 keys, the Task 13 step 8 key, any other test purchase), then archive both products.
- [ ] **Step 4: Verify.** Re-run step 2. Expected: neither line is `200` (the validate schema only ever returns `status: granted`, so a revoked key gets an error; record the code). Open `POLAR_SANDBOX_CHECKOUT_URL_MARKDOWN` in Playwright: no payable checkout (record what it shows). The betas existed only on this Mac and the L2 lease, and an installed one now lapses after its grace (K5).
- [ ] **Step 5: Clean up.** `pkill -f 'http.server 8765'; rm -rf dist-release/markdown/beta-feed`. From now on a Debug build's "Buy Pro…" opens an archived product; a later plan that needs a sandbox purchase makes its own product (plans 06 and 08 already do).
- [ ] **Step 6: Record.** Add the close-out rows to `docs/gates/m03-acceptance.md`. Commit on `main`: `docs/gates/m03-acceptance.md`, "docs(gates): m03 sandbox beta close-out"; then `git push origin main`.

---

## Hand-offs to plan 05

1. **arm64 / macOS 27 leg** on Scaleway M1 lease L2 (Thu 26 Nov 09:00 → Fri 27 Nov 09:00), second after plan 05's macOS 27 matrix, using b2.
   - **The feed holds b1 and b2 only.** Plan 05 keeps its RC entries in its own `dist-release/markdown/rc-feed/` (plan 05 Task 3 Step 4), so `beta-feed/` is still Task 13 step 6's feed. Check before copying: `grep -c '<item>' dist-release/markdown/beta-feed/appcast.xml` → `2`. With an rc entry, b1 would be offered the RC (production Polar) instead of b2, and steps 7 and 10–12 would fail.
   - On the lease, stop plan 05's feed server first (`pkill -f 'http.server 8765'`). Copy `beta-feed/` over (`scp -r`), serve it exactly as in Task 13 step 1, then repeat Task 13 steps 3–4, 7 and 10–12. Step 3 replaces plan 05's rc1 install with b1; step 7.5 must show `1.0.0-b2` before step 10.
   - **Licence key (steps 10–12):** b2 is a `--sandbox` build, so it talks to sandbox Polar. Use `POLAR_SANDBOX_TEST_LICENSE_KEY` (both its slots are free after Task 13 step 13), put on the clipboard with Task 9 step 3 item 1's command and pasted over Screen Sharing; never `POLAR_QA_LICENSE_KEY`, which is production.
   - Record the rows in `docs/gates/m03-acceptance.md` labelled "Scaleway M1, macOS 27". Task 15 runs after this leg.
2. **Nothing beta is on R2.** The first objects under `markdown/` are 1.0.0's, published with `scripts/release.sh markdown 1.0.0 --from-dmg <the smoke-tested DMG>`; compare the printed `sha256` with the smoked file's. That run is also the first real use of `release.sh`'s appcast and upload half.
3. **RC Sparkle acceptance:** RC builds use a local signed feed and the `-SUFeedURL` override as in Task 13 steps 6–7, but in their own folder, `dist-release/markdown/rc-feed/` (a copy of `beta-feed/` plus the RC), so `beta-feed/` stays b1/b2 for the L2 leg. No RC goes on the public feed (K7).
4. **Replace `REPLACE_IN_PLAN_05` in `Config/Release.xcconfig`** in all four settings: `TG_POLAR_ORGANIZATION_ID`, `TG_POLAR_CHECKOUT_URL_MARKDOWN`, `TG_POLAR_PORTAL_URL` and `TG_POLAR_BENEFIT_ID_MARKDOWN` (the live Markdown licence benefit). Create the live product with the same benefit settings (limit 2, `enable_customer_admin`) at $14 (D15). Check with a Release build (`xcodebuild -scheme markdown -configuration Release -derivedDataPath build`), not `make build` (Debug).
5. **Live BNPL row** in `docs/gates/bnpl.md` [F3g].
6. **FAQ input:** whether the key arrives by email (Task 13 step 9), and the error copy from Task 9.

## Deferred

- **S16, machine binding: DEFERRED (m00 consolidation).** v1 sends no machine `conditions` on activate or validate. Client licensing is patchable anyway, and binding would hurt Migration Assistant moves.

## Contract change requests

CR 1–6 accepted and applied to master §3.1, §3.3, §10 (P3) and D16 (27 Oct); history in `docs/reviews/m00-consolidated.md`.
