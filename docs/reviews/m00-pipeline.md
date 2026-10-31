# M00 pipeline: master roadmap + plans 01–09

Branch `plans/m00-full-plan`. Base `68f3bf5` (main, bootstrap). Plans-only diff: no code, no Makefile.

| Stage | What ran | Result |
|---|---|---|
| 1 Bloat audit (pre) | `code-upgrade` bloat-audit + writing-plans proportion rule, agent → `m00-bloat-audit.md` | 29 findings, ≈ 1,320 lines removable, all self-introduced |
| 2 Baseline | `git status` clean after commit b7648d5. `make check` **can't run**: no Makefile or code exists yet (plan 01 Task 1 creates them). Substitute: the cross-plan consistency sweep (stale-name/value grep over all plans, 27 Oct). Zero hits except intentional mentions | done |
| 3 Code review | Cold agent review → `m00-code-review.md` | 1 P0, 4 P1, 29 P2 |
| 4 Security (/cso) | Agent review against the CSO threat model → `m00-security-review.md`. gstack `/cso` runs as a skill over a codebase; with plans only, an agent applied the same threat model | 0 P0, 4 P1, 25 P2 |
| 5 Adversarial | `codex exec -s read-only` challenge (codex-cli 0.163.0) → `m00-codex-challenge.md` | 19 P1, 5 P2 |
| 6 Consolidate | `m00-consolidated.md`: 18 merged clusters K1–K18, single-plan fixes, bloat B1–B12; USER items: EUR prices, key-backup location, passwords in `.env` | done |
| 7 Patch + re-review | 7 parallel fixers (one per plan group), then a coordinator sweep for cross-plan conflicts: `€ ?14` NBSP false pass (plan 05 → plan 04 Task 15 checks), K14 narrowed back to BUSINESS-PLAN §12, opt-in wording (plan 04), master §3.3 CR-1/3/4, Mermaid SVG pass + 3 rule-list rules (plan 01 CRs), `themeCSS` break-out fixture. Fences balance in all 10 files; no `set -a` outside rule text | done |
| 8 Bloat audit (post) | Fresh agent → `m00-bloat-audit-post.md`: 19 findings (4 high, 8 medium, 7 low), 2 correctness items. High+medium applied by one fixer: −101 lines (12,041 → 11,940). Release keys `version`/`downloadURL` now have one owner (the plan that publishes the release); this moves the App 1 site go-live to Mon 7 Dec and App 2 to Mon 1 Feb, the day before each launch | done |
| 9 /review + cubic | **r1:** cubic (`m00-cubic-r1.md`) 7 P1, 39 P2, 45 P3 → fixed (0eb882c). **r2:** gstack `/review` structured agent (0 P1, 12 P2, 18 P3) and adversarial agent (1 P1, 7 P2, 7 P3); cubic r2 (2 P1, 21 P2, 17 P3); Codex re-run (1 P1, 25 P2, 1 P3). After dedupe, 93 fixed by 5 per-plan fixers (d6fd3a4), 21 cross-plan follow-ups (6accf6f) and 3 gaps (ff8faa9). P1s: release.sh R2 upload via curl SigV4 (no npm while signing keys are usable); waitlist live only after commit, `/cso` and merge; Data's Buy screen showed Markdown's Pro copy. Two reviewer claims rejected with evidence: "notary profile missing" (the screen was locked, which hides the item) and "Markdown export breaks rule 1" (BUSINESS-PLAN §6.2 specifies it; CLAUDE.md rule 1 corrected). **r3: cubic can't run** (subscription expired, 27 Oct); substitute: a cold Claude adversarial agent plus Codex `exec -s read-only`, both on `git diff 0eb882c..HEAD`, P0/P1 only. Exit rule unchanged: two consecutive rounds with no new P0/P1. Results, new P1s per source (Codex / Claude): r3 4 / 1 (a264f90); r4 2 / 0 (f883266, 0b1d823); r5 3 / 1 (53cb2fe, ab2c827); r6 1 / 0 (2002d31, cdc6421); r7 1 / 1 (031ef93); r8 3 / 13, the Claude side split into a `release.sh`-invocation sweep (7) and an `.env`/id-flow sweep (6) (aa5e9a1, a8af37b, 45f103b); r9 0 / 5 (8100ef8); r10 2 / 5 new (2000a8d, 51fa87b: the recurring dirty-tree class fixed at its root, as `release.sh` and stage 2 now ignore `docs/`, where the daily logs, QA rows and plan records live; `release_test` gains `docs-dirty`, 28 cases); r11 1 / 3 (17a7ec8, bbec5e5); r12 2 / 3 (1c93922: no Buy link reaches `main` before its DMG; Quick Look CSV masking no longer depends on the header vote; Select joins `make build`); r13 1 / 3 (ae717cc, a0dfa3c). r14: Codex hit its usage limit mid-run (27 Oct 23:2x) and was re-run after the reset (28 Oct 02:40) rather than substituted: 1 P1 (`.netrc` value on its own line, 185c974). From r24 the Claude side alternated targeted checks of the newest fix commits with end-to-end sweeps by area or theme, so every plan had at least one full sweep: plan 06 (r24, r26), plan 07 (r26), plans 05 and 08 (r27), plans 01–03 (r28), master, 04 and 09 (r29), cross-plan timeline, `.env` keys, branches and scripts (r30), design standard (r31), money and law (r32). New P1s per round (Claude / Codex): r24 3 / – (032a8b4); r25 1 / – (475aecd); r26 1 / – (ec23292); r27 4 / 1 (ac2ad0a, 185c974); r28 5 / 0 (8e3eafd); r29 4 / 0 (fb8c1e7); r30 2 / 0 (301f564); r31 3 / 0 (f68991b); r32 6 / 0 (95e3cc7); r33 2 / 0 (c089b68, 7a756c6); r34 1 / 0 (f571cf1); r35 0 / 1 (2a1f7d6, e38142b); r36 1 / 0 (89e8941); r37 1 / – (58d2f9a; Codex hit its usage limit again, 29 Oct 15:2x). Main classes fixed: Quick Look whole-file masking reduced to an explicit keep-list (netrc keywords, PEM armour, INI sections, whole-line masked URLs) with every watched failure simulated; every secret saved from the pasteboard (master §6); plan 07 direct releases update the site's version and download link; the waitlist form is placed and removed by plan 08 with checks; RCs merge `main` so 1.0.0 carries only RC-tested code; the privacy text discloses the 24 h address hash; App 2 pages have one owner and branch (plan 06 Task 13); Data's Welcome carries no licensing (new `DataProView`); refunds revoke every key; v2 upgrade codes skip erased buyers; middle-dot meta strings and sentence-case buttons removed from UI. Quick Look masking beyond `.env` values and secret dotfiles is now stated as best-effort (plan 06 Global Constraints, Scope). Account identity (user instruction, 29 Oct, between r37 and r38): 8e8597a adds CLAUDE.md "Accounts". Every account action uses `marketing@snelverhuizen.nl` and Apple team `23N7947PKX`. Stichting Tarbiyah Consultancy (team `72PF8SBQR6`, present on this Mac in the Keychain and in Xcode's team cache) is never used. Signing checks pin `TeamIdentifier`. Two cold reviews of it: first 1 P1 (the Search Console steps didn't name the Google account) and 5 P2 (6312ce0); then 0 P0/P1 and 6 P2 (5 fixed in 4b37753). r38: Claude 0 (re-simulation of every Task 4 watched failure plus a cold re-read of `475aecd..58d2f9a`); Codex 1 P1 on 4b37753 (the whole-file INI `[section]` exception showed a `.netrc` value like `[x]`, and a value that is a bare keyword showed the same way; fixed in 1b478b8). r39: Codex 0; Claude 2 P1 (a `.git-credentials` token in the URL's user slot showed; an earlier edit had dropped plan 04's "pastes the TXT value" from the normal path; fixed in e1265a8). **Exit:** r40 (Codex 0 on e1265a8; Claude 0 P0/P1, its 4 P2 fixed in c1f1ff8) and r41 (Codex 0 and Claude 0 P0/P1 on c1f1ff8, which includes those P2 fixes): two consecutive rounds with no new P0/P1. The whole-file masking rule and each of its watched failures were simulated in bun, by me and by two independent reviewers. **P2s left for the owning milestone's stage 7:** `git log --until` time of day (plan 06 Task 16 Step 4); `DataProView`'s Buy link has no `reference_id`; Licence "lapsed and each error" screenshots have no recipe; the comparison page has no sales-tax test; plan 08 Task 15 Step 2 doesn't cite the checkout outcome; no check that the Arabic form renders; Arabic copy for the form's email label and small print; plan 08 file map and CR 4(d) list only the English partial; `m07-stop` and `content/release-1.0.1` have no explicit `git switch -c`; plan 05 Task 3 Step 2's merge runs with the plan file's records uncommitted; RC2 happens only after a FAIL, so a branch merged after RC1 can reach 1.0.0 untested by an RC; plan 06 never says when "Launches Tue 2 Feb 2027" comes off the App 2 pages; Data's Settings `TabView` must bind `settingsTab` for "Enter Licence Key…"; plan 08 Task 8 Step 5c's new `curl` needs the `H=` prefix in a fresh shell; under the EU-VAT outcome plan 04 Task 4's `'$14'` test for `{{price:}}` changes; `maskSecrets`' "authority's last `@`" and authority-end rules have no test of their own (a first-`@` split passes all 14); a password that is itself a `.netrc` keyword shows when it starts a line followed by another token (a second ceiling, not yet named in the comment); Task 4 Step 5's "keep every line's first token" mutation should say "even on a one-token line"; CLAUDE.md "Accounts" compares the Cloudflare and Polar ids while `CLOUDFLARE_ACCOUNT_ID` and both Polar org ids are still empty (it stops and asks the user, the safe side); plan 03 Task 3 Step 1's `find-certificate -c` isn't pinned to the team; master §1's "Accounts: None created yet" belongs to the dated 27 Oct snapshot. Rejected or accepted with reason: KV counter overshoot (an accepted ceiling, bounded in plan 08's waitlist step); `release.sh` item 7's non-empty org/benefit checks run only on a real build, since the clean-tree rule blocks a mutation run (plan 05 Task 2's `org-ok` asserts the value positively) | done |

## Addendum: the 29 Oct decisions round (r42–r56)

Range `5310a1f..fad5bbd`: 17 commits, plans and CLAUDE.md only (14 files, +167/−80 lines). The user's 29 Oct answers (master §5) moved account passwords from `.env` to the login Keychain (S28) and added two session hooks. That changes secret handling, so the pipeline ran again (CLAUDE.md "When").

- **Stages 1 and 8 (bloat):** no separate audit. Each added line traces to a review finding, and the delta is 167 lines of plan text.
- **Stage 2 (baseline):** still can't run, because the delta is docs only and no Makefile exists yet.
- **Stages 3–5:** ran inside every stage-9 round. The cold Claude reviewer was briefed on security (secrets, Keychain, key store), and `codex exec -s read-only </dev/null` was the adversarial pass. Codex had hung on stdin at r42 until the `</dev/null` was added.
- **Testing:** every command this delta adds was run on synthetic data or throwaway disk images, under bash and zsh:
  - the exposure search;
  - the password generator;
  - the key-store checks, guard, copy and refresh.

New P0/P1 per round (Codex / Claude):

| Round | New P0/P1 | Fix | What changed |
|---|---|---|---|
| r42 | – / 2 | b580b49 | K3 second copy; passwords pasted, never typed; cubic substitute |
| r43 | 1 / 3 | 66e8c4b, 2a6dde7 | brand-account passwords to the Keychain; the user submits password forms; key store never recreated |
| r44 | 0 / 2 | 6b268ca | the exposure search looks for the value itself; a hit forces a password change |
| r45 | 1 / 1 | c06fed3, 7715741 | JSON-escaped match; every secret a page shows follows the password rule |
| r46 | 0 / 1 | eaeff50 | no screenshot may show a secret (the search reads text only) |
| r47 | 0 / 2 | 5a00895 | MailerLite password via `tegel-mailerlite`; keyless licence-error shots; the search decides on grep's output, not its exit status |
| r48 | 0 / 0 | 9ee18d8 (P2s) | transcript folder checked; generated passwords end in a symbol |
| r49 | 0 / 1 | 82b6c51 | one "Licence keys on screen" line in the Global Constraints of plans 03–08, after three rounds of per-step patches |
| r50 | 0 / 0 | 62d3d73 (P2s) | dashboard key views; directory-site accounts; Scaleway and Cloudflare name the search |
| r51 | 0 / 0 | 4cc8d47 (P2s) | `not-mounted` never creates a store; secret snippets source the helper |
| r52 | 0 / 0 | ece7d28 (P2s) | both media checked before create; image mount verified |
| r53 | 0 / 1 | 781f3a8 | the key-store guard checks *which* image is mounted (`hdiutil info` image-path) |
| r54 | 0 / 1 | e9d9d53 | media named `TegelWork` and `TegelSpare`, with literal paths, so plug order can't swap them |
| r55 | 0 / 0 | fad5bbd (P2s) | the first copy never overwrites; the refresh goes through `TegelKeys.dmg.new` |
| r56 | 0 / 0 | – | exit |

**Exit:** r55 and r56 had no new P0/P1 on either side. r50–r52 had also been clean, until r53 reopened the key store.

**Incident found at r43.** The 27 Oct Apple sign-up's Playwright snapshots held the Apple Account password in plaintext, and that session's transcript still does. The snapshots were deleted on 30 Oct, and the exposure search lists the transcript. Changing the password is a USER item (master H2-status), due before plan 01 starts.

**P2s left for the owning milestone's stage 7:**
- **Plan 03 Task 3 Step 5 item 4:**
  - `rm ~/TegelKeys.dmg` is gated only on both media ejecting; chain it after `copied`.
  - Item 2's reason ("copied over both backups") predates the no-overwrite first copy.
  - Renaming a FAT stick only in case remounts it as `TegelWork 1`. The check then stops, which is safe; replugging clears it.
  - After a refresh, nothing ejects `TegelWork`.
  - Item 2's check exits 1 when everything is fine (its final `grep` finds nothing).
- **Accounts:**
  - The Bluesky and Mastodon brand accounts (plan 08) aren't in the §6 register, and no step says who saves their passwords.
  - Slant and Peerlist may need accounts that plan 08 Task 17 doesn't name.
- **Detection gaps:**
  - claude-mem's database copies Playwright output and isn't in the exposure search. Detection still works, because every snapshot also lands in the transcript.
  - The 27 Oct images in `.playwright-mcp/` (`asc-key.png`, `pay1.png`, `enroll*.png`) predate the screenshot rule and haven't been reviewed.
  - The Scaleway Overview page may hold the server password in a masked input (unverified).
- **Small items:**
  - Stale `cubic review` commands in plan 03 and plan 09; the CLAUDE.md substitute rule covers them.
  - Pasteboard snippets keep the secret on the pasteboard when `envset` fails, deliberately, so a retry needs no re-copy.
