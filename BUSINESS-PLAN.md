# Mac Utility Studio: business plan

*Written 27 Oct 2026. Every number carries a label:*

| Label | Meaning |
|---|---|
| **[V]** | Verified from a primary source I opened on 27 Oct 2026 |
| **[S]** | Secondary source |
| **[E]** | Estimate, with the arithmetic shown |
| **[A]** | Assumption, with the test that would check it |

*Superscript numbers point to §16. FX: EUR/USD **1.1188** (ECB, 26 Oct 2026) [V⁵²].*

---

## 1. Verdict box

| | Low | **Central** | High |
|---|---|---|---|
| Net/month, month 3 (Jan 2027; app 1 in its 2nd sales month) | €5 | **€50** | €490 |
| Net/month, month 6 (Apr 2027; apps 1 and 2 live) | €30 | **€150** | €760 |
| Net/month, month 12 (Oct 2027; 3 apps live) | €95 | **€350** | €1,450 |

- **P(≥ €1k net/month by month 6):** about **19%**, within a range of 14–24% [E, §9].
  - This is lower than the discovery's 20–25% and its central €400.
  - The reason: I re-pulled 85 desktop apps and restricted the reference class to solo founders without an audience, which is the founder's actual position.
- **Verified ceiling:**
  - **Single app:** $8,964 in the last 30 days (Cooldock) [V¹]. Cooldock comes from a 2–5-person studio that had already been selling to its own customer list for about 17 months (ExtraDock was on sale at $4.99 by 11 Jan 2025, per a Wayback snapshot, not TrustMRR) [V].
  - **That studio's portfolio:** about $13.6k in 1–26 Oct 2026 [V¹].
  - **Best launch month in the cohort:** bytemail, $15,283 in Oct (founded 19 Sep; Sep $238); its founder has 5,281 X followers [V¹].
  - **Closest comparable to the chosen app 1:** MacMD Viewer, peak $3,023/month [V¹].
  - **€100k/month** is **not evidenced anywhere** in the 85-app cohort. The best single month was $27.8k (SlapMac, a viral novelty that then fell 97%) [V¹].
- **Time to first revenue:** about 6 weeks. App 1 is due to launch Tue **8 Dec 2026** [A].
- **Weekly hours:** about 30 h/week until app 2 ships (W1–W15) [A], then 15–20 h/week. Support takes 5–20 min/day [E, §6.4].
- **Verdict:** **Go, as a cheap, gated experiment, not as an income plan.**
  - Build two read-only developer viewers that share one renderer.
  - Distribute through SEO plus a few launch posts.
  - Kill fast if app 1 makes < 10 sales in its first 30 days.

---

## 2. What it is

A studio, working name **Tegel** (§15), of small native Mac apps.

- **Product format:**
  - SwiftUI/AppKit.
  - One-time licence at $15–19, covering 2 Macs.
  - Sold direct through **Polar** as merchant of record (MoR).
  - Notarised Developer ID builds, with Sparkle updates.
- **Cross-sell:** each new app is sold to the previous apps' buyers.
- **The first two apps are read-only "readers" for the files AI coding agents produce:**
  - **App 1:** Markdown + Mermaid reader with Quick Look, correct right-to-left (RTL) rendering and paginated PDF export.
  - **App 2:** JSONL/JSON/YAML/TOML/CSV/`.env` reader and Quick Look pack, including a Claude Code / Codex session-transcript mode.
- **Target buyer:** Mac developers and technical writers who use Claude Code, Codex or Cursor and drown in `.md` plans, specs and `.jsonl` logs that Finder and Quick Look render badly.
- **Secondary buyer (app 1):** people who write Arabic, Hebrew, Persian or Urdu Markdown and need it to render and print correctly.

---

## 3. Evidence

### 3.1 Base rate: re-pulled and corrected

**Method:**
- On 27 Oct 2026 I re-pulled 600+ TrustMRR `.md` profiles: keyword slugs from the 11,904-slug sitemap, plus the SwiftUI/Swift/Utilities pages [V¹].
- Each profile was summarised by script.
- **Inclusion rule:**
  - installed desktop app (macOS and/or Windows);
  - sold to end users;
  - not web/SaaS/API/Chrome/iOS-only;
  - TrustMRR founded date ≥ 2025-08-01.
- That gives **n = 85** apps (84 in the scratchpad `mus/tools/cohort.py`, plus MDViewer, which meets the rule but had been left out; added in the independent check).
- **Limits:**
  - TrustMRR shows only Nov 2025–Oct 2026 monthly data.
  - October covers about 26 days.
  - Founded dates are sometimes wrong. ExtraDock was already selling in Jan 2025.
  - Keyword sampling misses some apps.

| Metric | Discovery claimed | **Re-pulled (27 Oct 2026)** |
|---|---|---|
| Cohort size | 47 | **85** (wider sweep; the original list was not saved, so it can't be diffed) |
| Ever had a $1k month | 26% | **22%** (19/85) [V¹] |
| $1k month within 6 months of founding | 21% (10/47; included apps younger than 6 months) | **27%** (8/30), counting only apps ≥ 6 months old [V¹] |
| …same, **solo founders, < 2,000 followers, not the studio** | n/a | **14% (3/21)** [V¹] |
| Median last-30-day revenue, apps ≥ 3 months old | $177 (n=23) | **$114** (n=41, 3 stale profiles excluded) [V¹] |
| …same, solo/no-audience | n/a | **$58** (n=31); p25 **$0**, p75 $383; 13% ≥ $1k [V¹] |
| TrustMRR-wide: all-time revenue < $1k | 67.7% | **67.7%** (stats page updated 27 Oct 2026 04:16) [V³] |

**Corrections to the discovery:**
- **ScreenSnap Pro's "$4,653 last 30 days" is stale.**
  - Its revenue last synced on **4 Aug 2026** [V¹], so it is not October data.
  - It is excluded from the current medians.
- **Shiori is a studio app that flopped.**
  - It is the same founder as Cooldock, ExtraDock, DockFlow and ExtraBar (Asaf Mazuz) [V²].
  - Peak $655, now $114/month [V¹].
  - Even the studio with a customer list misses.
- **Cooldock's team size is "2–5 people", not solo** [V¹].
- **Headroom is not a one-time Mac utility.**
  - It is a cross-platform *subscription* ($3–40/month) with an AppSumo lifetime deal [V¹].
- **helumi is a cloud-storage subscription** ($10/TB/month) [V¹], not a utility licence.

**Survivorship haircut (×0.6) and the attempt to test it:**
- *Founder-reported data:*
  - Indie Hackers and Reddit return HTTP 403 to scripts. The Arctic Shift and PullPush archives returned 429/500.
  - The only usable founder report is Otabek's dev.to post: Halo, 66 orders and about $500 in 23 days, with no audience [S³⁶].
  - TrustMRR shows Halo at $762 in October [V¹], which is **consistent**.
  - An IH post title reports "first paying customer: $19 after 6 days and ~40 downloads" [S³⁷].
- *What the sample itself shows:* a quarter of solo listings made **$0** in the last 30 days [V¹]. Failures do list on TrustMRR, so ×0.6 may double-count.
- **Conclusion:** the haircut is **untestable with available data.** I show results raw and at ×0.6, and use the midpoint as the central estimate (§9).

### 3.2 Comparables (verified monthly revenue, TrustMRR) [V¹]

**Winners.** Rows marked ★ are solo founders with < 1,000 followers and no studio.

| App (followers) | What | Price | Monthly revenue | Pattern |
|---|---|---|---|---|
| **MacMD Viewer** ★ (991, FR) | Native Markdown viewer + Quick Look | $19.99 once | Mar $61 · Apr $580 · **May $1,283** · Jun $2,379 · **Jul $3,023** · Aug $2,199 · Sep $1,903 · Oct $1,543 (26 d). All-time $12,981. **Google: 657,853 impressions in 30 d** (GSC connected) | SEO-heavy (inferred from impressions [E]), **slow decay (−39%)**. Also on Setapp and Homebrew |
| **Headroom** ★ (719, NL) | Token compressor for Claude Code/Codex | Subscription | Apr $336 · Jun $2,540 · Oct $2,753; 91,108 impressions/30 d | SEO + Reddit, growing |
| **ActionClip** ★ (518, IN) | Text-selection action menu | $9 once | Jul $439 · Aug $764 · Sep $2,382 · Oct $2,411 | Reddit "top post of the day" (founder claim) |
| NotchLive ★ (716) | Live captions | $24.99 once | Mar $182 → Aug $1,924 → Oct $1,466 | Excluded on halal rule B (§5) |
| CC Assist (177) | VS Code extension: Claude Code/Codex history + diffs | $4.99/mo or $49.99 | Dec $423 · Mar $857 · Jun $875 · Sep $640 · Oct $361. "1,000+ developers" | Steady, then declining |
| Cooldock (367, studio) | Second dock with widgets | €29.99 lifetime | Jun $2,653 · **Jul $8,854** · Sep $4,935 · Oct $8,511 | Studio launch to an existing list |
| ExtraDock (367, studio) | Extra docks | $37.20 lifetime | $1.9k–6.5k/month for 12 months; all-time $40,508 | Studio, selling since ≤ Jan 2025 |
| ExtraBar (367, studio) | Custom menu bar | €24.99 | Dec $1,204 · **Jan $4,340** · Oct $540 | Product Hunt #5 on 29 Dec 2025 (149 pts) [V³⁵], then −85% |
| bytemail (5,281) | Mac email client | $19 once | Sep $238 · **Oct $15,283** | Audience-driven launch |
| CursorClip (2,210) | Auto-zoom screen recorder | $59 lifetime | $1.6k peak at month 7 → $635 | Slow ramp, −53% |

**Verified losers and spike-collapses** (peak → Oct 2026, Oct scaled ×31/26):

| App | Peak | Now | Note |
|---|---|---|---|
| SlapMac (4,222) | $27,829 | ~$762 | −97%, viral novelty |
| SuperShrimp (417,687) | $5,512 | ~$61 | −99%, Marc Lou's audience did not hold it |
| ShotsGlow | $2,742 | ~$76 | −97% |
| TypeBoost | $2,551 | $25 | −99% |
| MDViewer (2–5 people, SwiftUI Markdown viewer, $4.99) | $180 | $180 | **Direct loser in app 1's category**; all-time $534 |
| Shiori (studio) | $655 | $114 | Studio flop |
| CleanClip Pro | $762 | $163 | Clipboard manager |

**Never reached $1k (peak month):**
- **Desktop and files:** DeskDash $797, Jollycat $250, TeraConvert $58, FinderBuddy $126, Diskzy $82, Strata $17.
- **Menu bar, dock and notch:** ClearBar $177, DockLockr $51, Localdock $262, Halo $762, NotchOwl $234, NotchStack $11, NotchLedge $0.
- **Editors and terminals:** Scribbble $535 (4,120 followers), Edist $705, Termique $40.
- **Clipboard:** Maclip $45.

**Decay pattern** [V¹]:

| Driver | Apps | Peak-to-now change |
|---|---|---|
| Social/viral spikes | SlapMac, SuperShrimp, ShotsGlow, TypeBoost | −88% to −99% |
| SEO and Reddit | MacMD, NotchLive, CursorClip, SpeakMac | −9% to −54% |
| SEO and Reddit, still growing or flat | Headroom, ActionClip | growing / flat |

That difference decides the distribution plan (§8).

### 3.3 Sub-category screen (choosing the apps)

| Sub-category | Cohort n | Ever $1k | Solo/no-audience hits | Median last-30 d (≥ 3 mo) | Free incumbents (GitHub ★) [V²⁹] | Already absorbed by macOS | Decision |
|---|---|---|---|---|---|---|---|
| Notch | 18 | 2 | 1 (NotchLive, rule B) | $26 | boring.notch 11.2k | — | **Saturated** |
| Menu bar | 8 | 1 (studio) | 0 | $111 | Ice 29.9k, Hidden Bar 15.3k | **macOS 27** adds a "show more" overflow button for icons hidden by the notch [S²²]. 27 beta 1 broke Bartender/Ice/Hidden Bar [S²³⁻²⁴] | **Reject:** Sherlock risk plus an OS treadmill |
| Window management | 0 listed | — | — | — | Rectangle 30.2k, AeroSpace 23.6k, Loop 11.9k; Raycast free tier [V³⁰] | Native tiling with Fn-Control shortcuts (macOS 27 guide) [V¹⁹] | **Reject** |
| Clipboard / text | 4 | 1 (ActionClip) | 1 | $123 | Maccy 22.1k; Easydict 15.1k (selection translation); Raycast free clipboard | **macOS 26** Spotlight clipboard history [S²⁶] | Clipboard: reject. Selection actions: **backlog #1** |
| Finder / files / disk | 13 | 1 (cloud subscription) | 0 utilities | $34 | many | **macOS 26** folder colours/emoji [S²⁷] | **Reject** |
| Screenshot / recording | 13 | 4 | 0 durable (ShotsGlow −97%) | $167 | Shottr; CleanShot X. 10 "cleanshot x alternative" variants, incl. "free" and "github" [V³¹] | Built-in Screenshot | **Backlog #3** only |
| Dock | 9 | 3 (**all one studio**) | **0/6 outside the studio** | $820 (studio-inflated) | DockDoor 6.4k | none | Demand is real but captured by one studio: **backlog #2** |
| **Developer / AI-coding** | 5 (incl. MDViewer) | **2** | **2** (MacMD, Headroom), both SEO-driven | **$507** | CodexBar 22.8k (usage meters: avoid); QLMarkdown 3.7k | TextEdit in **macOS 27** still has no Markdown [V²¹]. macOS 15 **removed** legacy `.qlgenerator` plugins, breaking old free viewers [S²⁸] | **Pick both apps here** |

**Demand proxies for the picks** (Google autocomplete, 27 Oct 2026 [V³¹]; Google Trends returned HTTP 429, so it was not checked):
- "markdown viewer mac" returns 10 variants: "free", "app", "open source", "brew"…
- "md file mac" returns 10.
- "quick look markdown" returns 5.
- "markdown rtl" returns 10: "viewer", "support", "**to pdf**".
- "arabic markdown to pdf" appears.
- "obsidian rtl plugin" appears.
- "json viewer mac", "csv viewer mac" and "parquet viewer mac" return 10 each.
- "claude code transcript viewer" returns 1.
- sindresorhus/quick-look-plugins has **18.8k stars** [V²⁹].
- qlstephen (2.8k stars, last push 2023) is a legacy generator that **no longer works on macOS 15+** [V²⁹, S²⁸].

**Why not the higher-revenue categories?**
- The studio's dock apps sell well, but **0 of 6** outsiders reached $1k.
- Notch and menu-bar apps are crowded or being absorbed by macOS.
- Dev/AI is the only sub-category where:
  - 2 of 5 entrants hit $1k without an audience;
  - both hits were SEO-led, which a faceless founder can copy;
  - nothing needs Accessibility permission;
  - the apps can also ship on the Mac App Store.

---

## 4. Competitors and the specific gap

### App 1: Markdown + Mermaid reader

| Competitor | Weakness | Evidence |
|---|---|---|
| **MacMD Viewer** ($19.99) | No free tier. **PDF export is one continuous page** ("use Print for paper-sized pages"). No RTL mention. View-only, macOS 14+ | Its own site [V³⁹] |
| MDViewer ($4.99) | Low price and weak SEO; $180/month | [V¹] |
| QLMarkdown (free, open source) | Quick Look only; no window, export or folder view | [V²⁹] |
| MarkEdit, Obsidian, Typora | Editors, not readers. RTL in Obsidian needs a plugin ("obsidian rtl plugin") | [S, V³¹] |
| VS Code / Cursor preview | Tied to an IDE, which is exactly the pain MacMD sells against | MacMD copy [V³⁹] |

**The gap** (each part is a test, not a fact):
1. **Correct bidi/RTL rendering** plus **paginated, RTL-correct PDF export.**
   - Proxies: "markdown rtl to pdf" and "arabic markdown to pdf" [V³¹]. MacMD's PDF is continuous [V³⁹].
   - The founder's Arabic/French is a real edge here.
   - Volume is unknown [A]. Test: Google Search Console (GSC) impressions on the RTL landing page by day 60 (≥ 1,000/month).
2. **A free Quick Look tier,** which captures the "markdown viewer mac **free**" queries [V³¹], with the paid window app as the upgrade.
3. **Design quality** (typography and themes) is the founder's designer edge [A]. Test: conversion from visit to sale ≥ 1%.

**Honest limit:** the core demand ("markdown viewer mac") is already served by MacMD and free apps. App 1 wins only if SEO gets it onto page 1 for at least the RTL/PDF long tail.

### App 2: agent and data-file reader

| Competitor | Weakness | Evidence |
|---|---|---|
| CC Assist ($4.99/mo or $49.99) | VS Code extension only; history is limited on the free tier | [V⁴⁰] |
| Glance (free Quick Look, 836★), SourceCodeSyntaxHighlight (free, 4.3k★) | Code-oriented; no session/transcript view | [V²⁹] |
| OK JSON (free), Power JSON Editor ($4.99), Easy CSV Editor ($9.99), ParquetPeek ($4.99) | One format each | iTunes Search [V⁵¹] |
| qlstephen and other legacy plugins | **Broken on macOS 15+** | [S²⁸] |

**The gap:**
- One native, read-only app plus Quick Look for the formats agents emit (`.jsonl`, `.json`, `.yaml`, `.toml`, `.csv`, `.env` with secrets masked, extension-less text).
- A **session mode** that reads `~/.claude/projects/` and `~/.codex/sessions/` (the folders CC Assist reads [V⁴⁰]) outside the IDE.
- Export to Markdown, which opens in app 1. That is the cross-sell.

**Evidence quality:** moderate. The revenue proof is CC Assist's $400–875/month over 10 months [V¹], not a native app.

---

## 5. Halal compliance (rule by rule)

| Rule | Assessment |
|---|---|
| 1 Imagery | Product UI shows text, code and diagrams only. Icon: a plain geometric tile; **no** Delft-style figures, mascots or animals. Sample documents in screenshots use neutral technical prose. Arabic sample text is **not** Qur'an or hadith (rule 8, and out of respect). |
| 2 Music | Demo videos are silent screen recordings with on-screen captions. Optional male voice-over. No jingles. The apps ship no audio. |
| 3 Riba | One-time prepaid licence; nothing owed later; no late fees. **Disable any BNPL method** (Klarna/Afterpay) if the MoR's checkout offers one [A: check the Polar checkout settings in W4]. |
| 4 Chance / other religions | No giveaways by draw, no "spin to win". No Christmas or holiday theming, even though launch is in December. |
| 5 Deception | The launch price is a **dated introductory price, never a fake "was" price.** Dutch law (art. 5a Besluit prijsaanduiding) only allows a "from" price that is the lowest price in the prior 30 days, or since launch for new products [S⁴⁵]. No fake counters or fake scarcity. **14-day no-questions refund** via the MoR. Licence limits stated before purchase. |
| 6 Ads | None, in or around the apps. |
| 7 POD | Not applicable. |
| 8 Not Islamic-themed | Developer tools. RTL support serves languages, not religion. |
| 9 Content | No user-generated or bundled content. |
| A Migration | Unrelated. Do **not** market to inburgering or immigration use cases. |
| B Harm | **Read-only by design:** the apps never write to user files, so the worst failure is "the file doesn't render". `.env` values are masked by default. No network calls except licence checks and updates. **Excluded categories:** power and thermal tools (Clamshell, TurtleBar), captions and accessibility-critical tools (NotchLive), posture and health (SuperShrimp), camera gaze tracking (Glance Switch, rule C). |
| C Doubt | Also excluded: "now playing" and music widgets (e.g. Cooldock's music widget), desktop pets and animals (Nagomi's koi pond), novelty sound apps (SlapMac), AI interview "copilots" (deception), wallpaper content apps. |

**Questions for a scholar:**
1. Selling general-purpose software that buyers may use for any purpose: is the usual "the tool is mubah; the user bears responsibility" ruling sufficient?
2. Is a perpetual software licence sold through an MoR acting as reseller a valid sale of a usage right (bay' al-manfa'a), and is a 14-day voluntary refund fine?
3. Stripe/Polar payout balances earn no interest; please confirm nothing else in the payout chain is riba-bearing.

---

## 6. Product spec (MVP)

### 6.1 App 1: Markdown + Mermaid reader (build W1–W6, launch W7)

**Free tier (also the Homebrew-eligible "free version with paid features" [V⁴²]):**
- Quick Look preview of `.md`.
- Single-file window.
- Syntax highlighting, Mermaid, RTL rendering.

**Paid tier ($19 once, 2 Macs):**
- **Folder mode:** sidebar of every `.md` in a repo (`CLAUDE.md`, `AGENTS.md`, `docs/`), cross-document search and live reload.
- **Paginated PDF export** (A4/Letter), RTL-correct.
- 3 typographic themes, light/dark.
- UI in English, Dutch, French and Arabic.

**Cut from v1:**
- editing;
- math;
- sync;
- iOS;
- plugins;
- any AI feature;
- Windows.

**Later versions:**
- **v1.1:** KaTeX math, footnotes, custom CSS, print headers.
- **v2:** Mac App Store build (§7.4), Setapp application, Shortcuts actions.

### 6.2 App 2: agent and data-file reader (build W10–W14, launch W15)

**Free tier:**
- Quick Look for JSON, JSONL, YAML, TOML, CSV/TSV and extension-less text (the qlstephen replacement).

**Paid tier ($15 once; bundle with app 1 for $29):**
- Windowed viewer with collapsible JSON/JSONL and lazy-loaded large CSV.
- `.env` viewer with masking.
- **Session mode** for Claude Code/Codex folders: readable transcript, search, export to Markdown.

**Cut from v1:**
- editing;
- Parquet (v1.1);
- SQL;
- any cloud feature.

### 6.3 Shared design rules

- One rendering engine for both apps.
- No telemetry and no accounts.
- macOS 14+.

### 6.4 Customer contact: designed to stay small

**Self-service:**
- The Polar customer portal lets buyers view, rotate and deactivate their own licence keys [V⁶], so device transfers need no email.
- The MoR sends receipts and keys automatically.
- Refunds are one click in the dashboard, with a templated reply.

**Docs:**
- FAQ: activation, Gatekeeper, Quick Look enabling, refunds.
- A "known macOS issues" page.
- In-app "Copy diagnostics" button.
- Support by email only, answered once a day.

**Load [E]:**
- Inputs per 100 sales [A]:
  - 3 refund requests × 1 min;
  - 5 licence issues × 3 min;
  - 8 bug or feature mails × 5 min;
  - total about 58 min.
- **At €1k/month** (about 71 sales): about 41 min/month, roughly **2 min/day**.
- **At €10k/month:** about 14 min/day.
- **Spikes:** budget **20 min/day** in launch weeks and in each September/October macOS release window.
- **Test:** log minutes for 30 days after launch. Fix the docs if the average is > 20 min/day.

---

## 7. Technical architecture

### 7.1 Stack
- **Language and UI:** Swift 6, SwiftUI, with AppKit where needed.
- **Rendering:** `WKWebView` with a bundled renderer (Markdown parser + mermaid.js + highlight.js). The same renderer runs in the app and in a Quick Look Preview Extension (`QLPreviewingController`).
  - [A] A WKWebView-based Quick Look extension is stable on macOS 14/15/26/27. **Test at gate G0 in W1.**
- **RTL:** per-block `dir="auto"` and `unicode-bidi: plaintext`; code blocks forced left-to-right.
- **PDF:** `WKWebView.createPDF` or `NSPrintOperation` with CSS `@page`.
- **Folder mode:** user-selected folders through security-scoped bookmarks, plus file-system events for live reload.
- **Third-party licences:** Sparkle, the parser, mermaid.js and highlight.js are all permissive open source; include their notices.

### 7.2 Permissions
- **Apps 1 and 2 need no Accessibility, Screen Recording or Input Monitoring permission.**
- That is deliberate:
  - Apple's DTS says the Accessibility APIs are not supported in sandboxed apps [S¹⁷].
  - Permission prompts add friction [A].
- Keeping to sandbox-safe APIs leaves the Mac App Store open.
- Backlog apps #1 and #2 *do* need Accessibility, so they would be Developer ID only.

### 7.3 Distribution build
- **Requirements:**
  - Developer ID Application certificate, which only the **Account Holder** can create [V¹⁴];
  - Hardened Runtime;
  - secure timestamp.
- **Notarisation:** `xcrun notarytool submit --wait`, then `xcrun stapler staple`, for the app and the DMG.
  - Required for all Developer ID software since macOS 10.15.
  - altool is retired (since 1 Nov 2023) [V¹⁵].
- **Updates:** Sparkle **2.10.1** (released 25 Oct 2026 [V¹⁸]), with EdDSA keys (`generate_keys`) and an HTTPS appcast. Sparkle supports both sandboxed and Developer ID apps [V¹⁸].
- **Hosting:**
  - Site on Cloudflare Pages (free: 500 builds/month, 25 MiB per file) [V⁴⁸].
  - DMG and appcast on Cloudflare R2 (free: 10 GB-month, free egress) [V⁴⁸].

### 7.4 Licensing and the MoR choice

| | **Polar (chosen)** | Lemon Squeezy (fallback) | Paddle |
|---|---|---|---|
| Fee | 5% + 50¢, **+1.5% non-US cards**. Pro plan: $20/mo at 3.8% + 40¢ [V⁵] | 5% + 50¢, +1.5% non-US, +1.5% PayPal. **1% per payout to a non-US bank** [V⁹] | 5% + 50¢; bespoke pricing under $10 [V¹⁰] |
| MoR, VAT | Yes ("international tax compliance") [V⁵] | Yes; files and pays tax [V⁸] | Yes; collects and remits [V¹⁰] |
| Licence keys | **Native.** Activation limits; customer self-service. The public `validate` endpoint "doesn't require authentication and can be safely used on a public client" [V⁶⁻⁷] | Native, auto-issued [V⁸] | **None in Paddle Billing**; you build it yourself [S¹¹] |
| Other | Payout: $2/mo + 0.25% + $0.25; FX 0.25% (EU); $15 per dispute [V⁵] | Future unclear while Stripe migrates merchants to Managed Payments; admitted slower support [S¹²] | — |

- **Why Polar:** native public-client licence API, no PayPal surcharge, cheapest payouts to an NL bank.
- **When to upgrade:** switch to Polar Pro above about **61 sales/month at $19** [E: saving per sale = 0.012 × 19 + $0.10 = $0.33; $20 ÷ $0.33 ≈ 61].
- **Licence checks:** validate on launch with a 30-day offline grace period. No DRM beyond that, since honesty cuts both ways.

### 7.5 Mac App Store as a secondary channel (from month 5, app 1 only)
- **What the MAS requires** (guideline 2.4.5, updated 16 Oct 2026 [V¹⁶]):
  - sandboxing;
  - **no licence keys or licence screens**;
  - **no third-party updaters**.
  - Guideline 2.5.1 also allows only public APIs.
  - So the MAS build is a separate target without Sparkle or Polar, priced upfront.
- **Net per sale:**
  - EU €19 → 19 ÷ 1.21 × 0.85 = **€13.35**;
  - US $19 → $16.15 = €14.43 [E].
  - That is about the same as direct sales, so the MAS adds discovery at no real per-sale penalty.
- **Why dock, menu-bar and window apps sell direct instead:** they need Accessibility and often private APIs, which the sandbox forbids [S¹⁷, V¹⁶].

### 7.6 Platform order and costs
- **Platform order:** macOS only. The buyer is a Mac developer. NL Android share is irrelevant here, and Windows is deferred.
- **Running costs:**
  - Apple membership €99/yr (if a new one is needed);
  - domain about €10/yr;
  - per-sale MoR fees;
  - everything else on free tiers until MailerLite passes 250 subscribers [V⁴⁷].

---

## 8. Distribution (no ads, no faces, no music)

| Channel | Evidence it works for comparables | Plan |
|---|---|---|
| **SEO** (primary) | MacMD **657,853** impressions/30 d; Headroom 91,108 [V¹]. SEO-led apps decay −9% to −54%, against −97% for viral spikes [V¹] | Landing pages from W2: "markdown viewer mac", "rtl markdown to pdf", "arabic markdown pdf mac", "quick look markdown macos 15", "jsonl viewer mac", "view claude code transcripts". Fair comparison pages. Two articles/week from W8 |
| **r/macapps** | ActionClip: "top post of the day" (founder claim) [V¹]. Sidebar rules: **one promotion per developer per 30 days**; PCP template; "Lifetime > Subscription > Free" flair; main feed only for trust/transparency qualifiers, otherwise a monthly megathread [S³⁴]. The front page is a firehose (most new-app posts 0–50 upvotes; ExtraBar's repost got 2) [S³⁴] | One post per app at launch, in the megathread unless eligible. The "transparency path" needs a real identity and LinkedIn [S], which is a user decision |
| **Product Hunt** | ExtraBar #5 on 29 Dec 2025 (149 pts) → Dec $1,204, Jan $4,340 [V¹,³⁵]. Halo #31 (70 upvotes) → small sales [S³⁶] | Launch app 1 on Tue 8 Dec and app 2 on Tue 2 Feb |
| **Hacker News (Show HN), Indie Hackers** | Otabek: HN brought 2 of 3 sales on its day [S³⁶] | One post per launch |
| **Homebrew Cask** | MacMD lists Homebrew [V³⁹]. A free tier with paid features is eligible; new apps get a notability review [V⁴²] | Submit once app 1 has independent mentions (month 3+) |
| **Newsletter / cross-sell** | AppIt's bundle: $17,560 all-time, peak $2,234 [V¹] | Opt-out checkbox at checkout; email app 1 buyers about app 2 under the soft opt-in for "own similar products" (Tw art. 11.7; ACM reads it narrowly) [S⁴⁶]. MailerLite free up to 250 subscribers [V⁴⁷] |
| **Setapp** (month 6+) | Mac Setapp is active; only *Setapp Mobile* closed (16 Feb 2026) [S³³]. **70% of each user's fee split by usage and price tier, +20% partner fee on users you refer** [V³³]. Requires "mature software with an excellent reputation" [V³³]. MacMD is listed [V³⁹] | Apply when app 1 has 3+ months of releases and public reviews |
| **Press** | ExtraBar's "Wired Business" appears **only in founder text**; I could not find the article [S]. Unverified | Async email pitches to MacStories and 9to5Mac at launch. Expect nothing |
| **Silent demos** | UI screenshots are faceless by nature | Built-in screen recording; captions as text; no audio track |

**Launch-price wording (honest and legal):**
> "Introductory price $14 until Mon 14 Dec 2026 23:59 CET. From 15 Dec: $19."

- There is no "was" price, because none was ever charged [S⁴⁵].
- The price really rises on that date.

---

## 9. Pricing and unit economics

**Price:** $19 one-time for app 1 (2 Macs); $15 for app 2; $29 for the bundle. MacMD charges $19.99; at $4.99, MDViewer fails [V¹].

**Net per $19 sale on Polar Starter** [E, scratchpad `mus/tools/est.py`]:

| Buyer region (share [A]) | Tax | Fee | Net |
|---|---|---|---|
| US (45%) | 0 | $1.45 | $17.55 = €15.69 |
| EU (30%) | 21% VAT included | $1.74 (incl. +1.5% intl) | $13.97 = €12.48 |
| Other (25%) | ~12% included | $1.74 | $15.23 = €13.61 |
| **Blended**, after about 0.5% payout/FX | | | **€14.14 per sale = €0.744 per $1 gross** |

- €1k net needs **$1,344 gross**, which matches the brief's $1,350–1,500.
- Test for the region mix: the Polar country split after 30 days.

**Sales needed per month:**

| Target net/month | At $19 | At $15 | At $9 (ActionClip's price) |
|---|---|---|---|
| €1,000 | **71** | ~90 | 155 |
| €10,000 | **707** | ~904 | 1,547 |
| €100,000 | **7,074** (≈ 236/day) | ~9,036 | 15,475 |

**The honest ceiling:**
- **Best single app:** Cooldock's $8,964/30 days at a €29.99–99.99 ticket, roughly 200–300 sales [E]. That is a 2–5-person studio launching to its own list.
- **That studio's whole portfolio** (5 apps + bundle): about $13.6k in 1–26 Oct; $14.8k last 30 days [V¹]. Possible overlap between the bundle and app listings is not verifiable.
- **bytemail:** $15,283 in month 1, about 800 sales [E], backed by 5,281 followers.
- **What €100k/month would take:**
  - about **9× bytemail's launch month, every month**;
  - about **10× the studio's entire portfolio**;
  - about **5× SlapMac's one viral month**.
- **None of the 85 desktop apps came within 3× of it.**
- **TrustMRR-wide:** only 5.0% of all listings have *all-time* revenue ≥ $100k [V³]. The site shows no monthly-$100k distribution.
- **Treat €100k/month as not achievable on current evidence.**
- **One-time licences don't compound:** month-12 revenue is new buyers only. The only recurring levers are new apps, the bundle, Setapp and paid major upgrades (v2).

**Estimate arithmetic** [E]:
- **Reference class:** solo founders with < 2,000 followers, not the studio, apps ≥ 3 months old, n = 31. Last-30-day revenue: median $58, p75 $383. (Team size is blank on 20 of these profiles, so "solo" here means non-studio.)
- **Method:** exact enumeration of all 2- and 3-app sums; net factor 0.744.
- **Month 6, two apps:**
  - raw median $251 → **€187**; ×0.6 → **€112**; central = midpoint ≈ **€150**;
  - p25 ×0.6 = €29; p75 raw = €759 (fragile: it was €1,028 before MDViewer was added, because the 2-app sum distribution has a gap near p75);
  - **P(≥ €1k): 24% raw, 14% at ×0.6** → central about 19% (midpoint).
- **Month 12, three apps:** raw €435, ×0.6 €261 → central about **€350**; p25 €93, p75 €1,451; P(≥ €1k) 22–35%.
- **Month 3, one app in its 2nd sales month:** median $88 → €65 raw, €39 ×0.6 → about **€50**; p75 $661 → €490.
- **Upside not modelled:** the dev/AI sub-category's 2-of-5 hit rate. n = 5 is too small to lean on.

---

## 10. Budget within €200 (every line sourced)

| Item | Case A: existing Apple membership usable | Case B: new membership needed | Source |
|---|---|---|---|
| Apple Developer Program | €0 | **€99** | $99 "or local currency" [V¹³]; €99 in NL [S⁵³] |
| KvK eenmanszaak registration (in launch week, W6) | €85.15 | €85.15 | [V⁴³]; register from 1 week before to 1 week after start [S⁴³] |
| Domain, 1st year | tegelapps.com $11.08 ≈ **€9.90** | `.app` first year $8.75 ≈ **€7.82** | Porkbun API [V⁴⁹] |
| Site, DMG and appcast hosting | €0 | €0 | Cloudflare Pages/R2 free tiers [V⁴⁸] |
| MoR | €0 fixed (per-sale fees only) | €0 | Polar Starter [V⁵] |
| Newsletter | €0 | €0 | MailerLite Free, ≤ 250 subscribers [V⁴⁷] |
| Sparkle, renderer libraries | €0 | €0 | Open source [V¹⁸] |
| Test VMs for macOS 14/15/26/27 | €0 | €0 | [A] The founder's Apple Silicon Mac can run macOS VMs. Test: W1 |
| Dispute reserve (2 × $15) | €27 | €0 (pay from revenue) | Polar [V⁵] |
| **Total** | **€122** (buffer €78) | **€192** (buffer €8) | |

- **Not bought:** paid ads, paid directories (Otabek: those didn't work [S³⁶]), stock imagery, a Setapp fee (Setapp charges none; it takes a revenue share).

---

## 11. Timeline

Weeks run Tuesday to Monday. Week 1 = 27 Oct–2 Nov 2026.

| Week | Dates | Work |
|---|---|---|
| **W1** | 27 Oct–2 Nov | Answer the Apple-account question (§16 Q). Prototype the renderer (Markdown + Mermaid + an RTL test file) in the app **and** a Quick Look extension → **gate G0**. Check Google Trends manually in a browser. Trademark searches (§15); register the domain. Set up the Polar sandbox |
| W2 | 3–9 Nov | Folder mode, live reload, search. Static site skeleton plus the first 2 SEO pages |
| W3 | 10–16 Nov | Paginated, RTL-correct PDF export; 3 themes; EN/NL/FR/AR strings |
| W4 | 17–23 Nov | Polar licensing (activate/validate, Keychain, grace period). Sparkle + EdDSA + appcast on R2. Script the notarisation pipeline. DMG. Check the BNPL setting |
| W5 | 24–30 Nov | Test on macOS 14/15/26/27 VMs. FAQ/docs, privacy page, refund policy. Silent demo video. 2 more SEO pages |
| W6 | 1–7 Dec | **KvK registration.** Polar live. Final notarised build. Prepare the PH, r/macapps and HN posts |
| **W7** | **Tue 8 Dec** | **Launch app 1:** PH, r/macapps, Show HN, IH. Introductory $14 until 14 Dec |
| W8–W9 | 15–28 Dec | Fixes; v1.0.1. Two SEO articles a week. Log support minutes |
| W10–W13 | 29 Dec–25 Jan | Build app 2 on the shared renderer. **G1 on 7 Jan** |
| W14 | 26 Jan–1 Feb | Notarise app 2; docs and demo |
| **W15** | **Tue 2 Feb 2027** | **Launch app 2:** email app 1 buyers; PH; r/macapps (30-day rule respected); HN |
| Month 5 | Mar 2027 | **G2 on 8 Mar.** App 1 v1.1 (math). Mac App Store build of app 1 submitted |
| Month 6 | Apr 2027 | **G3 on 30 Apr.** Setapp application if eligible. Bundle at $29 |
| Months 7–9 | May–Jul 2027 | If G3 passes: app 3 from the backlog. Re-test everything on the macOS 28 betas in June |
| Months 10–12 | Aug–Oct 2027 | SEO cadence; Homebrew submission; app 4 only if net ≥ €700/month. **G4 on 29 Oct** |

---

## 12. Kill / continue criteria

| Gate | Date | Continue if | Kill / change if |
|---|---|---|---|
| **G0** | 2 Nov 2026 | A 1 MB `.md` file with Mermaid and RTL renders in < 1 s, in both the app window and Quick Look, on macOS 15 and 27 | Quick Look rendering is unreliable → drop Quick Look from both apps and re-scope app 1 to a window-only reader (or pick backlog #1) |
| **G1** | 7 Jan 2027 (day 30 after app 1) | **≥ 30 paid sales**, i.e. just below the solo cohort's top quartile (p75 2nd-month revenue $661 ÷ $14–19 ≈ 35–47 sales [V¹, E]) | **< 10 sales** → stop the app 1 SEO work; ship app 2 only because it shares about 60% of the code [A]. If app 2 also makes < 10 sales by **4 Mar 2027**, **stop the studio** |
| **G2** | 8 Mar 2027 (day 90) | App 1: ≥ 25 sales in the last 30 days **and** GSC ≥ 10,000 impressions/30 d | < 10 sales **and** < 2,000 impressions → the SEO thesis failed; freeze at maintenance only (≤ 2 h/week) |
| **G3** | 30 Apr 2027 (month 6) | Combined net ≥ **€300/month** → build app 3 | €100–300 → no new app, ≤ 10 h/week. **< €100 → stop development**; keep the apps on sale |
| **G4** | 29 Oct 2027 (month 12) | ≥ **€1,000/month** net → bundle, Setapp, app 4 | Otherwise wind down to maintenance |
| Support | Rolling | ≤ 20 min/day averaged over 14 days | > 30 min/day → fix the docs or raise the price before any new feature |

---

## 13. Risks and mitigations

| # | Risk | Evidence | Mitigation |
|---|---|---|---|
| 1 | **No audience, no customer list.** The real base rate is a $58 median | §3.1 [V¹] | SEO-led categories only; hard gates; ≤ €200 at risk |
| 2 | **An incumbent plus free options** (MacMD, QLMarkdown, MarkEdit, Obsidian) | §4 | Differentiate on RTL, paginated PDF and the free Quick Look tier; G1/G2 |
| 3 | **Launch spikes collapse**; one-time licences don't compound | −97% to −99% for viral apps [V¹] | Don't rely on PH or Reddit; SEO compounds; portfolio, bundle, paid v2 |
| 4 | **Sherlocking:** Apple renders Markdown in Quick Look/TextEdit; Anthropic/OpenAI ship session browsers | Not in macOS 27 [V²¹]. Vendor risk is high for app 2's transcript mode [A] | Keep transcripts a *mode*, not the core. Watch WWDC each June |
| 5 | **macOS update breakage** | 27 beta 1 broke menu-bar managers [S²⁴] | Public APIs only; no Accessibility; beta-test each June |
| 6 | **Undocumented transcript formats change** | Claude Code/Codex formats are not a public API [A] | Tolerant parser; fall back to the generic JSONL view |
| 7 | **MoR risk** (account review or hold; Lemon Squeezy's future) | [S¹²] | Polar primary, Lemon Squeezy as a tested fallback; keep the licence code MoR-agnostic |
| 8 | **Reddit or PH rules and variance** | One post per 30 days; megathread [S³⁴] | One post per app; don't depend on it |
| 9 | **AI Overviews cut search clicks** | [A] | Track GSC clicks, not just impressions; target long-tail "how do I…" queries |
| 10 | **Comparable data quality** | Stale syncs (ScreenSnap); wrong founded dates (ExtraDock) [V¹] | Gates use the founder's own numbers, not comparables |
| 11 | **Time assumption** (30 h/week) | [A] | Scope is fixed; slip launch dates, not quality |

---

## 14. Scale path (each step tied to evidence)

1. **App 1 + SEO** (MacMD pattern: $580 → $3,023 in 4 months [V¹]).
2. **App 2 cross-sold** to app 1 buyers (studio pattern: Cooldock's launch month was $2,653 [V¹]).
3. **Bundle** (AppIt bundle: $17,560 all-time [V¹]).
4. **Setapp** (70% usage-split pool + 20% partner fee on referred users [V³³]; MacMD is listed [V³⁹]).
5. **Mac App Store build** (about the same net per sale [E]; viewers are sandbox-safe [V¹⁶]).
6. **Apps 3–4 from the backlog:**
   - **#1 selection-action bar** (ActionClip $2.4k/month [V¹]; risks: Easydict 15.1k★ free, PopClip, Apple Writing Tools);
   - **#2 workspace presets** (DockFlow $17.4k all-time [V¹]; but 0 of 6 outsiders reached $1k in the dock category);
   - **#3 auto-zoom demo recorder** (CursorClip $0.6–1.6k/month [V¹]; crowded).
   - Backlog #1 and #2 need Accessibility, so they are Developer ID only.
7. **Paid major upgrade** (v2) for existing owners. That is the only honest "recurring" lever on a one-time licence.

**Realistic ceiling on evidence:** **$10–15k/month** for a mature 5-app studio with a list, after 2+ years (the AppIt studio [V¹]). Not €100k.

---

## 15. Legal / admin (NL)

**Business registration:**
- **KvK eenmanszaak:** €85.15 one-time [V⁴³], registered in W6, within the legal window of 1 week before to 1 week after starting [S⁴³].
- The Belastingdienst receives the registration automatically [S⁴³].

**VAT (BTW):**
- Polar (US) is the seller to consumers. The founder's supply to a non-EU business generally needs no NL VAT return entry if it is taxed abroad [V⁴⁴].
- MoR fees bought from a non-EU supplier are reverse-charged in **rubriek 4a**, usually netting to €0 [V⁴⁴].
- **Ask an adviser:**
  - whether the KOR applies;
  - how the Mac App Store (Apple's EU contracting entity) and Setapp (MacPaw; check the contracting entity) are treated;
  - income-tax deductibility of the Apple fee and the Mac.

**Platform terms:**
- Apple Developer Program Licence Agreement (Developer ID and notarisation);
- Polar terms and acceptable use;
- Mac App Store guidelines 2.4.5 and 2.5.1 [V¹⁶];
- Setapp SDK terms.
- Ship third-party notices: Sparkle, mermaid.js, highlight.js, parser.

**Consumer and marketing law:**
- **Price claims:** art. 5a Bpp (§8) [S⁴⁵].
- **Email:** soft opt-in, with an opt-out at collection [S⁴⁶].
- **Privacy:** none (no data collected) beyond the MoR's own privacy notice. Publish a one-page privacy statement.

**Studio name: three proposals, with collision checks** (RDAP and iTunes Search, 27 Oct 2026):

| Name | Domain status [V⁵⁰] | Collisions [V⁵¹, S] | Note |
|---|---|---|---|
| **Tegel** (Dutch "tile": each app a tile) | tegelapps.com **available**; tegelwerk.app **available**; tegelwerk.com and .nl taken (Dutch word for tiling) | iTunes: no Mac app named Tegel; "Puts & Tegel" (a quiz show) and a tile-adhesive app are unrelated | **Recommended.** Plain geometric logo; avoid Delft figurative tiles (rule 1) |
| **Kadeworks** ("kade" = quay) | kadeworks.app and .nl **available**; .com registered on **20 Sep 2026** by an unknown party | iTunes: none | The recent `.com` registration is a mild collision risk |
| **Netjes** ("tidy") | netjesapps.com **available**; netjes.app registered **26 Jun 2026** | iTunes: none | Hard to pronounce outside NL; possible parallel project |

- **Trademark check still to do (W1):**
  - EUIPO eSearch / TMview (classes 9 and 42);
  - BOIP (Benelux);
  - USPTO.
- Not done here: those registers aren't scriptable.

---

## 16. Sources (all accessed 27 Oct 2026)

**TrustMRR**
1. TrustMRR public Markdown profiles, `https://trustmrr.com/startup/<slug>.md`, fresh pulls 27 Oct 2026.
   - Named: cooldock, extrabar, extradock, dockflow, shiori-bookmarks-manager, appitstudio-apps-bundle-and-services, lnkflow, headroom, omninotch, notchlive, screensnap-pro, helumi, bytemail, macmd-viewer, actionclip, mdviewer, claude-code-and-codex-assist-history-diff-viewer-chat-manager, supershrimp, typeboost, shotsglow, slapmac, cursorclip, speakmac, screen-movie, glance-switch, halo-mac, deskdash, scribbble, cleanclip-pro, edist, clamshell, jollycat, compresso, turtlebar, docklockr, localdock, clearbar-mac-app, termique-ssh-client, maclip, nagomi.
   - Plus the rest of the 85-app cohort (84 slugs listed in the scratchpad `mus/tools/cohort.py`).
2. TrustMRR founder page: https://trustmrr.com/founder/mazuzasaf
3. TrustMRR stats (updated 27 Oct 2026 04:16): https://trustmrr.com/stats
4. TrustMRR llms.txt: https://trustmrr.com/llms.txt

**Payments and merchants of record**
5. Polar pricing: https://polar.sh/resources/pricing
6. Polar licence keys: https://polar.sh/docs/features/benefits/license-keys
7. Polar validate endpoint: https://polar.sh/docs/api-reference/customer-portal/license-keys/validate
8. Lemon Squeezy pricing: https://www.lemonsqueezy.com/pricing
9. Lemon Squeezy fees: https://docs.lemonsqueezy.com/help/getting-started/fees
10. Paddle pricing: https://www.paddle.com/pricing
11. Paddle Billing vs Classic (licence generation deprecated; build it yourself) [S]: https://developer.paddle.com/migrate/learn/feature-comparison/ and https://developer.paddle.com/migrate/paddle-classic/workflows
12. Lemon Squeezy → Stripe Managed Payments (competitor blogs) [S]: https://dodopayments.com/blogs/lemonsqueezy-alternatives and https://fungies.io/lemon-squeezy-stripe-acquisition-saas-founders-2026/

**Apple developer documentation**
13. Apple Developer Program: https://developer.apple.com/programs/whats-included/
14. Apple Developer ID: https://developer.apple.com/developer-id/
15. Apple, Notarizing macOS software (doc JSON): https://developer.apple.com/tutorials/data/documentation/security/notarizing-macos-software-before-distribution.json
16. App Review Guidelines 2.4.5 and 2.5.1 (last updated 16 Oct 2026): https://developer.apple.com/app-store/review/guidelines/
17. Apple DTS forum on Accessibility in sandboxed apps [S]: https://developer.apple.com/forums/thread/836644 and https://developer.apple.com/forums/thread/756130
18. Sparkle docs: https://sparkle-project.org/documentation/. Latest release 2.10.1 (25 Oct 2026): https://api.github.com/repos/sparkle-project/Sparkle/releases/latest

**Apple support guides (macOS 27)**
19. Tile app windows: https://support.apple.com/guide/mac-help/tile-app-windows-mchl9674d0b0/mac
20. Customize the menu bar: https://support.apple.com/guide/mac-help/customize-the-menu-bar-mchlp1446/mac
21. TextEdit User Guide for macOS 27: https://support.apple.com/guide/textedit/txted6a660ee/mac

**macOS 26/27 changes (secondary)**
22. ifun.de, macOS 27 menu-bar "Mehr anzeigen" (1 Jul 2026) [S]: https://www.ifun.de/macos-27-apple-integriert-bartender-funktion-direkt-ins-system-282819/
23. Bartender Golden Gate release notes [S]: https://www.macbartender.com/goldengate/releases/
24. Badgeify, macOS 27 menu-bar changes [S]: https://badgeify.app/macos-27-golden-gate-menu-bar-changes/
25. MacStories, WWDC 2026 small details [S]: https://www.macstories.net/news/wwdc-2026-small-details-and-compatibility-lists/
26. Spotlight clipboard history, macOS 26 [S]: https://www.tomsguide.com/computing/software/how-to-enable-clipboard-history-in-macos-tahoe and https://macmost.com/how-to-use-the-spotlight-clipboard-history-in-macos-tahoe.html
27. Folder customisation, macOS 26 [S]: https://macmost.com/how-to-customize-folders-in-macos-tahoe.html
28. Sequoia removed `.qlgenerator` support [S]: https://eclecticlight.co/2024/10/31/how-sequoia-has-changed-quicklook-and-its-thumbnails/ and https://mjtsai.com/blog/2024/11/05/sequoia-no-longer-supports-quicklook-generator-plug-ins

**Free incumbents and demand proxies**
29. GitHub API (stars and last push): `https://api.github.com/repos/<owner>/<repo>` for jordanbaird/Ice, rxhanson/Rectangle, p0deje/Maccy, dwarvesf/hidden, MrKai77/Loop, ejbills/DockDoor, lwouis/alt-tab-macos, nikitabobko/AeroSpace, exelban/stats, TheBoredTeam/boring.notch, steipete/CodexBar, sbarex/QLMarkdown, sbarex/SourceCodeSyntaxHighlight, chamburr/glance, MacDownApp/macdown, whomwah/qlstephen, sindresorhus/quick-look-plugins, tisfeng/Easydict.
30. Raycast pricing: https://www.raycast.com/pricing
31. Google autocomplete: `https://suggestqueries.google.com/complete/search?client=firefox&hl=en&q=<query>` (queries as quoted). Google Trends API returned HTTP 429.
32. *(unused)*

**Distribution channels**
33. Setapp: https://setapp.com/developers and https://docs.setapp.com/docs/setapp-membership-revenue. Wikipedia on Setapp Mobile [S]: https://en.wikipedia.org/wiki/Setapp
34. r/macapps sidebar via Redlib mirror [S]: https://redlib.scsimedia.duckdns.org/r/MacApps
35. Product Hunt, ExtraBar: https://www.producthunt.com/products/extrabar

**Founder reports and market data**
36. Otabek, "How I made my first $500 selling Mac apps in 23 days" [S]: https://dev.to/otabek_abdiraimov/how-i-made-my-first-500-selling-mac-apps-in-23-days-72a
37. Indie Hackers post title (page returned 403) [S]: https://www.indiehackers.com/post/first-paying-customer-for-my-mac-app-19-after-6-days-and-40-downloads-f36ad2d0d9
38. State of Mac Apps 2026 [S]: https://macapps.report/market

**Competitor sites**
39. MacMD Viewer: https://macmdviewer.com/. Wayback CDX, first capture 19 Mar 2026: http://web.archive.org/cdx/search/cdx?url=macmdviewer.com
40. CC Assist: https://ccassist.dev/
41. PopClip: https://www.popclip.app/
42. Homebrew Acceptable Casks: https://docs.brew.sh/Acceptable-Casks

**Dutch legal and admin**
43. KvK fee: https://www.kvk.nl/inschrijven/inschrijfvergoeding/. Registration timing [S]: https://www.kvk.nl/starten/op-welke-datum-moet-ik-mijn-bedrijf-inschrijven-bij-kvk/
44. Belastingdienst, VAT on non-EU services: https://www.belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/zakelijk/btw/zakendoen_met_het_buitenland/zakendoen_buiten_de_eu/aangifte_doen_als_u_zakendoet_buiten_de_eu/aangifte_doen_als_u_diensten_levert_aan_afnemers_in_niet_eu_landen and …/aangifte_doen_als_u_diensten_afneemt_van_leveranciers_uit_niet_eu_landen
45. ACM, price claims and art. 5a Bpp [S]: https://www.acm.nl/nl/verkoop-aan-consumenten/consumenten-informeren/prijzen-vermelden and https://www.acm.nl/system/files/documents/acm-leidraad-prijsweergave-en-vergelijkingen.pdf
46. ACM, soft opt-in (Companeo decision) [S]: https://www.acm.nl/sites/default/files/old_publication/publicaties/10416_Boetebesluit%20e-mailspam%20Companeo.pdf

**Infrastructure and tooling**
47. MailerLite pricing: https://www.mailerlite.com/pricing
48. Cloudflare R2 pricing: https://developers.cloudflare.com/r2/pricing/. Cloudflare Pages limits: https://developers.cloudflare.com/pages/platform/limits/
49. Porkbun pricing API: https://api.porkbun.com/api/json/v3/pricing/get
50. RDAP: `https://rdap.org/domain/<domain>` (calibrated against a nonsense domain, which returns 404)
51. iTunes Search API: `https://itunes.apple.com/search?term=<t>&entity=software|macSoftware&country=us|nl`
52. ECB EUR/USD: https://data-api.ecb.europa.eu/service/data/EXR/D.USD.EUR.SP00.A?lastNObservations=3&format=csvdata
53. iCulture, €99 NL price [S]: https://www.iculture.nl/nieuws/prijsverhoging-ios-mac-developer-program-99-euro/
54. RevenueCat SOSA 2026 (17.3% reach $1k/month within 2 years), quoted from the brief and not re-verified [S].

**Open questions for the user** (they change the budget and timeline):
1. Which entity holds the Apple Developer membership (personal, eenmanszaak or the Stichting)? Is it current, and may it sign commercial Mac apps? This decides Case A (€122) or Case B (€192).
2. Is there already a KvK eenmanszaak?
3. Is there an Apple Silicon Mac able to run macOS 14/15/26/27 test VMs?
4. Will you use the r/macapps "transparency path" (real identity + LinkedIn), or the megathread only?

---

## Verification log (independent check, 27 Oct 2026)

All sources re-opened on 27 Oct 2026 with curl (no browser). TrustMRR pages are `https://trustmrr.com/startup/<slug>.md`.

| # | Claim | Status | Source |
|---|---|---|---|
| 1 | EUR/USD 1.1188 (ECB, 26 Oct 2026) | **Confirmed** | https://data-api.ecb.europa.eu/service/data/EXR/D.USD.EUR.SP00.A?lastNObservations=3&format=csvdata |
| 2 | Cooldock: $8,964 last 30 d; Jun $2,653 · Jul $8,854 · Sep $4,935 · Oct $8,511; team 2–5; 367 followers; €29.99 1-Mac lifetime | **Confirmed** | trustmrr.com/startup/cooldock.md |
| 3 | Studio portfolio ≈ $13.6k in Oct, $14.8k last 30 d | **Confirmed**: six listings sum to $13,597 (Oct) and $14,822 (last 30 d) | cooldock, extradock, extrabar, dockflow, shiori-bookmarks-manager, appitstudio-apps-bundle-and-services `.md` |
| 4 | bytemail $15,283, 5,281 followers, $19 | **Confirmed** the figures; **corrected** the label "month 1" to "launch month" (founded 19 Sep; Sep $238, Oct $15,283) | trustmrr.com/startup/bytemail.md |
| 5 | MacMD Viewer: Mar $61 to Jul $3,023 to Oct $1,543; all-time $12,981; 657,853 GSC impressions/30 d; −39% (Oct scaled) | **Confirmed** | trustmrr.com/startup/macmd-viewer.md |
| 6 | SlapMac peak $27,829, now ≈ $762 (−97%); Headroom, ActionClip, ExtraBar and CC Assist monthly rows | **Confirmed** (SlapMac Oct $639 × 31/26 = $762) | slapmac, headroom, actionclip, extrabar, claude-code-and-codex-assist-history-diff-viewer-chat-manager `.md` |
| 7 | ExtraDock on sale by Jan 2025; $1.9k–6.5k/month; all-time $40,508 | **Confirmed**, but the source was **corrected**: TrustMRR only shows Nov 2025 onward (the 12 months sum to exactly $40,508). The Jan 2025 sale at $4.99 comes from Wayback | http://web.archive.org/web/20250111033031/https://extradock.app/ |
| 8 | TrustMRR-wide: 67.7% all-time < $1k; 5.0% ≥ $100k | **Confirmed** (4.0% + 1.0%; page updated 27 Oct 2026 04:16) | https://trustmrr.com/stats |
| 9 | Cohort base rates (n = 84; 23%, 28%, 15% (3/20), $111, $52; dev/AI 2 of 4, median $1,135) | **Corrected.** MDViewer (Mac app, founded 1 Feb 2026, 3 followers, peak $180) meets the inclusion rule and is named in §3.2 as a "direct loser", but it was missing from `cohort.py`. Re-running the writer's `cohort.py`/`est.py` with it added gives n = 85; 22%, 27% (8/30), 14% (3/21), $114 (n = 41), $58 (n = 31); dev/AI 2 of 5, median $507. "Solo" in the script means non-studio with < 2,000 followers; 20 of the 31 profiles leave team size blank | trustmrr.com/startup/mdviewer.md; scripts in scratchpad `vc1/` |
| 10 | Polar: 5% + 50¢, +1.5% non-US; Pro $20/mo at 3.8% + 40¢; payout $2/mo + 0.25% + $0.25; FX 0.25% EU; $15 per dispute | **Confirmed** (Polar's own Pro breakeven is ~$1,379/mo at its example basket; the plan's 61 sales at $19 is correct for $19 orders) | https://polar.sh/resources/pricing |
| 11 | Polar validate endpoint "doesn't require authentication and can be safely used on a public client" | **Confirmed** (verbatim) | https://polar.sh/docs/api-reference/customer-portal/license-keys/validate |
| 12 | Lemon Squeezy: +1.5% intl, +1.5% PayPal, 1% per payout to a non-US bank | **Confirmed** | https://docs.lemonsqueezy.com/help/getting-started/fees |
| 13 | Guideline 2.4.5: sandboxed; no licence screen or keys (vi); updates only via MAS (vii); last updated 16 Oct 2026 | **Confirmed** | https://developer.apple.com/app-store/review/guidelines/ |
| 14 | Sparkle 2.10.1 released 25 Oct 2026 | **Confirmed** (published 2026-10-25T14:36Z) | https://api.github.com/repos/sparkle-project/Sparkle/releases/latest |
| 15 | KvK €85.15; Apple $99 "or local currency"; Porkbun .com $11.08, .app $8.75 | **Confirmed** (.app renews at $14.93) | kvk.nl/inschrijven/inschrijfvergoeding/; developer.apple.com/programs/whats-included/; api.porkbun.com pricing |
| 16 | Setapp: 70% usage split + 20% partner fee | **Corrected**: the +20% partner fee applies only to users *you bring* to Setapp | https://docs.setapp.com/docs/setapp-membership-revenue |
| 17 | MacMD: $19.99, no free trial, PDF "flows as one continuous page", macOS 14+ | **Confirmed** | https://macmdviewer.com/ |
| 18 | Homebrew: "A free version that works indefinitely with optional paid features is eligible" | **Confirmed** | https://docs.brew.sh/Acceptable-Casks |

**Arithmetic re-run:**
- **Confirmed:** net per $19 sale €14.14 (€0.744 per $1); $1,344 gross for €1k; 71 / 707 / 7,074 sales; $9 column; MAS €13.35 / €14.43; Polar Pro crossover at 61 sales; budget €122 / €192; all launch and gate weekdays; the €100k multiples (8.8× bytemail, 9.9× studio, 4.8× SlapMac).
- **Corrected:**
  - $15 column: 92 / 920 / 9,200 → 90 / 904 / 9,036.
  - Central P was 18%, which is neither the midpoint of 25% and 14% (19.5%) nor P at a ×0.8 haircut (22%). With MDViewer it is now 19% (24% raw, 14% at ×0.6).
  - Month 6: €25 / €140 / €1,030 → **€30 / €150 / €760**. The p75 is fragile, since one added data point moved it by €270.
  - Month 12: €85 / €350 / €1,470 → **€95 / €350 / €1,450**.
  - G1: $661 ÷ $14–19 = 35–47 sales, not 35–45. The ≥ 30 threshold sits *below* the p75, so the wording now says so (the threshold itself is unchanged).
- **Unverifiable:** Product Hunt rank for ExtraBar (#5, 149 pts); r/macapps rules via a Redlib mirror; Otabek's and the IH founder reports. All of these are already labelled [S].

**Halal check:** no violations found. The icon is geometric, demos are silent, BNPL is disabled, there's no fake "was" price, there's no holiday theming, the tools are read-only (rule B) and none of it is Islamic-themed. One note: if the r/macapps "transparency path" is used, the identity or LinkedIn profile must carry no face photo (rule 1).

**Overall:** the data is real and reproducible, and one cohort omission had flattered the dev/AI pick and the month-6 high case. The verdict ("cheap, gated experiment, not an income plan") stands.
