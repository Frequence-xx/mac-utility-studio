# Milestone 05: Release readiness and launch of App 1, implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Take the feature-complete Tegel Markdown from plans 01–04 to a tested, notarised 1.0.0 sold on Polar at $14. Then launch it on Tue 8 Dec 2026, move the price to $19 on Tue 15 Dec 00:00 CET, ship 1.0.1, and run G1 on Thu 7 Jan 2027.

**Architecture:** Mostly operations, not code.
- **Two small scripts, because the steps repeat:**
  - `scripts/smoke-dmg.sh`: an installed-DMG smoke test, run on 5 machines and twice per release;
  - `scripts/polar_sales.py`: the sales counter used for launch monitoring, G1, the 4 Mar follow-up and G2.
- **Everything else is files:** docs, drafts and runbooks that the user approves.
- **Outward-facing steps:** every live Polar change, upload, post and email is its own step with an explicit approval checkbox (CLAUDE.md "Outward-facing actions").

**Tech stack:**
- bash + Apple CLI tools (`hdiutil`, `spctl`, `stapler`, `pluginkit`, `qlmanage`, `screencapture`, `sips`, `PlistBuddy`);
- python3 stdlib (`urllib`, `zoneinfo`, `unittest`);
- the installed `ffmpeg` (`overlay`, `pad`, `scale`; no `drawtext`, plan 09 [V18]) and plan 09's `caption.html`/`gallery.html` templates rendered with gstack browse;
- GitHub Actions `workflow_dispatch`;
- Polar dashboard + API;
- Playwright MCP for dashboards.

**Spec:** `BUSINESS-PLAN.md` (§5, §6.4, §8, §11 W5–W14, §12, §13, §15). **Contract:** `docs/superpowers/plans/2026-10-27-00-master-roadmap.md` (§3 names, D11, D13–D16, H5–H11). **Facts:** `docs/research/2026-10-27-technical-facts.md` [F3f, F3g, F7, F9]. **Rules:** `CLAUDE.md`.

**Branch:** `m05-launch` from `main` for Part A. Part B work goes on short branches or on `main` (docs only), as each task says.

## Global Constraints

- **Price:** App 1 is **$19 once, 2 Macs**. The introductory **$14 is the actual Polar price, not a discount** [F3f], changed by hand to $19 on **Tue 15 Dec 2026 00:00 CET** (D15).
- **Launch-price wording, verbatim, wherever a price is shown before 15 Dec:** `Introductory price $14 until Mon 14 Dec 2026 23:59 CET. From 15 Dec: $19.` Never a "was" price, struck-through price, countdown or "only N left" (rule 6, art. 5a Bpp).
- **No BNPL** in the checkout (rule 7) [F3g]. 14-day no-questions refund. The 2-Mac limit is stated before purchase.
- **Imagery and audio:**
  - Text, code and diagrams only. **No faces** anywhere (avatars, Dock icons of people, browser tabs).
  - **No music or audio:** videos are encoded with `-an`.
  - Arabic sample text is never Qur'an or hadith. Demo documents come from `Fixtures/markdown/`, which is neutral technical prose by contract (§3.4).
- **No holiday theming** (no Christmas, Black Friday 27 Nov or Cyber Monday 30 Nov tie-ins). No giveaways by draw.
- **Outward-facing actions need approval:** every live Polar change, release upload, post, email, PH scheduling and mod message gets explicit user approval for that specific action. Sandbox, preview deploys, local builds and the private GitHub repo don't.
- **Secrets:** never print a secret.
  - Check `.env` keys by name: `grep -cE '^KEY=.+' .env` → `1`.
  - Load them with `set -a; . ./.env; set +a`.
- **Evidence honesty:** every result names the machine that produced it (`m15-intel` = build Mac; `m14-arm`, `m15-arm`, `m26-arm` = GitHub runners; `m27-arm` = Scaleway M1). Never claim "works on Apple Silicon/26/27" from the build Mac (CLAUDE.md hardware constraint).
- **Names:**
  - App `Tegel Markdown` (`com.tegelapps.markdown`); Quick Look extension `com.tegelapps.markdown.quicklook` (D7).
  - Info.plist keys `TGPolarAPIBase`, `TGPolarOrganizationID`, `TGPolarCheckoutURL`, `TGPolarPortalURL`, `TGPolarBenefitID` (D16), fed by plan 03's `TG_POLAR_*` build settings in `Config/Release.xcconfig`.
  - Support address `hello@tegelapps.com`.
- **Dates (all CET):**
  - H8 scholar email this week (W1); H10 tax adviser by Fri 13 Nov;
  - Polar production org + Stripe identity verification started by Fri 20 Nov; live by Tue 1 Dec;
  - matrix W5 (24–30 Nov); Scaleway lease L2 Thu 26 Nov 09:00 → Fri 27 Nov 09:00;
  - launch Tue 8 Dec (PH 00:01 PT = 09:01 CET);
  - price change Tue 15 Dec 00:00 (site, then Polar; a late switch is safe until 08:00);
  - support gate check Tue 22 Dec;
  - G1 Thu 7 Jan 2027;
  - follow-up Thu 4 Mar 2027.

## Review Focus

1. **Checkout and site disagree around 15 Dec 00:00.** Expected: the checkout never charges more than the site shows. Site to $19 first, then Polar; verify a fresh checkout shows $19. *(Task 9 runbook, Task 12.)*
2. **xcconfig eats `//`.** Writing `TG_POLAR_API_BASE = https://api.polar.sh` in `Release.xcconfig` silently truncates it to `https:`. Every licence call then fails, and the 30-day grace hides it for a month. Expected: the installed app's Info.plist says exactly `https://api.polar.sh`. *(Task 1 smoke check `plist`, Task 2 Step 9.)*
3. **A false Gatekeeper pass.** Runner downloads carry no quarantine flag, and Gatekeeper may be relaxed on CI images, so "exit 0" proves nothing. Expected: the assessment output contains `source=Notarized Developer ID`, plus a real quarantined first launch on `m15-intel` and `m27-arm`. *(Task 1, Task 3 R1.)*
4. **Licence edge cases with live keys:**
   - a third Mac → HTTP 403 and the limit message;
   - offline relaunch → Pro stays on;
   - Copy Diagnostics never contains the key or `/Users/` paths.

   *(Task 3 R9, R11.)*
5. **G1 miscount.** Refunded orders, $0 QA/press orders, other products, and orders outside 8 Dec 00:00 – 7 Jan 00:00 CET must not count. *(Task 6 tests.)*

---

## File map

| Path | Task | Responsibility |
|---|---|---|
| `scripts/smoke-dmg.sh`, `scripts/test-smoke-dmg.sh` | 1 | Install a DMG, assert notarisation, archs, Polar plist values and Quick Look registration; take screenshots |
| `.github/workflows/smoke.yml` | 1 | `workflow_dispatch`: run the smoke test on `macos-14`, `macos-15`, `macos-26` |
| `.env.example`, `Config/Release.xcconfig` | 2 | Production Polar key names; production `TG_POLAR_*` values |
| `docs/gates/test-matrix-1.0.md`, `docs/gates/evidence/1.0/<machine>/` | 3 | Matrix with evidence per cell |
| `site/content/en/faq.md` (plan 04's `/faq/`) | 4 | Append the FAQ answers and a `## Known issues` section |
| `docs/ops/support-templates.md`, `docs/ops/support-log.md` | 4 | Reply templates; daily minutes log + gate |
| `docs/launch/demo/storyboard.md`, `docs/launch/demo/captions/*.png`, `docs/launch/demo/captions.filter` | 5 | Demo script, caption bands (plan 09 `caption.html`) and the overlay graph |
| `site/static/media/tegel-markdown-demo.{mp4,webm}`, `…-poster.png` | 5 | Site video and poster |
| `site/static/img/app1-<subject>-<light\|dark>.png` | 5 | Site screenshots (plan 04 CR-6) |
| `docs/launch/ph-gallery/*.png` | 5 | 4 × 1270×760 gallery (plan 09 `gallery.html`) + 240×240 thumbnail |
| `scripts/polar_sales.py`, `scripts/test_polar_sales.py`, `Makefile` | 6 | Count paid sales in a CET date window; `test-scripts` in `make check` |
| `docs/ops/advisers.md` | 7 | H8 scholar and H10 tax-adviser messages; H7 KvK-number check |
| `docs/launch/app1-posts.md` | 8 | PH, r/macapps, Show HN, IH, press drafts + approvals + results |
| `docs/launch/app1-runbooks.md` | 9 | Launch day, price change, post-launch triage/1.0.1 |
| `docs/reviews/m05.md` | 10 | Pipeline results |
| `docs/gates/G1.md` | 14 | G1 decision |

**Copy lint** (Tasks 4, 8, 12). Run it before every approval request:

```bash
grep -rniE 'was \$|~~\$|black friday|cyber monday|christmas|xmas|holiday|santa|limited time|only [0-9]+ left|hurry|last chance|giveaway|spin to win|countdown|sale ends' \
  docs/launch/app1-posts.md site/content/en/faq.md docs/ops/support-templates.md && echo "COPY-LINT: FIX" || echo "COPY-LINT: clean"
```

---

# Part A: before launch (W5–W6, branch `m05-launch`)

- [ ] **A0:** `git switch main && git pull && git switch -c m05-launch`. Expected: `git branch --show-current` → `m05-launch`.
- [ ] **A1:** The user has run `gh auth login`, needed for `gh workflow run` and `gh release`. Expected: `gh auth status` exits 0.

### Task 1: DMG smoke script + on-demand runner workflow (Tue 24 Nov)

**Files:**
- Create: `scripts/smoke-dmg.sh`, `scripts/test-smoke-dmg.sh`, `.github/workflows/smoke.yml`

**Interfaces:**
- Consumes: a DMG from `scripts/release.sh markdown <version> --no-upload`, whose `<version>` may be `X.Y.Z-rcN` (plan 03 Task 12; Contract change request 2); `Fixtures/markdown/*.md`.
- Produces:
  - `scripts/smoke-dmg.sh <dmg> <out-dir>`, which reads env `APP_NAME` (default `Tegel Markdown`), `INSTALL_DIR` (default `/Applications`) and `FIXTURES` (default `Fixtures/markdown`, relative to the working directory). It writes `<out-dir>/smoke.txt`, one line per check (`PASS <check> <detail>` / `FAIL <check> <detail>`), plus `<out-dir>/*.png`. It exits 0 only if every hard check passes, else 1.
  - Hard checks, by name:
    - `stapler`: `xcrun stapler validate <dmg>` succeeds;
    - `gatekeeper`: `spctl -a -vv -t exec <app>` output contains `source=Notarized Developer ID`;
    - `archs`: `lipo -archs` lists `arm64` and `x86_64`;
    - `plist`: `TGPolarAPIBase` == `https://api.polar.sh`; `TGPolarOrganizationID` and `TGPolarBenefitID` are non-empty;
    - `quicklook`: `pluginkit -m -v -i com.tegelapps.markdown.quicklook` prints a line after one app launch.

- [ ] **Step 1: Write the failing test `scripts/test-smoke-dmg.sh`.** It needs no app build:
  - copy `/System/Applications/Calculator.app` with `ditto` into a temp folder;
  - `hdiutil create -quiet -volname T -srcfolder <tmp>/src <tmp>/bad.dmg`;
  - run `APP_NAME=Calculator INSTALL_DIR=<tmp>/inst scripts/smoke-dmg.sh <tmp>/bad.dmg <tmp>/out`.

  It asserts:
  - the exit code is `1`;
  - `smoke.txt` has a line starting `FAIL stapler`;
  - `smoke.txt` has a line starting `FAIL gatekeeper` (Calculator assesses as `source=Apple System`, not Notarized Developer ID).

  It prints `test-smoke-dmg: PASS` or exits 1.
- [ ] **Step 2: Run it.** `bash scripts/test-smoke-dmg.sh`. Expected: FAIL (`scripts/smoke-dmg.sh: No such file or directory`).
- [ ] **Step 3: Implement `scripts/smoke-dmg.sh`** (`set -uo pipefail`, not `-e`, so every check runs and is reported).
  - **Install:** `hdiutil attach -nobrowse -readonly`, `ditto` the `.app` into `$INSTALL_DIR`, `hdiutil detach`.
  - **Hard checks:** the five above, each via a `check <name> <cmd…>` helper that appends PASS/FAIL. `quicklook` runs after `open -a "$INSTALL_DIR/$APP_NAME.app"` and `sleep 5`.
  - **Soft steps** (screenshots, never fail the run):
    - `pluginkit -e use -i com.tegelapps.markdown.quicklook`;
    - for each `$FIXTURES/*.md`: `qlmanage -p <file> &`, `sleep 3`, `screencapture -x <out>/ql-<name>.png`, kill `qlmanage`;
    - `open -a <app> Fixtures/markdown/rtl-arabic.md` → `window-rtl.png`;
    - `open -n -a <app> --args -AppleLanguages '(ar)'` → `ui-ar.png`.
  - **End:** `pkill -x "$APP_NAME"`; exit 1 if `grep -q '^FAIL' smoke.txt`.
- [ ] **Step 4: Run the test.** `bash scripts/test-smoke-dmg.sh`. Expected: `test-smoke-dmg: PASS`.
- [ ] **Step 5: Write `.github/workflows/smoke.yml`.** Pass the tag via `env`, never inline `${{ }}` in `run:`, to avoid script injection.

```yaml
name: smoke
on:
  workflow_dispatch:
    inputs: { tag: { description: "Private GitHub release tag holding the DMG", required: true } }
permissions: { contents: read }
jobs:
  smoke:
    strategy: { fail-fast: false, matrix: { os: [macos-14, macos-15, macos-26] } }
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v7
      - env: { GH_TOKEN: "${{ github.token }}", TAG: "${{ inputs.tag }}" }
        run: gh release download "$TAG" --pattern '*.dmg' --dir dmg
      - run: bash scripts/smoke-dmg.sh dmg/*.dmg out
      - if: always()
        uses: actions/upload-artifact@v4
        with: { name: "smoke-${{ matrix.os }}", path: out }
```

- [ ] **Step 6: Validate the YAML.** `ruby -ryaml -e 'YAML.load_file(".github/workflows/smoke.yml"); puts "yaml ok"'`. Expected: `yaml ok`.
- [ ] **Step 7: Commit.**

```bash
git add scripts/smoke-dmg.sh scripts/test-smoke-dmg.sh .github/workflows/smoke.yml
git commit -m "test(release): add DMG smoke script and on-demand runner workflow

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 2: Polar production (org + identity by Fri 20 Nov; setup Tue 24 Nov → live by Tue 1 Dec, H5)

**Files:**
- Modify: `.env.example` (add `POLAR_PRODUCT_ID_MARKDOWN=`, `POLAR_BENEFIT_ID_MARKDOWN=`, `POLAR_PORTAL_URL=`, `POLAR_QA_LICENSE_KEY=`)
- Modify: `Config/Release.xcconfig` (the four `REPLACE_IN_PLAN_05` values from plan 03 Task 8)
- Evidence: `docs/gates/evidence/1.0/polar/*.png`

**Interfaces:**
- Produces:
  - `.env` keys `POLAR_ORGANIZATION_ID`, `POLAR_ACCESS_TOKEN` (scopes `orders:read`, `products:read` only), `POLAR_PRODUCT_ID_MARKDOWN`, `POLAR_BENEFIT_ID_MARKDOWN`, `POLAR_CHECKOUT_URL_MARKDOWN`, `POLAR_PORTAL_URL`, `POLAR_QA_LICENSE_KEY`;
  - the four production `TG_POLAR_*` settings in `Release.xcconfig` (Step 9).

Each 🔒 step is a live, outward-facing change. Show the user the exact values, get approval, then act (Playwright MCP, with the user doing 2FA).

- [ ] **Step 0 (user, by Fri 20 Nov, H5):** Create the Polar **production** organisation and start Stripe identity + payout verification, so it can complete before Tue 1 Dec. Record the date here.
- [ ] **Step 1 (Tue 24 Nov):** In the Polar production dashboard, record the verification status (pending or verified) here.
  - **Check step:** can products be created and sold before verification completes? If selling is blocked, Task 3 R9 on `m27-arm` uses whatever exists on lease day and is otherwise deferred to `m15-intel` in Task 10.
- [ ] **Step 2 🔒 Org details:**
  - name `Tegel`; website `https://tegelapps.com`; support email `hello@tegelapps.com`;
  - avatar = the 512 px app-icon PNG from plan 09 (`AppIcon.icns`; no faces, rule 3).

  Expected: a screenshot of the settings page saved as `polar/org.png`.
- [ ] **Step 3 🔒 Access token:**
  - Create an organization access token with scopes `orders:read`, `products:read` and save it as `POLAR_ACCESS_TOKEN`.
  - Expected: `grep -cE '^POLAR_ACCESS_TOKEN=.+' .env` → `1`.
  - Expected: the command below prints `200`.

  ```bash
  curl -s -o /dev/null -w '%{http_code}\n' \
    -H "Authorization: Bearer $POLAR_ACCESS_TOKEN" \
    "https://api.polar.sh/v1/orders/?organization_id=$POLAR_ORGANIZATION_ID&limit=1"
  ```

  - If plan 08 Task 4 Step 1 found the `reference_id` only on checkouts, the token also needs `checkouts:read`. That scope change is its own 🔒 approval.
- [ ] **Step 4 🔒 Licence benefit:**
  - type License keys, description `Tegel Markdown licence (2 Macs)`, prefix `TEGEL`;
  - activations `limit: 2`, `enable_customer_admin: true` [F3e];
  - no expiry, no usage limit.

  Expected: a screenshot `polar/benefit.png` showing limit 2 and customer admin on. Save the benefit id as `POLAR_BENEFIT_ID_MARKDOWN` (the app's `TGPolarBenefitID`, which binds keys to this app; plan 03): `grep -cE '^POLAR_BENEFIT_ID_MARKDOWN=.+' .env` → `1`.
- [ ] **Step 5 🔒 Product:**
  - "Tegel Markdown", one-time purchase, fixed price **USD 14.00**, with the benefit attached;
  - a checkbox custom field `no_marketing`, label "Don't email me set-up tips or news about Tegel apps", not required. This is the soft opt-in objection at collection (BUSINESS-PLAN §8), and it covers plan 08's lifecycle tips and news emails. Plan 08 Task 14 rereads the live label before it activates them.

  Description, which states the limits before purchase:

  ```text
  One-time licence for 2 Macs. Unlocks folder mode with search and live reload, paginated A4/Letter PDF export (right-to-left correct) and 3 themes with light and dark. Quick Look, the single-file window, Mermaid and RTL rendering stay free. 14-day refund, no questions asked: reply to your receipt or email hello@tegelapps.com.
  ```

  Expected: `POLAR_PRODUCT_ID_MARKDOWN` saved (`grep -cE '^POLAR_PRODUCT_ID_MARKDOWN=.+' .env` → `1`).
- [ ] **Step 6 🔒 Public checkout link:**
  - product Tegel Markdown; discount codes **off**; success URL = `/download/` (plan 04 Task 14), or none.
  - Save `POLAR_CHECKOUT_URL_MARKDOWN` and `POLAR_PORTAL_URL` (`https://polar.sh/<org-slug>/portal`).
  - Expected: both `grep -c` checks → `1`; `curl -s -o /dev/null -w '%{http_code}' -L "$POLAR_CHECKOUT_URL_MARKDOWN"` → `200`.
  - **Keep the URL unpublished** (no site page, post or message) until `KVK_NUMBER` in `.env` is filled: `grep -cE '^KVK_NUMBER=.+' .env` → `1`. Plan 04 Task 14 then puts it in `site/config.json`.
- [ ] **Step 7 🔒 QA licence.** It gives a production key for the matrix without a real sale.
  - Create discount `QA-INTERNAL`: 100%, max redemptions 1 (single-use), ends 2026-12-07. Hidden: it's never published, and the public link has discount codes off (Step 6), so nobody can type it in.
  - Create a separate, unpublished checkout link with that discount preset. Complete it with the studio email.
  - Save the key from the receipt as `POLAR_QA_LICENSE_KEY`.
  - Expected: `grep -c` → `1`. The $0 order is excluded from G1 by Task 6.
- [ ] **Step 8: Receipt check.** Screenshot the QA receipt email (`polar/receipt.png`). Expected:
  - only the tile avatar and text;
  - no holiday or figurative imagery;
  - the key and the portal link are present.
- [ ] **Step 9: Fill `Config/Release.xcconfig`.** Replace the four `REPLACE_IN_PLAN_05` values in plan 03's build settings. `TG_POLAR_API_BASE = https:/$()/api.polar.sh` is already production (plan 03 Task 8); leave it. xcconfig treats `//` as a comment, so write URLs as `https:/$()/…`:

  ```text
  TG_POLAR_ORGANIZATION_ID = <POLAR_ORGANIZATION_ID value — public by design, D16>
  TG_POLAR_CHECKOUT_URL_MARKDOWN = <POLAR_CHECKOUT_URL_MARKDOWN with https:/$()/>
  TG_POLAR_PORTAL_URL = <POLAR_PORTAL_URL with https:/$()/>
  TG_POLAR_BENEFIT_ID_MARKDOWN = <POLAR_BENEFIT_ID_MARKDOWN value — public by design>
  ```

  Then build Release (`make build` is Debug): `xcodegen generate && xcodebuild -project Tegel.xcodeproj -scheme markdown -configuration Release -derivedDataPath build build`.

  Expected, after `set -a; . ./.env; set +a` and with `APP="build/Build/Products/Release/Tegel Markdown.app"`:
  - `grep -c REPLACE_IN_PLAN_05 Config/Release.xcconfig` → `0`;
  - `/usr/libexec/PlistBuddy -c 'Print :TGPolarAPIBase' "$APP/Contents/Info.plist"` → `https://api.polar.sh`;
  - `[ "$(/usr/libexec/PlistBuddy -c 'Print :TGPolarBenefitID' "$APP/Contents/Info.plist")" = "$POLAR_BENEFIT_ID_MARKDOWN" ] && echo benefit-ok` → `benefit-ok`;
  - `grep -c sandbox Config/Release.xcconfig` → `0`.
- [ ] **Step 10: Commit.**

```bash
git add .env.example Config/Release.xcconfig docs/gates/evidence/1.0/polar
git commit -m "chore(release): point Release config at Polar production

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 11 (Tue 1 Dec, after H5 is verified): BNPL check [F3g].** Open `POLAR_CHECKOUT_URL_MARKDOWN` in Safari (Apple Pay set up) and in Chrome. Then set the billing country to Netherlands, then United States. **Do not pay.**
  - Screenshot each payment section to `polar/checkout-{safari,chrome}-{nl,us}.png`.
  - Expected: no Klarna, Afterpay/Clearpay, Affirm, "pay later" or "pay in N instalments". Cash App Pay is a wallet, not BNPL; record it if shown.
  - **If BNPL appears:** stop launch prep, tell the user, and ask Polar support to remove it. Lemon Squeezy is the fallback (§13 risk 7, user decision).
- [ ] **Step 12 (Tue 1 Dec): Live status.** Confirm the dashboard shows payouts verified (H5 done) and a fresh checkout shows **$14.00**. Commit the screenshots (`git add docs/gates/evidence/1.0/polar`, message `docs(release): Polar live evidence` + trailer).

### Task 3: Test matrix 1.0 (RC1 Wed 25 – Fri 27 Nov; Scaleway lease L2 Thu 26 Nov 09:00 → Fri 27 Nov 09:00)

**Files:**
- Create: `docs/gates/test-matrix-1.0.md`, `docs/gates/evidence/1.0/{m15-intel,m14-arm,m15-arm,m26-arm,m27-arm}/…`

**Interfaces:**
- Consumes:
  - Task 1's `smoke-dmg.sh` and `smoke.yml`;
  - Task 2's production values and `POLAR_QA_LICENSE_KEY`;
  - plan 03's `release.sh` and its b1 → b2 update procedure (the "previous build").

**Matrix template.** Write this into `docs/gates/test-matrix-1.0.md`.
- **Cell values:** `PASS <evidence path>`, `FAIL #<issue>`, `auto <evidence>` (scripted on a runner) or `—` (not run there, with the reason in the notes).
- **Screenshots:** downscaled with `sips -Z 1280` before commit.

| Row | Check | m15-intel (build Mac) | m14-arm (GH) | m15-arm (GH) | m26-arm (GH) | m27-arm (Scaleway) |
|---|---|---|---|---|---|---|
| R1 | DMG install + Gatekeeper first launch (quarantined) | manual + smoke | smoke | smoke | smoke | manual + smoke |
| R2 | Enable the Quick Look extension in System Settings | manual | `pluginkit` only | `pluginkit` only | `pluginkit` only | manual |
| R3 | Quick Look on each fixture (12 committed + `g0-1mb.md`) | manual | auto (12) | auto (12) | auto (12) | manual |
| R4 | Single-file window | manual | auto | auto | auto | manual |
| R5 | Folder mode + live reload + search (Pro) | manual | — | — | — | manual |
| R6 | PDF A4 and Letter with `rtl-arabic.md` (Pro) | manual | — | — | — | manual |
| R7 | Themes paper/ink/studio × light/dark (Pro) | manual | — | — | — | manual |
| R8 | Arabic UI (`-AppleLanguages '(ar)'`) | manual | auto | auto | auto | manual |
| R9 | Licence activate / offline relaunch / 3rd-Mac 403 / deactivate | manual | — | — | — | manual |
| R10 | Sparkle update from the previous build | manual | — | — | — | manual |
| R11 | Copy Diagnostics | manual | — | — | — | manual |

Notes the doc must carry:
- `—` on GitHub runners: no GUI interaction or licence there. R5–R7 on arm64 15/26 are covered only by the `swift test` runs of `ci.yml`; link the run id. Never call that "tested by hand".
- **macOS 14 manual column:** only if Scaleway's OS list offers macOS 14. Then reinstall the *same* leased M1 as the last item on lease L2, after the macOS 27 work of plans 05, 03, 02 and 08. It costs nothing extra (check step on lease day).
- **If `macos-14` has been retired** from GitHub's runner images [F7], record `n/a: image retired`.

**Steps:**

- [ ] **Step 1: Price-string check** (Contract change request 5). `grep -rnE '\$ ?1[49]\b' Apps/Markdown || echo "no price in app"`. Expected: `no price in app`. A hit means 15 Dec would need an app release, so raise it before RC1.
- [ ] **Step 2: Build RC1 and store it privately.**
  - `scripts/release.sh markdown 1.0.0-rc1 --no-upload`; DMG = the last stdout line.
  - `gh release create v1.0.0-rc1 "$DMG" --prerelease --title "1.0.0-rc1 (internal)" --notes "internal test build"`. The repo is private, so this is not an outward action.
  - Expected: `gh release view v1.0.0-rc1 --json assets -q '.assets[].name'` lists the DMG.
- [ ] **Step 3: Runner smoke.**
  - **CI minutes first** (the repo is private; there is no payment method, so an exhausted quota blocks runs). Read the minutes used: `gh api /users/Frequence-xx/settings/billing/usage --jq '[.usageItems[] | select(.product=="actions")]'` (sum `quantity` for the current month), or the billing page at github.com/settings/billing for the free quota. Record both numbers here. If the remainder can't cover one 3-runner run (about 30 macOS minutes, times the macOS multiplier if one applies), stop and tell the user. Never add a payment method. Each dispatch is one matrix run, never one per push. Repeat this read before every later `gh workflow run smoke.yml` (Task 9 1.0.1, Task 10 Step 14).
  - `gh workflow run smoke.yml -f tag=v1.0.0-rc1`, then `gh run watch`, then `gh run download <run-id> -D docs/gates/evidence/1.0/gh`.
  - Expected: `smoke.txt` on each runner has 5 `PASS` lines and no `FAIL`.
  - Move each runner's files into `m14-arm/`, `m15-arm/` and `m26-arm/`.
  - If a Quick Look screenshot is black (headless session), mark R3 `—` for that runner with the reason.
- [ ] **Step 4: Build Mac, R1–R11 manual pass** (`m15-intel`). Steps per row:
  - **R1:** download the DMG through Safari from the private release, so it gets the quarantine flag. Open it, drag to Applications, first launch. Expected: the standard "downloaded from the Internet" prompt naming Apple-checked software, and the app opens. Also run `bash scripts/smoke-dmg.sh <dmg> docs/gates/evidence/1.0/m15-intel/smoke`: 5 `PASS`.
  - **R2:** screenshot the System Settings path that enables the extension. This exact path becomes the FAQ text in Task 4. Also click the Welcome window's `Open System Settings` button (`QuickLookSetup.settingsURL`) and screenshot where it lands as `R2-deeplink.png`; plan 08 Task 11 Step 2 reads it for `m15-intel`, `m27-arm` and `m14-arm`.
  - **R3:** Space on each fixture in Finder. Expected:
    - `hostile.md`: no script runs, no navigation;
    - `mermaid-broken.md`: one error box, the rest renders;
    - `empty.md`: no hang;
    - `g0-1mb.md`: renders within the G0 bound.
  - **R5:** open a folder copied from `Fixtures/markdown`. `echo '## added' >> <copy>/mixed-bidi.md` updates the view without a manual reload. A search for a word from `rtl-hebrew.md` finds it.
  - **R6:** export A4 and Letter.
    - Expected: `mdls -name kMDItemPageWidth -name kMDItemPageHeight <pdf>` → ≈595×842 for A4, 612×792 for Letter (points; if Spotlight hasn't indexed it yet, open it in Preview and screenshot the inspector).
    - Arabic paragraphs read right-to-left and code stays left-to-right (screenshot).
  - **R7:** 6 screenshots: 3 themes × light/dark.
  - **R8:** screenshot the Arabic UI.
  - **R9:**
    1. Paste `POLAR_QA_LICENSE_KEY` with a trailing newline. Expected: Pro.
    2. Add `0.0.0.0 api.polar.sh` to `/etc/hosts`, run `sudo dscacheutil -flushcache`, then quit and relaunch. Expected: still Pro. Remove the line afterwards.
    3. Leave this Mac activated for the 403 test in Step 5.
  - **R10:** install plan 03's previous build, then Check for Updates via plan 03's test feed. Expected: About shows `1.0.0-rc1`.
  - **R11:** Copy Diagnostics, then `pbpaste > m15-intel/R11.txt`.
    - Expected: it contains the app version and `x86_64`.
    - `grep -cF "$POLAR_QA_LICENSE_KEY" R11.txt` → `0`.
    - `grep -c '/Users/' R11.txt` → `0`.
- [ ] **Step 5: Scaleway lease L2 (`m27-arm`), H6.**
  - **Ask the user first:** "Lease one Scaleway M1 for 24 h, Thu 26 Nov 09:00 → Fri 27 Nov 09:00, macOS 27, at €3.19 incl. VAT (€2.64 before tax) [F9]?" Record the approval here.
  - **L2 is shared, in this order:** (1) this plan's matrix on macOS 27; (2) plan 03's arm64/macOS 27 acceptance with b2; (3) plan 02's pending arm64 checks; (4) plan 08's Quick Look deep-link check; (5) **last:** reinstall macOS 14 if offered, then the macOS 14 leg.
  - **Operator:**
    - SSH parts: Claude via `REMOTE_MAC_*`;
    - GUI rows: the user over Screen Sharing, or Claude through the computer-use skill driving Screen Sharing on the build Mac.
  - **Run:** `scp` the DMG and `Fixtures/` over. Run `smoke-dmg.sh`, then R1–R11 as in Step 4.
  - **R9 extra:** with both Macs activated, the call below returns `403` [F3a]. Then deactivate on both Macs. Expected: the customer portal shows 0 activations (screenshot).

    ```bash
    curl -s -o /dev/null -w '%{http_code}\n' -X POST \
      https://api.polar.sh/v1/customer-portal/license-keys/activate \
      -H 'Content-Type: application/json' \
      -d "{\"key\":\"$POLAR_QA_LICENSE_KEY\",\"organization_id\":\"$POLAR_ORGANIZATION_ID\",\"label\":\"qa-third\"}"
    ```

  - **Last, before the lease ends:** after items (2)–(4), if macOS 14 is offered, reinstall and repeat R1–R4, R8 and R9 (`m14-arm` manual cells).
  - **Release the lease by Fri 27 Nov 09:00 and confirm with the user:** the Scaleway console shows no running server.
- [ ] **Step 6: Each FAIL becomes a fix.**
  - Open `gh issue create --label bug,1.0.0`.
  - Fix it on `m05-launch` using superpowers:systematic-debugging, then superpowers:test-driven-development (failing test in the layer that owns the bug, then PASS).
  - Rebuild as `1.0.0-rc2` (Step 2) and re-run that row. After the lease, arm64 re-checks run on GitHub runners only; say so in the cell.
- [ ] **Step 7: Matrix green.** No `FAIL` cells remain: `grep -cE 'FAIL #[0-9]+' docs/gates/test-matrix-1.0.md` → `0` (an open issue cell). Commit:

```bash
git add docs/gates/test-matrix-1.0.md docs/gates/evidence/1.0
git commit -m "docs(gates): test matrix 1.0 with per-machine evidence

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 4: Support pages, templates and support log (Fri 27 – Mon 30 Nov)

**Files:**
- Modify: `site/content/en/faq.md` (plan 04 Task 12's FAQ shell, served at `/faq/`)
- Create: `docs/ops/support-templates.md`, `docs/ops/support-log.md`

**Interfaces:**
- Consumes: plan 04's FAQ shell and its build; the R2/R9 screenshots for exact menu paths.

**Prerequisite:** read `DESIGN.md` (voice, §7 site values); no UI value outside it.

- [ ] **Step 1: Append to `faq.md`.** One `##` per question. Where the shell already asks a question (Quick Look, first launch, new Mac, refunds), complete that answer in place rather than adding a second one. The facts each answer must state:
  - **How do I activate Pro?**
    - The key is in the Polar receipt email.
    - Go to Tegel Markdown → Settings → Licence (use the menu path from the R9 screenshot), paste, Activate.
    - It works offline for 30 days after the last successful check.
  - **"Activation limit reached":** one licence covers 2 Macs. Deactivate the old Mac in the app, or in the customer portal (link `POLAR_PORTAL_URL`) if that Mac is gone, then activate again. No email needed.
  - **Gatekeeper:** Tegel Markdown is notarised by Apple.
    - On first launch macOS asks for confirmation because it was downloaded; click Open.
    - If macOS says the app is damaged, delete it and download it again from tegelapps.com.
  - **Enabling Quick Look:**
    - Open the app once.
    - Then use the exact System Settings path per macOS version, from the R2 screenshots (`m15-intel`, `m27-arm`, and `m14-arm` if tested).
    - Then select a `.md` file in Finder and press Space.
  - **Refunds:** 14 days, no questions asked. Reply to your receipt or email hello@tegelapps.com. The licence key is revoked when the refund is issued.
  - **Where does Tegel Markdown read files from?**
    - Only the files and folders you open, plus the file Quick Look previews and images next to it.
    - Read-only: it never changes your files; PDF export writes only where you choose.
    - Nothing is uploaded. The only network calls are licence checks to api.polar.sh and update checks to downloads.tegelapps.com.
    - No telemetry, no account.
  - **Contact:** hello@tegelapps.com, answered once a day. For bugs, use Help → Copy Diagnostics and paste the result into the email.
- [ ] **Step 2: Add `## Known issues` as the last section of `faq.md`** (anchor `/faq/#known-issues`, which plan 08's `llms.txt` links). Each entry is symptom → cause → fix. Include only entries reproduced in the matrix or listed here:
  - another Markdown Quick Look extension takes precedence (disable it in the same Settings pane; `qlmanage -r && qlmanage -r cache`);
  - the extension stays missing until the app is moved to Applications and opened once;
  - files over 5 MB render truncated with a banner (by design);
  - iCloud Drive files that aren't downloaded show nothing in Quick Look until they are downloaded;
  - the PDF page count may be truncated on very long documents (Apple bug FB20581927 [F6]; only if R6 reproduced it).
- [ ] **Step 3: Build and check.** Run plan 04's site build. Expected:
  - `grep -c 'id="known-issues"' site/public/faq/index.html` → `1`;
  - the copy lint prints `COPY-LINT: clean`.
- [ ] **Step 4: Write `docs/ops/support-templates.md`.** Five templates: greeting, the body below, and a sign-off with the name chosen in H9.

  ```text
  REFUND — Subject: Your refund for Tegel Markdown
  I've refunded your order in full; it shows on your statement within 5–10 days, depending on your bank. Your licence key is now inactive. Thanks for trying Tegel Markdown.

  LIMIT REACHED — Subject: Moving your Tegel Markdown licence
  Your licence covers 2 Macs and both are in use. Open the customer portal (<POLAR_PORTAL_URL>), deactivate the Mac you no longer use, then activate on the new one. If a Mac is gone, the portal still lets you remove it.

  GATEKEEPER — Subject: Opening Tegel Markdown for the first time
  The app is notarised by Apple. Please download it again from https://tegelapps.com, drag it to Applications and open it from there. If macOS still blocks it, send me a screenshot of the message and your macOS version.

  QUICK LOOK NOT SHOWING — Subject: Turning on the Quick Look preview
  Open Tegel Markdown once from Applications, then enable it under <Settings path for their macOS, from the FAQ>. If another Markdown previewer is installed, switch that one off. Then run `qlmanage -r` in Terminal and press Space on a .md file again.

  BUG REPORT REQUEST — Subject: Re: <their subject>
  Thanks for reporting this. Could you send: (1) Help → Copy Diagnostics, pasted into a reply; (2) the steps that trigger it; (3) if the app crashed, the newest "Tegel Markdown" file in ~/Library/Logs/DiagnosticReports. A sample .md file helps if you can share it — only if it holds nothing private.
  ```

- [ ] **Step 5: Write `docs/ops/support-log.md`.**
  - **Routine:** once a day at 10:00 CET; target ≤ 20 min. Log **every** day, including `0`, so the average is honest.
  - **Buyer sync:** from Wed 9 Dec, once plan 08 Task 14 Step 7 has activated the lifecycle automation, the routine also runs `set -a; . ./.env; set +a; python3 scripts/sync_buyers.py --product markdown --days 3`.
  - **Table:** `| date | minutes | mails | refunds | licence | bug/feature | notes |`.
  - **Gates:**
    - §12 support gate: > 30 min/day averaged over 14 days → fix the docs or raise the price **before any new feature**;
    - §6.4 test: 30-day average > 20 min/day → fix the docs.
  - **Check command:**

    ```bash
    grep -E '^\| 20[0-9]{2}-' docs/ops/support-log.md | tail -14 | awk -F'|' '{s+=$3;n++} END{printf "avg %.1f min/day over %d days\n", s/n, n}'
    ```
- [ ] **Step 6: Commit.** `git add site/content/en/faq.md docs/ops/support-templates.md docs/ops/support-log.md`, message `docs(support): FAQ, known issues, reply templates, support log` + trailer.

### Task 5: Silent demo video, screenshots, PH gallery (Fri 27 – Mon 30 Nov)

**Files:**
- Create: `docs/launch/demo/storyboard.md`, `docs/launch/demo/captions/{01..08}.png`, `docs/launch/demo/captions.filter`, `site/static/media/tegel-markdown-demo.{mp4,webm}`, `site/static/media/tegel-markdown-demo-poster.png`, `site/static/img/app1-{quicklook,folder-mermaid,rtl-pdf,themes}-{light,dark}.png`, `docs/launch/ph-gallery/{01..04}-*.png`, `docs/launch/ph-gallery/thumb-240.png`

**Prerequisite:** read `DESIGN.md`; no UI value outside it. Captions, gallery frames and screenshots follow plan 09 Task 12 and its m05 gate (DESIGN.md §12).

- [ ] **Step 1: Check the tools.** The installed `ffmpeg` has no `drawtext` (plan 09 [V18]), so captions are PNG bands composited with `pad` + `overlay`.
  - Plan 09 Task 12 has merged: `ls docs/design/templates/caption.html docs/design/templates/gallery.html scripts/window-shot.sh | wc -l` → `3`.
  - `ffmpeg -hide_banner -filters | awk '$2=="overlay"||$2=="pad"' | wc -l` → `2`.
  - `B=~/.claude/skills/gstack/browse/dist/browse; test -x "$B" && echo browse-ok` → `browse-ok`.
- [ ] **Step 2: Write `storyboard.md`** (≤ 60 s; each caption is one line of plain text, rendered as a band by plan 09's `caption.html`):

| t (s) | Shot | Caption |
|---|---|---|
| 0–7 | Finder, repo folder, select `README.md`, Space → Quick Look with a Mermaid diagram | Press Space in Finder to read Markdown and Mermaid |
| 7–14 | Space on `docs/notes-ar.md` | Right-to-left text renders the right way |
| 14–23 | App → Open Folder → sidebar lists README, CLAUDE.md, AGENTS.md, docs/ | Open a whole repo and see every .md file |
| 23–31 | Search a word → hits across files → click one | Search across all documents |
| 31–39 | Terminal (text only) appends a line → view updates | Changes from your editor or agent appear live |
| 39–50 | Export PDF A4 of the Arabic note → Preview shows pages | Paginated A4 and Letter PDF, right-to-left correct |
| 50–57 | Theme switch paper → ink → studio, then dark | Three themes, light and dark |
| 57–60 | Plain end card: icon tile + text | Tegel Markdown · tegelapps.com |

No price in the video, so it never goes stale.

**Demo folder** (scratch, not committed), built from fixtures (§3.4: neutral prose, no Qur'an or hadith): `gfm-kitchen-sink.md`→`README.md`, `mermaid-basic.md`→`CLAUDE.md`, `mixed-bidi.md`→`AGENTS.md`, `rtl-arabic.md`→`docs/notes-ar.md`, `rtl-hebrew.md`→`docs/notes-he.md`.
- [ ] **Step 3: Prepare the screen** (checklist in `storyboard.md`). Expected: one screenshot of the empty desktop, reviewed by the user for faces.
  - solid grey wallpaper;
  - Dock hidden (`defaults write com.apple.dock autohide -bool true; killall Dock`);
  - Focus/Do Not Disturb on;
  - no user picture in the menu bar or Finder sidebar;
  - no browser windows.
- [ ] **Step 4: Record.** `screencapture -v -k -x -R0,0,1536,960 ~/tegel-demo-raw.mov` (16:10; plan 09's demo frame scales it to 1536×960). Never pass `-g`/`-G` (audio). QuickTime screen recording with the microphone set to None also works. Terminal needs the Screen Recording permission; the app doesn't.
- [ ] **Step 5: Render the caption bands and write `captions.filter`.**
  - One 1920×120 band per storyboard row, `01.png` … `08.png`, from plan 09's `caption.html` (DESIGN.md type and colours). URL-encode each caption with `python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1]))' "<caption>"`:

    ```bash
    $B viewport 1920x120 && $B goto "file://$PWD/docs/design/templates/caption.html?text=<encoded caption>&dir=ltr" \
     && $B screenshot docs/launch/demo/captions/<NN>.png --clip 0,0,1920,120
    ```

    Expected: `sips -g pixelWidth -g pixelHeight docs/launch/demo/captions/*.png` → 8 files, all 1920×120.
  - `captions.filter` is plan 09's demo frame (Task 12 Step 4). The recording is scaled to 1536×960 and padded onto a 1920×1080 #F5F5F7 canvas. Band N (input N) is then overlaid at y 960 for its row's time range:

    ```text
    [0:v]scale=1536:960:force_original_aspect_ratio=decrease,pad=1920:1080:(1920-iw)/2:0:color=0xF5F5F7[v0];
    [v0][1:v]overlay=0:960:enable='between(t,0,7)'[v1];
    [v1][2:v]overlay=0:960:enable='between(t,7,14)'[v2];
    [v2][3:v]overlay=0:960:enable='between(t,14,23)'[v3];
    [v3][4:v]overlay=0:960:enable='between(t,23,31)'[v4];
    [v4][5:v]overlay=0:960:enable='between(t,31,39)'[v5];
    [v5][6:v]overlay=0:960:enable='between(t,39,50)'[v6];
    [v6][7:v]overlay=0:960:enable='between(t,50,57)'[v7];
    [v7][8:v]overlay=0:960:enable='between(t,57,60)'[out]
    ```
- [ ] **Step 6: Encode.** Audio stripped with `-an`:

```bash
FC="$(cat docs/launch/demo/captions.filter)"
CAP=(); for f in docs/launch/demo/captions/0*.png; do CAP+=(-loop 1 -t 60 -i "$f"); done
ffmpeg -i ~/tegel-demo-raw.mov "${CAP[@]}" -filter_complex "$FC" -map '[out]' -an -t 60 -r 30 -c:v libx264 -crf 26 -preset slow -pix_fmt yuv420p -movflags +faststart site/static/media/tegel-markdown-demo.mp4
ffmpeg -i ~/tegel-demo-raw.mov "${CAP[@]}" -filter_complex "$FC" -map '[out]' -an -t 60 -r 30 -c:v libvpx-vp9 -crf 36 -b:v 0 -row-mt 1 site/static/media/tegel-markdown-demo.webm
ffmpeg -ss 2 -i site/static/media/tegel-markdown-demo.mp4 -frames:v 1 site/static/media/tegel-markdown-demo-poster.png
```

- [ ] **Step 7: Verify the media.** For both files, expected:
  - `ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 <file>` prints **nothing** (no audio stream);
  - `ffprobe -v error -show_entries format=duration -of csv=p=0 <file>` ≤ `60.0`;
  - `stat -f %z` → mp4 ≤ 6,000,000 and webm ≤ 5,000,000 bytes (raise `-crf` by 2 and re-encode if over);
  - `ffprobe -v error -select_streams v -show_entries stream=width,height -of csv=p=0 <file>` → `1920,1080`;
  - watching it once confirms the captions are readable, sit in the band and never over UI, and no face appears.
- [ ] **Step 8: Screenshots.**
  - **Site shots** (plan 04 CR-6: 2×, light and dark, Fixtures documents only): `scripts/window-shot.sh <owner> site/static/img/app1-<subject>-<light|dark>.png` (plan 09; native window shadow). Subjects are `quicklook` (owner `qlmanage`, via `qlmanage -p`), `folder-mermaid` and `themes` (owner `Tegel Markdown`) and `rtl-pdf` (owner `Preview`).
  - **PH gallery** (verified 27 Oct at producthunt.com/launch/preparing-for-launch: "recommended size for images in the gallery is 1270x760", thumbnail "240x240" square, images "under 3MB", "2+ images" required). Render each one from plan 09's `gallery.html`, with a caption of ≤ 48 characters and `img` relative to `docs/design/templates/`:

    ```bash
    $B viewport 1270x760 && $B goto "file://$PWD/docs/design/templates/gallery.html?img=../../../site/static/img/app1-quicklook-light.png&caption=<encoded caption>&scheme=light&dir=ltr" \
     && $B screenshot docs/launch/ph-gallery/01-quicklook.png --clip 0,0,1270,760
    ```

    - Repeat for `02-folder-mermaid.png`, `03-rtl-pdf.png` and `04-themes.png`.
    - `sips -s format png -z 240 240 "/Applications/Tegel Markdown.app/Contents/Resources/AppIcon.icns" --out docs/launch/ph-gallery/thumb-240.png` (the compiled icon of the installed RC).
  - Expected:
    - `ls site/static/img/app1-*-light.png site/static/img/app1-*-dark.png | wc -l` → `8`;
    - `sips -g pixelWidth -g pixelHeight docs/launch/ph-gallery/0*.png` → all 1270×760;
    - thumbnail 240×240;
    - `stat -f %z docs/launch/ph-gallery/*.png` all < 3,000,000.
- [ ] **Step 9: Commit.** `git add docs/launch/demo docs/launch/ph-gallery site/static/media site/static/img`, message `docs(launch): silent captioned demo, screenshots, PH gallery` + trailer.
- [ ] **Step 10: Coordinate with plan 04.**
  - [ ] Plan 04's home or product page embeds `/media/tegel-markdown-demo.webm` and `.mp4` with `muted playsinline` and the poster.
  - [ ] Plan 04 uses the 8 `/img/app1-*.png` screenshots.

### Task 6: Sales counter `scripts/polar_sales.py` (Tue 1 Dec)

**Files:**
- Create: `scripts/polar_sales.py`, `scripts/test_polar_sales.py`
- Modify: `Makefile` (add `test-scripts` to `check`)

**Interfaces:**
- API: `GET https://api.polar.sh/v1/orders/`, scope `orders:read`.
  - Query: `organization_id`, `product_id`, `created_after`, `created_before` (date-time), `page`, `limit` ≤ 100.
  - Response: `{items: [Order], pagination: {total_count, max_page}}`.
  - `Order.status` ∈ `draft|pending|paid|refunded|partially_refunded|void`; `net_amount` is in cents; `product_id`.
  - Verified 27 Oct at polar.sh/docs/api-reference/orders/list.md.
- Produces:
  - `window(start: str, end: str) -> tuple[str, str]`: `YYYY-MM-DD` dates at 00:00 Europe/Amsterdam → UTC ISO strings ending `Z`; `end` is exclusive.
  - `count_sales(orders: list[dict], product_id: str) -> dict[str, int]` with keys `sales`, `refunded`, `free`. Rules:
    - only orders whose `product_id` matches count at all;
    - `status` in `paid`/`partially_refunded` with `net_amount > 0` → `sales`;
    - `refunded` → `refunded`;
    - `net_amount == 0` → `free`;
    - anything else is ignored.
  - `fetch_orders(token: str, org_id: str, product_id: str, after: str, before: str) -> list[dict]`: pages until `page > pagination.max_page`.
  - CLI: `python3 scripts/polar_sales.py --from YYYY-MM-DD --to YYYY-MM-DD`.
    - Reads env `POLAR_ACCESS_TOKEN`, `POLAR_ORGANIZATION_ID`, `POLAR_PRODUCT_ID_MARKDOWN`; exits 2 naming any missing key.
    - Prints `sales=<n> refunded=<n> free=<n> from=<date> to=<date>`. Never prints the token.

- [ ] **Step 1: Write failing tests.** `scripts/test_polar_sales.py` (unittest):

```python
P = "prod-md"
def o(status, net, pid=P): return {"status": status, "net_amount": net, "product_id": pid}

# class PolarSalesTests(unittest.TestCase), importing count_sales and window from polar_sales
def test_count_sales_rules(self):
    orders = [o("paid", 1400), o("partially_refunded", 1400), o("refunded", 1400),
              o("paid", 0), o("paid", 1900, pid="other"), o("pending", 1400), o("void", 1400)]
    self.assertEqual(count_sales(orders, P), {"sales": 2, "refunded": 1, "free": 1})

def test_window_is_cet_midnight_end_exclusive(self):
    self.assertEqual(window("2026-12-08", "2027-01-07"),
                     ("2026-12-07T23:00:00Z", "2027-01-06T23:00:00Z"))
```

- [ ] **Step 2: Run them.** `python3 -m unittest discover -s scripts -p 'test_polar_sales.py' -v`. Expected: FAIL (`ModuleNotFoundError: No module named 'polar_sales'`).
- [ ] **Step 3: Implement `scripts/polar_sales.py`** with the three functions and the CLI above.
  - `urllib.request` with headers `Authorization: Bearer …`, `Accept: application/json`, `User-Agent: tegel-scripts`.
  - `zoneinfo.ZoneInfo("Europe/Amsterdam")` for `window`.
- [ ] **Step 4: Run them again.** Same command. Expected: `OK` (2 tests).
- [ ] **Step 5: Live wiring check.** `set -a; . ./.env; set +a; python3 scripts/polar_sales.py --from 2026-11-20 --to 2026-12-08`. Expected: `sales=0 refunded=0 free=1 …` (the QA order from Task 2 Step 7).
- [ ] **Step 6: Put the script tests in `make check`** (stage 2 must cover them; plan 08's `test_kpi.py` and `test_sync_buyers.py` are picked up by the same discover). Add this target (recipe line starts with a tab) and append `test-scripts` to `check`'s prerequisites:

  ```make
  test-scripts:
  	python3 -m unittest discover -s scripts -p 'test_*.py' && bash scripts/test-smoke-dmg.sh
  ```

  Expected: `make test-scripts` prints `OK`, then `test-smoke-dmg: PASS`; `make -n check | grep -c 'test-smoke-dmg'` → `1`.
- [ ] **Step 7: Commit.** `git add scripts/polar_sales.py scripts/test_polar_sales.py Makefile`, message `feat(ops): count paid Polar sales in a CET window for gates` + trailer.

### Task 7: Scholar and tax-adviser messages, KvK number (H8 this week, W1; H10 by Fri 13 Nov; H7)

**Files:**
- Create: `docs/ops/advisers.md`

**Branch:** `main` (docs only), because H8 goes out in W1, before `m05-launch` exists.

- [ ] **Step 1: Write `docs/ops/advisers.md`** with the three sections below plus a "Sent / answered" line under each.

**H8: scholar (send this week, W1; English):**

```text
Subject: Three questions on selling a software licence

Assalamu alaikum. I am starting a one-person business selling small Mac apps (developer tools that display Markdown and data files; read-only, no ads, no music, no imagery of living beings). Buyers pay once ($19; $14 introductory until 14 Dec 2026) for a perpetual licence on 2 computers. Polar (a US company) sells the licence as merchant of record — it is the legal seller to the customer and pays me out via Stripe to a Dutch bank account. I offer a voluntary 14-day refund. Buy-now-pay-later options are not offered.

1. Selling general-purpose software that buyers may use for any purpose: is the usual "the tool is mubah; the user bears responsibility" ruling sufficient?
2. Is a perpetual software licence sold through an MoR acting as reseller a valid sale of a usage right (bay' al-manfa'a), and is a 14-day voluntary refund fine?
3. Stripe/Polar payout balances earn no interest; please confirm nothing else in the payout chain is riba-bearing.

JazakAllahu khairan.
```

**H10: tax adviser (by Fri 13 Nov; Dutch):**

```text
Onderwerp: Btw en vennootschapsbelasting voor softwareverkoop via Polar (Baksh Logistics B.V.)

Baksh Logistics B.V. (KvK 85272248) gaat vanaf december 2026 naast de bestaande activiteiten Mac-software verkopen onder de handelsnaam Tegel. Polar (VS) is merchant of record: Polar verkoopt aan consumenten wereldwijd en betaalt de BV uit. Later mogelijk ook via de Mac App Store en Setapp (MacPaw). Verwachte omzet jaar 1: laag (schatting < €5.000).
1. De levering aan Polar (niet-EU ondernemer): klopt het dat hierover geen Nederlandse btw verschuldigd is, en moet dit in de aangifte (zo ja, in welke rubriek)? Hoe zit het met verlegde btw over de Polar-fees (rubriek 4a)?
2. Hoe worden de Mac App Store (Apple's Europese contractpartij) en Setapp (MacPaw; contractpartij nog te controleren) voor de btw behandeld?
3. Het Apple Developer-lidmaatschap (€99/jaar) staat op naam van de directeur als individu, maar is gefactureerd aan en betaald door de BV. Is dat aftrekbaar voor de BV, of moet het lidmaatschap op naam van de BV (organisatie) staan?
4. Moet de softwareomzet administratief gescheiden worden van de verhuisactiviteiten (aparte omzetgroep/kostenplaats volstaat?)
5. Welke administratie wilt u van ons (Polar-uitbetalingsrapporten, facturen)?
```

**H7: KvK number (existing registration):**
- [ ] The number comes from the user's existing KvK registration (public, not a secret). Check: `grep -cE '^KVK_NUMBER=.+' .env` → `1`; if it's `0`, ask the user for it. Plan 04 puts it in `site/config.json` for the imprint.

- [ ] **Step 2 (user): Send.**
  - H8 **this week (W1, by Fri 30 Oct)**; the user sends it, and Claude never emails on their behalf.
  - H10 by **Fri 13 Nov**.
  - Record the dates in the file.
  - An H8 answer that requires a change becomes a P0 for this plan.
- [ ] **Step 3: Commit.** `git add docs/ops/advisers.md`, message `docs(ops): scholar and tax-adviser messages, KvK number check` + trailer.

### Task 8: Launch kit drafts (Wed 2 – Fri 4 Dec; H9)

**Files:**
- Create: `docs/launch/app1-posts.md`

**H9 decisions, recorded at the top of the file by the user:**
- [ ] PH maker account (profile picture = the tile, not a face).
- [ ] Reddit account and r/macapps path: main feed (needs the trust/transparency qualification, rule 8) or the monthly megathread (default).
  - **Rule 3:** "You can't promote your own app in comments until you have 10 karma in r/MacApps", and a megathread entry is a comment. Record the account's r/MacApps karma.
- [ ] HN account; IH account.
- [ ] Sign-off name for posts and replies.

**No YouTube.** PH accepts video only as a YouTube link (preparing-for-launch page), but YouTube may monetise any upload, which would put ads around the demo (rule 8). PH shows the screenshot gallery only; the silent MP4 stays on the site.

- [ ] **Step 1: Write the file** with the sections below. Each section ends in `Approved: ____ (date, user)`.

**Product Hunt** (limits verified at producthunt.com/launch/preparing-for-launch: tagline max 60, description max 500, up to 3 launch tags, launch timed by the Pacific day):
- **Name:** `Tegel Markdown`
- **Tagline (52 chars):** `Markdown and Mermaid reader for Mac, with Quick Look`
- **Description (< 500):**

  ```text
  A native, read-only reader for the Markdown your AI agents and docs produce. Press Space in Finder for a Quick Look preview with Mermaid diagrams and correct right-to-left text (Arabic, Hebrew, Persian, Urdu). Free: Quick Look, single-file window, highlighting, Mermaid, RTL. Pro, one-time for 2 Macs: folder mode with search and live reload, paginated A4/Letter PDF, 3 themes. Introductory price $14 until Mon 14 Dec 2026 23:59 CET. From 15 Dec: $19.
  ```

- **Launch tags (3):** Mac, Developer Tools, Markdown. Check step: pick the nearest existing tags in the form.
- **Pricing field:** "Paid (with a free plan)".
- **Gallery:** `docs/launch/ph-gallery/01–04`; thumbnail `thumb-240.png`. No video (no YouTube).
- **Link:** plan 04's product page.
- **Schedule:** Tue 8 Dec **00:01 PT = 09:01 CET**.
- **First comment:**

  ```text
  Hi, I'm <sign-off>, the developer. I kept opening plans and specs from Claude Code and Codex in an editor just to read them, and Finder's preview showed raw text — and right-to-left documents came out mirrored or broken. Tegel Markdown is a reader only: it never writes to your files, sends no telemetry, and needs no account. The network is used for licence checks and updates, nothing else.
  Free covers Quick Look, the single-file window, Mermaid and RTL. Pro (one-time, 2 Macs) adds folder mode, PDF export and themes. Introductory price $14 until Mon 14 Dec 2026 23:59 CET. From 15 Dec: $19.
  I'd value feedback on two things: which Markdown files still render wrong for you, and what you'd want in folder mode next.
  ```

**r/macapps** (verified 27 Oct via the sidebar mirror [S³⁴]):
- Rules:
  - rule 1: no main-feed promotion unless you qualify; use the PCP template; flair hierarchy "Lifetime>Subscription>Free";
  - rule 3: one promotion per developer per 30 days, counted even if removed; always disclose the relationship; 10 r/MacApps karma before promoting in comments;
  - rule 8: otherwise the monthly Megathread;
  - rule 9: get post approval first.
- **Check step (Tue 1 Dec):** fetch the current PCP template from the subreddit (rules/wiki/post form) and map the fields below onto it.
- **Flair:** Lifetime. **Next promotion allowed:** 7 Jan 2027 or later (App 2 on 2 Feb is fine).
- **Title:** `Tegel Markdown – Markdown + Mermaid reader with Quick Look, RTL and paginated PDF`
- **Body fields:**
  - What it is: the PH description's first two sentences.
  - Free vs paid: as on PH.
  - Price: `$19 once, 2 Macs.` + the verbatim intro wording.
  - Privacy: read-only, no telemetry, no account; network only for licence and update checks.
  - Requirements: macOS 14+, Apple Silicon and Intel.
  - Disclosure: `I'm the developer.`
  - Link.

**Show HN** (verified at news.ycombinator.com/showhn.html: title begins "Show HN"; "make it easy for users to try your thing out, ideally without barriers such as signups"; "Please don't ask friends to upvote or comment"):
- **Title (75 chars):** `Show HN: Tegel Markdown – a read-only Markdown and Mermaid reader for macOS`
- **URL:** plan 04's product page. **Text:**

  ```text
  I built a small native reader for Markdown on macOS, mainly for the plans and specs coding agents leave in repos. It's a Quick Look extension plus a window app. You can try the free tier without signing up: download, open, press Space on a .md file.
  How it works: one renderer (markdown-it, highlight.js, DOMPurify, Mermaid with securityLevel 'strict') in a WKWebView under a CSP with no network access; the same page renders the window, Quick Look and a paginated PDF via NSPrintOperation. Block elements get dir="auto", so Arabic/Hebrew paragraphs render RTL while code stays LTR. The app is sandboxed and never writes to your files.
  Pro (one-time, 2 Macs) adds folder mode, PDF export and themes. Introductory price $14 until Mon 14 Dec 2026 23:59 CET. From 15 Dec: $19.
  I'd like to hear about files that render wrong, and about the Quick Look extension on macOS 26/27.
  ```

**Indie Hackers:**
- **Title:** `Launching a read-only Markdown reader for Mac on a €200 budget`
- **Body** (~150 words):
  - why (agent-written `.md` files, RTL gap);
  - stack;
  - the budget;
  - the public gate: "if it sells fewer than 10 copies in 30 days, I stop the SEO work and ship the second app anyway, since they share code";
  - the price wording verbatim;
  - a feedback ask.

**Press** (MacStories, 9to5Mac). Check step: take the current tips address from each site's contact page; don't guess. Sent Tue 8 Dec 15:30 CET; no embargo; a review licence via a single-use 100% code, only if they reply (🔒 approval).

```text
Subject: Tegel Markdown — a read-only Markdown + Mermaid reader with right-to-left PDF export (launching today)

Hi <name>, I'm <sign-off>, a solo developer in the Netherlands. Tegel Markdown launched today: a native Mac reader for Markdown with a Quick Look extension, Mermaid diagrams, correct right-to-left rendering (Arabic, Hebrew, Persian, Urdu) and paginated A4/Letter PDF export. It is read-only, sends no telemetry and needs no account. The free tier covers Quick Look and the single-file window; Pro is one-time for 2 Macs. Introductory price $14 until Mon 14 Dec 2026 23:59 CET. From 15 Dec: $19.
60-second silent demo and screenshots: <product page URL>. Happy to send a licence if you'd like to try Pro.
```

- [ ] **Step 2: Checks.**
  - `grep -cF 'Introductory price $14 until Mon 14 Dec 2026 23:59 CET. From 15 Dec: $19.' docs/launch/app1-posts.md` → ≥ `6` (PH description, first comment, r/macapps, HN, IH, press).
  - The copy lint → `COPY-LINT: clean`.
  - `printf %s "<tagline>" | wc -m` → ≤ 60.
  - The PH description passes the same test with ≤ 500.
- [ ] **Step 3: Approvals and setup.** The user approves each section; record the date in each `Approved:` line.
  - [ ] 🔒 **Thu 3 Dec:** schedule the PH launch for 8 Dec 00:01 PT (PH allows scheduling up to 1 month ahead).
  - [ ] 🔒 **Thu 3 Dec:** message the r/macapps mods for post approval (rule 9) with the draft.
- [ ] **Step 4: Commit.** `git add docs/launch/app1-posts.md`, message `docs(launch): App 1 launch post drafts` + trailer.

### Task 9: Runbooks: launch day, price change, post-launch (Thu 3 Dec)

**Files:**
- Create: `docs/launch/app1-runbooks.md`

- [ ] **Step 1: Write the launch-day runbook** (Tue 8 Dec, all times CET). U = user, C = Claude. 🔒 = approved action.

| Time | Who | Action | Done when |
|---|---|---|---|
| Mon 7 Dec 21:00 | C | Uptime check (below), `polar_sales.py` baseline, PH scheduled post visible in the maker dashboard | all `200`; screenshot |
| 08:30 | C | Uptime check; fresh checkout shows $14.00; download → `smoke-dmg.sh` on the public DMG | `200`s; 5 `PASS` |
| 09:01 | — | PH goes live (scheduled) | post URL recorded |
| 09:10 | U 🔒 | Post the approved PH first comment | comment URL |
| 09:30 | U 🔒 | Send the waitlist launch email (plan 08 Task 15) | sent |
| 10:00 | U + C | Support routine #1 (Task 4 log) | log row |
| 14:00 | U 🔒 | r/macapps post or megathread entry (approved path) | URL |
| 15:00 | U 🔒 | Show HN | URL |
| 15:30 | U 🔒 | Press emails (2) | sent |
| 16:00 | U 🔒 | Indie Hackers post | URL |
| 11:00–23:00, every 2 h | C | Monitoring checklist; draft replies to comments and mails for U to approve and post | checklist ticked |
| 23:00 | C | Record PH rank, `polar_sales.py --from 2026-12-08 --to 2026-12-09`, support minutes and post URLs under "Launch results" in `app1-posts.md` | section written |

**Uptime check:**

```bash
for u in https://tegelapps.com/ "$POLAR_CHECKOUT_URL_MARKDOWN" "<appcast URL = SUFeedURL>" "<public DMG URL>"; do printf '%s %s\n' "$(curl -s -o /dev/null -w '%{http_code}' -L "$u")" "$u"; done
```

Expected: every line starts with `200`. During launch week it can run on `/loop 30m`.

**Monitoring checklist:**
- [ ] Polar dashboard: new orders; any refund requests; failed payments.
- [ ] Support inbox (hello@ → the user's inbox, H3): U forwards or pastes; C drafts from the templates; U approves and sends.
- [ ] User-reported crashes: emails carrying Copy Diagnostics or `.ips` files → `gh issue create --label bug`. There's no telemetry, so this is the only crash channel.
- [ ] Uptime check is all `200`.
- [ ] Comments on PH, Reddit and HN: C drafts answers; U posts. No upvote requests anywhere.

- [ ] **Step 2: Write the price-change runbook** (Mon 14 → Tue 15 Dec):
  - [ ] **Mon 14 Dec, daytime:**
    - On plan 04 Task 15's branch `content/price-19`, set the single price source `site/config.json` (Contract change request 3): `apps.markdown.price` → `"19"`, `intro` → `false`. The pages and the JSON-LD `offers.price` read it.
    - Preview-deploy it.
    - Expected: `curl -s <preview URL>/markdown/ | grep -c 'Introductory'` → `0`; `curl -s <preview URL>/markdown/ | grep -c '"price":"19"'` → `1`.
  - [ ] **Mon 14 Dec:** the user approves in writing: "deploy `content/price-19` at 00:00 CET on 15 Dec, then change the Polar price of Tegel Markdown from $14 to $19". Record the approval.
  - [ ] **Reminder:** a calendar entry at **Mon 14 Dec 23:45 CET** (the user creates it). If the executing session offers `CronCreate`, also add a one-shot prompt at that time. Record which.
  - [ ] **00:00:** merge `content/price-19` into `main`, then run plan 04's production deploy (Task 15 Step 2). **Site first:** a site showing $19 while the checkout still says $14 never overcharges anyone.
  - [ ] **00:01, after the site is live:** Polar → Products → Tegel Markdown → price **USD 19.00** → save.
  - [ ] **00:05 verify, with a fresh checkout:**
    - a fresh private-window checkout shows **$19.00**; screenshot `docs/gates/evidence/1.0/polar/price-19.png`;
    - `curl -s -H "Authorization: Bearer $POLAR_ACCESS_TOKEN" https://api.polar.sh/v1/products/$POLAR_PRODUCT_ID_MARKDOWN | python3 -c 'import json,sys;print([p.get("price_amount") for p in json.load(sys.stdin)["prices"] if not p.get("is_archived")])'` → `[1900]`;
    - `curl -s https://tegelapps.com/ | grep -c 'Introductory'` → `0`;
    - `curl -s https://tegelapps.com/markdown/ | grep -c '"price":"19"'` → `1`.
  - [ ] **If 00:00 is missed:** a late switch in this order (site, then Polar, then a fresh checkout) is safe any time before **08:00 Tue 15 Dec**, so nobody has to be awake at midnight. Orders at $14 after midnight are lower than announced, which is not deceptive. Note them in the log.
  - [ ] Optional 🔒: edit the PH description and the r/macapps body to `$19 once, 2 Macs`. The dated wording stays true as history, so this is optional.
- [ ] **Step 3: Write the post-launch runbook** (W8–W9):
  - **Intake:** an email with Copy Diagnostics → `gh issue create --label bug`, with the severity in the title.
  - **Triage:**
    - **P0:** crash on open, licence lock-out of a paying user, any write to a user file, a sanitiser/CSP bypass. Fix within 24 h.
    - **P1:** a feature broken for a class of files. Goes in 1.0.1.
    - **P2:** backlog.
  - **Fix:**
    1. `git switch -c fix/1.0.1 main`.
    2. superpowers:systematic-debugging, then TDD.
    3. The **full** 9-stage pipeline, because code changed: Task 10 Steps 1–9 with `base=$(git merge-base HEAD main)`, plus Task 10 Step 10 (design review) when the diff touches UI. Results go under "1.0.1" in `docs/reviews/m05.md`.
    4. Merge and push.
  - **Release:**
    - `git tag -a v1.0.1 -m "1.0.1"`;
    - 🔒 `scripts/release.sh markdown 1.0.1`;
    - `curl -s "<SUFeedURL>" | grep -c '<sparkle:shortVersionString>1.0.1<'` → `1`;
    - on `m15-intel`, 1.0.0 → Check for Updates → About shows 1.0.1 (screenshot);
    - read the CI minutes (Task 3 Step 3), then `gh workflow run smoke.yml -f tag=v1.0.1` (after `gh release create v1.0.1 <dmg>` on the private repo) → 3 × 5 `PASS`.
  - **Close the loop:** reply to the reporters with "fixed in 1.0.1" (🔒 per reply).
- [ ] **Step 4: Check and commit.** `grep -cE '09:01|00:01|23:45' docs/launch/app1-runbooks.md` → ≥ `3`. Then `git add docs/launch/app1-runbooks.md`, message `docs(launch): launch-day, price-change and post-launch runbooks` + trailer.

### Task 10: 9-stage pipeline, merge, release 1.0.0 (Thu 3 – Mon 7 Dec)

**Files:**
- Create: `docs/reviews/m05.md`

**Template:** one `##` per stage with the commands run, the counts, findings (P0/P1/P2), fixes and cubic rounds.

- [ ] **Step 1: Stage 1, bloat audit (pre).**
  - `base=$(git merge-base HEAD main); git diff --stat $base...HEAD`.
  - Apply `~/.claude/skills/code-upgrade/bloat-audit.md` to the diff and the touched files.
  - Strip self-introduced bloat; queue pre-existing findings as questions for the user.
- [ ] **Step 2: Stage 2, baseline.** `git status --short` (clean), then `make check` (it includes `test-scripts`, Task 6). Record the pass/fail counts as the baseline.
- [ ] **Step 3: Stage 3, code review.** gstack `/review` (or a cold code-review subagent) on `git diff $base...HEAD`, prioritising bugs, security and correctness.
- [ ] **Step 4: Stage 4, security.** `/cso`, scoped to:
  - `Config/Release.xcconfig` (production ids only, no secrets, the `https:/$()/` form);
  - `.github/workflows/smoke.yml` (`permissions: contents: read`, no inline `${{ inputs.* }}` in `run:`; consider pinning actions to a SHA);
  - `scripts/polar_sales.py` (the token never printed or logged; HTTPS only);
  - `scripts/smoke-dmg.sh`;
  - `.env.example` (names only);
  - external URLs in `site/content/en/faq.md`;
  - the live Polar token scopes (`orders:read`, `products:read` only).

  Then a history scan: `git log -p $base..HEAD | grep -nE 'polar_[a-z]{2,4}_[A-Za-z0-9]{8,}|PRIVATE KEY|TEGEL-[A-Z0-9-]{8,}'`. Expected: no output.
- [ ] **Step 5: Stage 5, adversarial challenge.** `/codex` challenge mode on the same diff, plus Task 9's runbooks (ask: "how does this launch or price change mislead a buyer or fail?").
- [ ] **Step 6: Stage 6, consolidate.** Merge the findings, dedupe, classify P0/P1/P2, and decide what gets fixed. Record it in `m05.md`.
- [ ] **Step 7: Stage 7, patch and re-review.** Fix every P0/P1 and the actionable P2s (TDD where it's code), then re-run Step 2's commands. Expected: no regression against the baseline.
- [ ] **Step 8: Stage 8, bloat audit (post).** Same as Step 1, over the final cumulative diff.
- [ ] **Step 9: Stage 9, `/review` + cubic.** `/review`, then `cubic review -b $base -j` (JSON key `issues`). Repeat after each fix batch until **two consecutive rounds show no new P0/P1**. If a stage can't run, write which stage, why, and what ran instead.
- [ ] **Step 10: Design review** (DESIGN.md §12, gate m05; CLAUDE.md "Verification"). Run gstack `/design-review` on the 4 PH gallery PNGs, the OG image, 3 demo frames (`ffmpeg -ss <t> -i site/static/media/tegel-markdown-demo.mp4 -frames:v 1 <out>.png` at t = 3, 33, 45), the 8 `site/static/img/app1-*.png` (light and dark), the R8 Arabic UI shots, and the icon at 16/32/128/512 in Finder. Write `docs/reviews/design-m05.md` (Inputs, Findings P0/P1/P2, Guard output, Verdict). Expected: exact sizes; captions in the band, never over UI; no audio stream; every image a real capture; no P0/P1 open. Fix every P0/P1 in Task 5's files and re-run Task 5 Step 7.
- [ ] **Step 11: Merge and push** (D14 authorises pushing to this private repo):
  - commit `docs/reviews/m05.md` and `docs/reviews/design-m05.md` (`docs(reviews): m05 pipeline results` + trailer);
  - `git switch main && git merge --no-ff m05-launch -m "Merge m05-launch: release readiness and launch kit"`;
  - `git push origin main`;
  - `graphify update .`.
- [ ] **Step 12: Release pipeline for the 1.0.0 tag.**
  - `rel=$(git describe --tags --abbrev=0 --exclude '*-rc*')` (the last non-RC tag, from plan 03; `gh release create` adds `v1.0.0-rc*` tags).
  - Run stages 2, 3, 4 and 9 on `git diff $rel..HEAD`.
  - Run the **full** 9 stages if `git diff --stat $rel..HEAD -- Apps Packages Renderer scripts Config project.yml` is non-empty since the last milestone pipeline.
  - Append the results to `m05.md` under "Release 1.0.0", then commit and push.
- [ ] **Step 13: Tag and build (Mon 7 Dec).** `git tag -a v1.0.0 -m "Tegel Markdown 1.0.0" && git push origin v1.0.0`, then `scripts/release.sh markdown 1.0.0 --no-upload` → `$DMG`.
- [ ] **Step 14: Smoke the final build.** `gh release create v1.0.0 "$DMG" --title "1.0.0"` (private), read the CI minutes (Task 3 Step 3), then `gh workflow run smoke.yml -f tag=v1.0.0`. Expected: 3 runners × 5 `PASS`; `m15-intel` smoke also 5 `PASS`.
- [ ] **Step 15 🔒: Publish.** The user approves "publish Tegel Markdown 1.0.0 (DMG + appcast) to downloads.tegelapps.com". Then run `scripts/release.sh markdown 1.0.0`, which uploads. Expected:
  - the public DMG URL returns `200`;
  - `curl -s "<SUFeedURL>" | grep -c '<sparkle:shortVersionString>1.0.0<'` → `1`;
  - on `m15-intel`, the installed `1.0.0-rc1` → Check for Updates → About shows 1.0.0 (this is R10 against the production feed). The rc build number must be lower than 1.0.0's.
- [ ] **Step 16: Retire QA access.**
  - Revoke `POLAR_QA_LICENSE_KEY` in the dashboard; archive the `QA-INTERNAL` discount and its checkout link (🔒).
  - Remove the key from `.env`.
  - Expected: `grep -cE '^POLAR_QA_LICENSE_KEY=.+' .env` → `0`.

---

# Part B: launch and after (W7–W10, on `main` unless a task says otherwise)

### Task 11: Launch day (Tue 8 Dec)

- [ ] **Step 1:** Run the launch-day runbook (`docs/launch/app1-runbooks.md`) row by row and tick each row there.
- [ ] **Step 2:** "Launch results" in `docs/launch/app1-posts.md` has: post URLs, PH rank at 23:00, `sales=` for 8 Dec, and support minutes. Commit with `git add docs/launch/app1-posts.md docs/ops/support-log.md`, message `docs(launch): launch-day results` + trailer, then push.

### Task 12: Price change (Tue 15 Dec 00:00 CET)

- [ ] **Step 1:** Run the price-change runbook (site first, then Polar, then a fresh checkout). All four verifications pass: checkout `$19.00`, API `[1900]`, site `Introductory` count `0`, JSON-LD `"price":"19"` count `1`.
- [ ] **Step 2:** Copy lint over the live site: `curl -s https://tegelapps.com/ | grep -ciE 'introductory|\$14'` → `0`.
- [ ] **Step 3:** Commit `docs/gates/evidence/1.0/polar/price-19.png` (message `docs(release): price moved to $19 on 15 Dec` + trailer) and push.

### Task 13: Post-launch W8–W9: 1.0.1 and the support gate

- [ ] **Step 1: Daily, 8 Dec – 7 Jan.** Support routine at 10:00 CET; one log row per day; commit the log weekly (`docs(ops): support log week N` + trailer).
- [ ] **Step 2: Bugs.** For each P0/P1 issue, follow the post-launch runbook. If there are P0/P1 issues by **Fri 18 Dec**, ship 1.0.1 by **Tue 22 Dec**. If there are none, record "no 1.0.1 needed" in `docs/reviews/m05.md`.
- [ ] **Step 3: Support gate, Tue 22 Dec** (14 days, 8–21 Dec). Run the check command from Task 4.
  - Expected: `avg ≤ 20.0`, recorded in the log.
  - If > 30: write the docs fix (FAQ/known issues) or a price proposal for the user **before any new feature work** (§12).
- [ ] **Step 4: Hand-off.** Plan 06's W9 re-validation starts from the shipped TegelKit tag (`v1.0.0` or `v1.0.1`); give that tag to plan 06.

### Task 14: G1 (Thu 7 Jan 2027)

**Files:**
- Create: `docs/gates/G1.md`

- [ ] **Step 1: Count.** `set -a; . ./.env; set +a; python3 scripts/polar_sales.py --from 2026-12-08 --to 2027-01-07`, i.e. 30 days from 8 Dec 00:00 to 7 Jan 00:00 CET. Cross-check `sales` against the Polar dashboard order list for the same dates, excluding refunds. The two must match; any difference is explained in G1.md.
- [ ] **Step 2: Support gate.** Run the 30-day §6.4 average: the check command with `tail -30`.
- [ ] **Step 3: Write `docs/gates/G1.md`:**
  - date, command and output, the dashboard cross-check, `refunded` and `free` counts, and the support average;
  - the decision, worded exactly per BUSINESS-PLAN §12:
    - **≥ 30 paid sales:** continue.
    - **< 10:** stop the App 1 SEO work; ship App 2 anyway (it shares about 60% of the code). If App 2 also makes < 10 sales by **Thu 4 Mar 2027**, stop the studio.
    - **10–29:** §12 defines no action. Default: continue as scheduled and let G2 (Mon 8 Mar 2027) decide. The user may override; record their call.
- [ ] **Step 4: Follow-up reminder for Thu 4 Mar 2027.** Calendar entry (user), plus `CronCreate` if the session offers it. The reminder runs `polar_sales.py --from 2027-02-02 --to 2027-03-04` for App 2 (with App 2's product id), plus the App 1 figure from G1. Record in G1.md which reminder exists.
- [ ] **Step 5:** `git add docs/gates/G1.md`, commit `docs(gates): G1 result and decision` + trailer, push.

---

## Self-review notes

- **Spec coverage:**
  - test matrix (T3); support docs, templates, log (T4); demo, screenshots, PH gallery (T5);
  - Polar live at $14, BNPL, ids, Release.xcconfig, `release.sh` 1.0.0 (T2, T10);
  - KvK number check, H8, H10 (T7); launch kit, H9 (T8); runbooks (T9);
  - price change (T9, T12); 1.0.1 and intake (T9, T13); support gate (T4, T13); G1 and 4 Mar (T14); pipeline and merge (T10).
- **External facts verified 27 Oct:**
  - PH image, tagline and video rules: producthunt.com/launch/preparing-for-launch;
  - Polar orders list, product update (`PATCH /v1/products/{id}`), benefit properties, custom fields, payment methods: polar.sh/docs;
  - Show HN rules: news.ycombinator.com/showhn.html;
  - r/macapps rules 1/3/8/9 via the Redlib mirror [S³⁴]. reddit.com itself was not fetchable, and the PCP fields are a check step;
  - the local `ffmpeg` lacks `drawtext`, so captions are plan 09's PNG bands (plan 09 [V18]).
- **Still unverified, so they are check steps:**
  - whether Polar production sells before identity verification (T2 S1);
  - the PH tag names (T8);
  - the press tips addresses (T8);
  - whether `macos-14` still exists (T3);
  - whether Scaleway offers macOS 14 (T3 S5).

## Contract change requests

1. **§3.1 file layout, additive:**
   - `scripts/smoke-dmg.sh`, `scripts/test-smoke-dmg.sh`, `scripts/polar_sales.py`, `scripts/test_polar_sales.py`;
   - `.github/workflows/smoke.yml`, separate from `ci.yml` to avoid editing plan 01/03's file;
   - folders `docs/gates/evidence/`, `docs/ops/` (including `docs/ops/support-log.md`), `docs/launch/`.
   - Accepted, modified: the FAQ and known issues live in plan 04's `site/content/en/faq.md` (`/faq/`, `## Known issues`), not in a separate support folder.
2. **`scripts/release.sh <app> <version> [--sandbox] [--yes] [--no-upload]`**, version `X.Y.Z[-bN|-rcN]`. Accepted; it lands in plan 03 Task 12. `--no-upload` stops after the notarised, stapled DMG and prints its path as the last stdout line. Used for RCs and for the pre-publish smoke of 1.0.0.
3. **Single site price source.** Accepted: plan 04's `site/config.json`, read by the pages **and** the JSON-LD `offers.price`, so 15 Dec is a one-file change. The format is `"19"` (no decimals); Task 9 edits only that file.
4. **Schedule (master §5 H6, §7 W5):** the second Scaleway lease is L2, **Thu 26 Nov 09:00 → Fri 27 Nov 09:00** (€3.19 incl. VAT), so RC1 and the production Polar product (needed for R9 on macOS 27) exist on lease day. It is shared in the order 05 → 03 → 02 → 08, with macOS 14 last. The macOS 14 manual pass uses the same lease (reinstall), not a third lease.
5. **Invariant for plans 02/03:** the app UI contains no hard-coded price. The "Buy" button opens `TGPolarCheckoutURL`, so the 15 Dec change needs no app release. Task 3 Step 1 checks this. Accepted.
6. **`.env.example` keys added:** `POLAR_PRODUCT_ID_MARKDOWN`, `POLAR_BENEFIT_ID_MARKDOWN`, `POLAR_PORTAL_URL`, `POLAR_QA_LICENSE_KEY` (the last is removed from `.env` after Task 10).
