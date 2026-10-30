# Milestone 08: Growth engine, implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Tegel's apps find their buyers, from W1 (Tue 27 Oct 2026) to G4 (Fri 29 Oct 2027), and hit the master §12 stretch targets without breaking a halal guardrail.

**Architecture:** Mostly research, copy and operating routines. Five small pieces of code, each built because a step repeats or a number has to be counted:
- `site/functions/api/waitlist.js`: a same-origin Cloudflare Pages Function that turns a plain HTML form POST into a MailerLite double-opt-in subscriber. No third-party script on any page.
- `site/tools/rtl-markdown-check/`: a free, client-side RTL Markdown checker that reuses `Renderer/src`. It has no PDF export and no network access.
- `scripts/kpi.py`: the weekly funnel report. It imports plan 05's `scripts/polar_sales.py` instead of re-implementing Polar paging.
- `scripts/sync_buyers.py`: a daily, idempotent reconciliation of buyers who ticked the checkout opt-in into a MailerLite group (K9).
- One `TegelStore` addition (`PolarConfig.checkoutURL(ref:)`) and app-side upsell state for the in-app upgrade moments (K18). The Quick Look guide is plan 02's Welcome window, built on plan 02's `TegelKit.QuickLookSetup` (X11); this plan verifies its deep link and reviews its copy.

Everything else lives in files under `docs/growth/`, and every outward-facing action is its own step marked 🔒.

**Tech stack:**
- bun (`bun test`) for the site function and the tool.
- python3 stdlib (`urllib`, `csv`, `unittest`) for the scripts, the same as plan 05.
- Swift 6 / Swift Testing in `Packages/TegelKit`.
- MailerLite (free plan), Polar API, Cloudflare Web Analytics (dashboard, already on via plan 04) and Workers KV, Google Search Console CSV export, ffmpeg.

**Spec:** `BUSINESS-PLAN.md` §2–§5, §8, §9, §12–§14. **Contract:** `docs/superpowers/plans/2026-10-27-00-master-roadmap.md` (§3 names, §4–§7, D6, D7, D9, D15, §12). **Rules:** `CLAUDE.md`. **Siblings:** plan 05 (`2026-10-27-05-release-readiness-launch.md`) owns the launch kit, launch-day runbook, support, the price change and G1. This plan cites plan 05's task numbers and does not repeat them. Plan 04 (`2026-10-27-04-site-seo.md`) owns the site build, the SEO landing pages, the legal pages and the W8–W20 article calendar. Plans 02/03 own the ProGate seam, the Pro window (`ProUpsellView` in the `pro` window, never a sheet), the Welcome window with `QuickLookSetup`, and the licence UI. This plan owns MailerLite (account from W2) and every send to the waitlist and buyer groups, including App 2's cross-sell; plan 06 supplies that email's copy and segment rule. Plan 06 owns App 2 and plan 07 owns post-launch scale. Plan 04 was not yet written when this plan was; every reference to it names a scope, not a task number.

**Branches:**
- Code goes on `m08-<topic>` (`m08-kpi`, `m08-waitlist`, `m08-rtl-tool`, `m08-onboarding`, `m08-upsell`, `m08-lifecycle`).
- Each code branch is merged only after Task 23's pipeline (D14).
- Docs-only tasks commit straight to `main`, following plan 05's Part B precedent.

## Global constraints

Master §2/§3 and `CLAUDE.md` apply (product rules 1–9, design standard, approvals for outward-facing actions, secrets named by `.env` key only). Plan-specific:

- **Halal guardrails.** Every tactic cites a row of master §12's halal table. The rows are numbered top to bottom:
  - **HR1:** SEO, AI search, free tools and fair, dated, sourced comparisons, *not* paid ads of any kind (including paid newsletter slots, "featured" directory listings and paid priority queues).
  - **HR2:** launch posts, disclosed community answers and list/directory submissions, *not* astroturfing, sock puppets or undisclosed self-promotion.
  - **HR3:** a dated introductory price, a real bundle price and an honest upgrade price, *not* fake "was" prices, resetting countdowns or fake scarcity.
  - **HR4:** asking for reviews and testimonials with no reward, *not* incentivised or fabricated reviews.
  - **HR5:** a disclosed affiliate or referral commission, *not* giveaways by draw, "spin to win" or raffles.
  - **HR6:** silent captioned demos and text/diagram visuals, *not* music, jingles, faces, figures, animals or mascots.
  - **HR7:** an email waitlist with consent, and buyer email only to buyers who ticked the checkout opt-in (K9), *not* bought lists, mail without consent, or inburgering/immigration framing.
  - **HR8:** neutral seasonal timing, *not* Christmas, holiday or other-religion theming. This includes Black Friday (27 Nov), Cyber Monday (30 Nov), Nowruz and Hanukkah tie-ins.
  - **HR9:** Arabic/RTL as a language feature, *not* Islamic-themed marketing. That means no Ramadan or Eid tie-ins, and no Qur'an or hadith as sample text.
- **Price wording.** Before 15 Dec, the wording is verbatim: `Introductory price $14 until Mon 14 Dec 2026 23:59 CET. From 15 Dec: $19.` (plan 05 Global Constraints). EU-language copy uses the same sentence in € through plan 04's `{{pricing:…}}` placeholder (K10). The apps never show a price (plan 05 Task 3 Step 1).
- **Approvals:** every post, email, submission, reply, account creation and live DNS change is a 🔒 step; each records `Approved: <date>, user`.
- **Email law (NL).** Primary source: Telecommunicatiewet art. 11.7, the version in force from 15-08-2026, read at wetten.overheid.nl/BWBR0009950/2026-08-15 on 27 Oct 2026.
  - *Lid 1:* commercial email needs prior consent the sender "kan aantonen" (can prove). Double opt-in is the proof.
  - *Lid 4* (soft opt-in) is **not relied on**: buyers get email only after ticking plan 05's unticked opt-in box, which is consent under lid 1 (K9).
  - *Lid 7:* every message states "de werkelijke identiteit" of the sender and "een geldig postadres of nummer" for opt-out requests.
- **Budget:** €0 of new cash. MailerLite Free covers 250 subscribers, 2,500 emails/month and 3 active automations of 5 steps each (mailerlite.com/pricing, read 27 Oct 2026). Any spend is a purchase that needs approval.
- **New `.env` keys:**
  - `MAILERLITE_API_TOKEN` (local scripts only) and `MAILERLITE_API_TOKEN_PAGES` (the Pages secret only): two tokens, so either can be revoked alone (K8, S18);
  - `MAILERLITE_GROUP_WAITLIST`, `MAILERLITE_GROUP_BUYERS_MARKDOWN`, `MAILERLITE_GROUP_BUYERS_DATA`;
  - `CLOUDFLARE_KV_WAITLIST_ID` and `CLOUDFLARE_KV_WAITLIST_PREVIEW_ID` (the production and preview KV namespace ids; not secret).
- **Evidence honesty:** every number in `docs/growth/` names its source and date. Counts that include bots or updates say so.
- **Owners:** **C** = Claude, **U** = the user.
- **Commits:** "Commit: `<paths>`, `<msg>` + trailer" means `git add <paths> && git commit -m "<msg>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`. Explicit paths, never `-A` (B2).

## Review focus

1. **Subscription bombing through the waitlist.** A script posts strangers' addresses, and each one gets a confirmation mail. Expected:
   - a foreign `Host` (anything but `tegelapps.com`/`www.tegelapps.com` in production, so `*.pages.dev` too) or `Origin` gets 403;
   - a filled honeypot sends nothing;
   - past 3 sign-ups a day from one client IP (KV, hashed), past the global daily cap (KV), or for an address already posted in the last 24 h (KV cooldown), the function returns its "try later" or "check your email" page **without calling MailerLite**; a KV error fails closed;
   - a body over 2,048 bytes gets 413 before it is read in full, with or without `Content-Length`;
   - more than 5 POSTs in 10 s from one IP get 429 (the Cloudflare Free rate-limiting rule: 1 rule, counted by IP, 10 s period, path matching, per developers.cloudflare.com/waf/rate-limiting-rules).

   *(Task 7 tests; Task 8 Step 6.)*
2. **Consent leakage.** A buyer who didn't tick the opt-in, was refunded, or unsubscribed still gets a lifecycle email. Expected: never.
   - The sync adds only `marketing_opt_in == true` (K9).
   - The sync reconciles every order since launch each day, so a refund on day 13 still removes the buyer, and the removal cancels queued sends.
   - A buyer whose data was erased on request is never re-created by the next sync (K10).
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
| Free tool | GSC impressions on the tool page / 30 d | ≥ 500 | Mon 8 Mar | GSC `Pages.csv` (`kpi.py`, `TOOL_PAGES`) |
| SEO | GSC impressions / 30 d | ≥ 10,000 | Mon 8 Mar (G2) | GSC CSV |
| AI search | prompts where Tegel is cited at least once in n runs | ≥ 2 of 6 by G2; ≥ 4 of 6 by G4 | 8 Mar / 29 Oct 2027 | `docs/growth/ai-visibility.md` |
| Directories | accepted listings | ≥ 6 | Mon 8 Mar | `docs/growth/directories.md` |
| Reviews | public reviews (all venues) | ≥ 10 by G2; ≥ 25 by G3 (Setapp precondition, plan 07) | 8 Mar / 30 Apr | `docs/growth/reviews.md` |
| Revenue | net / month, both apps (`summarise`, per currency, EUR at the ECB rate) | ≥ €760 (G3); ≥ €1,450 (G4) | 30 Apr / 29 Oct 2027 | `kpi.py` |
| Always | visit → sale; refund rate | ≥ 1%; ≤ 5% | rolling 30 d | `kpi.py` |
| Traffic | qualified visits per window (below) | G1 ≥ 2,100; G2 ≥ 1,700 / 30 d | 7 Jan / 8 Mar | Web Analytics → `kpi.py --visits` |

## Channel mix to the sales targets (K16)

The sales targets hold only if enough qualified visitors arrive. With this plan's own rates (visit → sale 1%, the §4 test; GSC CTR 2–4%; ≥ 30% of sales from in-app moments; waitlist central ≈ 60):

| Gate window | Sales | In-app (30%) | From site visits at 1% | Qualified visits needed |
|---|---|---|---|---|
| G1 pass, 8 Dec – 7 Jan | 30 | 9 | 21 | 2,100 |
| G1 stretch | 47 | 14 | 33 | 3,300 |
| G2, the 30 days to 8 Mar | 25 | 8 | 17 | 1,700 |

- **G1:** search brings little in a site's first two months; at most ≈ 200 clicks (the G2 stretch rate). The waitlist adds ≤ 60 visits. So ≈ 1,850–3,050 visits must come from the launch posts (PH, Show HN, r/macapps, IH; plan 05) and the launch-week directories (Task 17). No source gives their visit counts for a launch like this; they're measured from 8 Dec, not assumed.
- **G2:** 10,000 impressions × 2–4% CTR = 200–400 clicks = 2–4 sales at 1%. **SEO alone can't reach G2's 25.** The other ≈ 1,300–1,500 visits per 30 days must come from App 2's launch on 2 Feb (cross-links), directories, AI citations (Task 13), the free tool (Task 9) and distribution (Task 19), or the conversion must run well above 1%.
- **Re-plan checkpoint** (the one trigger kept from the old backlog, B5): at each weekly review, if qualified visits over the last 14 days are under half the window's need (G1: < 1,050 by Tue 22 Dec; G2: < 850 in any 14 days from Mon 8 Feb), or visit → sale is < 0.5% with ≥ 1,000 visits, write a re-plan in that week's KPI file (channels kept, dropped and added, each within HR1–HR9). The user approves it before any new feature or channel work, and plan 07's MIDDLE branch adds no scope without traffic and sales at pace.
- **Qualified visits** = Cloudflare Web Analytics visits to the product, pricing and download pages, read from the dashboard each week (bots excluded by Web Analytics). Tool pages are left out because plan 04's `/tools/*` CSP blocks the beacon by design. Tool traffic is read from GSC clicks on the tool URL, and the tool's CTA leads to `/markdown/`, which is counted.

## File map

| Path | Task | Responsibility |
|---|---|---|
| `docs/growth/halal-checklist.md` | 1 | Gate every outward artefact |
| `docs/growth/voice-of-customer.md` | 2 | Buyer quotes with links |
| `docs/growth/positioning.md` | 3, 21 | ICP, JTBD, promise, proof, objections, per-channel messages |
| `scripts/kpi.py`, `scripts/test_kpi.py`, `docs/growth/kpi/<ISO-week>.md`, `docs/growth/kpi/gsc/` | 4 | Weekly funnel report |
| `docs/growth/experiments.md` | 5 | Ref ids, review ritual, triggers, pricing stance |
| `site/functions/api/waitlist.js`, `site/test/functions/waitlist.test.js` (tests never under `functions/`, K8) | 7 | Form POST → MailerLite |
| `site/templates/partials/waitlist-form.html`, `site/content/{en,ar}/waitlist/*.md` (incl. `later`) | 8 | Form markup and result pages |
| `docs/growth/email-copy.md` | 8, 14, 15, 21 | Every email, with approval lines |
| `site/tools/rtl-markdown-check/{analyze.js,analyze.test.js,main.js,tool.html}`, `site/content/{en,ar}/tools/rtl-markdown-check.md` | 9 | Free tool |
| `docs/growth/evidence/ql-deeplink-*.png`, `docs/growth/onboarding-copy.md` | 11 | Deep-link evidence and copy review for plan 02's Welcome window (plan 02 Task 15) |
| `Packages/TegelKit/Sources/TegelStore/CheckoutLink.swift`, `…/Tests/TegelStoreTests/CheckoutLinkTests.swift`, plan 02's `ProUpsellView.swift` (with `UpsellFeature` and `UpsellContext`), `Apps/Markdown/AppTests/UpsellContextTests.swift`, the `pro` window and its call sites | 12 | Upgrade moments + checkout refs |
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
      - recipients are confirmed waitlist members or buyers who ticked the checkout opt-in (both lid 1; K9);
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
- [ ] **Step 4: Commit:** `docs/growth/halal-checklist.md`, `docs(growth): halal checklist and copy lint for outward artefacts` + trailer.

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

**Files:** Create `scripts/kpi.py`, `scripts/test_kpi.py`, `docs/growth/kpi/gsc/.gitkeep`. Step 8 (on a branch cut from `m05-launch`, K11): modify `scripts/polar_sales.py`, `scripts/test_polar_sales.py`, `scripts/kpi.py` and `scripts/test_kpi.py`.

**Interfaces:**
- **Consumes:** `polar_sales.fetch_orders(token, org_id, product_id, after, before) -> list[dict]`, `count_sales(orders, product_id) -> dict`, `window(start, end) -> (str, str)` (plan 05 Task 6).
- **Order (K11):** plan 05 Task 6 writes `polar_sales.py` on `m05-launch` on Tue 1 Dec, and `m05-launch` reaches `main` only on Mon 7 Dec (plan 05 Task 10 Step 3). So Steps 1–7 (November, branched from `main`) never import it, and its counting rule is never copied here: the Polar rows print `n/a (polar_sales.py not merged)`. Everything that calls it (`sales_by_ref`, the Polar rows, `summarise`) is Step 8, on a branch cut from `m05-launch` after Task 6's commit.
- **Produces:**
  - `REF_KEY = "reference_id"`: the Order `metadata` key, confirmed in Step 1.
  - `iso_week(d: date) -> str`, e.g. `"2026-W46"`.
  - `week_bounds(week: str) -> tuple[date, date]`: Monday to the next Monday.
  - `gsc_totals(f: TextIO, start: date, end: date) -> dict[str, int]`: keys `clicks`, `impressions`; reads GSC `Chart.csv` columns `Date`, `Clicks`, `Impressions`; `end` is exclusive.
  - `gsc_pages(f: TextIO, paths: set[str]) -> dict[str, int]` (K9): keys `clicks`, `impressions`, summed over the rows of the same export's `Pages.csv` (first column the page URL, then `Clicks`, `Impressions`) whose URL path is in `paths`. `TOOL_PAGES = {"/tools/rtl-markdown-check/", "/ar/tools/rtl-markdown-check/"}`; `RTL_PAGES` = plan 04's W5 RTL landing pages (`/arabic-markdown-pdf-mac/`, `/nl/rtl-markdown-naar-pdf/`, `/fr/markdown-rtl-en-pdf/`, `/ar/arabic-markdown-pdf/`).
  - `sales_by_ref(orders: list[dict], product_id: str) -> dict[str, int]` (Step 8): same inclusion rule as `count_sales["sales"]`, keyed by `metadata[REF_KEY]` or `"none"`. It groups the orders by ref and calls `count_sales` on each group, so the rule lives only in `polar_sales.py`.
  - `summarise(orders, product_ids: set[str]) -> {"count": int, "gross": {currency: float}, "net": {currency: float}}`, added to **`polar_sales.py`** in Step 8 (B8: one net formula, which plan 07's gates also use). It counts exactly what `count_sales` counts as sales; `gross = Σ(total_amount − refunded_amount)/100` and `net = Σ(net_amount − (refunded_amount − refunded_tax_amount))/100` under the order's `currency` (K10), minus each `platform_fee_amount/100` under that order's `platform_fee_currency` (K21: a separate Order field, polar.sh/docs/api-reference/orders/get.md; a fee in another currency becomes a negative entry in that currency, converted at the ECB rate with the rest), rounded to cents.
  - `pace(actual: int, elapsed_days: int, window_days: int) -> int`
  - `status(actual: float, target: float, pass_mark: float | None) -> str` ∈ `"stretch met"`, `"pass, below stretch"`, `"below pass"`, `"below stretch"`.
  - `render_report(week: str, rows: list[tuple[str, str, str]], targets: list[tuple[str, str, str]]) -> str`
  - CLI: `python3 scripts/kpi.py --week 2026-W46 [--gsc docs/growth/kpi/gsc/2026-W46/Chart.csv] [--visits <n>]` (`Pages.csv` is read from the same folder) writes `docs/growth/kpi/2026-W46.md` and prints its path. `--visits` is the week's qualified visits, read from the Cloudflare Web Analytics dashboard (B4: no second visit counter).
  - The **KPI command** (K1; Task 5 reuses it):

    ```bash
    . scripts/lib/env.sh && POLAR_ACCESS_TOKEN="$(envget POLAR_ACCESS_TOKEN)" POLAR_ORGANIZATION_ID="$(envget POLAR_ORGANIZATION_ID)" \
      POLAR_PRODUCT_ID_MARKDOWN="$(envget POLAR_PRODUCT_ID_MARKDOWN)" MAILERLITE_API_TOKEN="$(envget MAILERLITE_API_TOKEN)" \
      MAILERLITE_GROUP_WAITLIST="$(envget MAILERLITE_GROUP_WAITLIST)" python3 scripts/kpi.py --week <week> --gsc <csv> --visits <n>
    ```
  - A missing key or file gives the row `n/a (missing <KEY>)`, never a crash. No secret or email address is ever printed.
  - One counter for every report and gate (X22): Polar numbers come only from `polar_sales.py`, and plan 07 G1 reads GSC through `gsc_totals`, so importing `kpi` must have no side effects (CLI under `if __name__ == "__main__":`).

- [ ] **Step 1: Attribution check in the Polar sandbox** (no approval needed).
  - In the sandbox org (H5), make a $1 test product and a checkout link. Open `<link>?reference_id=probe-1`, pay with Stripe's test card `4242 4242 4242 4242`.
  - Run `. scripts/lib/env.sh; curl -s -H "Authorization: Bearer $(envget POLAR_SANDBOX_ACCESS_TOKEN)" "https://sandbox-api.polar.sh/v1/orders/?organization_id=$(envget POLAR_SANDBOX_ORGANIZATION_ID)&limit=1"` piped into `python3 -c 'import json,sys;o=json.load(sys.stdin)["items"][0];print(o["metadata"],o["checkout_id"])'` (the `.env.example` key names).
  - **Expected:** `metadata` contains `probe-1`. Record its key as `REF_KEY`.
  - **If not:** `GET /v1/checkouts/{checkout_id}` (scopes `checkouts:read`) and check its `metadata`. Then `sales_by_ref` reads a checkout-enriched order, and plan 05's production token needs `checkouts:read` (🔒, listed under the contract change requests).
  - **Facts used:**
    - polar.sh/docs/features/checkout/links (27 Oct): `reference_id` and `utm_*` "are automatically attached to the generated Checkout Session", and link metadata "propagates to the resulting Order".
    - The Order schema has `metadata` and `custom_field_data` but no `reference_id` field (polar.sh/docs/api-reference/orders/get.md).
- [ ] **Step 2: Write failing tests** (`scripts/test_kpi.py`, unittest):

```python
class KpiTests(unittest.TestCase):
    def test_iso_week_handles_2026_week_53(self):
        self.assertEqual(iso_week(date(2026, 12, 29)), "2026-W53")
        self.assertEqual(week_bounds("2026-W46"), (date(2026, 11, 9), date(2026, 11, 16)))
    def test_gsc_totals_window_is_end_exclusive(self):
        csv = "Date,Clicks,Impressions,CTR,Position\n2026-11-09,3,120,2.5%,14.1\n2026-11-15,1,80,1.3%,12.0\n2026-11-16,9,900,1%,9\n"
        self.assertEqual(gsc_totals(io.StringIO(csv), date(2026, 11, 9), date(2026, 11, 16)), {"clicks": 4, "impressions": 200})
    def test_gsc_pages_sums_only_the_tracked_paths(self):
        csv = ("Top pages,Clicks,Impressions,CTR,Position\nhttps://tegelapps.com/tools/rtl-markdown-check/,5,300,1.7%,9\n"
               "https://tegelapps.com/ar/tools/rtl-markdown-check/,1,90,1.1%,12\nhttps://tegelapps.com/markdown/,7,800,0.9%,15\n")
        self.assertEqual(gsc_pages(io.StringIO(csv), TOOL_PAGES), {"clicks": 6, "impressions": 390})
    def test_pace_and_status(self):
        self.assertEqual(pace(actual=10, elapsed_days=10, window_days=30), 30)
        self.assertEqual(status(31, 47, 30), "pass, below stretch")
        self.assertEqual(status(9, 47, 30), "below pass")
        self.assertEqual(status(50, 47, 30), "stretch met")
    def test_report_marks_missing_sources(self):
        md = render_report("2026-W46", [("Sales (paid)", "n/a (missing POLAR_ACCESS_TOKEN)", "polar")], [])
        self.assertIn("n/a (missing POLAR_ACCESS_TOKEN)", md)
```

- [ ] **Step 3: Run them.** `python3 -m unittest discover -s scripts -p 'test_kpi.py' -v`. Expected: FAIL (`ModuleNotFoundError: No module named 'kpi'`).
- [ ] **Step 4: Implement `scripts/kpi.py`** with the signatures above.
  - **Report rows**, each with its source:
    - GSC impressions and clicks for the week and for the 30 days (`gsc_totals`); impressions / 30 d on `TOOL_PAGES` and on `RTL_PAGES` (`gsc_pages`, K9);
    - qualified visits (`--visits`, Web Analytics) against the Channel-mix pace (K16);
    - waitlist active count (`GET https://connect.mailerlite.com/api/groups?filter[name]=waitlist` → the item whose `id` is `MAILERLITE_GROUP_WAITLIST` → `active_count`; MailerLite has no single-group GET; check the field name on the first run);
    - sales, refunded, free; sales by ref; net per currency (all from Step 8; until then `n/a (polar_sales.py not merged)`);
    - visit → sale, as sales ÷ qualified visits and sales ÷ GSC clicks;
    - refund rate.
  - **Targets table:** the Scoreboard rows, each with `pace` and `status`, and the re-plan checkpoint's verdict.
- [ ] **Step 5: Run the tests.** Same command. Expected: `OK` (5 tests).
- [ ] **Step 6: Live run.** The KPI command with `--week 2026-W45 --visits 0` and no `--gsc`. Expected: the file exists, every `n/a` row names a source that isn't live yet (before launch: Polar production, and GSC until the first export), and `grep -ciE 'polar_(pat|oat)_|Bearer ' docs/growth/kpi/2026-W45.md` → `0`.
- [ ] **Step 7: Commit** (`git add scripts/kpi.py scripts/test_kpi.py docs/growth/kpi`, `feat(growth): weekly KPI report from Polar, GSC and Web Analytics visits` + trailer). Run Task 23 for `m08-kpi`, then merge.
- [ ] **Step 8: Polar rows, `sales_by_ref` and `summarise`** (Tue 1 Dec, B8, K11). Branch `m08-kpi-net` from `m05-launch` right after plan 05 Task 6 Step 7's commit: `git switch -c m08-kpi-net m05-launch`. Check: `git cat-file -e HEAD:scripts/polar_sales.py && git cat-file -e HEAD:scripts/kpi.py` exits 0 (`m05-launch` was cut from `main` after `m08-kpi` merged). Confirm `platform_fee_currency` is on Step 1's sandbox order. Also confirm the refund fields include tax, as the net formula assumes: fully refund a taxed EU sandbox order and compare its `refunded_amount` and `refunded_tax_amount` with `total_amount` and `tax_amount`; if `refunded_amount` is pre-tax, drop `− refunded_tax_amount` from `net` and record that in `docs/growth/README.md`. Append to `scripts/test_polar_sales.py`: `g` at module level, the test methods inside its `unittest.TestCase`:

```python
def g(**x):
    return {"currency": "usd", "status": "paid", "product_id": "p1", "total_amount": 1900, "net_amount": 1900,
            "platform_fee_amount": 145, "platform_fee_currency": "usd", "refunded_amount": 0, "refunded_tax_amount": 0, **x}

def test_summarise_gross_and_net_per_currency(self):
    self.assertEqual(summarise([
        g(),                                                    # US: 1900 - 145
        g(net_amount=1570, platform_fee_amount=174),            # EU buyer, USD price, 21% VAT inside: 1570 - 174
        g(status="partially_refunded", refunded_amount=950),    # 1900 - 145 - 950
        g(currency="eur", net_amount=1570, platform_fee_amount=150, platform_fee_currency="eur"),  # EUR price (K10): 1570 - 150
        g(status="refunded", refunded_amount=1900),             # excluded
        g(product_id="p2"),                                     # other product
        g(total_amount=0, net_amount=0, platform_fee_amount=0), # $0 order excluded
    ], {"p1"}), {"count": 4, "gross": {"usd": 47.5, "eur": 19.0}, "net": {"usd": 39.56, "eur": 14.2}})

def test_summarise_takes_the_fee_in_its_own_currency(self):   # K21
    self.assertEqual(summarise([g(currency="eur", net_amount=1570, platform_fee_amount=160)], {"p1"}),
                     {"count": 1, "gross": {"eur": 19.0}, "net": {"eur": 15.7, "usd": -1.6}})
```

  And to `scripts/test_kpi.py`, inside `KpiTests` (with the `o` helper at module level):

```python
def o(status, net, pid="prod-md", meta=None, total=None):
    return {"status": status, "net_amount": net, "total_amount": net if total is None else total,
            "product_id": pid, "metadata": meta or {}}

    def test_sales_by_ref_matches_count_sales_rules(self):
        orders = [o("paid", 1400, meta={"reference_id": "app-pdf"}), o("paid", 1900),
                  o("refunded", 1400, meta={"reference_id": "app-pdf"}), o("paid", 0, meta={"reference_id": "app-pdf"}),
                  o("paid", 1500, pid="other", meta={"reference_id": "app-pdf"})]
        self.assertEqual(sales_by_ref(orders, "prod-md"), {"app-pdf": 1, "none": 1})
```

  Run `python3 -m unittest discover -s scripts -p 'test_polar_sales.py' -v` → FAIL (`cannot import name 'summarise'`), and the same for `test_kpi.py` → FAIL (`sales_by_ref` not defined). Implement both to the interfaces, and switch kpi.py's Polar rows (sales, refunded, free, by ref, net) from `n/a` to `polar_sales`; re-run → `OK` (4 and 6 tests). Watch the K21 guard fail: subtract the fee under the order's `currency` → `test_summarise_takes_the_fee_in_its_own_currency` fails; restore → `OK`. Commit (`git add scripts/polar_sales.py scripts/test_polar_sales.py scripts/kpi.py scripts/test_kpi.py`, `feat(growth): Polar rows, sales by ref and per-currency net via polar_sales` + trailer). Run Task 23 for `m08-kpi-net` with `BASE=$(git merge-base HEAD m05-launch)`, so plan 05's commits stay out of scope, then merge to `main` only after plan 05 Task 10 Step 3 has merged `m05-launch` (Mon 7 Dec). Plan 07 G1 adds only the CLI flags on top.

### Task 5: Weekly growth review and triggers (C + U; Mon 9 Nov; first review Tue 10 Nov)

**Files:** Create `docs/growth/experiments.md`.

- [ ] **Step 1: Reference ids.**
  - Every link to checkout carries `?reference_id=<surface>-<placement>`. Values:
    - `app-folder`, `app-pdf`, `app-theme`, `app-licence`;
    - `site-<page-slug>` (the tool links `/markdown/`, so its sales count there);
    - `email-launch`, `email-launch2`, `email-d0`, `email-d7`, `email-crosssell`, `email-v11`;
    - `bench-rtl`.
  - The ids carry no personal data.
- [ ] **Step 2: The ritual.** Every **Tuesday 10:30–11:00 CET**, after plan 05's 10:00 support routine.
  - **C, before 10:30:**
    - export GSC (Performance → Date → Custom: the 30 days ending last Sunday → Export → Download CSV) and unzip it into `docs/growth/kpi/gsc/<week>/` (Google account `marketing@snelverhuizen.nl` only, CLAUDE.md "Accounts"; U does the export if Claude can't log in). One export holds the daily site totals (`Chart.csv`) and the per-page totals for the same 30 days (`Pages.csv`), so the 30-day and per-page triggers below read real 30-day figures (K9; "last 28 days" can't);
    - read the week's qualified visits from the Web Analytics dashboard, then run the KPI command (Task 4) for the last ISO week.
  - **Agenda:**
    1. Funnel vs last week, and the targets table (5 min).
    2. Triggers fired (5 min).
    3. The re-plan checkpoint (Channel mix, K16): on pace, or write the re-plan (10 min).
    4. Approve this week's 🔒 queue in one batch (5 min).
    5. Three lines under `## Decisions` in the week's KPI file (5 min).
  - Commit the KPI file (`docs(growth): KPI <week>` + trailer).
- [ ] **Step 3: Failure triggers.** Each maps to a BUSINESS-PLAN §12 gate.

| Trigger | Window | Action | Gate |
|---|---|---|---|
| Waitlist < 50 confirmed on Tue 24 Nov | pre-launch | Move the week's hours to Task 9 tool distribution and Task 10 RTL communities; launch unchanged | G1 input |
| Sales < 5 in 8–14 Dec | launch week | Check every funnel step: checkout 200, DMG 200, Web Analytics visits to `/download/`, refund reasons. Fix the leak and don't add channels | G1 |
| Sales < 10 on Tue 22 Dec (day 14) | G1 pace | Write the G1 "< 10" branch for plan 05 Task 14 now: App 1 SEO stops after G1 and App 2 ships | G1 |
| Visit → sale (÷ GSC clicks) < 0.5% with ≥ 1,000 clicks / 30 d | rolling | Positioning review (Task 3 Step 2) before any traffic work | §4 test (≥ 1%) |
| Refund rate > 5% with ≥ 20 sales | rolling | Read every refund reason, fix the product or the copy, and log it in `reviews.md` | quality |
| RTL pages (`RTL_PAGES`, `Pages.csv`) < 1,000 GSC impressions / 30 d on Sat 6 Feb (day 60) | day 60 | RTL thesis weak: shift article slots from RTL to agent-files topics (plan 04) | §4 gap 1, G2 |
| GSC impressions / 30 d < 4,000 on Sat 6 Feb | day 60 | G2 at risk: prepare the maintenance-only branch | G2 |
| Cited 0/n on all 6 prompts for 3 monthly runs | AI | Rewrite answer blocks (Task 13 Step 2) | G2 input |
| Support > 20 min/day (plan 05 Task 4) | 14 d | Plan 05's gate wins: docs before growth work | Support |
| Qualified visits under half the Channel-mix need (K16) | 14 d | Re-plan in the KPI file; the user approves it before any new feature or channel work | G1, G2 |
| A page logs ≥ 768 Web Analytics visits / 30 d | rolling | Start one sequential copy test on that page (period A, then B, n = 768 each; decide only at n) (B5) | — |
| Net / month < €100 on Fri 30 Apr | G3 | Development stops (plan 07 G3, Task G7); growth drops to the monthly AI check and the article cadence only | G3 |

- [ ] **Step 4: Pricing and packaging stance** (written into the file).
  - **No price A/B tests.** Two-proportion test, α = 0.05 two-sided, power 0.8 (computed with `statistics.NormalDist`, 27 Oct):
    - detecting visit → sale 1.0% → 1.5% needs **7,747 visits per arm**;
    - even a doubling (1% → 2%) needs **2,315 per arm**.
  - **Why that rules it out:** at the G2 stretch (10,000 impressions/30 d, about 200–400 search clicks/month at 2–4% CTR), one price test would take 1–6+ years. Charging two prices at once also clashes with rule 6's honest-pricing spirit.
  - **Allowed instead:** sequential, dated, pre-announced changes only (HR3):
    - $14 → $19 on 15 Dec (plan 05 Task 12);
    - App 2 at $15 (plan 06);
    - the $29 bundle with App 2 on 2 Feb (plan 06), launched on a stated date;
    - the paid-v2 upgrade price for v1 owners (plan 07).
  - **Evaluating a price change** needs ≥ 60 days on each side. Compare revenue per GSC click, and list the confounds: launch spike, season, macOS release in September.
  - **Never a "sale" event.**
- [ ] **Step 5: Commit** (`docs(growth): review ritual, triggers, pricing stance` + trailer). The one-off measures live with their tasks: the free tool (Task 9), the RTL benchmark (Task 16) and the cross-sell email (Task 15).

# Part A: before launch (W2–W6)

### Task 6: MailerLite account and lists (C via Playwright, U for 2FA; Tue 3 – Fri 6 Nov; approval may slip to Tue 10 Nov, and the waitlist go-live stays Mon 16 Nov)

- [ ] **Step 1 🔒 Create the account** with `STUDIO_EMAIL` on the Free plan (the user approves account creation).
  - Expected: the dashboard shows the Free plan. Record "250 subscribers / 2,500 emails / 3 automations × 5 steps" as seen on the plan page that day.
  - Check step: MailerLite may review a new account before it can send (duration unverified). If it asks for a website, use the live `tegelapps.com`; the domain exists from W2 (plan 04).
  - Check step (K2): do **unconfirmed** subscribers count toward Free's 250? Read MailerLite's pricing page and its help article on subscriber limits, and record the answer with URL and date here. If they do, unconfirmed sign-ups (including abusive ones) use up the plan: tell the user, and the weekly review (Task 5) reads the account's total subscriber count, not only `waitlist` actives.
- [ ] **Step 2: Accept the DPA.** It is MailerLite's data processing terms, from the account's legal/settings page. Record the date. Plan 04's privacy page cites it.
- [ ] **Step 3 🔒 Sender domain.** Authenticate `tegelapps.com` (DKIM/SPF TXT records in Cloudflare DNS: a DNS change on a live domain). Sender = `hello@tegelapps.com`, name `Tegel`.
  - **SPF stays one record.** Email Routing already publishes `v=spf1 include:_spf.mx.cloudflare.net ~all` at the apex (plan 04 Task 3), and two `v=spf1` records are an SPF permerror for forwarding and MailerLite alike. Cloudflare's Email Routing DNS page says to merge includes and keep only one SPF record. So don't add MailerLite's SPF record: unlock Email Routing's SPF record (Email Routing → Settings → DNS records → Unlock) and add MailerLite's `include:` to it, before `~all`.
  - Watch the SPF check catch two records first: `printf '"v=spf1 include:_spf.mx.cloudflare.net ~all"\n"v=spf1 include:_spf.example.net ~all"\n' | grep -c v=spf1` → `2`. On the live zone, before and after the change: `dig +short TXT tegelapps.com | grep -c v=spf1` → `1`. After the change, `dig +short TXT tegelapps.com | grep v=spf1` shows that one line holding both `include:_spf.mx.cloudflare.net` and MailerLite's include.
  - Expected: MailerLite shows the domain as verified, and `dig +short TXT <selector>._domainkey.tegelapps.com` returns the key.
- [ ] **Step 3b 🔒 DMARC** (K5; a DNS change on a live domain, so U approves "add TXT `_dmarc.tegelapps.com` = `v=DMARC1; p=quarantine`"). Plan 04 Task 3 Step 4 left DMARC out until something sends as `@tegelapps.com`; from this task MailerLite does.
  - **Before the record:** send a MailerLite test email to `STUDIO_EMAIL` and read its `Authentication-Results` header: `dkim=pass` with `header.d=tegelapps.com`. If support replies go out as `hello@tegelapps.com` through anything else (plan 05 Task 4), send one that way too and expect `dmarc=pass` or an aligned `dkim=pass`. If either fails, the record waits and the user is told: `p=quarantine` would put those mails in spam.
  - Add the TXT record in Cloudflare DNS. Expected: `dig +short TXT _dmarc.tegelapps.com` → `"v=DMARC1; p=quarantine"`, and a second MailerLite test email shows `dmarc=pass`.
- [ ] **Step 4: Settings.**
  - **Subscribe settings:** "Double opt-in for API and integrations" **on**. That setting is under Account settings → Subscribe settings; MailerLite: "The same double opt-in for API email is sent to all subscribers added via API" (mailerlite.com/help/how-to-use-double-opt-in-when-collecting-subscribers, 27 Oct).
  - **Confirmed-subscriber redirect:** `https://tegelapps.com/waitlist/confirmed/`.
  - **Tracking:** turn open and click tracking **off**, then verify it: send a test campaign to `STUDIO_EMAIL` and view its source. Expected: links point straight to their targets (no MailerLite redirect host) and there is no tracking-pixel image. If the Free plan can't turn tracking off, the privacy page must disclose open/click tracking before the waitlist goes live (Task 8 Step 6). Email results are measured by `reference_id`, not pixels.
  - **Footer:** identity + postal address/number (Tw 11.7 lid 7). Waits on open question 1.
- [ ] **Step 5: Groups and tokens.** Groups `waitlist`, `buyers-markdown`, `buyers-data`. Create **two** API tokens, "local scripts" and "Pages waitlist" (K8, S18). For each, the **user** clicks the final Create button and Copy, and Claude makes no Playwright call while the token is on screen (master §6). Save each with `envset` (K1): the two tokens from the pasteboard (`envset MAILERLITE_API_TOKEN "$(pbpaste)" && pbcopy </dev/null`, then the same for `MAILERLITE_API_TOKEN_PAGES`), and the three `MAILERLITE_GROUP_*` ids.
  - Expected: `. scripts/lib/env.sh; for k in MAILERLITE_API_TOKEN MAILERLITE_API_TOKEN_PAGES MAILERLITE_GROUP_WAITLIST MAILERLITE_GROUP_BUYERS_MARKDOWN MAILERLITE_GROUP_BUYERS_DATA; do [ -n "$(envget $k)" ] && echo "$k set"; done` → 5 lines.
  - Add these names, `CLOUDFLARE_KV_WAITLIST_ID` and `CLOUDFLARE_KV_WAITLIST_PREVIEW_ID` (contract change request 9) to `.env.example`.
- [ ] **Step 6: Check both tokens without writing.** `. scripts/lib/env.sh; for k in MAILERLITE_API_TOKEN MAILERLITE_API_TOKEN_PAGES; do curl -s -o /dev/null -w "$k %{http_code}\n" -H "Authorization: Bearer $(envget $k)" https://connect.mailerlite.com/api/groups; done` → `200` twice.

### Task 7: Waitlist form handler (C; Wed 4 – Tue 10 Nov; branch `m08-waitlist`)

**Why a function:** MailerLite's embed posts to `assets.mailerlite.com/jsonp/…`. Without JS, the browser lands on a bare `{"success":true}` page, which a Webflow forum user reports and no official MailerLite source contradicts. Plan 04's tests also forbid external scripts. A same-origin Pages Function keeps the form plain HTML and the UX clean.

**Platform facts** (developers.cloudflare.com/pages/functions, 27 Oct):
- the `/functions` folder "at the root of your Pages project (and not in the static root)";
- `onRequestPost` is a documented method handler, and `context.env` "holds the environment variables, secrets, and bindings";
- Functions requests count toward the Workers Free quota (100,000/day);
- static asset requests "are free and unlimited".
- Workers KV on Free (developers.cloudflare.com/kv/platform/limits, 27 Oct): 100,000 reads and 1,000 writes per day, at most 1 write per second to one key, `expirationTtl` ≥ 60 s. KV isn't atomic, so the daily cap is approximate, which is enough for abuse limiting.

`.ts` support isn't stated on the pages read, so the handler is `.js`.

**Files:** Create `site/functions/api/waitlist.js` and `site/test/functions/waitlist.test.js`. Every file under `functions/` becomes a route, so the tests live under `site/test/` (K8; plan 04's guard fails a deploy if one appears in `functions/`).

**Interfaces:**
- **Produces:** `export async function onRequestPost({ request, env }): Promise<Response>`.
  - **Env:** `MAILERLITE_API_TOKEN` (set from `.env`'s `MAILERLITE_API_TOKEN_PAGES`, never the local token), `MAILERLITE_GROUP_WAITLIST`, `SITE_ORIGIN` (`https://tegelapps.com` in production, the branch alias URL in preview), `WAITLIST_DAILY_CAP` (default `100`), and the KV binding `WAITLIST_KV`.
  - **Form fields:**
    - `email`;
    - `consent` (`on`);
    - `website` (the honeypot, must be empty);
    - `lang` (`en`|`ar`; anything else counts as `en`).
  - **Allowed hosts:** `new URL(SITE_ORIGIN).host` and `www.` + that host. Production therefore rejects `*.pages.dev`, and the preview accepts only its alias.
  - **Abuse limits (KV, before any MailerLite call):** first the per-client key `ip:<SHA-256 hex of CF-Connecting-IP + UTC yyyy-mm-dd>` (a count, TTL 24 h; the IP itself is never stored); at 3 or more → `later`, and a missing `CF-Connecting-IP` → `later`. Without it, one client posting 100 strangers' addresses (≈ 200 s at the rate limit) closes the list for the day and mails 100 people who never asked. Then the global key `day:<UTC yyyy-mm-dd>` (a count, TTL 2 days); at or over `WAITLIST_DAILY_CAP` → `later`. Per-address key `addr:<SHA-256 hex of the lowercased address>` (TTL 24 h; the address itself is never stored); present → `check-email` without a call. KV has no atomic increment, so parallel requests can each read the same count: a parallel burst can pass several sign-ups on one stale count, so the per-IP limit holds only roughly (the zone rule's 5 requests per IP per 10 s and KV's 1 write per second per key bound each burst), and the global cap is approximate. Accepted; ponytail: move the counters to a Durable Object if MailerLite's waitlist group grows faster in a day than `WAITLIST_DAILY_CAP` plus a few. Any KV error → `later` (fail closed).
  - **Redirects:** `303` to `<prefix>/waitlist/{check-email,invalid,error,later}/`, where prefix is `''` for en and `'/ar'` for ar. Check this against plan 04's URL scheme at Step 6.
  - **MailerLite call:** `POST https://connect.mailerlite.com/api/subscribers`, body `{email, groups:[MAILERLITE_GROUP_WAITLIST], status:"unconfirmed"}` (the field list is from developers.mailerlite.com/docs/subscribers). No IP address and no name are sent.

- [ ] **Step 1: Write the failing tests.**

```js
import { test, expect, mock, beforeEach } from 'bun:test';
import { onRequestPost } from '../../functions/api/waitlist.js';

const kv = () => { const m = new Map(); return { m, get: async k => m.get(k) ?? null, put: async (k, v) => { m.set(k, v) } } };
let env;
const post = (fields, headers = {}, body, url = 'https://tegelapps.com/api/waitlist') => new Request(url, {
  method: 'POST',
  headers: { 'Content-Type': 'application/x-www-form-urlencoded', Origin: 'https://tegelapps.com', 'CF-Connecting-IP': '192.0.2.1', ...headers },
  body: body ?? new URLSearchParams(fields).toString(),
});
let calls, reply;
beforeEach(() => {
  env = { MAILERLITE_API_TOKEN: 'test-token', MAILERLITE_GROUP_WAITLIST: '111', SITE_ORIGIN: 'https://tegelapps.com',
          WAITLIST_DAILY_CAP: '100', WAITLIST_KV: kv() };
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
  - `foreign host is forbidden`: the same valid POST to `https://tegel.pages.dev/api/waitlist` (Origin `https://tegelapps.com`) → 403, no call.
  - `daily cap reached returns the try-later page without calling MailerLite` (S17): `env.WAITLIST_KV.m.set('day:' + new Date().toISOString().slice(0, 10), '100')` → 303 `/waitlist/later/`, `calls.length === 0`.
  - `same address twice in 24 h calls MailerLite once`: three valid POSTs (`a@example.com` twice, then `A@Example.com`) → three 303s to `/waitlist/check-email/`, `calls.length === 1`, and no KV key contains `example.com`.
  - `a fourth sign-up from one IP in a day gets the try-later page` (K2): four valid POSTs with different addresses from `192.0.2.1` → the first three 303 `/waitlist/check-email/`, the fourth 303 `/waitlist/later/`, `calls.length === 3`, and no KV key contains `192.0.2.1`. Then one POST with `'CF-Connecting-IP'` removed → 303 `/waitlist/later/`, still 3 calls.
  - `a streamed body without Content-Length is cut off at 2,049 bytes` (K22): a `ReadableStream` of 100 chunks of 1,024 bytes as the body (`duplex: 'half'`, no `Content-Length`), counting each `pull` → 413, no call, and fewer than 10 chunks pulled.
  - `KV failure fails closed`: `env.WAITLIST_KV.put = async () => { throw new Error('429') }` → 303 `/waitlist/later/`, no call.
  - `missing KV binding fails closed`: `delete env.WAITLIST_KV` → 303 `/waitlist/later/`, no call. Step 6's preview check relies on this.
- [ ] **Step 2: Run them.** `(cd site && bun test test/functions)`. Expected: FAIL (`Cannot find module '../../functions/api/waitlist.js'`).
- [ ] **Step 3: Implement `onRequestPost`.**
  - Check order: Host (allowed hosts), Origin (exact match with `SITE_ORIGIN`), Content-Type, size, fields, honeypot, then the KV per-IP limit, cap and cooldown, then MailerLite. The KV writes happen before the call, so a failing provider can't be used to retry an address in a loop.
  - Size: a `Content-Length` over 2048 → 413 at once. Otherwise read `request.body` with `getReader()`, counting bytes, and at 2,049 cancel the reader and return the same 413 (K22). Never `request.text()` or `formData()` first: a streamed body without `Content-Length` would be buffered whole. Decode the kept bytes with `TextDecoder`, then `URLSearchParams`.
  - Hash with `crypto.subtle.digest('SHA-256', …)`.
  - Email check: trim; length ≤ 254; one `@`; a dot in the domain; no whitespace or control characters (`/^[^\s@]+@[^\s@]+\.[^\s@]+$/`).
  - Never `console.log` request data.
- [ ] **Step 4: Run them.** `(cd site && bun test test/functions)`. Expected: all pass (17 tests). Then `make test-site`: its output includes these 17 (plan 04's `cd site && bun test` discovers `test/` and `tools/`). If it doesn't, add `bun test site/test site/tools` to `test-site` and commit the `Makefile` with this task (X21).
- [ ] **Step 4b: Watch the new guards fail.** Comment out the Host check → `foreign host is forbidden` fails. Restore; comment out the cap read → `daily cap reached…` fails (one call made). Restore; make the KV calls optional (`env.WAITLIST_KV?.get(…)`, `?.put(…)`) → `missing KV binding fails closed` fails (one call made). Restore; comment out the per-IP read → the fourth-sign-up test fails (four calls). Restore; replace the byte counter with `await request.text()` → the streamed-body test fails (100 chunks pulled). Restore → 17 pass.
- [ ] **Step 5: Commit** (`git add site/functions/api site/test/functions`, `feat(site): same-origin waitlist handler with double opt-in, host check and KV limits` + trailer).
- [ ] **Step 6: KV and preview deploy.** `H` below is plan 04's real pages.dev host, saved as `CLOUDFLARE_PAGES_HOST` (plan 04 Task 8 Step 5; it may carry a suffix, so it is never typed in). Every command that uses `H` starts with `. scripts/lib/env.sh && H="$(envget CLOUDFLARE_PAGES_HOST)" &&`.
  - **KV 🔒 (dashboard, by hand):** the deploy token is Pages-only (plan 04 K2) and has no Workers KV permission. U approves "create the Workers KV namespaces `tegel-waitlist` and `tegel-waitlist-preview` and bind them as `WAITLIST_KV` to the `tegel` Pages project: `tegel-waitlist` for Production, `tegel-waitlist-preview` for Preview". Two namespaces, so preview tests never count toward production's day cap or per-IP limit and can't close the live waitlist (K3). Then, with Playwright:
    - Storage & Databases → KV → Create → `tegel-waitlist`, then `tegel-waitlist-preview`. Save the IDs with `. scripts/lib/env.sh && envset CLOUDFLARE_KV_WAITLIST_ID <id>` and `envset CLOUDFLARE_KV_WAITLIST_PREVIEW_ID <id>` (not secrets).
    - Workers & Pages → tegel → Settings → Bindings → KV namespace `WAITLIST_KV`: `tegel-waitlist` under Production, `tegel-waitlist-preview` under Preview. **Check step:** Pages bindings are set per environment (developers.cloudflare.com/pages/functions/bindings/, KV namespaces); confirm the dashboard shows a different namespace per environment and record it. If it allows only one, stop and tell the user.
    - No `wrangler kv` command runs in this plan.
  - **Preview secrets** (CR-P2-9: without the environment flag, wrangler targets production). Set each of `MAILERLITE_API_TOKEN` (value from `MAILERLITE_API_TOKEN_PAGES`), `MAILERLITE_GROUP_WAITLIST` and `SITE_ORIGIN` (plan 04's preview alias, `printf 'https://preview.%s' "$H"`). Pipe the value in so it's never echoed: `. scripts/lib/env.sh && need MAILERLITE_API_TOKEN_PAGES && envget MAILERLITE_API_TOKEN_PAGES | CLOUDFLARE_API_TOKEN="$(envget CLOUDFLARE_API_TOKEN)" CLOUDFLARE_ACCOUNT_ID="$(envget CLOUDFLARE_ACCOUNT_ID)" bunx wrangler@4.151.2 pages secret put MAILERLITE_API_TOKEN --project-name tegel --env preview`.
  - **Check step** (`--env preview` is documented only on a third-party mirror of the wrangler docs, 27 Oct): `… bunx wrangler@4.151.2 pages secret list --project-name tegel --env preview` lists the three names. If the flag is rejected, set them in the dashboard under Settings → Variables and Secrets → Preview, and record that.
  - **Deploy** with plan 04's preview command (it runs from `site/`, so `functions/` uploads; X9).
  - **Expected** (one `-w` each, CR-P2-9):
    - `curl -s -o /dev/null -w '%{http_code}' -X POST "https://preview.$H/api/waitlist"` → `403` (no Origin);
    - `curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -X POST -H "Origin: https://preview.$H" -H 'Content-Type: application/x-www-form-urlencoded' --data 'email=a@example.com&consent=on&website=bot' "https://preview.$H/api/waitlist"` → `303 https://preview.<H>/waitlist/check-email/`. The honeypot is filled, so the function is proven live without sending mail.
    - **KV binding, checked through the endpoint:** the same POST without `website=bot` and with `email=<STUDIO_EMAIL+preview@…>` → `303 …/waitlist/check-email/`. A missing or failing binding answers `…/waitlist/later/` instead (`missing KV binding fails closed`, `KV failure fails closed`), so `check-email` proves the cap read and both KV writes went through. KV is never read directly: the Pages-only token can't, and wrangler v4's `kv key` commands read local storage unless `--remote`. The unit tests cover "no address in a KV key". Forget the test subscriber in MailerLite.
    - **Close the preview endpoint.** The zone's rate-limiting rule doesn't cover pages.dev, so take the mail token away: `. scripts/lib/env.sh && CLOUDFLARE_API_TOKEN="$(envget CLOUDFLARE_API_TOKEN)" CLOUDFLARE_ACCOUNT_ID="$(envget CLOUDFLARE_ACCOUNT_ID)" bunx wrangler@4.151.2 pages secret delete MAILERLITE_API_TOKEN --project-name tegel --env preview` (or delete it in the dashboard, as above). Pages gives each deployment the secrets set when it was made, so the live preview keeps the token until it is redeployed (K6; check this against developers.cloudflare.com/pages/functions/bindings/, environment variables and secrets, and record the wording): redeploy with plan 04's preview command. Then `pages secret list … --env preview` no longer lists it, and a preview sign-up (the KV check POST with a new `+preview2` address) ends on `/waitlist/error/` with no mail sent. A later task that needs a live preview puts the token back with the command above and redeploys.

### Task 8: Waitlist copy, pages and go-live (C drafts, U approves; Wed 11 – Mon 16 Nov)

**Files:**
- Create `site/templates/partials/waitlist-form.html` and `site/templates/partials/waitlist-form-ar.html`.
- Modify `site/content/en/index.md` and `site/content/en/rtl-markdown-to-pdf.md` (one `{{partial:waitlist-form}}` line each, Step 1b).
- Create `site/content/{en,ar}/waitlist/{check-email,confirmed,invalid,error,later}.md` (front matter copied from an existing plan 04 page).
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
  - The Arabic partial (`waitlist-form-ar.html`) mirrors the markup, with `lang=ar`, `dir="rtl"` and this copy (U reviews the Arabic):
    - consent: `راسلني مرتين: عند إطلاق Tegel Markdown ‏(8 ديسمبر 2026)، وعند إطلاق تطبيق Tegel التالي (المخطط له مطلع 2027). بعد ذلك تُحذف هذه القائمة. يمكنك إلغاء الاشتراك في أي وقت.`
    - button: `انضم إلى القائمة`.
  - Consent law: Tw 11.7 lid 1 (prior, provable consent). The box is unchecked, the purpose is specific, the retention is stated and the opt-out is shown (HR7).
- [ ] **Step 1b: Place the form.** Add a `{{partial:waitlist-form}}` line below the pricing block of `site/content/en/index.md` and `site/content/en/rtl-markdown-to-pdf.md`. The Arabic page `site/content/ar/arabic-markdown-pdf.md` comes later (plan 04, W5); if it ships before Tue 8 Dec, that task adds a `{{partial:waitlist-form-ar}}` line to it. Expected after `bun site/build.js`: `grep -c 'action="/api/waitlist"' site/public/index.html site/public/rtl-markdown-to-pdf/index.html` → `1` for each.
- [ ] **Step 2: Result pages** (one short paragraph each, EN + AR):
  - **check-email:** "Check your inbox and confirm your address. Nothing arrives until you do. If it isn't there in 10 minutes, look in spam."
  - **confirmed:** "You're on the list. Two emails, then the list is deleted. Meanwhile you can try the RTL Markdown checker." (Link it once Task 9 is live.)
  - **invalid:** "That didn't work: please enter a valid email and tick the box." + a link back.
  - **error:** "We couldn't save your address just now. Please try again in 24 hours, or email hello@tegelapps.com and we'll add it by hand." (The address's 24 h cooldown key is written before the MailerLite call, so an earlier retry would only show check-email.)
  - **later:** "The waitlist is taking a break for today. Please try again tomorrow, or email hello@tegelapps.com and we'll add you by hand."
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
Waitlist. If you join the waitlist, your email address is stored by MailerLite (our email processor, under its data processing agreement) on the basis of your consent, confirmed by email. We use it for two emails: the launch of Tegel Markdown and the launch of the next Tegel app. After the second, we delete the list. You can unsubscribe at any time from any email, or by writing to hello@tegelapps.com. To limit abuse, the sign-up form keeps a hash of your IP address for 24 hours to count sign-ups per connection, and a hash of your email address for 24 hours to stop repeat sign-ups; neither the IP address nor the email address is stored in them.
Buyers. If you buy a licence, Polar (our merchant of record) shares your email with us. Only if you ticked "Email me set-up tips and news about Tegel apps" at checkout do we send three short emails in your first month (set-up, tips, a request for a review) and news about Tegel apps. Every email has an unsubscribe link. If you're refunded, we remove you from that list. If you ask us to delete your data, we do, and keep only a hash of your email address so the daily sync never adds you back.
```

- [ ] **Step 5: Checks.** Run Task 1's lint on `site/content/*/waitlist`, `site/templates/partials/waitlist-form.html`, `site/templates/partials/waitlist-form-ar.html` and `docs/growth/email-copy.md` → `COPY-LINT: clean`. Then plan 04's site build and tests: no external script. Expected: pass.
- [ ] **Step 5b: Commit** (`git add site/templates/partials site/content/en/index.md site/content/en/rtl-markdown-to-pdf.md site/content/en/waitlist site/content/ar/waitlist docs/growth/email-copy.md`, `feat(site): waitlist form, result pages and consent copy` + trailer), on `m08-waitlist`, before anything is deployed (K1).
- [ ] **Step 5c: Preview check.** Deploy with plan 04's preview command (no approval; it deploys the working tree, not `main`). Expected: `. scripts/lib/env.sh && H="$(envget CLOUDFLARE_PAGES_HOST)" && for p in {,ar/}waitlist/{check-email,confirmed,invalid,error,later}; do curl -s -o /dev/null -w "%{http_code} $p\n" "https://preview.$H/$p/"; done` → ten lines, each `200`; `curl -s "https://preview.$H/" | grep -c 'action="/api/waitlist"'` → `1`, and the same for `/rtl-markdown-to-pdf/`.
- [ ] **Step 5d: Review and merge.** Run Task 23 for `m08-waitlist` (its `/cso` scope covers `functions/api/waitlist.js` and this task's pages), fix every P0/P1, then merge to `main`. Nothing public sends mail before this review.
- [ ] **Step 6 🔒 Go live** (U approves "deploy the waitlist form to production"), from `main` after Step 5d's merge, with plan 04's production deploy command (it starts with `git switch main`, which now holds `functions/api/waitlist.js`). If plan 04 hasn't yet made the site's first public deploy, this one is it: CLAUDE.md lists that separately, so the request says so and the user confirms both. The approval needs these in place, each checked, not assumed:
  - **Live privacy page:** `curl -s https://tegelapps.com/privacy/ | grep -c MailerLite` ≥ 1, and the page lists MailerLite as processor, the waitlist, the buyer sync and the lifecycle emails (the Step 4 text). If Task 6 Step 4 found that tracking can't be turned off, `curl -s https://tegelapps.com/privacy/ | grep -ciE 'open.*click|tracking'` ≥ 1 as well;
  - **Email footer:** the double-opt-in test email (Task 6 settings, sent to `STUDIO_EMAIL`) shows the real identity and a postal address or number (Tw 11.7 lid 7), and `grep -c '<identity and postal address' docs/growth/email-copy.md` → `0`;
  - the Cloudflare rate-limiting rule (Free: 1 rule) is **path equals `/api/waitlist`, 5 requests per 10 s per IP, block 10 s** (🔒 zone change);
  - the production secrets are set, from `.env`'s `MAILERLITE_API_TOKEN_PAGES` (never the local token), with `--env production` (Task 7 Step 6's pattern), plus `SITE_ORIGIN=https://tegelapps.com` and `WAITLIST_DAILY_CAP=100`; `pages secret list --project-name tegel --env production` shows all four names, and `WAITLIST_KV` is bound to `tegel-waitlist` (not the preview namespace) in Production;
  - the form is on the home page and the RTL landing page (Step 1b, checked on the preview in Step 5c) until Tue 8 Dec (Task 15 Step 1b closes it).
- [ ] **Step 7: End-to-end check on production with `STUDIO_EMAIL`.** Expected:
  - the browser lands on `/waitlist/check-email/`;
  - the confirmation email arrives, lints clean and shows the footer;
  - the confirm link lands on `/waitlist/confirmed/`;
  - the MailerLite group `waitlist` shows 1 active.
  - Then 7 rapid POSTs in a loop: `for i in $(seq 7); do curl -s -o /dev/null -w '%{http_code} ' -X POST -H 'Origin: https://tegelapps.com' -H 'Content-Type: application/x-www-form-urlencoded' --data 'email=a&consent=on&website=x' https://tegelapps.com/api/waitlist; done` → at least one `429`.
  - Host check on the production deployment: `. scripts/lib/env.sh && curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Origin: https://tegelapps.com' -H 'Content-Type: application/x-www-form-urlencoded' --data 'email=a@example.com&consent=on&website=' "https://$(envget CLOUDFLARE_PAGES_HOST)/api/waitlist"` → `403` (K8).
  - Finally, remove the test subscriber (`POST /api/subscribers/{id}/forget`).

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

**Privacy:** nothing leaves the browser. The file is read with `FileReader`; plan 04's `/tools/*` CSP (in `site/static/_headers`) sets `connect-src 'none'` and `img-src data:` only; and sanitising drops every image source that isn't `data:image/*`, same-origin paths included, because an `<img src="/private-project/x.png">` would otherwise send that path to the server (K15).

**Files:**
- Create `site/tools/rtl-markdown-check/analyze.js` and `analyze.test.js` (`site/tools/` is never uploaded: the deploy uploads `public/` and `functions/` only).
- Create `main.js` (DOM glue: `addHooks(DOMPurify)` once; then textarea and file input → `renderToHTML` → `DOMPurify.sanitize(html, { ...SANITIZE_CONFIG, RETURN_DOM_FRAGMENT: true })` → `preview.replaceChildren(fragment)`, plus the warning list; never `innerHTML`).
- Create `tool.html` (markup fragment) and `site/content/{en,ar}/tools/rtl-markdown-check.md` (page copy, front matter `tool: rtl-markdown-check`).

**Interfaces:**
- **Consumes:**
  - `renderToHTML(markdown, {mode:'window'})` from `Renderer/src/markdown.js` (master §3.2), imported by relative path;
  - `SANITIZE_CONFIG` and `addHooks(purify, { fileImages = false } = {})` from `Renderer/src/sanitize.js` (plan 01 Step 7; X8). `fileImages` keeps `tegel-doc:` on `img[src]` for the app only. The tool calls `addHooks(DOMPurify)` without it, so every image source that isn't `data:image/*` is dropped (K15).
- **Produces:** `analyzeBlocks(markdown: string) -> { blocks: Array<{ index: number, kind: 'heading'|'paragraph'|'list'|'quote'|'table', dir: 'rtl'|'ltr'|'neutral', rtlShare: number, warnings: Array<'latin-first'|'rtl-first-mostly-latin'> , text: string }>, summary: { rtl: number, ltr: number, neutral: number, warnings: number } }`.
  - Blocks follow the renderer's `dir="auto"` elements, which are top-level blocks only (master §3.2): items and cells inherit, so a whole list or table is one block, directed by its first strong letter (K12). Fenced and indented code is skipped (it stays LTR).
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
test('a list takes its direction from its first item, like the renderer', () => {
  expect(analyzeBlocks('- یہ فائل جدول دکھاتی ہے۔\n- Settings کھولیں اور دیکھیں کہ کیا بدلا۔').blocks.map(b => [b.kind, b.dir])).toEqual([['list', 'rtl']]);
  const b = analyzeBlocks('- Settings کھولیں اور دیکھیں کہ کیا بدلا۔\n- یہ فائل جدول دکھاتی ہے۔').blocks;
  expect(b.map(x => [x.kind, x.dir])).toEqual([['list', 'ltr']]); expect(b[0].warnings).toContain('latin-first'); });
test('code fences are skipped and dates are neutral', () => {
  const r = analyzeBlocks('```\nconst x = 1;\n```\n\n2026-12-08');
  expect(r.blocks.length).toBe(1); expect(r.blocks[0].dir).toBe('neutral'); });
test('a table is one block, directed by its first strong letter', () => {
  expect(analyzeBlocks('| الاسم | Name |\n|---|---|\n| ملف | file |').blocks.map(b => [b.kind, b.dir])).toEqual([['table', 'rtl']]);
  expect(analyzeBlocks('| Name | الاسم |\n|---|---|\n| file | ملف |').blocks.map(b => [b.kind, b.dir])).toEqual([['table', 'ltr']]); });
test('summary counts warnings', () => {
  expect(analyzeBlocks('API هي واجهة تربط بين برنامجين مختلفين.').summary.warnings).toBe(1); });
```

  And the privacy guard (K15), in `analyze.test.js` too. It drives plan 01's hook the way plan 01's own `sanitize.test.js` does:

```js
import { addHooks } from '../../../Renderer/src/sanitize.js';
test('the tool drops every non-data: image source, same-origin paths included', () => {
  const hooks = []; addHooks({ addHook: (name, fn) => hooks.push([name, fn]) });   // the tool's call: no fileImages
  const verdict = (nodeName, attrName, attrValue) => { const d = { attrName, attrValue, keepAttr: true };
    for (const [n, fn] of hooks) if (n === 'uponSanitizeAttribute') fn({ nodeName }, d);
    return d.forceKeepAttr ? 'force' : d.keepAttr ? 'keep' : 'drop'; };
  for (const src of ['/private-project/architecture.png', 'diagram.png?token=abc', 'https://evil.example/b.gif', '//evil.example/b.gif', 'tegel-doc:///Users/u/a.png'])
    expect([src, verdict('IMG', 'src', src)]).toEqual([src, 'drop']);
  expect(verdict('IMG', 'src', 'data:image/png;base64,iVBORw0KGgo=')).toBe('keep');
});
```

- [ ] **Step 2: Run them.** `bun test site/tools`. Expected: FAIL (`Cannot find module './analyze.js'`).
- [ ] **Step 3: Implement `analyzeBlocks`.**
  - Line-based segmentation into top-level blocks: blank lines end paragraphs; ATX headings; consecutive `-`, `*`, `+` or `1.` items, nested ones and blank lines between them included, form one `list`; consecutive `>` lines one `quote`; consecutive pipe rows one `table`, with delimiter rows skipped; ``` and `~~~` fences skipped.
  - Strip inline code spans before counting letters, because code is LTR by contract.
- [ ] **Step 4: Run them, and watch the privacy guard fail.** `bun test site/tools`. Expected: 9 pass. Then make plan 01's hook keep relative `img[src]` (one line, temporarily) → the privacy test fails on `/private-project/architecture.png`; restore → 9 pass. If the privacy test fails with plan 01's hook as shipped, that's a plan 01 gap: fix it there (K15), not with a second hook here.
- [ ] **Step 5: Page and glue.** Write `tool.html` and `main.js`, then the page copy:
  - **EN H1:** `RTL Markdown checker`.
  - **Lead (49 words):** `Paste Markdown or open a .md file to see how Arabic, Hebrew, Persian and Urdu paragraphs will display. Each block takes its direction from its first letter, the way browsers do with dir="auto", so a paragraph that starts with an English word turns left-to-right. This page flags those blocks.`
  - **Privacy line:** `Your text stays in this browser tab. Nothing is uploaded.`
  - **CTA under the preview:** `Need it on paper? Tegel Markdown exports paginated A4 and Letter PDFs that keep right-to-left text correct.`, linking to `/markdown/` only. The tool goes live on 23 Nov, before `/download/` (W6) and the checkout gate (plan 04 Task 14) open, and plan 04's link test fails the build on a missing page.
  - **Print stylesheet:** `.preview { display: none }`, and `.print-note` shows: `Printing from this page is turned off. Tegel Markdown Pro exports paginated, right-to-left-correct PDFs.`
  - **AR page:** the same copy in Arabic (U reviews).
- [ ] **Step 6: Build.** Plan 04's build bundles `main.js` into `site/public/tools/rtl-markdown-check/` (plan 04 Task 5). Expected:
  - `grep -c "connect-src 'none'" site/static/_headers` → ≥ `1` (plan 04's `/tools/*` and `/:lang/tools/*` blocks; the tool CSP isn't a meta tag);
  - `gzip -c site/public/tools/rtl-markdown-check/main.js | wc -c` < `300000` (if over, report the size to plan 01; the highlight.js language set is theirs).
- [ ] **Step 7: Hostile input** (Review focus 5). Only a deploy applies `_headers`, so test on a preview deploy (plan 04's preview command; previews need no approval). First `curl -sI <preview>/tools/rtl-markdown-check/ | grep -i '^content-security-policy'`: it contains `connect-src 'none'`, `img-src data:` (with no `'self'` in `img-src`) and `script-src 'self'`, and not `cloudflareinsights` (proof the `!` detach dropped the global policy; joined policies would intersect and block `main.js`). Then open `<preview>/tools/rtl-markdown-check/` in Safari with Web Inspector → Network. Paste `Fixtures/markdown/hostile.md`, then `![d](/private-project/architecture.png)` and `![d](https://tegelapps.com/x.png?token=abc)`. Expected: no alert or navigation, and the Network tab shows no request after the page load, same-origin images included (K15). Screenshot to `docs/growth/evidence/tool-hostile.png`.
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
- No price in the app (plan 05 Task 3 Step 1; X30). The checkout shows it.

**Files:**
- Create `Packages/TegelKit/Sources/TegelStore/CheckoutLink.swift` and `Packages/TegelKit/Tests/TegelStoreTests/CheckoutLinkTests.swift`.
- Create `Apps/Markdown/AppTests/UpsellContextTests.swift`.
- Modify: `Apps/Markdown/App/ProUpsellView.swift` (add `UpsellContext`, the per-feature copy and the two-page preview; `UpsellFeature` stays declared here, K18), plan 02's `openWindow(id: "pro", value:)` call sites (Open Folder… and folder drops, Export as PDF, the theme picker), plan 03's `LicenceSettingsView` Buy button, and the strings catalogue (paths recorded in Step 1).

**Interfaces:**
- **Consumes:**
  - `PolarConfig.checkoutURL`, `PolarConfig.benefitID`, `LicenseManager.isPro` (master §3.3; plan 03);
  - `FolderIndex.markdownFiles(in:)`, `RendererTheme` (master §3.3); `PDFExporter.makePDFData(_ renderer: RendererWebView, paper: PaperSize) async throws -> Data` (plan 02: paginated, in memory to the caller; it passes through a private 0700 folder in the container that it deletes before returning); PDFKit's `PDFDocument(data:)` and `PDFPage.thumbnail(of:for:)`;
  - plan 02's `WindowGroup("Tegel Markdown Pro", id: "pro", for: UpsellFeature.self) { $feature in ProUpsellView(feature: feature) }` and `openWindow(id: "pro", value: UpsellFeature.<x>)`.
- **Produces:**
  - `enum UpsellFeature: String, Codable, Hashable, CaseIterable, Sendable { case folder, pdf, theme }` stays app-side in `ProUpsellView.swift` (plan 02; K18). It's the `pro` window's value, so it stays `String, Codable, Hashable`.
  - `extension PolarConfig { public func checkoutURL(ref: String) -> URL }`, the one TegelStore addition. It appends `reference_id=<ref>` via `URLComponents`, keeps existing query items, and percent-encodes the value.
  - App only, in `ProUpsellView.swift`: `@MainActor @Observable final class UpsellContext { var previewShown: Set<UpsellFeature> = []; private(set) var preview: [NSImage] = []; private(set) var pageCount = 0; func shouldShowPreview(_ f: UpsellFeature) -> Bool { previewShown.insert(f).inserted }; func loadPreview(from renderer: RendererWebView, paper: PaperSize) async throws; func clear() }`. One per launch in the environment, so "once per feature per session" is that set. `loadPreview` calls `makePDFData`, opens it with `PDFDocument(data:)`, keeps `pageCount` and **at most two** `thumbnail` images of the first pages, and drops the PDF; the app writes no file of its own (S19). A caller loads it just before `openWindow`; `ProUpsellView` shows the images and calls `clear()` in `onDisappear`. The window value stays the bare feature, so nothing large or private is encoded for state restoration.

- [ ] **Step 1: Re-validate.** Record the actual names:
  - plan 02's `ProUpsellView`, the `pro` `WindowGroup`, and its folder / PDF / theme `openWindow` call sites;
  - plan 03's Licence tab and its Buy button, and how "Buy Pro…" and "Enter Licence Key…" in `ProUpsellView` are wired (plan 03 Task 9 wires them; this task adds the `ref`);
  - how `isPro` reaches views (master §3.3 `EnvironmentValues.isPro`).

  Diff these against this task's interfaces, and list any mismatch under "Contract change requests" before coding.
- [ ] **Step 2: Failing tests.** `CheckoutLinkTests.swift` (starts with `import Testing`, `import Foundation`, `@testable import TegelStore`; the internal memberwise initialiser of `PolarConfig` is then visible; if plan 03 changed it, use plan 03's and record it in Step 1):

```swift
@Test func checkoutURLAddsReference() {
    let base = PolarConfig(apiBase: URL(string: "https://api.polar.sh")!, organizationID: "o",
                           checkoutURL: URL(string: "https://buy.polar.sh/polar_cl_abc")!, portalURL: URL(string: "https://polar.sh/x/portal")!,
                           benefitID: "b")
    #expect(base.checkoutURL(ref: "app-pdf").absoluteString == "https://buy.polar.sh/polar_cl_abc?reference_id=app-pdf")
    #expect(base.checkoutURL(ref: "a b").absoluteString.hasSuffix("reference_id=a%20b"))
    let q = URLComponents(url: base.checkoutURL(ref: "x&host=evil.example"), resolvingAgainstBaseURL: false)!.queryItems!
    #expect(q.count == 1 && q[0].name == "reference_id" && q[0].value == "x&host=evil.example")   // `&` and `=` stay inside the value
}
```

  `Apps/Markdown/AppTests/UpsellContextTests.swift` (XCTest, like plan 02's app tests; it renders the way plan 02's `PDFExporterTests` does):

```swift
@MainActor final class UpsellContextTests: XCTestCase {
    func testPreviewShowsOncePerFeaturePerSession() {
        let c = UpsellContext()
        XCTAssertTrue(c.shouldShowPreview(.pdf)); XCTAssertFalse(c.shouldShowPreview(.pdf)); XCTAssertTrue(c.shouldShowPreview(.folder))
        XCTAssertTrue(UpsellContext().shouldShowPreview(.pdf))   // new launch = new session
    }
    func testUpsellFeatureRoundTripsAsWindowValue() throws {
        XCTAssertEqual(try JSONDecoder().decode(UpsellFeature.self, from: JSONEncoder().encode(UpsellFeature.theme)), .theme)
    }
    func testPreviewIsAtMostTwoImagesAndLeavesNoFile() async throws {
        let md = (1...30).map { "## Part \($0)\n\n" + String(repeating: "Plain prose about reading documents. ", count: 60) }.joined(separator: "\n\n")
        let r = RendererWebView(); _ = try await r.render(md, options: RenderOptions(mode: .print, theme: .paper, baseURL: nil))
        let fm = FileManager.default
        let roots = [fm.temporaryDirectory, try fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)]
        let files = {   // PDFs and makePDFData's folder only, so WebKit's own cache churn can't flake the test
            Set(roots.flatMap { (fm.enumerator(at: $0, includingPropertiesForKeys: nil)?.allObjects as? [URL]) ?? [] }
                .filter { $0.pathExtension == "pdf" || $0.path.contains("tegel-pdf-") })
        }
        let before = files()
        let c = UpsellContext()
        try await c.loadPreview(from: r, paper: .a4)
        XCTAssertEqual(c.preview.count, 2); XCTAssertGreaterThan(c.pageCount, 2)
        XCTAssertEqual(files(), before)   // no file left after the call (makePDFData's private folder is gone too)
    }
}
```

- [ ] **Step 3: Run them.** `swift test --package-path Packages/TegelKit --filter checkoutURLAddsReference` and `xcodebuild test -scheme markdown -destination 'platform=macOS' -only-testing:MarkdownAppTests/UpsellContextTests`. Expected: FAIL (`checkoutURL(ref:)` and `UpsellContext` not found).
- [ ] **Step 4: Implement** to the interfaces, run both, expect PASS. Watch the injection guard fail: build the query with `percentEncodedQuery = "reference_id=" + ref.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!`, which leaves `&` and `=` raw → `checkoutURLAddsReference` fails (two query items); restore → PASS. Then watch the preview guards fail: map every page instead of the first two → `preview.count` fails; add `try data.write(to: FileManager.default.temporaryDirectory.appending(path: "p.pdf"))` in `loadPreview` → the file assertion fails. Restore both → PASS. Then `make check`: no regression.
- [ ] **Step 5: Wire the moments** (free tier only, `!isPro`). Each moment calls `openWindow(id: "pro", value:)`; `ProUpsellView(feature:)` shows the feature's title and body above plan 02's bullets and terms line (`One-time purchase for 2 Macs. No subscription. 14-day refund.`), with these buttons:
  - `Buy Pro…` opens `checkoutURL(ref: "app-<feature>")` (`app-folder`, `app-pdf`, `app-theme`);
  - `Enter Licence Key…` opens Settings on the Licence tab (plan 03; mechanism recorded in Step 1);
  - `Not Now` closes the window.

  Per feature:
  - **Folder:** free Open Folder… opens `.folder` straight away (plan 02's flow). There's no open panel first, because asking for a folder and then refusing it would be bait-and-switch.
    - title `Read Whole Folders with Pro`;
    - body `Pro shows a whole folder in a sidebar, searches across its Markdown files and reloads them as they change.`
  - **PDF:** if `upsell.shouldShowPreview(.pdf)`:
    - `try await upsell.loadPreview(from: renderer, paper:)`, then open the window; it shows the (at most two) page images side by side, not a `PDFView`, so there's no text to copy and nothing to print or save;
    - title `Export as PDF with Pro`;
    - body `Here is your document as %lld %@ pages. Saving it as a PDF is part of Pro.` (`pageCount`, `A4`/`Letter`).
    - Otherwise, the compact window: the same title, no preview.
  - **Theme:** picking Ink or Studio while free calls `openWindow(id: "pro", value: UpsellFeature.theme)`, and the stored theme stays `.paper` (plan 02's behaviour; no in-window preview, no banner).
    - title `Ink and Studio with Pro`;
    - body `Pro adds the Ink and Studio themes, in light and dark. Paper stays free.`
  - A `nil` feature keeps plan 02's generic copy and uses `app-pro`.
  - **Licence tab** (plan 03): its Buy button uses `checkoutURL(ref: "app-licence")`. App 2 compiles `LicenceSettingsView` by path (plan 06), so its Buy button carries the same ref; the KPI splits refs by product.
  - NL/FR/AR strings are drafted by C and go to manual review (Task 1 Step 2; P2-10).
- [ ] **Step 6: Price check** (plan 05 Task 3 Step 1; X30). `grep -rnE '\$ ?(1[459]|29)\b' Apps/ || echo "no price in app"` → `no price in app`.
- [ ] **Step 7: Manual check** (Review focus 4) on `m15-intel` with a Debug build, `isPro` off. Expected:
  - launch shows no upsell;
  - Export as PDF twice: the first `pro` window shows two page images, the second is compact;
  - Open Folder…: the `pro` window with the folder copy, no open panel first; no folder window opens;
  - picking Ink opens the `pro` window with the theme copy, and Settings ▸ Appearance still shows Paper;
  - `Enter Licence Key…` lands on Settings ▸ Licence;
  - with the Debug `isPro` override on (`-TGForcePro YES`), none of these appear;
  - `Buy Pro…` opens a URL ending `reference_id=app-pdf` (screenshot the address bar).
  - Screenshots in light, dark and Arabic UI, then `design-review`, with every finding at P1 or above fixed.
- [ ] **Step 8: Commit** (`git add Packages/TegelKit/Sources/TegelStore/CheckoutLink.swift Packages/TegelKit/Tests/TegelStoreTests/CheckoutLinkTests.swift Apps/Markdown/App/ProUpsellView.swift Apps/Markdown/AppTests/UpsellContextTests.swift <plan 02/03 files from Step 1> docs/growth/evidence`, `feat(app): honest upgrade moments in the Pro window with per-placement checkout refs` + trailer). Run Task 23 (stage 4 required: this touches TegelStore/licensing), then merge before RC1 (plan 05 Task 3, Wed 25 Nov), or hold the branch for v1.1.
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

**Legal basis:** Tw 11.7 lid 1, prior consent (K9). Consent is plan 05's checkout field `marketing_opt_in`, an unticked checkbox labelled `Email me set-up tips and news about Tegel apps` (plan 05 Task 2). Only buyers who ticked it get these emails; lid 4 soft opt-in is not relied on. Every message carries MailerLite's unsubscribe link. Licence and receipt mail is Polar's and is not part of this.

**Files:** Create `scripts/sync_buyers.py`, `scripts/test_sync_buyers.py`; add to `docs/growth/email-copy.md`.

**Interfaces:**
- **Consumes:** `polar_sales.fetch_orders(token, org_id, product_id, after, before)` and `window(start, end)` (plan 05 Task 6); Order fields `status`, `net_amount`, `product_id`, `custom_field_data`, `customer` (orders/get.md, 27 Oct). Step 1 confirms that `customer.email` exists.
- **Order (K11, as Task 4 Step 8):** Steps 1, 5 and 6 need no code and start Tue 24 Nov. Steps 2–4 start Tue 1 Dec on `m08-lifecycle`, branched with `git switch -c m08-lifecycle m05-launch` right after plan 05 Task 6's commit, because `polar_sales.py` reaches `main` only on Mon 7 Dec.
- **Produces:**
  - `erased_hash(email: str) -> str`: SHA-256 hex of the stripped, lowercased address. `ERASED` = `local-docs/erased-buyers.sha256` (repo-relative; `local-docs/` is already gitignored), one hash per line.
  - `plan_sync(orders: list[dict], product_id: str, erased: set[str] = frozenset()) -> dict[str, list[str]]` with keys `add`, `remove`, `skipped`. Emails are lowercased and de-duplicated.
    - **add:** emails with a counted sale (plan 05 rule) whose order has `custom_field_data.get("marketing_opt_in") is True`.
    - **remove:** emails of `refunded` orders, unless the same email also has a counted sale.
    - **skipped:** emails with a counted sale but no opt-in (field missing or `False`). All three lists are sorted.
    - An email whose `erased_hash` is in `erased` is in no list (K10): Polar keeps the order, so without this the next run would re-create an erased buyer and restart DAY 0/7/21.
  - **Erasure** (K10; a request under the privacy page's deletion promise, handled in plan 05 Task 4's support routine): first append the hash, with the address copied from the request and never typed into a command: `pbpaste | python3 -c 'import sys; sys.path.insert(0, "scripts"); from sync_buyers import erased_hash; print(erased_hash(sys.stdin.read()))' >> local-docs/erased-buyers.sha256`. Then forget the subscriber in MailerLite (`POST /api/subscribers/{id}/forget`). Hash first, so a sync in between can't re-add them. The file holds hashes only; back it up wherever `.env` is backed up.
  - `subscriber_payload(email: str, group_id: str) -> dict` → `{"email": email, "groups": [group_id], "status": "active"}`. It never contains `resubscribe`.
  - `LAUNCH = {"markdown": "2026-12-08", "data": "2027-02-02"}`.
  - CLI: `python3 scripts/sync_buyers.py --product markdown|data [--dry-run]` prints `added=<n> removed=<n> skipped=<n>`. It never prints an email.
    - It reconciles **every** order since launch each day (K9): `after, before = window(LAUNCH[p], <tomorrow, Europe/Amsterdam>)`, then `fetch_orders(token, org, pid, after, before)` called positionally. No `--days`: a missed day, or a refund weeks later, is caught on the next run. Mark it in code: `# ponytail: reads every order since launch each day; page by updated_at once orders pass ~2,000`.
    - Env: `POLAR_ACCESS_TOKEN`, `POLAR_ORGANIZATION_ID`, `POLAR_PRODUCT_ID_<P>`, `MAILERLITE_API_TOKEN`, `MAILERLITE_GROUP_BUYERS_<P>`; exits 2 naming any missing key. `--dry-run` makes no MailerLite call.
    - Reads `ERASED` before fetching orders and passes it to `plan_sync`. A missing file exits 2 (`missing local-docs/erased-buyers.sha256`), so a lost list can never re-add erased buyers silently; an empty file is fine.
    - **Upsert:** `POST /api/subscribers`, which is idempotent; an existing member doesn't re-trigger the automation.
    - **Remove** (a refund removes the buyer and cancels queued sends, K9): look up the subscriber by email (`GET /api/subscribers/{email}`), then `DELETE /api/subscribers/{id}/groups/{group_id}`, or the Step 1 fallback. A 404 counts as done.

- [ ] **Step 1: Check steps.**
  - In the Polar sandbox (Task 4 Step 1 order, opt-in ticked): the order JSON has `customer.email` and `custom_field_data`. Record the custom-field key exactly as Polar returns it (`marketing_opt_in` expected, value `true`).
  - In MailerLite, with `STUDIO_EMAIL+t1@…` as an **unsubscribed** test subscriber, an upsert with `status:"active"` leaves it unsubscribed.
  - **Account-wide API double opt-in (Task 6 Step 4):** upsert a new `STUDIO_EMAIL+t3@…` with `subscriber_payload`'s body into a scratch group. Expected: status `active`, and no confirmation email arrives within 10 minutes. If the waitlist confirmation arrives instead, buyers would get the waitlist wording and stall unconfirmed: don't activate Step 7; tell the user.
  - **Waitlist body on an active subscriber** (K4): with `STUDIO_EMAIL+t3@…` now `active`, `POST /api/subscribers` with Task 7's waitlist body (`{email, groups:[<scratch group>], status:"unconfirmed"}`), then `GET /api/subscribers/<email>` and read `status`. Expected: still `active`. If it reads `unconfirmed`, a buyer who joins the waitlist would drop out of the lifecycle emails: on a short branch `m08-waitlist-status`, drop `status` from the waitlist body (Task 7's interface and first test), run Task 7 Steps 2–4, Task 23, merge, redeploy with Task 8 Step 6's approval before Tue 8 Dec, and repeat Task 8 Step 7's end-to-end check to prove a new address still gets the confirmation email.
  - **Queued sends** (unverified on 27 Oct): add `STUDIO_EMAIL+t2@…` to a scratch group whose scratch automation waits 1 day before one email, then remove it with `DELETE /api/subscribers/{id}/groups/{group_id}`. Expected: the automation's subscriber list no longer shows it as queued, and no email arrives the next day. If it's still queued, the sync's remove uses `DELETE /api/subscribers/{id}` instead (the subscriber leaves every group and automation; a buyer of both apps is then re-added to the other group by that product's next sync). Delete the scratch group and automation (Free allows 3 automations).
  - Record all five results here.
- [ ] **Step 2: Failing tests.**

```python
import contextlib, io, os, tempfile, unittest
from pathlib import Path
from unittest import mock
import sync_buyers
from sync_buyers import erased_hash, plan_sync, subscriber_payload

ENV = {"POLAR_ACCESS_TOKEN": "t", "POLAR_ORGANIZATION_ID": "o", "POLAR_PRODUCT_ID_MARKDOWN": "prod-md",
       "MAILERLITE_API_TOKEN": "m", "MAILERLITE_GROUP_BUYERS_MARKDOWN": "9"}
def o(status, net, email, opt=None, pid="prod-md"):
    return {"status": status, "net_amount": net, "product_id": pid, "customer": {"email": email},
            "custom_field_data": {} if opt is None else {"marketing_opt_in": opt}}
class SyncTests(unittest.TestCase):
    def test_plan_adds_only_opted_in_and_removes_refunds(self):
        r = plan_sync([o("paid", 1400, "A@x.com", opt=True), o("paid", 1400, "a@x.com", opt=True),
                       o("paid", 1400, "b@x.com"), o("paid", 1400, "f@x.com", opt=False),
                       o("refunded", 1400, "c@x.com", opt=True), o("refunded", 1400, "a@x.com", opt=True),
                       o("paid", 0, "d@x.com", opt=True), o("paid", 1500, "e@x.com", opt=True, pid="other")], "prod-md")
        self.assertEqual(r, {"add": ["a@x.com"], "remove": ["c@x.com"], "skipped": ["b@x.com", "f@x.com"]})
    def test_payload_never_resubscribes(self):
        p = subscriber_payload("a@x.com", "9")
        self.assertEqual(p, {"email": "a@x.com", "groups": ["9"], "status": "active"}); self.assertNotIn("resubscribe", p)
    def test_erased_buyer_is_never_re_added(self):   # K10
        r = plan_sync([o("paid", 1400, "G@x.com", opt=True), o("refunded", 1400, "h@x.com", opt=True)], "prod-md",
                      erased={erased_hash("g@x.com"), erased_hash(" H@x.com\n")})
        self.assertEqual(r, {"add": [], "remove": [], "skipped": []})
    def test_cli_reads_every_order_since_launch_and_dry_run_sends_nothing(self):
        empty = Path(tempfile.mkdtemp(), "erased"); empty.touch()
        fetch, out = mock.Mock(return_value=[o("paid", 1400, "a@x.com", opt=True)]), io.StringIO()
        with mock.patch.dict(os.environ, ENV, clear=True), mock.patch.object(sync_buyers, "fetch_orders", fetch), \
             mock.patch.object(sync_buyers, "ERASED", empty), \
             mock.patch("urllib.request.urlopen", side_effect=AssertionError("network in dry run")), contextlib.redirect_stdout(out):
            sync_buyers.main(["--product", "markdown", "--dry-run"])
        self.assertEqual(fetch.call_args.args[3], "2026-12-07T23:00:00Z")   # launch day, 00:00 CET
        self.assertIn("added=1 removed=0 skipped=0", out.getvalue()); self.assertNotIn("a@x.com", out.getvalue())
    def test_missing_erasure_list_fails_closed(self):   # K10: a lost list must not re-add erased buyers
        with mock.patch.dict(os.environ, ENV, clear=True), mock.patch.object(sync_buyers, "ERASED", Path(tempfile.mkdtemp(), "missing")), \
             mock.patch.object(sync_buyers, "fetch_orders", side_effect=AssertionError("orders read")), self.assertRaises(SystemExit) as e:
            sync_buyers.main(["--product", "markdown", "--dry-run"])
        self.assertEqual(e.exception.code, 2)
```

- [ ] **Step 3: Run them.** `python3 -m unittest discover -s scripts -p 'test_sync_buyers.py' -v`. Expected: FAIL (`No module named 'sync_buyers'`).
- [ ] **Step 4: Implement** to the interfaces. Run them. Expected: `OK` (5 tests). Then watch the consent guards fail: make `add` ignore `marketing_opt_in` → the first test fails with `b@x.com`/`f@x.com` in `add`; set `after` to yesterday → the CLI test fails; drop the `erased` filter → the erasure test fails with `g@x.com` in `add`; treat a missing `ERASED` as empty → the fail-closed test fails. Restore all four → `OK`.
- [ ] **Step 5: Lifecycle copy** in `email-copy.md`. Every email ends with this footer:

```text
You're getting this because you bought Tegel Markdown and asked for set-up tips and news at checkout. Three short emails in your first month, then only news about Tegel apps. Unsubscribe: <MailerLite unsubscribe link>
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
  - **Precondition** (K9): open the live production checkout (don't pay) and read the checkbox. Expected: label verbatim `Email me set-up tips and news about Tegel apps`, **unticked** on load. If either differs, don't activate; tell the user, because those buyers didn't give this consent.
  - **Erasure list:** `mkdir -p local-docs && touch local-docs/erased-buyers.sha256` before the first run (an empty list; the sync exits 2 without it).
  - **Coordination:** plan 05 Task 4's daily routine gains this command (K1), run with `--dry-run` first on 9 Dec:

    ```bash
    . scripts/lib/env.sh && POLAR_ACCESS_TOKEN="$(envget POLAR_ACCESS_TOKEN)" POLAR_ORGANIZATION_ID="$(envget POLAR_ORGANIZATION_ID)" \
      POLAR_PRODUCT_ID_MARKDOWN="$(envget POLAR_PRODUCT_ID_MARKDOWN)" MAILERLITE_API_TOKEN="$(envget MAILERLITE_API_TOKEN)" \
      MAILERLITE_GROUP_BUYERS_MARKDOWN="$(envget MAILERLITE_GROUP_BUYERS_MARKDOWN)" python3 scripts/sync_buyers.py --product markdown
    ```

  - **Expected:** `added=` equals the distinct opted-in buyers since launch (it grows by each day's new opted-in sales); `removed=` equals the distinct fully refunded buyers; `skipped=` equals buyers who didn't tick the box.
- [ ] **Step 8: Commit** (`git add scripts/sync_buyers.py scripts/test_sync_buyers.py docs/growth/email-copy.md`, `feat(growth): daily buyer sync for opted-in lifecycle email` + trailer). Run Task 23 (stage 4: MailerLite token, PII handling, consent filter, refund removal, erasure list) with `BASE=$(git merge-base HEAD m05-launch)`, so plan 05's commits stay out of scope. Merge to `main` only after plan 05 Task 10 Step 3 has merged `m05-launch` (Mon 7 Dec), and before the first sync on Wed 9 Dec (K11).
- **Success:** ≥ 10 public reviews by Mon 8 Mar, of which at least half within 30 days of a day-21 email (Task 18 log).

### Task 15: Launch-day and App 2 emails (C drafts, U sends 🔒; Tue 8 Dec, Tue 2 Feb)

- [ ] **Step 1: Launch email to `waitlist`** into `email-copy.md`. It goes out at **Tue 8 Dec 09:30 CET**, after PH goes live at 09:01 (coordination: one row in plan 05's launch-day runbook, Task 9). There is no upvote ask anywhere (PH and HN rules; HR2).

```text
Subject: Tegel Markdown is out
Tegel Markdown is available today for macOS 14 and later.
Press Space on any .md file in Finder to read it with Mermaid diagrams and right-to-left text that displays the right way round. That part is free.
Pro is a one-time licence for 2 Macs: folder mode with search and live reload, paginated A4 and Letter PDF export that keeps right-to-left text correct, and three themes with light and dark.
Introductory price $14 until Mon 14 Dec 2026 23:59 CET. From 15 Dec: $19.
In the EU the checkout shows €14, then €19, VAT included (K10; the user's confirmed EUR points).
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
- [ ] **Step 1b 🔒 Close sign-up** (K13; Tue 8 Dec, right after the send). The consent promises an email "when Tegel Markdown launches (8 Dec 2026)", which nobody joining later can get, so the list closes rather than change its promise; everyone on it keeps the two emails they agreed to. U approves "close the waitlist form":
  - on `main`, remove the `{{partial:waitlist-form}}` lines from `site/content/en/index.md` and `site/content/en/rtl-markdown-to-pdf.md`, and the `{{partial:waitlist-form-ar}}` line from `site/content/ar/arabic-markdown-pdf.md` if it has one; `(cd site && bun test)` → 0 fail; Commit: those files, `feat(site): close the waitlist form` + trailer; push;
  - delete the production mail token: `. scripts/lib/env.sh && CLOUDFLARE_API_TOKEN="$(envget CLOUDFLARE_API_TOKEN)" CLOUDFLARE_ACCOUNT_ID="$(envget CLOUDFLARE_ACCOUNT_ID)" bunx wrangler@4.151.2 pages secret delete MAILERLITE_API_TOKEN --project-name tegel --env production`;
  - deploy with plan 04's production command (a deployment keeps the secrets it was made with: Task 7 Step 6).
  - Expected: `curl -s https://tegelapps.com/ | grep -c 'action="/api/waitlist"'` → `0`, the same for the RTL page and `/ar/arabic-markdown-pdf/`, and a valid POST with Task 8 Step 7's headers and `email=<STUDIO_EMAIL+closed@…>&consent=on&website=` → `303 https://tegelapps.com/waitlist/error/` with no email sent.
- [ ] **Step 1c 🔒 Late confirmations** (Mon 14 Dec, the last intro-price day). A sign-up made before the close but confirmed after Step 1's send hasn't had the launch email it was promised. U approves "send the launch email to late confirmations, then drop unconfirmed sign-ups":
  - in MailerLite, segment the waitlist group by "subscribed after <Step 1's recorded send time>" and send it the Step 1 campaign unchanged; record the count (often 0);
  - delete the subscribers still `unconfirmed` in the waitlist group (they never gave consent; nothing is kept), so nobody can confirm into a promise that can't be kept. Record the count.
- [ ] **Step 2: App 2 emails** (Tue 2 Feb 2027, 09:30 CET). The product facts and the price come from plan 06; if plan 06 sets an intro price, use its dated wording verbatim (HR3).
  - **To `waitlist`** (email 2 of 2). Subject `Tegel Data is out (and this list is now closed)`. Body:
    - what Tegel Data reads: JSON, JSONL, YAML, TOML, CSV, `.env` masked;
    - its free Quick Look pack and its Pro features (plan 06's list);
    - the price, read-only, no telemetry, 14-day refund;
    - `ref=email-launch2`;
    - the closing line: `That was the second and last email. The waitlist is deleted today.`
  - **To `buyers-markdown`** (opted-in buyers only: consent, lid 1, K9, HR7; measured as `email-crosssell` sales ÷ emails sent). Copy and recipients come verbatim from plan 06 Task 15's `docs/launch/data-crosssell-email.md`: its subject, body, `?reference_id=email-crosssell` links, closing line and segment rule (P1-10). This plan adds only the footer and `{$unsubscribe}`, then sends at **09:30 CET**. If the group is over MailerLite Free's 250 subscribers, ask the user before sending (plan 06's segment rule).
  - **Coordination:** plan 08 owns the MailerLite account and this one send; plan 06 sends nothing. Plan 06's "cross-sell email" exit item is met by this send.
  - 🔒 U approves both copies and the sends. Expected: sent counts recorded.
- [ ] **Step 3: Delete the waitlist** (Tue 2 Feb, after the send). For each subscriber in `waitlist` who isn't in a buyers group, `POST /api/subscribers/{id}/forget` ("completely deleted and forgotten within 30 days", developers.mailerlite.com). Those who are in a buyers group only leave the waitlist group: `DELETE /api/subscribers/{id}/groups/<MAILERLITE_GROUP_WAITLIST>`. Expected: the group has 0 members, and the consent promise is kept.
- [ ] **Step 4: v1.1 news** to `buyers-markdown` on plan 07's v1.1 release date. Subject `Tegel Markdown 1.1: math, footnotes and custom CSS, free for every owner`. Body: three features from plan 07, `Update from the app menu: Tegel Markdown > Check for Updates`, and `ref=email-v11` on any checkout link. 🔒 send.
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
- **Success:** ≥ 5 referring domains in 90 days (GSC Links) and ≥ 1 AI citation of this URL by the 6 Apr check.

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
  6. Log: date, venue, URL, approval, and the article's Web Analytics visits over 7 days.
- [ ] **Step 3: Brand accounts 🔒** (U creates them; open question 2).
  - Name `Tegel Apps`, handle `tegelapps` (or the nearest free one); avatar = the tile; bio `Native, read-only Mac apps. Made in the Netherlands.`
  - No face anywhere (HR6). Handles and emails go in `.env` (add the names to `.env.example`); each password goes in the Keychain as `tegel-<service>`, e.g. `tegel-bluesky`, `tegel-mastodon` (master §6).
  - Mastodon instance: one that allows commercial project accounts. Check the instance rules before signing up; Fosstodon is FOSS-only, so not that one.
- [ ] **Step 4: Silent clips** from plan 05's demo: `ffmpeg -ss <start> -t 8 -i site/static/media/tegel-markdown-demo.mp4 -an -vf "fps=24,scale=1080:-2" -c:v libx264 -crf 24 -pix_fmt yuv420p -movflags +faststart docs/growth/clips/<name>.mp4`. Each clip passes the Task 1 `ffprobe` audio check (empty output).
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
- **Success:** cross-sell sales (`email-crosssell`) ÷ emails sent are recorded on Tue 16 Feb, and App 2's ≥ 10 sales by Thu 4 Mar (BUSINESS-PLAN §12) are tracked in the weekly report.

### Task 22: Months 5–12 cadence and gate inputs (C + U; Mar – Oct 2027)

- [ ] **Step 1: Standing routines.**
  - weekly review (Task 5);
  - monthly AI check (Task 13);
  - per-article distribution (Task 19);
  - review replies (Task 18);
  - daily buyer sync (Task 14), with `--product data` from 2 Feb.
- [ ] **Step 2: Gate inputs.** Three working days before each gate (G2 Mon 8 Mar, G3 Fri 30 Apr, G4 Fri 29 Oct 2027), write `## Growth inputs to G<n>` in `docs/growth/experiments.md`. It holds:
  - the Scoreboard values;
  - what worked (sales by ref and by channel);
  - what didn't (null experiments);
  - the honest forecast vs the BUSINESS-PLAN central case.

  Plan 07 records the gate decision. This plan only supplies the evidence.
- [ ] **Step 3: Quarterly re-plan** (first Tuesday of Feb, May, Aug). Drop every channel with zero attributable sales or sign-ups in its last 90 days (karpathy: no vanity work), and move its hours to the channel with the most attributable sales per hour.
- [ ] **Step 4: Seasonal timing** (HR8, neutral). The macOS 28 release (September 2027): one article on Quick Look and Markdown changes in macOS 28, published within 7 days of release (plan 04 slot), after the June beta re-test (plan 07).
- [ ] **Step 5: Plan close** (Fri 29 Oct 2027). Write a final `## Close` in `experiments.md`: every Scoreboard row's final value, then run Task 23 Step 2.

### Task 23: Procedure P per code branch → `docs/reviews/m08.md`

**When:** before merging each code branch: `m08-kpi` (Task 4), `m08-kpi-net` (Task 4 Step 8), `m08-waitlist` (7–8), `m08-rtl-tool` (9), `m08-onboarding` (11, only with a fix), `m08-upsell` (12), `m08-lifecycle` (14). The code ships months apart, so one end-of-plan run would review November code in October 2027. Each run appends `## <branch>` to `docs/reviews/m08.md`.

Run **Procedure P (master §11)** with these deltas (B1):
- **Id and branch:** `m08`, the branch above.
- **Base:** P's `git merge-base HEAD main`, except for `m08-kpi-net` and `m08-lifecycle`, which are cut from `m05-launch` (K11): `BASE=$(git merge-base HEAD m05-launch)`, and they merge only after `m05-launch` has.
- **Stage 2:** `make check` (it runs `test-site` and `test-scripts`, master §2). Until those targets exist, also run `(cd site && bun test)` and `python3 -m unittest discover -s scripts -p 'test_*.py'`. Record the counts.
- **`/cso` scope (stage 4), per branch:**
  - **`m08-waitlist`** (public endpoint): the Host check against `SITE_ORIGIN` / `www.` before anything else, then Origin, Content-Type and size (a streamed body stops at 2,049 bytes); the KV per-IP limit, daily cap and per-address cooldown, failing closed to `later`; no PII in logs, responses or KV keys (`ip:` and `addr:` SHA-256 only); `MAILERLITE_API_TOKEN_PAGES` in Pages env only, preview and production set with their own `--env`, and never the local `MAILERLITE_API_TOKEN`; the header-injection test case.
  - **`m08-kpi`, `m08-kpi-net` and `m08-lifecycle`:** tokens read from env (K1) and never printed (`… 2>&1 | grep -ciE 'bearer|polar_(pat|oat)_'` → `0`); HTTPS only; MailerLite writes limited to group membership; emails never printed; `sync_buyers` adds only `marketing_opt_in == true` and reads every order since launch; a refund removes the buyer and its queued sends (Task 14 Step 1 result); an erased buyer is never re-added, and a missing erasure list exits 2.
  - **`m08-rtl-tool`:** `SANITIZE_CONFIG` plus `addHooks(DOMPurify)` with no `fileImages`, so every non-`data:image/*` image source is dropped (K15); `RETURN_DOM_FRAGMENT` into `replaceChildren`; plan 04's `/tools/*` and `/:lang/tools/*` CSP blocks (`! Content-Security-Policy`, `img-src data:`, `connect-src 'none'`); the hostile fixture; no `innerHTML` on unsanitised input.
  - **`m08-upsell`** (TegelStore, licensing): `checkoutURL(ref:)` can't be steered to another host; the preview leaves no file after the call and holds at most two page images; no key in logs.
  - **`m08-onboarding`** (only if Task 11 needed a fix): the external URL scheme and any strings change.
  - **Every branch:** `git log -p $BASE..HEAD | grep -nE 'polar_(pat|oat)_[A-Za-z0-9]{8,}|mlsn\.|eyJ[A-Za-z0-9_-]{20,}|PRIVATE KEY'` → no output.
- **Stage 5 question:** "How does this mislead a buyer, email someone who didn't consent, leak data or break the halal guardrails?"
- **Design review shots:** only `m08-upsell` (the three `pro` window variants and the compact window) and `m08-rtl-tool` (the tool page), light, dark and Arabic, in `docs/reviews/m08-design/`.
- **Merge:** `git merge --no-ff <branch> -m "merge: m08 <branch>"` per P stage 11.

- [ ] **Step 1: Run Procedure P** for the branch with the deltas above. Commit: `docs/reviews/m08.md docs/reviews/m08-design`, `docs(reviews): m08 <branch> pipeline results` + trailer; then merge and push per P.
- [ ] **Step 2: Plan close** (Task 22 Step 5): add `## Close` to `m08.md`, listing each merged branch with its pipeline date, and confirm that every `m08-*` branch merged to `main` has a section.

---

## Self-review notes

- **Verified 27 Oct (primary):**
  - Polar checkout-link params and Order/Checkout schemas; MailerLite Free limits, API fields, double opt-in and anti-spam policy;
  - Tw 11.7 lid 1/4/7; Cloudflare Pages Functions and pricing;
  - the macOS 15.7.7 Settings plist; llmstxt.org; HN guidelines;
  - list and directory rules (T17 table); Hsoub, Virgool and Obsidian codes; dev.to canonical.
- **Check steps (unverified):**
  - whether `reference_id` reaches Order `metadata` (T4 S1);
  - `wrangler pages secret put|list --env preview` (third-party mirror only) and the KV binding on preview (T7 S6);
  - the MailerLite tracking toggle (T6 S4), lookup by email, unsubscribe-safe upsert, and whether a group removal cancels queued automation sends (T14 S1);
  - the deep link on 14/26/27 (T11 S2);
  - Reddit sidebars, Slant, Mac Apps Library, Hashnode (T17, T19);
  - the GSC `Chart.csv` and `Pages.csv` file names and headers (first export).

## Contract change requests

CR 1–3, 4(a)–(c), 6 and 13 accepted and applied to master §3.1–§3.3, plans 01, 02, 04 and 05, and Task 4 Step 8 (27 Oct); history in `docs/reviews/m00-consolidated.md`. Open:

4. **Plan 04 build/deploy:**
   - (d) include `partials/waitlist-form.html` on the home and RTL pages until the launch email goes out on Tue 8 Dec 2026, then drop it (Task 15 Step 1b, K13);
   - (e) every checkout link carries `?reference_id=site-<slug>`;
   - (f) `robots.txt` allows the AI crawlers in Task 13 Step 3.

   **Status:** (f) is a no-op: `robots.txt` already allows all.
5. **Plan 04 schedule and wording:** the privacy page (with the Task 8 Step 4 text and the MailerLite DPA) goes **live by Mon 16 Nov**, before the waitlist, instead of with the W5 legal pages. Its buyer-sync sentence and its `pages.test.js` check use the opt-in label `Email me set-up tips and news about Tegel apps` (K9), and its tool sentence says images are dropped (K15, Task 9).
<!-- numbers kept, so cross-plan references resolve -->
7. **Plan 05 operations:**
   - Task 9 runbook gets a row at 09:30 for U 🔒 "Send the waitlist launch email (plan 08 Task 15)";
   - the Task 4 daily routine runs Task 14 Step 7's sync command (K1, no `.env` sourcing);
   - the Quick Look deep-link check has one owner, plan 08 Task 11 Step 2; plan 05 only reserves its slot on lease L2 (B25);
   - if T4 S1 shows the ref only on checkouts, the production token adds `checkouts:read` (🔒).
8. **Master §6 accounts:**
   - MailerLite moves to **W2** (waitlist + lifecycle), not W13;
   - add the Bluesky/Mastodon(/X) brand accounts (U-created, faceless);
   - add the Workers KV namespaces `tegel-waitlist` (Production) and `tegel-waitlist-preview` (Preview), each bound as `WAITLIST_KV` to the `tegel` Pages project; no Cloudflare analytics token (visits come from Web Analytics, B4).
9. **`.env.example`:** add `MAILERLITE_API_TOKEN`, `MAILERLITE_API_TOKEN_PAGES`, `MAILERLITE_GROUP_WAITLIST`, `MAILERLITE_GROUP_BUYERS_MARKDOWN`, `MAILERLITE_GROUP_BUYERS_DATA`, `CLOUDFLARE_KV_WAITLIST_ID`, `CLOUDFLARE_KV_WAITLIST_PREVIEW_ID` (+ the brand-account keys).
10. **`make check`:** plan 04's `test-site` (`cd site && bun test`) discovers `site/test/functions/` and `site/tools/`; plan 08 changes it only if Task 7 Step 4 shows otherwise. The Python tests (`test_kpi.py`, `test_sync_buyers.py`, plan 05's `test_polar_sales.py`) run under plan 05's `test-scripts` target (X21).
11. **Brief deviation:** the KPI script is `scripts/kpi.py`, not `kpi.ts`, so it imports plan 05's `polar_sales.py` instead of porting it.
12. **Plan 06:** its "cross-sell email to App 1 buyers" exit item is delivered by Task 15 Step 2. Plan 06 Task 15 supplies the copy (`docs/launch/data-crosssell-email.md`) and the segment rule; plan 08 owns MailerLite and the send (P1-10).
<!-- numbers kept, so cross-plan references resolve -->
14. **Plan 04 deploy:** if the Pages project is configured from a `wrangler.toml`, it carries the `WAITLIST_KV` binding per environment (production `CLOUDFLARE_KV_WAITLIST_ID`, preview `CLOUDFLARE_KV_WAITLIST_PREVIEW_ID`); otherwise Task 7 Step 6's dashboard binding stands. A missing binding fails closed (every sign-up gets `later`), so Task 7 Step 6's KV check is the gate.
