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
| 9 /review + cubic | | |
