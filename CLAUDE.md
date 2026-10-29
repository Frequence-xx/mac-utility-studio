# Tegel (Mac Utility Studio): Claude developer guide

A small studio of native, read-only Mac apps sold as one-time licences. The business case,
gates and every number come from `BUSINESS-PLAN.md`. The execution plan is
`docs/superpowers/plans/2026-10-27-00-master-roadmap.md`, which links the per-milestone plans.

- **App 1** (`Apps/Markdown`): Markdown + Mermaid reader. Quick Look extension, RTL, paginated PDF.
- **App 2** (`Apps/Data`, from W10): JSON/JSONL/YAML/TOML/CSV/.env reader and Quick Look pack, plus a session-transcript mode.
- **Shared code:** `Renderer/` (HTML/CSS/JS sources and tests) and `Packages/TegelKit` (Swift libraries `TegelKit` and `TegelStore`). bun builds the renderer into `Packages/TegelKit/Sources/TegelKit/Resources/Renderer/`, which is committed so Xcode builds never need bun.
- **Other parts:** `site/` (static site → Cloudflare Pages); `scripts/` (release, notarise, appcast).

Repo: `git@github-mus:Frequence-xx/mac-utility-studio.git` (SSH alias in `~/.ssh/config`, deploy key `~/.ssh/id_ed25519_mus`). Branch `main`.

---

## Commands

| What | Command |
|---|---|
| Everything the pipeline's stage 2 needs | `make check` |
| JS renderer tests | `bun test` (in `Renderer/`) |
| Rebuild renderer bundle | `make renderer` (then commit `Packages/TegelKit/Sources/TegelKit/Resources/Renderer/`) |
| Swift package tests | `swift test --package-path Packages/TegelKit` |
| Generate Xcode project | `xcodegen generate` (the `.xcodeproj` is generated and gitignored; edit `project.yml`, never the pbxproj) |
| Build app targets | `make build` |
| Release (sign, notarise, DMG, appcast, upload) | `scripts/release.sh <app> <version>` (needs Developer ID + `.env`) |

## Hardware constraint (MANDATORY to know)

The build Mac is an **Intel iMac19,1 on macOS 15.7, Xcode 26.3**. It can never run macOS 26 or 27, and it can't run arm64 code or macOS VMs.

- Universal binaries build here, but the **arm64 slice and macOS 26/27 are only tested remotely**: GitHub Actions macOS runners, or a rented Apple Silicon Mac (`REMOTE_MAC_*` in `.env`).
- Never claim something "works on macOS 26/27" or "works on Apple Silicon" from a local run. Say which machine produced the evidence.

---

## Product rules (MANDATORY: from BUSINESS-PLAN.md §5 and §6)

These bind code, UI copy, site copy, screenshots, demo videos and launch posts:

1. **Read-only.** The apps never write to user files. The only writes are exports to a path the user picked in a save panel (PDF; App 2's session transcript as Markdown, BUSINESS-PLAN §6.2), plus the app's own container. No telemetry, no accounts, no network calls except licence checks and Sparkle updates.
2. **Untrusted input.** Every opened file is untrusted. The renderer runs under a strict CSP: no network, no inline script, and output sanitised with DOMPurify. Mermaid uses `securityLevel: 'strict'`, and navigation is blocked. `.env` values are masked by default.
3. **Imagery.** Text, code and diagrams only. The icon is a plain geometric tile. No faces, figures, animals, mascots or Delft figurative tiles. Arabic sample text is never Qur'an or hadith.
4. **No music or audio** anywhere (apps, demos, site). Demo videos are silent, with captions.
5. **No holiday theming** (the December launch included). No giveaways by draw, no "spin to win".
6. **Honest pricing.** A dated introductory price only, never a fake "was" price (art. 5a Bpp). No fake counters or scarcity. Licence limits are stated before purchase. 14-day refund.
7. **No riba.** BNPL methods are disabled in the MoR checkout. One-time prepaid licence only.
8. **No ads**, in or around the apps.
9. **Excluded app categories:** power/thermal, captions/accessibility-critical, health/posture, camera gaze, now-playing/music, desktop pets, novelty sound, AI interview copilots, wallpaper content.

## Design standard (MANDATORY for any UI, icon, renderer theme, site page, screenshot or demo)

**The bar:** work a senior Apple-platform designer with 20 years' experience would sign. It should feel native, quiet and exact, with nothing that reads as "AI-generated".

**The single source of truth is `DESIGN.md`**, built in plan 09: type scale, grid, spacing, colour tokens, icon grid, voice. No UI work starts before it exists, and no UI value is invented outside it.

**Skills.** Brief each one into any subagent that touches UI:
- **App UI:** `macos-design-guidelines` (HIG rules for menus, windows, toolbars, sidebars, keyboard, pointer, Settings); `apple-design` (Apple typography, SF Symbols, Liquid Glass, UX writing, animation).
- **Site:** `web-design-guidelines` (WCAG 2.2, responsive, performance); `frontend-design`.
- **Design-system work:** `design-consultation`.
- **Review:** `plan-design-review` (plans) and `design-review` (built UI, with screenshots).

The first three were installed into `~/.claude/skills` on 27 Oct from MIT repos; their `SOURCE` file gives the origin. They are available as skills.

**Native first:**
- System controls, materials, SF Pro / SF Arabic / SF Hebrew, SF Symbols, standard menus and shortcuts, `Settings` scene.
- Liquid Glass on macOS 26+, falling back gracefully on 14/15.
- Respect Reduce Motion, Increase Contrast and the accent colour.

**Banned AI-slop patterns:**
- purple/blue gradients;
- glassmorphism blobs and decorative orbs;
- emoji as icons;
- a generic hero, then three feature cards with icons, then testimonials;
- "Supercharge / Unleash / Seamless / Effortless" copy;
- centred everything;
- uniform 16px rounded cards everywhere;
- drop shadows on everything;
- Inter as a default on the site;
- fake app screenshots;
- stock illustrations;
- placeholder lorem.

**Typography is the product.** Reading themes get a modular scale, a 60–75ch measure, real line-height for Arabic (larger than for Latin), and **no letter-spacing on Arabic**. They also need correct quotes and dashes, tabular figures in tables, and hanging punctuation where WebKit supports it.

**Verification:** design claims need screenshots (light, dark and Arabic UI), plus a `design-review` pass before a milestone closes.

## Outward-facing actions: confirm with the user first

Purchases of any kind. Creating or changing *live* Polar products, prices or discounts. Deploying the public site for the first time. Publishing a release (DMG/appcast upload). Any post, email or submission (Product Hunt, Reddit, HN, IH, Homebrew, Setapp, MAS, press, customers). DNS changes on a live domain.

Approval covers the specific action shown, not the next one. Sandbox and test resources (Polar sandbox, preview deploys, local builds) need no confirmation.

## Accounts: the studio identity only (MANDATORY)

Every account action uses the studio identity: **`marketing@snelverhuizen.nl`** (`STUDIO_EMAIL`), and on Apple the individual team **Mohammed Haroen Baksh, `23N7947PKX`**. This covers Apple Developer, App Store Connect, notarisation, Google, Cloudflare, Polar, Scaleway, MailerLite and every account added later.

- This Mac also holds another organisation's Apple access: **Stichting Tarbiyah Consultancy** (team `72PF8SBQR6`, Keychain certificate "Apple Development: Hamza Bouzaggou (W3Q9G8NSHG)") and a Personal Team `34WLYZ5RS6`, both in Xcode's cached team list. Never sign, upload, enrol or change anything with them.
- Before any change in a web dashboard, read the signed-in account on the page (the email; on Apple also the team name and id). If it's anything else, stop and tell the user.
- Signing names the team explicitly (`DEVELOPMENT_TEAM` from `APPLE_TEAM_ID`, notary profile `tegel-notary`), never a team Xcode picks, and `codesign -dv` must show `TeamIdentifier=23N7947PKX`.

## Secrets

- `.env` is gitignored and `chmod 600`; `.env.example` lists every key.
- Credentials for accounts Claude creates go in `.env` immediately.
- **Keychain holds:**
  - the notarytool profile (`tegel-notary`);
  - the Sparkle EdDSA private key. Its backup lives **outside** the repo.
- Never print a secret value in output, commit messages, plans or logs. Refer to it by its `.env` key name.

---

## Anti-sycophancy (MANDATORY)

Applies to every session, including compacted, resumed and handed-off ones.

- **Banned openers:** "You're absolutely right!", "Great point!", "Excellent!", "Brilliant!", "Love this!", "I understand your concern, however…", "That's a valid approach, but…".
- **On pushback:** don't capitulate by reflex.
  - If the user is right, say what you got wrong and own it.
  - If the user is wrong, defend the answer with evidence.
  - If uncertain, lay out both sides without hedging.
- **Output shapes:**
  - "Review this": the 3 worst issues first, then minor issues, then what works.
  - "Is this a good idea?": failure modes first, then strengths, then a verdict with a confidence %.
  - "What do you think of my plan?": name the weakest link first.
  - "X or Y?": pick one, with reasoning.
- **Anchoring:** answer the question in isolation first, then compare it to what the user seems to want and surface the gap.
- **Self-correction:** if you catch yourself being sycophantic mid-response, stop and restart.

## Coding rules (MANDATORY)

The canonical copy is `~/.claude/coding-rules.txt` (UserPromptSubmit hook). Ponytail governs solution size; these rules govern assumptions, blast radius and verification.

1. **Before coding:** state your assumptions. When two readings exist, present both. Surface any reversal of a commitment already made to the user.
2. **Simplicity:** minimum code, nothing speculative, no single-use abstractions. **Tests assert invariants, not source formatting.**
3. **Surgical changes:** every changed line traces to the request. Remove orphans your change created. Mention pre-existing dead code; don't delete it.
4. **Verify, never assert:** run the check in the same turn and read its output. A guard you haven't watched fail isn't verified. **Assert that capabilities are present, not only that bugs are absent.**

Skill routing:
- `superpowers:systematic-debugging` before any bug fix;
- `superpowers:test-driven-development` before implementation code;
- `superpowers:verification-before-completion` before claiming anything passes.

---

## Mandatory 9-stage review pipeline

**When:**
- at the end of every milestone plan (`docs/superpowers/plans/*`);
- before every release tag;
- after any change to the renderer's sanitisation/CSP, entitlements, licensing, the release scripts or the appcast.

Per-task reviews inside a milestone use `superpowers:subagent-driven-development`'s reviewer. The pipeline is the milestone gate.

Base = the commit the milestone branch started from (`git merge-base HEAD main`).

1. **Bloat audit (pre):**
   - Run the `code-upgrade` Bloat Audit (`~/.claude/skills/code-upgrade/bloat-audit.md`) on the diff and the touched files.
   - Strip self-introduced bloat. Queue pre-existing findings as questions for the user.
2. **Baseline:** `git status`, then `make check`. Record the pass/fail counts; they are the baseline later stages must not regress.
3. **Code reviewer:** a cold review of `git diff <base>...HEAD`, prioritising bugs, security and correctness (gstack `/review` or a code-review subagent).
4. **Security review:** run `/cso` when the diff touches any of these:
   - renderer HTML/JS, CSP or DOMPurify config;
   - file parsing (Markdown, JSON/JSONL/YAML/TOML/CSV/.env);
   - entitlements or sandbox exceptions;
   - security-scoped bookmarks;
   - licensing/Polar calls or Keychain;
   - Sparkle/appcast/EdDSA;
   - `scripts/release.sh`;
   - `.env` handling;
   - site forms or external URLs.
5. **Adversarial challenge:** `/codex` challenge mode (codex CLI is logged in), or the closest agent fallback.
6. **Consolidate:** merge findings, dedupe, classify P0/P1/P2, and decide what must be fixed.
7. **Patch + re-review:** fix every P0/P1 and the actionable P2s, then re-run the targeted checks and review until they're closed.
8. **Bloat audit (post):** re-run the Bloat Audit over the final cumulative diff, with the same rules as stage 1.
9. **gstack `/review` + cubic:**
   - Run `/review`, then `cubic review -b <base-sha> -j` from the repo root. The JSON key is `issues`.
   - Re-run after each fix batch until **two consecutive rounds show no new P0/P1**. Cubic can't converge while an agent is still writing to the tree, so stabilise first.

**If a stage can't run:** say which stage, why, and what you ran instead. Never skip silently.

---

## Tools

| Tool | Use |
|---|---|
| Browser | gstack `/browse` for web QA; the Playwright MCP for account set-up and dashboards. Never `mcp__claude-in-chrome__*` |
| `graphify update .` | After code changes |
| `graphify path "<A>" "<B>" [--undirected]` | Blast radius between two real symbols |
| grep | Locating a known symbol (not graphify `query`) |
| xcodegen, bun, cubic, codex | Installed |
| gh | Installed; needs `gh auth login` by the user for API operations. Git push works over the SSH deploy key |
