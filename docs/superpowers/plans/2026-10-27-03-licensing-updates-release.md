# Licensing, Updates and Release (Milestone 03) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Polar sandbox purchase activates, validates and deactivates Tegel Markdown Pro end to end. Sparkle updates 1.0.0-b1 → 1.0.0-b2 from R2. `scripts/release.sh` gives a notarised, stapled DMG that passes Gatekeeper on a clean Mac.

**Architecture:** TegelStore (second library in `Packages/TegelKit`) holds a pure grace policy, a URLSession Polar client, a Security.framework Keychain store and an `@Observable` `LicenseManager` that feeds the app's existing `isPro` seam. Polar values reach Info.plist through xcconfig (D16), and Sparkle 2.10.1 comes in over SPM. One bash release script runs native tools (xcodebuild, notarytool, stapler, hdiutil, codesign, spctl), then `generate_appcast`, then a `wrangler r2 object put --remote` upload.

**Tech Stack:** Swift 6 / SwiftPM tools 6.0, Swift Testing, Security.framework, URLSession, SwiftUI, XcodeGen 2.46, Sparkle 2.10.1, Polar customer-portal licence API, Cloudflare R2 + wrangler 4.151.2 via `bunx`, bash.

**Spec:** `BUSINESS-PLAN.md` (§5 rules 3 and 5, §6.4, §7.3, §7.4, §13 risk 7); `docs/superpowers/plans/2026-10-27-00-master-roadmap.md` (Global constraints, Review focus 5, D5, D12, D14–D16, §3.3, §5 H2/H4/H5, §6); facts `docs/research/2026-10-27-technical-facts.md` [F#]; rules `CLAUDE.md`.

**When / where:** **W4, Tue 17 – Mon 23 Nov 2026**, on branch `m03-commerce-release` (created in Task 4). Earlier: Task 1 (W1; it owns the Polar sandbox, master H5), Task 2 (W3) and the user half of Task 3 (H2).
**Assumed done:** plans 01–02, merged into `main`. They provide `project.yml` (App 1 + Quick Look extension), the `TegelKit` library, the `isPro` seam with a Debug override in `Apps/Markdown/App/ProGate.swift`, `Config/{Debug,Release}.xcconfig` and `ci.yml`. Plan 04 provides the Cloudflare account and the `tegelapps.com` zone.

## Global Constraints

- macOS deployment target **14.0**. Universal binary (arm64 + x86_64). Swift 6 language mode; swift-tools 6.0.
- Build Mac: Intel iMac19,1, macOS 15.7, Xcode 26.3, Swift 6.2.4. **arm64 or macOS 26/27 evidence comes only from the Scaleway M1 or GitHub runners, and is labelled with the machine.**
- **No telemetry, no accounts.** Network use is limited to the Polar licence calls and the Sparkle appcast/DMG. `SUEnableSystemProfiling` stays off (default `NO`).
- **Licence:** validate at launch; **30-day grace** from the last successful validation; **2 activations** [F3e]. **A 404 never locks on the spot** [F3d]. The app sends no API token.
- **Price:** App 1 **$19 once, 2 Macs**. The sandbox product uses $19. The live $14 intro price is plan 05 (D15). Licence limits are stated before purchase; 14-day refund (§5 rule 5).
- **No riba:** BNPL disabled in the checkout (§5 rule 3). Polar can't toggle methods [F3g], so it is inspected and recorded.
- **D5 entitlements:** `app-sandbox`, `files.user-selected.read-write`, `files.bookmarks.app-scope`, `network.client`, plus Sparkle's mach-lookup exception [F4]. The Quick Look extension gets no Sparkle and no TegelStore.
- **D16:** `Debug.xcconfig` → sandbox; `Release.xcconfig` → production (placeholder until plan 05). The Info.plist keys are exactly `TGPolarAPIBase`, `TGPolarOrganizationID`, `TGPolarCheckoutURL`, `TGPolarPortalURL`, `TGPolarBenefitID`.
- **Benefit binding (D1, ships in 1.0.0):** a key unlocks only the app whose Polar benefit issued it. `validate` sends `benefit_id`; `activate` checks `license_key.benefit_id`, and on a mismatch releases the activation and throws `PolarError.wrongProduct`. One benefit id per app.
- **D12:** DMG via `hdiutil`. DMG and appcast on R2 bucket `tegel-downloads` behind `https://downloads.tegelapps.com`.
- **Sparkle 2.10.1 exactly** [F4]. `SUFeedURL` = `https://downloads.tegelapps.com/markdown/appcast.xml`.
- **Secrets:** `.env` by key **name**; values are never printed, logged or committed. The Keychain holds the `tegel-notary` profile and the Sparkle EdDSA private key. Backups and the `.p8` live **outside** the repo.
- **Ask the user first (H11):** enabling R2 (it may need a card), publishing any DMG/appcast to R2, DNS on live `tegelapps.com`, anything in **production** Polar (untouched until plan 05). Polar sandbox and local builds need no confirmation.
- **MoR-agnostic (§13 risk 7):** only `PolarClient.swift` knows Polar. A Lemon Squeezy fallback rewrites that one file.
- **D14:** merge into `main` after the pipeline passes, then push (authorised).

## Review Focus

Master Review focus 5 belongs to this plan. Most likely first:

1. **Offline at launch, or Polar 5xx** → Pro stays on within 30 days of the last 200, no launch error. Pinned by `refreshOfflineWithinGraceStaysPro`, `refresh5xxWithinGraceStaysPro`, `initAppliesPolicyToStoredLicence` (Task 7); Task 13 step 11.
2. **Polar 404** (retired API version, revoked key, activation removed in the portal) → exactly like offline: grace, key kept, a later 200 restores Pro. Pinned by `refresh404WithinGraceNeverLocks`, `refresh404AfterGraceIsLapsedAndKeepsKey`, `refreshAfterLapseWith200RestoresPro` (Task 7); Task 13 step 14.
3. **Clock moved backwards** (`now < lastValidatedAt`) → Pro, and `lastValidatedAt` is not moved. Pinned by `clockMovedBackwardsStaysProWithoutExtendingLastValidatedAt` (Task 4), `refreshWithClockBackwardsKeepsLastValidatedAt` (Task 7).
4. **Activation limit reached, or an unknown key** → specific copy, state stays free, nothing stored. Pinned by `activateMapsErrors` (Task 5), `activateLimitReachedThrowsAndStaysFree` (Task 7); Task 13 step 13.
5. **Key pasted with spaces or newlines**, including a line break inside the key from a wrapped email → normalised before it is sent or stored. Pinned by `normalisedKeyStripsAllWhitespace`, `activateSendsNormalisedKeyAndComputerNameThenStores` (Task 7).

Also pinned: any 200 from validate is success even if the body drifts, since we send no `Polar-Version` (`validateAny200IsSuccessWithNilExpiry`). A deactivate racing a refresh can't resurrect a licence (`refreshDoesNotResurrectLicenceDeletedMidFlight`). A key for another Tegel app is rejected, its activation released and nothing stored (`activateWrongBenefitDeactivatesAndThrows`, `activateWrongProductThrowsAndStaysFree`; Task 13 step 13). The release guards (dirty tree, missing key, placeholder values, bad args) are covered by `scripts/release_test.sh`.

## H2 dependency (Developer ID)

Everything runs before H2 lands except these, which stay **BLOCKED until Task 3 is done**:
- Task 11 step 5 (signed archive check);
- Task 12 step 6 (first real `release.sh` run);
- all of Task 13 (the b1/b2 releases, Gatekeeper, the Sparkle update, and the purchase on a notarised build).

The licence flow is still exercised before H2 on a Debug build against the sandbox (Task 9). If H2 isn't done by Mon 16 Nov, the launch slips week for week (master P5).

## Conventions used in every task

Run from the repo root `R=~/Development/mac-utility-studio`. Define these in the shell first:

```bash
R=~/Development/mac-utility-studio
envget() { sed -n "s/^$1=//p" "$R/.env" | head -1; }                       # read; never echo the result
envset() { { grep -v "^$1=" "$R/.env"; printf '%s=%s\n' "$1" "$2"; } > "$R/.env.tmp" && mv "$R/.env.tmp" "$R/.env" && chmod 600 "$R/.env"; }
envhas() { grep -qE "^$1=.+" "$R/.env" && echo "$1 saved" || echo "$1 MISSING"; }
build()  { xcodegen generate >/dev/null && xcodebuild build -scheme markdown -configuration "$1" -destination 'platform=macOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO -quiet "${@:2}"; }
plist()  { /usr/libexec/PlistBuddy -c "Print :$2" "$(echo build/Build/Products/$1/*.app)/Contents/Info.plist"; }
ST="swift test --package-path Packages/TegelKit"
```

Commits end with the trailer as a second `-m`:
```bash
git commit -m "<type>(<scope>): <summary>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

**GUI steps** are marked *(GUI)*. The user does them, or Claude does them through the computer-use skill. Playwright is used for web dashboards only.

---

### Task 1: Polar sandbox org, product, licence benefit, checkout link (W1, done by Mon 2 Nov)

Needs H3 (studio inbox) and H5 (sandbox org). Sandbox only, so no confirmation is needed.

**Files:**
- None in the repo. Writes `.env` keys and a gitignored screenshot `local-docs/m03/bnpl-sandbox.png`.

**Interfaces:**
- Consumes: `.env` `STUDIO_EMAIL` (H3).
- Produces these `.env` names, used by Tasks 8, 9 and 13: `POLAR_EMAIL`, `POLAR_SANDBOX_ORGANIZATION_ID`, `POLAR_SANDBOX_BENEFIT_ID_MARKDOWN`, `POLAR_SANDBOX_PRODUCT_ID_MARKDOWN`, `POLAR_SANDBOX_CHECKOUT_URL_MARKDOWN`, `POLAR_SANDBOX_PORTAL_URL`, `POLAR_SANDBOX_TEST_LICENSE_KEY`, and `POLAR_SANDBOX_OTHER_LICENSE_KEY` (step 10, used by Task 13).

- [ ] **Step 1: Sign up.** Playwright `browser_navigate` to `https://sandbox.polar.sh/start` and sign up with the H3 inbox (`envget STUDIO_EMAIL`); the **user** enters the emailed code. Then `envset POLAR_EMAIL "$(envget STUDIO_EMAIL)"`. Result: `envhas POLAR_EMAIL` → `POLAR_EMAIL saved`.
- [ ] **Step 2: Create the org.** Name `Tegel`, slug `tegelapps` (or the nearest free slug). Copy the organization ID from org settings and `envset POLAR_SANDBOX_ORGANIZATION_ID <id>`. Check that the saved id is well formed (step 9 proves it is the right org):
  ```bash
  curl -s -o /dev/null -w '%{http_code}\n' -X POST https://sandbox-api.polar.sh/v1/customer-portal/license-keys/validate \
    -H 'Content-Type: application/json' -d "{\"key\":\"NOPE\",\"organization_id\":\"$(envget POLAR_SANDBOX_ORGANIZATION_ID)\"}"
  ```
  Expected: `404` (key not found). `422` means the id was saved wrong.
- [ ] **Step 3: Create the benefit.** Benefits → New → type **License Keys**: description `Tegel Markdown licence`, no expiry, no usage limit, **activation limit 2**, **customer can deactivate activations ON** (`enable_customer_admin`) [F3e]. Then `envset POLAR_SANDBOX_BENEFIT_ID_MARKDOWN <id>`.
- [ ] **Step 4: Create the product.** Products → New → `Tegel Markdown`, **one-time, $19 USD**, with the benefit from step 3 attached.
  - Description (states the limits before purchase, rule 5): `One-time purchase. One licence activates Tegel Markdown Pro on up to 2 Macs. 14-day refund.`
  - Then `envset POLAR_SANDBOX_PRODUCT_ID_MARKDOWN <id>`.
- [ ] **Step 5: Create a checkout link** for the product, then `envset POLAR_SANDBOX_CHECKOUT_URL_MARKDOWN <url>`. Check: `curl -s -o /dev/null -w '%{http_code}\n' -L "$(envget POLAR_SANDBOX_CHECKOUT_URL_MARKDOWN)"` → `200`.
- [ ] **Step 6: Find the portal URL.** Polar documents `https://polar.sh/<slug>/portal` for production but no sandbox URL (polar.sh/docs/features/customer-portal/navigate-customers.md).
  - Test: `curl -s -o /dev/null -w '%{http_code}\n' https://sandbox.polar.sh/tegelapps/portal` → `200`, and Playwright shows an email sign-in form.
  - If it isn't 200, take the portal link from the dashboard's customer-portal settings instead.
  - Then `envset POLAR_SANDBOX_PORTAL_URL <url>`.
- [ ] **Step 7: Test purchase, with a BNPL look.**
  - Open the checkout link in Playwright.
  - Email = `envget POLAR_EMAIL`. Sandbox emails reach org members only (polar.sh/docs/integrate/sandbox.md).
  - **Before paying**, set the billing country to **Netherlands**, then to **United States**, and list every payment method offered. Save `browser_take_screenshot` to `local-docs/m03/bnpl-sandbox.png`.
  - If any pay-later method appears (Klarna, Afterpay, Affirm, Riverty, "pay in 3"), **stop and tell the user** (product rule 7).
  - Pay with `4242 4242 4242 4242`, any future expiry, any CVC.
  - Result: the order shows in Sales.
- [ ] **Step 8: Get the key.**
  - Note whether the order email to `POLAR_EMAIL` contains the key; the docs only promise it in the portal (polar.sh/docs/features/benefits/license-keys.md).
  - Copy the key from the portal and `envset POLAR_SANDBOX_TEST_LICENSE_KEY <key>`. Never echo it.
- [ ] **Step 9: Check that the 2-Mac limit is enforced server-side** [F3a, F3c, F3e]. The response bodies contain the key, so they go to a temp file that is deleted:
  ```bash
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
  - Copy the key from the portal and `envset POLAR_SANDBOX_OTHER_LICENSE_KEY <key>`. Never echo it. Result: `envhas POLAR_SANDBOX_OTHER_LICENSE_KEY` → `POLAR_SANDBOX_OTHER_LICENSE_KEY saved`.

No commit: the outputs are gitignored. Task 4 adds the new key names to `.env.example`.

### Task 2: R2 bucket, `downloads.tegelapps.com`, scoped token (W3, by Mon 16 Nov)

Needs plan 04's Cloudflare account and the `tegelapps.com` zone, plus H4's card. **Enabling R2 may need a card, and the custom domain adds DNS on a live domain, so each gets its own ask first.**

**Files:**
- None in the repo; writes `.env` keys.

**Interfaces:**
- Produces these `.env` names, used by Task 12: `R2_BUCKET`, `R2_PUBLIC_BASE_URL`, `CLOUDFLARE_ACCOUNT_ID` (if plan 04 hasn't set it), `CLOUDFLARE_R2_API_TOKEN`.

- [ ] **Step 1: Enable R2** in the dashboard (Playwright).
  - Ask the user first: "Enable R2 on the Cloudflare account? It may ask for a card; our use stays inside the free tier."
  - After a yes, enable it. If it asks for a payment method and none is on file, that's H4 (user) [F8: unverified whether the free tier needs a card]. Result: the R2 Overview loads.
- [ ] **Step 2: Create the bucket** `tegel-downloads`: automatic location, Standard class, r2.dev public URL **left disabled**. Then `envset R2_BUCKET tegel-downloads`.
- [ ] **Step 3: Connect the domain.**
  - Ask the user first: "Connect `downloads.tegelapps.com` to bucket `tegel-downloads` (adds a DNS record on tegelapps.com)?"
  - Then: bucket → Settings → Custom Domains → Connect → `downloads.tegelapps.com`, **minimum TLS 1.2** (the default is 1.0, per developers.cloudflare.com/workers/wrangler/commands/r2/).
  - `envset R2_PUBLIC_BASE_URL https://downloads.tegelapps.com`.
  - Check: `dig +short downloads.tegelapps.com | head -1` prints an address, and the dashboard shows the domain as Active.
- [ ] **Step 4: Create the token.** R2 → Manage API tokens → Create:
  - permission **Object Read & Write**, applied to **`tegel-downloads` only**;
  - `envset CLOUDFLARE_R2_API_TOKEN <token>`; then `envhas CLOUDFLARE_ACCOUNT_ID`, and if MISSING, `envset` it from the dashboard.
- [ ] **Step 5: Verify the token and the `--remote` flag.** Wrangler v4 runs "in local mode by default" (developers.cloudflare.com/workers/wrangler/migration/update-v3-to-v4/). Run this in a temp dir so the local state doesn't land in the repo:
  ```bash
  cd "$(mktemp -d)" && printf ok > probe.txt
  w() { CLOUDFLARE_API_TOKEN="$(envget CLOUDFLARE_R2_API_TOKEN)" CLOUDFLARE_ACCOUNT_ID="$(envget CLOUDFLARE_ACCOUNT_ID)" bunx wrangler@4.151.2 r2 object "$@"; }
  w put tegel-downloads/probe-local.txt --file probe.txt
  w put tegel-downloads/probe-remote.txt --file probe.txt --content-type text/plain --remote
  for k in probe-local probe-remote; do curl -s -o /dev/null -w "$k %{http_code}\n" "https://downloads.tegelapps.com/$k.txt"; done
  curl -s -o /dev/null -w 'tls1.1 %{http_code}\n' --tls-max 1.1 https://downloads.tegelapps.com/probe-remote.txt
  w delete tegel-downloads/probe-remote.txt --remote
  ```
  Expected: `probe-local 404`, `probe-remote 200`, `tls1.1 000`.
  - If the remote `put` fails with an auth error, the bucket-scoped token doesn't work with wrangler. Replace it with an account API token limited to **Workers R2 Storage: Edit**, re-run, and note which token type is in use in Task 13's acceptance doc.

No commit; Task 4 adds `CLOUDFLARE_R2_API_TOKEN`, `R2_BUCKET` and `R2_PUBLIC_BASE_URL` to `.env.example`.

### Task 3: Developer ID certificate and notarytool profile (H2)

**Schedule:** the user enrols by **Fri 6 Nov**; certificate and API key by **Mon 16 Nov**; Claude's steps on Tue 17 Nov.

**Files:** none in the repo; writes `.env` keys and the Keychain.

**Interfaces:**
- Produces these `.env` names, used by Tasks 11–13: `APPLE_DEVELOPER_ID_IDENTITY`, `APPLE_TEAM_ID`, `ASC_API_KEY_ID`, `ASC_API_ISSUER_ID` (Team keys only), `ASC_API_KEY_PATH`, `NOTARY_KEYCHAIN_PROFILE`.
- Keychain profile: `tegel-notary`.

- [ ] **Step 1: the certificate, check first, then create.** H2 may already be done when this plan runs.
  - Check: `security find-identity -v -p codesigning | grep -c '"Developer ID Application:'`. `1` → done; go to step 2.
  - `0` → the **user** (Account Holder) uploads the existing CSR `~/.tegel-signing/devid-application.csr` at developer.apple.com → Certificates, IDs & Profiles → Certificates → **+** → **Developer ID Application**, profile type **G2 Sub-CA**, and downloads the `.cer`. Don't use Xcode ▸ Manage Certificates: it makes a new key and orphans the one in `~/.tegel-signing/`.
  - Claude moves the `.cer` into `~/.tegel-signing/` and imports the key and the certificate into the login Keychain:
    ```bash
    security import ~/.tegel-signing/devid-application.key -k ~/Library/Keychains/login.keychain-db -t priv -f openssl -T /usr/bin/codesign
    security import ~/.tegel-signing/*.cer -k ~/Library/Keychains/login.keychain-db
    ```
  - Check again → `1`.
- [ ] **Step 2: Save the identity and team id without printing them.**
  ```bash
  ID=$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application: [^"]*\)"/\1/p' | head -1)
  envset APPLE_DEVELOPER_ID_IDENTITY "$ID"; T=${ID##*(}; envset APPLE_TEAM_ID "${T%)}"; unset ID T
  envhas APPLE_DEVELOPER_ID_IDENTITY; envhas APPLE_TEAM_ID
  ```
  Expected: two `… saved` lines.
- [ ] **Step 3 (user + Claude): the App Store Connect API key.**
  - User: App Store Connect → Users and Access → Integrations → **Team Keys** (role Developer), or an Individual key. Download the `.p8` once.
  - Claude: `mkdir -p ~/.tegel-secrets && chmod 700 ~/.tegel-secrets`, move the file to `~/.tegel-secrets/AuthKey_<KEYID>.p8`, `chmod 600` it, and `envset ASC_API_KEY_PATH`, `ASC_API_KEY_ID`, and `ASC_API_ISSUER_ID` (**Team keys only**).
  - Check: `stat -f %Lp "$(envget ASC_API_KEY_PATH)"` → `600`.
- [ ] **Step 4: Store the notary credentials.** `--issuer` is "Required for Team API Keys. Do not provide for Individual API Keys" (`xcrun notarytool store-credentials --help` on Xcode 26.3).
  ```bash
  ISS=$(envget ASC_API_ISSUER_ID)
  xcrun notarytool store-credentials tegel-notary --key "$(envget ASC_API_KEY_PATH)" --key-id "$(envget ASC_API_KEY_ID)" ${ISS:+--issuer "$ISS"}
  envset NOTARY_KEYCHAIN_PROFILE tegel-notary
  xcrun notarytool history --keychain-profile tegel-notary >/dev/null && echo notary-ok
  ```
  Expected: the credentials validate and are saved to the Keychain, then `notary-ok`.
  - **Fallback:** if the account can't create API keys, run `xcrun notarytool store-credentials tegel-notary --apple-id <id> --team-id "$(envget APPLE_TEAM_ID)"`; the user types an app-specific password at the secure prompt.

No commit.

### Task 4: Branch, TegelStore target, value types, LicensePolicy (Tue 17 Nov)

**Files:**
- Modify: `.env.example` (new names only)
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
  ```
- Test support: `let t0 = Date(timeIntervalSince1970: 1_800_000_000)` and `let lic = StoredLicense(key: "K-1", activationID: "act_1", lastValidatedAt: t0)`. Tests use the internal memberwise inits via `@testable import TegelStore`.

- [ ] **Step 1: Branch and env names.**
  - Run `git checkout main && git pull --ff-only origin main && git checkout -b m03-commerce-release`.
  - Add these names, without values, to `.env.example`:
    - under `# --- Polar`: `POLAR_SANDBOX_PRODUCT_ID_MARKDOWN`, `POLAR_SANDBOX_BENEFIT_ID_MARKDOWN`, `POLAR_SANDBOX_PORTAL_URL`, `POLAR_SANDBOX_TEST_LICENSE_KEY`, `POLAR_SANDBOX_OTHER_LICENSE_KEY`;
    - under `# --- Cloudflare`: `CLOUDFLARE_R2_API_TOKEN`, `R2_BUCKET`, `R2_PUBLIC_BASE_URL`.
  - Check: `grep -cE '^(POLAR_SANDBOX_(PRODUCT_ID|BENEFIT_ID)_MARKDOWN|POLAR_SANDBOX_PORTAL_URL|POLAR_SANDBOX_(TEST|OTHER)_LICENSE_KEY|CLOUDFLARE_R2_API_TOKEN|R2_BUCKET|R2_PUBLIC_BASE_URL)$' .env.example` → `8`.
  - Commit: `git add .env.example && git commit -m "chore(env): name the m03 Polar sandbox and R2 keys" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`.
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
      @Test func clockMovedBackwardsStaysProWithoutExtendingLastValidatedAt() {
          let state = LicensePolicy.state(stored: lic, now: t0 - 400 * 86_400)
          #expect(state == .pro(lic))
          guard case .pro(let kept) = state else { return }
          #expect(kept.lastValidatedAt == t0)
      }
  }
  ```
- [ ] **Step 3: Run it to verify it fails.** `$ST --filter LicensePolicyTests`. Expected: FAIL, `error: no such module 'TegelStore'`.
- [ ] **Step 4: Implement.**
  - `Package.swift`: add `.library(name: "TegelStore", targets: ["TegelStore"])`, `.target(name: "TegelStore")` and `.testTarget(name: "TegelStoreTests", dependencies: ["TegelStore"])`.
  - `License.swift`: the four types above.
  - `state`:
    - `nil` → `.free`;
    - `now.timeIntervalSince(last) <= grace` → `.pro(stored)` (a negative interval, i.e. the clock moved back, also lands here, unchanged);
    - otherwise `.lapsed(stored)`.
  - `fromInfoPlist` reads the five `TG*` strings with `bundle.object(forInfoDictionaryKey:)`. It calls `preconditionFailure("Info.plist: <key> missing or not a URL")` on absence, and also on an empty `TGPolarBenefitID`: a build-config bug must fail loudly (Task 8 and `release.sh` check the values).
- [ ] **Step 5: Run it to verify it passes.** `$ST --filter LicensePolicyTests`. Expected: `✔ Test run with 6 tests … passed`.
- [ ] **Step 6: Commit.**
  ```bash
  git add Packages/TegelKit/Package.swift Packages/TegelKit/Sources/TegelStore/License.swift Packages/TegelKit/Tests/TegelStoreTests
  git commit -m "feat(store): add TegelStore with LicensePolicy and 30-day grace" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  ```

### Task 5: PolarClient (Tue 17 Nov)

**`Polar-Version` decision: omit the header.**
- "If the header is omitted, Polar uses Current", and "a malformed, unknown, or removed version returns `404 Not Found`" (polar.sh/docs/api-reference/2026-10/versioning.md).
- **Pinning** guarantees that every install that never updates gets 404 about 9 months after release. With the 30-day grace, that install then loses Pro: a broken perpetual licence.
- **Omitting** fails only if Polar changes these endpoints' fields in a new Current version. The client limits that exposure:
  - it reads only `id`, `license_key.benefit_id` (activate) and `expires_at`;
  - it treats any 200 on validate as success;
  - every failure path goes through grace.
- Each quarter, while the new version sits in "Next" for 3 months, run Task 1 step 9 with `-H 'Polar-Version: <Next>'` (see Contract change requests).

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
          let (client, host) = stubbedClient(respond(200, #"{"status":"granted","expires_at":"\#(expiresAt)"}"#))
          #expect(try await client.validate(key: "K-1", activationID: "act_1") == Date(timeIntervalSince1970: 1_798_761_600))
          let (req, body) = try #require(StubURLProtocol.requests(host: host).first)
          #expect(req.url?.path == "/v1/customer-portal/license-keys/validate")
          #expect(body == ["key": "K-1", "organization_id": "org-1", "activation_id": "act_1", "benefit_id": "ben-1"])
      }
      @Test(arguments: [#"{"expires_at":null}"#, #"{"status":"granted"}"#, "not json"])
      func validateAny200IsSuccessWithNilExpiry(body: String) async throws {
          let (client, _) = stubbedClient(respond(200, body))
          #expect(try await client.validate(key: "K-1", activationID: "act_1") == nil)
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
- [ ] **Step 2: Run it to verify it fails.** `$ST --filter PolarClientTests`. Expected: FAIL, `error: cannot find 'PolarClient' in scope`.
- [ ] **Step 3: Implement `PolarClient` and `PolarError`** in `PolarClient.swift`. The three calls share one private `post(_ path: String, _ body: [String: String]) async throws -> (Int, Data)`:
  - `POST apiBase/v1/customer-portal/license-keys/<activate|validate|deactivate>` with a JSON body, `Content-Type: application/json`, and `organization_id` from the config. Body fields exactly per [F3a–c].
  - A URLSession throw or a non-HTTP response → `.network`. `403` → `.limitReached`. `404` → `.notFound`. Any other non-2xx → `.http(code)`.
  - `activate` decodes `{id, license_key: {benefit_id}}`. A 200 without `id` → `.http(200)`. With an `id` but no `license_key.benefit_id` → `try? await deactivate(key:activationID:)` (best effort, so API drift never eats a device slot), then `.http(200)` (fails closed; the quarterly `Polar-Version` check above catches the drift). A `benefit_id` ≠ `config.benefitID` → the same best-effort deactivate, then throw `.wrongProduct`.
  - `validate` adds `"benefit_id": config.benefitID` to its body; Polar answers 404 on a mismatch (plan 06 DF6), which goes through grace like any 404.
  - `validate` treats **any 200 as success**. It parses `expires_at` with `ISO8601DateFormatter` using `[.withInternetDateTime, .withFractionalSeconds]`, then falls back to the plain options (Polar returns microseconds; checked on the build Mac). An unparseable or absent value → `nil`.
- [ ] **Step 4: Run it to verify it passes.** `$ST --filter PolarClientTests`. Expected: `✔ Test run with 11 tests … passed`.
- [ ] **Step 5: Commit.**
  ```bash
  git add Packages/TegelKit/Sources/TegelStore/PolarClient.swift Packages/TegelKit/Tests/TegelStoreTests/TestSupport.swift Packages/TegelKit/Tests/TegelStoreTests/PolarClientTests.swift
  git commit -m "feat(store): add PolarClient for licence activate/validate/deactivate" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  ```

### Task 6: KeychainStore (Wed 18 Nov)

**Files:**
- Create: `Packages/TegelKit/Sources/TegelStore/KeychainStore.swift`
- Modify: `Packages/TegelKit/Tests/TegelStoreTests/TestSupport.swift` (add `func uniqueService() -> String`, returning `"com.tegelapps.tests.\(UUID().uuidString)"`)
- Test: `Packages/TegelKit/Tests/TegelStoreTests/KeychainStoreTests.swift`

**Interfaces:**
- Consumes: `StoredLicense`.
- Produces (§3.3 verbatim): `public struct KeychainStore: Sendable { public init(service: String); public func load() -> StoredLicense?; public func save(_ l: StoredLicense) throws; public func delete() throws }`.
- Errors are `NSError(domain: NSOSStatusErrorDomain, code: Int(status))`, so no new type.

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
- [ ] **Step 2: Run it to verify it fails.** `$ST --filter KeychainStoreTests`. Expected: FAIL, `error: cannot find 'KeychainStore' in scope`.
- [ ] **Step 3: Implement `KeychainStore`.**
  - Item: `kSecClassGenericPassword`, `kSecAttrService` = service, `kSecAttrAccount` = `"licence"`, value = the JSON-encoded `StoredLicense`.
  - Use the file-based login keychain: the data-protection keychain needs a provisioning profile.
  - `save` = `SecItemDelete`, then `SecItemAdd`.
  - `load` = `SecItemCopyMatching` + decode. Any failure → `nil`.
  - `delete` treats `errSecItemNotFound` as success.
- [ ] **Step 4: Run it to verify it passes, and check cleanup.**
  - `$ST --filter KeychainStoreTests`. Expected: `✔ Test run with 2 tests … passed`.
  - Then `security dump-keychain 2>/dev/null | grep -c 'com.tegelapps.tests'` → `0` (no leftovers; this prints attributes only, no secrets).
- [ ] **Step 5: Commit.**
  ```bash
  git add Packages/TegelKit/Sources/TegelStore/KeychainStore.swift Packages/TegelKit/Tests/TegelStoreTests/TestSupport.swift Packages/TegelKit/Tests/TegelStoreTests/KeychainStoreTests.swift
  git commit -m "feat(store): add KeychainStore for the stored licence" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  ```

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
- New, internal: `static func normalisedKey(_ raw: String) -> String`. It removes **all** whitespace and newlines, not just the ends: Polar keys contain none, so this also fixes a key wrapped across lines in an email.
- Test helper, in this test file: `@MainActor func makeManager(stored: StoredLicense?, _ handler: @escaping StubHandler = respond(200, #"{"id":"act_1","license_key":{"benefit_id":"ben-1"}}"#)) throws -> (LicenseManager, KeychainStore, String)`. It uses a `uniqueService()` store, pre-saves `stored`, and builds the client with `stubbedClient`.

- [ ] **Step 1: Write the failing test.** Each test also deletes its Keychain store at the end (`defer { try? store.delete() }`, omitted below).
  ```swift
  import Foundation
  import Testing
  @testable import TegelStore

  @MainActor @Suite struct LicenseManagerTests {
      @Test func initAppliesPolicyToStoredLicence() throws {
          let fresh = StoredLicense(key: "K-1", activationID: "act_1", lastValidatedAt: .now - 86_400)
          let (m, _, _) = try makeManager(stored: fresh)
          #expect(m.state == .pro(fresh)); #expect(m.isPro)
          let (m2, _, _) = try makeManager(stored: nil)
          #expect(m2.state == .free); #expect(!m2.isPro)
      }
      @Test func normalisedKeyStripsAllWhitespace() {
          #expect(LicenseManager.normalisedKey("  ABCD-1234 \n") == "ABCD-1234")
          #expect(LicenseManager.normalisedKey("ABCD-\r\n1234\t") == "ABCD-1234")
      }
      @Test func activateSendsNormalisedKeyAndComputerNameThenStores() async throws {
          let (m, store, host) = try makeManager(stored: nil, respond(200, #"{"id":"act_9","license_key":{"benefit_id":"ben-1"}}"#))
          try await m.activate(key: " K-1\n")
          let (_, body) = try #require(StubURLProtocol.requests(host: host).first)
          #expect(body["key"] == "K-1")
          #expect(body["label"] == (Host.current().localizedName ?? "Mac"))
          #expect(store.load()?.key == "K-1"); #expect(store.load()?.activationID == "act_9"); #expect(m.isPro)
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
          let (m, store, _) = try makeManager(stored: lic, respond(200))
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
          let (m, _, _) = try makeManager(stored: lic, respond(200))
          await m.refresh(now: t0 + 40 * 86_400)
          #expect(m.state == .pro(StoredLicense(key: "K-1", activationID: "act_1", lastValidatedAt: t0 + 40 * 86_400)))
      }
      @Test func refreshWithClockBackwardsKeepsLastValidatedAt() async throws {
          let (m, store, _) = try makeManager(stored: lic, offline)
          await m.refresh(now: t0 - 86_400)
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
      @Test func refreshDoesNotResurrectLicenceDeletedMidFlight() async throws {
          let service = uniqueService(), store = KeychainStore(service: service)
          try store.save(lic)
          let (client, _) = stubbedClient { _, _ in try? KeychainStore(service: service).delete(); return (200, Data("{}".utf8)) }
          let m = LicenseManager(client: client, keychain: store)
          await m.refresh(now: t0 + 86_400)
          #expect(store.load() == nil); #expect(m.state == .free)
      }
  }
  ```
- [ ] **Step 2: Run it to verify it fails.** `$ST --filter LicenseManagerTests`. Expected: FAIL, `error: cannot find 'LicenseManager' in scope`.
- [ ] **Step 3: Implement `LicenseManager`.**
  - **`init`:** `state = LicensePolicy.state(stored: keychain.load(), now: .now)`. This is synchronous, so Pro is on at launch before any network call.
  - **`activate`:**
    1. Normalise the key.
    2. Call `client.activate(key:label:)` with `label: Host.current().localizedName ?? "Mac"`.
    3. `keychain.save(StoredLicense(key:activationID:lastValidatedAt: .now))`, then `state = .pro`.
    - Errors propagate unchanged, and nothing is stored on error. That includes `.wrongProduct`, whose activation `PolarClient` has already released.
  - **`refresh(now:)`:**
    1. With no stored licence: `state = .free`, no request.
    2. Otherwise call `validate`.
    3. After the `await`, check that `keychain.load()?.activationID` still equals the activation it started with. If not, a deactivate/activate ran mid-flight: set `state` from the current Keychain and return.
    4. On 200: stamp `lastValidatedAt = now`, `try? save`, `state = .pro`.
    5. On **any** error (404, 5xx, network): `state = LicensePolicy.state(stored:now:)`, and **neither the Keychain nor the stamp is touched**.
    - `expires_at` is ignored: Polar 404s expired keys [F3b].
  - **`deactivate`:** call `client.deactivate`. Then `.notFound` and success both `keychain.delete()` and set `state = .free`. Every other error is rethrown, and the licence is kept.
- [ ] **Step 4: Run it to verify it passes.**
  - `$ST --filter LicenseManagerTests`. Expected: `✔ Test run with 16 tests … passed`.
  - Then `$ST --filter TegelStoreTests`. Expected: `35 tests … passed`.
- [ ] **Step 5: Commit.**
  ```bash
  git add Packages/TegelKit/Sources/TegelStore/LicenseManager.swift Packages/TegelKit/Tests/TegelStoreTests/LicenseManagerTests.swift
  git commit -m "feat(store): add LicenseManager with grace on every failure, 404 included" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  ```

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

- [ ] **Step 1: Write the failing check.**
  ```bash
  build Debug && plist Debug TGPolarAPIBase && [ "$(plist Debug TGPolarBenefitID)" = "$(envget POLAR_SANDBOX_BENEFIT_ID_MARKDOWN)" ] && echo benefit-ok
  build Release && plist Release TGPolarAPIBase && plist Release TGPolarOrganizationID && plist Release TGPolarBenefitID
  build Release -xcconfig Config/PolarSandbox.xcconfig && plist Release TGPolarAPIBase
  ```
- [ ] **Step 2: Run it to verify it fails.** Expected: FAIL, `Print: Entry, ":TGPolarAPIBase", Does Not Exist`.
- [ ] **Step 3: Implement.**
  - **`//` starts an xcconfig comment**, so write URLs as `https:/$()/host…`. Generate the sandbox file from `.env` without echoing values:
    ```bash
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
- [ ] **Step 4: Run it to verify it passes.** Same commands. Expected, in order:
  1. `https://sandbox-api.polar.sh`
  2. `benefit-ok`
  3. `https://api.polar.sh`
  4. `REPLACE_IN_PLAN_05`
  5. `REPLACE_IN_PLAN_05`
  6. `https://sandbox-api.polar.sh`
  - Then `make check` still passes with the plan 01/02 baseline counts.
- [ ] **Step 5: Commit.**
  ```bash
  git add Config/PolarSandbox.xcconfig Config/Debug.xcconfig Config/Release.xcconfig project.yml
  git commit -m "build: feed Polar sandbox/production values into Info.plist via xcconfig (D16)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  ```

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
  - `struct LicenceSettingsView: View`, reading `@Environment(LicenseManager.self)`;
  - the App injects `.environment(license)` and `.environment(\.isPro, license.isPro)` (OR'd with plan 02's `#if DEBUG` override, which stays Debug-only) on every scene.

- [ ] **Step 1: Write the failing check (GUI).** Run `build Debug` with signing on (drop `CODE_SIGNING_ALLOWED=NO`) and open the app. Expected FAIL: Settings has no **Licence** tab, and Pro features follow only the Debug override.
- [ ] **Step 2: Implement.**
  - **App init:**
    - `let m = LicenseManager(client: PolarClient(config: .fromInfoPlist()))`, `_license = State(initialValue: m)`;
    - `Task { while !Task.isCancelled { await m.refresh(); try? await Task.sleep(for: .seconds(86_400)) } }`. This refreshes at launch, then every 24 h while running.
  - **LicenceSettingsView**, a `Form` with exactly this EN copy:

  | State | Content |
  |---|---|
  | `.free` | Text "Pro adds folder mode with search and live reload, paginated PDF export and three themes. One-time purchase for up to 2 Macs, with a 14-day refund." · Button **"Buy Pro…"** → `openURL(config.checkoutURL)` · TextField "Licence key" + Button **"Activate"** (disabled while empty or busy) |
  | `.pro` | Text "Pro is active on this Mac." · Button **"Deactivate this Mac"** · Button **"Manage activations…"** → `openURL(config.portalURL)` |
  | `.lapsed` | Text "Tegel couldn't confirm your licence for more than 30 days. Connect to the internet, then click Check Again." · Button **"Check Again"** → `refresh()` · **"Manage activations…"** |
  | error `.limitReached` | "This key is already active on 2 Macs, or it is no longer valid. Free up a Mac in Manage activations, then try again." |
  | error `.notFound` | "That licence key wasn't found. Copy it again from your receipt or the customer portal." |
  | error `.network` | "Couldn't reach the licence server. Check your connection and try again." |
  | error `.http(n)` | "The licence server returned error \(n). Try again later." |
  | error `.wrongProduct` | "This key is for another Tegel app. Each app has its own key on your Polar purchases page." |

  - The activation label is the computer name; `LicenseManager` sends it (Task 7).
  - Add the tab `.tabItem { Label("Licence", systemImage: "key") }` to the Settings `TabView`.
- [ ] **Step 3: Run the smoke test (GUI), on the build Mac with a Debug build against the sandbox.**
  1. `envget POLAR_SANDBOX_TEST_LICENSE_KEY | sed 's/^/  /;s/$/\n/' | pbcopy`. This puts the key on the clipboard with leading spaces and a trailing newline, without printing it.
  2. Paste it, then click Activate. Expected: "Pro is active on this Mac", and folder mode is enabled.
  3. Sandbox dashboard → the order's licence key → activations. Expected: one activation whose label equals `scutil --get ComputerName`. This also confirms `Host.current()` works inside the sandbox.
  4. Disconnect the network, quit, relaunch. Expected: still Pro, no error. Reconnect.
  5. Deactivate this Mac. Expected: the free copy shows, and the dashboard shows 0 activations.
  6. Type the key `TEGEL-0000` and Activate. Expected: the `.notFound` copy.
  7. `make test-app ONLY=LocalizationTests`. Expected: `Executed 3 tests, with 0 failures` (every new string has NL/FR/AR). Then relaunch with `-AppleLanguages '(nl)'`, then `(fr)`, then `(ar)`. Expected: the Licence tab shows no English, and the AR layout is right-to-left.
- [ ] **Step 4: Run `make check`.** Expected: baseline + 35 TegelStore tests, all passing.
- [ ] **Step 5: Commit.**
  ```bash
  git add Apps/Markdown/App/LicenceSettingsView.swift Apps/Markdown/App/MarkdownApp.swift Apps/Markdown/App/Localizable.xcstrings <settings-tabview-file>
  git commit -m "feat(app): Licence settings tab; LicenseManager feeds isPro; 24 h refresh" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  ```

### Task 10: Sparkle 2.10.1 and EdDSA keys (Fri 20 Nov)

**Files:**
- Modify: `project.yml`:
  - `packages: Sparkle: {url: https://github.com/sparkle-project/Sparkle, exactVersion: 2.10.1}`, and the dependency `- package: Sparkle` on the `markdown` app target only;
  - `info.properties`: `SUFeedURL`, `SUPublicEDKey`, `SUEnableInstallerLauncherService: true`, `SUEnableAutomaticChecks: true`;
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
  - `.env` `SPARKLE_PUBLIC_ED_KEY` and `SPARKLE_PRIVATE_KEY_BACKUP_PATH`;
  - a Keychain item with account **`tegelapps`**;
  - `SPARKLE_BIN=build/SourcePackages/artifacts/sparkle/Sparkle/bin`.

- [ ] **Step 1: Write the failing check.**
  ```bash
  build Debug && for k in SUFeedURL SUEnableInstallerLauncherService SUEnableAutomaticChecks; do plist Debug $k; done
  xcodebuild build -scheme markdown -configuration Debug -derivedDataPath build -quiet && \
    codesign -d --entitlements - --xml "$(echo build/Build/Products/Debug/*.app)" 2>/dev/null | grep -oE 'com\.tegelapps\.markdown-sp[ik]s|network\.client' | sort
  ```
- [ ] **Step 2: Run it to verify it fails.** Expected: FAIL, `Entry, ":SUFeedURL", Does Not Exist`, and no `-spks`/`-spki` lines.
- [ ] **Step 3: Implement and generate the keys.**
  - Add the package and the `SUFeedURL`, flag and entitlement entries; then `xcodegen generate && xcodebuild -resolvePackageDependencies -derivedDataPath build | grep Sparkle`. Expected: `Sparkle: https://github.com/sparkle-project/Sparkle @ 2.10.1`.
  - Generate the keys. Flags were verified in Sparkle 2.10.1's `generate_keys/main.swift`: `--account`, `-p` prints the public key, `-x` exports the private key.
    ```bash
    SPARKLE_BIN=build/SourcePackages/artifacts/sparkle/Sparkle/bin
    "$SPARKLE_BIN/generate_keys" --account tegelapps >/dev/null
    envset SPARKLE_PUBLIC_ED_KEY "$("$SPARKLE_BIN/generate_keys" --account tegelapps -p)"
    mkdir -p ~/.tegel-secrets && chmod 700 ~/.tegel-secrets
    "$SPARKLE_BIN/generate_keys" --account tegelapps -x ~/.tegel-secrets/sparkle-ed25519-tegelapps.key && chmod 600 ~/.tegel-secrets/sparkle-ed25519-tegelapps.key
    envset SPARKLE_PRIVATE_KEY_BACKUP_PATH ~/.tegel-secrets/sparkle-ed25519-tegelapps.key
    envhas SPARKLE_PUBLIC_ED_KEY; envhas SPARKLE_PRIVATE_KEY_BACKUP_PATH
    ```
  - Put the public key, which is public by design, into `project.yml` as `SUPublicEDKey`. **Ask the user to copy the backup file to an off-machine backup**: losing it means no more updates for every installed copy.
  - **App:** `CommandGroup(after: .appInfo) { Button("Check for Updates…") { updaterController.updater.checkForUpdates() } }`.
  - **Settings:** add the tab `UpdatesSettingsView(updater: updaterController.updater)` with `.tabItem { Label("Updates", systemImage: "arrow.triangle.2.circlepath") }` after Licence. Its `Form` holds (plan 09 Settings spec):
    - `Toggle("Check for updates automatically")` bound to `updater.automaticallyChecksForUpdates`. Use local `@State`, read on appear, and write in `onChange`. The runtime API is used only for user changes, per sparkle-project.org/documentation/customization/;
    - a **"Check Now"** button → `updater.checkForUpdates()`;
    - "Last checked: <relative date>" from `updater.lastUpdateCheckDate`, hidden while it is `nil`.
- [ ] **Step 4: Run it to verify it passes.**
  - Step 1's commands. Expected:
    - `https://downloads.tegelapps.com/markdown/appcast.xml`, `true`, `true`;
    - then `com.tegelapps.markdown-spki`, `com.tegelapps.markdown-spks`, `network.client`.
  - `test -d "$(echo build/Build/Products/Debug/*.app)/Contents/Frameworks/Sparkle.framework" && echo embedded` → `embedded`.
  - `stat -f %Lp "$(envget SPARKLE_PRIVATE_KEY_BACKUP_PATH)"` → `600`.
  - *(GUI)* The app menu has "Check for Updates…", and Settings shows the tabs General | Appearance | Licence | Updates, with the Licence tab unchanged. Before Task 13, Check Now reports an update error, because no appcast exists yet.
  - `make check` passes, including `LocalizationTests` for the new strings.
- [ ] **Step 5: Commit.**
  ```bash
  git add project.yml Apps/Markdown/App/MarkdownApp.swift Apps/Markdown/App/UpdatesSettingsView.swift Apps/Markdown/App/Localizable.xcstrings <settings-tabview-file>
  git commit -m "feat(app): Sparkle 2.10.1 updater, menu item and Updates settings tab" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  ```

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

- [ ] **Step 1: Write the failing check.** This runs before H2: it reads settings only.
  ```bash
  xcodegen generate >/dev/null && xcodebuild -showBuildSettings -alltargets -configuration Release 2>/dev/null \
    | grep -cE '^\s*(CODE_SIGN_STYLE = Manual|CODE_SIGN_IDENTITY = Developer ID Application|ENABLE_HARDENED_RUNTIME = YES|OTHER_CODE_SIGN_FLAGS = .*--timestamp)$'
  ```
- [ ] **Step 2: Run it to verify it fails.** Expected: FAIL, a count below `8`.
- [ ] **Step 3: Implement** the four lines in `Config/Release.xcconfig`.
- [ ] **Step 4: Run it to verify it passes.** Expected: `8` (4 settings × 2 targets). Then `make check` passes: its builds use `CODE_SIGNING_ALLOWED=NO`, so they don't need the certificate.
- [ ] **Step 5: Signed archive check (BLOCKED until Task 3).**
  ```bash
  xcodebuild archive -scheme markdown -configuration Release -destination 'generic/platform=macOS' -archivePath build/sig.xcarchive -quiet \
    CODE_SIGN_IDENTITY="$(envget APPLE_DEVELOPER_ID_IDENTITY)" DEVELOPMENT_TEAM="$(envget APPLE_TEAM_ID)"
  A=$(echo build/sig.xcarchive/Products/Applications/*.app)
  for c in "$A" "$A"/Contents/PlugIns/*.appex; do codesign -dvv "$c" 2>&1 | grep -cE '^Authority=Developer ID Application|^Timestamp=|flags=0x10000\(runtime\)'; done
  ```
  Expected: `3` and `3`. The app and the extension are each Developer ID signed, timestamped and hardened.
- [ ] **Step 6: Commit.**
  ```bash
  git add Config/Release.xcconfig
  git commit -m "build: Developer ID manual signing, hardened runtime, secure timestamp for Release" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  ```

### Task 12: `scripts/release.sh` (Fri 20 – Sat 21 Nov)

**Files:**
- Create: `scripts/release.sh` (chmod +x)
- Test: `scripts/release_test.sh`
- Modify: `Makefile` (add a `test-release` target and include it in `check`)

**Interfaces:**
- Consumes:
  - `.env` `APPLE_TEAM_ID`, `APPLE_DEVELOPER_ID_IDENTITY`, `NOTARY_KEYCHAIN_PROFILE`, `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_R2_API_TOKEN`, `R2_BUCKET`;
  - `Config/PolarSandbox.xcconfig` (Task 8);
  - Sparkle Keychain account `tegelapps` (Task 10);
  - Release signing (Task 11).
- Produces:
  - **`scripts/release.sh <app> <version> [--sandbox] [--yes] [--no-upload]`**:
    - `<app>` ∈ `markdown` (plan 06 adds `data`);
    - `<version>` matches `^[0-9]+\.[0-9]+\.[0-9]+(-(b|rc)[0-9]+)?$`, so `1.0.0`, `1.0.0-b1` and `1.0.0-rc1` (plans 05–07) all pass;
    - `--sandbox` builds Release with the sandbox Polar values (betas);
    - `--yes` skips the publish prompt. **Claude passes `--yes` only after the user approved that exact version in chat**;
    - `--no-upload` stops after the notarised, stapled DMG passes Gatekeeper, and prints the DMG's absolute path as the last stdout line: no appcast, no R2, no prompt. Plans 05, 06 and 07 use it for RCs and pre-publish smoke tests.
  - **Exit codes:** 2 = usage error, 1 = guard or step failure, 0 = published (or, with `--no-upload`, DMG built).
  - **Artefacts:** `dist-release/markdown/<version>/` (gitignored); public `https://downloads.tegelapps.com/markdown/TegelMarkdown-<version>.dmg` and `…/markdown/appcast.xml`.

- [ ] **Step 1: Write the failing test** `scripts/release_test.sh`. It uses no network, no signing and no build.
  ```bash
  #!/usr/bin/env bash
  # Guard tests for release.sh. Runs it in throwaway clones so the real tree and .env are never touched.
  set -uo pipefail
  ROOT=$(git rev-parse --show-toplevel); pass=0; fail=0; tmps=(); trap 'rm -rf "${tmps[@]}"' EXIT
  KEYS="APPLE_TEAM_ID APPLE_DEVELOPER_ID_IDENTITY NOTARY_KEYCHAIN_PROFILE CLOUDFLARE_ACCOUNT_ID CLOUDFLARE_R2_API_TOKEN R2_BUCKET"
  fresh() { local t; t=$(mktemp -d); tmps+=("$t"); git clone -q "$ROOT" "$t"
    cp "$ROOT/scripts/release.sh" "$t/scripts/" && echo 'TG_POLAR_ORGANIZATION_ID = REPLACE_IN_PLAN_05' >> "$t/Config/Release.xcconfig"
    git -C "$t" add -A && git -C "$t" -c user.name=t -c user.email=t@t commit -qm t
    for k in $KEYS; do echo "$k=dummy-secret-value"; done > "$t/.env"; D=$t; }
  check() { local name=$1 want=$2 sub=$3; shift 3; local out got
    out=$(cd "$D" && ./scripts/release.sh "$@" </dev/null 2>&1); got=$?
    if [[ $got == "$want" && $out == *"$sub"* && $out != *dummy-secret-value* ]]; then ((pass++)); else ((fail++)); echo "FAIL $name (exit $got): $out"; fi; }
  fresh; check usage        2 "usage: scripts/release.sh <app> <version> [--sandbox] [--yes] [--no-upload]"
         check unknown-app  2 "unknown app: nope"   nope 1.0.0
         check bad-version  2 "bad version: 1.0"    markdown 1.0
  sed -i '' '/^APPLE_TEAM_ID=/d' "$D/.env"
         check missing-key  1 "missing .env key: APPLE_TEAM_ID" markdown 1.0.0
  fresh; touch "$D/stray.txt"
         check dirty-tree   1 "working tree is dirty" markdown 1.0.0
  fresh; check placeholder  1 "Config/Release.xcconfig still has REPLACE_IN_PLAN_05" markdown 1.0.0
         check rc-version   1 "Config/Release.xcconfig still has REPLACE_IN_PLAN_05" markdown 1.0.0-rc1   # passes the version regex
         check no-upload    1 "Config/Release.xcconfig still has REPLACE_IN_PLAN_05" markdown 1.0.0 --no-upload   # flag accepted
         check bad-flag     2 "usage: scripts/release.sh" markdown 1.0.0 --bogus   # so no-upload above proves the flag is parsed
  echo "release_test: $pass passed, $fail failed"; [[ $fail == 0 ]]
  ```
- [ ] **Step 2: Run it to verify it fails.** `bash scripts/release_test.sh`. Expected: FAIL, `cp: …/scripts/release.sh: No such file or directory`, … `release_test: 0 passed, 9 failed`.
- [ ] **Step 3: Implement `scripts/release.sh`.** It runs under `set -euo pipefail` and **never uses `set -x`**. In order:
  1. **Arguments:**
     - parse; no args or an unknown flag → the usage line, exit 2;
     - `case $app in markdown) SCHEME=markdown; DMG_NAME=TegelMarkdown-$V.dmg; VOL="Tegel Markdown";; *) die 2 "unknown app: $app"`;
     - version regex → `bad version: $V`, exit 2.
  2. **Guards:**
     - `cd "$(git rev-parse --show-toplevel)"`;
     - `need KEY` for each consumed key reads the value with `sed -n "s/^KEY=//p" .env` and `export`s it. An empty value → `missing .env key: KEY`, exit 1. Only the name is ever printed;
     - `[ -z "$(git status --porcelain)" ] || die 1 "working tree is dirty"`;
     - without `--sandbox`, `grep -q REPLACE_IN_PLAN_05 Config/Release.xcconfig` → `Config/Release.xcconfig still has REPLACE_IN_PLAN_05; pass --sandbox for a beta`, exit 1.
  3. **Set up:** `OUT=dist-release/markdown/$V` (wiped); `BUILD=$(git rev-list --count HEAD)` (a monotonic `CFBundleVersion` that Sparkle compares); `xcodegen generate`.
  4. **Archive:**
     ```
     xcodebuild archive -scheme $SCHEME -configuration Release -destination 'generic/platform=macOS' \
       -derivedDataPath build/release-dd -archivePath "$OUT/$SCHEME.xcarchive" \
       MARKETING_VERSION=$V CURRENT_PROJECT_VERSION=$BUILD \
       CODE_SIGN_IDENTITY="$APPLE_DEVELOPER_ID_IDENTITY" DEVELOPMENT_TEAM="$APPLE_TEAM_ID"
     ```
     Add `-xcconfig Config/PolarSandbox.xcconfig` when `--sandbox` is passed.
  5. **Export:**
     - `ExportOptions.plist` is generated in `$OUT` with `plutil -create xml1` + `-insert`: `method developer-id`, `signingStyle manual`, `signingCertificate "Developer ID Application"`, `teamID $APPLE_TEAM_ID`. Method names were checked against `xcodebuild -help` on Xcode 26.3;
     - `xcodebuild -exportArchive … -exportPath "$OUT/export"`;
     - `APP=$(echo "$OUT"/export/*.app)`.
  6. **Pre-notary checks** (each failure → exit 1):
     - PlistBuddy `CFBundleShortVersionString == $V` and `CFBundleVersion == $BUILD`;
     - `TGPolarAPIBase` == `https://sandbox-api.polar.sh` (`--sandbox`) or `https://api.polar.sh`;
     - `TGPolarBenefitID` is non-empty (D1);
     - `lipo -archs` on the app and the appex executables contains both `x86_64` and `arm64`;
     - `codesign --verify --deep --strict --verbose=2 "$APP"`;
     - `syspolicy_check notary-submission "$APP"`.
  7. **`notarize <file>`:**
     - `xcrun notarytool submit "$1" --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" --wait --output-format json > "$OUT/notary-<n>.json"`;
     - `plutil -extract status raw -o - <json>` must be `Accepted` (plutil reads JSON; checked on the build Mac). Otherwise write `xcrun notarytool log <id> …` to `$OUT/notary-log.json`, then exit 1.
  8. **App:** `ditto -c -k --keepParent "$APP" "$OUT/app.zip"` → `notarize` → `xcrun stapler staple "$APP"`.
  9. **DMG:** `ditto "$APP" "$OUT/dmg/$(basename "$APP")"`; `ln -s /Applications "$OUT/dmg/Applications"`; `hdiutil create -volname "$VOL" -srcfolder "$OUT/dmg" -format UDZO -ov "$OUT/$DMG_NAME"`; `codesign --sign "$APPLE_DEVELOPER_ID_IDENTITY" --timestamp` the DMG → `notarize` → `xcrun stapler staple`.
  10. **Gatekeeper.** All must pass; print the outputs:
      - `spctl -a -vvv -t exec "$APP"` → `accepted` + `source=Notarized Developer ID`;
      - `spctl -a -vvv -t open --context context:primary-signature "$OUT/$DMG_NAME"` → the same. `-t install` assesses "installation of an installer package" (`man spctl`), so a DMG uses `-t open`;
      - `xcrun stapler validate "$OUT/$DMG_NAME"` → `The validate action worked!`;
      - `syspolicy_check distribution "$APP"` → exit 0.
      - With `--no-upload`: `printf '%s\n' "$PWD/$OUT/$DMG_NAME"` as the last stdout line, then exit 0.
  11. **Appcast:**
      - copy the DMG into `$OUT/feed/`;
      - `curl -fsS "https://downloads.tegelapps.com/markdown/appcast.xml?v=$BUILD" -o "$OUT/feed/appcast.xml" || rm -f "$OUT/feed/appcast.xml"`. The first release has none; generate_appcast keeps the existing feed's items (`--maximum-versions` defaults to 3);
      - `build/release-dd/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast --account tegelapps --download-url-prefix https://downloads.tegelapps.com/markdown/ -o "$OUT/feed/appcast.xml" "$OUT/feed"`;
      - check: `grep "$DMG_NAME" "$OUT/feed/appcast.xml" | grep -q 'sparkle:edSignature='`, then print `appcast signature present`.
  12. **Confirm** unless `--yes`:
      - print the DMG name, `du -h`, `shasum -a 256` and the two destination URLs;
      - `read -r -p "Publish to downloads.tegelapps.com? [y/N] " a || a=`;
      - anything but `y` → `aborted: nothing uploaded`, exit 1. With no TTY, `read` hits EOF and aborts.
  13. **Upload**, DMG first so the appcast never points at a missing file:
      - `CLOUDFLARE_API_TOKEN="$CLOUDFLARE_R2_API_TOKEN" bunx wrangler@4.151.2 r2 object put "$R2_BUCKET/markdown/$DMG_NAME" --file … --content-type application/x-apple-diskimage --cache-control "public, max-age=31536000, immutable" --remote`;
      - then `appcast.xml` with `--content-type application/xml --cache-control "public, max-age=300" --remote`.
  14. **Post-upload:**
      - `curl -fsSI https://downloads.tegelapps.com/markdown/$DMG_NAME | head -1` → `HTTP/2 200`;
      - `curl -fsS "…/appcast.xml?v=$BUILD" | grep -c "$DMG_NAME"` ≥ 1;
      - print `published https://downloads.tegelapps.com/markdown/$DMG_NAME`, the public DMG URL that plan 05 writes into `site/config.json`.
  - **Makefile:** `test-release: ; bash scripts/release_test.sh`, and add `test-release` to `check`'s prerequisites.
- [ ] **Step 4: Run it to verify it passes.**
  - `bash scripts/release_test.sh`. Expected: `release_test: 9 passed, 0 failed`.
  - `bash -n scripts/release.sh && echo syntax-ok` → `syntax-ok`.
  - `make check` → the baseline, plus TegelStore, plus `release_test: 9 passed`.
- [ ] **Step 5: Commit.**
  ```bash
  git add scripts/release.sh scripts/release_test.sh Makefile
  git commit -m "feat(release): release.sh archive→notarise→DMG→appcast→R2 with guards" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  ```
- [ ] **Step 6: First real run (BLOCKED until Task 3).** This is Task 13 step 1.

### Task 13: End-to-end acceptance and BNPL record (Sat 21 – Sun 22 Nov; needs Task 3)

**Machine:**
- Build Mac (Intel iMac19,1, macOS 15.7), in a **fresh admin user account `tegeltest`** that the user creates.
- The arm64 / macOS 27 leg runs on Scaleway M1 lease **L2 (Thu 26 Nov 09:00 → Fri 27 Nov 09:00)**, booked by plan 05. It is second in L2's order, after plan 05's macOS 27 matrix (see Hand-offs).

**Files:**
- Create: `docs/gates/m03-acceptance.md` (table: check | machine | date | result | evidence)
- Create: `docs/gates/bnpl.md`
- Create: `docs/reviews/m03.md` (the "Pre-b1" section; Task 14 adds the rest)

**Interfaces:**
- Consumes everything above.
- Produces the evidence for the milestone exit criterion.

- [ ] **Step 0: Pre-b1 review.** b1 publishes the new licensing code, `release.sh` and the appcast, so they are reviewed first. The full pipeline still runs in Task 14.
  - `BASE=$(git merge-base HEAD main)`. Run Task 14's **stages 2, 3, 4 and 9** on `git diff $BASE...HEAD`, with the same scope and commands. Where stage 4 inspects "the b2 app", use the app from `scripts/release.sh markdown 1.0.0-b1 --sandbox --no-upload` (nothing is uploaded).
  - Fix every P0/P1 (failing test first), then re-run the stage that found it.
  - Record the results under "Pre-b1" in `docs/reviews/m03.md`, then `git add docs/reviews/m03.md && git commit -m "docs(reviews): m03 pre-b1 stages 2, 3, 4, 9" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`. `release.sh` needs a clean tree.
- [ ] **Step 1: Publish b1 (outward-facing).**
  - Ask: "Publish Tegel Markdown 1.0.0-b1 (sandbox Polar) to downloads.tegelapps.com?"
  - After a yes: `scripts/release.sh markdown 1.0.0-b1 --sandbox --yes`. The first `generate_appcast` run may trigger a Keychain prompt for the Sparkle key; the user clicks **Always Allow**.
  - Expected: the Gatekeeper lines from Task 12 step 3.10 all accepted, `appcast signature present`, `published https://downloads.tegelapps.com/markdown/TegelMarkdown-1.0.0-b1.dmg`.
- [ ] **Step 2 (user):** create the admin account `tegeltest` in System Settings → Users & Groups, and log in to it.
- [ ] **Step 3 (GUI, tegeltest): download and mount.**
  - Safari → `https://downloads.tegelapps.com/markdown/TegelMarkdown-1.0.0-b1.dmg`;
  - `xattr -p com.apple.quarantine ~/Downloads/TegelMarkdown-1.0.0-b1.dmg` prints a value (quarantine is set);
  - open it. The window shows the app and an Applications alias. Drag to Applications.
- [ ] **Step 4 (GUI): first launch.** Record the dialog text verbatim.
  - Pass = only the standard "…downloaded from the Internet. Are you sure you want to open it?" prompt.
  - Then `spctl -a -vvv -t exec "/Applications/Tegel Markdown.app"` → `accepted`, `source=Notarized Developer ID`.
- [ ] **Step 5:** add the b1 rows to `docs/gates/m03-acceptance.md` and commit (`docs(gates): m03 b1 acceptance`). This later commit gives b2 a higher `CFBundleVersion`.
- [ ] **Step 6: Publish b2.**
  - Ask the user for the b2 publish, then run `scripts/release.sh markdown 1.0.0-b2 --sandbox --yes`.
  - Then `curl -fsS "https://downloads.tegelapps.com/markdown/appcast.xml?v=b2" | grep -c '<item>'` → `2`.
- [ ] **Step 7 (GUI, tegeltest): update.**
  - Check for Updates… → b2 is offered.
  - For the Task 14 design review, before installing: `mkdir -p /Users/Shared/m03 && screencapture -x -w /Users/Shared/m03/sparkle-prompt-light.png` (click the prompt). Switch System Settings ▸ Appearance to Dark and capture `…-dark.png`; switch back. Click Remind Me Later, quit, `open -a "Tegel Markdown" --args -AppleLanguages '(ar)'`, Check for Updates…, capture `…-ar.png`, then quit and relaunch normally.
  - Check for Updates… → Install and Relaunch;
  - `defaults read "/Applications/Tegel Markdown.app/Contents/Info" CFBundleShortVersionString` → `1.0.0-b2`;
  - `spctl -a -vvv -t exec` again → `accepted`.
- [ ] **Step 8 (GUI): purchase, with the BNPL look.**
  - Settings → Licence → Buy Pro… → the sandbox checkout opens;
  - set the country to Netherlands, list every payment method, and screenshot;
  - pay as `POLAR_EMAIL` with `4242 4242 4242 4242`. Expected: the success page.
- [ ] **Step 9: Key email.** Record whether the email to `POLAR_EMAIL` contains the key. If it doesn't, take the key from the portal; that result feeds plan 05's FAQ.
- [ ] **Step 10 (GUI): activate.**
  - Paste the key with leading spaces and a trailing newline → Activate. Expected: "Pro is active on this Mac", and folder mode works.
  - Dashboard: the activation label = `scutil --get ComputerName`.
- [ ] **Step 11 (GUI): offline relaunch.** Disconnect the network, ⌘Q, relaunch. Expected: still Pro, no error dialog. Reconnect.
- [ ] **Step 12 (GUI): deactivate.** Deactivate this Mac. Expected: the free copy, and 0 activations in the dashboard.
- [ ] **Step 13: Error copy.**
  - Key `TEGEL-0000` → the `.notFound` copy.
  - Fill both slots with Task 1 step 9's `act probe-1; act probe-2` (expected `200`, `200`), then Activate in the app → the `.limitReached` copy.
  - Free both slots with `deact` (expected `204`, `204`).
  - **Another app's key is rejected (D1).** Paste `POLAR_SANDBOX_OTHER_LICENSE_KEY` (Task 1 step 10) as in step 10, then Activate → the `.wrongProduct` copy, and the app stays free. Then prove no activation was left on that key (its limit is 2):
    ```bash
    O=$(envget POLAR_SANDBOX_ORGANIZATION_ID); K=$(envget POLAR_SANDBOX_OTHER_LICENSE_KEY); A=https://sandbox-api.polar.sh/v1/customer-portal/license-keys; T=$(mktemp)
    # act / deact exactly as in Task 1 step 9
    act probe-1; I1=$(plutil -extract id raw -o - "$T"); act probe-2; I2=$(plutil -extract id raw -o - "$T")
    deact "$I1"; deact "$I2"; rm -f "$T"
    ```
    Expected: `200`, `200`, `204`, `204`. A `403` on probe-2 means the app left an activation behind.
- [ ] **Step 14 (GUI): the 404 rule, live.**
  1. Activate in the app.
  2. Manage activations… opens the portal; sign in with the emailed code and deactivate this Mac there. This exercises `enable_customer_admin`.
  3. ⌘Q, then relaunch online. Expected: **still Pro** (validate 404 → grace).
  4. Deactivate this Mac. Expected: free (a 404 counts as already done).
- [ ] **Step 15 (GUI): auto-update toggle.**
  - In Settings ▸ Updates, turn "Check for updates automatically" off, ⌘Q, then `defaults read ~/Library/Containers/com.tegelapps.markdown/Data/Library/Preferences/com.tegelapps.markdown SUEnableAutomaticChecks` → `0`.
  - Turn it back on → `1`.
- [ ] **Step 16: Record and commit.**
  - Write all rows into `docs/gates/m03-acceptance.md`, each naming the machine (Intel iMac, macOS 15.7, `tegeltest`).
  - Write `docs/gates/bnpl.md`: rows for the W1 sandbox look (Task 1 step 7) and this one (date, checkout, countries tried, methods shown, BNPL present yes/no), plus a row "live checkout: pending plan 05 (W6)".
  - Commit:
  ```bash
  git add docs/gates/m03-acceptance.md docs/gates/bnpl.md
  git commit -m "docs(gates): m03 end-to-end acceptance (Intel) and sandbox BNPL check" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  ```

### Task 14: 9-stage pipeline, merge, push (Mon 23 Nov)

**Files:**
- Modify: `docs/reviews/m03.md` (created in Task 13 step 0)
- Modify: `.github/workflows/ci.yml` (plan 01)
- Create: `docs/reviews/m03/*.png` (design-review screenshots)
- Modify: whatever stage 7 patches

**Interfaces:**
- Consumes: the whole branch. `BASE=$(git merge-base HEAD main)`.

- [ ] **Step 0: CI on release tags.** Plan 01's macOS job runs on `workflow_dispatch` only; release tags `v*` must run it too. The workflow's `on: { push: {}, … }` already fires on tag pushes (adding a `push: tags:` filter there would stop the js job on branch pushes), so widen the job's condition:
  - in `.github/workflows/ci.yml`, job `macos`: `if: github.event_name == 'workflow_dispatch' || startsWith(github.ref, 'refs/tags/v')`;
  - check: `grep -c "startsWith(github.ref, 'refs/tags/v')" .github/workflows/ci.yml` → `1`;
  - commit: `git add .github/workflows/ci.yml && git commit -m "ci: run the macOS matrix on v* release tags" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`.

- [ ] **Stage 1: bloat audit (pre).** Apply `~/.claude/skills/code-upgrade/bloat-audit.md` to `git diff $BASE...HEAD` and the touched files. Strip self-introduced bloat; queue pre-existing findings as questions in `docs/reviews/m03.md`.
- [ ] **Stage 2: baseline.** `git status --short` (expected empty), then `make check 2>&1 | tail -30`. Record the bun, swift (TegelKit + 35 TegelStore) and `release_test: 9 passed` counts.
- [ ] **Stage 3: code review.** gstack `/review` on `git diff $BASE...HEAD`, or a cold code-review subagent given only the diff.
- [ ] **Stage 4: `/cso` (mandatory).** Scope:
  - **TegelStore:** error → grace mapping (no 404 lock); the mid-flight race; key normalisation; no token or `Authorization` sent; HTTPS-only `apiBase`; the benefit binding (validate sends `benefit_id`; an activate mismatch releases the activation and throws `.wrongProduct`; a missing `benefit_id` fails closed; `TGPolarBenefitID` in the b2 app is the Markdown sandbox benefit).
  - **Keychain:** item attributes and ACL; nothing logged.
  - **Entitlements** (`codesign -d --entitlements -` on the b2 app): only D5's set plus the two mach-lookup names.
  - **Sparkle:** `SUPublicEDKey` present; HTTPS feed; `SUEnableSystemProfiling` absent; EdDSA on every enclosure.
  - **`release.sh`:** quoting, no `set -x`, no value echoed, guard order, the confirmation, upload order, token scope.
  - **`.env.example`:** names only.
  - **Debug override compiled out of Release:** `strings "<b2 app>/Contents/MacOS/"* | grep -c <plan-02 override key>` → `0`.
  - **No secrets in history:** `git log -p $BASE..HEAD | grep -cE 'polar_oat_|BEGIN (EC |OPENSSH )?PRIVATE KEY|AuthKey_[A-Z0-9]+\.p8'` → `0`.
- [ ] **Stage 5: adversarial.** `/codex` challenge mode: "Find a way a paying user loses Pro, a non-payer or another app's key gains Pro, an unsigned or unnotarised update installs, or a secret reaches the repo or a log." If codex can't run, use an agent fallback and say so.
- [ ] **Design review** (CLAUDE.md "Verification"; skill `design-review`). Review against `DESIGN.md` and plan 09's Settings spec:
  - the Licence tab (free, Pro, and the `.wrongProduct` error) and the Updates tab, on a Debug build on the build Mac, each in light, dark (System Settings ▸ Appearance) and Arabic (`-AppleLanguages '(ar)'`): `screencapture -x -w docs/reviews/m03/<licence-free|licence-pro|licence-error|updates>-<light|dark|ar>.png`;
  - Sparkle's update prompt: copy Task 13 step 7's `/Users/Shared/m03/sparkle-prompt-*.png` into `docs/reviews/m03/`.
  - Findings go into stage 6 with the others.
- [ ] **Stage 6: consolidate.** Dedupe and classify P0/P1/P2 in `docs/reviews/m03.md`.
- [ ] **Stage 7: patch and re-review.**
  - Each fix gets a failing test first, then `make check` and the targeted review again.
  - If `release.sh`, entitlements, Info.plist or TegelStore changed: publish `1.0.0-b3 --sandbox` (ask the user first) and repeat Task 13 steps 3–4, 7 and 11.
- [ ] **Stage 8: bloat audit (post)** on the final cumulative diff.
- [ ] **Stage 9: `/review` + cubic.** `cubic review -b "$BASE" -j > dist-release/cubic-<n>.json`, then read `issues`. Repeat after each fix batch until **two consecutive rounds show no new P0/P1**, on a stable tree.
- [ ] **Graph and record.** `graphify update .`, then write the stage results into `docs/reviews/m03.md` (findings, fixes, cubic rounds, any stage that couldn't run and its substitute).
  ```bash
  git add docs/reviews/m03.md docs/reviews/m03/ && git commit -m "docs(reviews): m03 pipeline results" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  ```
- [ ] **Merge and push (D14).**
  ```bash
  git checkout main && git pull --ff-only origin main
  git merge --no-ff m03-commerce-release -m "merge: m03 licensing, updates, release" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  make check && git push origin main
  ```
  Expected: `make check` matches the stage 2 counts, and the push succeeds.

---

## Hand-offs to plan 05

1. **arm64 / macOS 27 leg** on Scaleway M1 lease L2 (Thu 26 Nov 09:00 → Fri 27 Nov 09:00), second after plan 05's macOS 27 matrix, using b2. Repeat Task 13 steps 3–4, 7 and 10–12, and record them in `docs/gates/m03-acceptance.md` labelled "Scaleway M1, macOS 27".
2. **Before 1.0.0, delete `markdown/TegelMarkdown-1.0.0-b*.dmg` and `markdown/appcast.xml` from R2.** This is outward-facing, so ask the user first. Sandbox betas accept Stripe test cards, so anyone holding a beta DMG gets Pro for free.
3. **Replace `REPLACE_IN_PLAN_05` in `Config/Release.xcconfig`** in all four settings: `TG_POLAR_ORGANIZATION_ID`, `TG_POLAR_CHECKOUT_URL_MARKDOWN`, `TG_POLAR_PORTAL_URL` and `TG_POLAR_BENEFIT_ID_MARKDOWN` (the live Markdown licence benefit). Create the live product with the same benefit settings (limit 2, `enable_customer_admin`) at $14 (D15). Check with a Release build (`xcodebuild -scheme markdown -configuration Release -derivedDataPath build`), not `make build` (Debug).
4. **Live BNPL row** in `docs/gates/bnpl.md` [F3g].
5. **FAQ input:** whether the key arrives by email (Task 13 step 9), and the error copy from Task 9.

## Contract change requests

Status (consolidation, 27 Oct): 1–5 accepted; 3 extended with `--no-upload` and `-rcN` versions; 6 added.

1. **`Polar-Version`: omitted, not pinned.** This changes master §10 P3's mitigation ("Calendar: bump `Polar-Version` every 6 months").
   - **Reason:** an omitted header uses Current, while a pinned version 404s after about 9 months, which would remove Pro from every install that doesn't update (polar.sh/docs/api-reference/2026-10/versioning.md).
   - **New mitigation:** each quarter, when a version enters Next, run Task 1 step 9 against the sandbox with `-H 'Polar-Version: <Next>'`, and ship a fix within the 3-month Next window if it breaks. The 30-day grace still covers 404s.
2. **§3.1 layout: add `Config/PolarSandbox.xcconfig`.**
   - **Reason:** notarised betas (Task 13) need sandbox Polar values in a *Release* build. One file, included by `Debug.xcconfig` and passed as `xcodebuild -xcconfig` by `release.sh --sandbox`, keeps a single source of sandbox values.
3. **`scripts/release.sh <app> <version>` gains `[--sandbox] [--yes] [--no-upload]`, and versions may end `-bN` or `-rcN`**, in CLAUDE.md's Commands table and §3.1.
   - **Reason:** sandbox betas, plus a confirmation prompt for an outward-facing upload. The prompt is skipped only by an explicit flag after user approval. Plans 05–07 build RCs with `--no-upload`.
4. **§3.1: add `scripts/release_test.sh` and a Makefile `test-release` target in `check`.**
   - **Reason:** the release guards (dirty tree, missing key, placeholder values) need a regression test that runs without signing or network.
5. **Clarifications to §3.3, no signature change:**
   - `LicenseManager.isPro` is computed (true only for `.pro`).
   - `deactivate()` treats `PolarError.notFound` as success, because the activation was already removed.
   - `refresh` ignores `validate`'s `expires_at`.
   - `KeychainStore` throws `NSError(NSOSStatusErrorDomain)`.
   - Key normalisation strips all whitespace, not only the ends.
6. **§3.3 and D16: licence keys bind to one app** (decision D1; interfaces X2). `PolarConfig.benefitID` (Info.plist `TGPolarBenefitID`, build setting `TG_POLAR_BENEFIT_ID_MARKDOWN`), `PolarError.wrongProduct`, `benefit_id` on validate, and the activate check.
   - **Reason:** without it, any key in the Polar organisation (a later Data or bundle key) unlocks App 1. Plan 07 F1 generalises the single id to a set only if v2 needs it.
