# Milestone 08: Growth engine, implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Tegel's apps find their buyers, from W1 (Tue 27 Oct 2026) to G4 (Fri 29 Oct 2027), and hit the master §12 stretch targets without breaking a halal guardrail.

**Architecture:** Mostly research, copy and operating routines. Five small pieces of code, each built because a step repeats or a number has to be counted:
- `site/functions/api/waitlist.js`: a same-origin Cloudflare Pages Function that turns a plain HTML form POST into a MailerLite double-opt-in subscriber. No third-party script on any page.
- `site/tools/rtl-markdown-check/`: a free, client-side RTL Markdown checker that reuses `Renderer/src`. It has no PDF export and no network access.
- `scripts/kpi.py`: the weekly funnel report. It imports plan 05's `scripts/polar_sales.py` instead of re-implementing Polar paging.
- `scripts/sync_buyers.py`: a daily, idempotent copy of new buyers into a MailerLite group, under the soft opt-in rules.
- Two `TegelStore` additions for the in-app upgrade moments. The Quick Look guide is plan 02's Welcome window, built on plan 02's `TegelKit.QuickLookSetup` (X11); this plan verifies its deep link and reviews its copy.

Everything else lives in files under `docs/growth/`, and every outward-facing action is its own step marked 🔒.

**Tech stack:**
- bun (`bun test`) for the site function and the tool.
- python3 stdlib (`urllib`, `csv`, `unittest`) for the scripts, the same as plan 05.
- Swift 6 / Swift Testing in `Packages/TegelKit`.
- MailerLite (free plan), Polar API, Cloudflare GraphQL Analytics, Google Search Console CSV export, ffmpeg.

**Spec:** `BUSINESS-PLAN.md` §2–§5, §8, §9, §12–§14. **Contract:** `docs/superpowers/plans/2026-10-27-00-master-roadmap.md` (§3 names, §4–§7, D6, D7, D9, D15, §12). **Rules:** `CLAUDE.md`. **Siblings:** plan 05 (`2026-10-27-05-release-readiness-launch.md`) owns the launch kit, launch-day runbook, support, the price change and G1. This plan cites plan 05's task numbers and does not repeat them. Plan 04 (`2026-10-27-04-site-seo.md`) owns the site build, the SEO landing pages, the legal pages and the W8–W20 article calendar. Plans 02/03 own the ProGate seam, the Pro window (`ProUpsellView` in the `pro` window, never a sheet), the Welcome window with `QuickLookSetup`, and the licence UI. This plan owns MailerLite (account from W2) and every send to the waitlist and buyer groups, including App 2's cross-sell; plan 06 supplies that email's copy and segment rule. Plan 06 owns App 2 and plan 07 owns post-launch scale. Plan 04 was not yet written when this plan was; every reference to it names a scope, not a task number.

**Branches:**
- Code goes on `m08-<topic>` (`m08-kpi`, `m08-waitlist`, `m08-rtl-tool`, `m08-onboarding`, `m08-upsell`, `m08-lifecycle`).
- Each code branch is merged only after Task 23's pipeline (D14).
- Docs-only tasks commit straight to `main`, following plan 05's Part B precedent.

## Global constraints

- **Halal guardrails.** Every tactic cites a row of master §12's halal table. The rows are numbered top to bottom:
  - **HR1:** SEO, AI search, free tools and fair, dated, sourced comparisons, *not* paid ads of any kind (including paid newsletter slots, "featured" directory listings and paid priority queues).
  - **HR2:** launch posts, disclosed community answers and list/directory submissions, *not* astroturfing, sock puppets or undisclosed self-promotion.
  - **HR3:** a dated introductory price, a real bundle price and an honest upgrade price, *not* fake "was" prices, resetting countdowns or fake scarcity.
  - **HR4:** asking for reviews and testimonials with no reward, *not* incentivised or fabricated reviews.
  - **HR5:** a disclosed affiliate or referral commission, *not* giveaways by draw, "spin to win" or raffles.
  - **HR6:** silent captioned demos and text/diagram visuals, *not* music, jingles, faces, figures, animals or mascots.
  - **HR7:** an email waitlist with consent, and buyer cross-sell under soft opt-in with opt-out, *not* bought lists, mail without consent, or inburgering/immigration framing.
  - **HR8:** neutral seasonal timing, *not* Christmas, holiday or other-religion theming. This includes Black Friday (27 Nov), Cyber Monday (30 Nov), Nowruz and Hanukkah tie-ins.
  - **HR9:** Arabic/RTL as a language feature, *not* Islamic-themed marketing. That means no Ramadan or Eid tie-ins, and no Qur'an or hadith as sample text.
- **Product rules 1–9 (CLAUDE.md)** bind all copy, screenshots and media.
- **Price wording.** Before 15 Dec, the wording is verbatim: `Introductory price $14 until Mon 14 Dec 2026 23:59 CET. From 15 Dec: $19.` (plan 05 Global Constraints). The apps never show a price (plan 05 contract change request 5).
- **Outward-facing actions need approval:** every post, email, submission, reply, account creation and DNS change on a live domain (CLAUDE.md). Approval covers the one action shown. Each 🔒 step records `Approved: <date>, user`.
- **Email law (NL).** Primary source: Telecommunicatiewet art. 11.7, the version in force from 15-08-2026, read at wetten.overheid.nl/BWBR0009950/2026-08-15 on 27 Oct 2026.
  - *Lid 1:* commercial email needs prior consent the sender "kan aantonen" (can prove). Double opt-in is the proof.
  - *Lid 4:* customers may be emailed about "eigen gelijksoortige producten of diensten" if they were offered a free, easy objection "op het ogenblik dat zij worden verzameld" and "bij elke verzonden boodschap".
  - *Lid 7:* every message states "de werkelijke identiteit" of the sender and "een geldig postadres of nummer" for opt-out requests.
- **Budget:** €0 of new cash. MailerLite Free covers 250 subscribers, 2,500 emails/month and 3 active automations of 5 steps each (mailerlite.com/pricing, read 27 Oct 2026). Any spend is a purchase that needs approval.
- **Secrets:** refer to them by `.env` key name only. New keys:
  - `MAILERLITE_API_TOKEN`, `MAILERLITE_GROUP_WAITLIST`, `MAILERLITE_GROUP_BUYERS_MARKDOWN`, `MAILERLITE_GROUP_BUYERS_DATA`;
  - `CLOUDFLARE_ANALYTICS_TOKEN` (Account Analytics Read + Zone Analytics Read only), `CLOUDFLARE_ZONE_ID`.
- **Evidence honesty:** every number in `docs/growth/` names its source and date. Counts that include bots or updates say so.
- **Owners:** **C** = Claude, **U** = the user.
- **Commits:** "+ trailer" means the message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Every commit stages explicit paths (`git add <paths>`), never `-A`.

## Review focus

1. **Subscription bombing through the waitlist.** A script posts strangers' addresses, and each one gets a confirmation mail. Expected:
   - a foreign `Origin` gets 403;
   - a filled honeypot sends nothing;
   - more than 5 POSTs in 10 s from one IP get 429 (the Cloudflare Free rate-limiting rule: 1 rule, counted by IP, 10 s period, path matching, per developers.cloudflare.com/waf/rate-limiting-rules).

   *(Task 7 tests; Task 8 Step 6.)*
2. **Opt-out leakage.** A buyer who ticked `no_marketing`, was refunded, or unsubscribed still gets a lifecycle email. Expected: never.
   - The sync skips `no_marketing: true`.
   - The sync unassigns refunded buyers.
   - The sync never sends `resubscribe: true`. MailerLite: unsubscribed subscribers "can only be reactivated through the app, a form, or a landing page" (developers.mailerlite.com/docs/subscribers).

   *(Task 14 tests.)*
3. **Attribution miscount.** Refunded, $0, other-product or ref-less orders inflate a placement. Expected: they are counted exactly as plan 05's `count_sales` counts them, and ref-less orders fall under `none`. *(Task 4 tests.)*
4. **Nagging.** The upsell shows on launch, to Pro users, or more than once per feature per session. Expected:
   - it shows only in response to the user invoking a Pro action;
   - the page preview shows once per feature per session;
   - never when `isPro`.

   *(Task 12 tests + Step 7 manual check.)*
5. **The free tool leaks data or gives Pro away.** Expected:
   - pasted `Fixtures/markdown/hostile.md` runs no script and makes no request (plan 04's `/tools/*` CSP has `connect-src 'none'`);
   - printing the page shows only a one-line note, never the rendered document.

   *(Task 9 Steps 7–8.)*

---

## Scoreboard (what "working" means; the weekly report checks each row)

| Area | Metric | Target | By | Source |
|---|---|---|---|---|
| Waitlist | confirmed subscribers in `waitlist` | ≥ 150 (central ≈ 60, see Task 10) | Mon 7 Dec | MailerLite API |
| Launch | App 1 paid sales 8 Dec–7 Jan | ≥ 47 (G1 passes at 30) | Thu 7 Jan | `polar_sales.py` |
| In-app | share of sales with an `app-*` ref | ≥ 30% | Thu 7 Jan | `kpi.py` by-ref |
| Free tool | GSC impressions on the tool page / 30 d | ≥ 500 | Mon 8 Mar | GSC CSV |
| SEO | GSC impressions / 30 d | ≥ 10,000 | Mon 8 Mar (G2) | GSC CSV |
| AI search | prompts where Tegel is cited at least once in n runs | ≥ 2 of 6 by G2; ≥ 4 of 6 by G4 | 8 Mar / 29 Oct 2027 | `docs/growth/ai-visibility.md` |
| Directories | accepted listings | ≥ 6 | Mon 8 Mar | `docs/growth/directories.md` |
| Reviews | public reviews (all venues) | ≥ 10 by G2; ≥ 25 by G3 (Setapp precondition, plan 07) | 8 Mar / 30 Apr | `docs/growth/reviews.md` |
| Revenue | est. net / month, both apps | ≥ €760 (G3); ≥ €1,450 (G4) | 30 Apr / 29 Oct 2027 | `kpi.py` |
| Always | visit → sale; refund rate | ≥ 1%; ≤ 5% | rolling 30 d | `kpi.py` |

## File map

| Path | Task | Responsibility |
|---|---|---|
| `docs/growth/halal-checklist.md` | 1 | Gate every outward artefact |
| `docs/growth/voice-of-customer.md` | 2 | Buyer quotes with links |
| `docs/growth/positioning.md` | 3, 21 | ICP, JTBD, promise, proof, objections, per-channel messages |
| `scripts/kpi.py`, `scripts/test_kpi.py`, `docs/growth/kpi/<ISO-week>.md`, `docs/growth/kpi/gsc/` | 4 | Weekly funnel report |
| `docs/growth/experiments.md` | 5 | Ref ids, review ritual, triggers, ICE backlog, pricing stance |
| `site/functions/api/waitlist.js`, `site/functions/api/waitlist.test.js` | 7 | Form POST → MailerLite |
| `site/templates/partials/waitlist-form.html`, `site/content/{en,ar}/waitlist/*.md` | 8 | Form markup and result pages |
| `docs/growth/email-copy.md` | 8, 14, 15, 21 | Every email, with approval lines |
| `site/tools/rtl-markdown-check/{analyze.js,analyze.test.js,main.js,tool.html}`, `site/content/{en,ar}/tools/rtl-markdown-check.md` | 9 | Free tool |
| `docs/growth/evidence/ql-deeplink-*.png`, `docs/growth/onboarding-copy.md` | 11 | Deep-link evidence and copy review for plan 02's Welcome window (plan 02 Task 15) |
| `Packages/TegelKit/Sources/TegelStore/{UpsellPolicy,CheckoutLink}.swift`, `…/Tests/TegelStoreTests/{UpsellPolicyTests,CheckoutLinkTests}.swift`, plan 02's `ProUpsellView`, the `pro` window and its call sites | 12 | Upgrade moments + checkout refs |
| `site/static/llms.txt`, `docs/growth/answers.md`, `docs/growth/ai-visibility.md` | 13 | AI-search layer |
| `scripts/sync_buyers.py`, `scripts/test_sync_buyers.py` | 14 | Buyers → MailerLite |
| `docs/growth/rtl-benchmark/`, `site/content/en/research/rtl-markdown-rendering-test.md` | 16 | Citation-worthy test |
| `docs/growth/directories.md` | 17 | Dated submission list |
| `docs/growth/reviews.md` | 18 | Reviews, replies, consented quotes |
| `docs/growth/distribution.md` | 19 | Per-article checklist + log + community rules |
| `docs/growth/partners.md` | 20 | Partner and RTL-language outreach |
| `docs/reviews/m08.md` | 23 | Pipeline results |

**Copy lint.** It extends plan 05's lint and is defined in Task 1. Every 🔒 request runs it first.

---

# Part 0: foundations (W1–W2)

### Task 1: Halal checklist (C; Tue 27 – Wed 28 Oct)

**Files:** Create `docs/growth/halal-checklist.md`.

- [ ] **Step 1: Write the checklist.** One checkbox per item; an artefact ships only when every box is ticked or marked `n/a`.
  1. **Imagery (rule 3, HR6):** only text, code, diagrams and the geometric tile. No faces, avatars, figures, animals, mascots, Delft figurative tiles or stock illustrations.
  2. **Audio (rule 4, HR6):** none. For every video/GIF, `ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 <file>` prints nothing.
  3. **Sample text (rule 3, HR9):** the Arabic/Hebrew/Persian/Urdu text comes from `Fixtures/markdown/` or is neutral technical prose. No Qur'an, hadith or religious phrases.
  4. **Theming (rule 5, HR8, HR9):** no Christmas, holiday, Black Friday/Cyber Monday, Ramadan, Eid, Nowruz or Hanukkah tie-in, and no "seasonal sale".
  5. **Price (rule 6, HR3):**
     - only the dated intro wording or the current real price;
     - no "was", struck-through or "from $X" reference price, countdown, "only N left" or "ends soon";
     - the licence limits (2 Macs, one-time, 14-day refund) are stated wherever a price is.
  6. **No riba (rule 7):** no BNPL mention or link.
  7. **No ads (rule 8, HR1):** no paid placement, sponsored slot, paid "featured" listing or paid boost.
  8. **Disclosure (HR2):** every community post, answer or comment by the studio says `I make Tegel Markdown` (or the Arabic/Hebrew/Persian equivalent). No second account, no asking others to post, upvote or review.
  9. **Reviews (HR4):** the review ask names no reward and isn't sent selectively. It goes to every eligible buyer, critics included. Quotes carry the person's written consent and the attribution they chose.
  10. **Email (HR7, Tw 11.7):**
      - recipients are confirmed waitlist members (lid 1) or buyers who didn't object (lid 4);
      - an unsubscribe link plus the identity and postal address/number (lid 7) are present;
      - no bought or scraped addresses;
      - no inburgering or immigration framing.
  11. **Excluded categories (rule 9):** nothing positions the apps for those uses.
  12. **Design (CLAUDE.md design standard):** none of the banned slop patterns or words (Supercharge / Unleash / Seamless / Effortless).
  13. **Facts:** every comparison claim about another product is dated and linked to its source (HR1).
- [ ] **Step 2: Add the copy lint** to the file, so it can be run on any text file:

```bash
lint() { grep -niE 'was \$|~~\$|black friday|cyber monday|christmas|xmas|holiday|santa|ramadan|eid |nowruz|hanukkah|limited time|only [0-9]+ left|spots left|hurry|last chance|ends soon|giveaway|raffle|spin to win|countdown|sale ends|% off|supercharge|unleash|seamless|effortless|pay later|klarna|afterpay' "$@" && echo "COPY-LINT: FIX" || echo "COPY-LINT: clean"; }
```

  The lint covers English only. NL, FR and AR copy goes to **manual review**: the user's reviewer for that language (U-10) reads it against this checklist before its 🔒 request, and the request records `Reviewed (<lang>): <date>, <reviewer>`.
- [ ] **Step 3: Check the lint.** `printf 'Black Friday deal\n' > /tmp/l.txt && lint /tmp/l.txt` → `COPY-LINT: FIX`; `printf 'Read Markdown on your Mac.\n' > /tmp/l.txt && lint /tmp/l.txt` → `COPY-LINT: clean`.
- [ ] **Step 4: Commit.** `git add docs/growth/halal-checklist.md`, then `git commit -m "docs(growth): halal checklist and copy lint for outward artefacts" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`.

### Task 2: Voice-of-customer research (C; Wed 28 Oct – Fri 6 Nov)

**Files:** Create `docs/growth/voice-of-customer.md`.

**Method:** customer-research Mode 2. Each entry records:
- source, URL, date, the verbatim quote (never paraphrased), context;
- sentiment, with a tag from `pain|trigger|outcome|alternative|language`;
- profile signals.

**Tools:**
- Scriptable APIs first.
- The Playwright MCP browser only when no other session is using it. Ask first: it is shared.
- Reddit returns 403 to scripts. Reddit threads are read by U in a logged-in browser and pasted in, or read through a working Redlib mirror.

- [ ] **Step 1: GitHub issues.** Query: `gh api -X GET search/issues -f q='repo:<r> <terms>' -f per_page=50 --jq '.items[]|[.html_url,.created_at,.title]|@tsv'`, then read each hit's body and comments.
  - **Repos and terms:**
    - `sbarex/QLMarkdown` (`rtl`, `arabic`, `hebrew`, `sequoia`, `pdf`, `mermaid`);
    - `MacDownApp/macdown` (`rtl`, `arabic`, `pdf`);
    - `MarkEdit-app/MarkEdit` (`rtl`, `bidi`, `preview`);
    - `esm7/obsidian-rtl` (all open issues);
    - `whomwah/qlstephen` (`sequoia`, `15`).
  - **Check step:** `gh auth status` exits 0 (master A1). Without it, use `curl https://api.github.com/search/issues?q=…`, which allows 10 requests/min.
  - **Expected:** ≥ 20 quotes.
- [ ] **Step 2: Hacker News** via Algolia: `curl -s 'https://hn.algolia.com/api/v1/search?query=<q>&tags=comment&hitsPerPage=50'` for `markdown viewer mac`, `quick look markdown`, `markdown rtl`, `claude code plan files`, `mermaid preview mac`. Expected: ≥ 10 quotes.
- [ ] **Step 3: Stack Overflow / Super User / Ask Different** via `curl -s 'https://api.stackexchange.com/2.3/search/advanced?order=desc&sort=votes&q=<q>&site=<site>&filter=withbody'` (gzip, `--compressed`), with sites `stackoverflow`, `superuser`, `apple`, and queries `quick look markdown`, `markdown right-to-left`, `markdown pdf arabic`. Expected: ≥ 10 quotes.
- [ ] **Step 4: Reddit** (U, or a Redlib mirror): r/macapps, r/ClaudeAI, r/ObsidianMD, r/Markdown. Searches: "markdown viewer", "quick look markdown", "RTL", "plan.md". Expected: ≥ 10 quotes, or `UNVERIFIED: no access` recorded.
- [ ] **Step 5: RTL communities:**
  - Hsoub I/O (`io.hsoub.com` search `ماركداون` / `markdown`);
  - Virgool (`virgool.io` search `مارک‌داون راست‌چین`);
  - the Obsidian forum (`forum.obsidian.md/search?q=rtl`);
  - VS Code Marketplace reviews of extensions found by searching `rtl markdown`.

  Expected: ≥ 10 quotes in Arabic, Persian or Hebrew, each with an English gloss.
- [ ] **Step 6: Synthesise** at the top of the file. Use the customer-research template: top themes ranked by frequency × intensity, the exact buyer phrases (≥ 15), the alternatives buyers name, and triggers ("after upgrading to Sequoia", "my agent wrote 40 md files").
  - Expected: `grep -c '^| ' docs/growth/voice-of-customer.md` ≥ 60, from ≥ 6 source types; ≥ 10 RTL quotes and ≥ 10 about agent-written files.
- [ ] **Step 7: Commit** (`docs(growth): voice-of-customer quotes with sources` + trailer).

### Task 3: Positioning (C drafts, U approves; v0 Fri 30 Oct, v1 Mon 9 Nov)

**Files:** Create `docs/growth/positioning.md`.

- [ ] **Step 1: v0 from the business plan** (Fri 30 Oct, so plan 04's W2 pages aren't blocked). Hypotheses to test against Task 2:
  - **ICP A:** Mac developers using Claude Code/Codex/Cursor who read `.md` plans and specs all day (BUSINESS-PLAN §2).
  - **ICP B:** people writing Arabic/Hebrew/Persian/Urdu Markdown who need it to display and print correctly (§2, §4 gap 1).
  - **JTBD:**
    1. "When my agent leaves plans in the repo, I want to read them properly without opening an editor."
    2. "When I press Space on a .md file, I want to see the document, not raw text."
    3. "When I hand in an Arabic document, I want a paginated PDF that reads right-to-left."
  - **One-line promise (v0):** `Press Space to read any Markdown file on your Mac: diagrams, right-to-left text and all.`
  - **3 proof points** (each with its evidence):
    1. The free Quick Look extension works on macOS 15+, where `.qlgenerator` plugins stopped working [BUSINESS-PLAN S²⁸].
    2. Paginated A4/Letter PDF that keeps RTL correct. MacMD's PDF "flows as one continuous page" [V³⁹].
    3. Read-only, no telemetry, one-time licence for 2 Macs.
  - **Objections and answers** (≥ 8):
    - "QLMarkdown is free": it is, and it covers Quick Look only; Tegel's Quick Look is free too, and Pro adds folders and PDF.
    - "VS Code previews Markdown": it does, inside an editor.
    - Then: "Why pay?", "Is it another subscription?", "Does it phone home?", "Will it break on macOS 27?", "Can it edit?" (no, by design), and "What if I switch Macs?" (portal deactivation).
  - **Message hierarchy per channel:** a table with rows site hero, RTL landing, PH tagline, r/macapps, Show HN, Arabic communities, email, in-app Pro window, and columns lead message, proof used, CTA.
- [ ] **Step 2: v1 from the research** (Mon 9 Nov). Rewrite the promise, proof order and objections using the buyers' own phrases from Task 2. Mark each change with the quote that caused it. Copy-lint the file.
- [ ] **Step 3 🔒 U approves v1.** Record `Approved:`.
- [ ] **Step 4: Coordination:**
  - [ ] Plan 04 takes the hero, the RTL page lead and the meta descriptions from v1 (by its W5 copy pass).
  - [ ] Plan 05 Task 8 (drafted Wed 2 Dec) uses the v1 promise and proof order for PH, r/macapps, HN and IH.
  - [ ] Plans 02/03 use the in-app Pro window row for Task 12's copy.
- [ ] **Step 5: Commit** (`docs(growth): positioning v1` + trailer).

### Task 4: KPI script `scripts/kpi.py` (C; Tue 3 – Mon 9 Nov; branch `m08-kpi`)

**Deviation, by choice:** the brief named `kpi.ts`. Plan 05's counter is `scripts/polar_sales.py`, so importing `fetch_orders`, `count_sales` and `window` (ladder rung 2) beats porting the Polar paging and the CET windows to TypeScript. One scripts language, one test runner.

**Files:** Create `scripts/kpi.py`, `scripts/test_kpi.py`, `docs/growth/kpi/gsc/.gitkeep`.

**Interfaces:**
- **Consumes:** `polar_sales.fetch_orders(token, org_id, product_id, after, before) -> list[dict]`, `count_sales(orders, product_id) -> dict`, `window(start, end) -> (str, str)` (plan 05 Task 6). Before 1 Dec, plan 05 Task 6 may not have merged. Until then the Polar rows print `n/a (polar_sales.py not merged)`.
- **Produces:**
  - `REF_KEY = "reference_id"`: the Order `metadata` key, confirmed in Step 1.
  - `iso_week(d: date) -> str`, e.g. `"2026-W46"`.
  - `week_bounds(week: str) -> tuple[date, date]`: Monday to the next Monday.
  - `gsc_totals(f: TextIO, start: date, end: date) -> dict[str, int]`: keys `clicks`, `impressions`; reads GSC `Chart.csv` columns `Date`, `Clicks`, `Impressions`; `end` is exclusive.
  - `sales_by_ref(orders: list[dict], product_id: str) -> dict[str, int]`: same inclusion rule as `count_sales["sales"]`, keyed by `metadata[REF_KEY]` or `"none"`.
  - `est_net_eur(orders: list[dict], product_id: str) -> float`: Σ `total_amount`/100 over counted sales × 0.744 (BUSINESS-PLAN §9 blended factor). It is labelled as an estimate.
  - `pace(actual: int, elapsed_days: int, window_days: int) -> int`
  - `status(actual: float, target: float, pass_mark: float | None) -> str` ∈ `"stretch met"`, `"pass, below stretch"`, `"below pass"`, `"below stretch"`.
  - `parse_cf(resp: dict) -> dict[str, int]`: GraphQL response → `{path: count}`.
  - `render_report(week: str, rows: list[tuple[str, str, str]], targets: list[tuple[str, str, str]]) -> str`
  - CLI: `python3 scripts/kpi.py --week 2026-W46 [--gsc docs/growth/kpi/gsc/2026-W46/Chart.csv]` writes `docs/growth/kpi/2026-W46.md` and prints its path.
  - A missing key or file gives the row `n/a (missing <KEY>)`, never a crash. No secret or email address is ever printed.
  - One counter for every report and gate (X22): Polar numbers come only from `polar_sales.py`, and plan 07 G1 reads GSC through `gsc_totals`, so importing `kpi` must have no side effects (CLI under `if __name__ == "__main__":`).

- [ ] **Step 1: Attribution check in the Polar sandbox** (no approval needed).
  - In the sandbox org (H5), make a $1 test product and a checkout link. Open `<link>?reference_id=probe-1`, pay with Stripe's test card `4242 4242 4242 4242`.
  - Run `curl -s -H "Authorization: Bearer $POLAR_SANDBOX_ACCESS_TOKEN" "https://sandbox-api.polar.sh/v1/orders/?organization_id=$POLAR_SANDBOX_ORGANIZATION_ID&limit=1"` piped into `python3 -c 'import json,sys;o=json.load(sys.stdin)["items"][0];print(o["metadata"],o["checkout_id"])'` (the `.env.example` key names).
  - **Expected:** `metadata` contains `probe-1`. Record its key as `REF_KEY`.
  - **If not:** `GET /v1/checkouts/{checkout_id}` (scopes `checkouts:read`) and check its `metadata`. Then `sales_by_ref` reads a checkout-enriched order, and plan 05's production token needs `checkouts:read` (🔒, listed under the contract change requests).
  - **Facts used:**
    - polar.sh/docs/features/checkout/links (27 Oct): `reference_id` and `utm_*` "are automatically attached to the generated Checkout Session", and link metadata "propagates to the resulting Order".
    - The Order schema has `metadata` and `custom_field_data` but no `reference_id` field (polar.sh/docs/api-reference/orders/get.md).
- [ ] **Step 2: Cloudflare dataset check.** Run this once (`POST https://api.cloudflare.com/client/v4/graphql`, header `Authorization: Bearer $CLOUDFLARE_ANALYTICS_TOKEN`):
  - **Query:** `{ viewer { zones(filter:{zoneTag:"<CLOUDFLARE_ZONE_ID>"}) { settings { httpRequestsAdaptiveGroups { enabled maxDuration notOlderThan } } } } }`
  - **Expected:** `enabled: true`. Record `maxDuration`.
  - **Docs:** the settings node is at developers.cloudflare.com/analytics/graphql-api/features/discovery/settings/. The limits page says adaptive datasets "retain at least 31 days of data on every plan" but doesn't confirm Free-plan availability, hence this step.
  - **If it's disabled:** the visits row uses GSC clicks only, and the report says so.
- [ ] **Step 3: Write failing tests** (`scripts/test_kpi.py`, unittest):

```python
def o(status, net, pid="prod-md", meta=None, total=None):
    return {"status": status, "net_amount": net, "total_amount": net if total is None else total,
            "product_id": pid, "metadata": meta or {}}

class KpiTests(unittest.TestCase):
    def test_iso_week_handles_2026_week_53(self):
        self.assertEqual(iso_week(date(2026, 12, 29)), "2026-W53")
        self.assertEqual(week_bounds("2026-W46"), (date(2026, 11, 9), date(2026, 11, 16)))
    def test_gsc_totals_window_is_end_exclusive(self):
        csv = "Date,Clicks,Impressions,CTR,Position\n2026-11-09,3,120,2.5%,14.1\n2026-11-15,1,80,1.3%,12.0\n2026-11-16,9,900,1%,9\n"
        self.assertEqual(gsc_totals(io.StringIO(csv), date(2026, 11, 9), date(2026, 11, 16)), {"clicks": 4, "impressions": 200})
    def test_sales_by_ref_matches_count_sales_rules(self):
        orders = [o("paid", 1400, meta={"reference_id": "app-pdf"}), o("paid", 1900),
                  o("refunded", 1400, meta={"reference_id": "app-pdf"}), o("paid", 0, meta={"reference_id": "app-pdf"}),
                  o("paid", 1500, pid="other", meta={"reference_id": "app-pdf"})]
        self.assertEqual(sales_by_ref(orders, "prod-md"), {"app-pdf": 1, "none": 1})
    def test_est_net_uses_total_amount_and_plan_factor(self):
        self.assertAlmostEqual(est_net_eur([o("paid", 1900, total=1900)], "prod-md"), 14.136, places=3)
    def test_pace_and_status(self):
        self.assertEqual(pace(actual=10, elapsed_days=10, window_days=30), 30)
        self.assertEqual(status(31, 47, 30), "pass, below stretch")
        self.assertEqual(status(9, 47, 30), "below pass")
        self.assertEqual(status(50, 47, 30), "stretch met")
    def test_parse_cf_sums_paths(self):
        resp = {"data": {"viewer": {"zones": [{"httpRequestsAdaptiveGroups": [
            {"count": 5, "dimensions": {"clientRequestPath": "/"}},
            {"count": 2, "dimensions": {"clientRequestPath": "/download/"}}]}]}}, "errors": None}
        self.assertEqual(parse_cf(resp), {"/": 5, "/download/": 2})
    def test_report_marks_missing_sources(self):
        md = render_report("2026-W46", [("Sales (paid)", "n/a (missing POLAR_ACCESS_TOKEN)", "polar")], [])
        self.assertIn("n/a (missing POLAR_ACCESS_TOKEN)", md)
```

- [ ] **Step 4: Run them.** `python3 -m unittest discover -s scripts -p 'test_kpi.py' -v`. Expected: FAIL (`ModuleNotFoundError: No module named 'kpi'`).
- [ ] **Step 5: Implement `scripts/kpi.py`** with the signatures above.
  - `cf_counts(token, zone, host, day, path_like) -> dict[str, int]` posts one query per day, so it never exceeds `maxDuration`. It is a thin I/O wrapper with no unit test; `parse_cf` carries the logic:

```graphql
query($zone: string!, $host: string!, $start: Time!, $end: Time!, $like: string!) {
  viewer { zones(filter: {zoneTag: $zone}) {
    httpRequestsAdaptiveGroups(limit: 1000, filter: {datetime_geq: $start, datetime_lt: $end,
      clientRequestHTTPHost: $host, clientRequestPath_like: $like, edgeResponseStatus: 200,
      clientRequestHTTPMethodName: "GET"}) { count dimensions { clientRequestPath } } } } }
```

  - **Report rows**, each with its source:
    - GSC impressions; GSC clicks;
    - site page requests (host `tegelapps.com`, paths ending `/`, bots included);
    - `/download/` requests;
    - DMG GETs (host `downloads.tegelapps.com`, `%.dmg`, includes Sparkle update downloads);
    - appcast GETs per day (the SUFeedURL path from plan 03): an installed-base proxy from aggregate CDN counts, with no app telemetry;
    - waitlist active count (`GET https://connect.mailerlite.com/api/groups/{id}` → `active_count`; check the field name on the first run);
    - sales, refunded, free; sales by ref; est. net €;
    - visit → sale, as two figures: sales ÷ page requests (a floor) and sales ÷ GSC clicks;
    - refund rate.
  - **Targets table:** the Scoreboard rows, each with `pace` and `status`.
  - The Cloudflare `/download/` path and the DMG paths come from plans 03/04. Check that they match the deployed URLs on the first run.
- [ ] **Step 6: Run the tests.** Same command. Expected: `OK` (7 tests).
- [ ] **Step 7: Live run.** `set -a; . ./.env; set +a; python3 scripts/kpi.py --week 2026-W45`. Expected: the file exists, every `n/a` row names a source that isn't live yet (before launch: Polar production, and GSC until the first export), and `grep -ciE 'polar_(pat|oat)_|Bearer ' docs/growth/kpi/2026-W45.md` → `0`.
- [ ] **Step 8: Commit** (`git add scripts/kpi.py scripts/test_kpi.py docs/growth/kpi`, `feat(growth): weekly KPI report from Polar, Cloudflare and GSC` + trailer). Run Task 23 for `m08-kpi`, then merge.

### Task 5: Weekly growth review and experiment backlog (C + U; Mon 9 Nov; first review Tue 10 Nov)

**Files:** Create `docs/growth/experiments.md`.

- [ ] **Step 1: Reference ids.**
  - Every link to checkout carries `?reference_id=<surface>-<placement>`. Values:
    - `app-folder`, `app-pdf`, `app-theme`, `app-licence`;
    - `site-<page-slug>`;
    - `tool-rtl`;
    - `email-launch`, `email-launch2`, `email-d0`, `email-d7`, `email-crosssell`, `email-v11`;
    - `bench-rtl`.
  - The ids carry no personal data.
- [ ] **Step 2: The ritual.** Every **Tuesday 10:30–11:00 CET**, after plan 05's 10:00 support routine.
  - **C, before 10:30:**
    - export GSC (Performance → last 28 days → Export → CSV) into `docs/growth/kpi/gsc/<week>/` (U does the export if Claude can't log in);
    - run `kpi.py` for the last ISO week.
  - **Agenda:**
    1. Funnel vs last week, and the targets table (5 min).
    2. Triggers fired (5 min).
    3. Running experiments: has n been reached? Decide; otherwise wait. No peeking verdicts (10 min).
    4. Approve this week's 🔒 queue in one batch (5 min).
    5. Three lines under `## Decisions` in the week's KPI file (5 min).
  - Commit the KPI file (`docs(growth): KPI <week>` + trailer).
- [ ] **Step 3: Failure triggers.** Each maps to a BUSINESS-PLAN §12 gate.

| Trigger | Window | Action | Gate |
|---|---|---|---|
| Waitlist < 50 confirmed on Tue 24 Nov | pre-launch | Move the week's hours to Task 9 tool distribution and Task 10 RTL communities; launch unchanged | G1 input |
| Sales < 5 in 8–14 Dec | launch week | Check every funnel step: checkout 200, DMG 200, `/download/` requests vs DMG GETs, refund reasons. Fix the leak and don't add channels | G1 |
| Sales < 10 on Tue 22 Dec (day 14) | G1 pace | Write the G1 "< 10" branch for plan 05 Task 14 now: App 1 SEO stops after G1 and App 2 ships | G1 |
| Visit → sale (÷ GSC clicks) < 0.5% with ≥ 1,000 clicks / 30 d | rolling | Positioning review (Task 3 Step 2) before any traffic work | §4 test (≥ 1%) |
| Refund rate > 5% with ≥ 20 sales | rolling | Read every refund reason, fix the product or the copy, and log it in `reviews.md` | quality |
| RTL page < 1,000 GSC impressions / 30 d on Sat 6 Feb (day 60) | day 60 | RTL thesis weak: shift article slots from RTL to agent-files topics (plan 04) | §4 gap 1, G2 |
| GSC impressions / 30 d < 4,000 on Sat 6 Feb | day 60 | G2 at risk: prepare the maintenance-only branch | G2 |
| Cited 0/n on all 6 prompts for 3 monthly runs | AI | Rewrite answer blocks (Task 13 Step 2) | G2 input |
| Support > 20 min/day (plan 05 Task 4) | 14 d | Plan 05's gate wins: docs before growth work | Support |
| Est. net / month < €100 on Fri 30 Apr | G3 | Development stops; growth drops to the monthly AI check and the article cadence only | G3 |

- [ ] **Step 4: Pricing and packaging stance** (written into the file).
  - **No price A/B tests.** Two-proportion test, α = 0.05 two-sided, power 0.8 (computed with `statistics.NormalDist`, 27 Oct):
    - detecting visit → sale 1.0% → 1.5% needs **7,747 visits per arm**;
    - even a doubling (1% → 2%) needs **2,315 per arm**.
  - **Why that rules it out:** at the G2 stretch (10,000 impressions/30 d, about 200–400 search clicks/month at 2–4% CTR), one price test would take 1–6+ years. Charging two prices at once also clashes with rule 6's honest-pricing spirit.
  - **Allowed instead:** sequential, dated, pre-announced changes only (HR3):
    - $14 → $19 on 15 Dec (plan 05 Task 12);
    - App 2 at $15 (plan 06);
    - the $29 bundle after G3 (plan 07), launched on a stated date;
    - the paid-v2 upgrade price for v1 owners (plan 07).
  - **Evaluating a price change** needs ≥ 60 days on each side. Compare revenue per GSC click, and list the confounds: launch spike, season, macOS release in September.
  - **Never a "sale" event.**
- [ ] **Step 5: Copy/placement tests are sequential.**
  - Run period A until it reaches n visits to the tested page, then period B for the same n. Decide only at n (no peeking).
  - Metric: `/download/` requests ÷ tested-page requests (server-side counts, no JS).
  - **Minimum n per period:**
    - 768 to detect 20% → 26%;
    - 290 for 20% → 30%;
    - 434 for 30% → 39%.
  - **Verdict:** `python3 -c "from statistics import NormalDist as N;a,na,b,nb=<x>;p=(a+b)/(na+nb);z=(b/nb-a/na)/((p*(1-p)*(1/na+1/nb))**.5);print(z, 2*(1-N().cdf(abs(z))))"`. Ship B if p < 0.05 and B > A. Otherwise keep A and log it as a null result.
- [ ] **Step 6: The backlog, ICE-scored** (Impact, Confidence, Ease, 1–10; score = mean). Every row names its halal row.

| # | Hypothesis | Metric · method · n | I | C | E | ICE | HR |
|---|---|---|---|---|---|---|---|
| E01 | Home hero "Press Space to read Markdown" beats an agent-files-first hero | download rate · sequential · 768/period | 7 | 5 | 8 | 6.7 | 1 |
| E02 | The 60-s silent demo above the fold beats screenshots on the product page | download rate · sequential · 768 | 6 | 5 | 7 | 6.0 | 6 |
| E03 | The RTL page leading with a real Arabic PDF page image lifts downloads | RTL-page download rate · sequential · 768 | 6 | 4 | 8 | 6.0 | 9 |
| E04 | The free RTL checker brings non-brand impressions and downloads | tool GSC impressions ≥ 500/30 d; `tool-rtl` sales · one-off (Task 9) | 7 | 4 | 5 | 5.3 | 1 |
| E05 | A fair, dated "Tegel vs MacMD vs QLMarkdown" page earns "alternative" queries | GSC impressions on "alternative" queries · one-off, 60 d (plan 04 builds) | 6 | 5 | 6 | 5.7 | 1 |
| E06 | The RTL benchmark gets cited (links + AI answers) | referring domains (GSC Links) ≥ 5 in 90 d; AI citations · one-off (Task 16) | 6 | 3 | 5 | 4.7 | 1 |
| E07 | A waitlist form on every landing page beats home only | sign-ups per 1k views · sequential · 290 | 5 | 5 | 8 | 6.0 | 7 |
| E08 | A day-21 review ask linking one venue beats a list of three | public reviews per 100 asks · sequential by monthly cohort | 5 | 4 | 9 | 6.0 | 4 |
| E09 | A disclosed Arabic technical post (Hsoub I/O) drives AR-page downloads | `/ar/` page requests and downloads over 14 d · one-off | 5 | 4 | 7 | 5.3 | 2, 9 |
| E10 | Canonical dev.to cross-posts add referral visits without hurting rank | article requests over 14 d vs uncross-posted articles · paired | 3 | 4 | 8 | 5.0 | 1 |
| E11 | Answer-first blocks (40–60 words) raise AI citations and CTR | cited k/n + GSC CTR, 4 weeks before/after (Task 13) | 6 | 4 | 7 | 5.7 | 1 |
| E12 | Six directory listings in launch week + 1 raise branded impressions | GSC impressions for "tegel" queries · before/after | 4 | 5 | 8 | 5.7 | 2 |
| E13 | The cross-sell email sells App 2 to App 1 buyers | `email-crosssell` sales ÷ emails sent · one-off, 2 Feb | 7 | 6 | 9 | 7.3 | 7 |
| E14 | A Free-vs-Pro table beats a bullet list on the product page | sales per 1k product views · sequential, **underpowered** (needs 7,747): directional only | 4 | 3 | 8 | 5.0 | 3 |
| E15 | The v1.1 "free update" email + post revives App 1 sales | sales in the 14 d after vs before · one-off (plan 07 date) | 5 | 4 | 8 | 5.7 | 7 |

  Re-score on the first Tuesday of each month. Run at most 2 sequential tests at once, on different pages.
- [ ] **Step 7: Commit** (`docs(growth): review ritual, triggers, ICE backlog` + trailer). Expected: `grep -cE '^\| E[0-9]{2} ' docs/growth/experiments.md` → `15`.

# Part A: before launch (W2–W6)

### Task 6: MailerLite account and lists (C via Playwright, U for 2FA; Tue 3 – Fri 6 Nov; approval may slip to Tue 10 Nov, and the waitlist go-live stays Mon 16 Nov)

- [ ] **Step 1 🔒 Create the account** with `STUDIO_EMAIL` on the Free plan (the user approves account creation).
  - Expected: the dashboard shows the Free plan. Record "250 subscribers / 2,500 emails / 3 automations × 5 steps" as seen on the plan page that day.
  - Check step: MailerLite may review a new account before it can send (duration unverified). If it asks for a website, use the live `tegelapps.com`; the domain exists from W2 (plan 04).
- [ ] **Step 2: Accept the DPA.** It is MailerLite's data processing terms, from the account's legal/settings page. Record the date. Plan 04's privacy page cites it.
- [ ] **Step 3 🔒 Sender domain.** Authenticate `tegelapps.com` (DKIM/SPF TXT records in Cloudflare DNS: a DNS change on a live domain). Sender = `hello@tegelapps.com`, name `Tegel`.
  - Expected: MailerLite shows the domain as verified, and `dig +short TXT <selector>._domainkey.tegelapps.com` returns the key.
- [ ] **Step 4: Settings.**
  - **Subscribe settings:** "Double opt-in for API and integrations" **on**. That setting is under Account settings → Subscribe settings; MailerLite: "The same double opt-in for API email is sent to all subscribers added via API" (mailerlite.com/help/how-to-use-double-opt-in-when-collecting-subscribers, 27 Oct).
  - **Confirmed-subscriber redirect:** `https://tegelapps.com/waitlist/confirmed/`.
  - **Tracking:** turn open and click tracking **off**, then verify it: send a test campaign to `STUDIO_EMAIL` and view its source. Expected: links point straight to their targets (no MailerLite redirect host) and there is no tracking-pixel image. If the Free plan can't turn tracking off, the privacy page must disclose open/click tracking before the waitlist goes live (Task 8 Step 6). Email results are measured by `reference_id`, not pixels.
  - **Footer:** identity + postal address/number (Tw 11.7 lid 7). Waits on open question 1.
- [ ] **Step 5: Groups.** `waitlist`, `buyers-markdown`, `buyers-data`. Save their ids and an API token to `.env` (`MAILERLITE_*`).
  - Expected: `grep -cE '^MAILERLITE_(API_TOKEN|GROUP_WAITLIST|GROUP_BUYERS_MARKDOWN|GROUP_BUYERS_DATA)=.+' .env` → `4`.
  - Add these names, plus `CLOUDFLARE_ANALYTICS_TOKEN` and `CLOUDFLARE_ZONE_ID` (contract change request 9), to `.env.example`.
- [ ] **Step 6: Check the API without writing.** `curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $MAILERLITE_API_TOKEN" https://connect.mailerlite.com/api/groups` → `200`.

### Task 7: Waitlist form handler (C; Wed 4 – Tue 10 Nov; branch `m08-waitlist`)

**Why a function:** MailerLite's embed posts to `assets.mailerlite.com/jsonp/…`. Without JS, the browser lands on a bare `{"success":true}` page, which a Webflow forum user reports and no official MailerLite source contradicts. Plan 04's tests also forbid external scripts. A same-origin Pages Function keeps the form plain HTML and the UX clean.

**Platform facts** (developers.cloudflare.com/pages/functions, 27 Oct):
- the `/functions` folder "at the root of your Pages project (and not in the static root)";
- `onRequestPost` is a documented method handler, and `context.env` "holds the environment variables, secrets, and bindings";
- Functions requests count toward the Workers Free quota (100,000/day);
- static asset requests "are free and unlimited".

`.ts` support isn't stated on the pages read, so the handler is `.js`.

**Files:** Create `site/functions/api/waitlist.js`, `site/functions/api/waitlist.test.js`.

**Interfaces:**
- **Produces:** `export async function onRequestPost({ request, env }): Promise<Response>`.
  - **Env:** `MAILERLITE_API_TOKEN`, `MAILERLITE_GROUP_WAITLIST`, `SITE_ORIGIN` (`https://tegelapps.com`).
  - **Form fields:**
    - `email`;
    - `consent` (`on`);
    - `website` (the honeypot, must be empty);
    - `lang` (`en`|`ar`; anything else counts as `en`).
  - **Redirects:** `303` to `<prefix>/waitlist/{check-email,invalid,error}/`, where prefix is `''` for en and `'/ar'` for ar. Check this against plan 04's URL scheme at Step 6.
  - **MailerLite call:** `POST https://connect.mailerlite.com/api/subscribers`, body `{email, groups:[MAILERLITE_GROUP_WAITLIST], status:"unconfirmed"}` (the field list is from developers.mailerlite.com/docs/subscribers). No IP address and no name are sent.

- [ ] **Step 1: Write the failing tests.**

```js
import { test, expect, mock, beforeEach } from 'bun:test';
import { onRequestPost } from './waitlist.js';

const env = { MAILERLITE_API_TOKEN: 'test-token', MAILERLITE_GROUP_WAITLIST: '111', SITE_ORIGIN: 'https://tegelapps.com' };
const post = (fields, headers = {}, body) => new Request('https://tegelapps.com/api/waitlist', {
  method: 'POST',
  headers: { 'Content-Type': 'application/x-www-form-urlencoded', Origin: 'https://tegelapps.com', ...headers },
  body: body ?? new URLSearchParams(fields).toString(),
});
let calls, reply;
beforeEach(() => {
  calls = []; reply = () => new Response('{}', { status: 201 });
  globalThis.fetch = mock(async (url, init) => { calls.push({ url, init }); return reply(); });
});
const ok = { email: 'a@example.com', consent: 'on', website: '', lang: 'en' };

test('valid sign-up creates an unconfirmed subscriber and redirects', async () => {
  const res = await onRequestPost({ request: post(ok), env });
  expect(res.status).toBe(303);
  expect(res.headers.get('Location')).toBe('/waitlist/check-email/');
  expect(calls[0].url).toBe('https://connect.mailerlite.com/api/subscribers');
  expect(calls[0].init.headers.Authorization).toBe('Bearer test-token');
  expect(JSON.parse(calls[0].init.body)).toEqual({ email: 'a@example.com', groups: ['111'], status: 'unconfirmed' });
});
```

  The remaining tests and their assertions:
  - `arabic form redirects under /ar`: `lang:'ar'` → Location `/ar/waitlist/check-email/`.
  - `missing consent is rejected without calling MailerLite`: `consent` absent → 303 `/waitlist/invalid/`, `calls.length === 0`.
  - `honeypot drops silently`: `website:'x'` → 303 `/waitlist/check-email/`, `calls.length === 0`.
  - `bad emails are rejected`: each of `'no-at'`, `'a@b'`, `'a@example.com\nBcc: x@y.z'`, and `'x'.repeat(250)+'@e.com'` → `/waitlist/invalid/`, no call.
  - `foreign origin is forbidden`: `Origin: https://evil.example` → 403, no call. A missing `Origin` → 403.
  - `oversized body is refused`: a body of 2,049 bytes → 413, no call.
  - `wrong content type is refused`: `application/json` → 415, no call.
  - `provider failure shows the error page and never echoes the address`: `reply = () => new Response('', {status: 500})` → 303 `/waitlist/error/`, and the response body doesn't contain `a@example.com`.
  - `network failure shows the error page`: `globalThis.fetch = mock(async () => { throw new TypeError('offline'); })` → 303 `/waitlist/error/`.
- [ ] **Step 2: Run them.** `bun test site/functions`. Expected: FAIL (`Cannot find module './waitlist.js'`).
- [ ] **Step 3: Implement `onRequestPost`.**
  - Check order: Origin (exact match with `SITE_ORIGIN`), then Content-Type, then size (`Content-Length` and the actual text length ≤ 2048), then fields.
  - Email check: trim; length ≤ 254; one `@`; a dot in the domain; no whitespace or control characters (`/^[^\s@]+@[^\s@]+\.[^\s@]+$/`).
  - Never `console.log` request data.
- [ ] **Step 4: Run them.** `bun test site/functions`. Expected: all pass (10 tests). Then `make test-site`: its output includes these 10 tests (plan 04's `cd site && bun test` discovers `functions/` and `tools/`). If it doesn't, add `bun test site/functions site/tools` to `test-site` and commit the `Makefile` with this task (X21).
- [ ] **Step 5: Commit** (`git add site/functions/api`, `feat(site): same-origin waitlist handler with double opt-in` + trailer).
- [ ] **Step 6: Preview deploy** through plan 04's deploy command (it runs from `site/`, so `functions/` uploads; X9).
  - **Secrets:** `wrangler pages secret put MAILERLITE_API_TOKEN --project-name <plan 04 project>`, and the same for `MAILERLITE_GROUP_WAITLIST` and `SITE_ORIGIN`. Never echo the values.
  - **Expected:**
    - `curl -s -o /dev/null -w '%{http_code}' -X POST <preview>/api/waitlist` → `403`;
    - `curl -s -o /dev/null -w '%{http_code}' -X POST -H "Origin: https://tegelapps.com" -H 'Content-Type: application/x-www-form-urlencoded' --data 'email=a@example.com&consent=on&website=bot' -w ' %{redirect_url}' <preview>/api/waitlist` → `303 …/waitlist/check-email/`. The honeypot is filled, so the function is proven live without sending any mail.

### Task 8: Waitlist copy, pages and go-live (C drafts, U approves; Wed 11 – Mon 16 Nov)

**Files:**
- Create `site/templates/partials/waitlist-form.html`.
- Create `site/content/{en,ar}/waitlist/{check-email,confirmed,invalid,error}.md` (front matter copied from an existing plan 04 page).
- Create `docs/growth/email-copy.md`.

- [ ] **Step 1: Form markup.** Plain HTML with no script. Native validation only: `type="email" required` and the checkbox `required`.

```html
<form class="waitlist" method="post" action="/api/waitlist">
  <label for="wl-email">Email</label>
  <input id="wl-email" name="email" type="email" autocomplete="email" required maxlength="254">
  <label class="wl-consent"><input name="consent" type="checkbox" required>
    Email me twice: when Tegel Markdown launches (8 Dec 2026) and when the next Tegel app launches (planned for early 2027). Then this list is deleted. Unsubscribe any time.</label>
  <div class="wl-hp" aria-hidden="true"><label>Leave this empty <input name="website" tabindex="-1" autocomplete="off"></label></div>
  <input type="hidden" name="lang" value="en">
  <button type="submit">Join the List</button>
  <p class="wl-small">You'll get one email first to confirm your address. MailerLite stores it for Tegel only. <a href="/privacy/">Privacy</a></p>
</form>
```

  - `.wl-hp` is positioned off-screen (plan 04 CSS), not `display:none`.
  - The Arabic partial mirrors the markup, with `lang=ar`, `dir="rtl"` and this copy (U reviews the Arabic):
    - consent: `راسلني مرتين: عند إطلاق Tegel Markdown ‏(8 ديسمبر 2026)، وعند إطلاق تطبيق Tegel التالي (المخطط له مطلع 2027). بعد ذلك تُحذف هذه القائمة. يمكنك إلغاء الاشتراك في أي وقت.`
    - button: `انضم إلى القائمة`.
  - Consent law: Tw 11.7 lid 1 (prior, provable consent). The box is unchecked, the purpose is specific, the retention is stated and the opt-out is shown (HR7).
- [ ] **Step 2: Result pages** (one short paragraph each, EN + AR):
  - **check-email:** "Check your inbox and confirm your address. Nothing arrives until you do. If it isn't there in 10 minutes, look in spam."
  - **confirmed:** "You're on the list. Two emails, then the list is deleted. Meanwhile you can try the RTL Markdown checker." (Link it once Task 9 is live.)
  - **invalid:** "That didn't work: please enter a valid email and tick the box." + a link back.
  - **error:** "We couldn't save your address just now. Please try again later, or email hello@tegelapps.com and we'll add it by hand."
- [ ] **Step 3: The double-opt-in confirmation email** (MailerLite → Subscribe settings → API double opt-in email). Write it into `email-copy.md`:

```text
Subject: Confirm your email for Tegel
Please confirm you'd like two emails from Tegel: one when Tegel Markdown launches on 8 Dec 2026, and one when the next Tegel app launches in early 2027. After that, the list is deleted.
[Confirm my email]
If you didn't ask for this, ignore this message and you won't hear from us.
Tegel, a one-person studio in the Netherlands · hello@tegelapps.com · <identity and postal address/number, Tw 11.7 lid 7>
```

- [ ] **Step 4: Privacy line.** It goes to plan 04's privacy page, which must be **live before the form**. That is contract change request 5.

```text
Waitlist. If you join the waitlist, your email address is stored by MailerLite (our email processor, under its data processing agreement) on the basis of your consent, confirmed by email. We use it for two emails: the launch of Tegel Markdown and the launch of the next Tegel app. After the second, we delete the list. You can unsubscribe at any time from any email, or by writing to hello@tegelapps.com.
Buyers. If you buy a licence, Polar (our merchant of record) shares your email with us. Unless you ticked "Don't email me set-up tips or news about Tegel apps" at checkout, we send three short emails in your first month (set-up, tips, a request for a review) and news about Tegel apps. Every email has an unsubscribe link.
```

- [ ] **Step 5: Checks.** Run Task 1's lint on `site/content/*/waitlist`, `site/templates/partials/waitlist-form.html` and `docs/growth/email-copy.md` → `COPY-LINT: clean`. Then plan 04's site build and tests: no external script. Expected: pass.
- [ ] **Step 6 🔒 Go live** (U approves "deploy the waitlist form to production"). The approval needs these in place, each checked, not assumed:
  - **Live privacy page:** `curl -s https://tegelapps.com/privacy/ | grep -c MailerLite` ≥ 1, and the page lists MailerLite as processor, the waitlist, the buyer sync and the lifecycle emails (the Step 4 text). If Task 6 Step 4 found that tracking can't be turned off, `curl -s https://tegelapps.com/privacy/ | grep -ciE 'open.*click|tracking'` ≥ 1 as well;
  - **Email footer:** the double-opt-in test email (Task 6 settings, sent to `STUDIO_EMAIL`) shows the real identity and a postal address or number (Tw 11.7 lid 7), and `grep -c '<identity and postal address' docs/growth/email-copy.md` → `0`;
  - the Cloudflare rate-limiting rule (Free: 1 rule) is **path equals `/api/waitlist`, 5 requests per 10 s per IP, block 10 s** (🔒 zone change);
  - the production secrets are set;
  - the form is included on the home page and the RTL landing page (plan 04 coordination).
- [ ] **Step 7: End-to-end check on production with `STUDIO_EMAIL`.** Expected:
  - the browser lands on `/waitlist/check-email/`;
  - the confirmation email arrives, lints clean and shows the footer;
  - the confirm link lands on `/waitlist/confirmed/`;
  - the MailerLite group `waitlist` shows 1 active.
  - Then 7 rapid POSTs in a loop: `for i in $(seq 7); do curl -s -o /dev/null -w '%{http_code} ' -X POST -H 'Origin: https://tegelapps.com' -H 'Content-Type: application/x-www-form-urlencoded' --data 'email=a&consent=on&website=x' https://tegelapps.com/api/waitlist; done` → at least one `429`.
  - Finally, remove the test subscriber (`POST /api/subscribers/{id}/forget`).
- [ ] **Step 8: Commit** (`git add site/templates/partials/waitlist-form.html site/content/en/waitlist site/content/ar/waitlist docs/growth/email-copy.md`, `feat(site): waitlist form, result pages and consent copy` + trailer). Run Task 23 for `m08-waitlist`, then merge.

### Task 9: Free tool, the RTL Markdown checker (C; Tue 10 – Fri 20 Nov; live Mon 23 Nov; branch `m08-rtl-tool`)

**Evaluation** (free-tools scorecard, 1–5 per factor; ≥ 25 = strong):

| Option | Demand | Buyer match | Unique | Path to product | Feasible | Upkeep (inv.) | Links | Share | Total | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|
| **RTL Markdown checker**: paste or open a file, preview with `dir="auto"`, flag blocks that will display in the wrong direction | 3 ("markdown rtl" has 10 suggestions [V³¹]) | 5 | 5 | 5 | 4 (reuses `Renderer/src`) | 4 | 4 | 3 | **33** | **Pick** |
| Mermaid previewer | 4 | 3 | 1 (mermaid.live is free and official) | 2 | 5 | 4 | 1 | 2 | 22 | No |
| Markdown → PDF online | 5 | 4 | 2 | 1 (gives Pro away) | 4 | 3 | 3 | 3 | — | **Ruled out:** paginated PDF is Pro |
| "Is your Quick Look working?" guide page | 3 | 4 | 3 | 4 | 5 | 4 | 2 | 2 | 27 | That's an article; it goes to plan 04 |

**Pro protection:**
- no export, download or copy-as-HTML;
- print CSS hides the preview;
- no folder mode;
- Mermaid isn't rendered (code only).

**Privacy:** nothing leaves the browser. The file is read with `FileReader`, and plan 04's `/tools/*` CSP (in `site/static/_headers`) sets `connect-src 'none'`.

**Files:**
- Create `site/tools/rtl-markdown-check/analyze.js` and `analyze.test.js`.
- Create `main.js` (DOM glue: `addHooks(DOMPurify)` once; then textarea and file input → `renderToHTML` → `DOMPurify.sanitize(html, { ...SANITIZE_CONFIG, RETURN_DOM_FRAGMENT: true })` → `preview.replaceChildren(fragment)`, plus the warning list; never `innerHTML`).
- Create `tool.html` (markup fragment) and `site/content/{en,ar}/tools/rtl-markdown-check.md` (page copy, front matter `tool: rtl-markdown-check`).

**Interfaces:**
- **Consumes:**
  - `renderToHTML(markdown, {mode:'window'})` from `Renderer/src/markdown.js` (master §3.2), imported by relative path;
  - `SANITIZE_CONFIG` and `addHooks(purify, { fileImages = false } = {})` from `Renderer/src/sanitize.js` (plan 01 Step 7; X8). The site tool installs the default hooks only: no `file:` images.
- **Produces:** `analyzeBlocks(markdown: string) -> { blocks: Array<{ index: number, kind: 'heading'|'paragraph'|'list-item'|'quote'|'table-cell', dir: 'rtl'|'ltr'|'neutral', rtlShare: number, warnings: Array<'latin-first'|'rtl-first-mostly-latin'> , text: string }>, summary: { rtl: number, ltr: number, neutral: number, warnings: number } }`.
  - Blocks follow the renderer's `dir="auto"` elements. Fenced and indented code is skipped (it stays LTR).
  - `dir` comes from the first strong character: RTL scripts are Arabic, Hebrew, Syriac, Thaana and N'Ko (`\p{Script=…}`), any other `\p{L}` is LTR, and a block with no letters is `neutral`.
  - `latin-first` fires when `dir==='ltr'` and `rtlShare > 0.5`. `rtl-first-mostly-latin` fires when `dir==='rtl'` and `rtlShare < 0.5`.

- [ ] **Step 1: Write failing tests.** All sample text is neutral technical prose, never religious text (rule 3).

```js
import { test, expect } from 'bun:test';
import { analyzeBlocks } from './analyze.js';
test('arabic paragraph is rtl', () => {
  expect(analyzeBlocks('يعرض هذا الملف الجداول والرموز.').blocks[0].dir).toBe('rtl'); });
test('latin-first, mostly-arabic paragraph is flagged', () => {
  const b = analyzeBlocks('API هي واجهة تربط بين برنامجين مختلفين في النظام.').blocks[0];
  expect(b.dir).toBe('ltr'); expect(b.warnings).toContain('latin-first'); });
test('hebrew heading', () => {
  const b = analyzeBlocks('## מדריך התקנה').blocks[0]; expect([b.kind, b.dir]).toEqual(['heading', 'rtl']); });
test('persian with zero-width non-joiner', () => {
  expect(analyzeBlocks('می‌خواهم فایل را باز کنم.').blocks[0].dir).toBe('rtl'); });
test('urdu list items', () => {
  const r = analyzeBlocks('- یہ فائل جدول دکھاتی ہے۔\n- Settings کھولیں اور دیکھیں کہ کیا بدلا۔');
  expect(r.blocks.map(b => b.dir)).toEqual(['rtl', 'ltr']); expect(r.blocks[1].warnings).toContain('latin-first'); });
test('code fences are skipped and dates are neutral', () => {
  const r = analyzeBlocks('```\nconst x = 1;\n```\n\n2026-12-08');
  expect(r.blocks.length).toBe(1); expect(r.blocks[0].dir).toBe('neutral'); });
test('table cells are analysed one by one', () => {
  const r = analyzeBlocks('| الاسم | Name |\n|---|---|\n| ملف | file |');
  expect(r.blocks.filter(b => b.kind === 'table-cell').map(b => b.dir)).toEqual(['rtl', 'ltr', 'rtl', 'ltr']); });
test('summary counts warnings', () => {
  expect(analyzeBlocks('API هي واجهة تربط بين برنامجين مختلفين.').summary.warnings).toBe(1); });
```

- [ ] **Step 2: Run them.** `bun test site/tools`. Expected: FAIL (`Cannot find module './analyze.js'`).
- [ ] **Step 3: Implement `analyzeBlocks`.**
  - Line-based segmentation: blank lines; ATX headings; `-`, `*`, `+` and `1.` items; `>` quotes; pipe-table rows split into cells, with delimiter rows skipped; ``` and `~~~` fences skipped.
  - Strip inline code spans before counting letters, because code is LTR by contract.
- [ ] **Step 4: Run them.** `bun test site/tools`. Expected: 8 pass.
- [ ] **Step 5: Page and glue.** Write `tool.html` and `main.js`, then the page copy:
  - **EN H1:** `RTL Markdown checker`.
  - **Lead (49 words):** `Paste Markdown or open a .md file to see how Arabic, Hebrew, Persian and Urdu paragraphs will display. Each block takes its direction from its first letter, the way browsers do with dir="auto", so a paragraph that starts with an English word turns left-to-right. This page flags those blocks.`
  - **Privacy line:** `Your text stays in this browser tab. Nothing is uploaded.`
  - **CTA under the preview:** `Need it on paper? Tegel Markdown exports paginated A4 and Letter PDFs that keep right-to-left text correct.`, linking to `/download/` and to checkout with `?reference_id=tool-rtl`.
  - **Print stylesheet:** `.preview { display: none }`, and `.print-note` shows: `Printing from this page is turned off. Tegel Markdown Pro exports paginated, right-to-left-correct PDFs.`
  - **AR page:** the same copy in Arabic (U reviews).
- [ ] **Step 6: Build.** Plan 04's build bundles `main.js` into `site/public/tools/rtl-markdown-check/` (contract change request 4). Expected:
  - `grep -c "connect-src 'none'" site/static/_headers` → ≥ `1` (plan 04's `/tools/*` and `/:lang/tools/*` blocks; the tool CSP isn't a meta tag);
  - `gzip -c site/public/tools/rtl-markdown-check/main.js | wc -c` < `300000` (if over, report the size to plan 01; the highlight.js language set is theirs).
- [ ] **Step 7: Hostile input** (Review focus 5). Only a deploy applies `_headers`, so test on a preview deploy (plan 04's preview command; previews need no approval). First `curl -sI <preview>/tools/rtl-markdown-check/ | grep -i '^content-security-policy'`: it contains `connect-src 'none'` and `script-src 'self'`, and not `cloudflareinsights` (proof the `!` detach dropped the global policy; joined policies would intersect and block `main.js`). Then open `<preview>/tools/rtl-markdown-check/` in Safari with Web Inspector → Network. Paste `Fixtures/markdown/hostile.md`. Expected: no alert or navigation, and the Network tab shows no request after the page load. Screenshot to `docs/growth/evidence/tool-hostile.png`.
- [ ] **Step 8: Print** (Review focus 5). On the same preview, Safari → File → Print with `rtl-arabic.md` loaded. Expected: the preview shows only the print note. Screenshot `docs/growth/evidence/tool-print.png`.
- [ ] **Step 9: Design.** Run `design-review` with light, dark and Arabic screenshots, and fix every finding at P1 or above. Then the Task 1 checklist.
- [ ] **Step 10: Commit** (`git add site/tools/rtl-markdown-check site/content/en/tools site/content/ar/tools docs/growth/evidence`, `feat(site): free client-side RTL Markdown checker` + trailer). Run Task 23 for `m08-rtl-tool`, then merge.
- [ ] **Step 11 🔒 Deploy** (U approves). Expected: `curl -s -o /dev/null -w '%{http_code}' https://tegelapps.com/tools/rtl-markdown-check/` → `200`, and `curl -sI https://tegelapps.com/tools/rtl-markdown-check/ | grep -ci "connect-src 'none'"` → `1` (the same for the `/ar/tools/` page). Request indexing for the URL in GSC.
- **Target queries:** `rtl markdown preview`, `markdown rtl checker`, `arabic markdown preview`, `hebrew markdown preview`, `persian markdown rtl`, `markdown right to left`.
- **Success:** ≥ 500 GSC impressions/30 d on the tool URL by Mon 8 Mar; ≥ 3 referring domains by Fri 30 Apr. Both are measured in the weekly report.

### Task 10: Waitlist acquisition (C drafts, U approves each 🔒; Mon 16 Nov – Mon 7 Dec)

**Target:** ≥ 150 confirmed by Mon 7 Dec 23:59. Honest expectation ≈ 60. The stretch needs one community to pick up the free tool.

| Source | When | Central | Stretch | HR | How |
|---|---|---|---|---|---|
| Free RTL checker + RTL communities (Hsoub I/O, Virgool, Obsidian forum RTL threads, where on-topic) | Tue 24 Nov – Fri 4 Dec | 25 | 70 | 1, 2, 9 | Disclosed technical posts about bidi in Markdown, linking the tool; Task 19 rules |
| Indie Hackers build-in-public posts (2) | Tue 17 Nov, Tue 1 Dec | 10 | 25 | 2 | Honest progress + budget + the G1 gate; waitlist link |
| Brand accounts (Bluesky + Mastodon; X if U chooses) | from Tue 17 Nov, 2 posts/week | 5 | 15 | 2, 6 | Silent screen captures of real builds (Task 19 Step 3) |
| Plan 04's SEO pages (4 by W5) | W2–W6 | 5 | 10 | 1 | Form on home + RTL page |
| Disclosed answers where someone asks for exactly this (SO, GitHub discussions, forums) | W3–W6, ≤ 2/week | 5 | 15 | 2 | Answer the question fully first, mention a free alternative too, disclose |
| U's own network (U decides) | any | ? | ? | 7 | Personal message, never a bulk send |
| **Total** | | **≈ 50–60** | **≈ 135–150+** | | |

**Not used:**
- r/macapps before launch: its one-promotion-per-30-days rule would spend the 8 Dec slot (plan 05 Task 8).
- A pre-launch Show HN: the account would make two self-posts in a few weeks (HN: "Please don't use HN primarily for promotion"). That is open question 3.

- [ ] **Step 1: Drafts in `docs/growth/distribution.md`** (Task 19 file):
  - IH post 1 (Tue 17 Nov). Title `Building a read-only Markdown reader for Mac on €200: week 4`. About 150 words: what, why, stack, budget, gate, waitlist link, a disclosure line.
  - IH post 2 (Tue 1 Dec): `One week to launch: what the RTL checker taught me`.
  - The Hsoub I/O post (Arabic; Step 2).
  - The Virgool article outline (Persian; U decides if a Persian reviewer is available; skip if not).
- [ ] **Step 2: Hsoub I/O draft (AR).** Hsoub's terms forbid promoting "حساباتك أو خدماتك" but allow showing your work, and its FAQ allows links "إذا كان مفيداً ويخدم النقاش" (io.hsoub.com/terms, /faq, read 27 Oct). Post in the `برمجة` community:

```text
لماذا تظهر فقرة عربية في Markdown من اليسار إلى اليمين؟
عند عرض Markdown في المتصفح، يأخذ كل عنصر اتجاهه غالباً من أول حرف "قوي" فيه (dir="auto"). لذلك إذا بدأت الفقرة بكلمة إنجليزية مثل API أو Docker، تُعرض الفقرة كلها من اليسار إلى اليمين حتى لو كانت عربية في معظمها. الحلول: ابدأ الفقرة بكلمة عربية، أو ضع الكلمة الإنجليزية داخل `code`، أو استخدم محرراً يحدد الاتجاه يدوياً.
كتبت أداة مجانية تعمل داخل المتصفح فقط (لا يُرفع أي نص) تُظهر لك الفقرات التي ستنعكس: <رابط الأداة>
إفصاح: أنا مطوّر Tegel Markdown، وهو قارئ Markdown لنظام ماك.
```

- [ ] **Step 3: Weekly count** in the KPI report (waitlist row). On Tue 24 Nov, apply the trigger from Task 5 Step 3.
- [ ] **Step 4: Each send 🔒,** logged in `distribution.md` with the date, URL, approval and sign-ups 7 days later (waitlist delta that week). Expected on Mon 7 Dec: a recorded total and a per-source estimate.

### Task 11: Quick Look deep link and Welcome copy (C; Wed 18 – Fri 20 Nov, deep link on lease L2 Thu 26 Nov; branch `m08-onboarding` only if a fix is needed)

**Starts only after plan 02 has merged to `main`.** Plan 02 Task 15 builds the one Welcome window, `TegelKit.QuickLookSetup` (this plan's interface and test) and Help ▸ Welcome to Tegel Markdown (X11). This task adds no window, defaults key or menu item; it verifies the deep link and reviews the copy.

**Facts:**
- On this macOS 15.7.7 build Mac, `/System/Library/ExtensionKit/Extensions/LoginItems.appex/Contents/Info.plist` declares `CFBundleIdentifier = com.apple.LoginItems-Settings.extension`, `allowsXAppleSystemPreferencesURLScheme = 1`, `alt_name = "Login Items & Extensions"` and `url_alias = ["com.apple.ExtensionsPreferences"]` (read with `plutil -p`, 27 Oct, `m15-intel`).
- So `x-apple.systempreferences:com.apple.ExtensionsPreferences` opens that pane on 15, and is the native Extensions pane id on 14.
- macOS 14, 26 and 27 are **unverified** (Step 2).

**Files:** Create `docs/growth/evidence/ql-deeplink-{15,27,14}.png` and `docs/growth/onboarding-copy.md`. Code changes only if Step 2 finds a miss: plan 02's `Packages/TegelKit/Sources/TegelKit/QuickLookSetup.swift` and `Packages/TegelKit/Tests/TegelKitTests/QuickLookSetupTests.swift`.

- [ ] **Step 1: Re-validate.** Read plan 02's merged Task 15. Expected: `QuickLookSetup.settingsURL`, `SettingsPath { privacySecurityExtensions, loginItemsExtensions }` and `settingsPath(macOSMajor:)` exist with this plan's former interface, and `WelcomeView` picks its Quick Look body with `settingsPath`. Record any mismatch under "Contract change requests" before Step 2.
- [ ] **Step 2: Verify the deep link** per machine. Run `open "x-apple.systempreferences:com.apple.ExtensionsPreferences"` and screenshot where it lands, then click Welcome's "Open System Settings…" and confirm the same pane.
  - `m15-intel` now: `docs/growth/evidence/ql-deeplink-15.png`.
  - Lease L2 (Thu 26 Nov 09:00 → Fri 27 Nov 09:00; plan 08 runs fourth, after plans 05, 03 and 02): `m27-arm` → `ql-deeplink-27.png`; the macOS 14 leg runs **last**, after the reinstall if offered → `ql-deeplink-14.png`. macOS 26 comes from GitHub `macos-26` if a run is already scheduled; otherwise it stays unverified and is said so.
  - **If it misses on a version:** on `m08-onboarding`, branch `settingsURL` on version in plan 02's `QuickLookSetup`, add that version to `QuickLookSetupTests`, run `swift test --package-path Packages/TegelKit --filter QuickLookSetupTests` (expect PASS), then Task 23 and merge for plan 05's next build. Fallback URL: `x-apple.systempreferences:` (the Settings home, which Welcome already opens when `open` returns `false`).
- [ ] **Step 3: Copy review** of plan 02's Welcome Quick Look copy (title, both `settingsPath` bodies, the "another previewer" line, the button) into `docs/growth/onboarding-copy.md`.
  - EN: the copy lint (Task 1); the pane names match the Step 2 screenshots word for word.
  - NL, FR and AR: manual review against the Task 1 checklist (P2-10; the U-10 reviewer records `Reviewed (<lang>): <date>, <reviewer>`). No price and no upsell on Welcome.
  - Copy findings are fixed in plan 02's strings catalogue on `m08-onboarding`, never as a second window.
- [ ] **Step 4: Commit** (`git add docs/growth/evidence docs/growth/onboarding-copy.md`, `docs(growth): Quick Look deep-link evidence and Welcome copy review` + trailer). With a Step 2 or Step 3 fix, the `m08-onboarding` commit adds the changed `QuickLookSetup` files or strings catalogue, then Task 23 runs for it.

### Task 12: Upgrade moments and checkout attribution (C; Mon 23 – Tue 24 Nov; branch `m08-upsell`)

**Starts only after plans 02 and 03 have both merged to `main`.** It modifies plan 02's `ProUpsellView` in the `pro` window and plan 03's Licence tab Buy button (X12). It ships in **1.0.0** (RC1, plan 05 Task 3, Wed 25 Nov). If plan 03 merges after Mon 23 Nov 12:00, it moves to **v1.1**, never 1.0.1, which plan 05 limits to bug fixes (P2-7). Record which.

**Rules** (paywalls skill; UX-writing per `apple-design`):
- The `pro` window opens only when the user invokes a Pro action: Open Folder, Export as PDF, or choosing a Pro theme. Never on launch or on a timer, never to `isPro` users.
- The page preview shows at most once per feature per session. Later invocations in the same session show the compact window (no preview).
- No price in the app (plan 05 contract change request 5; X30). The checkout shows it.

**Files:**
- Create `Packages/TegelKit/Sources/TegelStore/UpsellPolicy.swift` (with `UpsellFeature`, moved from plan 02) and `CheckoutLink.swift`.
- Create `Packages/TegelKit/Tests/TegelStoreTests/UpsellPolicyTests.swift` and `CheckoutLinkTests.swift`.
- Modify: `Apps/Markdown/App/ProUpsellView.swift` (drop the in-app `UpsellFeature`, add the per-feature copy and the PDF preview), plan 02's `openWindow(id: "pro", value:)` call sites (Open Folder… and folder drops, Export as PDF, the theme picker), plan 03's `LicenceSettingsView` Buy button, and the strings catalogue (paths recorded in Step 1).

**Interfaces:**
- **Consumes:**
  - `PolarConfig.checkoutURL`, `PolarConfig.benefitID`, `LicenseManager.isPro` (master §3.3; plan 03);
  - `FolderIndex.markdownFiles(in:)`, `PDFExporter.export(_:to:paper:)`, `RendererTheme` (master §3.3);
  - plan 02's `WindowGroup("Tegel Markdown Pro", id: "pro", for: UpsellFeature.self) { $feature in ProUpsellView(feature: feature) }` and `openWindow(id: "pro", value: UpsellFeature.<x>)`.
- **Produces:**
  - `public enum UpsellFeature: String, CaseIterable, Codable, Hashable, Sendable { case folder, pdf, theme }`, moved into TegelStore next to `UpsellPolicy`. It stays `String, Codable` (and `Hashable`), because it's the `pro` window's value (master §3.3). The app then imports it from TegelStore; no second declaration remains.
  - `@MainActor public final class UpsellPolicy { public init(); public func shouldShowPreview(_ feature: UpsellFeature) -> Bool }`. It returns `true` the first time per feature for this instance; the app holds one instance per launch.
  - `extension PolarConfig { public func checkoutURL(ref: String) -> URL }`. It appends `reference_id=<ref>` via `URLComponents`, keeps existing query items, and percent-encodes the value.
  - App only: `@MainActor @Observable final class UpsellContext { var preview: PDFDocument? }`, one per launch in the environment. A caller sets it just before `openWindow`; `ProUpsellView` reads it and clears it in `onDisappear`. The window value stays the bare feature, so nothing large or private is encoded for state restoration.

- [ ] **Step 1: Re-validate.** Record the actual names:
  - plan 02's `ProUpsellView`, the `pro` `WindowGroup`, and its folder / PDF / theme `openWindow` call sites;
  - plan 03's Licence tab and its Buy button, and how "Buy Pro…" and "Enter Licence Key…" in `ProUpsellView` are wired (plan 02 left them to plan 03; if plan 03 didn't wire them, this task does);
  - how `isPro` reaches views (master §3.3 `EnvironmentValues.isPro`).

  Diff these against this task's interfaces, and list any mismatch under "Contract change requests" before coding.
- [ ] **Step 2: Failing tests.**

```swift
@MainActor @Test func previewShowsOncePerFeaturePerSession() {
    let p = UpsellPolicy()
    #expect(p.shouldShowPreview(.pdf)); #expect(!p.shouldShowPreview(.pdf)); #expect(p.shouldShowPreview(.folder))
    #expect(UpsellPolicy().shouldShowPreview(.pdf))   // new launch = new session
}
@Test func upsellFeatureRoundTripsAsWindowValue() throws {
    let data = try JSONEncoder().encode(UpsellFeature.theme)
    #expect(try JSONDecoder().decode(UpsellFeature.self, from: data) == .theme)
}
@Test func checkoutURLAddsReference() {
    let base = PolarConfig(apiBase: URL(string: "https://api.polar.sh")!, organizationID: "o",
                           checkoutURL: URL(string: "https://buy.polar.sh/polar_cl_abc")!, portalURL: URL(string: "https://polar.sh/x/portal")!,
                           benefitID: "b")
    #expect(base.checkoutURL(ref: "app-pdf").absoluteString == "https://buy.polar.sh/polar_cl_abc?reference_id=app-pdf")
    #expect(base.checkoutURL(ref: "a b").absoluteString.hasSuffix("reference_id=a%20b"))
}
```

  Both files start with `import Testing`, `import Foundation` and `@testable import TegelStore`. The internal memberwise initialiser of `PolarConfig` is then visible; if plan 03 changed it, use plan 03's initialiser and record it in Step 1. If plan 01 set the test targets up with XCTest, write the same assertions in XCTest.
- [ ] **Step 3: Run them.** `swift test --package-path Packages/TegelKit --filter 'previewShowsOncePerFeaturePerSession|upsellFeatureRoundTripsAsWindowValue|checkoutURLAddsReference'`. Expected: FAIL (`cannot find 'UpsellPolicy' in scope`).
- [ ] **Step 4: Implement both** to the interfaces. Delete the `UpsellFeature` declaration from `ProUpsellView.swift` and `import TegelStore` where the app uses it. Run them. Expected: PASS. Then `make check`: no regression, and `grep -rn 'enum UpsellFeature' Apps/ Packages/` → exactly one hit, in `TegelStore/UpsellPolicy.swift`.
- [ ] **Step 5: Wire the moments** (free tier only, `!isPro`). Each moment calls `openWindow(id: "pro", value:)`; `ProUpsellView(feature:)` shows the feature's title and body above plan 02's bullets and terms line (`One-time purchase for 2 Macs. No subscription. 14-day refund.`), with these buttons:
  - `Buy Pro…` opens `checkoutURL(ref: "app-<feature>")` (`app-folder`, `app-pdf`, `app-theme`);
  - `Enter Licence Key…` opens Settings on the Licence tab (plan 03; mechanism recorded in Step 1);
  - `Not Now` closes the window.

  Per feature:
  - **Folder:** free Open Folder… opens `.folder` straight away (plan 02's flow). There's no open panel first, because asking for a folder and then refusing it would be bait-and-switch.
    - title `Read Whole Folders with Pro`;
    - body `Pro shows a whole folder in a sidebar, searches across its Markdown files and reloads them as they change.`
  - **PDF:** if `shouldShowPreview(.pdf)`:
    - export with `PDFExporter` to `FileManager.default.temporaryDirectory`, load it as `PDFDocument(data:)`, **delete the file at once**, put it in `UpsellContext.preview`, and show the pages in a read-only `PDFView` (no print/save controls);
    - title `Export as PDF with Pro`;
    - body `Here is your document as %lld %@ pages. Saving it as a PDF is part of Pro.` (`A4`/`Letter`).
    - Otherwise, the compact window: the same title, no preview.
    - Mark the ceiling in code: `// ponytail: temp PDF lives for milliseconds in the container; a determined user could race it, so accept that or render page images in memory instead.`
  - **Theme:** picking Ink or Studio while free calls `openWindow(id: "pro", value: UpsellFeature.theme)`, and the stored theme stays `.paper` (plan 02's behaviour; no in-window preview, no banner).
    - title `Ink and Studio with Pro`;
    - body `Pro adds the Ink and Studio themes, in light and dark. Paper stays free.`
  - A `nil` feature keeps plan 02's generic copy and uses `app-pro`.
  - **Licence tab** (plan 03): its Buy button uses `checkoutURL(ref: "app-licence")`. App 2 compiles `LicenceSettingsView` by path (plan 06), so its Buy button carries the same ref; the KPI splits refs by product.
  - NL/FR/AR strings are drafted by C and go to manual review (Task 1 Step 2; P2-10).
- [ ] **Step 6: Price check** (plan 05 Task 3 Step 1; X30). `grep -rnE '\$ ?(1[459]|29)\b' Apps/ || echo "no price in app"` → `no price in app`.
- [ ] **Step 7: Manual check** (Review focus 4) on `m15-intel` with a Debug build, `isPro` off. Expected:
  - launch shows no upsell;
  - Export as PDF twice: the first `pro` window shows pages, the second is compact;
  - Open Folder…: the `pro` window with the folder copy, no open panel first; no folder window opens;
  - picking Ink opens the `pro` window with the theme copy, and Settings ▸ Appearance still shows Paper;
  - `Enter Licence Key…` lands on Settings ▸ Licence;
  - with the Debug `isPro` override on (`-TGForcePro YES`), none of these appear;
  - `Buy Pro…` opens a URL ending `reference_id=app-pdf` (screenshot the address bar).
  - Screenshots in light, dark and Arabic UI, then `design-review`, with every finding at P1 or above fixed.
- [ ] **Step 8: Commit** (`git add Packages/TegelKit/Sources/TegelStore/UpsellPolicy.swift Packages/TegelKit/Sources/TegelStore/CheckoutLink.swift Packages/TegelKit/Tests/TegelStoreTests/UpsellPolicyTests.swift Packages/TegelKit/Tests/TegelStoreTests/CheckoutLinkTests.swift Apps/Markdown/App/ProUpsellView.swift <plan 02/03 files from Step 1> docs/growth/evidence`, `feat(app): honest upgrade moments in the Pro window with per-placement checkout refs` + trailer). Run Task 23 (stage 4 required: this touches TegelStore/licensing), then merge before RC1 (plan 05 Task 3, Wed 25 Nov), or hold the branch for v1.1.
- **Success:** ≥ 30% of App 1 sales carry an `app-*` ref by G1. Each placement's count shows in the weekly report.

### Task 13: AI-search and answer-engine layer (C; Tue 24 Nov – Tue 1 Dec; then monthly)

**Files:** Create `site/static/llms.txt`, `docs/growth/answers.md`, `docs/growth/ai-visibility.md`.

- [ ] **Step 1: `llms.txt`.** Format from llmstxt.org (27 Oct): an H1 (the only required part), a blockquote summary, optional prose, then H2 sections of `[name](url): notes` links, plus an `## Optional` section.

```markdown
# Tegel Markdown

> Tegel Markdown is a native, read-only Markdown and Mermaid reader for macOS 14 and later, made by Tegel, a one-person studio in the Netherlands. Its Quick Look extension and single-file window are free; a one-time Pro licence for 2 Macs adds folder mode, paginated right-to-left-correct PDF export and themes.

It never changes your files, sends no telemetry and needs no account. The only network calls are licence checks and update checks.

## Product
- [Tegel Markdown](https://tegelapps.com/<product path>): features, free vs Pro, requirements, current price
- [Download](https://tegelapps.com/download/): notarised DMG, macOS 14+, Apple Silicon and Intel

## Support
- [FAQ](https://tegelapps.com/faq/): activation, enabling Quick Look, refunds
- [Known issues](https://tegelapps.com/faq/#known-issues)

## Optional
- [RTL Markdown checker](https://tegelapps.com/tools/rtl-markdown-check/): free in-browser tool
- [RTL Markdown rendering test](https://tegelapps.com/research/rtl-markdown-rendering-test/): dated results and method
```

  There's no price in the file, so it never goes stale. Replace `<product path>` with plan 04's actual path. Check: `grep -oE 'https://[^)]+' site/static/llms.txt | while read u; do curl -s -o /dev/null -w "%{http_code} $u\n" "$u"; done` → every line `200` (after Tasks 9 and 16 go live; until then, skip those two lines).
- [ ] **Step 2: Answer blocks** in `docs/growth/answers.md`. Each is 40–60 words that answer first, plus a dated source line. Plan 04 places each on the named landing page as an H2 phrased like the query (coordination checkbox per row). Drafts (C rewrites each with Task 2's phrasing):
  1. **"Best Markdown viewer for Mac"** (comparison page, plan 04): `It depends on what you need. QLMarkdown is free and open source but previews in Quick Look only. MacMD Viewer ($19.99, no free tier) adds a window app; its PDF export is one continuous page. Tegel Markdown has a free Quick Look tier and adds folders and paginated PDF in a one-time Pro licence.` Sources: [V²⁹], [V³⁹], checked <date>.
  2. **"How to open .md files on Mac":** `macOS shows Markdown as plain text: TextEdit has no Markdown mode, even in macOS 27. To read it formatted, install a viewer with a Quick Look extension, open it once, then select the .md file in Finder and press Space. Tegel Markdown and QLMarkdown both do this for free.` Source: [V²¹].
  3. **"Quick Look Markdown not working macOS 15":** `macOS 15 Sequoia dropped support for old .qlgenerator plug-ins, so previewers built that way stopped working. Use an app that ships a modern Quick Look extension, open it once, then check System Settings > General > Login Items & Extensions > Quick Look and turn it on.` Sources: [S²⁸] (eclecticlight.co, 31 Oct 2024), Task 11 facts.
  4. **"Arabic Markdown to PDF":** `Markdown has no direction syntax, so the PDF depends on the renderer. Pandoc with XeLaTeX and a bidi setup works but takes configuration. Printing from a browser gives one flowing document without page control. Tegel Markdown Pro exports paginated A4 or Letter PDFs with right-to-left paragraphs and left-to-right code.`
  5. **"Does Markdown support right-to-left?":** `Not in its syntax. Renderers decide direction, usually from each block's first strong letter (dir="auto"), so a paragraph that starts with an English word turns left-to-right. Start RTL paragraphs with an RTL word, or keep English terms in code spans. The free RTL Markdown checker shows which blocks will flip.`
  6. **"Read Claude Code plan files on Mac":** `Coding agents leave Markdown plans and specs in your repo (CLAUDE.md, AGENTS.md, docs/). Press Space in Finder for a formatted preview, or open the whole folder in a reader that lists every .md file, searches across them and reloads them when the agent edits them. Tegel Markdown Pro does this read-only.`

  Run the Task 1 lint. Check every product claim against the shipped app. Each third-party claim (e.g. Pandoc + XeLaTeX in answer 4) gets a cited primary source or is cut.
- [ ] **Step 3: Crawler access** (coordination, plan 04 owns `robots.txt`). Allow `GPTBot`, `OAI-SearchBot`, `ChatGPT-User`, `PerplexityBot`, `ClaudeBot`, `Claude-SearchBot`, `Google-Extended` and `Applebot-Extended`. Check: `curl -s https://tegelapps.com/robots.txt | grep -ciE 'disallow: /$'` → `0`.
- [ ] **Step 4: The visibility procedure** in `ai-visibility.md`.
  - **Who and when:** U runs it, or C through a browser where the engine's terms allow it. First Tuesday of each month (Tue 1 Dec, 5 Jan, 2 Feb, 2 Mar, 6 Apr, 4 May, 1 Jun, 6 Jul, 3 Aug, 7 Sep, 5 Oct 2027), about 30 minutes.
  - **Engines:** ChatGPT (search on), Perplexity, Google (AI Overview / AI Mode).
  - **Prompts (6):**
    - `best markdown viewer mac`
    - `how do I open .md files on a mac`
    - `quick look markdown macos 15 not working`
    - `arabic markdown to pdf`
    - `markdown rtl viewer`
    - `how to read claude code plan files on mac`
  - **Runs:** each prompt twice per engine in a fresh session, because answers are non-deterministic (ai-seo skill: track the mention rate with n).
  - **Record table:** `| month | engine | prompt | runs | Tegel cited k/n | Tegel URL cited | competitors named |`.
  - **Expected:** a baseline row set on Tue 1 Dec (36 rows).
- [ ] **Step 5: Commit** (`docs(growth): llms.txt, answer blocks, AI-visibility procedure + baseline` + trailer). Deploy `llms.txt` with plan 04's next approved deploy. Expected: `curl -s -o /dev/null -w '%{http_code}' https://tegelapps.com/llms.txt` → `200`.

# Part B: launch and after (W5 → month 12)

### Task 14: Buyer lifecycle email (C; Tue 24 Nov – Fri 4 Dec; branch `m08-lifecycle`)

**Legal basis:** Tw 11.7 lid 4 soft opt-in for own similar products. The objection is offered at collection by plan 05's `no_marketing` checkbox (label `Don't email me set-up tips or news about Tegel apps`, plan 05 Task 2; P0-2) and in every message by MailerLite's unsubscribe link. MailerLite allows "Customers who have purchased from you within the last 2 years" (mailerlite.com/legal/anti-spam-policy, 27 Oct).

**Files:** Create `scripts/sync_buyers.py`, `scripts/test_sync_buyers.py`; add to `docs/growth/email-copy.md`.

**Interfaces:**
- **Consumes:** `polar_sales.fetch_orders(...)`; Order fields `status`, `net_amount`, `product_id`, `custom_field_data`, `customer` (orders/get.md, 27 Oct). Step 1 confirms that `customer.email` exists.
- **Produces:**
  - `plan_sync(orders: list[dict], product_id: str) -> dict[str, list[str]]` with keys `add`, `remove`, `skipped`. Emails are lowercased and de-duplicated.
    - **add:** counted sales (plan 05 rule), excluding `custom_field_data.get("no_marketing") is True`.
    - **remove:** `refunded` orders, unless the same email also has a counted sale.
    - **skipped:** the `no_marketing` set.
  - `subscriber_payload(email: str, group_id: str) -> dict` → `{"email": email, "groups": [group_id], "status": "active"}`. It never contains `resubscribe`.
  - CLI: `python3 scripts/sync_buyers.py --product markdown|data --days 3 [--dry-run]` prints `added=<n> removed=<n> skipped=<n>`. It never prints an email.
    - **Upsert:** `POST /api/subscribers`, which is idempotent; an existing member doesn't re-trigger the automation.
    - **Remove:** look up the subscriber by email (`GET /api/subscribers/{email}`; check step), then `DELETE /api/subscribers/{id}/groups/{group_id}`.

- [ ] **Step 1: Check steps.**
  - In the Polar sandbox (Task 4 Step 1 order): the order JSON has `customer.email` and `custom_field_data`. Record the custom-field key exactly as Polar returns it (`no_marketing` expected).
  - In MailerLite, with `STUDIO_EMAIL+t1@…` as an **unsubscribed** test subscriber, an upsert with `status:"active"` leaves it unsubscribed.
  - Record both results here.
- [ ] **Step 2: Failing tests.**

```python
def o(status, net, email, nm=None, pid="prod-md"):
    return {"status": status, "net_amount": net, "product_id": pid,
            "customer": {"email": email}, "custom_field_data": {} if nm is None else {"no_marketing": nm}}
class SyncTests(unittest.TestCase):
    def test_plan_respects_objection_refunds_and_dupes(self):
        r = plan_sync([o("paid", 1400, "A@x.com"), o("paid", 1400, "a@x.com"), o("paid", 1400, "b@x.com", nm=True),
                       o("refunded", 1400, "c@x.com"), o("refunded", 1400, "a@x.com"), o("paid", 0, "d@x.com"),
                       o("paid", 1500, "e@x.com", pid="other")], "prod-md")
        self.assertEqual(r, {"add": ["a@x.com"], "remove": ["c@x.com"], "skipped": ["b@x.com"]})
    def test_payload_never_resubscribes(self):
        p = subscriber_payload("a@x.com", "9")
        self.assertEqual(p, {"email": "a@x.com", "groups": ["9"], "status": "active"}); self.assertNotIn("resubscribe", p)
```

- [ ] **Step 3: Run them.** `python3 -m unittest discover -s scripts -p 'test_sync_buyers.py' -v`. Expected: FAIL (`No module named 'sync_buyers'`).
- [ ] **Step 4: Implement** to the interfaces. Run them. Expected: `OK` (2 tests).
- [ ] **Step 5: Lifecycle copy** in `email-copy.md`. Every email ends with this footer:

```text
You're getting this because you bought Tegel Markdown. Three short emails in your first month, then only news about Tegel apps. Unsubscribe: <MailerLite unsubscribe link>
Tegel · <legal name> · KvK <number> · <postal address or number, Tw 11.7 lid 7> · hello@tegelapps.com
```

```text
DAY 0 — Subject: Three things to set up in Tegel Markdown
Thanks for buying Tegel Markdown. Three things worth two minutes:
1. Activate Pro: <Settings path from plan 03>, paste the key from your Polar receipt. It works offline for 30 days after each successful check, on 2 Macs. Moving to a new Mac? Deactivate the old one in the app or in the customer portal: <POLAR_PORTAL_URL>.
2. Quick Look: select any .md file in Finder and press Space. Plain text instead? Help > Welcome to Tegel Markdown in the app shows where to switch it on.
3. Open a whole repo: <Open Folder menu path from plan 02>. The sidebar lists README, CLAUDE.md, AGENTS.md and docs/, and pages reload when your editor or agent changes them.
Something wrong? Reply to this email with Help > Copy Diagnostics pasted in.

DAY 7 — Subject: Three things you might have missed
1. Search across every document in a folder: <shortcut from plan 02>.
2. Export as PDF gives real A4 or Letter pages, with right-to-left paragraphs that stay right-to-left and code that stays left-to-right.
3. Three themes (Paper, Ink, Studio), each with light and dark, from <View menu path>.
If a file renders wrong, reply and attach it if it holds nothing private. I read every reply.

DAY 21 — Subject: Would you review Tegel Markdown?
If you have three minutes, a short public review helps other Mac users decide. There's no reward and nothing to unlock; honest reviews, critical ones included, are what I'm after.
· AlternativeTo: <listing URL>
· Product Hunt: <reviews URL>
And if something isn't working, reply and I'll try to fix it, whether or not you write a review.
Happy for your words to appear on tegelapps.com? Reply "you may quote me" with the name or handle to show. Nothing is quoted without that.
```

  Fill every `<…>` from the shipped app (plans 02/03) and the live listings (Task 17) before Step 7. Check: `grep -c '<' docs/growth/email-copy.md` counts only the MailerLite merge tags. Run the Task 1 lint → clean.
- [ ] **Step 6: Automation** (MailerLite, Free: ≤ 3 automations × 5 steps). `buyers-markdown`: trigger "joins group", then email D0, wait 7 days, email D7, wait 14 days, email D21 (5 steps). Links carry `reference_id=email-d0` / `email-d7` only where they point to checkout. Send a test to `STUDIO_EMAIL`. Expected: three test emails render, the footer is complete and the unsubscribe link works.
- [ ] **Step 7 🔒 Activate the automation** (U approves the copy and the activation). The first live sync runs at the 10:00 support routine on Wed 9 Dec.
  - **Precondition** (P0-2): open the live production checkout (don't pay) and read the `no_marketing` checkbox label. Expected verbatim: `Don't email me set-up tips or news about Tegel apps`. If it differs, don't activate; tell the user, because buyers who saw another label weren't offered this objection.
  - **Coordination:** plan 05 Task 4's daily routine gains `set -a; . ./.env; set +a; python3 scripts/sync_buyers.py --product markdown --days 3`.
  - **Expected:** `added=` matches that day's new non-objecting sales.
- [ ] **Step 8: Commit** (`git add scripts/sync_buyers.py scripts/test_sync_buyers.py docs/growth/email-copy.md`, `feat(growth): daily buyer sync for soft-opt-in lifecycle email` + trailer). Run Task 23 (stage 4: MailerLite token, PII handling), then merge.
- **Success:** ≥ 10 public reviews by Mon 8 Mar, of which at least half within 30 days of a day-21 email (Task 18 log).

### Task 15: Launch-day and App 2 emails (C drafts, U sends 🔒; Tue 8 Dec, Tue 2 Feb)

- [ ] **Step 1: Launch email to `waitlist`** into `email-copy.md`. It goes out at **Tue 8 Dec 09:30 CET**, after PH goes live at 09:01 (coordination: one row in plan 05's launch-day runbook, Task 9). There is no upvote ask anywhere (PH and HN rules; HR2).

```text
Subject: Tegel Markdown is out
Tegel Markdown is available today for macOS 14 and later.
Press Space on any .md file in Finder to read it with Mermaid diagrams and right-to-left text that displays the right way round. That part is free.
Pro is a one-time licence for 2 Macs: folder mode with search and live reload, paginated A4 and Letter PDF export that keeps right-to-left text correct, and three themes with light and dark.
Introductory price $14 until Mon 14 Dec 2026 23:59 CET. From 15 Dec: $19.
Download: https://tegelapps.com/download/
Buy Pro: <POLAR_CHECKOUT_URL_MARKDOWN>?reference_id=email-launch
It's read-only: it never changes your files, sends no telemetry and needs no account. 14-day refund, no questions asked.
If a file renders wrong, reply to this email. I read every reply.
This was email 1 of 2. The second comes when the next Tegel app launches; then this list is deleted.
<footer: waitlist variant: "You're getting this because you joined the Tegel waitlist.">
```

  Checks:
  - `grep -cF 'Introductory price $14 until Mon 14 Dec 2026 23:59 CET. From 15 Dec: $19.' docs/growth/email-copy.md` ≥ `1`;
  - the lint is clean;
  - a test send to `STUDIO_EMAIL` renders.

  🔒 Send. Record the time and recipient count.
- [ ] **Step 2: App 2 emails** (Tue 2 Feb 2027, 09:30 CET). The product facts and the price come from plan 06; if plan 06 sets an intro price, use its dated wording verbatim (HR3).
  - **To `waitlist`** (email 2 of 2). Subject `Tegel Data is out (and this list is now closed)`. Body:
    - what Tegel Data reads: JSON, JSONL, YAML, TOML, CSV, `.env` masked;
    - its free Quick Look pack and its Pro features (plan 06's list);
    - the price, read-only, no telemetry, 14-day refund;
    - `ref=email-launch2`;
    - the closing line: `That was the second and last email. The waitlist is deleted today.`
  - **To `buyers-markdown`** (soft opt-in cross-sell, lid 4, HR7; this is E13). Copy and recipients come verbatim from plan 06 Task 15's `docs/launch/data-crosssell-email.md`: its subject, body, `?reference_id=email-crosssell` links, closing line and segment rule (P1-10). This plan adds only the footer and `{$unsubscribe}`, then sends at **09:30 CET**. If the group is over MailerLite Free's 250 subscribers, ask the user before sending (plan 06's segment rule).
  - **Coordination:** plan 08 owns the MailerLite account and this one send; plan 06 sends nothing. Plan 06's "cross-sell email" exit item is met by this send.
  - 🔒 U approves both copies and the sends. Expected: sent counts recorded.
- [ ] **Step 3: Delete the waitlist** (Tue 2 Feb, after the send). For each subscriber in `waitlist` who isn't in a buyers group, `POST /api/subscribers/{id}/forget` ("completely deleted and forgotten within 30 days", developers.mailerlite.com). Expected: the group has 0 members, and the consent promise is kept.
- [ ] **Step 4: v1.1 news** to `buyers-markdown` on plan 07's v1.1 release date. Subject `Tegel Markdown 1.1: math, footnotes and custom CSS, free for every owner`. Body: three features from plan 07, `Update from the app menu: Tegel Markdown > Check for Updates`, and `ref=email-v11` on any checkout link. 🔒 send. This is E15.
- [ ] **Step 5: Commit** each copy as it is written (`docs(growth): <email> copy` + trailer).

### Task 16: RTL Markdown rendering test (C; Tue 1 – Tue 15 Dec; at most a plain HN link Tue 12 Jan)

**Why:** original, dated, reproducible data is what AI engines and writers cite (ai-seo: cite sources, add statistics). This piece is HR1's "fair, dated, sourced comparison".

**Files:**
- Create `docs/growth/rtl-benchmark/{cases.md,results.md}`, `docs/growth/rtl-benchmark/shots/`.
- Create `site/content/en/research/rtl-markdown-rendering-test.md`.

- [ ] **Step 1: Cases** (12). Each is a minimal Markdown snippet built from `Fixtures/markdown/{rtl-arabic,rtl-hebrew,rtl-persian-urdu,mixed-bidi}.md` (neutral prose, §3.4):
  1. Arabic paragraph; 2. Arabic paragraph starting with an English word; 3. Hebrew heading + English paragraph; 4. RTL bulleted list; 5. RTL numbered list; 6. RTL table; 7. RTL blockquote; 8. inline code inside RTL; 9. a fenced code block after RTL text; 10. Persian with ZWNJ; 11. Urdu paragraph (record the font each viewer falls back to); 12. a mixed-direction link text.
- [ ] **Step 2: Viewers.** All are free or on a free trial, installed on `m15-intel` (macOS 15.7.7). Record versions:
  - Finder Quick Look default; QLMarkdown; MacDown; MarkEdit; Obsidian (no plugins); Typora (trial); VS Code Markdown preview; GitHub.com rendering; Tegel Markdown 1.0.
  - **MacMD Viewer: not tested.** It has no trial ([V³⁹]) and buying it is a purchase outside the budget. The article says so.
- [ ] **Step 3: Score** each case × viewer as `pass` / `fail` / `partial`. The criteria are written before testing: block direction, alignment, list-marker side, table column order, and code direction. Screenshot each to `shots/<viewer>-<case>.png` (`sips -Z 1280`). Fill `results.md`.
- [ ] **Step 4: Article.** It contains:
  - method, date, machine and versions;
  - the results table;
  - the criteria;
  - one paragraph per viewer, fair: lead with what each does well;
  - the disclosure `Tegel makes Tegel Markdown, one of the tested apps.`;
  - Tegel's own failures, if any;
  - a correction line: `Vendors: email hello@tegelapps.com with corrections and we'll re-test and date the update.`
  - Run the Task 1 checklist and lint.
- [ ] **Step 5: Upstream goodwill** (HR2, no promotion). For each OSS viewer that fails a case, open one issue with the minimal snippet and the screenshot, never mentioning Tegel. 🔒 each.
- [ ] **Step 6 🔒 Publish** through plan 04 on **Tue 15 Dec** (W8, the first article week). Then distribute (Task 19 checklist):
  - Hsoub I/O (Arabic summary);
  - Obsidian forum RTL thread, where on-topic;
  - HN: at most a plain link post on **Tue 12 Jan**, never Show HN (P2-19: Show HN posts on 8 Dec and 2 Feb already risk self-promotion flags). Once, no upvote ask; skip it if the 8 Dec thread drew flags.
- **Success:** ≥ 5 referring domains in 90 days (GSC Links) and ≥ 1 AI citation of this URL by the 6 Apr check (E06).

### Task 17: Directory and list submissions (C prepares, U approves each 🔒; Wed 9 Dec → Tue 9 Mar)

**Files:** Create `docs/growth/directories.md` from the table below. Each row gets `Submitted`, `URL`, `Result` and `Approved` columns.

Rules were read on 27 Oct from each primary source (repo `CONTRIBUTING.md`/README via raw.githubusercontent.com, or the site's FAQ/submit page). Rows marked UNVERIFIED are check steps.

| Target | Rule that decides it | Verdict and date |
|---|---|---|
| jaywcjlove/awesome-mac (117k★, active) | "Link additions should be added in alphabetical order"; "Create individual pull requests/issues for each suggestion"; paid apps (Marked 2, Typora) are listed | PR to "Markdown Tools" with the Native icon, not Freeware. **Tue 15 Dec** |
| iCHAIT/awesome-macOS (19k★) | "Commercial applications should offer a free trial for maintainers to validate inclusion"; no Electron | PR; offer the maintainers a review licence (single-use 100% code, 🔒) in the PR text. **Tue 12 Jan** |
| sindresorhus/quick-look-plugins (18.8k★) | Paid entries are marked 💰; the maintainer rejected immature apps ("not something I want to recommend until it's more mature and has some more users", PR #157) | PR with `### [Tegel Markdown](…) 💰`, a quoted one-liner, "Purchase on tegelapps.com" and a screenshot. **Tue 9 Mar**, only if G2 passes |
| ayub-kokabi/awesome-rtl | "must have built-in RTL support"; not only for local audiences | PR under "Text and Code Editors". **Tue 15 Dec** |
| 01walid/awesome-arabic | "just send me a Pull Request!"; has a Markdown section; commercial acceptance UNVERIFIED | PR. **Tue 15 Dec** |
| AlternativeTo | Developers may add their app and get developer access; not accepted while "Coming Soon"; "creating fake accounts to like or review your product" penalised | Add as an alternative to MacMD Viewer, QLMarkdown, MacDown and Typora; request developer access. Skip paid priority review (HR1). **Wed 9 Dec** |
| MacUpdate | Doesn't accept "Commercial applications without a downloadable demo" (the free tier is the demo); "Avoid promotional text and pricing information" | Submit with a plain description. **Wed 9 Dec** |
| SaaSHub | Accepts "Most software products and apps"; "Products that are not released yet will be rejected"; list competitors; verify with a domain email | Submit, verify with hello@tegelapps.com; no paid featured listing (HR1). **Wed 9 Dec** |
| Slant | UNVERIFIED (Cloudflare 403) | Check step: U reads the guidelines in a browser; submit only if self-listing with disclosure is allowed. **Tue 12 Jan** |
| Mac Apps Library (Peerlist) | UNVERIFIED | Check step, same as Slant. **Tue 12 Jan** |
| open-saas-directory/awesome-native-macosx-apps | Excludes "self-promoted apps (unless truly exceptional)" | **Don't self-submit**, and don't ask a user to submit it for us (HR2). Fine if a user suggests it unprompted |
| BubuAnabelas/awesome-markdown | Last push 2024-08-21; 76 open PRs | Skip: inactive |
| serhii-londar/open-source-mac-os-apps | "A curated list of open source applications" | Skip: closed source |
| macapps.link, macmenubar.com | A bulk installer (last updated 2022); "genuine macOS menu bar apps only" | Skip |
| Homebrew Cask, Setapp | [F11]; Setapp's maturity requirement | Plan 07 owns |

- [ ] **Step 1: Assets.** Name, one line (< 100 chars, no "best"), a 50-word description, the icon (512 px tile), 4 screenshots (plan 05 Task 5) and the category list. Run the Task 1 lint.
- [ ] **Step 2: One row at a time 🔒** on its date. Expected: each row's `Result` is filled within 14 days (accepted / pending / rejected + reason).
- [ ] **Step 3: Commit** after each batch (`docs(growth): directory submissions <date>` + trailer).
- **Success:** ≥ 6 accepted by Mon 8 Mar (Scoreboard).

### Task 18: Reviews, testimonials and replies (C drafts, U posts 🔒; from Tue 29 Dec, weekly)

**Files:** Create `docs/growth/reviews.md`. It has two tables:
- `| date | venue | URL | rating/sentiment | summary | reply URL | approved |`
- `| date | person (as they asked to be shown) | quote | consent (verbatim + date) | used on |`

- [ ] **Step 1: Weekly sweep** (Tuesday review). Check:
  - PH reviews; AlternativeTo comments; MacUpdate reviews;
  - Reddit/HN threads naming Tegel (HN Algolia `query=tegel`);
  - GitHub issues on our list PRs.
- [ ] **Step 2: Reply to every review publicly within 7 days** 🔒 (one approval batch per week).
  - Thank them and answer the substance.
  - For a bug: say whether it's fixed and in which version.
  - Never argue. Never offer anything in exchange for changing a review (HR4).
- [ ] **Step 3: Testimonials.** Quote only replies that contain "you may quote me" (Task 14 day-21 email) or an equivalent written yes. Use the exact name/handle they gave, never edit the meaning, and record the consent text and date. Plan 04 shows ≤ 3 quotes on the product page from Mon 8 Feb onwards (coordination).
- [ ] **Step 4: Refund reasons.** Every refund reply goes in the table. The Task 5 trigger reads this.
- **Success:** ≥ 10 public reviews by 8 Mar; ≥ 25 by 30 Apr (Setapp's "public reviews" requirement, plan 07).

### Task 19: Content distribution and brand accounts (C drafts, U posts 🔒; W3 → month 12)

**Files:** Create `docs/growth/distribution.md`. It holds the community-rules table, the per-article checklist and the log.

- [ ] **Step 1: Community rules table.** One row per venue: rule quote, URL, date read, max frequency, disclosure wording.
  - **Verified 27 Oct:**
    - **HN:** "Please don't use HN primarily for promotion"; "It's ok to post your own stuff part of the time"; "Don't solicit upvotes, comments, or submissions" (news.ycombinator.com/newsguidelines.html).
    - **Hsoub I/O:** quotes in Task 10.
    - **Virgool:** purely promotional or commercial posts made for link building "مصداقِ هرزنامه است" (count as spam; virgool.io/terms).
    - **r/ObsidianMD:** "Promotional content must also be relevant to Obsidian … paid content will always receive additional scrutiny" (obsidian.md/help/community-code-of-conduct).
    - **dev.to:** `canonical_url` front matter "link for the canonical version of the content" (dev.to/p/editor_guide).
  - **UNVERIFIED, check steps before the first post:**
    - r/Markdown, r/MacOS, r/mac and r/ClaudeAI: Reddit blocks scripts, so U reads each sidebar logged in and pastes the self-promotion rule;
    - Hashnode's "Add Original URL" (official docs returned 404/500; seen in a search snippet only).
- [ ] **Step 2: Per-article checklist,** run for each plan 04 article (2/week from W8):
  1. Task 1 checklist passed.
  2. Brand posts (Bluesky, Mastodon; X if chosen): one post, plain text plus one real screenshot or a ≤ 8 s silent clip, at most 2 hashtags.
  3. Cross-posting, for technical how-to articles only, ≤ 1/week:
     - dev.to with `canonical_url: <tegelapps URL>`;
     - Hashnode with Original URL, only after the Step 1 check.
  4. Communities: only where the article answers a question being asked there now, ≤ 1 self-post per community per 30 days, with the disclosure line. RTL articles also go to Hsoub I/O / Virgool as full translated articles, not bare links.
  5. HN: only original-data pieces (Task 16), at most 1 per quarter.
  6. Log: date, venue, URL, approval, and the article's page requests over 7 days (kpi `cf_counts` for that path).
- [ ] **Step 3: Brand accounts 🔒** (U creates them; open question 2).
  - Name `Tegel Apps`, handle `tegelapps` (or the nearest free one); avatar = the tile; bio `Native, read-only Mac apps. Made in the Netherlands.`
  - No face anywhere (HR6). Credentials go in `.env` (names in `.env.example`).
  - Mastodon instance: one that allows commercial project accounts. Check the instance rules before signing up; Fosstodon is FOSS-only, so not that one.
- [ ] **Step 4: Silent clips** from plan 05's demo: `"$FF" -ss <start> -t 8 -i site/static/media/tegel-markdown-demo.mp4 -an -vf "fps=24,scale=1080:-2" -c:v libx264 -crf 24 -pix_fmt yuv420p -movflags +faststart docs/growth/clips/<name>.mp4`. Each clip passes the Task 1 `ffprobe` audio check (empty output).
- [ ] **Step 5: Localised timing** for RTL communities. Post Sunday to Wednesday at 10:00 local time (the weekend is Fri–Sat in most Arabic-speaking countries and in Israel, and Friday in Iran). No tie-in with Ramadan, Eid, Nowruz or Jewish holidays (HR8, HR9). Never frame the apps for inburgering or immigration (HR7).
- [ ] **Step 6: Commit** the log weekly (`docs(growth): distribution log week N` + trailer).

### Task 20: Partnerships and RTL-language outreach (C researches and drafts, U sends 🔒; W8 → month 12)

**Files:** Create `docs/growth/partners.md`. It holds the target list (≥ 20), templates and the log.

**Rules:**
- Editorial only, never paid placement (HR1).
- ≤ 5 sends a week; one follow-up after 7 days, then never again.
- A complimentary licence for a writer is offered only as a review copy, with no obligation to cover or rate the app (HR4). Writers follow their own disclosure policy.

- [ ] **Step 1: Build the list** (by Tue 22 Dec). Verify each target's submission or contact rule from its own page, and record the URL and date. Candidates (the plan names categories; Step 1 verifies names):
  - **Markdown/RTL tool authors:** obsidian-rtl (esm7), QLMarkdown (sbarex), MarkEdit. Offer: the Task 16 test cases and issues (goodwill, no ask).
  - **Arabic tech writers and sites:** e.g. aitnews.com, tech-wd.com; Hebrew: e.g. geektime.co.il; Persian: e.g. zoomit.ir. Pitch: an RTL-correct Markdown reader and the Task 16 data.
  - **Developer-tool newsletters that take free editorial submissions** (e.g. Console.dev): verify that the submission is free.
  - **Claude Code / Codex community newsletters and lists** for App 2 (research at W13, send W15).
  - **Setapp timing:** plan 07 owns the application. This plan delivers its preconditions: the Task 18 review count, and the release history from plans 05/07.
- [ ] **Step 2: Templates.**

```text
WRITER PITCH — Subject: An RTL-correct Markdown reader for Mac (and a test of 9 viewers)
Hi <name>, I'm <sign-off>, a solo developer in the Netherlands. I tested how 9 Markdown viewers on macOS handle Arabic, Hebrew, Persian and Urdu: <article URL> (method and screenshots included; I make one of the tested apps, Tegel Markdown, and say so in the piece). If it's useful for <publication>, the data is free to cite. Happy to send a review licence for Tegel Markdown, with no obligation to write about it.

TOOL AUTHOR — Subject: RTL test cases for <project>
Hi <name>, while testing right-to-left Markdown I found <case> renders <result> in <project> <version> (screenshot + minimal file attached). Sharing in case it's useful; no reply needed.
```

  Arabic, Hebrew and Persian versions are drafted by C; U reviews the Arabic. Hebrew and Persian go out only if a reviewer is available, otherwise in English.
- [ ] **Step 3: Sends 🔒,** logged: date, target, response, resulting mention URL.
- **Success:** ≥ 3 independent mentions (articles, newsletters or lists not submitted by us) by Fri 30 Apr. These also unlock the quick-look-plugins PR (Task 17).

### Task 21: App 2 positioning and launch growth kit (C; Tue 22 Dec, Tue 26 Jan – Tue 2 Feb)

- [ ] **Step 1: VOC for App 2** (Tue 15 – Tue 22 Dec). Same method as Task 2. Repos and searches:
  - GitHub issues mentioning `.jsonl` viewing, `claude code transcript`, `codex sessions`;
  - HN/Reddit threads on reading Claude Code session logs;
  - qlstephen and Glance issues (the "broken on macOS 15" pain).

  Expected: ≥ 30 quotes appended to `voice-of-customer.md` under `## App 2`.
- [ ] **Step 2: Positioning for App 2** in `positioning.md` (Tue 22 Dec): ICP, JTBD, promise, 3 proof points, objections and the message table, as in Task 3. 🔒 U approves.
  - **Coordination:** plan 06's re-validation (W9) and its site/launch copy use it.
- [ ] **Step 3: Kit** (Tue 26 Jan – Mon 1 Feb):
  - the App 2 emails (Task 15 Step 2; the cross-sell copy is plan 06's);
  - the App 2 answer blocks (Task 13 format: "jsonl viewer mac", "view claude code transcripts", "yaml quick look mac");
  - directory rows for App 2 (Task 17 targets that list data viewers);
  - r/macapps: next promotion allowed ≥ 7 Jan, so 2 Feb is fine (plan 05 Task 8).
- **Success:** E13. Cross-sell sales ÷ emails sent are recorded on Tue 16 Feb, and App 2's ≥ 10 sales by Thu 4 Mar (BUSINESS-PLAN §12) are tracked in the weekly report.

### Task 22: Months 5–12 cadence and gate inputs (C + U; Mar – Oct 2027)

- [ ] **Step 1: Standing routines.**
  - weekly review (Task 5);
  - monthly AI check (Task 13);
  - monthly ICE re-score;
  - per-article distribution (Task 19);
  - review replies (Task 18);
  - daily buyer sync (Task 14), with `--product data` from 2 Feb.
- [ ] **Step 2: Gate inputs.** Three working days before each gate (G2 Mon 8 Mar, G3 Fri 30 Apr, G4 Fri 29 Oct 2027), write `## Growth inputs to G<n>` in `docs/growth/experiments.md`. It holds:
  - the Scoreboard values;
  - what worked (sales by ref and by channel);
  - what didn't (null experiments);
  - the honest forecast vs the BUSINESS-PLAN central case.

  Plan 07 records the gate decision. This plan only supplies the evidence.
- [ ] **Step 3: Quarterly re-plan** (first Tuesday of Feb, May, Aug). Drop every channel with zero attributable sales or sign-ups in its last 90 days (karpathy: no vanity work), and move its hours to the best ICE item.
- [ ] **Step 4: Seasonal timing** (HR8, neutral). The macOS 28 release (September 2027): one article on Quick Look and Markdown changes in macOS 28, published within 7 days of release (plan 04 slot), after the June beta re-test (plan 07).
- [ ] **Step 5: Plan close** (Fri 29 Oct 2027). Write a final `## Close` in `experiments.md`: every Scoreboard row's final value, then run Task 23 Step 10.

### Task 23: 9-stage review pipeline for this plan's code → `docs/reviews/m08.md`

**When:** before merging each code branch: `m08-kpi` (Task 4), `m08-waitlist` (7–8), `m08-rtl-tool` (9), `m08-onboarding` (11, only with a fix), `m08-upsell` (12), `m08-lifecycle` (14). The code ships months apart, so one end-of-plan run would review November code in October 2027. Each run appends `## <branch>` to `docs/reviews/m08.md`.

- [ ] **Step 1: Stage 1, bloat audit (pre).** `base=$(git merge-base HEAD main); git diff --stat $base...HEAD`. Apply `~/.claude/skills/code-upgrade/bloat-audit.md` to the diff and touched files; strip self-introduced bloat; queue pre-existing findings for U.
- [ ] **Step 2: Stage 2, baseline.**
  - Run `git status --short` (clean), then `make check`.
  - Run `python3 -m unittest discover -s scripts -p 'test_*.py'`, `bun test site/functions site/tools` and `swift test --package-path Packages/TegelKit`.
  - Record the pass/fail counts.
- [ ] **Step 3: Stage 3, code review.** gstack `/review` (or a cold code-review subagent) on `git diff $base...HEAD`: bugs, security, correctness.
- [ ] **Step 4: Stage 4, `/cso`**, scoped per branch:
  - **`m08-waitlist`:** the form and function, which are a public endpoint. Check:
    - Origin/Content-Type/size order;
    - no PII in logs or responses;
    - the secret only in Pages env;
    - the rate-limit rule present;
    - the MailerLite token scope;
    - the header-injection test case.
  - **`m08-kpi` and `m08-lifecycle`:** tokens. Check:
    - read from env only and never printed (`python3 scripts/kpi.py … 2>&1 | grep -ciE 'bearer|polar_(pat|oat)_'` → `0`);
    - HTTPS only;
    - MailerLite writes limited to group membership;
    - emails never printed.
  - **`m08-rtl-tool`:** sanitisation reuse (`SANITIZE_CONFIG` plus `addHooks(DOMPurify)`, `RETURN_DOM_FRAGMENT` into `replaceChildren`), plan 04's `/tools/*` and `/:lang/tools/*` CSP blocks in `site/static/_headers` (`! Content-Security-Policy`, `connect-src 'none'`), the hostile fixture, and that no `innerHTML` takes unsanitised input.
  - **`m08-upsell`:** the TegelStore change (licensing). Check:
    - `checkoutURL(ref:)` can't be steered to another host;
    - the temp PDF is deleted;
    - no key in logs.
  - **`m08-onboarding`** (only if Task 11 needed a fix): the external URL scheme and any strings change.
  - **Every branch:** `git log -p $base..HEAD | grep -nE 'polar_(pat|oat)_[A-Za-z0-9]{8,}|mlsn\.|eyJ[A-Za-z0-9_-]{20,}|PRIVATE KEY'` → no output.
- [ ] **Step 5: Stage 5, adversarial challenge.** `/codex` challenge mode on the diff. Ask it: "How does this mislead a buyer, email someone who didn't consent, leak data or break the halal guardrails?"
- [ ] **Step 6: Stage 6, consolidate.** Merge and dedupe the findings and classify them P0/P1/P2 in `m08.md`.
- [ ] **Step 7: Stage 7, patch and re-review.** Fix every P0/P1 and the actionable P2s with TDD, then re-run the Step 2 commands. Expected: no regression against the baseline.
- [ ] **Step 8: Stage 8, bloat audit (post)** over the final cumulative diff.
- [ ] **Step 9: Stage 9.** `/review`, then `cubic review -b $base -j` (key `issues`). Repeat until **two consecutive rounds show no new P0/P1**. If a stage can't run, write which stage, why, and what ran instead.
- [ ] **Step 10: Merge and record.**
  - `git add docs/reviews/m08.md && git commit -m "docs(reviews): m08 <branch> pipeline results" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`;
  - `git switch main && git merge --no-ff <branch>`, then `git push origin main` (D14) and `graphify update .`.
  - At plan close (Task 22 Step 5), add `## Close`: the list of branches with their pipeline dates, and confirm no code merged without a section. Expected: `grep -c '^## m08-' docs/reviews/m08.md` → `5`, or `6` if Task 11 needed an `m08-onboarding` fix.

---

## Self-review notes

- **Brief coverage:**
  - halal check (T1); buyer research + positioning (T2, T3, T21);
  - KPI + review + triggers + ICE + pricing stance (T4, T5);
  - waitlist (T6–T8, T10, T15); free tool (T9); in-app conversion (T12) + the Welcome deep link and copy (T11);
  - AI search (T13); lifecycle email (T14, T15); RTL benchmark (T16); directories (T17);
  - reviews (T18); distribution + localisation (T19, T20); partnerships (T20); months 5–12 (T22); pipeline (T23).
- **Verified 27 Oct (primary):**
  - Polar checkout-link params and Order/Checkout schemas; MailerLite Free limits, API fields, double opt-in and anti-spam policy;
  - Tw 11.7 lid 1/4/7; Cloudflare Pages Functions, pricing, rate limiting and GraphQL limits;
  - the macOS 15.7.7 Settings plist; llmstxt.org; HN guidelines;
  - list and directory rules (T17 table); Hsoub, Virgool and Obsidian codes; dev.to canonical.
- **Check steps (unverified):**
  - whether `reference_id` reaches Order `metadata` (T4 S1);
  - whether `httpRequestsAdaptiveGroups` is on Free (T4 S2);
  - the MailerLite tracking toggle (T6 S4), lookup by email and unsubscribe-safe upsert (T14 S1);
  - the deep link on 14/26/27 (T11 S2);
  - Reddit sidebars, Slant, Mac Apps Library, Hashnode (T17, T19);
  - the GSC `Chart.csv` headers (first export).

## Contract change requests

1. **§3.1 layout, additive:** `docs/growth/`, `site/functions/api/`, `site/tools/`, `site/static/llms.txt`, `scripts/kpi.py`, `scripts/sync_buyers.py` and their tests.
2. **§3.3 Swift API, additive:**
   - `TegelKit.QuickLookSetup` (`settingsURL`, `SettingsPath`, `settingsPath(macOSMajor:)`);
   - `TegelStore.UpsellFeature`, `TegelStore.UpsellPolicy`;
   - `PolarConfig.checkoutURL(ref:)`.

   The MAS target (plan 07) drops TegelStore, and with it the upsell.

   **Status:** accepted-modified (X11, X12). Plan 02 Task 15 builds `QuickLookSetup` for its Welcome window. Plan 02 declares `UpsellFeature` in the app (TegelStore arrives with plan 03) as the `pro` window's value, so it is `String, Codable, Hashable`; Task 12 moves it into TegelStore next to `UpsellPolicy`, keeping those conformances (master §3.3).
3. **§3.2 renderer (plan 01):** move the DOMPurify options into `Renderer/src/sanitize.js`, exporting `SANITIZE_CONFIG`, imported by `page.js`. Task 9 reuses it, so the site tool and the app sanitise identically. **Status:** accepted, done in plan 01 Step 7 (X8): `SANITIZE_CONFIG` plus `addHooks(purify, { fileImages = false } = {})`; the tool calls `addHooks(DOMPurify)`.
4. **Plan 04 build/deploy:**
   - (a) bundle `site/tools/*/main.js` into `site/public/tools/*/`, and render pages with front matter `tool: <name>` using `tool.html` and a page CSP with `connect-src 'none'`;
   - (b) deploy so `site/functions/` is uploaded (run from `site/`);
   - (c) the site tests allow same-origin scripts only under `/tools/`;
   - (d) include `partials/waitlist-form.html` on the home and RTL pages until 2 Feb 2027;
   - (e) every checkout link carries `?reference_id=site-<slug>`;
   - (f) `robots.txt` allows the AI crawlers in Task 13 Step 3.

   **Status:** (a)–(c) are done in plan 04 (X9). The tool CSP is the `/tools/*` and `/:lang/tools/*` blocks in `site/static/_headers` (`! Content-Security-Policy` detaches the global policy), not a page meta tag. (f) is a no-op: `robots.txt` already allows all.
5. **Plan 04 schedule:** the privacy page (with the Task 8 Step 4 text and the MailerLite DPA) goes **live by Mon 16 Nov**, before the waitlist, instead of with the W5 legal pages.
6. **Plan 05 Task 2 Step 5:** the custom field label becomes `Don't email me set-up tips or news about Tegel apps`. The key stays `no_marketing`, so the soft-opt-in objection at collection covers the lifecycle emails (Tw 11.7 lid 4a).
7. **Plan 05 operations:**
   - Task 9 runbook gets a row at 09:30 for U 🔒 "Send the waitlist launch email (plan 08 Task 15)";
   - the Task 4 daily routine runs `sync_buyers.py`;
   - the Task 3 R2 row records the Quick Look deep-link landing on `m27-arm`/`m14-arm`;
   - if T4 S1 shows the ref only on checkouts, the production token adds `checkouts:read` (🔒).
8. **Master §6 accounts:**
   - MailerLite moves to **W2** (waitlist + lifecycle), not W13;
   - add the Bluesky/Mastodon(/X) brand accounts (U-created, faceless);
   - add a Cloudflare API token `CLOUDFLARE_ANALYTICS_TOKEN`.
9. **`.env.example`:** add `MAILERLITE_API_TOKEN`, `MAILERLITE_GROUP_WAITLIST`, `MAILERLITE_GROUP_BUYERS_MARKDOWN`, `MAILERLITE_GROUP_BUYERS_DATA`, `CLOUDFLARE_ANALYTICS_TOKEN`, `CLOUDFLARE_ZONE_ID` (+ the brand-account keys).
10. **`make check`:** plan 08 only makes `test-site` run `bun test site/functions site/tools`. The Python tests (`test_kpi.py`, `test_sync_buyers.py`) run under plan 05's `test-scripts` target (X21).
11. **Brief deviation:** the KPI script is `scripts/kpi.py`, not `kpi.ts`, so it imports plan 05's `polar_sales.py` instead of porting it.
12. **Plan 06:** its "cross-sell email to App 1 buyers" exit item is delivered by Task 15 Step 2. Plan 06 Task 15 supplies the copy (`docs/launch/data-crosssell-email.md`) and the segment rule; plan 08 owns MailerLite and the send (P1-10).
