# Post-launch scale (milestone 07) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Measure G2, G3, G4 and the support gate on fixed dates with fixed procedures. Behind those gates, ship App 1 v1.1, a Mac App Store edition, the Setapp/Homebrew channels (the bundle ships in plan 06; C1 only verifies it), a macOS 28-ready release, the paid-v2 licensing mechanics and App 3 (selection-action bar).

**Architecture:**
- **Branches and gates:** each section is a branch off `main`, starts only when its gate holds, and opens with a re-validation task (D17).
- **v1.1:** KaTeX reuses Mermaid's lazy-load pattern. WebKit has no CSS page-margin boxes, so page numbers are stamped onto the exported PDF with PDFKit.
- **Store editions:** extra XcodeGen targets with Swift compilation conditions `UNLOCKED`/`MAS`/`SETAPP` that drop `Direct/` sources, Sparkle and TegelStore.
- **TegelStore:** generalises plan 03's single benefit id (which already rejects wrong-app keys) to sets, for v2.
- **App 3:** a non-sandboxed Developer ID menu-bar agent. It reads the selection through `AXUIElement` only when a Carbon hotkey fires, and shows a non-activating `NSPanel`.

**Tech stack:**
- Existing: Swift 6, XcodeGen, bun, the pinned renderer libraries, Sparkle 2.10.1, the Polar API.
- New: `markdown-it-texmath@1.0.0`, `katex` (newest release ≥ 14 days old; 0.19.1 today), `markdown-it-footnote@4.0.0`, all MIT. PDFKit; App Intents (macOS 13+); Setapp-framework 5.5.4 (Apache-2.0); KeyboardShortcuts 3.1.0 (MIT, App 3); GitHub Actions `macos-26`.

**Spec:**
- `BUSINESS-PLAN.md` §6.1, §7.2, §7.4, §7.5, §8, §9, §11 (months 5–12), §12, §13, §14, §15.
- Master roadmap §2 (D5, D6, D14, D16, D17), §3, §7, §8, §10, §12. Facts [F2, F5, F7, F9, F11]. `CLAUDE.md`.

## Global Constraints

Master §2/§3 and `CLAUDE.md` apply (platform and universal binary, build Mac and evidence naming, product rules 1–9, design standard and `DESIGN.md`, approvals for outward-facing actions, secrets, dependency pins). Plan-specific:
- **Read-only, extended:** App 3 may also write the pasteboard on an explicit action. `readonly-gate` (plan 06) scans every app; a new writer joins its allowlist by exact name, with a step that watches the gate fail first.
- **Network:** the MAS edition makes **no** network calls. Setapp framework reporting is allowed only if the user signs the exception in Task C2.
- **Pricing:** App 1 **$19 once, 2 Macs**; App 2 **$15**; bundle **$29**; each with its EUR price from plans 05/06 (K10, pending the user); MAS at the $19 price point. App 3 and v2 prices are set by the user (D1, F0).
- **Licence and kill path:** master GC; Task G7 is Procedure S.
- **Site keys after every direct release (plan 04 CR-5):** in the same session as each `--from-dmg` publish (A7, D7, E4, F2, G7), on `content/release-<app>-<v>`: set `apps.<app>.version` → `"<v>"` and `apps.<app>.downloadURL` → the URL on `release.sh`'s `published …` line in `site/config.json` (App 1 also adds a `/changelog/` entry); `(cd site && bun test)` → 0 fail; review stages 2, 3 and 9; merge, push, and deploy with plan 04's production deploy command (Task 10 Step 2; not a first deploy, so no approval). Expected: `curl -s https://tegelapps.com/<page>/ | grep -cF "<downloadURL>"` ≥ 1, where `<page>` is `download` for markdown (plan 04's download page), `data` for data and D1's slug for select. MAS and Setapp builds don't touch these keys.
- **Permissions:** **no Accessibility, Screen Recording or Input Monitoring in Apps 1–2.** App 3 would use Accessibility only: no event tap, no Input Monitoring, no key-event monitor. That exception (CR-8) stays **NO-GO until the user signs it off explicitly** in D2.
- **Gate windows:** the **30 full days before the gate day**, Europe/Amsterdam. EUR uses the ECB rate (USD per EUR) on the gate day:
  `curl -s 'https://data-api.ecb.europa.eu/service/data/EXR/D.USD.EUR.SP00.A?lastNObservations=1&format=csvdata' | python3 -c "import csv,sys; r=list(csv.DictReader(sys.stdin))[-1]; print(r['TIME_PERIOD'], r['OBS_VALUE'])"`
- **Hours:** ≤ 20 h/week; ≤ 10 h/week if G3 lands in €100–300; ≤ 2 h/week under a G2 freeze (BUSINESS-PLAN §11–12).
- **Commits:** "Commit: `<paths>`, `<msg>` + trailer" means `git add <paths> && git commit -m "<msg>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`.
- **WebKit tests** (every test that renders through `RendererWebView`) live under `Packages/TegelKit/Tests/TegelKitTests/WebView/` and run on plan 01's established runner. Under plan 01 Branch A, use the `swift test --package-path Packages/TegelKit --filter <Class>` lines as written below. Under Branch B (its commit message records which), use `xcodebuild test -project Tegel.xcodeproj -scheme TegelKitHostTests -derivedDataPath build -only-testing:TegelKitHostTests/<Class>` instead, once per class.

## Review Focus

1. **Hostile TeX and plain dollar signs** (`Intro $14 until 14 Dec, then $19.`, `\href{javascript:…}`, `\includegraphics{https://…}`, `\htmlData`, `</span><script>`, a `\def` bomb). Expected: prices stay text; no element or attribute that can run script or fetch; the bomb renders an error in < 500 ms. *(Task A1.)*
2. **Hostile or broken custom CSS** (`@import`, remote `url()` backgrounds/fonts, `</style><script>`, a 300 KB file, a stylesheet deleted after it was picked). Expected: zero network connections, no script, the size cap enforced, theme fallback with a notice. *(Task A3.)*
3. **Mixed bidi in the new blocks:** Arabic footnotes, inline math in an Arabic paragraph, an Arabic title in the PDF header. Expected: the footnotes `<section>` takes `dir="auto"` like every top-level block (plan 01; never per item), math stays LTR, the header stamps without changing the page count. *(Tasks A1, A2, A4.)*
4. **Keys and builds crossing channels:** an App 2 key pasted into App 1; a v1 key in v2; MAS and DMG copies on one Mac; leftover Sparkle/Polar code in a store build. Expected: "this key is for another Tegel app"; v1 features kept forever; `verify-store-build.sh` fails on any leftover. *(Tasks A0, B1, B5, C3, F1.)*
5. **App 3 privacy edges:** a password field; an app that exposes no AX selection; permission revoked mid-session; permission after a Sparkle update. Expected: secure fields never read; a clear message; onboarding returns; the permission survives the update. *(Tasks D4, D6.)*

---

## Schedule and gate map

| Section | Branch | Window | Starts only if |
|---|---|---|---|
| G: gates | `m07-gates` (tooling) | Tooling Thu 4 Mar 2027. **G2 Mon 8 Mar · G3 Fri 30 Apr · G4 Fri 29 Oct.** Support gate every Monday | The studio was not stopped on Thu 4 Mar (master §7) |
| A: App 1 v1.1 | `m07a-v1.1` | Tue 9 – Tue 30 Mar (release) | G2 ≠ FREEZE; support ≠ RED |
| B: MAS edition | `m07b-mas` | Wed 31 Mar – Fri 23 Apr (submit; April supersedes BUSINESS-PLAN's month 5, per the master note) | G2 ≠ FREEZE; A merged |
| C: bundle check, Setapp, Homebrew | `m07c-bundle-setapp` | Mon 3 – Fri 28 May; Homebrew decision Mon 2 Aug | G3 ≥ €100 |
| D: App 3 | `m07d-app3` | Mon 3 May (brainstorm) – launch Tue 20 Jul | **G3 ≥ €300**; support GREEN |
| E: macOS 28 | `m07e-macos28` | WWDC week (June) – release by Tue 31 Aug | Studio not stopped (also runs under FREEZE, as maintenance) |
| F: paid v2 | `m07f-v2` | After G4 | **G4 ≥ €1,000** and the user says go |

## Procedure P

Each section's last task runs **Procedure P (master §11)** with its id (`m07-gates`, `m07a` … `m07f`), branch, review file `docs/reviews/<id>.md`, and the deltas it lists: the `/cso` scope, the design-review shots and the release steps (B1).

---

## Section G: gates (`m07-gates`)

### Task G0: Re-validate gate inputs (Thu 4 Mar 2027)

**Files:** Create `docs/gates/m07-inputs.md`, `scripts/gates/products.json`

- [ ] **Step 1: Stop check.** Read `docs/gates/G1.md` and plan 06's 4 Mar record (`docs/gates/G1b.md`). If App 1 had < 10 sales at G1 **and** App 2 has < 10 by 4 Mar: run Task G7 (Procedure S), which writes `docs/gates/STOP.md`; plan 07 is cancelled.
- [ ] **Step 2: Token scope** (no echo; K1):
  ```bash
  . scripts/lib/env.sh
  curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $(envget POLAR_ACCESS_TOKEN)" "https://api.polar.sh/v1/orders/?organization_id=$(envget POLAR_ORGANIZATION_ID)&limit=1"
  ```
  Expected `200` (scope `orders:read`, polar.sh/docs/api-reference/orders/list). Repeat with `https://api.polar.sh/v1/refunds/?organization_id=…&limit=1` → `200` (scope `refunds:read`, polar.sh/docs/api-reference/refunds/list; G1's refund pass). On 401/403 the user issues a token with `orders:read` + `products:read` + `refunds:read`.
- [ ] **Step 3: Product ids.** From `GET https://api.polar.sh/v1/products/?organization_id=<id>&limit=100` (same headers as Step 2), write `scripts/gates/products.json` = `{"markdown":[…],"data":[…],"bundle":[…],"select":[]}`. Product ids aren't secret.
- [ ] **Step 4: Reuse check.** One Polar counter only (X22). Record the shipped signatures of `scripts/polar_sales.py` (plan 05's `fetch_orders`, `count_sales`, `window`, CLI entry; plan 08's `summarise`, B8) and of plan 08's `kpi.gsc_totals(f, start, end)`, plus the file names and column names of the GSC export CSVs that `kpi.py` reads (plan 08: `Chart.csv` and `Pages.csv`; use the names the first export actually shows). G1 adds only the CLI flags. Also record how Polar pays out EUR orders (converted into the USD balance, or a separate EUR balance); G3 Step 4 uses it.
- [ ] **Step 5: Other inputs.** Record the support-log path and row format from plan 05 (expected `docs/ops/support-log.md`, rows `| date | minutes | mails | refunds | licence | bug/feature | notes |`) and the Google login that opens Search Console for `tegelapps.com`.
- [ ] **Step 6: Commit:** `docs/gates/m07-inputs.md scripts/gates/products.json`, `docs(gates): m07 inputs and product ids` + trailer.

### Task G1: Gate metrics (Polar orders, GSC export)

One counter for every gate (X22, B8): plan 05's `scripts/polar_sales.py` counts, plan 08 Task 4 adds `summarise` (gross and net per currency, K10), and G1 adds only the CLI flags the gates need. GSC comes through plan 08's `kpi.gsc_totals`. No second order counter, no new test runner.

**Files:**
- Modify: `scripts/polar_sales.py`, `scripts/test_polar_sales.py` (already in `make check` through `test-scripts`)

**Interfaces:**
- Consumes: plan 05's `fetch_orders`, `count_sales`, `window` and CLI entry; plan 08's `summarise(orders, product_ids) -> {"count": int, "gross": {currency: float}, "net": {currency: float}}`; `scripts/gates/products.json` (G0); plan 08's `kpi.gsc_totals(f, start, end) -> {"clicks", "impressions"}` (`end` exclusive); Polar `GET /v1/refunds/` (scope `refunds:read`; before Step 1, check the field names `order_id`, `amount`, `tax_amount`, `currency`, `created_at` and the succeeded `status` value against polar.sh/docs/api-reference/refunds/list, and use what it says).
- Produces:
  - CLI `main(argv=None, products=None)`: `--from YYYY-MM-DD --to YYYY-MM-DD --summary [--products markdown,bundle]` prints `count=<n> gross=<cur>:<x>[,<cur>:<x>] net=<cur>:<y>[,…] refunds_older=<cur>:<z>[,…] from=<date> to=<date>`. `--products` maps names through `products.json` (or `products`); without it, `--summary` covers every product there. With `--summary`, `POLAR_PRODUCT_ID_MARKDOWN` isn't needed. The window is `window(from, to)`. It never prints the token.
  - `count`, `gross` and `net` cover the orders created in the window (the sales cohort; `net` already subtracts their own refunds). `refunds_older` is kept apart from that cohort: a new `fetch_refunds(token, org, after, before)` returns the succeeded refunds created in the window, and `refunds_older` sums `amount − tax_amount` per currency over those whose `order_id` isn't one of the window's orders, i.e. refunds of earlier purchases (`refunds_older=0` when there are none; it covers every product, and G3/G4 run without `--products`).
  - The **gate sales command**, used by G2–G4:

    ```bash
    . scripts/lib/env.sh && POLAR_ACCESS_TOKEN="$(envget POLAR_ACCESS_TOKEN)" POLAR_ORGANIZATION_ID="$(envget POLAR_ORGANIZATION_ID)" \
      python3 scripts/polar_sales.py --from <date> --to <date> --summary [--products <names>]
    ```

- [ ] **Step 1: Write the failing test** (append to `scripts/test_polar_sales.py`, inside its `unittest.TestCase`; imports `io`, `os`, `unittest.mock` and the module as `polar_sales`):
```python
def test_summary_cli_maps_names_and_needs_no_markdown_id(self):
    seen = []
    def fake(token, org, pid, after, before):
        seen.append(pid)
        return [{"id": "o-" + pid, "currency": "usd", "status": "paid", "product_id": pid, "total_amount": 1900, "net_amount": 1900,
                 "platform_fee_amount": 145, "platform_fee_currency": "usd", "refunded_amount": 0, "refunded_tax_amount": 0}]
    def fake_refunds(token, org, after, before):   # one refund of a window order (already in net), one of an older order
        return [{"order_id": "o-p1", "currency": "usd", "amount": 1900, "tax_amount": 0},
                {"order_id": "o-old", "currency": "usd", "amount": 1500, "tax_amount": 0}]
    with mock.patch.object(polar_sales, "fetch_orders", fake), \
         mock.patch.object(polar_sales, "fetch_refunds", fake_refunds), \
         mock.patch.dict(os.environ, {"POLAR_ACCESS_TOKEN": "t", "POLAR_ORGANIZATION_ID": "o"}, clear=True), \
         mock.patch("sys.stdout", new_callable=io.StringIO) as out:
        polar_sales.main(["--from", "2027-02-06", "--to", "2027-03-08", "--summary", "--products", "markdown,bundle"],
                         products={"markdown": ["p1"], "bundle": ["p3"]})
    self.assertEqual(seen, ["p1", "p3"])
    self.assertTrue(out.getvalue().startswith("count=2 gross=usd:38.00 net=usd:35.10 refunds_older=usd:15.00 "), out.getvalue())
```
- [ ] **Step 2: Run and watch it fail.** `python3 -m unittest discover -s scripts -p 'test_polar_sales.py' -v` → FAIL (`polar_sales` has no attribute `fetch_refunds`, `main()` takes no `products`, or `--summary` is unrecognised).
- [ ] **Step 3: Implement.** If plan 05's argparse block isn't already `main(argv=None)`, wrap it first. `--summary` calls `fetch_orders` once per mapped product id in the window, then `summarise` over the union, then `fetch_refunds` once for the window (a paginated `GET /v1/refunds/` filtered to `created_at` in the window), and prints the line above (currencies sorted, two decimals).
- [ ] **Step 4: Run and watch it pass.** The Step 2 command → `OK` (plan 05's and plan 08's tests plus this one); `make check` → all pass.
- [ ] **Step 5: Commit:** `scripts/polar_sales.py scripts/test_polar_sales.py`, `feat(gates): --summary and --products in polar_sales.py` + trailer.

### Task G2: G2, Mon 8 Mar 2027 (day 90) → `docs/gates/G2.md`

**Thresholds (BUSINESS-PLAN §12, verbatim):** continue if "App 1: ≥ 25 sales in the last 30 days **and** GSC ≥ 10,000 impressions/30 d". Kill / change if "< 10 sales **and** < 2,000 impressions → the SEO thesis failed; freeze at maintenance only (≤ 2 h/week)". **Window:** `2027-02-06T00:00:00+01:00` → `2027-03-08T00:00:00+01:00`.

- [ ] **Step 1: Sales.** Run the gate sales command (G1) with `--from 2027-02-06 --to 2027-03-08 --products markdown`, then again with `--products bundle`. App 1 sales = both counts (each bundle sells an App 1 licence). Record both; flag it to the user if counting the bundle flips the decision.
- [ ] **Step 2: Impressions.** The user, in their own browser: Search Console → `tegelapps.com` → Performance → Search results → Date: Custom **6 Feb – 7 Mar 2027**, Search type Web → Export → Download CSV → unzip it into `local-docs/gates/G2-gsc/` (gitignored), as plan 08 does. Run `python3 -c "import sys; sys.path.insert(0, 'scripts'); from datetime import date; from kpi import gsc_totals; print(gsc_totals(open('local-docs/gates/G2-gsc/Chart.csv'), date(2027, 2, 6), date(2027, 3, 8))['impressions'])"` (plan 08's `Chart.csv`; use the name the first export actually shows, as recorded in G0). Also record total clicks (risk 9), App 1 page impressions (`Pages.csv` rows containing `/markdown`), and any days marked preliminary.
- [ ] **Step 3: Write `docs/gates/G2.md`:** thresholds verbatim, window, a metrics table with the command or source per number, stretch targets (master §12: sales ≥ 47, impressions ≥ 10,000), `Decision: PASS | MIDDLE | FREEZE` (PASS = both continue conditions; FREEZE = both kill conditions; otherwise MIDDLE), the cancellation list, `User sign-off: <date>`.
- [ ] **Step 4: Apply.** **FREEZE cancels** Sections A, B, C, D, F and the Homebrew task, and hands the SEO cadence back to plan 08. E (maintenance) and the support gate stay; when the user ends maintenance, Task G7 runs first (K14). **MIDDLE:** A and B proceed; plan 08 re-targets SEO. **PASS:** everything proceeds on schedule.
- [ ] **Step 5: Commit** `docs/gates/G2.md` to `main` (docs only) and push.

### Task G3: G3, Fri 30 Apr 2027 (month 6) → `docs/gates/G3.md`

**Thresholds (verbatim):** continue if "Combined net ≥ **€300/month** → build app 3". Kill / change if "€100–300 → no new app, ≤ 10 h/week. **< €100 → stop development**; keep the apps on sale". **Window:** `2027-03-31T00:00:00+02:00` → `2027-04-30T00:00:00+02:00`.

- [ ] **Step 0: Rotate the Pages deploy token (Thu 29 Apr 2027, before any deploy).** Plan 04 Task 3 Step 5's `CLOUDFLARE_API_TOKEN` ends Fri 30 Apr 2027, and Step 6's deploy, A7, D7, G7 and plan 08's later deploys all need it. Repeat plan 04 Task 3 Step 5 (same name, scope and account; TTL start today, end Fri 29 Oct 2027) and save the new token with its `envset … "$(pbpaste)"` line. Delete the old token (the one ending 30 Apr 2027) in My Profile → API Tokens. Then plan 04 Task 3 Step 6's TTL and no-zone checks → `active True` and `0`.
- [ ] **Step 1: Polar, all products.** The gate sales command with `--from 2027-03-31 --to 2027-04-30` (no `--products`). Record `count`, and `gross`/`net`/`refunds_older` per currency.
- [ ] **Step 2: Payout ratio `r` from actual payout data.** Polar dashboard → Finance → Payouts: the USD withdrawn in the last 3 payouts; the user reads the EUR credited for each on the bank statement. `r = Σ EUR credited ÷ Σ USD withdrawn`. With fewer than 3 payouts: `r = 0.995 ÷ ECB USD-per-EUR` (§9's "about 0.5% payout/FX").
- [ ] **Step 3: Other channels.** MAS: App Store Connect → Sales and Trends → Proceeds for the window, converted at the ECB rate. Setapp: the developer-account statistics, if live.
- [ ] **Step 4: Compute.** Decision value **net = (net.usd − refunds_older.usd) × r + (net.eur − refunds_older.eur) × r_eur + MAS + Setapp** (a refund paid out this month for an earlier purchase counts this month), where `r_eur` = 0.995 if Polar pays EUR orders out in EUR (§9's payout/FX), or `r` × the ECB USD-per-EUR rate if it converts them into the USD balance (G0 Step 4 records which): €1 becomes ECB dollars, and each dollar pays out `r` euros. Sanity check: with Step 2's fallback `r` (0.995 ÷ ECB), `r_eur` is 0.995 at any rate; at ECB 1.08 and `r` = 0.921, `r_eur` ≈ 0.995, never ≈ 0.85. Plan cross-check **net_§9 = (gross.usd + gross.eur × ECB USD-per-EUR) × 0.744** (§9: "€0.744 per $1 gross"). If the two Polar figures differ by > 15%, record the Polar country split (the §9 test) and propose updating the factor.
- [ ] **Step 5: Write `docs/gates/G3.md`:** thresholds, window, all inputs, stretch ≥ €760, `Decision: APP3 | NO-NEW-APP | STOP`, the cancellation list, sign-off.
- [ ] **Step 6: Apply.** **STOP cancels** C, D, F and Homebrew. The apps stay on sale (BUSINESS-PLAN §12), with "Maintenance only: no new features." on each product page (plan 04's deploy). Task G7 runs when maintenance ends, or now if the user chooses to stop sales at sign-off (open question 6). **NO-NEW-APP cancels** D (≤ 10 h/week). **APP3** starts D.
- [ ] **Step 7: Commit to `main` and push.**

### Task G4: G4, Fri 29 Oct 2027 (month 12) → `docs/gates/G4.md`

**Thresholds (verbatim):** continue if "≥ **€1,000/month** net → bundle, Setapp, app 4". Kill / change if "Otherwise wind down to maintenance". **Window:** `2027-09-29T00:00:00+02:00` → `2027-10-29T00:00:00+02:00`.

- [ ] **Step 0: Renewals (about Wed 20 Oct 2027, before G4).** The Apple Developer membership (paid 27 Oct 2026) and the domain (bought about 30 Oct 2026) renew around the gate. Ask the user (U-49): renew each, or turn auto-renew off first. A renewal is a purchase, so it needs the user's approval. Also list the Developer ID Application certificate: it expires Fri 26 Nov 2027, and its renewal is plan 03 Task 3 Step 6, due by Fri 12 Nov 2027 (run that step; without it no new build can be signed, Procedure S's final builds included). Also the Pages deploy token: G3 Step 0's ends Fri 29 Oct 2027, so repeat G3 Step 0 now with an end date six months on (no purchase, no ask). Record the answers in `docs/gates/G4.md`.
- [ ] **Step 1: Measure.** Repeat G3 Steps 1–4 for this window, including App 3 (`select` in `products.json`), MAS proceeds and Setapp payouts.
- [ ] **Step 2: Write `docs/gates/G4.md`:** stretch ≥ €1,450, `Decision: CONTINUE | WIND-DOWN`, the cancellation list, sign-off.
- [ ] **Step 3: Apply.** **WIND-DOWN cancels** F, app 4 and any pending Homebrew work; macOS maintenance and support continue, and Task G7 runs before maintenance ends (K14). **CONTINUE** makes F eligible; app 4 gets its own plan via `superpowers:brainstorming`.
- [ ] **Step 4: Commit to `main` and push.**

### Task G5: Support gate (rolling, every Monday from 8 Mar 2027) → `docs/gates/support.md`

**Thresholds (verbatim):** continue if "≤ 20 min/day averaged over 14 days". Kill / change if "> 30 min/day → fix the docs or raise the price before any new feature".

- [ ] **Step 1: Compute the 14-day average.** Run plan 05 Task 4 Step 5's check command.
- [ ] **Step 2: Append a row:** `| date | avg min/day | GREEN ≤ 20 / AMBER 20–30 / RED > 30 | top 3 categories |`.
- [ ] **Step 3: On RED.** The next feature task in any active section waits. Write FAQ/docs fixes for the top 3 categories, or propose a price rise (outward-facing; never framed with a "was" price). Re-measure after 14 days.
- [ ] **Step 4: Commit the row** (and any docs fixes) to `main`.

### Task G6: Procedure P for `m07-gates`

- [ ] **Step 1: Run Procedure P (master §11).** `/cso` scope: `.env` loading through `scripts/lib/env.sh` and `POLAR_ACCESS_TOKEN` handling (never logged, only sent to `api.polar.sh`). Review file `docs/reviews/m07-gates.md`. Merge and push per P; `make check` is green on `main`.

### Task G7: Procedure S, stopping without stranding a buyer (K14)

**Runs when:** G0 Step 1 (plan 06's G1b stop: "stop the studio"); or, under STOP (G3), FREEZE (G2) or WIND-DOWN (G4), before maintenance ends; or whenever the user decides to stop sales. The order is fixed: **new sales stop first, then the final builds ship.** Branch `m07-stop`.

**Files:**
- Modify: TegelStore's `PolarConfig` and `LicenseManager` (plan 03's files); `Packages/TegelKit/Tests/TegelStoreTests/FinalBuildTests.swift`; `project.yml` (on every direct app target, Info.plist `TGFinalBuild = $(TG_FINAL_BUILD)`, and plan 03's `SUEnableAutomaticChecks = YES` becomes `$(TG_SU_AUTOMATIC_CHECKS)`); `Config/Release.xcconfig` (`TG_FINAL_BUILD = YES` and `TG_SU_AUTOMATIC_CHECKS = NO`; elsewhere `TG_FINAL_BUILD` empty and `TG_SU_AUTOMATIC_CHECKS = YES`); each direct app's entry file (`MarkdownApp.swift`, `DataApp.swift`, App 3's if shipped); `site/config.json` and the product pages; `docs/gates/STOP.md`.

**Interfaces:**
- `PolarConfig.finalBuild: Bool` (Info.plist `TGFinalBuild` == `YES`). When true, `LicenseManager.refresh()` returns before any network call, and wherever the manager applies `LicensePolicy` (the designated init and `refresh`) a stored licence maps to `.pro(stored)`, whatever its last validation date. So `state` never reads `.lapsed`, `isPro` (true only for `.pro`) follows, the Licence tab never shows plan 03's lapsed row with **Check Again** and **Remove Licence…**, and the manager never removes the stored key. Activating a new Mac still calls Polar, which is why Step 1 keeps the Polar organisation.
- **No update checks in a final build** (it must not keep contacting `downloads.tegelapps.com` after the studio stops, or after the domain lapses and someone else holds it): Info.plist `SUEnableAutomaticChecks` is `NO`; the app creates `SPUStandardUpdaterController(startingUpdater: !finalBuild, …)`, so Sparkle never schedules a check, even when a stored user default turned automatic checks on; "Check for Updates…" and the Updates tab are hidden.

- [ ] **Step 1 🔒 Stop new sales** (**user approval**: live Polar products). Archive every live product (Markdown, Data, Bundle, App 3 if live). **Archive only: never delete the Polar organisation, a product, its licence-key benefits or any licence key.** Copies that never install the final build keep validating against them, and a final build activates a new Mac through them. Check each: `curl … /v1/products/<id>` (G0 Step 2 headers) → `"is_archived": true`; each `POLAR_CHECKOUT_URL_*` no longer completes a purchase (screenshot to `docs/gates/stop/`).
  - **Site.** Plan 04's `fill` throws on a `{{checkout:<app>}}` whose URL is empty, and its deploy runs only after `bun test` passes, so the copy and the tests change together. First replace the site tests that assume an open sale with one test: no built page contains `reference_id=` or a JSON-LD `"Offer"`, and every product page contains "No longer sold. Existing licences keep working." Those tests are plan 04 Task 14's `product and pricing pages link the checkout from config`, the price-sentence tests on product pages (plan 04 Tasks 7 and 11), and plan 06 Task 13's `reference_id=site-data`/`site-bundle` and price assertions. `(cd site && bun test)` → the new test fails on the current pages (watched).
  - Then, on every page whose body uses a sale placeholder (`grep -rlE '\{\{(pricing|price|checkout):' site/content`: the product, pricing and bundle pages in every language, and also the home and RTL landing pages, which carry `{{pricing:markdown}}` under plan 04's declared-app guard), replace each buy block (`{{pricing:<app>}}` or `{{price:<app>}}` and its `{{checkout:<app>}}` link) with "No longer sold. Existing licences keep working.", set every `checkoutURL` in `site/config.json` to `""`, and delete the `app:` line from every page's front matter (plan 04 emits the SoftwareApplication JSON-LD and its Offer only when `app` is set, and has no availability field). `(cd site && bun test)` → 0 fail. If another test still asserts a price or a checkout link on a product page, fold it into the new test in this same commit.
  - Commit: `site docs/gates/stop`, `chore(stop): sales stopped, the site says no longer sold` + trailer. Plan 04's command deploys `main` (it starts with `git switch main`), so merge first: `git switch main && git merge --no-ff m07-stop -m "Merge m07-stop: sales stopped" && git push origin main`. Deploy (plan 04's command), then `git switch m07-stop` for Step 2. Check: `. scripts/lib/env.sh; curl -s https://tegelapps.com/markdown/ | grep -cF "$(envget POLAR_CHECKOUT_URL_MARKDOWN)"` → `0`, and the same for Data and the bundle. MAS and Setapp editions: remove from sale in their consoles (approval each); they never check a licence.
- [ ] **Step 2: Write the failing test.** `testFinalBuildKeepsStoredLicenceWithoutNetwork`: `PolarConfig` with `finalBuild: true`; a stored licence last validated at `t0`; plan 03's URLProtocol stub recording every request; the manager built through plan 03's designated `LicenseManager(client:keychain:now:)` (its `makeManager` helper) with `now: t0 + 400 * 86_400`, so the test never reads the real clock. `await m.refresh(now: t0 + 400 * 86_400)` → `state == .pro(lic)`, `isPro == true`, `keychain.load() == lic` (the key is kept), and the stub saw 0 requests. Run `swift test --package-path Packages/TegelKit --filter FinalBuildTests` → FAIL to compile (`finalBuild` missing).
- [ ] **Step 3: Implement** one guard at the top of `refresh()` and one where the manager applies `LicensePolicy` (`finalBuild` with a stored licence → `.pro(stored)`); then the updater lines above in each app entry file and the two `project.yml`/xcconfig settings. Build-setting expansion turns `SUEnableAutomaticChecks` into a string (`NO`/`YES`), so first read Sparkle 2.10.1's source to confirm it reads that Info.plist key through `boolValue`, making the string `NO` off and `YES` on; note the file and line for Step 6. If Sparkle accepts only a boolean there, keep plan 03's boolean `SUEnableAutomaticChecks: true`, rely on `startingUpdater: !finalBuild` (Step 5 watches it), and drop Step 5's `SUEnableAutomaticChecks` print.
- [ ] **Step 4: Watch it pass, then watch each guard fail.** Re-run → PASS. Comment out the `refresh()` guard → FAIL (the stub records 1 request; `state` still holds `.pro` through the policy guard); restore. Comment out the policy guard → FAIL (`state == .lapsed(lic)`, `isPro == false`: 400 days is past plan 03's grace); restore → PASS. `swift test --package-path Packages/TegelKit` → all pass, plan 03's grace tests included. Commit: `Packages/TegelKit Apps project.yml Config`, `feat(stop): final build keeps Pro without licence calls or update checks` + trailer (Step 5's `release.sh` needs a clean tree).
- [ ] **Step 4b: Run Procedure P (master §11)** with id `m07-stop` and review file `docs/reviews/m07-stop.md`, through its merge and push, before Step 5 builds anything. This changes licensing and the updater (master §11, out of cadence), and a final build checks for no updates, so a bug that ships in it can never be fixed. `/cso` scope: the two `finalBuild` guards (no network call; a stored licence reads `.pro` and is never removed); `TG_FINAL_BUILD` and `TG_SU_AUTOMATIC_CHECKS` set only in `Config/Release.xcconfig`; `startingUpdater: !finalBuild` and the hidden update UI in each app entry file. Design review: the Licence tab and the app menu of a final build, light, dark and Arabic.
- [ ] **Step 5: Final builds** (**user approval** per release). For each direct app:
  - `scripts/release.sh <app> <v> --no-upload`; `PlistBuddy -c 'Print TGFinalBuild'` → `YES` and `-c 'Print SUEnableAutomaticChecks'` → `NO` (a string, which Step 3 confirmed Sparkle reads as off).
  - **Watch the update guard fail on the shipped build.** On the build Mac's activated copy, with `D=~/Library/Containers/<bundle id>/Data/Library/Preferences/<bundle id>` (App 3, unsandboxed: `~/Library/Preferences/<bundle id>`): `defaults write "$D" SUEnableAutomaticChecks -bool YES; defaults write "$D" SULastCheckTime -date "2000-01-01 00:00:00 +0000"` (a user who turned checks on, with a check long overdue). Launch, wait 60 s, quit. `defaults read "$D" SULastCheckTime` → today's date: it checked.
  - Install the final build over that copy and repeat the two writes, the launch and the read → still `2000-01-01 …`, and the app menu has no "Check for Updates…". Turn Wi-Fi off, relaunch → Pro.
  - Then `scripts/release.sh <app> <v> --yes --from-dmg <path>` (`--yes` only after this release's approval: without a terminal the confirmation prompt aborts with `aborted: nothing uploaded`), so every install's Sparkle check offers the final build, its last one; then the site keys (Global Constraints), so new downloads get the final build too.
- [ ] **Step 6: Record.** `docs/gates/STOP.md`: the trigger, the date, what stopped, the final versions, the Sparkle source line from Step 3, "the Polar organisation, its benefits and its licence keys are kept, never deleted: copies that never installed the final build still validate against them", "existing licences keep working; support by email until <date the user sets>". Commit: `docs/gates/STOP.md`, `docs(stop): Procedure S record` + trailer; merge and push.

---

## Section A: App 1 v1.1 (`m07a-v1.1`)

### Task A0: Re-validate v1.1 assumptions

**Files:** Create `docs/reviews/m07a-revalidation.md`

- [ ] **Step 1: Gate and branch.** `grep '^Decision:' docs/gates/G2.md` shows PASS or MIDDLE, and the last `docs/gates/support.md` row isn't RED. `git checkout -b m07a-v1.1 main`.
- [ ] **Step 2: Swift API diff.** Run `grep -rhn "public " Packages/TegelKit/Sources --include=*.swift | grep -E "func |init\(|struct |enum |class |case |var |let "` and write `Assumed (master §3.3) | Shipped | Action` rows for `RenderOptions`, `RendererWebView.render`, `PDFExporter.makePDFData`, `BookmarkStore`, `LicenseManager` and `ProGate`.
- [ ] **Step 3: Renderer facts:** the markdown-it major in `Renderer/bun.lock` (texmath has no peer dependency, so 14 and 15 both work); `SANITIZE_CONFIG` and `addHooks` in `Renderer/src/sanitize.js` (plan 01); how `page.js` injects `mermaid.min.js`, including the Quick Look path (KaTeX copies it); plan 01's `#doc` click listener that scrolls `#x` links to `user-content-x` (A2 relies on it); whether a failed `<img>` already becomes a placeholder.
- [ ] **Step 4: App facts:** the direct target names (assumed plan 01's `markdown`, `markdown.quicklook`, and plan 02's test target `MarkdownAppTests` in `Apps/Markdown/AppTests/`); the PDF export call site (`grep -rn "PDFExporter.makePDFData" Apps/`; plan 02 puts it in `ReaderController.swift`, followed by its one `data.write(to:)`); the folder-window opener; the settings view; whether `makePDFData` needs a visible window; `scripts/release.sh` usage (assumed `<app> <version> [--sandbox] [--yes] [--no-upload]`, versions `X.Y.Z[-bN|-rcN]`, plan 03); the appcast and DMG URL paths; `print.css` page margins (need ≥ 36 pt for the header/footer).
- [ ] **Step 5: Cross-app key regression check (Review Focus 4).** Plan 03 ships the benefit binding in 1.0.0 (D1). Paste an App 2 **sandbox** key into a Debug App 1. Expected: rejected with plan 03's `wrongProduct` message, and the sandbox portal shows no activation left on that key. If it unlocks Pro, that's a **P0** regression of plan 03's binding: stop Section A, root-cause it with `superpowers:systematic-debugging`, and ship a v1.0.x fix (approval) before A1.
- [ ] **Step 6: Library versions.** `npm view markdown-it-texmath version time license` (1.0.0, MIT); `npm view markdown-it-footnote version license` (4.0.0, MIT); `npm view katex dist-tags time license` → the newest version ≥ 14 days old.
- [ ] **Step 7: Fix and commit.** Rewrite any Interface below that the diff falsified. Commit: `docs/reviews/m07a-revalidation.md docs/superpowers/plans/2026-10-27-07-post-launch-scale.md`, `docs(m07a): re-validation` + trailer.

### Task A1: KaTeX math, lazy-loaded like Mermaid

**Files:**
- Create: `Renderer/src/math.js`, `Renderer/test/math.test.js`, `Packages/TegelKit/Tests/TegelKitTests/WebView/RendererMathTests.swift`
- Modify: `Renderer/src/{markdown.js,page.js,css/base.css}`, `Renderer/build.js`, `Renderer/package.json`, `Renderer/bun.lock`, `Fixtures/markdown/hostile.md`, the third-party notices file, `docs/design/decisions.md` (records KaTeX's `fonts/*.woff2` as the one exception to DESIGN.md's "No bundled font files": math glyphs need them)
- Regenerated: `Packages/TegelKit/Sources/TegelKit/Resources/Renderer/**` (adds `katex/katex.min.js`, `katex/katex.min.css`, `katex/fonts/*.woff2`)

**Interfaces:**
- Consumes: `renderToHTML(markdown, opts)` (§3.2); `SANITIZE_CONFIG` from `Renderer/src/sanitize.js` (plan 01; the hooks are already installed by `page.js`); `RendererWebView.webView` (§3.3).
- Produces:
  - `renderToHTML` emits `<span class="math-src" data-math="inline" dir="ltr">…</span>` and `<div class="math-src" data-math="block" dir="ltr">…</div>`. The TeX has `& < > "` escaped and `$` → `&#36;`.
  - `KATEX_OPTIONS = { throwOnError: false, trust: false, strict: 'ignore', maxExpand: 1000, maxSize: 20, output: 'htmlAndMathml' }`
  - `renderMath(katex, tex: string, displayMode: boolean) -> string`

- [ ] **Step 1: Write the failing bun tests.**
```js
import { test, expect } from 'bun:test';
import katex from 'katex';
import { renderToHTML } from '../src/markdown.js';
import { renderMath } from '../src/math.js';
const W = { mode: 'window' };
async function elements(html) {
  const seen = [];
  await new HTMLRewriter().on('*', { element(e) { seen.push({ tag: e.tagName, attrs: [...e.attributes].map(([n]) => n) }); } })
    .transform(new Response(html)).text();
  return seen;
}
test('inline math becomes an escaped LTR placeholder', () => {
  expect(renderToHTML('Area $a<b$ here', W)).toContain('<span class="math-src" data-math="inline" dir="ltr">a&lt;b</span>');
});
test('block math becomes a block placeholder', () => {
  expect(renderToHTML('$$\n\\frac{1}{2}\n$$', W)).toMatch(/<div class="math-src" data-math="block" dir="ltr">\s*\\frac\{1\}\{2\}\s*<\/div>/);
});
test('prices and code are not math', () => {
  expect(renderToHTML('Intro $14 until 14 Dec, then $19.', W)).not.toContain('math-src');
  expect(renderToHTML('`$x$`', W)).not.toContain('math-src');
});
test("an escaped dollar can't act as a String.replace pattern in texmath's template", () => {
  const html = renderToHTML("x $a \\$' b$ y", W);            // texmath substitutes via tmpl.replace(/\$1/, rendered)
  expect(html).toContain("a \\&#36;' b");
  expect(html.match(/math-src/g).length).toBe(1);
});
test('hostile TeX yields no element or attribute that can run or fetch', async () => {
  for (const tex of ['\\href{javascript:alert(1)}{x}', '\\url{https://evil.example}', '\\includegraphics{https://evil.example/a.png}',
                     '\\htmlData{onerror=alert(1)}{x}', '\\htmlClass{x" onload="alert(1)}{y}', '</span><script>alert(1)</script>']) {
    for (const e of await elements(renderMath(katex, tex, false))) {
      expect(['script', 'a', 'img', 'iframe', 'object', 'embed']).not.toContain(e.tag);
      expect(e.attrs.filter((n) => n.startsWith('on') || n === 'href' || n === 'src')).toEqual([]);
    }
  }
});
test('expansion bomb fails fast', () => {
  const t = performance.now();
  renderMath(katex, '\\def\\a{\\a\\a}\\a', true);
  expect(performance.now() - t).toBeLessThan(500);
});
```
- [ ] **Step 2: Run and watch it fail.** `cd Renderer && bun add -E --ignore-scripts markdown-it-texmath@1.0.0 katex@<A0 version> && bun test test/math.test.js` → FAIL: `Cannot find module '../src/math.js'`.
- [ ] **Step 3: Implement.**
  - `math.js` exports `KATEX_OPTIONS` and `renderMath`, which returns `katex.renderToString(tex, { ...KATEX_OPTIONS, displayMode })`.
  - `markdown.js`: `md.use(texmath, { engine: { renderToString: placeholder }, delimiters: 'dollars' })`. `placeholder(tex, { displayMode })` returns the span or div above. texmath wraps it in `<eq>`/`<eqn>`, which DOMPurify drops while keeping the content.
  - `page.js`, mirroring Mermaid (a pass after plan 01's `render` step 2, whose `style` filter covers the main fragment only, so KaTeX's inline `style` attributes are kept): if `[data-math]` exists, append `katex/katex.min.css` and inject `katex/katex.min.js` once, then await it. For each placeholder: `el.replaceChildren(DOMPurify.sanitize(renderMath(window.katex, el.textContent, el.dataset.math === 'block'), { ...SANITIZE_CONFIG, RETURN_DOM_FRAGMENT: true }))`. The config returns a DocumentFragment, so never assign it to `innerHTML` (that would insert `[object DocumentFragment]`). Post `rendered` only afterwards; KaTeX errors go into `errors`.
  - `build.js` copies `katex.min.js`, `katex.min.css` and only `fonts/*.woff2`. `base.css`: `.math-src { unicode-bidi: isolate; }`.
- [ ] **Step 4: Run and watch it pass.** `bun test test/math.test.js` → 6 pass.
- [ ] **Step 5: Write the failing Swift tests** (`RendererMathTests`, `@MainActor`, one `RendererWebView` per test):
  - `testMathRendersWithMathML`: render `Euler: $e^{i\\pi}+1=0$` → `.katex` count == 1; `.katex math` count == 1; `.katex [style]` count ≥ 1 (KaTeX's layout styles survived plan 01's main-pass filter); `result.errors.isEmpty`.
  - `testKatexLoadsOnlyWhenNeeded`: after `# No math`, `document.querySelector('script[src$="katex.min.js"]') == null`; after the math document it's non-null.
  - `testMathInArabicParagraphStaysLTR`: `النتيجة $a+b$ صحيحة` → `getComputedStyle(document.querySelector('.math-src')).direction == "ltr"`.
  - `testFontsReferencedByKatexCSSExist`: every `url(fonts/…woff2)` in `Resources/Renderer/katex/katex.min.css` exists in `Bundle.module`.
- [ ] **Step 6: Run and watch it fail.** `swift test --package-path Packages/TegelKit --filter RendererMathTests` → FAIL (no `katex/` in the bundle; `.katex` count 0).
- [ ] **Step 7: Regenerate and re-run.** Append the six hostile TeX lines to `Fixtures/markdown/hostile.md`. `make renderer && swift test --package-path Packages/TegelKit --filter "RendererMathTests|Hostile"` → PASS, and the existing hostile test still shows no script and no navigation.
- [ ] **Step 8: Commit:** `Renderer Packages/TegelKit Fixtures/markdown/hostile.md <notices file> docs/design/decisions.md`, `feat(renderer): KaTeX math, lazy-loaded, trust off, sanitised` + trailer.

### Task A2: Footnotes

**Files:**
- Create: `Renderer/test/footnote.test.js`
- Modify: `Renderer/src/markdown.js`, `Renderer/package.json`, `Renderer/bun.lock`, the notices file, `Fixtures/markdown/hostile.md`
- Test: `RendererMathTests.swift` (adds `testFootnoteLinkScrollsWithinDocument`)

**Interfaces:**
- Consumes: `renderToHTML` (§3.2).
- Produces: `markdown-it-footnote@4.0.0` markup: ids `fn<N>` and `fnref<N>` from `renderToHTML`, which plan 01's `SANITIZE_NAMED_PROPS` pass turns into `user-content-fn<N>` and `user-content-fnref<N>` in the DOM. `dir="auto"` goes on the footnotes `<section>` only, as on every top-level block (plan 01, master §3.2); a per-item `dir="auto"` on `li` breaks RTL lists in WebKit.

- [ ] **Step 1: Write the failing tests.**
```js
import { test, expect } from 'bun:test';
import { renderToHTML } from '../src/markdown.js';
test('footnotes link both ways', () => {
  const html = renderToHTML('Claim[^1].\n\n[^1]: Source.', { mode: 'window' });
  for (const s of ['href="#fn1"', 'id="fn1"', 'href="#fnref1"', 'id="fnref1"']) expect(html).toContain(s);
});
test('footnotes take their direction at the section, never per item', () => {
  const html = renderToHTML('نص[^1].\n\n[^1]: مصدر عربي.', { mode: 'window' });
  expect(html.match(/<section[^>]*class="footnotes"[^>]*>/)[0]).toContain('dir="auto"');
  expect(html.match(/<li[^>]*id="fn1"[^>]*>/)[0]).not.toContain('dir=');
});
```
- [ ] **Step 2: Run and watch it fail.** `cd Renderer && bun add -E --ignore-scripts markdown-it-footnote@4.0.0 && bun test test/footnote.test.js` → FAIL (`href="#fn1"` not found).
- [ ] **Step 3: Implement.**
  - `md.use(footnote)`, and wrap `md.renderer.rules.footnote_block_open` so its `<section class="footnotes"` gains ` dir="auto"`. Item `<li>`s stay as the plugin writes them.
  - No new click handler: plan 01's `#doc` listener already scrolls `#fn1` to `user-content-fn1` without navigating.
  - Append to `hostile.md` a footnote whose body is `<img src=x onerror=alert(1)>`.
- [ ] **Step 4: Run and watch it pass.** `bun test test/footnote.test.js` → 2 pass.
- [ ] **Step 5: Swift scroll test.** `testFootnoteLinkScrollsWithinDocument`: render 200 paragraphs plus a footnote; `document.querySelector('a[href="#fn1"]').click()` → `document.getElementById('user-content-fn1').getBoundingClientRect().top < 50` (the DOM id after plan 01's `SANITIZE_NAMED_PROPS`), and `webView.url` is unchanged apart from the hash. `make renderer && swift test --package-path Packages/TegelKit --filter "RendererMathTests|Hostile"` → PASS.
- [ ] **Step 6: Commit:** `Renderer Packages/TegelKit Fixtures/markdown/hostile.md <notices file>`, `feat(renderer): footnotes, direction set on the section` + trailer.

### Task A3: Custom CSS (Pro), a read-only bookmarked file injected after the theme

**Files:**
- Create: `Apps/Markdown/App/CustomStylesheet.swift`, `Apps/Markdown/AppTests/CustomStylesheetTests.swift`, `Packages/TegelKit/Tests/TegelKitTests/WebView/UserCSSTests.swift`
- Modify: `Packages/TegelKit/Sources/TegelKit/RendererWebView.swift` and the file defining `RenderOptions`; `Renderer/src/page.js`; the settings view (A0 name: a "Custom stylesheet…" row under Appearance, Pro-gated, layout from `DESIGN.md`); `Localizable.xcstrings` (EN/NL/FR/AR); the FAQ (Quick Look ignores custom CSS; remote URLs are blocked)

**Interfaces:**
- Consumes: `RenderOptions` and `RendererWebView.render(_:options:)` (§3.3); `EnvironmentValues.isPro`.
- Produces:
  - Contract change: `RenderOptions.userCSS: String? = nil`; JS `opts.userCSS?: string`. Element `<style id="tegel-user-css">` is the last child of `<head>`.
  - `enum CustomStylesheet { static let maxBytes = 262_144; static let defaultsKey = "TGCustomCSSBookmark"; @MainActor static func choose() async -> URL?; static func save(_ url: URL) throws; static func load() -> String?; static func clear() }`

- [ ] **Step 1: Write the failing WebKit tests** (`UserCSSTests`, `@MainActor`):
  - `testUserCSSIsLastAndApplied`: `userCSS = "p { outline-color: rgb(1, 2, 3) }"` → the last `document.styleSheets` entry's `ownerNode.id == "tegel-user-css"`, and the first `p`'s computed `outline-color == "rgb(1, 2, 3)"`.
  - `testUserCSSCannotReachNetwork`: start an `NWListener` on `127.0.0.1`, port 0, counting accepted connections. `userCSS = "@import url(\"http://127.0.0.1:\(port)/a.css\"); body{background-image:url(\"http://127.0.0.1:\(port)/b.png\")} @font-face{font-family:x;src:url(\"http://127.0.0.1:\(port)/c.woff2\")} p{font-family:x}"`. Render, wait 1 s → `XCTAssertEqual(connections, 0)`.
  - `testUserCSSCannotInjectMarkup`: `userCSS = "</style><script>window.__pwned=1</script><style>"` → `typeof window.__pwned == "undefined"` and `document.querySelectorAll('script:not([src])').length == 0`.
- [ ] **Step 2: Run and watch it fail.** `swift test --package-path Packages/TegelKit --filter UserCSSTests` → FAIL to compile: `extra argument 'userCSS'`.
- [ ] **Step 3: Implement.** Add `userCSS` to `RenderOptions` and the JSON options. `page.js` `applyUserCSS(css)`: get or create `#tegel-user-css`, append it as `document.head`'s last child, set `textContent = css || ''` (never `innerHTML`). The CSP is unchanged.
- [ ] **Step 4: Run and watch it pass.** `make renderer && swift test --package-path Packages/TegelKit --filter UserCSSTests` → 3 pass.
- [ ] **Step 5: Watch the network guard fail when broken.** Two layers block the network, so remove both (plan 01 Task 5 Step 9, row 2): `sed -i '' '/Content-Security-Policy/d' Packages/TegelKit/Sources/TegelKit/Resources/Renderer/index.html`, and comment out the rule-list `add` in `RendererWebView`. Run `--filter testUserCSSCannotReachNetwork` → FAIL (connections ≥ 1). With the CSP gone but the rule list in place it would still pass: the `^https?:` rule blocks `http://127.0.0.1`. Restore: un-comment the `add` line and run `make renderer`, which rewrites `index.html` from `Renderer/src` (Step 3's edits aren't committed yet, so no `git checkout`). Re-run Step 4's command → 3 pass.
- [ ] **Step 6: Write the failing app tests** (`CustomStylesheetTests`):
  - `testRoundTrip`: temp `a.css` = `p{}`, `save`, `load() == "p{}"`.
  - `testOversizedFileIsRejected`: 300,000 bytes → `load() == nil`.
  - `testDeletedFileReturnsNil`: `save`, delete the file → `nil`.
  - `testClear`: `clear()` → `nil`.
- [ ] **Step 7: Run and watch it fail.** `xcodegen generate && xcodebuild test -scheme markdown -destination 'platform=macOS' -only-testing:MarkdownAppTests/CustomStylesheetTests` → FAIL (`cannot find 'CustomStylesheet'`).
- [ ] **Step 8: Implement.**
  - `choose`: `NSOpenPanel` filtered to `UTType(filenameExtension: "css")`.
  - `save`: `url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess])` into `UserDefaults`.
  - `load`: resolve, `startAccessingSecurityScopedResource`, read only if the size is ≤ `maxBytes` and it decodes as UTF-8, stop accessing; `nil` on any failure.
  - The window and PDF render paths pass `userCSS: isPro ? CustomStylesheet.load() : nil`. A saved bookmark that fails to load shows "Stylesheet unavailable: using the theme" in the settings row.
- [ ] **Step 9: Run and watch it pass.** Re-run Step 7's command → 4 pass.
- [ ] **Step 10: Commit:** `Apps/Markdown Packages/TegelKit Renderer/src/page.js`, `feat(app): custom CSS from a read-only bookmark, CSP-bound` + trailer.

### Task A4: Print header and page numbers (Pro, part of PDF export)

**Verified constraints:**
- WebKit has no page-margin boxes: in MDN browser-compat-data `css/at-rules/page.json`, `at_top-center` (and every other margin box) has Safari `version_added: false`.
- WKWebView's printing view overrides `drawPageBorderWithSize:` without calling super. It draws headers and footers only through the private UI-delegate SPI `_webViewHeaderHeight:` / `_webView:drawHeaderInRect:forPageWithTitle:URL:` (WebKit `Source/WebKit/UIProcess/mac/WKPrintingView.mm`, `UIProcess/Cocoa/UIDelegate.mm`).
- So `NSPrintInfo.AttributeKey.headerAndFooter` and `NSView.pageHeader`/`pageFooter` never reach a WKWebView print, and SPI is barred by guideline 2.5.1.
- **Decision:** stamp the exported PDF with PDFKit and Core Graphics (public APIs).

**Files:**
- Create: `Packages/TegelKit/Sources/TegelKit/PDFStamper.swift`, `Packages/TegelKit/Tests/TegelKitTests/WebView/PDFStamperTests.swift` (its end-to-end test renders)
- Modify: the PDF export call site (A0; plan 02's `ReaderController.swift`) — `stamp` runs on the `makePDFData` result before its one `data.write(to:)`, so no new write appears; a "Page numbers" toggle, `@AppStorage("TGPDFPageNumbers")`, default on; its accessory view (`DESIGN.md`); `Localizable.xcstrings`

**Interfaces:**
- Consumes: `PDFExporter.makePDFData(_:paper:) async throws -> Data` (plan 02); `RenderResult.headings`.
- Produces: `public enum PDFStamper { public static func stamp(_ pdf: Data, header: String?) throws -> Data }`, in memory, no file I/O (the `readonly-gate` stays unchanged). The footer is always `"<n> / <N>"`, centred, Western digits. The header is centred: the first H1's text, else the file name without its extension. Typography comes from `DESIGN.md`; baselines sit 18 pt inside the media box.

- [ ] **Step 1: Write the failing tests.**
```swift
func testStampsHeaderAndPageNumbersKeepingTextSizeAndLinks() throws {
    let pdf = try makePDF(pages: ["Alpha", "Beta", "Gamma"], link: URL(string: "https://example.com")!)  // helper: CGContext A4 pages into Data + PDFAnnotation(.link) on page 1
    let doc = try XCTUnwrap(PDFDocument(data: try PDFStamper.stamp(pdf, header: "Release notes")))
    XCTAssertEqual(doc.pageCount, 3)
    for i in 0..<3 {
        let page = try XCTUnwrap(doc.page(at: i)), text = page.string ?? ""
        XCTAssertTrue(text.contains("\(i + 1) / 3"), text)
        XCTAssertTrue(text.contains("Release notes"))
        XCTAssertTrue(text.contains(["Alpha", "Beta", "Gamma"][i]))
        XCTAssertEqual(page.bounds(for: .mediaBox).width, 595.28, accuracy: 0.5)
        XCTAssertEqual(page.bounds(for: .mediaBox).height, 841.89, accuracy: 0.5)
    }
    XCTAssertEqual(doc.page(at: 0)?.annotations.first { $0.type == "Link" }?.url, URL(string: "https://example.com"))
}
func testArabicHeaderKeepsPageCount() throws { XCTAssertEqual(PDFDocument(data: try PDFStamper.stamp(try makePDF(pages: ["a", "b"]), header: "تقرير"))?.pageCount, 2) }
func testRejectsNonPDF() { XCTAssertThrowsError(try PDFStamper.stamp(Data("no".utf8), header: nil)) }
@MainActor func testExportedPDFHasPageNumbers() async throws {   // end to end with the real renderer
    let r = RendererWebView(); _ = try await r.render(try String(contentsOf: fixtureURL("gfm-kitchen-sink.md")), options: .init(mode: .print, theme: .paper, baseURL: nil))
    let d = try XCTUnwrap(PDFDocument(data: try PDFStamper.stamp(try await PDFExporter.makePDFData(r, paper: .a4), header: "Kitchen sink"))); XCTAssertTrue(d.page(at: d.pageCount - 1)!.string!.contains("\(d.pageCount) / \(d.pageCount)"))
}
```
- [ ] **Step 2: Run and watch it fail.** `swift test --package-path Packages/TegelKit --filter PDFStamperTests` → FAIL (`cannot find 'PDFStamper' in scope`).
- [ ] **Step 3: Implement `stamp(_:header:)`.**
  - `PDFDocument(data:)`; throw `CocoaError(.fileReadCorruptFile)` if it is nil or has 0 pages.
  - Create `CGContext(consumer: CGDataConsumer(data: out)!, mediaBox: nil, nil)` over an `NSMutableData` `out`. Per page: `beginPDFPage` with that page's media box → `page.draw(with: .mediaBox, to:)` → push `NSGraphicsContext(cgContext:flipped: false)` and draw the header/footer `NSAttributedString`s → `endPDFPage`. Then `closePDF()`.
  - `PDFDocument(data: out as Data)`, add a `copy()` of every original `"Link"` annotation at the same page index, and return its `dataRepresentation()` (throw if nil).
- [ ] **Step 4: Run and watch it pass.** Re-run Step 2's command → 4 pass.
- [ ] **Step 5: Wire it in.** In `ReaderController`, `data = try PDFStamper.stamp(data, header:)` between `makePDFData` and the existing `data.write(to:)` when the toggle is on; `make readonly-gate` → exit 0 with no allowlist change. `xcodebuild build -scheme markdown -destination 'platform=macOS'` → `** BUILD SUCCEEDED **`.
- [ ] **Step 6: Commit:** `Packages/TegelKit Apps/Markdown`, `feat(pdf): header and page numbers via PDFKit (WebKit has no margin boxes)` + trailer.

### Task A5: Shortcuts actions (App Intents)

**Verified:** `AppIntent`, `IntentFile`, `OpenIntent` and `AppShortcutsProvider` are all macOS **13.0+** (Apple documentation JSON, `developer.apple.com/documentation/appintents/{appintent,intentfile,openintent,appshortcutsprovider}`), so a 14.0 target is fine.

**Files:**
- Create: `Apps/Markdown/App/Intents/{ExportPDFIntent.swift,OpenFolderIntent.swift,TegelMarkdownShortcuts.swift}`, `Apps/Markdown/AppTests/IntentsTests.swift`
- Modify: `Apps/Markdown/App/ProGate.swift`, `Localizable.xcstrings`, `AppShortcuts.xcstrings` (EN/NL/FR/AR phrases), `Makefile` (`readonly-gate` allowlist: `^Apps/Markdown/App/Intents/ExportPDFIntent\.swift:`, which writes only into the app's temporary directory)

**Interfaces:**
- Consumes: `TextFileLoader.load`, `RendererWebView`, `PDFExporter.makePDFData`, `PDFStamper.stamp`, the folder-window opener (A0), `PaperSize`.
- Produces:
  - `extension ProGate { @MainActor static func isProNow() -> Bool }` — `true` under `UNLOCKED`, otherwise the shared `LicenseManager.isPro`.
  - `struct ExportPDFIntent: AppIntent`: title "Export Markdown to PDF"; `@Parameter var file: IntentFile` (`supportedContentTypes: [UTType(importedAs: "net.daringfireball.markdown")]`); `paper: PaperSizeAppEnum = .a4` (an `AppEnum` with cases `a4`, `letter`, mapped to `PaperSize`); `pageNumbers: Bool = true`; `perform() async throws -> some IntentResult & ReturnsValue<IntentFile>`.
  - `@MainActor static func exportPDF(markdown: Data, name: String, paper: PaperSize, pageNumbers: Bool, isPro: Bool) async throws -> URL` (result in `FileManager.default.temporaryDirectory`).
  - `enum IntentError: Error, CustomLocalizedStringResourceConvertible { case needsPro, folderUnreadable }`
  - `struct OpenFolderIntent: AppIntent` (`openAppWhenRun = true`; `@Parameter var folder: IntentFile`, `[.folder]`). `struct TegelMarkdownShortcuts: AppShortcutsProvider`: two shortcuts, with phrases containing `\(.applicationName)`.

- [ ] **Step 1: Write the failing tests.**
  - `testExportReturnsPagedA4PDFInTemp`: fixture `gfm-kitchen-sink.md`, `isPro: true` → `pageCount > 1`; page 0 media box 595.28 × 841.89 ± 0.5; the path is under the temporary directory; the last page's text contains `"\(n) / \(n)"`.
  - `testExportRefusesFreeTier`: throws `IntentError.needsPro`.
- [ ] **Step 2: Run and watch it fail.** `xcodegen generate && xcodebuild test -scheme markdown -destination 'platform=macOS' -only-testing:MarkdownAppTests/IntentsTests` → FAIL (`cannot find 'ExportPDFIntent'`).
- [ ] **Step 3: Implement.**
  - `exportPDF`: write `markdown` to a temp `.md` → `TextFileLoader.load` → render in `.print` mode with the saved theme and `userCSS` → `makePDFData` → stamp if `pageNumbers` → write the data to a temp `.pdf` → return the URL.
  - `perform` calls `exportPDF(…, isPro: ProGate.isProNow())` and returns `IntentFile(fileURL:filename:type: .pdf)`. Shortcuts decides where to save, so the app writes only to its container (rule 1).
  - `OpenFolderIntent.perform` requires Pro and opens `folder.fileURL` through the folder opener. If the URL is missing or unreadable in the sandbox, it shows an `NSOpenPanel` with `directoryURL` set to it, so one click grants access.
- [ ] **Step 4: Run and watch it pass, then clear the gate.** Re-run Step 2's command → 2 pass. The gate uses `git grep`, which skips untracked files, so stage the new files first: `git add Apps/Markdown/App/Intents && make readonly-gate` → FAIL naming `ExportPDFIntent.swift` (watched); add its allowlist entry → exit 0.
- [ ] **Step 5: Discoverability.** `make build && test -d "$(find build -name 'Tegel Markdown.app' -maxdepth 6 | head -1)/Contents/Resources/Metadata.appintents" && echo OK` → `OK`. Manual: Shortcuts.app lists both actions, and "Open Folder in Tegel Markdown" with a Folder action opens the sidebar; screenshot to `docs/qa/v1.1/shortcuts.png`.
- [ ] **Step 6: Commit:** `Apps/Markdown docs/qa/v1.1`, `feat(app): Shortcuts actions for PDF export and Open Folder` + trailer.

### Task A6: v1.1 QA matrix → `docs/qa/v1.1-matrix.md`

- [ ] **Step 1: Local (macOS 15, Intel, the build Mac).** `make check`, then the plan 05 matrix rows plus the new rows: math (inline, block, Arabic); footnotes (scroll, RTL); custom CSS (apply, delete the file, oversize); PDF header and numbers (A4, Letter, RTL document); both Shortcuts. Record pass/fail per row and the machine. Plan 05's R9 and R11 need a production App 1 key, but `POLAR_QA_LICENSE_KEY` is empty after plan 06 Task 16 Step 6: re-issue it under the same name with plan 06 Task 12 Step 3's App 1 QA pattern (🔒, a new discount code), and revoke it and empty it the same way when the matrix is done.
- [ ] **Step 2: macOS 26 arm64.** (Needs the user's `gh auth login`.) `gh workflow run` creates the run asynchronously, so wait for a run id other than the newest one before the dispatch (plan 09 Task 11 Step 9's pattern; a non-interactive `gh run watch` needs the id):
  ```bash
  OLD=$(gh run list --workflow ci.yml --branch m07a-v1.1 --event workflow_dispatch -L1 --json databaseId -q '.[0].databaseId')
  gh workflow run ci.yml --ref m07a-v1.1
  for i in $(seq 30); do ID=$(gh run list --workflow ci.yml --branch m07a-v1.1 --event workflow_dispatch -L1 --json databaseId -q '.[0].databaseId'); [ -n "$ID" ] && [ "$ID" != "$OLD" ] && break; sleep 2; done
  [ "$ID" != "$OLD" ] && gh run watch --exit-status "$ID"
  ```
  Expected: the macOS jobs are green; link the run URL.
- [ ] **Step 3: macOS 27 arm64 on Scaleway** (M1, €3.19 incl. VAT for 24 h [F9], master H6; purchase approval first; ordered and released with H6's lease lifecycle). Commit Steps 1–2's rows first (Commit: `docs/qa/v1.1-matrix.md`, `docs(qa): v1.1 matrix, local and macOS 26 rows` + trailer; `git status --porcelain -- . ':(exclude)docs'` → empty, since `release.sh` needs a clean tree). Then install a notarised release candidate from `scripts/release.sh markdown 1.1.0-rc1 --no-upload`. Run the new rows plus the G0 timing for `g0-1mb.md` and a math-heavy file (< 1 s).
- [ ] **Step 4: Commit** the matrix (Step 3's rows).

### Task A7: Pipeline P, then release v1.1.0

- [ ] **Step 1: Run Procedure P (master §11) for `m07a`.** `/cso` scope: KaTeX insertion and sanitisation, the `trust: false` options; user CSS (CSP, `textContent`, size cap, read-only bookmark); App Intents file input and temp files; the `readonly-gate` allowlist entry. Design review: the custom-CSS row, the export accessory, stamped pages.
- [ ] **Step 2: Merge and push** (P step 11).
- [ ] **Step 3: Release** (approval of this release). On `main`: `scripts/release.sh markdown 1.1.0 --no-upload`; run the A6 rows on that DMG and commit them to `docs/qa/v1.1-matrix.md` (`docs(qa): v1.1.0 DMG rows` + trailer; `git status --porcelain -- . ':(exclude)docs'` → empty, since `--from-dmg` still runs the clean-tree check); then `scripts/release.sh markdown 1.1.0 --yes --from-dmg <path>` (K7; `--yes` only after this release's approval, since without a terminal the prompt aborts) → `spctl -a -vv` shows `accepted … source=Notarized Developer ID`. `curl -s https://downloads.tegelapps.com/<appcast path from A0> | grep -c '1.1.0'` ≥ 1. A Sparkle update from 1.0.x on the build Mac shows 1.1.0 in About.
- [ ] **Step 4: Release notes and site keys.** The site step in Global Constraints (keys, `/changelog/` entry), with the release notes in the same commit. `curl -sI https://tegelapps.com/<changelog path>` → 200.

---

## Section B: Mac App Store edition of App 1 (`m07b-mas`)

**Binding rules:**
- **Guideline 2.4.5** (developer.apple.com/app-store/review/guidelines/): (i) appropriately sandboxed; (ii) packaged with Xcode, no third-party installers; (iii) no auto-launch without consent; (iv) may not download code; (v) no root escalation; (vi) may not "present a license screen at launch, require license keys, or implement their own copy protection"; (vii) "must use the Mac App Store to distribute updates"; (viii) currently shipping OS, no deprecated tech; (ix) all localisations in one bundle.
- **Guideline 2.5.1:** "Apps may only use public APIs".

**Bundle-id decision:** keep `com.tegelapps.markdown` and `com.tegelapps.markdown.quicklook`. The App Store enforces bundle-id uniqueness through App IDs. A Developer ID app with no restricted entitlements needs no App ID or profile (Apple DTS, developer.apple.com/forums/thread/750645), so we may register ours for the MAS build. One id = one container and one Quick Look provider for `net.daringfireball.markdown`. B5 checks how the App Store treats an existing DMG copy.

### Task B0: Re-validate MAS assumptions → `docs/reviews/m07b-revalidation.md`

- [ ] **Step 1: Gate and branch.** G2 ≠ FREEZE and `m07a` is merged. `git checkout -b m07b-mas main`.
- [ ] **Step 2: SDK rule.** Record the newest "built with Xcode N" rule and its date from developer.apple.com/news/upcoming-requirements/ (today: "Xcode 26 or later", since 28 Apr 2026). If submission day needs an Xcode newer than 26.3, CI is mandatory [F2]; otherwise the build Mac may build too.
- [ ] **Step 3: Runner image.** `curl -s https://raw.githubusercontent.com/actions/runner-images/main/images/macos/macos-26-arm64-Readme.md | grep -A12 '### Xcode'`. On 27 Oct 2026 the default was 26.6 (17F113), with 26.3, 26.4.1 and 26.5 installed; `xcode-27` was a preview image [F7]. Choose the newest GA Xcode that meets Step 2. Record the full commit SHA of the release of every action `mas.yml` uses (`actions/checkout`) and the XcodeGen release version plus the sha256 of its `xcodegen.zip`; B3 pins `mas.yml` to them (S25).
- [ ] **Step 4: Source split, by an explicit file list.** A grep can't decide it: `MarkdownApp.swift` imports Sparkle and is the `@main` entry the store targets need, and plan 06 Task 8 compiles `ProGate.swift`, `LicenceSettingsView.swift` and `UpdatesSettingsView.swift` into `data` by path. Run `grep -rlE "import (Sparkle|TegelStore)|TGPolar|SUFeedURL|checkoutURL|portalURL" Apps/Markdown/App` as input only, then write three named lists into the revalidation doc, every hit in exactly one:
  - **Move to `Direct/`** (B1): files only the direct app uses and no other target names by path: `ProUpsellView.swift`, plus any hit that meets both conditions. Check: `grep -n 'Apps/Markdown/App/' project.yml` names none of them.
  - **Stay, excluded by name from the store targets:** `LicenceSettingsView.swift` and `UpdatesSettingsView.swift` (App 2 compiles them from these paths).
  - **Stay, gated with `#if !UNLOCKED`** (B1 Step 5): `MarkdownApp.swift`, `ProGate.swift`, the Settings tab view, and every other hit.
- [ ] **Step 5: Human checkpoint H-M1 (Account Holder).** Create the **Apple Distribution** and **Mac Installer Distribution** certificates; register the explicit App IDs `com.tegelapps.markdown` and `com.tegelapps.markdown.quicklook`; create a Team API key "tegel-ci-mas" with role **App Manager** → `.env` keys `ASC_CI_API_KEY_ID`, `ASC_CI_API_ISSUER_ID`, `ASC_CI_API_KEY_PATH`. Check: `security find-identity -v -p codesigning | grep -c "Apple Distribution"` ≥ 1.
- [ ] **Step 6: Commit** the revalidation doc.

### Task B1: Channel split and the `MarkdownMAS` targets

**Files:**
- Create: `scripts/verify-store-build.sh`, `Apps/Markdown/App/DistributionChannel.swift`, `Apps/Markdown/MAS/{Markdown.entitlements,QuickLook.entitlements}`, `Apps/Markdown/MASTests/ChannelTests.swift`
- Move (`git mv`): the B0 Step 4 "Move" list, and nothing else → `Apps/Markdown/App/Direct/`
- Modify: `project.yml`, `Apps/Markdown/App/ProGate.swift`, the app entry/menu file (`#if !UNLOCKED` around the updater and licence items), Copy Diagnostics (adds the channel)

**Interfaces:**
- Consumes: `ProGate.isProNow()` (A5).
- Produces:
  - Compilation conditions `UNLOCKED` (no Sparkle, no TegelStore, `isPro == true`), `MAS`, `SETAPP`.
  - `enum DistributionChannel: String { case direct, mas, setapp; static var current: DistributionChannel }`
  - `scripts/verify-store-build.sh <App.app> <mas|setapp>`: exit 0 prints `verify-store-build: PASS`; exit 1 prints one `FAIL: <reason>` line per violation.

- [ ] **Step 1: Write the guard script.**
  - Both modes, over every Mach-O file in the bundle (`find "$APP" -type f -exec file {} + | grep Mach-O`; this covers Debug's `.debug.dylib` and the `.appex`):
    - no `Contents/Frameworks/Sparkle.framework`;
    - `otool -L` shows no `Sparkle`;
    - `strings -a` contains none of `polar.sh`, `sparkle-project`, `SUFeedURL`, `TegelStore`;
    - Info.plists have no `SUFeedURL`, `SUPublicEDKey` or `TGPolar*` key;
    - `codesign -d --entitlements - --xml` on the app and the appex shows `com.apple.security.app-sandbox` true.
  - `mas`: no entitlement key containing `temporary-exception`; `ITSAppUsesNonExemptEncryption` false; `LSApplicationCategoryType` = `public.app-category.developer-tools`.
  - `setapp`: the bundle id ends with `-setapp`; `NSUpdateSecurityPolicy` is present; `Contents/Resources/setappPublicKey.pem` exists; the only temporary exception is `mach-lookup.global-name = [com.setapp.ProvisioningService]`.
- [ ] **Step 2: Watch it fail on the direct build.** `make build && scripts/verify-store-build.sh "$(find build -name 'Tegel Markdown.app' -maxdepth 6 | head -1)" mas` → exit 1, with FAIL lines for Sparkle.framework, `polar.sh`, `SUFeedURL` and `temporary-exception`.
- [ ] **Step 3: Write the failing MAS unit test.**
```swift
@MainActor final class ChannelTests: XCTestCase {
    func testMASBuildIsUnlockedWithoutLicensingOrUpdater() {
        XCTAssertEqual(DistributionChannel.current, .mas)
        XCTAssertTrue(ProGate.isProNow())
        XCTAssertNil(Bundle.main.object(forInfoDictionaryKey: "SUFeedURL"))
        XCTAssertNil(Bundle.main.object(forInfoDictionaryKey: "TGPolarAPIBase"))
    }
}
```
- [ ] **Step 4: Add the targets to `project.yml`** (values fixed here; everything else is copied from the direct targets):
```yaml
  MarkdownMAS:
    type: application
    platform: macOS
    sources: [{ path: Apps/Markdown/App, excludes: ["Direct/**", "LicenceSettingsView.swift", "UpdatesSettingsView.swift"] }]   # B0 Step 4's lists
    dependencies: [{ package: TegelKit, product: TegelKit }, { target: MarkdownMASQuickLook }]
    info: { path: Apps/Markdown/MAS/Info.plist, properties: { LSApplicationCategoryType: public.app-category.developer-tools, ITSAppUsesNonExemptEncryption: false } }  # plus the direct target's document types and UTI imports; no SU*/TG* keys
    settings:
      base: { PRODUCT_BUNDLE_IDENTIFIER: com.tegelapps.markdown, SWIFT_ACTIVE_COMPILATION_CONDITIONS: "$(inherited) MAS UNLOCKED",
              CODE_SIGN_ENTITLEMENTS: Apps/Markdown/MAS/Markdown.entitlements, ENABLE_HARDENED_RUNTIME: YES }
      configs:
        Debug: { CODE_SIGN_STYLE: Manual, CODE_SIGN_IDENTITY: "-" }   # ad hoc, as the direct target: B0 creates no development certificate (CR-P2-10)
        Release: { CODE_SIGN_STYLE: Automatic, CODE_SIGN_IDENTITY: "Apple Distribution" }   # archive and export only; overrides Release.xcconfig's Developer ID selector; mas.sh passes DEVELOPMENT_TEAM
  MarkdownMASQuickLook:   # app-extension; sources Apps/Markdown/QuickLook; bundle id com.tegelapps.markdown.quicklook; CODE_SIGN_ENTITLEMENTS Apps/Markdown/MAS/QuickLook.entitlements; same Debug/Release signing split
  MarkdownMASTests:       # bundle.unit-test; sources Apps/Markdown/MASTests; depends on MarkdownMAS; TEST_HOST = the MarkdownMAS app
```
  Entitlements — app: `app-sandbox`, `files.user-selected.read-write`, `files.bookmarks.app-scope`, `network.client` (WebKit in a sandbox, FB6993802 [F5]). Quick Look: `app-sandbox` and `network.client` only. As in the Developer ID build (master D5, K4), Quick Look has no `temporary-exception.files.absolute-path.read-only` and shows no local images [F5].
- [ ] **Step 5: Implement.** `ProGate`: `#if UNLOCKED` → `isPro` is the constant `true` and `isProNow()` returns `true`. `DistributionChannel.current`: `#if MAS .mas #elseif SETAPP .setapp #else .direct`. The menu and app entry wrap the updater and licence items in `#if !UNLOCKED`. `ProUpsellView.swift` (which declares `UpsellFeature` and, after plan 08 Task 12, `UpsellContext` and calls `checkoutURL(ref:)`) matches the B0 Step 4 grep and moves to `Direct/`, so the `pro` `WindowGroup`, the `UpsellContext` environment value and every `openWindow(id: "pro", …)` call site (Open Folder…, folder drops, licence lapse, Export as PDF, the theme picker) also sit in `#if !UNLOCKED`; with `isPro == true` they never run there anyway (CR-P2-11). Step 6's MAS build is the check: a missed call site fails it with `cannot find 'UpsellFeature' in scope`.
- [ ] **Step 6: Watch it pass.**
  ```bash
  xcodegen generate && xcodebuild test -scheme MarkdownMAS -destination 'platform=macOS' -only-testing:MarkdownMASTests
  xcodebuild build -scheme MarkdownMAS -configuration Debug -destination 'platform=macOS'
  scripts/verify-store-build.sh <MarkdownMAS Debug .app path> mas
  ```
  Expected: the test passes; `** BUILD SUCCEEDED **`; `verify-store-build: PASS`. The direct scheme still passes `make check`, whose `build` also builds `data`: that proves plan 06's by-path sources (`ProGate.swift`, `LicenceSettingsView.swift`, `UpdatesSettingsView.swift`) still resolve.
- [ ] **Step 7: Commit:** `project.yml Apps/Markdown scripts/verify-store-build.sh`, `feat(mas): MarkdownMAS targets, UNLOCKED split, store-build guard` + trailer.

### Task B2: Quick Look image placeholder (only if A0 found none)

**Files:** Modify `Renderer/src/page.js`, `Renderer/src/css/base.css`. Test: `WebView/UserCSSTests.swift` (adds `testBrokenImageBecomesPlaceholder`).

**Interfaces:** Produces: a failed `<img>` is replaced by `<span class="img-placeholder" role="img" aria-label="<alt>"><alt></span>`.

- [ ] **Step 1: Write the failing test.** Use a relative `src`, the real case: plan 01's sanitiser drops every `file:` URL, so a `file:` image has no `src`, never fires `error` and can't test this. Render `![Flow diagram](images/x.png)` twice: with `baseURL: nil` (Quick Look: the `src` stays relative and can't load), and with `baseURL` = a temp folder's `doc.md` that has no `images/` (the window: plan 02 rewrites the `src` to `tegel-doc:` and the handler answers 404). Each time, wait for `rendered` + 300 ms → `document.querySelector('img') == null` and `document.querySelector('.img-placeholder').textContent == "Flow diagram"`.
- [ ] **Step 2: Watch it fail.** `swift test --package-path Packages/TegelKit --filter testBrokenImageBecomesPlaceholder` → FAIL (null).
- [ ] **Step 3: Implement.** `page.js` adds an `error` listener per `img` that builds the span with `textContent` from `alt` (never `innerHTML`) and calls `replaceWith`.
- [ ] **Step 4: Watch it pass.** `make renderer`, then re-run Step 2's command → PASS.
- [ ] **Step 5: Commit** `Renderer` and `Packages/TegelKit` (`feat(renderer): placeholder for unreadable images`, plus the co-author line).

### Task B3: MAS build script and CI workflow, with the keychain import

**Files:** Create `scripts/mas.sh`, `scripts/ExportOptions-MAS.plist`, `.github/workflows/mas.yml`. Modify `.env.example` (adds `ASC_CI_API_KEY_ID`, `ASC_CI_API_ISSUER_ID`, `ASC_CI_API_KEY_PATH`) and `scripts/check-guards.sh` (plan 01; the inputs guard, S24).

**Interfaces:**
- Consumes: `scripts/verify-store-build.sh`, `APPLE_TEAM_ID`.
- Produces: `scripts/mas.sh <version> <build> [--upload]` → `build/MAS.xcarchive`, then `build/MAS-export/*.pkg` or an upload to App Store Connect.

**Verified:** local Xcode 26.3 `xcodebuild -help` lists export `method` `app-store-connect`, `destination` `export|upload`, and `-allowProvisioningUpdates` with `-authenticationKeyPath/-authenticationKeyID/-authenticationKeyIssuerID`. The keychain commands follow docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications.

- [ ] **Step 1: `ExportOptions-MAS.plist`:** `method` = `app-store-connect`; `signingStyle` = `automatic`; `teamID` = `__TEAM__` (filled by the script); `destination` = `export`; `uploadSymbols` = true; `manageAppVersionAndBuildNumber` = false.
- [ ] **Step 2: `scripts/mas.sh`** (`set -euo pipefail`):
  - `[[ $1 =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ && $2 =~ ^[0-9]+$ ]] || { echo "usage: mas.sh <X.Y[.Z]> <build> [--upload]" >&2; exit 2; }`
  - `: "${APPLE_TEAM_ID:?APPLE_TEAM_ID is empty}"` (Release.xcconfig leaves `DEVELOPMENT_TEAM` empty, and automatic signing can't archive without a team)
  - `xcodegen generate`
  - `xcodebuild archive -scheme MarkdownMAS -configuration Release -archivePath build/MAS.xcarchive MARKETING_VERSION=$1 CURRENT_PROJECT_VERSION=$2 DEVELOPMENT_TEAM="$APPLE_TEAM_ID" -allowProvisioningUpdates -authenticationKeyPath "$ASC_CI_API_KEY_PATH" -authenticationKeyID "$ASC_CI_API_KEY_ID" -authenticationKeyIssuerID "$ASC_CI_API_ISSUER_ID"`
  - `scripts/verify-store-build.sh "build/MAS.xcarchive/Products/Applications/Tegel Markdown.app" mas`
  - Copy the plist to `build/ExportOptions.plist`; `plutil -replace teamID -string "$APPLE_TEAM_ID"`; with `--upload`, also `plutil -replace destination -string upload`.
  - `xcodebuild -exportArchive -archivePath build/MAS.xcarchive -exportPath build/MAS-export -exportOptionsPlist build/ExportOptions.plist` plus the same auth flags.
- [ ] **Step 3: Local dry run** (only if B0 allows Xcode 26.3). `. scripts/lib/env.sh && APPLE_TEAM_ID="$(envget APPLE_TEAM_ID)" ASC_CI_API_KEY_PATH="$(envget ASC_CI_API_KEY_PATH)" ASC_CI_API_KEY_ID="$(envget ASC_CI_API_KEY_ID)" ASC_CI_API_ISSUER_ID="$(envget ASC_CI_API_ISSUER_ID)" scripts/mas.sh 1.1.0 110`, then `codesign -dv --verbose=2 "build/MAS.xcarchive/Products/Applications/Tegel Markdown.app" 2>&1 | grep -c "Authority=Apple Distribution"` → `1` (if `xcodebuild` rejects the `Apple Distribution` identity under automatic signing, record its error in the B0 doc and fix the MAS Release signing before Step 8's CI run), and `pkgutil --check-signature build/MAS-export/*.pkg | grep -E "Mac Installer Distribution|3rd Party Mac Developer Installer"` → one match.
- [ ] **Step 4: Add the inputs guard to `check-guards.sh` and watch it fail (S24).** Plan 01's script already fails `make check` on an unpinned `uses:` (S25); this adds one rule: `${{ inputs.* }}` reaches a workflow only as a `NAME: ${{ inputs.x }}` env entry, never inline in `run:`. Plant first:
```bash
mkdir -p .github/workflows && printf '      - run: echo ${{ inputs.version }}\n      VERSION: ${{ inputs.version }}\n      - env: { TAG: "${{ inputs.tag }}" }\n' > .github/workflows/planted.yml
make test-shell; echo "exit=$?"
```
Expected: `exit=0`; nothing catches it yet. Insert this line into the script's `{ … }` group, above the `uses:` grep (each `NAME: ${{ inputs.x }}` entry is stripped, block or flow style; any `${{ inputs.` left is a hit), and append `; pass workflow inputs through env:` to its error message:
```sh
          grep -rnE '\$\{\{ *inputs\.' .github/workflows | sed -E 's/([{,:][[:space:]-]*)[A-Z_]+: "?\$\{\{ *inputs\.[a-z_]+ *\}\}"?/\1/g' | grep -E '\$\{\{ *inputs\.'
```
Re-run `make test-shell; echo "exit=$?"`. Expected: exactly `.github/workflows/planted.yml:1:      - run: echo ${{ inputs.version }}`, the `check-guards:` line and `exit=1`; lines 2–3 (the allowed env forms) aren't listed. `rm .github/workflows/planted.yml`, then `make test-shell` → exit 0 (plan 05's `smoke.yml` passes `TAG` through `env:`).
- [ ] **Step 5: Write `.github/workflows/mas.yml`.** Inputs reach the shell only through `env:` and are checked against a pattern before use; the job's token can only read; the imported keys are usable only by `codesign` and `productbuild` (S24); xcodegen comes from a pinned, checksummed release (S25).
```yaml
name: mas
on:
  workflow_dispatch:
    inputs: { version: { required: true }, build: { required: true }, xcode: { required: true, default: "26.6" }, upload: { type: boolean, default: false } }
permissions:
  contents: read
jobs:
  mas:
    runs-on: macos-26
    timeout-minutes: 45
    env:
      APPLE_TEAM_ID: "${{ secrets.APPLE_TEAM_ID }}"
      ASC_CI_API_KEY_ID: "${{ secrets.ASC_CI_API_KEY_ID }}"
      ASC_CI_API_ISSUER_ID: "${{ secrets.ASC_CI_API_ISSUER_ID }}"
      VERSION: ${{ inputs.version }}
      BUILD: ${{ inputs.build }}
      XCODE: ${{ inputs.xcode }}
      UPLOAD: ${{ inputs.upload }}
      XCODEGEN_VERSION: "<B0 version>"
      XCODEGEN_SHA256: "<B0 sha256>"
    steps:
      - name: Check inputs
        run: |
          [[ $VERSION =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ && $BUILD =~ ^[0-9]+$ && $XCODE =~ ^[0-9]+(\.[0-9]+)*$ && $UPLOAD =~ ^(true|false)$ ]] || { echo "bad input" >&2; exit 2; }
      - uses: actions/checkout@<full commit SHA recorded in B0>  # v7
      - run: sudo xcode-select -s "/Applications/Xcode_${XCODE}.app" && xcodebuild -version
      - name: Install pinned XcodeGen
        run: |
          curl -fsSL -o "$RUNNER_TEMP/xcodegen.zip" "https://github.com/yonaskolb/XcodeGen/releases/download/${XCODEGEN_VERSION}/xcodegen.zip"
          echo "${XCODEGEN_SHA256}  $RUNNER_TEMP/xcodegen.zip" | shasum -a 256 -c -
          unzip -q "$RUNNER_TEMP/xcodegen.zip" -d "$RUNNER_TEMP" && echo "$RUNNER_TEMP/xcodegen/bin" >> "$GITHUB_PATH"
      - name: Import signing identities and API key
        env: { DIST_P12: "${{ secrets.MAS_DIST_CERT_P12_BASE64 }}", INST_P12: "${{ secrets.MAS_INSTALLER_CERT_P12_BASE64 }}", P12_PASSWORD: "${{ secrets.MAS_P12_PASSWORD }}", KEYCHAIN_PASSWORD: "${{ secrets.KEYCHAIN_PASSWORD }}", ASC_P8: "${{ secrets.ASC_CI_KEY_P8_BASE64 }}" }
        run: |
          KC="$RUNNER_TEMP/app-signing.keychain-db"
          echo "$DIST_P12" | base64 --decode > "$RUNNER_TEMP/dist.p12"; echo "$INST_P12" | base64 --decode > "$RUNNER_TEMP/inst.p12"
          security create-keychain -p "$KEYCHAIN_PASSWORD" "$KC"
          security set-keychain-settings -lut 21600 "$KC"
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KC"
          security import "$RUNNER_TEMP/dist.p12" -P "$P12_PASSWORD" -T /usr/bin/codesign -T /usr/bin/productbuild -t cert -f pkcs12 -k "$KC"
          security import "$RUNNER_TEMP/inst.p12" -P "$P12_PASSWORD" -T /usr/bin/codesign -T /usr/bin/productbuild -t cert -f pkcs12 -k "$KC"
          security set-key-partition-list -S apple-tool:,apple: -k "$KEYCHAIN_PASSWORD" "$KC"
          security list-keychain -d user -s "$KC"
          echo "$ASC_P8" | base64 --decode > "$RUNNER_TEMP/AuthKey.p8"; echo "ASC_CI_API_KEY_PATH=$RUNNER_TEMP/AuthKey.p8" >> "$GITHUB_ENV"
          rm "$RUNNER_TEMP/dist.p12" "$RUNNER_TEMP/inst.p12"
      - run: if [ "$UPLOAD" = true ]; then scripts/mas.sh "$VERSION" "$BUILD" --upload; else scripts/mas.sh "$VERSION" "$BUILD"; fi
      - if: always()
        run: security delete-keychain "$RUNNER_TEMP/app-signing.keychain-db" || true; rm -f "$RUNNER_TEMP/AuthKey.p8"
```
  Then `make test-shell` → exit 0 (the `VERSION: ${{ inputs.version }}` lines are the allowed form).
- [ ] **Step 6: Secrets (human checkpoint H-M2).** The user exports both identities from Keychain Access as `.p12` files outside the repo and runs `gh auth login`. The workflow runs `base64 --decode` on the three `*_BASE64` secrets, so encode those files first: `base64 -i <file> | gh secret set <NAME>` for `MAS_DIST_CERT_P12_BASE64` (the distribution `.p12`), `MAS_INSTALLER_CERT_P12_BASE64` (the installer `.p12`) and `ASC_CI_KEY_P8_BASE64` (the `.p8` at `ASC_CI_API_KEY_PATH`). The other five are stored raw: `gh secret set <NAME> < <file>` for `APPLE_TEAM_ID`, `MAS_P12_PASSWORD`, `KEYCHAIN_PASSWORD`, `ASC_CI_API_KEY_ID`, `ASC_CI_API_ISSUER_ID`. Check: `gh secret list` shows all 8 names.
- [ ] **Step 7: Commit:** `scripts/mas.sh scripts/ExportOptions-MAS.plist scripts/check-guards.sh .github/workflows .env.example`, `build(mas): archive/export script, macos-26 CI with a temporary keychain, pinned actions` + trailer.
- [ ] **Step 8: Land `mas.yml` on `main` (K13), then the CI dry run.** GitHub dispatches only workflows that exist on the default branch. As plan 09 Task 11 Step 9 lands `design-shots.yml`:

```bash
git switch main && git pull --ff-only && git checkout m07b-mas -- .github/workflows/mas.yml
git commit -m "ci: MAS archive workflow, dispatch only" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

  Before pushing, a cold code-review subagent reviews `git show HEAD` against B6's `mas.yml` `/cso` items (inputs only through `env:` and checked, `permissions: contents: read`, `-T` not `-A`, keychain cleanup, pinned SHAs and XcodeGen checksum). Fix and amend until it finds no P0/P1. On `main` the file is inert until dispatched, and it runs the `scripts/mas.sh` of the ref it's given.

```bash
git push origin main && git switch m07b-mas && git push -u origin m07b-mas
OLD=$(gh run list --workflow mas.yml --branch m07b-mas -L1 --json databaseId -q '.[0].databaseId')
gh workflow run mas.yml --ref m07b-mas -f version=1.1.0 -f build=110 -f xcode=<B0> -f upload=false
for i in $(seq 30); do ID=$(gh run list --workflow mas.yml --branch m07b-mas -L1 --json databaseId -q '.[0].databaseId'); [ -n "$ID" ] && [ "$ID" != "$OLD" ] && break; sleep 2; done
[ "$ID" != "$OLD" ] && gh run watch --exit-status "$ID" && gh run view "$ID" --log | grep -c "verify-store-build: PASS"
```

  `gh workflow run` creates the run asynchronously, so the loop waits up to 60 s for a run id other than the newest one before the dispatch (plan 09 Task 11 Step 9's pattern). Expected: success, then `1`. (About 20 macOS minutes [F7].)

### Task B4: App Store Connect record and listing

**Files:** Create `docs/mas/listing.md`, `docs/mas/screenshots/0{1..5}.png`

- [ ] **Step 1: Write `docs/mas/listing.md`.**
  - **Text fields:** Name "Tegel Markdown" (≤ 30 chars; availability is checked when the record is created); subtitle ≤ 30; promotional text ≤ 170; description ≤ 4,000, stating honestly "Quick Look previews show placeholders for local images" (true of every edition: master D5, K4); keywords ≤ 100.
  - **URLs:** support `https://tegelapps.com/faq/` (plan 04's FAQ, with plan 05's known issues); privacy `https://tegelapps.com/privacy`.
  - **Category:** Developer Tools (secondary: Productivity).
  - **Price:** USD base storefront at **$19.00**. Apple's grid offers rounded `.00` endings (developer.apple.com/news/?id=qzex35ch); if $19.00 isn't offered, use the nearest point ≤ $19. Record Apple's generated NL price.
  - **Age rating:** 4+ (all "None"). **Export compliance:** no non-exempt encryption.
  - **App Privacy: "Data Not Collected".** Apple: "'Collect' refers to transmitting data off the device…" (developer.apple.com/app-store/app-privacy-details/). The MAS build has no network code path (B1 guard, A3 CSP test).
  - **Review notes:** no account needed, all features unlocked; `network.client` is required by WebKit inside the sandbox, the renderer CSP has `default-src 'none'` and the app makes no requests; how to enable the Quick Look extension; a sample `.md` attached.
  - All copy follows rules 3, 5 and 6: no "was" price, no holiday wording, no other platforms or prices.
- [ ] **Step 2: Five real screenshots** at 2880 × 1800, PNG, no alpha (developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/), layout from `DESIGN.md`, neutral fixture text: folder mode; Arabic RTL document; Mermaid; the paginated PDF with page numbers; Quick Look in Finder. Check: `sips -g pixelWidth -g pixelHeight -g hasAlpha docs/mas/screenshots/*.png` → `2880`, `1800`, `no` each.
- [ ] **Step 3: Create the record** (approval). App Store Connect → Apps → + → macOS, bundle id `com.tegelapps.markdown`, SKU `tegel-markdown-mas`; enter the listing. Check: the record shows "Prepare for Submission".
- [ ] **Step 4: Commit** `docs/mas/`.

### Task B5: TestFlight QA and the guidelines checklist → `docs/mas/review-checklist.md`

- [ ] **Step 1: Upload a build** (approval). `gh workflow run mas.yml --ref m07b-mas -f version=1.1.0 -f build=111 -f xcode=<B0> -f upload=true` (only the branch has `MarkdownMAS` until B6 merges); wait for "Ready to Test" in TestFlight.
- [ ] **Step 2: Install on the build Mac** (H-M3: the user signs in to TestFlight). Check:
  - it launches; folder mode and PDF export work with no licence UI; there's no "Check for Updates…" or licence menu item; a save-panel export writes the file;
  - Quick Look shows a placeholder for a local image; both Shortcuts appear;
  - `codesign -dv --verbose=2 "/Applications/Tegel Markdown.app" 2>&1 | grep Authority` shows Apple Mac OS Application Signing;
  - what happens when the DMG copy is already in `/Applications` (installs over it, or asks to remove it). Add a FAQ line either way.
- [ ] **Step 3: Checklist rows**, one per item with an evidence command and its output:
  - (i) the `codesign` entitlements; (ii) export method `app-store-connect`;
  - (iii) `grep -rn "SMAppService\|LSSharedFileList" Apps/` is empty; (iv) the CSP plus bundled KaTeX and Mermaid;
  - (v) `grep -rn "AuthorizationExecuteWithPrivileges\|SMJobBless" Apps/` is empty; (vi)/(vii) `verify-store-build.sh` PASS;
  - (viii) `xcodebuild -showsdks` plus the macOS 27 run (A6); (ix) `ls "…/Contents/Resources" | grep -E "(en|nl|fr|ar)\.lproj"`;
  - 2.5.1: page numbers via PDFKit, not WebKit SPI; `strings` on the binary has no `_webViewHeaderHeight`.
- [ ] **Step 4: Commit** the checklist.

### Task B6: Pipeline P, then submit for review

- [ ] **Step 1: Run Procedure P (master §11) for `m07b`.** `/cso` scope: MAS and Quick Look entitlements; the `UNLOCKED` split (no licence bypass reaches the direct build); `mas.yml` (inputs only through `env:` and checked, `permissions: contents: read`, `-T` not `-A`, keychain cleanup, pinned SHAs and XcodeGen checksum; `check-guards.sh` green in `make check`); `mas.sh` argument checks. Design review: screenshots and the menu without licence items.
- [ ] **Step 2: Merge and push.**
- [ ] **Step 3: Submit for Review** (approval of this submission). Log rejections in `docs/mas/review-log.md`; fix → P stages 2–4 → resubmit, with approval each time.
- [ ] **Step 4: On approval.** Release manually (approval). Add "Also on the Mac App Store" and a FAQ entry ("same features; licences don't transfer between the direct and App Store editions") to the site. `curl -s https://tegelapps.com/markdown | grep -c "apps.apple.com"` ≥ 1. Later MAS updates run `gh workflow run mas.yml --ref main … -f upload=true`, each with approval.

---

## Section C: bundle check, Setapp, Homebrew (`m07c-bundle-setapp`)

### Task C0: Re-validate → `docs/reviews/m07c-revalidation.md`

- [ ] **Step 1: Gate and branch.** `docs/gates/G3.md` shows APP3 or NO-NEW-APP. `git checkout -b m07c-bundle-setapp main`.
- [ ] **Step 2: What plan 06 built.** `. scripts/lib/env.sh; curl -s -H "Authorization: Bearer $(envget POLAR_ACCESS_TOKEN)" "https://api.polar.sh/v1/products/?organization_id=$(envget POLAR_ORGANIZATION_ID)&limit=100" | jq '.items[] | {id,name,is_archived,prices:[.prices[].price_amount],benefits:[.benefits[]|{id,type}]}'`. Record whether a $29 product with both `license_keys` benefits exists.
- [ ] **Step 3: Setapp's current rules.** Re-read and diff against this plan: docs.setapp.com/docs/preparing-your-application-for-setapp, /set-an-app-bundle-id, /allow-setapp-to-update-your-app-on-macos-13, /build-validation-findings, and the github.com/MacPaw/Setapp-framework README ("Add sandbox temporary exception entitlement"). Record the latest framework release ≥ 14 days old (5.5.4 on 23 Oct 2026; build validation warns below 5.5.1).
- [ ] **Step 4: Commit.**

### Task C1: Verify the bundle (plan 06 owns it)

Plan 06 creates the $29 bundle (Polar product, BNPL check, site copy at `site/content/en/bundle.md` for plan 04's bundle row) and ships it with App 2 in February (P1-9). This task only verifies it.

**Files:** Modify `scripts/gates/products.json`.

- [ ] **Step 1: Verify.** From C0 Step 2: a live $29 product carrying both existing `license_keys` benefits. Then `curl -s https://tegelapps.com/bundle/ | grep -c '\$29'` ≥ 1 and `curl -sI https://tegelapps.com/bundle/` → 200 (the URL from plan 04's register).
- [ ] **Step 2: Record or flag.** If both hold, record the bundle's product id in `products.json`. If either is missing, it's a plan 06 gap: tell the user and fix it with plan 06's Task 12 and 13 steps (sandbox, live with approval, BNPL check, page), not with new steps here.
- [ ] **Step 3: Commit** `scripts/gates/products.json`.

### Task C2: Setapp decision and application (non-code, outward-facing)

**Files:** Create `docs/gates/setapp.md`, `docs/setapp/application.md`

**Verified:**
- Setapp wants "mature software with an excellent reputation and stable performance" (setapp.com/developers).
- Membership pays a 70% usage-based share, plus 20% on members you bring (docs.setapp.com/docs/setapp-marketplace-overview).
- The Setapp build may have no "Paid features or app components", no "Activation and licensing mechanisms", no third-party updater (framework README; Review Guidelines §2.7, §2.10).
- The framework collects "Usage Data", "Performance Data" and "Device Information" (docs.setapp.com/docs/faq).

- [ ] **Step 1: Eligibility.** In `docs/gates/setapp.md`, list the release history (≥ 3 months since 8 Dec 2026) and links to public reviews (PH, MAS ratings, third-party posts). BUSINESS-PLAN §8: "Apply when app 1 has 3+ months of releases and public reviews".
- [ ] **Step 2: Rule 1 decision (the user's).** Joining means a Setapp edition that reports usage to Setapp — an exception to "No telemetry". Options: (a) accept it for the Setapp edition only, disclosed on `tegelapps.com/privacy` ("The Setapp edition reports usage to Setapp under Setapp's privacy policy; the direct and App Store editions report nothing"); (b) don't join. Record `Decision: GO | NO-GO` with the user's sign-off. **Default NO-GO** until signed; NO-GO skips C3–C4.
- [ ] **Step 3: Application** in `docs/setapp/application.md`: name; one-line description; the gap it fills (RTL Markdown with paginated PDF and a Quick Look tier); category; website; silent demo URL; 5 screenshots (reuse `docs/mas/screenshots`); macOS 14+, universal; contact `hello@tegelapps.com`. The user approves the text, then it goes in through the setapp.com/developers form ("Get in touch"). Check: the confirmation email has arrived.
- [ ] **Step 4: Contracting entity.** When the developer agreement arrives, record the legal party it names. The site operator is "MacPaw Way Ltd., … Limassol, Cyprus" (setapp.com footer); the agreement's party is unverified. Add the VAT question to H10 (BUSINESS-PLAN §15). The user signs; Claude never does.
- [ ] **Step 5: Commit both docs.** C3 starts only after Setapp accepts.

### Task C3: `MarkdownSetapp` targets

**Files:** Create `Apps/Markdown/Setapp/Markdown.entitlements`, `Apps/Markdown/Setapp/setappPublicKey.pem` (downloaded from the developer account; it's a public key), `Apps/Markdown/App/SetappStart.swift`. Modify `project.yml`, `.gitignore` (Step 2).

**Interfaces:**
- Consumes: `UNLOCKED`/`SETAPP` (B1); `verify-store-build.sh … setapp` (B1).
- Produces: targets `MarkdownSetapp` (`com.tegelapps.markdown-setapp`) and `MarkdownSetappQuickLook` (`com.tegelapps.markdown-setapp.quicklook`), following Setapp's `<appName>-setapp.<executableName>` pattern; `enum SetappStart { static func run() }` under `#if SETAPP`, called in `applicationDidFinishLaunching`.

- [ ] **Step 1: Watch the guard fail.** On the MarkdownMAS Debug build from B1: `scripts/verify-store-build.sh <path> setapp` → exit 1 with `FAIL: bundle id lacks -setapp`, `FAIL: no NSUpdateSecurityPolicy`, `FAIL: no setappPublicKey.pem`.
- [ ] **Step 2: Add the targets.**
  - **Un-ignore the public key first.** `.gitignore`'s `*.pem` line would make `git add` skip `setappPublicKey.pem` without a warning, and clean checkouts would then fail `verify-store-build.sh`. `git check-ignore -v Apps/Markdown/Setapp/setappPublicKey.pem; echo "exit=$?"` → `.gitignore:<n>:*.pem …` and `exit=0` (watched). Add `!Apps/Markdown/Setapp/setappPublicKey.pem` on a line below `*.pem`, then `git check-ignore Apps/Markdown/Setapp/setappPublicKey.pem; echo "exit=$?"` (no `-v`: verbose mode prints the matching `!` line and exits 0) → no output and `exit=1`.
  - `packages.Setapp: { url: https://github.com/MacPaw/Setapp-framework.git, exactVersion: <C0> }`; sources exclude the same three patterns as `MarkdownMAS`; `SWIFT_ACTIVE_COMPILATION_CONDITIONS: "$(inherited) SETAPP UNLOCKED"`; Developer ID signing and Hardened Runtime.
  - Info.plist adds `NSUpdateSecurityPolicy = { AllowProcesses = { MEHY5QF425 = [com.setapp.DesktopClient.SetappAgent] } }`.
  - App entitlements: the B1 MAS set plus `com.apple.security.temporary-exception.mach-lookup.global-name = [com.setapp.ProvisioningService]` (framework README). Quick Look reuses the **direct** Quick Look entitlements, since the Setapp edition is Developer ID [F5].
- [ ] **Step 3: Implement `SetappStart.run()`.** `SetappManager.shared.start(with: .default)` if C0 confirms macOS still needs it (the README's "Start" section shows it for iOS), then `SetappManager.shared.showReleaseNotesWindowIfNeeded()`. No "Rate on App Store" or store links (Review Guidelines §5.5).
- [ ] **Step 4: Watch it pass.** `xcodegen generate && xcodebuild build -scheme MarkdownSetapp -configuration Release -destination 'platform=macOS'`, then `scripts/verify-store-build.sh <path> setapp` → PASS. `nm -m <executable> | grep -c SetappManager` ≥ 1; if 0, add `OTHER_LDFLAGS: -force_load "$(BUILT_PRODUCTS_DIR)/libSetapp.a"` (docs.setapp.com/docs/setting-up-the-framework-1).
- [ ] **Step 5: Setapp test flow** (docs.setapp.com/docs/testing-your-application). Install the Setapp desktop app and sign in with the developer test member account; launch the build → it activates with no licence UI. Record the result in `docs/qa/setapp.md`.
- [ ] **Step 6: Commit:** `project.yml .gitignore Apps/Markdown docs/qa/setapp.md`, `feat(setapp): MarkdownSetapp targets with the Setapp framework, no Sparkle or licensing` + trailer.

### Task C4: Setapp packaging and upload

**Files:** Modify `scripts/release.sh` and `scripts/release_test.sh` (plan 03's; adds app `markdown-setapp`). Create `scripts/entitlements/markdown-setapp.plist` and `scripts/entitlements/markdown-setapp.quicklook.plist` (the allowlist `check_ents` reads, by bundle id minus `com.tegelapps.`).

**Delta on plan 03's `release.sh`** (its Task 12 Step 3 `main` items). The Setapp edition has no `TGPolar*` keys, no Sparkle and no DMG, so the `case` row selects a channel and every other app keeps plan 03's path unchanged:
- Before the `case`: `CHANNEL=direct`. New row: `markdown-setapp) SLUG=markdown-setapp SCHEME=MarkdownSetapp NAME=TegelMarkdown-setapp VOL="Tegel Markdown" CHANNEL=setapp;;`.
- Item 1: with `CHANNEL=setapp`, `--from-dmg` is a usage error: `markdown-setapp has no DMG`, exit 2. So item 3's `check_app` never runs for it.
- Item 4: with `CHANNEL=setapp`, skip `check_direct`: this edition carries `SETAPP UNLOCKED` by design (C3), and item 7's `verify-store-build.sh` checks it instead. Every direct app still runs `check_direct`.
- Item 7: with `CHANNEL=setapp`, the three Polar checks (`TGPolarAPIBase`, and `TGPolarBenefitID` and `TGPolarOrganizationID` non-empty) give way to `scripts/verify-store-build.sh "$APP" setapp` (B1), which fails on any `TGPolar*`, `SUFeedURL` or `SUPublicEDKey` key, any Sparkle code and any temporary exception but Setapp's. The version, `lipo`, `check_ents`, `codesign` and `syspolicy_check` checks run unchanged.
- Items 9–11: the app is notarised and stapled as before. With `CHANNEL=setapp`, `ditto -c -k --keepParent "$APP" "$OUT/$NAME-$V.zip"` replaces the DMG, with the icon PNG beside it (docs.setapp.com/docs/submitting-apps-for-review); `spctl -a -vvv -t exec "$APP"` must pass; the zip's absolute path is printed last; exit 0. Items 12–15 (appcast, confirm, R2) never run for it: Step 4 uploads by hand.

- [ ] **Step 1: Watch it fail.** Add two cases to `release_test.sh`, right after `check print-config` in its first `fresh` block:
  ```bash
         check setapp-args     1 "Config/Release.xcconfig still has REPLACE_IN_PLAN_05" markdown-setapp 1.1.1 --no-upload
         check setapp-from-dmg 2 "markdown-setapp has no DMG"   markdown-setapp 1.1.1 --from-dmg x.dmg
  ```
  `bash scripts/release_test.sh` → both `FAIL … (exit 2): … unknown app: markdown-setapp`, every earlier case still passing.
- [ ] **Step 2: Implement the delta and the allowlist.** The entitlements follow C3: the app gets the B1 MAS set plus Setapp's mach-lookup name; Quick Look reuses the direct set.
  ```bash
  P=/usr/libexec/PlistBuddy; A=scripts/entitlements/markdown-setapp.plist; G=com.apple.security.temporary-exception.mach-lookup.global-name
  for k in app-sandbox files.user-selected.read-write files.bookmarks.app-scope network.client; do $P -c "Add :com.apple.security.$k bool true" "$A"; done
  $P -c "Add :$G array" -c "Add :$G: string com.setapp.ProvisioningService" "$A"
  cp scripts/entitlements/markdown.quicklook.plist scripts/entitlements/markdown-setapp.quicklook.plist
  ```
  `bash scripts/release_test.sh` → `0 failed`. Commit: `scripts/release.sh scripts/release_test.sh scripts/entitlements`, `build(setapp): release.sh markdown-setapp channel, zip, no Polar or Sparkle checks` + trailer (`release.sh` needs a clean tree).
- [ ] **Step 3: Watch it pass.** `scripts/release.sh markdown-setapp 1.1.1 --no-upload` → `verify-store-build: PASS`, exit 0, the zip path last. `unzip -l dist-release/markdown-setapp/1.1.1/TegelMarkdown-setapp-1.1.1.zip | grep -c "Tegel Markdown.app/Contents/Info.plist"` → 1. `plutil -extract CFBundleIdentifier raw` on the extracted app → `com.tegelapps.markdown-setapp`.
- [ ] **Step 3b: Review before upload.** Run Task C6 now, through its merge and push: the `release.sh`, entitlement and Setapp SDK changes are reviewed before Step 4 sends a build out (master §11). If stage 7 changed anything, re-run Step 3 on `main` and upload that zip.
- [ ] **Step 4: Upload** (approval). Setapp developer account → Apps → Add First Version → build validation shows no blocking finding. Record the review outcome in `docs/setapp/application.md`, then on `main` commit and push it (`docs(setapp): first version review outcome` + trailer; `git status --porcelain -- . ':(exclude)docs'` → empty, since the next `release.sh` run needs a clean tree).

### Task C5: Homebrew go/no-go (Mon 2 Aug 2027) → `docs/gates/homebrew.md`

**Verified:**
- Notability: 30 forks, 30 watchers or 75 stars; "at least 90 forks, 90 watchers or 225 stars for a self-submission". "A self-submission without a public code repository is not automatically rejected, but its author must provide evidence of notability in the pull request" (docs.brew.sh/Package-Acceptance-Policy).
- "A free version that works indefinitely with optional paid features is eligible" (docs.brew.sh/Acceptable-Casks) [F11].

- [ ] **Step 1: Evidence.** List independent mentions (articles, posts or lists not written by us, with URLs) and whether a third party has requested or submitted a cask.
- [ ] **Step 2: Decide.** `Decision: GO` needs ≥ 5 independent mentions **or** a third-party request; otherwise `NO-GO` (expected), re-checked at G4. Commit to `main`.
- [ ] **Step 3: If GO, write the cask** in a fork of `homebrew/homebrew-cask` at `Casks/t/tegel-markdown.rb`:
  - `version`, `sha256` (`shasum -a 256` of the DMG), `url "https://downloads.tegelapps.com/…/TegelMarkdown-#{version}.dmg"` (path from A0), `name "Tegel Markdown"`, `desc`, `homepage "https://tegelapps.com/markdown"`;
  - `livecheck` with `strategy :sparkle` on the appcast URL; `auto_updates true`; `depends_on macos: ">= :sonoma"`; `app "Tegel Markdown.app"`; `zap trash:` for both containers.
  - `brew audit --new --cask tegel-markdown && brew style --cask tegel-markdown && brew install --cask tegel-markdown` → no offences, and the install succeeds.
  - The PR, with the notability evidence, is opened only after the user approves it.

### Task C6: Pipeline P for `m07c` (if C4 runs, at its Step 3b, before the upload)

- [ ] **Step 1: Run Procedure P (master §11).** `/cso` scope: the Setapp SDK, its mach-lookup exception and `NSUpdateSecurityPolicy`; no licence bypass reaching the direct build; the `release.sh` changes. Design review: the Setapp edition's UI, if C3 ran (the bundle page is plan 06's).
- [ ] **Step 2: Merge and push.**

---

## Section D: App 3, the selection-action bar (`m07d-app3`)

**Architecture contract** (master §3 style). Task D1 may rename items; it updates this block before any code.

```swift
// Apps/Select/App: target "Select", bundle id com.tegelapps.select, LSUIElement YES (menu-bar agent),
// NOT sandboxed (AX APIs aren't supported in a sandbox, BUSINESS-PLAN §7.2), Hardened Runtime, Developer ID, Sparkle, TegelStore.
enum AccessibilityPermission { static func isTrusted() -> Bool                                   // AXIsProcessTrusted()
                               static func request()                                             // AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])
                               static let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")! }
struct TextRun: Equatable, Sendable { var text: String; var bold = false; var italic = false; var link: URL? = nil }
struct Selection: Equatable, Sendable { let runs: [TextRun]; var text: String { runs.map(\.text).joined() } }
enum SelectionReader { @MainActor static func readFocused() -> Selection?   // AXUIElementCreateSystemWide → kAXFocusedUIElementAttribute → kAXSelectedTextAttribute;
                                                                            // runs via kAXAttributedStringForRangeParameterizedAttribute over kAXSelectedTextRangeAttribute
                       static func isReadable(role: String?, subrole: String?) -> Bool }   // false for kAXSecureTextFieldSubrole
enum CaseStyle: String, CaseIterable, Sendable { case upper, lower, title, sentence, camel, snake, kebab }
enum TextTools { static func convert(_ s: String, to: CaseStyle) -> String
                 static func counts(_ s: String) -> (words: Int, characters: Int, lines: Int)
                 static func markdown(from runs: [TextRun]) -> String
                 static func searchURL(template: String, query: String) -> URL? }   // nil unless the result is https; query percent-encoded without & # + = ? (S29)
enum SelectionAction: String, CaseIterable, Sendable { case copyMarkdown, openInTegelMarkdown, searchDocs, convertCase, wordCount }
enum SelectError: Error, Equatable { case needsPro }
enum Actions { static let freeActions: Set<SelectionAction> = [.wordCount, .convertCase]
               @MainActor static func perform(_ a: SelectionAction, on s: Selection, style: CaseStyle? = nil, isPro: Bool) throws -> String }  // status text
@MainActor final class ActionPanel: NSPanel {            // styleMask [.nonactivatingPanel, .titled, .fullSizeContentView], level .floating
    static let dismissMask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
    private(set) var selection: Selection?
    func present(_ s: Selection, near point: NSPoint)       // installs NSEvent.addGlobalMonitorForEvents(matching: dismissMask)
    func dismiss() }                                         // removes the monitor; selection = nil
@MainActor @Observable final class OnboardingModel { enum Step: Equatable { case needsPermission, ready }
    init(isTrusted: @escaping () -> Bool = AccessibilityPermission.isTrusted); private(set) var step: Step; func poll() }
@MainActor @Observable final class MenuBarModel { init(onboarding: OnboardingModel); var showsOnboarding: Bool { get } }  // true while step == .needsPermission
extension KeyboardShortcuts.Name { static let showActionBar = Self("showActionBar", default: .init(.space, modifiers: [.control, .option, .command])) }
```

**Verified APIs:**
- `AXUIElementCopyAttributeValue` (10.2+), `kAXSelectedTextAttribute`, `kAXFocusedUIElementAttribute`, `kAXAttributedStringForRangeParameterizedAttribute` (10.4+), `AXIsProcessTrustedWithOptions` (10.9+) — Apple documentation JSON.
- `addGlobalMonitorForEvents`: "Key-related events may only be monitored if accessibility is enabled…". We monitor **mouse-down only**, to dismiss the panel.
- Since macOS 15, `RegisterEventHotKey` rejects Option-only and Option-Shift shortcuts (developer.apple.com/forums/thread/763878), so the default includes ⌃ and ⌘. KeyboardShortcuts 3.1.0 (MIT, 11 Sep 2026) wraps the Carbon hotkey and provides the recorder.

**Actions** (no AI, no network beyond licence and Sparkle):
- **Copy as Markdown** and **Convert case** write the pasteboard.
- **Open in Tegel Markdown** writes `$TMPDIR/Selection/selection-<uuid>.md` (deleted at next launch or quit) and opens it with `NSWorkspace.shared.open(_:withApplicationAt:configuration:)`; the app URL comes from `urlForApplication(withBundleIdentifier:)` for `com.tegelapps.markdown`, then `…-setapp`. The action is hidden when neither is installed (rule 8: no ads).
- **Search docs** opens `TextTools.searchURL(template:query:)` in the default browser (default template `https://devdocs.io/#q=%s`, editable in Settings, which accepts only templates that yield an `https` URL); the app itself sends nothing.
- **Word count** shows status text only.

### Task D0: Gate and re-validation → `docs/reviews/m07d-revalidation.md`

- [ ] **Step 1: Gate.** `docs/gates/G3.md` shows `Decision: APP3` and support is GREEN. `git checkout -b m07d-app3 main`.
- [ ] **Step 2: Shared code.** Record how `release.sh` maps app names, the `LicenseManager` init for a new app, and the D16 Polar config keys. `curl -s https://api.github.com/repos/sindresorhus/KeyboardShortcuts/releases/latest | jq -r '.tag_name,.published_at'` → a release ≥ 14 days old.
- [ ] **Step 3: Commit.**

### Task D1: Brainstorm checkpoint with the user (`superpowers:brainstorming`), with the AX spike as input

- [ ] **Step 1: AX spike** (throwaway, in `$SCRATCH`, not committed). `axspike.swift` sleeps 3 s, then prints the frontmost app's focused element role/subrole, the `kAXSelectedTextAttribute` length, and whether the attributed-string attribute returns runs. `swiftc axspike.swift -o axspike && ./axspike`, with Accessibility granted to Terminal. Test selections in Safari, Chrome, Mail, Notes, TextEdit, Xcode, VS Code, Terminal, Slack and Tegel Markdown. Write a works / plain-only / nothing table to `docs/superpowers/specs/app3-ax-spike.md`.
- [ ] **Step 2: Brainstorm** these decisions (defaults in brackets):
  - name [Tegel Select, `com.tegelapps.select`], with a trademark check like W1's;
  - trigger [hotkey ⌃⌥⌘Space only; no auto-popup on mouse selection];
  - action set [the five above];
  - clipboard fallback [off, unless < 6 of 10 spike apps work; it would need a synthetic ⌘C and a restored pasteboard, which touches rule B];
  - free vs Pro [free: word count and case; Pro: Markdown, open, search, custom hotkey];
  - price [$15 once, 2 Macs]; launch [Tue 20 Jul 2027]; bundle [none until G4].
- [ ] **Step 3: Spec.** Write `docs/superpowers/specs/2027-05-app3-selection-bar-design.md`, update the contract block above if anything changed, and commit both.

### Task D2: Halal and harm review → `docs/gates/app3-review.md`

- [ ] **Step 1: Rule B (harm).**
  - **No keylogging:** no `CGEventTap`, no IOHID, no Input Monitoring; the only key input is the registered hotkey; the global monitor is mouse-down only.
  - The selection is read only when the hotkey fires.
  - **Nothing stored:** the selection lives in memory only while the panel is open. The one temp file exists only for "Open in Tegel Markdown" and is deleted at next launch or quit. No history, no logs.
  - Secure text fields are never read.
  - App 3 never writes into other apps (no `AXUIElementSetAttributeValue`); results go to the pasteboard, so the read-only identity holds.
- [ ] **Step 2: Other rules.** Rule 9: a general productivity tool, not accessibility-critical, not an AI copilot. Rules 1–8: geometric icon, no audio, one-time price, no ads. Rule C: secure fields excluded.
- [ ] **Step 3: User sign-off line, then commit.** The Accessibility exception (CR-8) stays **NO-GO until the user signs it off explicitly** here; without that line, D3 doesn't start. `/cso` in D8 verifies every claim.

### Task D3: Scaffold and `TextTools`

**Files:**
- Create: `Apps/Select/App/{SelectApp.swift,TextTools.swift}`, `Apps/Select/App/AppIcon.icon/` (Step 4b), `Apps/Select/Tests/TextToolsTests.swift`
- Modify: `Makefile` — the `build` recipe gets a line like its `markdown` one with `-scheme Select`, into the same `-derivedDataPath build` (as plan 06 did for `data`), so `make build` and `make check` build App 3.
- Modify: `project.yml` — targets `Select` and `SelectTests`; packages `KeyboardShortcuts` (`exactVersion: 3.1.0` or the D0 value), `TegelKit` (product `TegelStore`) and Sparkle; `ENABLE_APP_SANDBOX: NO`, `ENABLE_HARDENED_RUNTIME: YES`, `LSUIElement: true`, `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`, and `PRODUCT_BUNDLE_IDENTIFIER` set to the lower-case bundle id from D1 (prefix + target name would give `com.tegelapps.Select`, which `release.sh`'s `check_app` rejects: it compares `com.tegelapps.$SLUG`).

**Interfaces:** `TextTools` and `CaseStyle`, as in the contract.

- [ ] **Step 1: Write the failing tests.**
```swift
func testCaseStyles() {
    let s = "hello world_foo-bar"
    XCTAssertEqual(TextTools.convert(s, to: .camel), "helloWorldFooBar")
    XCTAssertEqual(TextTools.convert(s, to: .snake), "hello_world_foo_bar")
    XCTAssertEqual(TextTools.convert(s, to: .kebab), "hello-world-foo-bar")
    XCTAssertEqual(TextTools.convert("hello world", to: .title), "Hello World")
    XCTAssertEqual(TextTools.convert("HELLO. WORLD", to: .sentence), "Hello. World")
    XCTAssertEqual(TextTools.convert("مرحبا بالعالم", to: .upper), "مرحبا بالعالم")
}
func testCounts() {
    XCTAssertTrue(TextTools.counts("") == (0, 0, 0))
    XCTAssertTrue(TextTools.counts("hello world\nbye") == (3, 15, 2))
    XCTAssertEqual(TextTools.counts("مرحبا بالعالم").words, 2)
    XCTAssertGreaterThan(TextTools.counts("日本語のテキスト").words, 0)
}
func testMarkdownFromRunsEscapesAndLinksSafely() {
    XCTAssertEqual(TextTools.markdown(from: [.init(text: "a*b "), .init(text: "bold", bold: true), .init(text: " and "),
                                             .init(text: "it", italic: true), .init(text: " "), .init(text: "site", link: URL(string: "https://a.example"))]),
                   "a\\*b **bold** and *it* [site](https://a.example)")
    XCTAssertEqual(TextTools.markdown(from: [.init(text: "x", link: URL(string: "javascript:alert(1)"))]), "x")
}
func testSearchURLEncodesQueryAndAcceptsOnlyHTTPS() {
    XCTAssertEqual(TextTools.searchURL(template: "https://devdocs.io/#q=%s", query: "a&b#c")?.absoluteString, "https://devdocs.io/#q=a%26b%23c")
    XCTAssertNil(TextTools.searchURL(template: "http://example.com/?q=%s", query: "x"))
    XCTAssertNil(TextTools.searchURL(template: "javascript:alert('%s')", query: "x"))
}
```
- [ ] **Step 2: Watch it fail.** `xcodegen generate && xcodebuild test -scheme Select -destination 'platform=macOS' -only-testing:SelectTests/TextToolsTests` → FAIL (`cannot find 'TextTools'`).
- [ ] **Step 3: Implement.**
  - `convert`: words split on whitespace, `_` and `-`; `title` capitalises each whitespace-separated word; `sentence` lowercases, then capitalises after `^|[.!?]\s+`; locale-independent `uppercased()`/`lowercased()`.
  - `counts`: `enumerateSubstrings(in:options: .byWords)`; `characters` = `count`; `lines` = the number of `\n` + 1 for non-empty text.
  - `markdown`: escapes `\ * _ [ ] ` #` in plain text; wraps bold and italic runs; emits links only for `http`, `https` and `mailto`.
  - `searchURL`: `query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&#+=?")))`, substituted for `%s`; return the `URL` only if its `scheme == "https"`.
- [ ] **Step 4: Watch it pass.** Re-run Step 2's command → 4 pass.
- [ ] **Step 4b: App icon.** Plan 09's guard `every app icon compiles to all ten macOS sizes` (in `make check`) requires an `AppIcon.icon` in every `Apps/*/App`. Watch it fail first: `(cd Renderer && bun test test/design.test.js)` → FAIL on `["Select", false]`. Create `Apps/Select/App/AppIcon.icon/` (`icon.json` + `Assets/*.svg`): a plain geometric tile (rule 3: no face, figure, animal or mascot) built to plan 09 Task 9's icon rules (1024 canvas of square, unmasked layers; strokes ≥ 136 and gaps ≥ 168; filled shapes with radius ≥ 24) and `DESIGN.md`'s icon section and colours. The user approves the concept before this commit. Re-run → PASS; `xcodegen generate && make build`, then `/usr/libexec/PlistBuddy -c 'Print CFBundleIconName'` on the built `Select` app → `AppIcon`.
- [ ] **Step 5: Commit** `project.yml`, `Makefile` and `Apps/Select` (`feat(select): scaffold, text tools and app icon`, plus the co-author line).

### Task D4: `SelectionReader` and the permission

**Files:** Create `Apps/Select/App/{SelectionReader.swift,AccessibilityPermission.swift,OnboardingModel.swift}`, `Apps/Select/Tests/SelectionReaderTests.swift`

- [ ] **Step 1: Write the failing tests.**
  - `XCTAssertFalse(SelectionReader.isReadable(role: "AXTextField", subrole: "AXSecureTextField"))`; `XCTAssertTrue(SelectionReader.isReadable(role: "AXTextArea", subrole: nil))`.
  - `var t = false; let m = OnboardingModel(isTrusted: { t })` → `.needsPermission`; `t = true; m.poll()` → `.ready`; `t = false; m.poll()` → `.needsPermission` (revoked mid-session).
- [ ] **Step 2: Watch it fail.** `xcodebuild test -scheme Select -destination 'platform=macOS' -only-testing:SelectTests/SelectionReaderTests` → FAIL (types missing).
- [ ] **Step 3: Implement.**
  - `readFocused`: return nil unless `isTrusted()`; read the focused element's `kAXRoleAttribute`/`kAXSubroleAttribute` and return nil if `!isReadable`; read the selected text, nil when empty.
  - Map attributed runs: a font name containing `Bold` → bold; `Italic`/`Oblique` → italic; an `AXLink` element's `kAXURLAttribute` → link. Otherwise fall back to one plain run.
  - `poll()` re-reads `isTrusted`. The app polls once a second while onboarding is visible, and calls `poll()` before every read.
- [ ] **Step 4: Watch it pass.** Re-run Step 2's command → PASS.
- [ ] **Step 5: Commit** `Apps/Select`.

### Task D5: Hotkey, `ActionPanel`, actions and the no-keylogging guard

**Files:** Create `Apps/Select/App/{ActionPanel.swift,Actions.swift,Shortcuts.swift}`, `Apps/Select/Tests/ActionPanelTests.swift`, `scripts/verify-no-keylogging.sh`

- [ ] **Step 1: Write the failing tests.**
```swift
@MainActor func testPanelNeverActivatesAndDropsSelectionOnDismiss() {
    let p = ActionPanel()
    XCTAssertTrue(p.styleMask.contains(.nonactivatingPanel)); XCTAssertEqual(p.level, .floating)
    p.present(Selection(runs: [.init(text: "secret")]), near: .zero); XCTAssertNotNil(p.selection)
    p.dismiss(); XCTAssertNil(p.selection)
}
func testDismissMonitorWatchesNoKeys() { XCTAssertTrue(ActionPanel.dismissMask.isDisjoint(with: [.keyDown, .keyUp, .flagsChanged])) }
@MainActor func testFreeActionsWorkWithoutProAndProActionsDont() throws {
    let s = Selection(runs: [.init(text: "hello world")])
    XCTAssertEqual(try Actions.perform(.wordCount, on: s, isPro: false), "2 words · 11 characters")
    _ = try Actions.perform(.convertCase, on: s, style: .kebab, isPro: false)
    XCTAssertEqual(NSPasteboard.general.string(forType: .string), "hello-world")
    XCTAssertThrowsError(try Actions.perform(.copyMarkdown, on: s, isPro: false)) { XCTAssertEqual($0 as? SelectError, .needsPro) }
}
```
- [ ] **Step 2: Write the guard and watch it fail on a real tap.** `scripts/verify-no-keylogging.sh <executable|App.app>` fails if `nm -u` on any Mach-O file lists `_CGEventTapCreate`, `_CGEventTapCreateForPid`, `_IOHIDManagerCreate`, `_IOHIDRequestAccess`, `_CGRequestListenEventAccess` or `_CGPreflightListenEventAccess`.
  ```bash
  echo 'import CoreGraphics; _ = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly, eventsOfInterest: 0, callback: { _, _, e, _ in Unmanaged.passUnretained(e) }, userInfo: nil)' > "$SCRATCH/tap.swift" && swiftc "$SCRATCH/tap.swift" -o "$SCRATCH/tap" && scripts/verify-no-keylogging.sh "$SCRATCH/tap"
  ```
  Expected: exit 1, `FAIL: _CGEventTapCreate`.
- [ ] **Step 3: Watch the tests fail.** `xcodebuild test -scheme Select -destination 'platform=macOS' -only-testing:SelectTests/ActionPanelTests` → FAIL (`cannot find 'ActionPanel'`).
- [ ] **Step 4: Implement.**
  - `KeyboardShortcuts.onKeyUp(for: .showActionBar)` → `SelectionReader.readFocused()` → `panel.present(_:near: NSEvent.mouseLocation)`, or a small "Nothing selected / this app doesn't share its selection" status.
  - Buttons call `Actions.perform(…, isPro: licence.isPro)`; actions outside `freeActions` throw `.needsPro` when not Pro.
  - `Esc` and an outside click dismiss. Layout from `DESIGN.md`.
- [ ] **Step 5: Watch it pass.** Re-run Step 3's command → 3 pass. `make build` (Select included), then `scripts/verify-no-keylogging.sh <Select.app>` → `PASS`. Then the read-only gate (Global Constraints): `git add Apps/Select && make readonly-gate` → FAIL naming the "Open in Tegel Markdown" temp-file write and its cleanup in `Actions.swift` (watched); add `^Apps/Select/App/Actions\.swift:` to its allowlist in the `Makefile` → exit 0.
- [ ] **Step 6: Commit** `Apps/Select`, `scripts/verify-no-keylogging.sh` and the `Makefile` allowlist line.

### Task D6: Onboarding, settings, licence, updates, localisation

**Files:** Create `Apps/Select/App/{OnboardingView.swift,SettingsView.swift,MenuBar.swift}`, `Apps/Select/App/Localizable.xcstrings` (EN/NL/FR/AR), `scripts/entitlements/select.plist`. Modify `Config/Release.xcconfig` and the sandbox xcconfig (add `TG_POLAR_CHECKOUT_URL_SELECT` and `TG_POLAR_BENEFIT_ID_SELECT` for App 3's Polar product, as plan 06 Task 1 adds `_DATA`; `check_app` reads `TG_POLAR_BENEFIT_ID_<SLUG>` from `Config/Release.xcconfig`), `.env.example` (add `POLAR_PRODUCT_ID_SELECT`, `POLAR_BENEFIT_ID_SELECT`, `POLAR_CHECKOUT_URL_SELECT`, `POLAR_SANDBOX_CHECKOUT_URL_SELECT`, as plan 06 Task 1 does for `_DATA`; D7 fills them with `envset`), `scripts/release.sh`, `scripts/release_test.sh` (Step 3b)

- [ ] **Step 1: Write the failing test.** `testOnboardingShowsWhenUntrusted`: with `OnboardingModel(isTrusted: { false })`, `MenuBarModel(onboarding:).showsOnboarding == true`; with `{ true }`, false. Then `xcodebuild test -scheme Select -destination 'platform=macOS' -only-testing:SelectTests` → FAIL (`MenuBarModel` missing).
- [ ] **Step 2: Implement.**
  - Onboarding explains in one sentence why Accessibility is needed ("to read the text you select, only when you press your shortcut"); one button calls `request()` and opens `settingsURL`.
  - Settings: the shortcut recorder, the search URL template (refused with an inline message when `searchURL(template:query: "test")` is nil), the licence pane (TegelStore), Sparkle "Check for Updates". The menu-bar item: Settings and Quit.
- [ ] **Step 3: Watch it pass.** `xcodebuild test -scheme Select -destination 'platform=macOS'` → all SelectTests pass.
- [ ] **Step 3b: Add App 3 to `release.sh`** (Step 4's b1 and b2 come from it), as plan 06 Task 14 Step 1 adds `data`: a `release_test.sh` `print-config` case for `select`, watched failing (`unknown app: select`); the row `select) SLUG=select SCHEME=Select NAME=TegelSelect VOL="Tegel Select";;`; `scripts/entitlements/select.plist` holding the Release build's signed set as D2 reviewed it; `release_test.sh` → `0 failed`. Then App 3's **Polar sandbox** product and benefit (sandbox: no approval; plan 03 Task 15 archived the Markdown ones, so a later plan makes its own): fill `TG_POLAR_CHECKOUT_URL_SELECT` and `TG_POLAR_BENEFIT_ID_SELECT` in `Config/PolarSandbox.xcconfig`, and `envset POLAR_SANDBOX_CHECKOUT_URL_SELECT`. `Config/Release.xcconfig` keeps plan 03's placeholder for them until D7, so only `--sandbox` builds pass the benefit check. Commit everything D6 has changed so far (Steps 1–3's source and strings, the three release files, both xcconfigs) before Step 4: `release.sh` needs a clean tree; `git status --porcelain -- . ':(exclude)docs'` → empty.
- [ ] **Step 4: Manual QA → `docs/qa/app3.md`:** the D1 spike apps; a password field shows "Nothing selected"; revoking the permission brings onboarding back; a Sparkle update 1.0.0-b1 → b2 (both `release.sh select 1.0.0-b<n> --sandbox --no-upload`; after b1, write its rows to `docs/qa/app3.md` and commit them, as plan 03 Task 13 does, so b2's `CFBundleVersion` (`git rev-list --count HEAD`) is higher; served from a local signed feed in `dist-release/select/beta-feed/` exactly as plan 03 Task 13 serves Markdown's; stop the server and delete the folder afterwards) keeps the Accessibility permission (same Team ID and designated requirement); an Option-only shortcut is refused or warned about on macOS 15.
- [ ] **Step 5: Commit** the rest of `docs/qa/app3.md`.

### Task D7: Polar product, site page, release, launch (outward-facing)

- [ ] **Step 1: Polar.** Sandbox: product at the D1 price with a licence-key benefit (2 activations); buy it and activate in Debug. Then live (approval): the product, its benefit and a checkout link.
  - **Production ids** (D6 left plan 03's placeholders in `Config/Release.xcconfig`): `. scripts/lib/env.sh`, then `envset POLAR_PRODUCT_ID_SELECT '<id>'`, `envset POLAR_BENEFIT_ID_SELECT '<id>'` and `envset POLAR_CHECKOUT_URL_SELECT '<url>'`; `need POLAR_PRODUCT_ID_SELECT POLAR_BENEFIT_ID_SELECT POLAR_CHECKOUT_URL_SELECT POLAR_SANDBOX_CHECKOUT_URL_SELECT && echo saved` → `saved` (the sandbox one is D6 Step 3b's). Replace the placeholders of `TG_POLAR_BENEFIT_ID_SELECT` and `TG_POLAR_CHECKOUT_URL_SELECT` in `Config/Release.xcconfig` with those values, the URL in the `https:/$()/` form (plan 05 Task 2 Step 9). Expected: `grep -c REPLACE_IN_PLAN_05 Config/Release.xcconfig` → `0`, and `. scripts/lib/env.sh; grep -cF "TG_POLAR_BENEFIT_ID_SELECT = $(envget POLAR_BENEFIT_ID_SELECT)" Config/Release.xcconfig` → `1` (Step 3's `check_app` compares the built app with that line).
  - Record the live product id under `select` in `scripts/gates/products.json` (G0 Step 3 left it `[]`; G4 counts App 3 from it, and an App 3 refund missing from the window orders would be subtracted again as an older one).
  - **BNPL check** (rule 7): run plan 05 Task 2 Step 11's procedure, unchanged, on the live App 3 checkout link before it goes public; screenshots to `docs/reviews/m07d-polar/checkout-{safari,chrome}-{nl,us}.png`. Its stop rule applies (B17).
  - The product carries plan 05's opt-in field (`marketing_opt_in`, unticked), a EUR price set by the user (K10), and a description that states the licence limits (2 Macs, every 1.x update, 14-day refund; rule 6).
  - Commit: `scripts/gates/products.json Config/Release.xcconfig docs/reviews/m07d-polar`, `build(select): production Polar ids and BNPL evidence` + trailer; `git status --porcelain -- . ':(exclude)docs'` → empty, since Step 3's `release.sh` needs a clean tree.
- [ ] **Step 2: Site.** `site/content/en/<slug from D1>.md` (plan 04's build reads only `<lang>/` folders), with plan 04's front matter (`slug`, `lang: en`, `title`, `description`): a permission explanation, a privacy statement (what is read, and when), a silent captioned demo (rules 2 and 4), recorded now as `site/static/media/tegel-select-demo.mp4` with plan 05 Task 5's encoding and caption bands, after its Step 3 screen preparation and the user's face review (rule 3). Every selection is synthetic fixture text in TextEdit or our own apps, never real mail, chat or browsing and embedded as a `<video>` (plan 04's asset test needs the file in the same commit). It sells the app the way plan 04's pages do: front matter `app: select` (add `select` to plan 04's `app` values, as plan 06 added `bundle`), with `{{pricing:select}}` (the price plus plan 04's licence sentence: 2 Macs, 1.x updates, 14-day refund, so the limits show before purchase; rule 6). No `{{checkout:select}}` or `{{download:select}}` yet: no Buy link reaches `main` before the DMG it sells (plan 04's twice-weekly article deploys publish `main`), and `fill` throws on an empty URL, so Step 3 adds both, as plan 06 Task 16 Step 4 does for App 2. Add `apps.select` to `site/config.json` with plan 04's keys (name, page, `price`/`regularPrice` and `priceEUR`/`regularPriceEUR` from D1 and K10, `intro: false`, `launchDate: "2027-07-20"`, `minMacOS` from `project.yml`, `checkoutURL`, `version` and `downloadURL` empty until Step 3, plan 04 CR-5). `(cd site && bun test)` → PASS, including the offer test on this page. Commit the page, the video and `site/config.json` on `m07d-app3`; it reaches `main` with Step 2b's merge. Don't deploy yet: plan 04's deploy command starts with `git switch main`, which doesn't hold the page until then. Step 3 deploys it.
- [ ] **Step 2b: Review before release.** Run Task D8 now, through its merge and push: App 3 brings new licensing, Sparkle, entitlement and `release.sh` code, so the full Procedure P runs before Step 3 publishes it (master §11). Step 3 then builds from `main`.
- [ ] **Step 3: Release.** `select` joined `release.sh` in D6 Step 3b. `scripts/release.sh select 1.0.0 --no-upload`, then QA on that DMG with rows in `docs/qa/select-1.0.0.md`. Commit them (`docs(qa): select 1.0.0 DMG` + trailer; `git status --porcelain -- . ':(exclude)docs'` → empty, since `--from-dmg` still runs the clean-tree check and takes `BUILD` from the DMG, so this commit doesn't change it). Then `scripts/release.sh select 1.0.0 --yes --from-dmg <path>` (approval; `--yes` only after it, since without a terminal the prompt aborts) → `spctl -a -vv` shows `accepted`. Then, on `content/release-select-1.0.0` (plan 04 CR-5, as plan 06 Task 16 Step 4), set `apps.select.version` → `"1.0.0"` and `downloadURL` → the printed `published …` URL, set `checkoutURL` to the `POLAR_CHECKOUT_URL_SELECT` value without printing it, and add `{{checkout:select}}` next to the price and `{{download:select}}` with "Version {{version:select}}" to Step 2's page; `(cd site && bun test)` → 0 fail; run review stages 2, 3 and 9; merge, push, and deploy with plan 04's command (not a first deploy, so no approval); URL → 200, and `curl -s https://tegelapps.com/<slug from D1>/ | grep -cF "<downloadURL>"` ≥ 1 (the page's `{{download:select}}`).
- [ ] **Step 4: Launch Tue 20 Jul** with plan 08's playbook: PH, r/macapps (≥ 30 days after our last post), Show HN, IH, and a cross-sell email to App 1/2 buyers who ticked the checkout opt-in (`marketing_opt_in`, K9), sent by plan 08 (it owns MailerLite) under the segment rule from plan 06 Task 15. Each post and email is approved first.

### Task D8: Pipeline P for `m07d` (runs at D7 Step 2b, before the release)

- [ ] **Step 1: Run Procedure P (master §11).** `/cso` scope: AX reading and the secure-field exclusion; the global monitor mask; hotkey registration; the temp file's lifetime; pasteboard writes; the search URL encoding and https-only template; the non-sandboxed Hardened Runtime; Sparkle without a sandbox; TegelStore reuse; `verify-no-keylogging.sh` PASS on the release build; each claim in `docs/gates/app3-review.md`. Design review: onboarding, panel, settings, Arabic UI, and the demo video (rules 2–4; synthetic text only).
- [ ] **Step 2: Merge and push.**

---

## Section E: macOS 28 (`m07e-macos28`)

### Task E0: Re-validate (Mon 31 May 2027) → `docs/reviews/m07e-revalidation.md`

- [ ] **Step 1: Dates and machines.** Record the WWDC 2027 keynote date (developer.apple.com/wwdc). Record whether Scaleway's Mac mini OS list or changelog offers a macOS 28 beta image (scaleway.com/en/pricing/apple-silicon/). If not, the fallback is a macOS 27 M1 upgraded through System Settings → General → Software Update → Beta Updates, with the developer Apple Account entered by the user over VNC.
- [ ] **Step 2: Scope.** List the shipped apps and the plan 05 matrix path. `git checkout -b m07e-macos28 main`, then commit.

### Task E1: WWDC watch (keynote day + 1) → `docs/research/2027-06-wwdc-macos28.md`

- [ ] **Step 1: Sherlock risk 4.** Does macOS 28 render Markdown in Quick Look, TextEdit or Finder previews (Apple's "What's new in macOS 28", release notes)? Did Anthropic or OpenAI ship session or transcript browsers (Claude Code and Codex release notes, desktop apps), threatening App 2's session mode?
- [ ] **Step 2: Platform changes.** Xcode 28's system requirements (can the build Mac still build Developer ID? [F2]); new App Store Connect SDK deadlines; WebKit changes (page-margin boxes could later replace `PDFStamper`); Quick Look, App Intents and Accessibility changes.
- [ ] **Step 3: One action per finding:** none / copy change / re-scope / retire a feature. The user decides any re-scope or retirement. Commit.

### Task E2: Beta matrix on Scaleway → `docs/qa/macos28-beta.md`

- [ ] **Step 1: Lease** (purchase approval: M1, 24 h, €3.19 incl. VAT [F9], master H6; ordered and released with H6's lease lifecycle, and E4 reuses it only within the same 24 h). Install the macOS 28 beta (E0 route) and record `sw_vers`.
- [ ] **Step 2: Run the matrix.** Install the latest notarised DMGs of App 1, App 2 (and App 3 if shipped). Run every plan 05 row (R9 and R11 with a re-issued QA key, as in A6 Step 1) plus the A6 and D6 rows, and the G0 timing for `g0-1mb.md` in the window and in `qlmanage -p`. With our extension disabled (`pluginkit -e ignore -i com.tegelapps.markdown.quicklook`), record whether the system now previews `.md` itself (risk 4 evidence), then re-enable it.
- [ ] **Step 3: Record and commit.** One row per check: pass/fail, the machine (Scaleway M1, macOS 28 beta N), and a screenshot path for failures.

### Task E3: Fix loop (once per failing row)

- [ ] **Step 1: Root cause** with `superpowers:systematic-debugging`.
- [ ] **Step 2: Regression test.** Write a failing test in the owning layer (`bun test`, `swift test` or `xcodebuild test`). Watch it fail on the build Mac when the bug reproduces there; if it only reproduces on 28, record that its failure was observed on Scaleway.
- [ ] **Step 3: Minimal fix;** the test passes.
- [ ] **Step 4: Commit** `fix(<area>): <row> on macOS 28`, plus the co-author line.

### Task E4: Pipeline P, release by Tue 31 Aug 2027

- [ ] **Step 1: Run Procedure P (master §11) for `m07e`.** `/cso` scope: whatever the fixes touched. Design review if any UI changed.
- [ ] **Step 2: Merge, push, release.** Merge and push (P step 11). Then, per app (`markdown`, `data`, and `select` only if App 3 shipped), the K7 order every other release follows:
  - on `main`, `scripts/release.sh <app> <v> --no-upload`; `<path>` = the last stdout line;
  - on that DMG, E2's failing rows again on a macOS 28 beta M1 (E2 Step 1's lease and route, purchase approval first; Step 3 reuses it within 24 h), and on the build Mac `APP_NAME="<app name>" FIXTURES=<its fixtures> INSTALL_DIR="$(mktemp -d)" scripts/smoke-dmg.sh <path> docs/qa/macos28-release/<app>` (plan 06 Task 16 Step 2's form). Expected: every `smoke.txt` line `PASS`; for `select`, which has no Quick Look extension, every line but `FAIL quicklook none`, so the script exits 1 there and that line alone is expected;
  - record the rows in `docs/qa/macos28-beta.md`, then Commit: `docs/qa`, `docs(qa): macOS 28 release evidence for <app>` + trailer; `git status --porcelain -- . ':(exclude)docs'` → empty, since `--from-dmg` still runs `release.sh`'s clean-tree check;
  - `scripts/release.sh <app> <v> --yes --from-dmg <path>` (`--yes` only after that release's approval, since without a terminal the prompt aborts);
  - the site keys for that app and version (Global Constraints).

  Then the MAS update via `mas.yml upload=true` and the Setapp build via C4, each with approval.
- [ ] **Step 3: September RC.** Re-run only the previously failing rows on the release candidate (reuse the lease within 24 h, otherwise a new lease with approval) → `docs/qa/macos28-rc.md`.

---

## Section F: paid v2 mechanics (`m07f-v2`)

**How v2 works:**
- A new Polar product "Tegel Markdown 2" carries a **new** licence-key benefit. The app tells keys apart by `benefit_id`, which `validate` returns in its 200 response (polar.sh/docs/api-reference/customer-portal/license-keys/validate).
- v1 owners get a **personal one-use discount code** restricted to the v2 product. Polar discounts support `products`, `max_redemptions` and `max_redemptions_per_customer` and are created with `POST /v1/discounts/` (scope `discounts:write`; polar.sh/docs/features/discounts, /api-reference/discounts/create). Polar has no customer targeting, so each owner gets a unique code.
- **v1 keys keep every v1 feature in all future versions.** Only new v2 features check `hasV2`.

**Honest-pricing rules (rule 6, art. 5a Bpp, master §12):**
1. v2's public price is charged to everyone from its launch day. No intro price within 30 days of any upgrade announcement.
2. The site shows "Upgrade for v1 owners: $X" as a real price, never as a strike-through of a former price.
3. No countdown. If the upgrade price ends, its date is stated from day one and kept.
4. Licence limits are stated before purchase.
5. Nothing a v1 owner bought is removed.

### Task F0: Gate and re-validation → `docs/reviews/m07f-revalidation.md`

- [ ] **Step 1: Gate.** `docs/gates/G4.md` shows `Decision: CONTINUE`, the user has said go, and v2's features come from a separate brainstorm spec. The user sets the v2 price and the upgrade price.
- [ ] **Step 2: TegelStore diff** against master §3.3. Record plan 03's singular `PolarConfig.benefitID`, its activate-time check and `PolarError.wrongProduct`, and which app targets set `TGPolarBenefitID`. F1 generalises plan 03's `benefitID` to sets (CR 07-7).
- [ ] **Step 3: Branch and commit.** `git checkout -b m07f-v2 main`.

### Task F1: TegelStore generalises the benefit id to sets

Plan 03 already binds each key to one benefit (D1): `PolarConfig.benefitID: String` (Info.plist `TGPolarBenefitID`, build setting `TG_POLAR_BENEFIT_ID_<APP>`), `benefit_id` on validate, an activate check against `license_key.benefit_id` that deactivates a mismatch, and `PolarError.wrongProduct` with its copy. F1 only widens that single id to sets, so one app can accept its v1 and v2 benefits.

**Files:**
- Modify: `Packages/TegelKit/Sources/TegelStore/*` (`PolarClient`, `LicenseManager`, `PolarConfig`, `StoredLicense`; file names from F0); `Config/{Debug,Release}.xcconfig` and the sandbox xcconfig: rename `TG_POLAR_BENEFIT_ID_<APP>` → `TG_POLAR_BENEFIT_IDS_<APP>` for every app target, and add `TG_POLAR_V2_BENEFIT_IDS_MARKDOWN` (space-separated, X29); `project.yml` (Info.plist `TGPolarBenefitID` → `TGPolarBenefitIDs = $(TG_POLAR_BENEFIT_IDS_<APP>)` on every app target, plus `TGPolarV2BenefitIDs = $(TG_POLAR_V2_BENEFIT_IDS_MARKDOWN)` on `markdown`); `scripts/release.sh` (plan 03's; item 7's "`TGPolarBenefitID` non-empty" pre-notary check reads `TGPolarBenefitIDs`, and `check_app`'s benefit comparison reads `TG_POLAR_BENEFIT_IDS_<SLUG>` and `TGPolarBenefitIDs`, Step 6)
- Test: `Packages/TegelKit/Tests/TegelStoreTests/BenefitTests.swift`

**Interfaces (contract changes, listed at the end):**
- `public struct ValidatedLicense: Sendable, Equatable { public let expiresAt: Date?; public let benefitID: String }`
- `public struct Activation: Sendable, Equatable { public let id: String; public let benefitID: String }`; `PolarClient.activate(key:label:) async throws -> Activation`, read from the response's `license_key.benefit_id`. `LicenseManager` stores `benefitID` in the `StoredLicense` **at activation** (CX16), so a new v2 key has `hasV2` before its first validate.
- `PolarClient.validate(key:activationID:benefitID:) async throws -> ValidatedLicense`. It sends its `benefitID` argument as `benefit_id`; the client holds no stored licence, so `LicenseManager.refresh` chooses the id: the stored licence's `benefitID`, or for a legacy item (nil, written before F1 by a build that accepted only the v1 benefit) the v1 id, the single member of `benefitIDs.subtracting(v2BenefitIDs)` (plan 03 binds one v1 benefit per app; F0 Step 2).
- `StoredLicense` gains `public var benefitID: String?` (decoded with `decodeIfPresent`, so v1.x Keychain items read as nil and fill on the next 200).
- `PolarConfig.benefitID: String` becomes `public let benefitIDs: Set<String>`, plus `public let v2BenefitIDs: Set<String>`. `LicenseManager` gains `public var hasV2: Bool`. `PolarError.wrongProduct` and its copy are plan 03's, unchanged.

- [ ] **Step 1: Write the failing tests** (reusing plan 03's URLProtocol stub and its `makeManager(…, now:)` helper over the designated `LicenseManager(client:keychain:now:)`; every stamped date is relative to plan 03's `t0`, and every `refresh` passes `now:`, so no test reads the real clock):
  - `testValidateReturnsBenefitID`: `validate(key:activationID:benefitID: "b-v2")` against a stubbed 200 `{"benefit_id":"b-v2","expires_at":null,…}` → the request body's `benefit_id == "b-v2"`, and it returns `ValidatedLicense(expiresAt: nil, benefitID: "b-v2")`.
  - `testActivateAcceptsAnyBenefitInTheSets`: activate → `{"id":"act1","license_key":{"benefit_id":"b-v2"}}` with `"b-v2"` ∈ `v2BenefitIDs` → returns `Activation(id: "act1", benefitID: "b-v2")`, no deactivate.
  - `testActivateStoresBenefitIDAtOnce` (CX16): after that activate, `keychain.load()?.benefitID == "b-v2"` and `hasV2 == true` with no validate call; the next `refresh()` sends `benefit_id == "b-v2"`, never the v1 id.
  - `testActivateRejectsBenefitOutsideBothSets`: `{"id":"act1","license_key":{"benefit_id":"b-data"}}` → throws `.wrongProduct`; the stub recorded `deactivate` with `activation_id == "act1"`; `keychain.load() == nil` (plan 03's behaviour, now against the sets).
  - `testV1KeyIsProNotV2`: benefit `"b-v1"` ∈ `benefitIDs` → `isPro`, `!hasV2`.
  - `testV2KeyIsProAndV2`: benefit `"b-v2"` ∈ `v2BenefitIDs` → both true.
  - `testLapsedV2KeyHasNoV2`: `lastValidatedAt = t0`, the manager at `now: t0 + 31 * 86_400`, network down, `refresh(now: t0 + 31 * 86_400)` → `hasV2 == false`.
  - `testLegacyStoredLicenseDecodes`: JSON without `benefitID` decodes with `benefitID == nil`; `isPro` unchanged within grace; its next `refresh` sends `benefit_id == "b-v1"`.
  - `test404StillFallsIntoGrace`: the [F3d] invariant is unchanged.
- [ ] **Step 2: Watch it fail.** `swift test --package-path Packages/TegelKit --filter BenefitTests` → FAIL to compile (`ValidatedLicense` undefined).
- [ ] **Step 3: Implement.**
  - Decode `benefit_id` from validate, and `license_key.benefit_id` from activate; `LicenseManager.activate` writes it into the new `StoredLicense`.
  - `validate` takes `benefitID:` and `refresh` passes it as the Interfaces say; plan 03's `validate` tests (`validateSendsExactBodyAndReturnsExpiry` and the rest) pass `benefitID: "ben-1"`, so their expected bodies are unchanged.
  - `activate`: plan 03's check against `license_key.benefit_id`, widened to `benefitIDs ∪ v2BenefitIDs`; on a miss it still deactivates and throws `.wrongProduct`.
  - `refresh` stores `benefitID` on each 200. `hasV2`: `state` is `.pro(l)` with `l.benefitID ∈ v2BenefitIDs`. `PolarConfig.fromInfoPlist` splits `TGPolarBenefitIDs` and `TGPolarV2BenefitIDs` on spaces.
- [ ] **Step 4: Watch it pass.** `swift test --package-path Packages/TegelKit` → all pass, including plan 03's binding and grace tests. Watch the CX16 guard fail: make `LicenseManager.activate` store `benefitID: nil` → `testActivateStoresBenefitIDAtOnce` fails; restore. `xcodegen generate && make build`, then `/usr/libexec/PlistBuddy -c 'Print TGPolarBenefitIDs'` on each built app → its own benefit id(s), never empty.
- [ ] **Step 5: Commit:** `Packages/TegelKit Config project.yml`, `feat(store): benefit-id sets for v2 entitlement` + trailer.
- [ ] **Step 6: Move `release.sh`'s benefit check to the new key, watched failing first.** With Step 5 committed and `release.sh` unchanged: `scripts/release.sh markdown <next v1.x>-rc1 --sandbox --no-upload` → exit 1 at item 7's `TGPolarBenefitID` check (the key no longer exists), which is what would stop F2's release. Change that check to `TGPolarBenefitIDs` non-empty, and in `check_app` set `k=TG_POLAR_BENEFIT_IDS_…`, compare `Print :TGPolarBenefitIDs` with it and say `TGPolarBenefitIDs is not $k …` in its `die`; in `scripts/release_test.sh` change `from-dmg-no-appex`'s expected text to `TGPolarBenefitIDs is not TG_POLAR_BENEFIT_IDS_SELECT` (unchanged, every `--from-dmg` publish, F2's included, would stop at `check_app`: the old key no longer exists in `Config/Release.xcconfig`); commit `scripts/release.sh scripts/release_test.sh`, `build(release): pre-notary check and check_app read TGPolarBenefitIDs` + trailer (it needs a clean tree); re-run → past the pre-notary checks, notarised, the DMG path printed last. `bash scripts/release_test.sh` → `0 failed`.

### Task F2: The `hasV2` seam and a v1.x that accepts v2 keys

**Files:** Modify `Apps/Markdown/App/ProGate.swift` (adds `EnvironmentValues.hasV2: Bool`; true under `UNLOCKED`), `Config/Release.xcconfig` (adds the v2 benefit id to `TG_POLAR_BENEFIT_IDS_MARKDOWN` and `TG_POLAR_V2_BENEFIT_IDS_MARKDOWN`, Step 2b) and `.env.example`; Test: `Apps/Markdown/AppTests/ProGateTests.swift` (`POLAR_PRODUCT_ID_MARKDOWN_V2`, `POLAR_BENEFIT_ID_MARKDOWN_V2`)

- [ ] **Step 1: Write the failing test.** `MarkdownAppTests/ProGateTests.testHasV2DefaultsFalseForV1Key` with F1's `LicenseManager` stub; `xcodebuild test -scheme markdown -destination 'platform=macOS' -only-testing:MarkdownAppTests/ProGateTests` → FAIL (no member `hasV2`).
- [ ] **Step 2: Implement the seam;** the test passes.
- [ ] **Step 2b 🔒: The live v2 product and benefit** (approval: a live Polar product). In Polar production, create the benefit "Tegel Markdown 2 licence" with plan 05 Task 2 Step 4's settings (License keys, `limit: 2`, `enable_customer_admin: true`, no expiry, no usage limit), and the product "Tegel Markdown 2": one-time, F0's v2 price in USD and EUR, that benefit, plan 05's `marketing_opt_in` field (unticked), and a description that states the licence limits. No checkout link yet, since v2 isn't on sale: check that Polar's storefront doesn't list it (as plan 06 Task 12 Step 3).
  - `. scripts/lib/env.sh`, then `envset POLAR_PRODUCT_ID_MARKDOWN_V2 '<id>'` and `envset POLAR_BENEFIT_ID_MARKDOWN_V2 '<id>'`; `need POLAR_PRODUCT_ID_MARKDOWN_V2 POLAR_BENEFIT_ID_MARKDOWN_V2 && echo saved` → `saved`. Add both names to `.env.example`.
  - In `Config/Release.xcconfig`, append the v2 benefit id to `TG_POLAR_BENEFIT_IDS_MARKDOWN` (space-separated, after the v1 id) and set `TG_POLAR_V2_BENEFIT_IDS_MARKDOWN` to it, so F1's legacy rule (`benefitIDs.subtracting(v2BenefitIDs)`) still leaves the single v1 id. Expected: `. scripts/lib/env.sh; grep -cE "^TG_POLAR_(V2_)?BENEFIT_IDS_MARKDOWN = .*$(envget POLAR_BENEFIT_ID_MARKDOWN_V2)" Config/Release.xcconfig` → `2`.
  - Commit: `Apps/Markdown/App/ProGate.swift Apps/Markdown/AppTests/ProGateTests.swift Config/Release.xcconfig .env.example`, `feat(v2): hasV2 seam; v1.x accepts the v2 benefit` + trailer.
- [ ] **Step 2c: Review before release.** Run Procedure P (master §11) on `m07f-v2` with F4's `/cso` scope and design review (its discount-script items wait for F3), through its merge and push. Step 3 ships F1's licence, Keychain and `release.sh` changes, so the full P runs first (master §11, out of cadence); F4 runs it again over F3.
- [ ] **Step 3: Ship.** Ship the last v1.x with the v2 benefit in `TG_POLAR_BENEFIT_IDS_MARKDOWN` **before** v2 goes on sale, so v2 buyers on older systems still get v1 Pro. On `main` (Step 2b committed it and Step 2c merged it; `release.sh` needs a clean tree): `scripts/release.sh markdown <v1.x> --no-upload`, then QA on that DMG with rows in `docs/qa/markdown-<v1.x>.md`, committed (`git status --porcelain -- . ':(exclude)docs'` → empty, since `--from-dmg` still runs the clean-tree check), then `scripts/release.sh markdown <v1.x> --yes --from-dmg <path>` (approval; `--yes` only after it, since without a terminal the prompt aborts), then the site keys (Global Constraints).

### Task F3: Upgrade codes for v1 owners

**Files:** Create `scripts/v2/upgrade-codes.js`, `scripts/v2/upgrade-codes.test.js`

**Interfaces:**
- `upgradeBasisPoints({ usd: [fullCents, upgradeCents], eur: [fullCents, upgradeCents] }) -> number`: `Math.round(10000 × (full − upgrade) / full)` from the USD pair. It throws unless the EUR pair gives the same upgrade price to the cent (`Math.round(fullEUR × (10000 − bp) / 10000) === upgradeEUR`). Every Polar product carries a EUR price beside the USD one (master), and a percentage discount applies in either checkout currency, where a USD-only fixed amount would fail or not apply on a EUR checkout.
- `planDiscounts(orders, { v2ProductId: string, basisPoints: number, existingCodes: Set<string> }) -> Array<{ customerId, email, code, body }>`, where `body = { name, type: 'percentage', basis_points: basisPoints, duration: 'once', code, max_redemptions: 1, products: [v2ProductId] }`. Before Step 1, check every body field name against Polar's create-discount API docs (polar.sh/docs/api-reference/discounts/create) and use the names they give.
- CLI `bun scripts/v2/upgrade-codes.js --v2-product <id> --full <usd cents>,<eur cents> --upgrade <usd cents>,<eur cents> [--v1-products <id,…>] [--sandbox] [--apply]` (dry run by default): the v2 prices and upgrade prices the user set in F0, in both currencies. v1 orders are those of `scripts/gates/products.json`'s `markdown` and `bundle` ids, or of `--v1-products`. `--sandbox` sends every call to `https://sandbox-api.polar.sh` with `POLAR_SANDBOX_ACCESS_TOKEN` (plan 03 Task 1 Step 11: it holds `orders:read` and `discounts:write`) and never reads a production token; without it, the base is `https://api.polar.sh`. Both come from `apiConfig(sandbox: boolean, env) -> { base, readToken, writeToken }`. Production orders are read with `POLAR_ACCESS_TOKEN`; `--apply` posts discounts with `POLAR_DISCOUNTS_TOKEN`, a one-off token with scope `discounts:write` only, created for this run and deleted after it (K8, S18). Both are passed one at a time (K1).

- [ ] **Step 1: Write the failing tests.** Three v1 orders from two customers (one a bundle order) → 2 plans. Codes are unique and match `^[A-HJ-NP-Z2-9]{10}$`. Each `body` equals `{ name, type: 'percentage', basis_points: bp, duration: 'once', code, max_redemptions: 1, products: [v2ProductId] }` exactly (no `amounts`). `upgradeBasisPoints({ usd: [2900, 1500], eur: [2900, 1500] })` → `4828`; `{ usd: [2900, 1500], eur: [2700, 1500] }` throws (the EUR checkout would charge €13.96, not the stated €15). A customer whose name already appears in `existingCodes` is skipped (idempotent re-run). Refunded orders are excluded. `apiConfig(true, env)` returns the sandbox base and `POLAR_SANDBOX_ACCESS_TOKEN` for both tokens, with an `env` whose `POLAR_ACCESS_TOKEN` and `POLAR_DISCOUNTS_TOKEN` getters throw (a sandbox run that touched either would post live discounts); `apiConfig(false, env)` returns `https://api.polar.sh`.
- [ ] **Step 2: Watch it fail.** `bun test scripts/v2` → FAIL (module missing).
- [ ] **Step 3: Implement.** Codes come from `crypto.getRandomValues`. `--apply` calls `POST /v1/discounts/` and writes `local-docs/v2/codes.csv` (gitignored; it holds emails).
- [ ] **Step 4: Watch it pass, then a sandbox run.** `bun test scripts/v2` → PASS. Plan 03 Task 15 archived the sandbox `Tegel Markdown` product, so in the sandbox dashboard (no approval) create a stand-in v1 product `F3 v1 (test)` with a licence-key benefit and a checkout link, and a v2 product with both prices. Buy the v1 one twice with the test card: as `POLAR_EMAIL` and as a `+v2` plus-address of it (two customers; the codes come from the CSV, not an email). The dry run then lists 2 plans. Then `. scripts/lib/env.sh` and `--sandbox --apply --v1-products <F3 v1 id> --v2-product <v2 id>`: one code checks out at the USD upgrade price from a USD checkout (record how that currency was reached: Polar picks it by geolocation), another at the EUR upgrade price from a EUR checkout (the build Mac's Dutch IP, as in plan 04 Task 14 Step 3), and a second use of either is refused. If a total differs from the stated upgrade price, stop: the site would state a price Polar doesn't charge.
- [ ] **Step 5: Live, on v2's launch day.** It waits for v2's own release, planned from F0's brainstorm spec: the v2 DMG published with approval, the live v2 checkout link created with discount codes **on** (unlike plan 05 Task 2 Step 6's App 1 link) and BNPL-checked (plan 05 Task 2 Step 11), and the v2 page deployed with the v2 price, the upgrade price and the licence limits (rule 6). Until then Steps 1–4 and 6 are done and this step waits; no owner is emailed about an offer they can't buy. After the live run and before the email, ask the user to approve "create one test discount on the live v2 product, check its total at checkout without paying, then delete it" (a live discount, CLAUDE.md); after the yes, create that one extra live code with the same body (no owner's), enter it on the live v2 checkout (Playwright, no payment) and check that the total shown is the stated upgrade price, in USD and in EUR as in Step 4; then delete that code in the Polar dashboard. The user creates `POLAR_DISCOUNTS_TOKEN` (`discounts:write` only) and it goes into `.env` with `envset`. The live run, with `--v2-product "$(envget POLAR_PRODUCT_ID_MARKDOWN_V2)"` (F2 Step 2b; approval of the live discounts); the owner email through plan 08's MailerLite buyer groups to opted-in owners only (K9; approval), stating the v2 price, the upgrade price, and that v1 keeps working. Owners who didn't opt in get their code on request through `hello@tegelapps.com`, which the v2 page says.
- [ ] **Step 5b 🔒: Delete the one-off token.** Revoke it in the Polar dashboard, then `. scripts/lib/env.sh; envset POLAR_DISCOUNTS_TOKEN ''; [ -z "$(envget POLAR_DISCOUNTS_TOKEN)" ] && echo gone`. Expected: `gone`.
- [ ] **Step 6: Commit** `scripts/v2`.

### Task F4: Pipeline P for `m07f`

- [ ] **Step 1: Run Procedure P (master §11).** `/cso` scope: the licence state machine (no lockout on 404/5xx; `wrongProduct` frees the activation; the benefit id stored at activation); Keychain migration; Info.plist benefit ids; the discount script's token use (`POLAR_DISCOUNTS_TOKEN` empty after F3, S18) and keeping its email CSV out of git. Design review: the upgrade UI copy.
- [ ] **Step 2: Merge and push.**

---

## Contract change requests

Row 14 accepted and applied to plan 08 Task 4 Step 8 and Task G1 (27 Oct); history in `docs/reviews/m00-consolidated.md`. Row 13 is dropped: Task B3 Step 4 adds the inputs guard to plan 01's `check-guards.sh`. Open:

| # | Change | Reason | Section |
|---|---|---|---|
| 1 | §3.2: `renderToHTML` also emits math placeholders (`.math-src`, `data-math`, `dir="ltr"`) and footnotes (`fn<N>`/`fnref<N>`, `user-content-` prefixed in the DOM; `dir="auto"` on the footnotes `<section>` only, never per item). `window.tegel.render` lazy-loads `katex/katex.min.js` like Mermaid and sanitises KaTeX output with `SANITIZE_CONFIG` from `Renderer/src/sanitize.js` (plan 01), inserted with `replaceChildren` | v1.1 math and footnotes (BUSINESS-PLAN §6.1) | A1, A2 |
| 2 | §3.2/§3.3: `RenderOptions.userCSS: String?` and JS `opts.userCSS`, injected as the last `<style id="tegel-user-css">` under the unchanged CSP | Custom CSS | A3 |
| 3 | App seam: `ProGate.isProNow()` (static, `@MainActor`) beside `EnvironmentValues.isPro`, plus `EnvironmentValues.hasV2` | App Intents run outside the SwiftUI environment; v2 gating | A5, F2 |
| 4 | §3.1 layout: `Apps/Markdown/App/Direct/`, `Apps/Markdown/{MAS,MASTests,Setapp}/`, `Apps/Select/`, `scripts/gates/products.json`, `scripts/v2/`, `scripts/{mas.sh,verify-store-build.sh,verify-no-keylogging.sh}`, `.github/workflows/mas.yml`. Gate counting extends plan 05's `polar_sales.py` (no second counter, no Makefile change; X22) | Store editions, App 3, gate tooling | G0, G1, B1, B3, C3, D3 |
| 5 | D5 entitlements gain two variants: MAS (no temporary exceptions; the Quick Look extension keeps D5's set, which has had no absolute-path read-only exception since K4) and Setapp (adds `mach-lookup` `com.setapp.ProvisioningService`) | Guideline 2.4.5; Setapp README | B1, C3 |
| 6 | Swift compilation conditions `UNLOCKED`, `MAS`, `SETAPP` | Drop TegelStore and Sparkle at compile time | B1, C3 |
| 7 | TegelStore: `ValidatedLicense`; `validate(key:activationID:benefitID:)` returns it, with the benefit id chosen by `LicenseManager`; `StoredLicense.benefitID: String?`; plan 03's `PolarConfig.benefitID` generalised to `benefitIDs`/`v2BenefitIDs`; `LicenseManager.hasV2`. D16: `TGPolarBenefitID` → `TGPolarBenefitIDs`, plus `TGPolarV2BenefitIDs`; build settings `TG_POLAR_BENEFIT_IDS_<APP>`, `TG_POLAR_V2_BENEFIT_IDS_MARKDOWN`. `PolarError.wrongProduct` already exists (plan 03) | v2 (wrong-app keys are already rejected by plan 03) | F1 |
| 8 | Global constraint "No Accessibility…" scoped to Apps 1–2. App 3 may use Accessibility only: no event tap, no Input Monitoring, no key monitor. **NO-GO until the user signs it off explicitly** (D2) | BUSINESS-PLAN §7.2, §14 backlog #1 | D |
| 9 | Product rule 1 ("No telemetry") gains a Setapp-edition exception, **only if the user signs C2**; NO-GO until then | The Setapp framework collects usage, performance and device data | C2 |
| 10 | `scripts/release.sh` accepts the apps `markdown-setapp` (zip; no DMG, appcast or R2) and `select` | Setapp packaging; App 3 | C4, D6 |
| 11 | TegelStore: `PolarConfig.finalBuild` (Info.plist `TGFinalBuild`, build setting `TG_FINAL_BUILD`); `refresh()` makes no call and any stored licence reads `.pro` when it's set (never `.lapsed`, so the Licence tab offers no Check Again or Remove Licence…, and the key is kept). Master: every stop path runs Procedure S | K14: a stop never strands a buyer | G7 |
| 12 | `PDFStamper.stamp(_:header:) -> Data`, in memory, applied between plan 02's `makePDFData` and its one write | No new file write; `readonly-gate` unchanged | A4 |
| 15 | `PolarClient.activate` returns `Activation { id, benefitID }` and the benefit id is stored at activation | CX16 | F1 |

## Open questions only the user can answer

1. **Setapp:** accept the Setapp edition's usage reporting as a disclosed exception to rule 1, or skip Setapp? (C2; default no.)
2. **MAS price:** $19.00 in the USD storefront, and is Apple's auto-generated euro price acceptable? (B4)
3. **v2 prices:** the v2 list price and the v1-owner upgrade price, each in USD and EUR, with the same upgrade percentage in both (F0, F3).
4. **App 3:** name, price ($15?), trigger, and whether a clipboard fallback is acceptable (D1); and the Accessibility-API exception (CR-8, D2; default NO-GO until you sign it off).
5. **G2 counting:** do bundle sales count as "App 1 sales"? (G2; the plan counts them and flags it when it decides the outcome.)
6. **G3 STOP:** the plan follows BUSINESS-PLAN §12 and keeps the apps on sale with a "Maintenance only" note; Task G7 (stop sales, then final builds) runs when maintenance ends. Or stop sales at G3 itself? (Default: keep on sale.)
7. **EUR prices** for the Data product, the bundle and App 3 (K10; defaults €15 and €29 in plan 06).
