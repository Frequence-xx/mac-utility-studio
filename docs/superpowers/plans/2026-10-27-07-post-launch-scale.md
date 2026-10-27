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

- **Platform:** macOS **14.0** deployment target; universal binary (arm64 + x86_64).
- **Build Mac:** Intel, macOS 15.7, Xcode 26.3 — the last Xcode it can run [F2]. Evidence for arm64 or macOS 26/27/28 comes only from GitHub Actions or Scaleway, and every QA record names the machine.
- **Product rules 1–9 (`CLAUDE.md`)** bind code, UI copy, screenshots, listings and posts.
- **Read-only:** the only writes are a save-panel export, the app's own container, and (App 3) the pasteboard on an explicit action.
- **No telemetry, no accounts.** Network use is limited to Polar licence calls and Sparkle. The MAS edition makes **no** network calls. Setapp framework reporting is allowed only if the user signs the exception in Task C2.
- **Pricing (verbatim):** App 1 **$19 once, 2 Macs**; App 2 **$15**; bundle **$29**; MAS at the $19 price point. App 3 and v2 prices are set by the user (D1, F0). No fake "was" price, no countdowns, licence limits stated before purchase, 14-day refund (rule 6, art. 5a Bpp).
- **Licence:** 2 activations [F3e]; **30-day grace** from the last 200. A 404, 5xx or network error never locks a user on the spot [F3d].
- **Permissions:** **no Accessibility, Screen Recording or Input Monitoring in Apps 1–2.** App 3 would use Accessibility only: no event tap, no Input Monitoring, no key-event monitor. That exception (CR-8) stays **NO-GO until the user signs it off explicitly** in D2.
- **Design:** `DESIGN.md` (plan 09) is the only source of UI values. Every section with UI closes with a `design-review` pass (screenshots in light, dark and Arabic UI).
- **Outward-facing actions need approval of that specific action first:** releases and appcast uploads, live Polar products/prices/discounts, MAS/Setapp/Homebrew submissions, posts and emails, purchases (Scaleway leases).
- **Gate windows:** the **30 full days before the gate day**, Europe/Amsterdam. EUR uses the ECB rate on the gate day:
  `curl -s 'https://data-api.ecb.europa.eu/service/data/EXR/D.USD.EUR.SP00.A?lastNObservations=1&format=csvdata' | python3 -c "import csv,sys; r=list(csv.DictReader(sys.stdin))[-1]; print(r['TIME_PERIOD'], r['OBS_VALUE'])"`
- **Dependencies:** exact pins, releases ≥ 14 days old at install, licences added to the third-party notices file (plans 02/05).
- **Hours:** ≤ 20 h/week; ≤ 10 h/week if G3 lands in €100–300; ≤ 2 h/week under a G2 freeze (BUSINESS-PLAN §11–12).
- **Secrets:** never printed; docs name `.env` keys only.
- **Commits:** every message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, shown below as a second `-m`.

## Review Focus

1. **Hostile TeX and plain dollar signs** (`Intro $14 until 14 Dec, then $19.`, `\href{javascript:…}`, `\includegraphics{https://…}`, `\htmlData`, `</span><script>`, a `\def` bomb). Expected: prices stay text; no element or attribute that can run script or fetch; the bomb renders an error in < 500 ms. *(Task A1.)*
2. **Hostile or broken custom CSS** (`@import`, remote `url()` backgrounds/fonts, `</style><script>`, a 300 KB file, a stylesheet deleted after it was picked). Expected: zero network connections, no script, the size cap enforced, theme fallback with a notice. *(Task A3.)*
3. **Mixed bidi in the new blocks:** Arabic footnotes, inline math in an Arabic paragraph, an Arabic title in the PDF header. Expected: footnote `<li dir="auto">`, math stays LTR, the header stamps without changing the page count. *(Tasks A1, A2, A4.)*
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

## Shared procedure P: 9-stage pipeline, merge, push

Each section's last task runs P with its id (`m07a` … `m07f`), its `/cso` scope and the review file `docs/reviews/<id>.md`. A stage that can't run is written down in the review file with the reason and the substitute. `BASE=$(git merge-base HEAD main)`.

1. **Bloat (pre):** apply `~/.claude/skills/code-upgrade/bloat-audit.md` to `git diff $BASE...HEAD` and the touched files. Strip self-introduced bloat; pre-existing findings go under "Questions for the user".
2. **Baseline:** `git status --short` is empty, then `make check 2>&1 | tee /tmp/<id>-check.log`. Record the pass/fail counts.
3. **Code review:** gstack `/review` on `git diff $BASE...HEAD` (fallback: a code-review subagent).
4. **Security:** `/cso` with the section's scope.
5. **Adversarial:** `/codex` challenge mode on the same diff.
6. **Consolidate:** a P0/P1/P2 table in `docs/reviews/<id>.md`.
7. **Patch + re-review:** fix every P0/P1 and the actionable P2s; re-run `make check` and the targeted tests.
8. **Bloat (post):** over the final cumulative diff.
9. **Final loop:** `/review`, then `cubic review -b $BASE -j > /tmp/<id>-cubic.json && jq '.issues | length' /tmp/<id>-cubic.json`. Repeat after each fix batch until two consecutive rounds show no new P0/P1.
10. **UI sections:** `design-review` with screenshots in `docs/reviews/<id>-design/`.
11. **Merge:** `git checkout main && git pull --ff-only && git merge --no-ff <branch> -m "merge: <id>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" && make check && git push origin main && graphify update .` (push authorised, D14).

---

## Section G: gates (`m07-gates`)

### Task G0: Re-validate gate inputs (Thu 4 Mar 2027)

**Files:** Create `docs/gates/m07-inputs.md`, `scripts/gates/products.json`

- [ ] **Step 1: Stop check.** Read `docs/gates/G1.md` and plan 06's 4 Mar record. If App 1 had < 10 sales at G1 **and** App 2 has < 10 by 4 Mar: write `docs/gates/STOP.md` ("plan 07 cancelled; apps stay on sale"), commit, stop.
- [ ] **Step 2: Token scope** (loaded without echo):
  ```bash
  set -a; . ./.env; set +a
  curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $POLAR_ACCESS_TOKEN" "https://api.polar.sh/v1/orders/?organization_id=$POLAR_ORGANIZATION_ID&limit=1"
  ```
  Expected `200` (scope `orders:read`, polar.sh/docs/api-reference/orders/list). On 401/403 the user issues a token with `orders:read` + `products:read`.
- [ ] **Step 3: Product ids.** From `GET https://api.polar.sh/v1/products/?organization_id=$POLAR_ORGANIZATION_ID&limit=100`, write `scripts/gates/products.json` = `{"markdown":[…],"data":[…],"bundle":[…],"select":[]}`. Product ids aren't secret.
- [ ] **Step 4: Reuse check.** One Polar counter only (X22). Record the shipped signatures of plan 05's `scripts/polar_sales.py` (`fetch_orders`, `count_sales`, `window`, CLI) and of plan 08's `kpi.gsc_totals(f, start, end)`, plus the column names of the GSC dates CSV that `kpi.py` reads. G1 extends the former and calls the latter.
- [ ] **Step 5: Other inputs.** Record the support-log path and row format from plan 05 (expected `docs/ops/support-log.md`, rows `| date | minutes | mails | refunds | licence | bug/feature | notes |`) and the Google login that opens Search Console for `tegelapps.com`.
- [ ] **Step 6: Commit.**
  ```bash
  git add docs/gates/m07-inputs.md scripts/gates/products.json
  git commit -m "docs(gates): m07 inputs and product ids" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  ```

### Task G1: Gate metrics (Polar orders, GSC export)

One counter for every gate (X22): G1 extends plan 05's `scripts/polar_sales.py`, the script plan 05's G1 and plan 08's `kpi.py` already use, and reads GSC through plan 08's `kpi.gsc_totals`. No second order counter, no new test runner.

**Files:**
- Modify: `scripts/polar_sales.py`, `scripts/test_polar_sales.py` (plan 05; already in `make check` through `test-scripts`)

**Interfaces:**
- Consumes: plan 05's `fetch_orders`, `count_sales` and `window`; `scripts/gates/products.json` (G0); plan 08's `kpi.gsc_totals(f, start, end) -> {"clicks", "impressions"}` (`end` exclusive). `GET /v1/orders/` fields `status`, `product_id`, `currency`, and the cent amounts `total_amount`, `net_amount` ("after discounts but before taxes"), `platform_fee_amount`, `refunded_amount`, `refunded_tax_amount` (polar.sh/docs/api-reference/orders/get).
- Produces:
  - `summarise(orders: list[dict], product_ids: set[str]) -> dict` with keys `count`, `gross_usd`, `net_usd`. It counts exactly what `count_sales` counts as `sales` (status `paid`/`partially_refunded`, `net_amount > 0`, product in the set) and raises `ValueError` naming `currency` on any counted non-USD order.
  - CLI: `python3 scripts/polar_sales.py --from YYYY-MM-DD --to YYYY-MM-DD --summary [--products markdown,bundle]` prints `count=<n> gross_usd=<x> net_usd=<y> from=<date> to=<date>`. `--products` maps names through `products.json`; without it, `--summary` covers every product there. The window is `window(from, to)`: 00:00 Europe/Amsterdam, end exclusive. It never prints the token.

- [ ] **Step 1: Write the failing tests** (append to `scripts/test_polar_sales.py`, inside its `unittest.TestCase`, importing `summarise`):
```python
def g(**x):
    return {"currency": "usd", "status": "paid", "product_id": "p1", "total_amount": 1900, "net_amount": 1900,
            "platform_fee_amount": 145, "refunded_amount": 0, "refunded_tax_amount": 0, **x}

def test_summarise_gross_and_net_of_fees_vat_and_refunds(self):
    self.assertEqual(summarise([
        g(),                                                    # US: 1900 - 145
        g(net_amount=1570, platform_fee_amount=174),            # EU, 21% VAT inside the 1900: 1570 - 174
        g(status="partially_refunded", refunded_amount=950),    # 1900 - 145 - 950
        g(status="refunded", refunded_amount=1900),             # excluded
        g(product_id="p2"),                                     # other product
        g(total_amount=0, net_amount=0, platform_fee_amount=0), # $0 order excluded
    ], {"p1"}), {"count": 3, "gross_usd": 47.5, "net_usd": 39.56})

def test_non_usd_order_fails_loudly(self):
    with self.assertRaisesRegex(ValueError, "currency"):
        summarise([g(currency="eur")], {"p1"})
```
- [ ] **Step 2: Run and watch it fail.** `python3 -m unittest discover -s scripts -p 'test_polar_sales.py' -v` → FAIL: `ImportError: cannot import name 'summarise'`.
- [ ] **Step 3: Implement.**
  - `summarise` keeps the orders `count_sales` would count as sales; `gross_usd = Σ(total_amount − refunded_amount)/100`; `net_usd = Σ(net_amount − platform_fee_amount − (refunded_amount − refunded_tax_amount))/100`; both rounded to cents.
  - `--summary` calls `fetch_orders` once per product id in the window, then `summarise` over the union.
- [ ] **Step 4: Run and watch it pass.** The Step 2 command → `OK` (plan 05's tests plus these 2); `make check` → all pass.
- [ ] **Step 5: Commit.**
  ```bash
  git add scripts/polar_sales.py scripts/test_polar_sales.py
  git commit -m "feat(gates): gross/net summary and product filter in polar_sales.py" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  ```

### Task G2: G2, Mon 8 Mar 2027 (day 90) → `docs/gates/G2.md`

**Thresholds (BUSINESS-PLAN §12, verbatim):** continue if "App 1: ≥ 25 sales in the last 30 days **and** GSC ≥ 10,000 impressions/30 d". Kill / change if "< 10 sales **and** < 2,000 impressions → the SEO thesis failed; freeze at maintenance only (≤ 2 h/week)". **Window:** `2027-02-06T00:00:00+01:00` → `2027-03-08T00:00:00+01:00`.

- [ ] **Step 1: Sales.** Run `set -a; . ./.env; set +a; python3 scripts/polar_sales.py --from 2027-02-06 --to 2027-03-08 --summary --products markdown`, then again with `--products bundle`. App 1 sales = both counts (each bundle sells an App 1 licence). Record both; flag it to the user if counting the bundle flips the decision.
- [ ] **Step 2: Impressions.** The user, in their own browser: Search Console → `tegelapps.com` → Performance → Search results → Date: Custom **6 Feb – 7 Mar 2027**, Search type Web → Export → Download CSV → save to `local-docs/gates/G2-gsc/` (gitignored). Run `python3 -c "import sys; sys.path.insert(0, 'scripts'); from datetime import date; from kpi import gsc_totals; print(gsc_totals(open('local-docs/gates/G2-gsc/Dates.csv'), date(2027, 2, 6), date(2027, 3, 8))['impressions'])"` (the dates CSV name as recorded in G0). Also record total clicks (risk 9), App 1 page impressions (`Pages.csv` rows containing `/markdown`), and any days marked preliminary.
- [ ] **Step 3: Write `docs/gates/G2.md`:** thresholds verbatim, window, a metrics table with the command or source per number, stretch targets (master §12: sales ≥ 47, impressions ≥ 10,000), `Decision: PASS | MIDDLE | FREEZE` (PASS = both continue conditions; FREEZE = both kill conditions; otherwise MIDDLE), the cancellation list, `User sign-off: <date>`.
- [ ] **Step 4: Apply.** **FREEZE cancels** Sections A, B, C, D, F and the Homebrew task, and hands the SEO cadence back to plan 08. E (maintenance) and the support gate stay. **MIDDLE:** A and B proceed; plan 08 re-targets SEO. **PASS:** everything proceeds on schedule.
- [ ] **Step 5: Commit** `docs/gates/G2.md` to `main` (docs only) and push.

### Task G3: G3, Fri 30 Apr 2027 (month 6) → `docs/gates/G3.md`

**Thresholds (verbatim):** continue if "Combined net ≥ **€300/month** → build app 3". Kill / change if "€100–300 → no new app, ≤ 10 h/week. **< €100 → stop development**; keep the apps on sale". **Window:** `2027-03-31T00:00:00+02:00` → `2027-04-30T00:00:00+02:00`.

- [ ] **Step 1: Polar, all products.** `python3 scripts/polar_sales.py --from 2027-03-31 --to 2027-04-30 --summary` (no `--products`). Record `count`, `gross_usd`, `net_usd`.
- [ ] **Step 2: Payout ratio `r` from actual payout data.** Polar dashboard → Finance → Payouts: the USD withdrawn in the last 3 payouts; the user reads the EUR credited for each on the bank statement. `r = Σ EUR credited ÷ Σ USD withdrawn`. With fewer than 3 payouts: `r = 0.995 ÷ ECB USD-per-EUR` (§9's "about 0.5% payout/FX").
- [ ] **Step 3: Other channels.** MAS: App Store Connect → Sales and Trends → Proceeds for the window, converted at the ECB rate. Setapp: the developer-account statistics, if live.
- [ ] **Step 4: Compute.** Decision value **net = net_usd × r + MAS + Setapp**. Plan cross-check **net_§9 = gross_usd × 0.744** (§9: "€0.744 per $1 gross"). If the two Polar figures differ by > 15%, record the Polar country split (the §9 test) and propose updating the factor.
- [ ] **Step 5: Write `docs/gates/G3.md`:** thresholds, window, all inputs, stretch ≥ €760, `Decision: APP3 | NO-NEW-APP | STOP`, the cancellation list, sign-off.
- [ ] **Step 6: Apply.** **STOP cancels** C, D, F and Homebrew; development stops and the apps stay on sale; E runs as maintenance only. **NO-NEW-APP cancels** D (≤ 10 h/week). **APP3** starts D.
- [ ] **Step 7: Commit to `main` and push.**

### Task G4: G4, Fri 29 Oct 2027 (month 12) → `docs/gates/G4.md`

**Thresholds (verbatim):** continue if "≥ **€1,000/month** net → bundle, Setapp, app 4". Kill / change if "Otherwise wind down to maintenance". **Window:** `2027-09-29T00:00:00+02:00` → `2027-10-29T00:00:00+02:00`.

- [ ] **Step 0: Renewals (about Wed 20 Oct 2027, before G4).** The Apple Developer membership (paid 27 Oct 2026) and the domain (bought about 30 Oct 2026) renew around the gate. Ask the user (U-49): renew each, or turn auto-renew off first. A renewal is a purchase, so it needs the user's approval. Record the answers in `docs/gates/G4.md`.
- [ ] **Step 1: Measure.** Repeat G3 Steps 1–4 for this window, including App 3 (`select` in `products.json`), MAS proceeds and Setapp payouts.
- [ ] **Step 2: Write `docs/gates/G4.md`:** stretch ≥ €1,450, `Decision: CONTINUE | WIND-DOWN`, the cancellation list, sign-off.
- [ ] **Step 3: Apply.** **WIND-DOWN cancels** F, app 4 and any pending Homebrew work; macOS maintenance and support continue. **CONTINUE** makes F eligible; app 4 gets its own plan via `superpowers:brainstorming`.
- [ ] **Step 4: Commit to `main` and push.**

### Task G5: Support gate (rolling, every Monday from 8 Mar 2027) → `docs/gates/support.md`

**Thresholds (verbatim):** continue if "≤ 20 min/day averaged over 14 days". Kill / change if "> 30 min/day → fix the docs or raise the price before any new feature".

- [ ] **Step 1: Compute the 14-day average** (path from G0):
  ```bash
  python3 -c "import re,datetime as d;t=d.date.today();rows=re.findall(r'\|\s*(\d{4}-\d\d-\d\d)\s*\|\s*(\d+)\s*\|',open('docs/ops/support-log.md').read());print(round(sum(int(m) for day,m in rows if 0<(t-d.date.fromisoformat(day)).days<=14)/14,1))"
  ```
- [ ] **Step 2: Append a row:** `| date | avg min/day | GREEN ≤ 20 / AMBER 20–30 / RED > 30 | top 3 categories |`.
- [ ] **Step 3: On RED.** The next feature task in any active section waits. Write FAQ/docs fixes for the top 3 categories, or propose a price rise (outward-facing; never framed with a "was" price). Re-measure after 14 days.
- [ ] **Step 4: Commit the row** (and any docs fixes) to `main`.

### Task G6: Pipeline P for `m07-gates`

- [ ] **Step 1: Run P** (stages 1–9). `/cso` scope: `.env` loading and `POLAR_ACCESS_TOKEN` handling — never logged, only sent to `api.polar.sh`. Review file `docs/reviews/m07-gates.md`.
- [ ] **Step 2: Merge and push;** `make check` is green on `main`.

---

## Section A: App 1 v1.1 (`m07a-v1.1`)

### Task A0: Re-validate v1.1 assumptions

**Files:** Create `docs/reviews/m07a-revalidation.md`

- [ ] **Step 1: Gate and branch.** `grep '^Decision:' docs/gates/G2.md` shows PASS or MIDDLE, and the last `docs/gates/support.md` row isn't RED. `git checkout -b m07a-v1.1 main`.
- [ ] **Step 2: Swift API diff.** Run `grep -rhn "public " Packages/TegelKit/Sources --include=*.swift | grep -E "func |init\(|struct |enum |class |case |var |let "` and write `Assumed (master §3.3) | Shipped | Action` rows for `RenderOptions`, `RendererWebView.render`, `PDFExporter.export`, `BookmarkStore`, `LicenseManager` and `ProGate`.
- [ ] **Step 3: Renderer facts:** the markdown-it major in `Renderer/bun.lock` (texmath has no peer dependency, so 14 and 15 both work); `SANITIZE_CONFIG` and `addHooks` in `Renderer/src/sanitize.js` (plan 01); how `page.js` injects `mermaid.min.js`, including the Quick Look path (KaTeX copies it); whether same-document `#fragment` clicks scroll or are blocked; whether a failed `<img>` already becomes a placeholder.
- [ ] **Step 4: App facts:** the direct target names (assumed plan 01's `markdown`, `markdown.quicklook`, and plan 02's test target `MarkdownAppTests` in `Apps/Markdown/AppTests/`); the PDF export call site (`grep -rn "PDFExporter.export" Apps/`); the folder-window opener; the settings view; whether `PDFExporter.export` needs a visible window; `scripts/release.sh` usage (assumed `<app> <version> [--sandbox] [--yes] [--no-upload]`, versions `X.Y.Z[-bN|-rcN]`, plan 03); the appcast and DMG URL paths; `print.css` page margins (need ≥ 36 pt for the header/footer).
- [ ] **Step 5: Cross-app key regression check (Review Focus 4).** Plan 03 ships the benefit binding in 1.0.0 (D1). Paste an App 2 **sandbox** key into a Debug App 1. Expected: rejected with plan 03's `wrongProduct` message, and the sandbox portal shows no activation left on that key. If it unlocks Pro, that's a **P0** regression of plan 03's binding: stop Section A, root-cause it with `superpowers:systematic-debugging`, and ship a v1.0.x fix (approval) before A1.
- [ ] **Step 6: Library versions.** `npm view markdown-it-texmath version time license` (1.0.0, MIT); `npm view markdown-it-footnote version license` (4.0.0, MIT); `npm view katex dist-tags time license` → the newest version ≥ 14 days old.
- [ ] **Step 7: Fix and commit.** Rewrite any Interface below that the diff falsified, then:
  ```bash
  git add docs/reviews/m07a-revalidation.md docs/superpowers/plans/2026-10-27-07-post-launch-scale.md
  git commit -m "docs(m07a): re-validation" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  ```

### Task A1: KaTeX math, lazy-loaded like Mermaid

**Files:**
- Create: `Renderer/src/math.js`, `Renderer/test/math.test.js`, `Packages/TegelKit/Tests/TegelKitTests/RendererMathTests.swift`
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
- [ ] **Step 2: Run and watch it fail.** `cd Renderer && bun add -E markdown-it-texmath@1.0.0 katex@<A0 version> && bun test test/math.test.js` → FAIL: `Cannot find module '../src/math.js'`.
- [ ] **Step 3: Implement.**
  - `math.js` exports `KATEX_OPTIONS` and `renderMath`, which returns `katex.renderToString(tex, { ...KATEX_OPTIONS, displayMode })`.
  - `markdown.js`: `md.use(texmath, { engine: { renderToString: placeholder }, delimiters: 'dollars' })`. `placeholder(tex, { displayMode })` returns the span or div above. texmath wraps it in `<eq>`/`<eqn>`, which DOMPurify drops while keeping the content.
  - `page.js`, mirroring Mermaid: if `[data-math]` exists, append `katex/katex.min.css` and inject `katex/katex.min.js` once, then await it. For each placeholder: `el.replaceChildren(DOMPurify.sanitize(renderMath(window.katex, el.textContent, el.dataset.math === 'block'), { ...SANITIZE_CONFIG, RETURN_DOM_FRAGMENT: true }))`. The config returns a DocumentFragment, so never assign it to `innerHTML` (that would insert `[object DocumentFragment]`). Post `rendered` only afterwards; KaTeX errors go into `errors`.
  - `build.js` copies `katex.min.js`, `katex.min.css` and only `fonts/*.woff2`. `base.css`: `.math-src { unicode-bidi: isolate; }`.
- [ ] **Step 4: Run and watch it pass.** `bun test test/math.test.js` → 6 pass.
- [ ] **Step 5: Write the failing Swift tests** (`RendererMathTests`, `@MainActor`, one `RendererWebView` per test):
  - `testMathRendersWithMathML`: render `Euler: $e^{i\\pi}+1=0$` → `.katex` count == 1; `.katex math` count == 1; `result.errors.isEmpty`.
  - `testKatexLoadsOnlyWhenNeeded`: after `# No math`, `document.querySelector('script[src$="katex.min.js"]') == null`; after the math document it's non-null.
  - `testMathInArabicParagraphStaysLTR`: `النتيجة $a+b$ صحيحة` → `getComputedStyle(document.querySelector('.math-src')).direction == "ltr"`.
  - `testFontsReferencedByKatexCSSExist`: every `url(fonts/…woff2)` in `Resources/Renderer/katex/katex.min.css` exists in `Bundle.module`.
- [ ] **Step 6: Run and watch it fail.** `swift test --package-path Packages/TegelKit --filter RendererMathTests` → FAIL (no `katex/` in the bundle; `.katex` count 0).
- [ ] **Step 7: Regenerate and re-run.** Append the six hostile TeX lines to `Fixtures/markdown/hostile.md`. `make renderer && swift test --package-path Packages/TegelKit --filter "RendererMathTests|Hostile"` → PASS, and the existing hostile test still shows no script and no navigation.
- [ ] **Step 8: Commit.**
  ```bash
  git add Renderer Packages/TegelKit Fixtures/markdown/hostile.md <notices file> docs/design/decisions.md
  git commit -m "feat(renderer): KaTeX math, lazy-loaded, trust off, sanitised" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  ```

### Task A2: Footnotes

**Files:**
- Create: `Renderer/test/footnote.test.js`
- Modify: `Renderer/src/markdown.js`, `Renderer/src/page.js` (only if A0 found fragment clicks blocked), `Renderer/package.json`, `Renderer/bun.lock`, the notices file, `Fixtures/markdown/hostile.md`
- Test: `RendererMathTests.swift` (adds `testFootnoteLinkScrollsWithinDocument`)

**Interfaces:**
- Consumes: `renderToHTML` (§3.2).
- Produces: `markdown-it-footnote@4.0.0` markup (ids `fn<N>` and `fnref<N>`), with `dir="auto"` on every `footnote-item` `<li>`.

- [ ] **Step 1: Write the failing tests.**
```js
import { test, expect } from 'bun:test';
import { renderToHTML } from '../src/markdown.js';
test('footnotes link both ways', () => {
  const html = renderToHTML('Claim[^1].\n\n[^1]: Source.', { mode: 'window' });
  for (const s of ['href="#fn1"', 'id="fn1"', 'href="#fnref1"', 'id="fnref1"']) expect(html).toContain(s);
});
test('footnote items take the direction of their own text', () => {
  const li = renderToHTML('نص[^1].\n\n[^1]: مصدر عربي.', { mode: 'window' }).match(/<li[^>]*id="fn1"[^>]*>/)[0];
  expect(li).toContain('dir="auto"');
});
```
- [ ] **Step 2: Run and watch it fail.** `cd Renderer && bun add -E markdown-it-footnote@4.0.0 && bun test test/footnote.test.js` → FAIL (`href="#fn1"` not found).
- [ ] **Step 3: Implement.**
  - `md.use(footnote)`, and wrap `md.renderer.rules.footnote_open` so its `<li ` output gains `dir="auto" `.
  - If A0 found fragment clicks blocked, `page.js` handles `a[href^="#"]` with `preventDefault()` + `document.getElementById(decodeURIComponent(hash.slice(1)))?.scrollIntoView()`. No navigation.
  - Append to `hostile.md` a footnote whose body is `<img src=x onerror=alert(1)>`.
- [ ] **Step 4: Run and watch it pass.** `bun test test/footnote.test.js` → 2 pass.
- [ ] **Step 5: Swift scroll test.** `testFootnoteLinkScrollsWithinDocument`: render 200 paragraphs plus a footnote; `document.querySelector('a[href="#fn1"]').click()` → `document.getElementById('fn1').getBoundingClientRect().top < 50`, and the URL is unchanged apart from the hash. `make renderer && swift test --package-path Packages/TegelKit --filter "RendererMathTests|Hostile"` → PASS.
- [ ] **Step 6: Commit.** `git add Renderer Packages/TegelKit Fixtures/markdown/hostile.md <notices file>`; `git commit -m "feat(renderer): footnotes with per-item direction" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`.

### Task A3: Custom CSS (Pro), a read-only bookmarked file injected after the theme

**Files:**
- Create: `Apps/Markdown/App/CustomStylesheet.swift`, `Apps/Markdown/AppTests/CustomStylesheetTests.swift`, `Packages/TegelKit/Tests/TegelKitTests/UserCSSTests.swift`
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
- [ ] **Step 4: Watch the network guard fail when broken.** Temporarily delete the CSP `<meta>` in the built `Resources/Renderer/index.html` and run `--filter testUserCSSCannotReachNetwork` → FAIL (connections ≥ 1). Restore with `git checkout -- Packages/TegelKit/Sources/TegelKit/Resources/Renderer/index.html`.
- [ ] **Step 5: Run and watch it pass.** `make renderer && swift test --package-path Packages/TegelKit --filter UserCSSTests` → 3 pass.
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
- [ ] **Step 10: Commit.** `git add Apps/Markdown Packages/TegelKit Renderer/src/page.js`; `git commit -m "feat(app): custom CSS from a read-only bookmark, CSP-bound" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`.

### Task A4: Print header and page numbers (Pro, part of PDF export)

**Verified constraints:**
- WebKit has no page-margin boxes: in MDN browser-compat-data `css/at-rules/page.json`, `at_top-center` (and every other margin box) has Safari `version_added: false`.
- WKWebView's printing view overrides `drawPageBorderWithSize:` without calling super. It draws headers and footers only through the private UI-delegate SPI `_webViewHeaderHeight:` / `_webView:drawHeaderInRect:forPageWithTitle:URL:` (WebKit `Source/WebKit/UIProcess/mac/WKPrintingView.mm`, `UIProcess/Cocoa/UIDelegate.mm`).
- So `NSPrintInfo.AttributeKey.headerAndFooter` and `NSView.pageHeader`/`pageFooter` never reach a WKWebView print, and SPI is barred by guideline 2.5.1.
- **Decision:** stamp the exported PDF with PDFKit and Core Graphics (public APIs).

**Files:**
- Create: `Packages/TegelKit/Sources/TegelKit/PDFStamper.swift`, `Packages/TegelKit/Tests/TegelKitTests/PDFStamperTests.swift`
- Modify: the PDF export call site (A0) — a "Page numbers" toggle, `@AppStorage("TGPDFPageNumbers")`, default on; its accessory view (`DESIGN.md`); `Localizable.xcstrings`

**Interfaces:**
- Consumes: `PDFExporter.export(_:to:paper:)`; `RenderResult.headings`.
- Produces: `public enum PDFStamper { public static func stamp(pdfAt url: URL, header: String?) throws }`. The footer is always `"<n> / <N>"`, centred, Western digits. The header is centred: the first H1's text, else the file name without its extension. Typography comes from `DESIGN.md`; baselines sit 18 pt inside the media box.

- [ ] **Step 1: Write the failing tests.**
```swift
func testStampsHeaderAndPageNumbersKeepingTextSizeAndLinks() throws {
    let url = try makePDF(pages: ["Alpha", "Beta", "Gamma"], link: URL(string: "https://example.com")!)  // helper: CGContext A4 pages + PDFAnnotation(.link) on page 1
    try PDFStamper.stamp(pdfAt: url, header: "Release notes")
    let doc = try XCTUnwrap(PDFDocument(url: url))
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
func testArabicHeaderKeepsPageCount() throws { let u = try makePDF(pages: ["a", "b"]); try PDFStamper.stamp(pdfAt: u, header: "تقرير"); XCTAssertEqual(PDFDocument(url: u)?.pageCount, 2) }
func testRejectsNonPDF() throws { let u = tmp("x.pdf"); try Data("no".utf8).write(to: u); XCTAssertThrowsError(try PDFStamper.stamp(pdfAt: u, header: nil)) }
@MainActor func testExportedPDFHasPageNumbers() async throws {   // end to end with the real renderer
    let r = RendererWebView(); _ = try await r.render(try String(contentsOf: fixtureURL("gfm-kitchen-sink.md")), options: .init(mode: .print, theme: .paper, baseURL: nil))
    let u = tmp("k.pdf"); try await PDFExporter.export(r, to: u, paper: .a4); try PDFStamper.stamp(pdfAt: u, header: "Kitchen sink")
    let d = try XCTUnwrap(PDFDocument(url: u)); XCTAssertTrue(d.page(at: d.pageCount - 1)!.string!.contains("\(d.pageCount) / \(d.pageCount)"))
}
```
- [ ] **Step 2: Run and watch it fail.** `swift test --package-path Packages/TegelKit --filter PDFStamperTests` → FAIL (`cannot find 'PDFStamper' in scope`).
- [ ] **Step 3: Implement `stamp(pdfAt:header:)`.**
  - Open a `PDFDocument`; throw `CocoaError(.fileReadCorruptFile)` if it is nil or has 0 pages.
  - Create `CGContext(tempURL, mediaBox: nil, nil)`. Per page: `beginPDFPage` with that page's media box → `page.draw(with: .mediaBox, to:)` → push `NSGraphicsContext(cgContext:flipped: false)` and draw the header/footer `NSAttributedString`s → `endPDFPage`. Then `closePDF()`.
  - Re-open the temp file and add a `copy()` of every original `"Link"` annotation at the same page index. Write to a second temp file, then `FileManager.default.replaceItemAt(url, withItemAt:)`.
- [ ] **Step 4: Run and watch it pass.** Re-run Step 2's command → 4 pass.
- [ ] **Step 5: Wire it in.** Call `PDFStamper.stamp` after `PDFExporter.export` when the toggle is on. `xcodebuild build -scheme markdown -destination 'platform=macOS'` → `** BUILD SUCCEEDED **`.
- [ ] **Step 6: Commit.** `git add Packages/TegelKit Apps/Markdown`; `git commit -m "feat(pdf): header and page numbers via PDFKit (WebKit has no margin boxes)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`.

### Task A5: Shortcuts actions (App Intents)

**Verified:** `AppIntent`, `IntentFile`, `OpenIntent` and `AppShortcutsProvider` are all macOS **13.0+** (Apple documentation JSON, `developer.apple.com/documentation/appintents/{appintent,intentfile,openintent,appshortcutsprovider}`), so a 14.0 target is fine.

**Files:**
- Create: `Apps/Markdown/App/Intents/{ExportPDFIntent.swift,OpenFolderIntent.swift,TegelMarkdownShortcuts.swift}`, `Apps/Markdown/AppTests/IntentsTests.swift`
- Modify: `Apps/Markdown/App/ProGate.swift`, `Localizable.xcstrings`, `AppShortcuts.xcstrings` (EN/NL/FR/AR phrases)

**Interfaces:**
- Consumes: `TextFileLoader.load`, `RendererWebView`, `PDFExporter.export`, `PDFStamper.stamp`, the folder-window opener (A0), `PaperSize`.
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
  - `exportPDF`: write `markdown` to a temp `.md` → `TextFileLoader.load` → render in `.print` mode with the saved theme and `userCSS` → export → stamp if `pageNumbers` → return the URL.
  - `perform` calls `exportPDF(…, isPro: ProGate.isProNow())` and returns `IntentFile(fileURL:filename:type: .pdf)`. Shortcuts decides where to save, so the app writes only to its container (rule 1).
  - `OpenFolderIntent.perform` requires Pro and opens `folder.fileURL` through the folder opener. If the URL is missing or unreadable in the sandbox, it shows an `NSOpenPanel` with `directoryURL` set to it, so one click grants access.
- [ ] **Step 4: Run and watch it pass.** Re-run Step 2's command → 2 pass.
- [ ] **Step 5: Discoverability.** `make build && test -d "$(find build -name 'Tegel Markdown.app' -maxdepth 6 | head -1)/Contents/Resources/Metadata.appintents" && echo OK` → `OK`. Manual: Shortcuts.app lists both actions, and "Open Folder in Tegel Markdown" with a Folder action opens the sidebar; screenshot to `docs/qa/v1.1/shortcuts.png`.
- [ ] **Step 6: Commit.** `git add Apps/Markdown docs/qa/v1.1`; `git commit -m "feat(app): Shortcuts actions for PDF export and Open Folder" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`.

### Task A6: v1.1 QA matrix → `docs/qa/v1.1-matrix.md`

- [ ] **Step 1: Local (macOS 15, Intel, the build Mac).** `make check`, then the plan 05 matrix rows plus the new rows: math (inline, block, Arabic); footnotes (scroll, RTL); custom CSS (apply, delete the file, oversize); PDF header and numbers (A4, Letter, RTL document); both Shortcuts. Record pass/fail per row and the machine.
- [ ] **Step 2: macOS 26 arm64.** `gh workflow run ci.yml --ref m07a-v1.1 && gh run watch --exit-status` → the macOS jobs are green; link the run URL. (Needs the user's `gh auth login`.)
- [ ] **Step 3: macOS 27 arm64 on Scaleway** (M1, ≈ €2.64 for 24 h [F9]; purchase approval first). Install a notarised release candidate from `scripts/release.sh markdown 1.1.0-rc1 --no-upload`. Run the new rows plus the G0 timing for `g0-1mb.md` and a math-heavy file (< 1 s).
- [ ] **Step 4: Commit** the matrix.

### Task A7: Pipeline P, then release v1.1.0

- [ ] **Step 1: Run P for `m07a`.** `/cso` scope: KaTeX insertion and sanitisation, the `trust: false` options; user CSS (CSP, `textContent`, size cap, read-only bookmark); App Intents file input and temp files. Design review: the custom-CSS row, the export accessory, stamped pages.
- [ ] **Step 2: Merge and push** (P step 11).
- [ ] **Step 3: Release** (approval of this release). On `main`: `scripts/release.sh markdown 1.1.0` → `spctl -a -vv` shows `accepted … source=Notarized Developer ID`. `curl -s https://downloads.tegelapps.com/<appcast path from A0> | grep -c '1.1.0'` ≥ 1. A Sparkle update from 1.0.x on the build Mac shows 1.1.0 in About.
- [ ] **Step 4: Release notes.** Update the release notes and site changelog (plan 04 path) and deploy (not a first deploy, so no approval). `curl -sI https://tegelapps.com/<changelog path>` → 200.

---

## Section B: Mac App Store edition of App 1 (`m07b-mas`)

**Binding rules:**
- **Guideline 2.4.5** (developer.apple.com/app-store/review/guidelines/): (i) appropriately sandboxed; (ii) packaged with Xcode, no third-party installers; (iii) no auto-launch without consent; (iv) may not download code; (v) no root escalation; (vi) may not "present a license screen at launch, require license keys, or implement their own copy protection"; (vii) "must use the Mac App Store to distribute updates"; (viii) currently shipping OS, no deprecated tech; (ix) all localisations in one bundle.
- **Guideline 2.5.1:** "Apps may only use public APIs".

**Bundle-id decision:** keep `com.tegelapps.markdown` and `com.tegelapps.markdown.quicklook`. The App Store enforces bundle-id uniqueness through App IDs. A Developer ID app with no restricted entitlements needs no App ID or profile (Apple DTS, developer.apple.com/forums/thread/750645), so we may register ours for the MAS build. One id = one container and one Quick Look provider for `net.daringfireball.markdown`. B5 checks how the App Store treats an existing DMG copy.

### Task B0: Re-validate MAS assumptions → `docs/reviews/m07b-revalidation.md`

- [ ] **Step 1: Gate and branch.** G2 ≠ FREEZE and `m07a` is merged. `git checkout -b m07b-mas main`.
- [ ] **Step 2: SDK rule.** Record the newest "built with Xcode N" rule and its date from developer.apple.com/news/upcoming-requirements/ (today: "Xcode 26 or later", since 28 Apr 2026). If submission day needs an Xcode newer than 26.3, CI is mandatory [F2]; otherwise the build Mac may build too.
- [ ] **Step 3: Runner image.** `curl -s https://raw.githubusercontent.com/actions/runner-images/main/images/macos/macos-26-arm64-Readme.md | grep -A12 '### Xcode'`. On 27 Oct 2026 the default was 26.6 (17F113), with 26.3, 26.4.1 and 26.5 installed; `xcode-27` was a preview image [F7]. Choose the newest GA Xcode that meets Step 2, and record the full commit SHA of the `actions/checkout` v7 release. Other workflows use `@v7`; only the secret-bearing `mas.yml` pins a SHA (X26).
- [ ] **Step 4: Source split.** `grep -rlE "import (Sparkle|TegelStore)|TGPolar|SUFeedURL|checkoutURL|portalURL" Apps/Markdown/App` lists the files that move to `Apps/Markdown/App/Direct/` in B1.
- [ ] **Step 5: Human checkpoint H-M1 (Account Holder).** Create the **Apple Distribution** and **Mac Installer Distribution** certificates; register the explicit App IDs `com.tegelapps.markdown` and `com.tegelapps.markdown.quicklook`; create a Team API key "tegel-ci-mas" with role **App Manager** → `.env` keys `ASC_CI_API_KEY_ID`, `ASC_CI_API_ISSUER_ID`, `ASC_CI_API_KEY_PATH`. Check: `security find-identity -v -p codesigning | grep -c "Apple Distribution"` ≥ 1.
- [ ] **Step 6: Commit** the revalidation doc.

### Task B1: Channel split and the `MarkdownMAS` targets

**Files:**
- Create: `scripts/verify-store-build.sh`, `Apps/Markdown/App/DistributionChannel.swift`, `Apps/Markdown/MAS/{Markdown.entitlements,QuickLook.entitlements}`, `Apps/Markdown/MASTests/ChannelTests.swift`
- Move (`git mv`): the B0 Step 4 files → `Apps/Markdown/App/Direct/`
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
    sources: [{ path: Apps/Markdown/App, excludes: ["Direct/**"] }]
    dependencies: [{ package: TegelKit, product: TegelKit }, { target: MarkdownMASQuickLook }]
    info: { path: Apps/Markdown/MAS/Info.plist, properties: { LSApplicationCategoryType: public.app-category.developer-tools, ITSAppUsesNonExemptEncryption: false } }  # plus the direct target's document types and UTI imports; no SU*/TG* keys
    settings: { PRODUCT_BUNDLE_IDENTIFIER: com.tegelapps.markdown, SWIFT_ACTIVE_COMPILATION_CONDITIONS: "$(inherited) MAS UNLOCKED",
                CODE_SIGN_ENTITLEMENTS: Apps/Markdown/MAS/Markdown.entitlements, CODE_SIGN_STYLE: Automatic, ENABLE_HARDENED_RUNTIME: YES }
  MarkdownMASQuickLook:   # app-extension; sources Apps/Markdown/QuickLook; bundle id com.tegelapps.markdown.quicklook; CODE_SIGN_ENTITLEMENTS Apps/Markdown/MAS/QuickLook.entitlements
  MarkdownMASTests:       # bundle.unit-test; sources Apps/Markdown/MASTests; depends on MarkdownMAS; TEST_HOST = the MarkdownMAS app
```
  Entitlements — app: `app-sandbox`, `files.user-selected.read-write`, `files.bookmarks.app-scope`, `network.client` (WebKit in a sandbox, FB6993802 [F5]). Quick Look: `app-sandbox` and `network.client` only. Without `temporary-exception.files.absolute-path.read-only`, Quick Look shows image placeholders [F5].
- [ ] **Step 5: Implement.** `ProGate`: `#if UNLOCKED` → `isPro` is the constant `true` and `isProNow()` returns `true`. `DistributionChannel.current`: `#if MAS .mas #elseif SETAPP .setapp #else .direct`. The menu and app entry wrap the updater and licence items in `#if !UNLOCKED`.
- [ ] **Step 6: Watch it pass.**
  ```bash
  xcodegen generate && xcodebuild test -scheme MarkdownMAS -destination 'platform=macOS' -only-testing:MarkdownMASTests
  xcodebuild build -scheme MarkdownMAS -configuration Debug -destination 'platform=macOS'
  scripts/verify-store-build.sh <MarkdownMAS Debug .app path> mas
  ```
  Expected: the test passes; `** BUILD SUCCEEDED **`; `verify-store-build: PASS`. The direct scheme still passes `make check`.
- [ ] **Step 7: Commit.** `git add project.yml Apps/Markdown scripts/verify-store-build.sh`; `git commit -m "feat(mas): MarkdownMAS targets, UNLOCKED split, store-build guard" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`.

### Task B2: Quick Look image placeholder (only if A0 found none)

**Files:** Modify `Renderer/src/page.js`, `Renderer/src/css/base.css`. Test: `UserCSSTests.swift` (adds `testBrokenImageBecomesPlaceholder`).

**Interfaces:** Produces: a failed `<img>` is replaced by `<span class="img-placeholder" role="img" aria-label="<alt>"><alt></span>`.

- [ ] **Step 1: Write the failing test.** Render `![Flow diagram](file:///nonexistent/x.png)`, wait for `rendered` + 300 ms → `document.querySelector('.img-placeholder').textContent == "Flow diagram"`.
- [ ] **Step 2: Watch it fail.** `swift test --package-path Packages/TegelKit --filter testBrokenImageBecomesPlaceholder` → FAIL (null).
- [ ] **Step 3: Implement.** `page.js` adds an `error` listener per `img` that builds the span with `textContent` from `alt` (never `innerHTML`) and calls `replaceWith`.
- [ ] **Step 4: Watch it pass.** `make renderer`, then re-run Step 2's command → PASS.
- [ ] **Step 5: Commit** `Renderer` and `Packages/TegelKit` (`feat(renderer): placeholder for unreadable images`, plus the co-author line).

### Task B3: MAS build script and CI workflow, with the keychain import

**Files:** Create `scripts/mas.sh`, `scripts/ExportOptions-MAS.plist`, `.github/workflows/mas.yml`. Modify `.env.example` (adds `ASC_CI_API_KEY_ID`, `ASC_CI_API_ISSUER_ID`, `ASC_CI_API_KEY_PATH`).

**Interfaces:**
- Consumes: `scripts/verify-store-build.sh`, `APPLE_TEAM_ID`.
- Produces: `scripts/mas.sh <version> <build> [--upload]` → `build/MAS.xcarchive`, then `build/MAS-export/*.pkg` or an upload to App Store Connect.

**Verified:** local Xcode 26.3 `xcodebuild -help` lists export `method` `app-store-connect`, `destination` `export|upload`, and `-allowProvisioningUpdates` with `-authenticationKeyPath/-authenticationKeyID/-authenticationKeyIssuerID`. The keychain commands follow docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications.

- [ ] **Step 1: `ExportOptions-MAS.plist`:** `method` = `app-store-connect`; `signingStyle` = `automatic`; `teamID` = `__TEAM__` (filled by the script); `destination` = `export`; `uploadSymbols` = true; `manageAppVersionAndBuildNumber` = false.
- [ ] **Step 2: `scripts/mas.sh`** (`set -euo pipefail`):
  - `xcodegen generate`
  - `xcodebuild archive -scheme MarkdownMAS -configuration Release -archivePath build/MAS.xcarchive MARKETING_VERSION=$1 CURRENT_PROJECT_VERSION=$2 -allowProvisioningUpdates -authenticationKeyPath "$ASC_CI_API_KEY_PATH" -authenticationKeyID "$ASC_CI_API_KEY_ID" -authenticationKeyIssuerID "$ASC_CI_API_ISSUER_ID"`
  - `scripts/verify-store-build.sh "build/MAS.xcarchive/Products/Applications/Tegel Markdown.app" mas`
  - Copy the plist to `build/ExportOptions.plist`; `plutil -replace teamID -string "$APPLE_TEAM_ID"`; with `--upload`, also `plutil -replace destination -string upload`.
  - `xcodebuild -exportArchive -archivePath build/MAS.xcarchive -exportPath build/MAS-export -exportOptionsPlist build/ExportOptions.plist` plus the same auth flags.
- [ ] **Step 3: Local dry run** (only if B0 allows Xcode 26.3). `set -a; . ./.env; set +a; scripts/mas.sh 1.1.0 110`, then `pkgutil --check-signature build/MAS-export/*.pkg | grep -E "Mac Installer Distribution|3rd Party Mac Developer Installer"` → one match.
- [ ] **Step 4: Write `.github/workflows/mas.yml`.**
```yaml
name: mas
on:
  workflow_dispatch:
    inputs: { version: { required: true }, build: { required: true }, xcode: { required: true, default: "26.6" }, upload: { type: boolean, default: false } }
jobs:
  mas:
    runs-on: macos-26
    timeout-minutes: 45
    env: { APPLE_TEAM_ID: "${{ secrets.APPLE_TEAM_ID }}", ASC_CI_API_KEY_ID: "${{ secrets.ASC_CI_API_KEY_ID }}", ASC_CI_API_ISSUER_ID: "${{ secrets.ASC_CI_API_ISSUER_ID }}" }
    steps:
      - uses: actions/checkout@<full commit SHA recorded in B0>
      - run: sudo xcode-select -s "/Applications/Xcode_${{ inputs.xcode }}.app" && xcodebuild -version
      - run: brew install xcodegen
      - name: Import signing identities and API key
        env: { DIST_P12: "${{ secrets.MAS_DIST_CERT_P12_BASE64 }}", INST_P12: "${{ secrets.MAS_INSTALLER_CERT_P12_BASE64 }}", P12_PASSWORD: "${{ secrets.MAS_P12_PASSWORD }}", KEYCHAIN_PASSWORD: "${{ secrets.KEYCHAIN_PASSWORD }}", ASC_P8: "${{ secrets.ASC_CI_KEY_P8_BASE64 }}" }
        run: |
          KC="$RUNNER_TEMP/app-signing.keychain-db"
          echo "$DIST_P12" | base64 --decode > "$RUNNER_TEMP/dist.p12"; echo "$INST_P12" | base64 --decode > "$RUNNER_TEMP/inst.p12"
          security create-keychain -p "$KEYCHAIN_PASSWORD" "$KC"
          security set-keychain-settings -lut 21600 "$KC"
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KC"
          security import "$RUNNER_TEMP/dist.p12" -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k "$KC"
          security import "$RUNNER_TEMP/inst.p12" -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k "$KC"
          security set-key-partition-list -S apple-tool:,apple: -k "$KEYCHAIN_PASSWORD" "$KC"
          security list-keychain -d user -s "$KC"
          echo "$ASC_P8" | base64 --decode > "$RUNNER_TEMP/AuthKey.p8"; echo "ASC_CI_API_KEY_PATH=$RUNNER_TEMP/AuthKey.p8" >> "$GITHUB_ENV"
          rm "$RUNNER_TEMP/dist.p12" "$RUNNER_TEMP/inst.p12"
      - run: scripts/mas.sh "${{ inputs.version }}" "${{ inputs.build }}" ${{ inputs.upload && '--upload' || '' }}
      - if: always()
        run: security delete-keychain "$RUNNER_TEMP/app-signing.keychain-db" || true; rm -f "$RUNNER_TEMP/AuthKey.p8"
```
- [ ] **Step 5: Secrets (human checkpoint H-M2).** The user exports both identities from Keychain Access as `.p12` files outside the repo and runs `gh auth login`. Then `gh secret set <NAME> < <file>` for `APPLE_TEAM_ID`, `MAS_DIST_CERT_P12_BASE64`, `MAS_INSTALLER_CERT_P12_BASE64`, `MAS_P12_PASSWORD`, `KEYCHAIN_PASSWORD`, `ASC_CI_API_KEY_ID`, `ASC_CI_API_ISSUER_ID`, `ASC_CI_KEY_P8_BASE64`. Check: `gh secret list` shows all 8 names.
- [ ] **Step 6: CI dry run.** `gh workflow run mas.yml --ref m07b-mas -f version=1.1.0 -f build=110 -f xcode=<B0> -f upload=false && gh run watch --exit-status` → success; `gh run view --log | grep -c "verify-store-build: PASS"` → 1. (About 20 macOS minutes [F7].)
- [ ] **Step 7: Commit.** `git add scripts/mas.sh scripts/ExportOptions-MAS.plist .github/workflows/mas.yml .env.example`; `git commit -m "build(mas): archive/export script and macos-26 CI with a temporary keychain" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`.

### Task B4: App Store Connect record and listing

**Files:** Create `docs/mas/listing.md`, `docs/mas/screenshots/0{1..5}.png`

- [ ] **Step 1: Write `docs/mas/listing.md`.**
  - **Text fields:** Name "Tegel Markdown" (≤ 30 chars; availability is checked when the record is created); subtitle ≤ 30; promotional text ≤ 170; description ≤ 4,000, stating honestly "Quick Look previews in this edition show placeholders for local images"; keywords ≤ 100.
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

- [ ] **Step 1: Upload a build** (approval). `gh workflow run mas.yml -f version=1.1.0 -f build=111 -f xcode=<B0> -f upload=true`; wait for "Ready to Test" in TestFlight.
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

- [ ] **Step 1: Run P for `m07b`.** `/cso` scope: MAS and Quick Look entitlements; the `UNLOCKED` split (no licence bypass reaches the direct build); `mas.yml` (secrets, keychain cleanup, pinned action SHA); `mas.sh`. Design review: screenshots and the menu without licence items.
- [ ] **Step 2: Merge and push.**
- [ ] **Step 3: Submit for Review** (approval of this submission). Log rejections in `docs/mas/review-log.md`; fix → P stages 2–4 → resubmit, with approval each time.
- [ ] **Step 4: On approval.** Release manually (approval). Add "Also on the Mac App Store" and a FAQ entry ("same features; licences don't transfer between the direct and App Store editions") to the site. `curl -s https://tegelapps.com/markdown | grep -c "apps.apple.com"` ≥ 1. Later MAS updates run `mas.yml upload=true`, each with approval.

---

## Section C: bundle check, Setapp, Homebrew (`m07c-bundle-setapp`)

### Task C0: Re-validate → `docs/reviews/m07c-revalidation.md`

- [ ] **Step 1: Gate and branch.** `docs/gates/G3.md` shows APP3 or NO-NEW-APP. `git checkout -b m07c-bundle-setapp main`.
- [ ] **Step 2: What plan 06 built.** `curl -s -H "Authorization: Bearer $POLAR_ACCESS_TOKEN" "https://api.polar.sh/v1/products/?organization_id=$POLAR_ORGANIZATION_ID&limit=100" | jq '.items[] | {id,name,is_archived,prices:[.prices[].price_amount],benefits:[.benefits[]|{id,type}]}'`. Record whether a $29 product with both `license_keys` benefits exists.
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

**Files:** Create `Apps/Markdown/Setapp/Markdown.entitlements`, `Apps/Markdown/Setapp/setappPublicKey.pem` (downloaded from the developer account; it's a public key), `Apps/Markdown/App/SetappStart.swift`. Modify `project.yml`.

**Interfaces:**
- Consumes: `UNLOCKED`/`SETAPP` (B1); `verify-store-build.sh … setapp` (B1).
- Produces: targets `MarkdownSetapp` (`com.tegelapps.markdown-setapp`) and `MarkdownSetappQuickLook` (`com.tegelapps.markdown-setapp.quicklook`), following Setapp's `<appName>-setapp.<executableName>` pattern; `enum SetappStart { static func run() }` under `#if SETAPP`, called in `applicationDidFinishLaunching`.

- [ ] **Step 1: Watch the guard fail.** On the MarkdownMAS Debug build from B1: `scripts/verify-store-build.sh <path> setapp` → exit 1 with `FAIL: bundle id lacks -setapp`, `FAIL: no NSUpdateSecurityPolicy`, `FAIL: no setappPublicKey.pem`.
- [ ] **Step 2: Add the targets.**
  - `packages.Setapp: { url: https://github.com/MacPaw/Setapp-framework.git, exactVersion: <C0> }`; sources exclude `Direct/**`; `SWIFT_ACTIVE_COMPILATION_CONDITIONS: "$(inherited) SETAPP UNLOCKED"`; Developer ID signing and Hardened Runtime.
  - Info.plist adds `NSUpdateSecurityPolicy = { AllowProcesses = { MEHY5QF425 = [com.setapp.DesktopClient.SetappAgent] } }`.
  - App entitlements: the B1 MAS set plus `com.apple.security.temporary-exception.mach-lookup.global-name = [com.setapp.ProvisioningService]` (framework README). Quick Look reuses the **direct** Quick Look entitlements, since the Setapp edition is Developer ID [F5].
- [ ] **Step 3: Implement `SetappStart.run()`.** `SetappManager.shared.start(with: .default)` if C0 confirms macOS still needs it (the README's "Start" section shows it for iOS), then `SetappManager.shared.showReleaseNotesWindowIfNeeded()`. No "Rate on App Store" or store links (Review Guidelines §5.5).
- [ ] **Step 4: Watch it pass.** `xcodegen generate && xcodebuild build -scheme MarkdownSetapp -configuration Release -destination 'platform=macOS'`, then `scripts/verify-store-build.sh <path> setapp` → PASS. `nm -m <executable> | grep -c SetappManager` ≥ 1; if 0, add `OTHER_LDFLAGS: -force_load "$(BUILT_PRODUCTS_DIR)/libSetapp.a"` (docs.setapp.com/docs/setting-up-the-framework-1).
- [ ] **Step 5: Setapp test flow** (docs.setapp.com/docs/testing-your-application). Install the Setapp desktop app and sign in with the developer test member account; launch the build → it activates with no licence UI. Record the result in `docs/qa/setapp.md`.
- [ ] **Step 6: Commit.** `git add project.yml Apps/Markdown docs/qa/setapp.md`; `git commit -m "feat(setapp): MarkdownSetapp targets with the Setapp framework, no Sparkle or licensing" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`.

### Task C4: Setapp packaging and upload

**Files:** Modify `scripts/release.sh` (adds app `markdown-setapp`)

- [ ] **Step 1: Watch it fail.** `scripts/release.sh markdown-setapp 1.1.1 --no-upload` → exit 1, "unknown app".
- [ ] **Step 2: Add the `markdown-setapp` path.** Archive `MarkdownSetapp`, export `developer-id`, notarise and staple (existing functions). Then `ditto -c -k --keepParent "Tegel Markdown.app" dist-release/TegelMarkdown-setapp-<v>.zip`, with the icon PNG beside it as Setapp requires (docs.setapp.com/docs/submitting-apps-for-review). Skip the DMG, appcast and R2 steps.
- [ ] **Step 3: Watch it pass.** Re-run Step 1's command → exit 0. `unzip -l dist-release/TegelMarkdown-setapp-1.1.1.zip | grep -c "Tegel Markdown.app/Contents/Info.plist"` → 1. `plutil -extract CFBundleIdentifier raw` on the extracted app → `com.tegelapps.markdown-setapp`.
- [ ] **Step 4: Upload** (approval). Setapp developer account → Apps → Add First Version → build validation shows no blocking finding. Record the review outcome in `docs/setapp/application.md`.
- [ ] **Step 5: Commit** `scripts/release.sh`.

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

### Task C6: Pipeline P for `m07c`

- [ ] **Step 1: Run P.** `/cso` scope: the Setapp SDK, its mach-lookup exception and `NSUpdateSecurityPolicy`; no licence bypass reaching the direct build; the `release.sh` changes. Design review: the Setapp edition's UI, if C3 ran (the bundle page is plan 06's).
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
                 static func markdown(from runs: [TextRun]) -> String }
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
- **Search docs** opens a URL template in the default browser (default `https://devdocs.io/#q=%s`, editable in Settings); the app itself sends nothing.
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
- Create: `Apps/Select/App/{SelectApp.swift,TextTools.swift}`, `Apps/Select/Tests/TextToolsTests.swift`
- Modify: `project.yml` — targets `Select` and `SelectTests`; packages `KeyboardShortcuts` (`exactVersion: 3.1.0` or the D0 value), `TegelKit` (product `TegelStore`) and Sparkle; `ENABLE_APP_SANDBOX: NO`, `ENABLE_HARDENED_RUNTIME: YES`, `LSUIElement: true`, the bundle id from D1.

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
```
- [ ] **Step 2: Watch it fail.** `xcodegen generate && xcodebuild test -scheme Select -destination 'platform=macOS' -only-testing:SelectTests/TextToolsTests` → FAIL (`cannot find 'TextTools'`).
- [ ] **Step 3: Implement.**
  - `convert`: words split on whitespace, `_` and `-`; `title` capitalises each whitespace-separated word; `sentence` lowercases, then capitalises after `^|[.!?]\s+`; locale-independent `uppercased()`/`lowercased()`.
  - `counts`: `enumerateSubstrings(in:options: .byWords)`; `characters` = `count`; `lines` = the number of `\n` + 1 for non-empty text.
  - `markdown`: escapes `\ * _ [ ] ` #` in plain text; wraps bold and italic runs; emits links only for `http`, `https` and `mailto`.
- [ ] **Step 4: Watch it pass.** Re-run Step 2's command → 3 pass.
- [ ] **Step 5: Commit** `project.yml` and `Apps/Select` (`feat(select): scaffold and text tools`, plus the co-author line).

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
- [ ] **Step 5: Watch it pass.** Re-run Step 3's command → 3 pass. `make build` (Select included), then `scripts/verify-no-keylogging.sh <Select.app>` → `PASS`.
- [ ] **Step 6: Commit** `Apps/Select` and `scripts/verify-no-keylogging.sh`.

### Task D6: Onboarding, settings, licence, updates, localisation

**Files:** Create `Apps/Select/App/{OnboardingView.swift,SettingsView.swift,MenuBar.swift}`, `Apps/Select/App/Localizable.xcstrings` (EN/NL/FR/AR), `Config/Select-{Debug,Release}.xcconfig` (D16 keys for App 3's Polar product)

- [ ] **Step 1: Write the failing test.** `testOnboardingShowsWhenUntrusted`: with `OnboardingModel(isTrusted: { false })`, `MenuBarModel(onboarding:).showsOnboarding == true`; with `{ true }`, false. Then `xcodebuild test -scheme Select -destination 'platform=macOS' -only-testing:SelectTests` → FAIL (`MenuBarModel` missing).
- [ ] **Step 2: Implement.**
  - Onboarding explains in one sentence why Accessibility is needed ("to read the text you select, only when you press your shortcut"); one button calls `request()` and opens `settingsURL`.
  - Settings: the shortcut recorder, the search URL template, the licence pane (TegelStore), Sparkle "Check for Updates". The menu-bar item: Settings and Quit.
- [ ] **Step 3: Watch it pass.** `xcodebuild test -scheme Select -destination 'platform=macOS'` → all SelectTests pass.
- [ ] **Step 4: Manual QA → `docs/qa/app3.md`:** the D1 spike apps; a password field shows "Nothing selected"; revoking the permission brings onboarding back; a Sparkle update 1.0.0-b1 → b2 keeps the Accessibility permission (same Team ID and designated requirement); an Option-only shortcut is refused or warned about on macOS 15.
- [ ] **Step 5: Commit.**

### Task D7: Polar product, site page, release, launch (outward-facing)

- [ ] **Step 1: Polar.** Sandbox: product at the D1 price with a licence-key benefit (2 activations); buy it and activate in Debug. Then live (approval).
  - **BNPL check** (rule 7; plan 05 Task 2 Step 11's check, repeated because Polar or Stripe defaults can change). Open the live App 3 checkout link in Safari (Apple Pay set up) and in Chrome. Then set the billing country to Netherlands, then United States. **Do not pay.** Screenshot each payment section to `docs/reviews/m07d-polar/checkout-{safari,chrome}-{nl,us}.png`.
  - Expected: no Klarna, Afterpay/Clearpay, Affirm, "pay later" or "pay in N instalments". Cash App Pay is a wallet, not BNPL; record it if shown.
  - **If BNPL appears:** stop before any link goes public, tell the user, and ask Polar support to remove it. Lemon Squeezy is the fallback (§13 risk 7, user decision).
- [ ] **Step 2: Site.** `site/content/<slug from D1>.md`: a permission explanation, a privacy statement (what is read, and when), a silent captioned demo (rules 2 and 4). Deploy; URL → 200.
- [ ] **Step 3: Release.** `scripts/release.sh select 1.0.0` (approval) → `spctl -a -vv` shows `accepted`.
- [ ] **Step 4: Launch Tue 20 Jul** with plan 08's playbook: PH, r/macapps (≥ 30 days after our last post), Show HN, IH, and a cross-sell email to App 1/2 buyers, sent by plan 08 (it owns MailerLite) under the soft-opt-in segment rule from plan 06 Task 15. Each post and email is approved first.

### Task D8: Pipeline P for `m07d`

- [ ] **Step 1: Run P.** `/cso` scope: AX reading and the secure-field exclusion; the global monitor mask; hotkey registration; the temp file's lifetime; pasteboard writes; the non-sandboxed Hardened Runtime; Sparkle without a sandbox; TegelStore reuse; `verify-no-keylogging.sh` PASS on the release build; each claim in `docs/gates/app3-review.md`. Design review: onboarding, panel, settings, Arabic UI.
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

- [ ] **Step 1: Lease** (purchase approval: M1, 24 h, ≈ €2.64 [F9]). Install the macOS 28 beta (E0 route) and record `sw_vers`.
- [ ] **Step 2: Run the matrix.** Install the latest notarised DMGs of App 1, App 2 (and App 3 if shipped). Run every plan 05 row plus the A6 and D6 rows, and the G0 timing for `g0-1mb.md` in the window and in `qlmanage -p`. With our extension disabled (`pluginkit -e ignore -i com.tegelapps.markdown.quicklook`), record whether the system now previews `.md` itself (risk 4 evidence), then re-enable it.
- [ ] **Step 3: Record and commit.** One row per check: pass/fail, the machine (Scaleway M1, macOS 28 beta N), and a screenshot path for failures.

### Task E3: Fix loop (once per failing row)

- [ ] **Step 1: Root cause** with `superpowers:systematic-debugging`.
- [ ] **Step 2: Regression test.** Write a failing test in the owning layer (`bun test`, `swift test` or `xcodebuild test`). Watch it fail on the build Mac when the bug reproduces there; if it only reproduces on 28, record that its failure was observed on Scaleway.
- [ ] **Step 3: Minimal fix;** the test passes.
- [ ] **Step 4: Commit** `fix(<area>): <row> on macOS 28`, plus the co-author line.

### Task E4: Pipeline P, release by Tue 31 Aug 2027

- [ ] **Step 1: Run P for `m07e`.** `/cso` scope: whatever the fixes touched. Design review if any UI changed.
- [ ] **Step 2: Merge, push, release.** `scripts/release.sh markdown <v>` (and `data`, `select`); the MAS update via `mas.yml upload=true`; the Setapp build via C4 — each with approval.
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
- Modify: `Packages/TegelKit/Sources/TegelStore/*` (`PolarClient`, `LicenseManager`, `PolarConfig`, `StoredLicense`; file names from F0); `Config/{Debug,Release}.xcconfig` and the sandbox xcconfig: rename `TG_POLAR_BENEFIT_ID_<APP>` → `TG_POLAR_BENEFIT_IDS_<APP>` for every app target, and add `TG_POLAR_V2_BENEFIT_IDS_MARKDOWN` (space-separated, X29); `project.yml` (Info.plist `TGPolarBenefitID` → `TGPolarBenefitIDs = $(TG_POLAR_BENEFIT_IDS_<APP>)` on every app target, plus `TGPolarV2BenefitIDs = $(TG_POLAR_V2_BENEFIT_IDS_MARKDOWN)` on `markdown`)
- Test: `Packages/TegelKit/Tests/TegelStoreTests/BenefitTests.swift`

**Interfaces (contract changes, listed at the end):**
- `public struct ValidatedLicense: Sendable, Equatable { public let expiresAt: Date?; public let benefitID: String }`
- `PolarClient.validate(key:activationID:) async throws -> ValidatedLicense`. It sends the stored licence's `benefitID` as `benefit_id`; a legacy item (nil, written before F1 by a build that accepted only the v1 benefit) sends the v1 id.
- `StoredLicense` gains `public var benefitID: String?` (decoded with `decodeIfPresent`, so v1.x Keychain items read as nil and fill on the next 200).
- `PolarConfig.benefitID: String` becomes `public let benefitIDs: Set<String>`, plus `public let v2BenefitIDs: Set<String>`. `LicenseManager` gains `public var hasV2: Bool`. `PolarError.wrongProduct` and its copy are plan 03's, unchanged.

- [ ] **Step 1: Write the failing tests** (reusing plan 03's URLProtocol stub):
  - `testValidateReturnsBenefitID`: a stubbed 200 `{"benefit_id":"b-v2","expires_at":null,…}` → `ValidatedLicense(expiresAt: nil, benefitID: "b-v2")`.
  - `testActivateAcceptsAnyBenefitInTheSets`: activate → `{"id":"act1","license_key":{"benefit_id":"b-v2"}}` with `"b-v2"` ∈ `v2BenefitIDs` → returns `"act1"`, no deactivate.
  - `testActivateRejectsBenefitOutsideBothSets`: `{"id":"act1","license_key":{"benefit_id":"b-data"}}` → throws `.wrongProduct`; the stub recorded `deactivate` with `activation_id == "act1"`; `keychain.load() == nil` (plan 03's behaviour, now against the sets).
  - `testV1KeyIsProNotV2`: benefit `"b-v1"` ∈ `benefitIDs` → `isPro`, `!hasV2`.
  - `testV2KeyIsProAndV2`: benefit `"b-v2"` ∈ `v2BenefitIDs` → both true.
  - `testLapsedV2KeyHasNoV2`: `lastValidatedAt` 31 days ago, network down → `hasV2 == false`.
  - `testLegacyStoredLicenseDecodes`: JSON without `benefitID` decodes with `benefitID == nil`; `isPro` unchanged within grace.
  - `test404StillFallsIntoGrace`: the [F3d] invariant is unchanged.
- [ ] **Step 2: Watch it fail.** `swift test --package-path Packages/TegelKit --filter BenefitTests` → FAIL to compile (`ValidatedLicense` undefined).
- [ ] **Step 3: Implement.**
  - Decode `benefit_id` from validate.
  - `activate`: plan 03's check against `license_key.benefit_id`, widened to `benefitIDs ∪ v2BenefitIDs`; on a miss it still deactivates and throws `.wrongProduct`.
  - `refresh` stores `benefitID` on each 200. `hasV2`: `state` is `.pro(l)` with `l.benefitID ∈ v2BenefitIDs`. `PolarConfig.fromInfoPlist` splits `TGPolarBenefitIDs` and `TGPolarV2BenefitIDs` on spaces.
- [ ] **Step 4: Watch it pass.** `swift test --package-path Packages/TegelKit` → all pass, including plan 03's binding and grace tests. `xcodegen generate && make build`, then `/usr/libexec/PlistBuddy -c 'Print TGPolarBenefitIDs'` on each built app → its own benefit id(s), never empty.
- [ ] **Step 5: Commit.** `git add Packages/TegelKit Config project.yml`; `git commit -m "feat(store): benefit-id sets for v2 entitlement" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`.

### Task F2: The `hasV2` seam and a v1.x that accepts v2 keys

**Files:** Modify `Apps/Markdown/App/ProGate.swift` (adds `EnvironmentValues.hasV2: Bool`; true under `UNLOCKED`) and `Config/Release.xcconfig` (adds the v2 benefit id to `TG_POLAR_BENEFIT_IDS_MARKDOWN`)

- [ ] **Step 1: Write the failing test.** `MarkdownAppTests/ProGateTests.testHasV2DefaultsFalseForV1Key` with F1's `LicenseManager` stub; `xcodebuild test -scheme markdown -destination 'platform=macOS' -only-testing:MarkdownAppTests/ProGateTests` → FAIL (no member `hasV2`).
- [ ] **Step 2: Implement the seam;** the test passes.
- [ ] **Step 3: Ship and commit.** Ship the last v1.x (`release.sh`, approval) with the v2 benefit in `TG_POLAR_BENEFIT_IDS_MARKDOWN` **before** v2 goes on sale, so v2 buyers on older systems still get v1 Pro.

### Task F3: Upgrade codes for v1 owners

**Files:** Create `scripts/v2/upgrade-codes.js`, `scripts/v2/upgrade-codes.test.js`

**Interfaces:**
- `planDiscounts(orders, { v2ProductId: string, amountCents: number, existingCodes: Set<string> }) -> Array<{ customerId, email, code, body }>`, where `body = { name, type: 'fixed', amounts: { usd: amountCents }, duration: 'once', code, max_redemptions: 1, products: [v2ProductId] }`.
- CLI `bun scripts/v2/upgrade-codes.js --v2-product <id> --amount <cents> [--apply]` (dry run by default).

- [ ] **Step 1: Write the failing tests.** Three v1 orders from two customers (one a bundle order) → 2 plans. Codes are unique and match `^[A-HJ-NP-Z2-9]{10}$`. Each `body.products` equals `[v2ProductId]` and `max_redemptions` is 1. A customer whose name already appears in `existingCodes` is skipped (idempotent re-run). Refunded orders are excluded.
- [ ] **Step 2: Watch it fail.** `bun test scripts/v2` → FAIL (module missing).
- [ ] **Step 3: Implement.** Codes come from `crypto.getRandomValues`. `--apply` calls `POST /v1/discounts/` and writes `local-docs/v2/codes.csv` (gitignored; it holds emails).
- [ ] **Step 4: Watch it pass, then a sandbox run.** `bun test scripts/v2` → PASS. A sandbox `--apply` against a sandbox v2 product: one code checks out at the upgrade price, and a second use is refused.
- [ ] **Step 5: Live.** The live run (approval of the live discounts) and the owner email through plan 08's MailerLite buyer groups (approval), stating the v2 price, the upgrade price, and that v1 keeps working.
- [ ] **Step 6: Commit** `scripts/v2`.

### Task F4: Pipeline P for `m07f`

- [ ] **Step 1: Run P.** `/cso` scope: the licence state machine (no lockout on 404/5xx; `wrongProduct` frees the activation); Keychain migration; Info.plist benefit ids; the discount script's token use and keeping its email CSV out of git. Design review: the upgrade UI copy.
- [ ] **Step 2: Merge and push.**

---

## Contract change requests

| # | Change | Reason | Section |
|---|---|---|---|
| 1 | §3.2: `renderToHTML` also emits math placeholders (`.math-src`, `data-math`, `dir="ltr"`) and footnotes (`fn<N>`/`fnref<N>`, `<li dir="auto">`). `window.tegel.render` lazy-loads `katex/katex.min.js` like Mermaid and sanitises KaTeX output with `SANITIZE_CONFIG` from `Renderer/src/sanitize.js` (plan 01), inserted with `replaceChildren` | v1.1 math and footnotes (BUSINESS-PLAN §6.1) | A1, A2 |
| 2 | §3.2/§3.3: `RenderOptions.userCSS: String?` and JS `opts.userCSS`, injected as the last `<style id="tegel-user-css">` under the unchanged CSP | Custom CSS | A3 |
| 3 | App seam: `ProGate.isProNow()` (static, `@MainActor`) beside `EnvironmentValues.isPro`, plus `EnvironmentValues.hasV2` | App Intents run outside the SwiftUI environment; v2 gating | A5, F2 |
| 4 | §3.1 layout: `Apps/Markdown/App/Direct/`, `Apps/Markdown/{MAS,MASTests,Setapp}/`, `Apps/Select/`, `scripts/gates/products.json`, `scripts/v2/`, `scripts/{mas.sh,verify-store-build.sh,verify-no-keylogging.sh}`, `.github/workflows/mas.yml`. Gate counting extends plan 05's `polar_sales.py` (no second counter, no Makefile change; X22) | Store editions, App 3, gate tooling | G0, G1, B1, B3, C3, D3 |
| 5 | D5 entitlements gain two variants: MAS (no temporary exceptions; the Quick Look extension loses the absolute-path read-only exception) and Setapp (adds `mach-lookup` `com.setapp.ProvisioningService`) | Guideline 2.4.5; Setapp README | B1, C3 |
| 6 | Swift compilation conditions `UNLOCKED`, `MAS`, `SETAPP` | Drop TegelStore and Sparkle at compile time | B1, C3 |
| 7 | TegelStore: `ValidatedLicense`; `validate` returns it; `StoredLicense.benefitID: String?`; plan 03's `PolarConfig.benefitID` generalised to `benefitIDs`/`v2BenefitIDs`; `LicenseManager.hasV2`. D16: `TGPolarBenefitID` → `TGPolarBenefitIDs`, plus `TGPolarV2BenefitIDs`; build settings `TG_POLAR_BENEFIT_IDS_<APP>`, `TG_POLAR_V2_BENEFIT_IDS_MARKDOWN`. `PolarError.wrongProduct` already exists (plan 03) | v2 (wrong-app keys are already rejected by plan 03) | F1 |
| 8 | Global constraint "No Accessibility…" scoped to Apps 1–2. App 3 may use Accessibility only: no event tap, no Input Monitoring, no key monitor. **NO-GO until the user signs it off explicitly** (D2) | BUSINESS-PLAN §7.2, §14 backlog #1 | D |
| 9 | Product rule 1 ("No telemetry") gains a Setapp-edition exception, **only if the user signs C2**; NO-GO until then | The Setapp framework collects usage, performance and device data | C2 |
| 10 | `scripts/release.sh` accepts the apps `markdown-setapp` (zip; no DMG, appcast or R2) and `select` | Setapp packaging; App 3 | C4, D7 |

## Open questions only the user can answer

1. **Setapp:** accept the Setapp edition's usage reporting as a disclosed exception to rule 1, or skip Setapp? (C2; default no.)
2. **MAS price:** $19.00 in the USD storefront, and is Apple's auto-generated euro price acceptable? (B4)
3. **v2 prices:** the v2 list price and the v1-owner upgrade price. (F0)
4. **App 3:** name, price ($15?), trigger, and whether a clipboard fallback is acceptable (D1); and the Accessibility-API exception (CR-8, D2; default NO-GO until you sign it off).
5. **G2 counting:** do bundle sales count as "App 1 sales"? (G2; the plan counts them and flags it when it decides the outcome.)
