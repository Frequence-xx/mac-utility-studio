# M00 stage 8: bloat audit (post)

Scope: `git diff 68f3bf5...HEAD -- docs/superpowers/plans/`, at HEAD `c6c73d6`. The plans are 12,041 lines: 11,655 after consolidation (`5015d71`), then +386 net from stage 7 (+2,663 / −2,277).

Method: `~/.claude/skills/code-upgrade/bloat-audit.md`, plus the writing-plans proportion rule. A plan states decisions. It doesn't transcribe bodies, repeat another plan or the master, or carry steps that decide nothing.

Not flagged, by rule:
- security guards;
- watched-fail steps on security or money paths;
- user-approval gates;
- exact values;
- the single owner copy of a rule.

Where a finding touches a guard, only the duplicate goes and the guard stays.

**Result:** 19 findings: 4 high, 8 medium, 7 low. About 138 lines are removable: about 117 from the high and medium findings, and 21 from the low ones. Two items are correctness issues found along the way rather than bloat; they're listed at the end for stage 9.

## Findings

Origin: **S7** means the text was added in stage 7 (`c6c73d6`). **pre** means it was already in `5015d71` but wasn't in the stage 1 list.

| ID | File:line | Cut or replace | Replacement | Lines | Conf. | Origin |
|---|---|---|---|---|---|---|
| P-1 | 01:1907–1912; 02:1813–1824 (CR-1, 3, 4); 03:1229–1250; 04:1035–1053 (all but CR-5); 05:921–932; 06:1004–1009 (CR-1, 2, 5, 6); 07:1071 (row 14, which duplicates 08 CR-13); 08:1260–1292 (CR-2, 3, 4(a)–(c), 6, 13); 09:1190–1198 (CR-9, CR-13, which duplicates 01 CR-1) | Contract change requests that have already been accepted and applied are kept in full: the change, the reason and the status. Master §3 now carries each one: 00:109, 130, 143, 146, 155–224, 238–253, 264, 336, 345, 348, 397. Downstream plans carry the rest: 01 `SANITIZE_CONFIG`, 05:171, 05 has no `ffmpeg-full`. | One line per plan: "CR n–m accepted and applied to master §… (27 Oct); history in `docs/reviews/m00-consolidated.md`." Keep only the open items: 02 CR-2; 04 CR-5, the release runbook (see note 2); 06 CR-3, 4 and 7; 07 rows 1–12 and 15; 08 CR-4(d)–(f), 5, 7–12 and 14; 09 CR-1–8 and 10–12. | ≈70 | medium | S7 (the applying made them history) |
| P-2 | 00:424–426, 436–444 | Procedure P stages 1–3 and 5–9 re-type CLAUDE.md's pipeline, and 00:415 already says "CLAUDE.md wins on any difference". | "Stages 1–9 are CLAUDE.md's, with `BASE=$(git merge-base HEAD main)`. Stage 7 adds: every new guard is watched failing first." Keep stages 10–11 and the "can't run" rule, which are master deltas. | ≈12 | low (a single checklist may be deliberate) | S7 |
| P-3 | 00:428–435 | Stage 4 says "whenever the diff touches a CLAUDE.md stage-4 trigger:" and then re-lists all eight triggers. | End the line at "…a CLAUDE.md stage-4 trigger." | 8 | medium | S7 |
| P-4 | 01:40, 03:29, 04:46, 05:33, 06:57, 07:33, 08:54 | The `.env` (K1) bullet is restated in seven Global Constraints. Master 00:325 owns the rule, plan 01 Task 1 defines `env.sh`, and `check-guards.sh` fails `make check` on `set -a`. Plan 03 also restates it twice: GC 03:29 and Conventions 03:63. | Delete each bullet; the GC header line already cites master. In 03, keep only Conventions 03:63. Keep 04:46's last sentence ("each Bash call is a fresh shell…") only if it isn't already a convention. | 7 | high | S7 |
| P-5 | 03:1132–1139 | Task 13 Step 13's OTHER-key block re-types Task 1 Step 9's `act`/`deact` helpers verbatim, with another key and without `probe-3`. | "Run Task 1 Step 9's block with `K=$(envget POLAR_SANDBOX_OTHER_LICENSE_KEY)` and without `act probe-3` → `200`, `200`, `204`, `204`." The D1 check itself stays: it's a money path. | 7 | medium | pre |
| P-6 | 02:120, 02:141–143, 02:243, 02:245–249 | Plan 02 re-specifies plan 01's bounded open (K11), which plan 01 Task 7 already specifies (01:1259) and watches failing (01:1376). Step 8 adds "make the open bounded… skip the edit if Step 1 found no `regularFileContents`" and a stop-and-report branch: a hedge against plan 01 not doing its own task. | Drop the `Modify` line and the Interfaces bullet. Step 7: write `LargeFileOpenTests`, run it, expect PASS (plan 01 Task 7). Watch it fail with the one-line whole-file read, then remove the line. The new automated test and its watched fail stay. | 6 | medium | S7 |
| P-7 | 07:546–553, 07:1070 (CR row 13) | The `workflow-gate` Make target duplicates `check-guards.sh`'s SHA-pin check (01:318). Its expected result ("FAIL, listing the `@v…` lines in plan 01's `ci.yml` and plan 05's `smoke.yml`") can't happen, because both files are SHA-pinned and `make check` already fails on a tag (see note 1). | Add one line to `scripts/check-guards.sh`: the `${{ inputs.` grep, minus the `NAME: ${{ inputs.x }}` env lines. Watch it fail on the planted `run: echo ${{ inputs.version }}`. Drop the Make target, the pin regex, the "pin each to its B0 SHA" sentence and CR row 13. The inputs guard (S24, S25) stays. | 5 | medium | S7 |
| P-8 | 04:572, 756, 804, 864, 966 | Five "**Prerequisite (P1-3):** read `DESIGN.md` … no value outside it" lines. GC 04:44 and CLAUDE.md already bind this. B15 cut the same boilerplate from plans 02, 05 and 06; plan 04 wasn't on its list. | Delete them. Keep 04:512, which carries the Drop A merge check. | 5 | low (each names the DESIGN.md sections to read) | pre |
| P-9 | 07:156–160 | G5 Step 1 re-types plan 05's support-gate command in a fence. Plan 05 (05:436) says it is "the only support-gate implementation", so this is a residual of B9. | "Run plan 05 Task 4 Step 5's check command." | 3 | high | S7 |
| P-10 | 01:35–38; 09:41 | Renderer security values are copied into Global Constraints: the CSP string, the three rule-list rules, the DOMPurify forbid list and the Mermaid pass. Master §3.2 (00:155–183) owns them and plan 01 Task 5 implements them. Stage 7 had to patch every copy (`tegel-doc:`, the `|` split), which is the drift this invites. | 01: "Renderer security (CSP, content rule list, sanitiser, Mermaid pass): master §3.2, built in Task 5; any change runs Procedure P." 09:41: "Renderer CSP: master §3.2; this plan never changes it." The owner copy and Task 5's implementation copy stay. | 3 | medium | S7 |
| P-11 | 04:858–860; 04:1057 | Task 13's "(removed)" body re-explains the btw-id (already in Task 7 and K17). 04:1057 answers U-6, which is no longer asked (residual of B14). | Keep the heading only, as `### Task 13: (removed; number kept)`. Delete 04:1057. | 3 | high | S7 |
| P-12 | 05:157–160, 05:825; 09:1041 | Plan 05 builds an ad-hoc `grep` pin guard for `smoke.yml` and watches it fail. Plan 09 re-watches `check-guards.sh` failing on a planted tag. That guard is already in `make check` and was watched failing in plan 01 Task 1 Step 8. | 05 Step 7: keep the YAML line, then "`make test-shell` → exit 0". At 05:825, "check-guards passes". 09:1041: stop after "exit 0". The guard is unchanged. | 2 | high | S7 |
| P-13 | 03:20–22, 03:277; 07:28 | Plan 03 GC restates master's K5 licence rules (00:38–40), plus a changelog sentence: "This replaces the earlier rule that a clock moved backwards stays Pro." A test comment, `// K5: was "stays Pro", which made grace unbounded`, would ship into the source. 07:28 restates the licence rules and the kill path (00:38, 41). | 03: "Licence rules: master GC (K5); Tasks 4–7 implement them; the app sends no API token." Drop the changelog sentence and the `was …` comment tail. 07: "Licence and kill path: master GC; Task G7 is Procedure S." | 2 | medium | S7 |
| P-14 | 04:41, 05:30, 05:914, 06:862, 07:27, 08:43 | Pricing and "EUR pending user confirmation" are restated six more times. The owners are master 00:32–34, the gate at 04:771 (Task 11 Step 0) and Open question 04:1059. 04:41 also overlaps decision A8 (04:73), and 08:43 re-quotes plan 05's verbatim wording. | Cite the owner: "Price: master GC; wording: plan 05 GC." Fold 04:41 into A8, and drop the 05:914 bullet, which duplicates the open question. | 2 | low | S7 |
| P-15 | 03:1104 | A step that tells the executor not to do something: "No second BNPL look … (B17)". | Delete it. Task 13's title can drop "BNPL record" only if 03:1151 moves; otherwise leave the title. | 1 | medium | S7 |
| P-16 | 05:33 (last two sentences), 04:234, 08:421 | Hand-rolled `.env` key checks (`[ -n "$(envget K)" ] && echo set`, plus a loop), with a sentence explaining why `grep` isn't used. Plan 01's `need KEY…` does exactly this (01:301). | `need K1 K2 … && echo set`. | 1 | low | S7 |
| P-17 | 02:140 (last two sentences), 06:992 (after "Procedure S") | Plan 02 describes plan 08's preview mechanism, which master 00:265 owns. Plan 06 re-summarises Procedure S after citing it. | End each at the citation. | 1 | low | S7 |
| P-18 | Code fences: 01:279, 316, 536, 744, 887, 970, 989; 02:137, 227, 297, 374, 379, 386, 448, 475, 526, 544, 858, 862, 903, 935, 954, 1018, 1067, 1082, 1297, 1344; 03:252, 277, 408, 548, 561, 949; 04:110, 112, 449, 466; 06:367, 451, 649, 750, 782, 795; 07:499; 08:342 | Review ids (`K11`, `S12`, `CR-P2-24`, `Review Focus 7`) in code comments. These are copied into shipped source and tests, where the ids mean nothing. Stage 7 added 287 lines with K ids and removed none. The ids in prose are fine as pointers. | Keep the plain-language reason where there is one (e.g. "a FIFO named trap.md must not hang Quick Look") and drop the id. The test-to-focus mapping already lives in each plan's Review focus (e.g. 02:67). | 0 (≈45 comment tails) | low | S7 and pre |
| P-19 | 00:308 | The `H2-status` row is a dated status log (≈250 words) inside the roadmap. Its K3 bullet repeats 00:326 and 03:30. | Move the log to `docs/ops/` or the session hand-off. Leave one line: "H2: enrolled 27 Oct; see `docs/ops/accounts.md`." | 0 (≈200 words) | low | S7 |

**Total:** ≈138 lines. High: P-4, P-9, P-11 and P-12, ≈15 lines. Medium: P-1, P-3, P-5, P-6, P-7, P-10, P-13 and P-15, ≈102 lines. Low: P-2, P-8, P-14, P-16, P-17, P-18 and P-19, ≈21 lines.

## Checked and not flagged

- **Watched-fail steps:**
  - security: waitlist 08:506, 664, 814, 961; mask/K12 06:488, 547, 715; user-CSS network 07:326; keylogging 07:895; store build 07:475, 697;
  - money: licence skew/decode 03:299, 442; currency 04:414, 799.

  None duplicates another guard.
- **Plan 01's manual 2 GB watched fail (01:1376)** and **plan 02's new automated test**. These are two different guards: G0 evidence, then a regression test.
- **Plan 08 HR1–HR9 and the K16 channel mix.** Both were mandated.
- **The /cso scope lists in each pipeline task.** These are the per-plan deltas that Procedure P asks for.
- **Plan 09 Task 1's DESIGN.md text.** These are exact values and DESIGN.md doesn't exist yet. See B12.

## For stage 9 (correctness, not bloat)

1. **07:553.** `workflow-gate`'s watched fail expects `@v…` lines in `ci.yml` and `smoke.yml`. Both are SHA-pinned (01:1556, 05:157), so the step can't produce that output, and an executor would stall on it. P-7 removes the step.
2. **04 CR-5 (04:1046–1050): the release runbook writes `site/config.json` `version`/`downloadURL`, but the plans disagree on who does it.**
   - 03:1032 says plan 05 writes it.
   - 05:234 says plan 04 Task 14 does.
   - 04:987 expects plan 06 to supply `apps.data.downloadURL` at W15, but plan 06 never mentions `downloadURL`.

   One owner needs naming, and plan 06 needs the step.

## Stage 1 items: status

Rule: B1–B21 (high and medium) were to be applied; B22–B29 (low) were skipped.

| Item | Stage 1 conf. | Status | Evidence / residual |
|---|---|---|---|
| B1 pipeline re-typed per plan | High | Landed | One Procedure P in master §11 (00:413–448). Plans say "Run Procedure P (master §11)" plus deltas. Procedure P itself re-types CLAUDE.md: P-2, P-3. |
| B2 commit boilerplate | High | Landed | One trailer definition per plan. The `git commit` fences are only the definitions (01:44, 09:39). |
| B3 duplicate weekly report | High | Landed | Plan 04's weekly `gsc-log` is gone; plan 08 Task 5 owns the weekly KPI. |
| B4 second visit counter | Medium | Landed | No Cloudflare analytics token; visits come from Web Analytics (08 CR-8). |
| B5 ICE backlog / sequential tests | Medium-high | Landed | A single trigger at 08:388. |
| B6 `UpsellPolicy` | Medium-high | Landed | Master 00:262–265: app-side `UpsellFeature`, no `UpsellPolicy`. |
| B7 G1b jq count | High | Landed | G1b uses `polar_sales.py`. |
| B8 two net formulas | Medium | Landed | `summarise` in `polar_sales.py` (08:265; 07:84). |
| B9 two support-gate commands | High | **Partial** | One implementation (05:436–439), but 07:156–160 re-types it: P-9. |
| B10 GCs restate master | Medium | **Partial** | Every plan has the "master applies, deltas only" line. GCs still restate `.env` (P-4), renderer security (P-10), licence/K5 (P-13) and pricing (P-14). |
| B11 self-review coverage tables | Medium | Landed | Only verified/unverified lists remain (02:1809–1811, 05:900–919, 08:1242–1255). Plans 01 and 09 have none. |
| B12 DESIGN.md text in plan 09 | Medium | **Partial** | The §7 copy is gone (09:226 names the CSS files as the only home). Task 1 (09:143–286) still carries DESIGN.md's text. It's dated today and DESIGN.md doesn't exist yet, so it's the only copy for now. Once T1 commits, replace Steps 1–11 with "Done: `DESIGN.md` @ <sha>". |
| B13 price switch written three times | High | Landed | Plan 05 Task 12 is the owner. |
| B14 imprint checks + U-6 | High | **Partial** | The checks were cut. 04:1057 still answers U-6: P-11. |
| B15 DESIGN.md prerequisite lines | High | Landed (02, 05, 06) | Plan 04's six lines weren't on B15's list: P-8. |
| B16 source-format greps | Medium-high | Landed | The eight listed greps are gone. The new 05:157–160 pin grep is P-12. |
| B17 BNPL procedure ×3 | Medium | Landed | One procedure, in plan 05 Task 2 Step 11. The second sandbox look is gone, but its "don't" line remains: P-15. |
| B18 smoke re-checks intrinsic DMG properties | Medium | Landed | Intrinsic checks run once, in `release.sh`. |
| B19 second site-test harness | Medium | Landed | The App 2 cases are in plan 04's site tests. |
| B20 CI-minutes check ×4 | Medium | Landed | Plan 05 Task 3 Step 3 is the owner. |
| B21 duplicate release review | Medium | Landed | 05:844 is conditional. |
| B22 `release.sh` sub-steps | Low-medium | Skipped by rule | Not applied; the Task 12 body grew in stage 7 (e.g. 03:986, 03:1030). |
| B23 duplicate GUI smoke | Low-medium | Skipped by rule | Not applied (03:762). |
| B24 Drop A runs stages 2/3/4/9 | Low | Skipped by rule | Not applied; master 00:409 keeps the pre-merge subset. |
| B25 deep-link check with 3 owners | Low | Skipped by rule | Applied anyway (08 CR-7: one owner, plan 08 Task 11 Step 2). |
| B26 two dispatch workflows | Low | Skipped by rule | Not applied (00:146–147). |
| B27 RSS feed | Low-medium | Skipped by rule | Not applied (04:150, 04:417). |
| B28 data-based Quick Look spike | Low | Skipped by rule | Not applied (01:1495). |
| B29 App 3 / v2 test code before brainstorm | Low | Skipped by rule | Not applied (07:813–906, 07:990–1031). |
