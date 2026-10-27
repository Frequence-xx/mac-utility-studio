# Tegel Data (App 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship Tegel Data 1.0.0, a read-only JSON/JSONL/YAML/TOML/CSV/TSV/`.env` reader. It has a free Quick Look pack and a Pro window with session-transcript mode and Markdown export. Notarised by Mon 1 Feb 2027, launched Tue 2 Feb 2027.

**Architecture:**
- **Renderer:** data views are pure JS functions in `Renderer/src/data/` that return escaped HTML strings, bundled as a lazily loaded `data.js` inside the same CSP page and DOMPurify path as Markdown.
- **TegelKit** gains `DataFormat`/`DataFile` (routing, capped loading), a `RecordIndex` that keeps only record offsets in memory and reads records through `FileHandle` (no mapping, so a file truncated while open gives an error, never SIGBUS), and a `renderData`/`renderPaged` bridge. The window pages through 200 MB files over a reply-message handler with a scaled virtual scroller; Quick Look renders a capped prefix.
- **Apps:** `Apps/Data/{App,QuickLook}` are thin shells: routing, the `isPro` gate, session folders via `BookmarkStore`, export through a save panel. App 2 reuses App 1's licence and update wiring from plan 03 by path (Task 8).

**Tech Stack:** the master stack plus three exact pins (npm registry, 27 Oct 2026; Task 0 bumps each to its newest patch ≥ 14 days old): `js-yaml@5.5.0` (MIT), `smol-toml@1.9.1` (BSD-3-Clause), `papaparse@5.7.0` (MIT). JSON uses `JSON.parse` only.

**Spec:** `BUSINESS-PLAN.md` §2, §4 (App 2), §5 rule B, §6.2, §6.3, §8, §9, §11 W10–W15, §12 G1, §13 risks 4 and 6. Master roadmap D3–D7, D16, D17, §3, §7. `CLAUDE.md`. Facts: `docs/research/2026-10-27-technical-facts.md` [F#] and the [DF#] table below.

**Branch:** `m06-app2`. **Weeks:**

| Week | Dates | Tasks |
|---|---|---|
| W9 | 22–28 Dec | 0 |
| W10 | 29 Dec–4 Jan | 1–3 |
| W11 | 5–11 Jan (G1 Thu 7 Jan) | 4–6 |
| W12 | 12–18 Jan | 7, 8, 12 |
| W13 | 19–25 Jan | 9–11, 13 |
| W14 | 26 Jan–1 Feb | 14–16 |
| W15 | Tue 2 Feb 2027 | launch runbook |

## Facts verified for this plan (27 Oct 2026)

| # | Fact | Status | Source |
|---|---|---|---|
| DF1 | The `UTType` constants `.json`, `.yaml`, `.commaSeparatedText` and `.tabSeparatedText` are `public.json`, `public.yaml`, `public.comma-separated-values-text` and `public.tab-separated-values-text`, all **macOS 11.0+** | VERIFIED | developer.apple.com/documentation/uniformtypeidentifiers/uttype-swift.struct/{json,yaml,commaseparatedtext,tabseparatedtext} |
| DF2 | On the build Mac, macOS 15.7 (measured with `URLResourceValues.contentType`):<br>• **Declared by the system:** `.ndjson` → `public.ndjson` (CoreTypes, conforms to `public.text`). `README`, `LICENSE`, `AUTHORS`, `COPYING`, `INSTALL` → `public.plain-text`. `Makefile` → `public.make-source`.<br>• **Undeclared (`dyn.*`):** `.jsonl`, `.toml`, `x.env`, `.env.local`.<br>• **Plain `public.data`:** `Dockerfile`, `CHANGELOG`, `TODO`, `.gitignore`, `.zshrc`, `.env`. Binaries are `public.data` or `public.unix-executable`. | VERIFIED on 15.7; macOS 14/26/27 UNVERIFIED → Task 1 Step 5 | local probe |
| DF3 | Apple's guidance:<br>• "Define an imported type if your app uses a type that another app defines, or if it's a proprietary file format the system doesn't declare."<br>• "Don't use `public`, `dyn`, or `com.apple` as the prefix in your app's types."<br>• "If both exported and imported declarations for a type exist, the exported declaration takes precedence." | VERIFIED | developer.apple.com/documentation/uniformtypeidentifiers/defining-file-and-data-types-for-your-app |
| DF4 | There's no shared community identifier for JSONL: y-a-v-a/quicklooks declares its own `nl.vincentbruijn.jsonl`. Its README says the system declares `public.toml`. That's false on 15.7 (DF2) and possibly true on 26+ | VERIFIED / 26+ UNVERIFIED → Task 1 Step 5 | github.com/y-a-v-a/quicklooks |
| DF5 | Quick Look:<br>• It dispatches by the **concrete** UTI. A `public.data` claim only catches files typed exactly `public.data` (extension-less files, dotfiles), never `dyn.*` types.<br>• QLStephenSwift ships a data-based extension that claims `public.data`. It rejects any NUL byte as binary and needs macOS 15. Its author says "system plugin wins for core types".<br>• Generator plugins were removed in macOS 15. | VERIFIED (third-party) / precedence UNVERIFIED → Task 7 matrix | github.com/j-256/qlomni; github.com/whomwah/qlstephen/issues/143 (j-256, 23 May 2026); github.com/MyCometG3/QLStephenSwift (Info.plist, README) |
| DF6 | Polar licence keys:<br>• `validate` accepts an optional `benefit_id` and returns **404** when "benefit … do[es] not match".<br>• `activate` has no `benefit_id` input, but its response's `license_key` carries `benefit_id`.<br>• The docs say: "Offering more than one type of license key? Be sure to validate their unique benefit_id".<br>• Benefits are "standalone resources … connected to one or many products".<br>• Orders carry `custom_field_data` (List Orders, scope `orders:read`); a checkbox field stores a boolean. | VERIFIED; whether a 2-benefit product shows both keys in email and portal: UNVERIFIED → Task 12 Step 2 | polar.sh/docs: features/benefits/license-keys, features/benefits/introduction, api-reference/customer-portal/license-keys/{validate,activate}, features/custom-fields, api-reference/2026-10/orders/list-orders |
| DF7 | JavaScriptCore (bun 1.4.0, same engine family as WKWebView):<br>• `JSON.parse` error messages carry **no position** (e.g. `Expected '}'`).<br>• The reviver's third argument `context.source` works, so integers above 2^53 can be kept exact. Whether macOS 14's WebKit has it: UNVERIFIED → Task 2 test accepts the exact value or "≈". | VERIFIED (bun) | local probe |
| DF8 | Libraries:<br>• js-yaml 5.5.0 (`load()`; 5.4.1 hard-limits merge keys);<br>• smol-toml 1.9.1 (`unsafeKeyBehaviour`, `integersAsBigInt`; returned objects must not be spread or `Object.assign`ed: "careless use … may lead to prototype pollution");<br>• papaparse 5.7.0 (no dependencies). | VERIFIED | registry.npmjs.org; smol-toml README "Key safety" |
| DF9 | **Claude Code location:** transcripts live at `~/.claude/projects/<encoded-cwd>/<uuid>.jsonl` (plus `<uuid>/subagents/*.jsonl`) and are written asynchronously. **Scan of 979 local files (structure only):**<br>• `type` values: user, assistant, system, attachment, ai-title, last-prompt, queue-operation, file-history-snapshot, file-history-delta, mode, permission-mode, cost-state, tools-used, api-request(-blob/-shape), atis-latch, frame-link, …<br>• user/assistant records carry `uuid`, `parentUuid`, `sessionId`, `timestamp`, `isSidechain`, `isMeta?` and `message{role, content}`.<br>• `content` is a string or blocks: `text`, `thinking`, `tool_use{id,name,input}`, `tool_result{tool_use_id,content,is_error}`, `image`.<br>• No `summary` records in current files (older versions wrote `{type:"summary",summary,leafUuid}`).<br>**Not a public API** (risk 6). | VERIFIED locally | code.claude.com/docs/en/hooks (`transcript_path`); local scan |
| DF10 | Codex sessions:<br>• Location: `~/.codex/sessions/YYYY/MM/DD/rollout-<time>-<uuid>.jsonl`. Each line is `{timestamp, type, payload, ordinal?}`; `type` is session_meta, response_item, event_msg, turn_context, compacted, token_usage_record, world_state, ….<br>• `response_item.payload.type` is one of: `message{role,content[input_text\|output_text]}`, `reasoning{summary,encrypted_content}`, `function_call{name,arguments,call_id}`, `function_call_output{call_id,output}`, `custom_tool_call{name,input,call_id}`, `custom_tool_call_output{call_id,output}`. | VERIFIED | github.com/openai/codex `codex-rs/protocol/src/{protocol.rs,models.rs}`; scan of 119 local files |

## Global Constraints

Master §2/§3 and `CLAUDE.md` apply (platform, machines and evidence naming, product rules 1–9, design standard, approvals, secrets). Every task with UI reads `DESIGN.md` first; no UI value comes from outside it. Plan-specific:

- **Bundle ids:** `com.tegelapps.data` and `com.tegelapps.data.quicklook` (D7).
- **Writes:** only a Markdown export to a save-panel URL and the app's own container (rule 1). `readonly-gate` (Task 11) scans all of `Apps/`.
- **Secrets on screen:**
  - `.env` values are masked by default and revealed per click in the window only. They never appear in any Quick Look DOM.
  - Quick Look also masks PEM private-key bodies, URL passwords and common token shapes in any file, in every view; the value of every secret-named key or column in tree, row and table views; and every value in secret dotfiles (`.netrc`, `.npmrc`, `.git-credentials`, `credentials`, `id_rsa`, …), with no reveal.
  - The transcript view and its Markdown export mask common token shapes unless the user turns on "Show secrets".
- **Untrusted input:** every string is escaped by our code **and** the result goes through the page's DOMPurify sanitiser.
- **Pricing:** $15 once, 2 Macs; the bundle at $29 grants both licences; EUR prices per master K10 (user-confirmed amounts). Free = Quick Look for every format. Pro = window viewer, `.env` viewer, session mode, export (§6.2).
- **Fixtures:** synthetic and secret-free; never copy a real transcript. Fixture filenames must not be `.env` or `.env.*` (`.gitignore` ignores both). Secret-shaped test strings are built by concatenation inside test files, never committed under `Fixtures/`.
- **Quick Look limits:** reads ≤ 2 MB and shows ≤ 500 JSONL records or 1,000 CSV/TSV rows. It answers in < 2 s.
- **Commits:** "Commit: `<paths>`, `<msg>` + trailer" means `git add <paths> && git commit -m "<msg>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`.

## Review Focus

1. **A CSV with an unbalanced quote** (`"abc` never closed at row 10 of 1M rows). Expect the index not to swallow the rest of the file into one record: it falls back to line records and shows a banner. *Task 5, `testUnbalancedQuoteFallsBackToLines`.*
2. **A huge extension-less binary, or a FIFO, previewed with Space in Finder.** Expect Quick Look to return to the system's generic preview in < 2 s, without decoding garbage or blocking. *Task 5: `testBinaryRejected`, `testFIFORejected`, `testReadsPrefixOnly`.*
3. **A UTF-16 (BOM) CSV or JSONL opened in the window.** Expect correct text through the capped whole-text path, not mojibake rows. *Task 5: `testUTF16BOMThrows` + `testUTF16LoadsAsText`.*
4. **Integers above 2^53 in JSON or TOML** (snowflake ids). Expect exact digits or a visible "≈", never a silently rounded id. *Task 2, `big integers stay exact or are marked`.*
5. **Commented-out secrets in `.env` (`# API_KEY=…`) and `.envrc` files.** Expect those values masked too, and error rows that never echo the raw line. *Task 4 tests; `.envrc` routing in Task 5.*
6. **A 200 MB JSONL truncated while open, and a `.netrc` previewed with Space.** Expect an error and a reload, never a crash, and no secret value in the preview. *Task 5 `testTruncatedFileThrowsNotCrash`; Task 6 `testQuickLookMasksSecretFiles`.*

---

## File structure

```
Apps/Data/App/            DataApp.swift, DataWindow.swift, WelcomeView.swift, SessionsView.swift,
                          SessionSources.swift, ExportController.swift, Info.plist, Data.entitlements
Apps/Data/QuickLook/      PreviewProvider.swift, Info.plist, DataQuickLook.entitlements
Apps/Data/Shared/         DataLabels.swift, Localizable.xcstrings      (compiled into both targets)
Renderer/src/data/        labels.js, parse.js, tree.js, jsonl.js, table.js, dotenv.js, transcript.js, view.js
Renderer/src/css/data.css
Renderer/test/            data-tree, data-rows, data-dotenv, data-transcript .test.js
Packages/TegelKit/Sources/TegelKit/    DataFile.swift (DataFormat, DataFile, RecordIndex), DataRender.swift
Packages/TegelKit/Tests/TegelKitTests/ DataFileTests.swift, WebView/DataRenderTests.swift (+FolderIndexTests)
Apps/Data/App/AppIcon.icon/            plan 09's Data icon (D-5)
Fixtures/data/            sample.*, quoted-newline.csv, hostile.*, sessions/…, generate.js (big-* generated)
scripts/check-data-types.swift, scripts/entitlements/{data,data.quicklook}.plist
.github/workflows/types.yml               (K13 UTType matrix, dispatch only)
site/content/en/          data.md, jsonl-viewer-mac.md, claude-code-transcript-viewer.md, bundle.md (plan 04's URLs)
docs/launch/data-*.md, docs/gates/G1b.md, docs/reviews/m06.md
Modified: project.yml, Config/{Debug,Release}.xcconfig, Makefile, .gitignore, .env.example,
          scripts/{release.sh,release_test.sh} (plan 03), scripts/{smoke-dmg.sh,test-smoke-dmg.sh} (plan 05),
          site/config.json, site/test/pages.test.js,
          Renderer/{package.json,bun.lock,build.js,src/page.js}, TegelKit Resources/Renderer (generated),
          TegelKit {RendererWebView,FolderIndex}.swift (Tasks 6, 10)
```

---

### Task 0: W9 re-validation (Tue 22 – Mon 28 Dec 2026)

**Files:**
- Modify: this plan only.

**Interfaces:**
- Consumes: master §3 as actually shipped by plans 01–05.
- Produces: corrected Consumes/Produces lines in Tasks 1–16, and a filled **W9 re-validation record** (near the end of this file).

- [ ] **Step 1: Branch.** `git checkout main && git pull && git checkout -b m06-app2`
- [ ] **Step 2: Dump the shipped API.** `grep -rhnE '^\s*(@MainActor )?public ' Packages/TegelKit/Sources | sort > /tmp/m06-api.txt`. Diff it by eye against master §3.3 and every **Consumes** line below. Edit each mismatching line in this plan (name, label, type).
- [ ] **Step 3: Answer each check.** Write each answer into the record table.

| # | Check | Command | Changes |
|---|---|---|---|
| 1 | G0: view-based WKWebView or data-based `QLPreviewReply`? Does the Quick Look extension keep `network.client`? | `sed -n 1,60p docs/gates/G0.md` | Tasks 1, 7 |
| 2 | Does `TextFileLoader.load` read only `maxBytes` (a prefix), not the whole file? | `grep -nE 'read\(upToCount\|contentsOf\|mappedIfSafe' Packages/TegelKit/Sources/TegelKit/TextFileLoader.swift` | Task 5 |
| 3 | `FolderIndex.search`: does it read files through `TextFileLoader`'s 5 MB default? Is `markdownFiles` built on a generic walker? | `sed -n 1,200p Packages/TegelKit/Sources/TegelKit/FolderIndex.swift` | Task 10, CR-2 |
| 4 | Does `BookmarkStore.resolveAll()` call `startAccessingSecurityScopedResource()`? Is there a remove function? | `grep -n 'startAccessing\|func ' Packages/TegelKit/Sources/TegelKit/BookmarkStore.swift` | Task 10 |
| 5 | Does `scroll(toHeading:)` take the DOM id and use `getElementById`, and does the data path's sanitise pass set `SANITIZE_NAMED_PROPS` (so `id="L<line>"` lands as `user-content-L<line>`, plan 01 CR 4)? Is `RenderOptions` given a public `init(mode:theme:baseURL:)`? | `grep -n 'getElementById\|public init' Packages/TegelKit/Sources/TegelKit/*.swift; grep -n SANITIZE_NAMED_PROPS Renderer/src/page.js` | Tasks 6, 10 |
| 6 | Does TegelStore send `benefit_id` on validate and check `license_key.benefit_id` on activate (plan 03, D1)? If not, stop and ask the user: no Data product goes live without it. | `grep -rn benefit Packages/TegelKit/Sources/TegelStore` | Task 12 |
| 7 | App 1's patterns:<br>• opening a file from Finder (`application(_:open:)` or `WindowGroup(for: URL.self)`);<br>• the `ProGate.swift` and `LicenceSettingsView.swift` paths, and the Debug override;<br>• the localisation format (`.xcstrings`) | `ls Apps/Markdown/App; grep -rn 'onOpenURL\|open urls\|WindowGroup' Apps/Markdown/App` | Tasks 1, 8 |
| 8 | `page.js`:<br>• the lazy script-loader function (the Mermaid one);<br>• the sanitise function and DOMPurify config;<br>• whether an escape helper is exported;<br>• the content container id;<br>• the test framework (XCTest or Swift Testing) and whether there's a DOM test helper | `grep -nE 'function \|export ' Renderer/src/page.js Renderer/src/markdown.js; ls Packages/TegelKit/Tests/TegelKitTests` | Tasks 2, 6 |
| 9 | `scripts/release.sh`:<br>• the `<app>` values;<br>• the RC/no-upload flag;<br>• the appcast and DMG URL layout;<br>• how pre-release versions are named | `sed -n 1,80p scripts/release.sh` | Tasks 1, 14, 16 |
| 10 | Site: content front-matter keys; App 1 page URL; build and preview-deploy commands; how the sitemap picks up new pages | `ls site/content/en; sed -n 1,40p site/build.js` | Tasks 11, 13 |
| 11 | Polar and launch history:<br>• slug and label of the checkout **opt-in** field on the App 1 product (plan 05 Task 2: `marketing_opt_in`, "Email me set-up tips and news about Tegel apps", unticked);<br>• date of the last r/macapps promotion;<br>• folder of the App 1 launch drafts | `grep -rn 'custom_field\|opt' docs/launch docs/reviews 2>/dev/null \| head` + Polar dashboard | Tasks 12, 15 |
| 12 | Path of the third-party notices file | `grep -rln 'DOMPurify' --include='*.md' --include='*.txt' . \| grep -v node_modules` | Task 2 |
| 13 | How the `make fixtures` target and the generated-fixture `.gitignore` lines are written | `grep -n 'fixtures' Makefile .gitignore` | Task 3 |
| 14 | Newest js-yaml / smol-toml / papaparse release that is ≥ 14 days old | `for p in js-yaml smol-toml papaparse; do npm view $p time --json \| tail -4; done` | Task 2 |
| 15 | Does a GitHub `macos-27` runner image exist? | `curl -s https://raw.githubusercontent.com/actions/runner-images/main/README.md \| grep -n 'macos-2[67]'` | Task 14 |

- [ ] **Step 4: Baseline.** Run `make check`. Expected: PASS. Record the JS/Swift/build pass counts in the record.
- [ ] **Step 5: Commit** (no product code is written before this commit exists): `docs/superpowers/plans/2026-10-27-06-app2-data-reader.md`, `docs(m06): re-validate plan 06 against shipped TegelKit/TegelStore` + trailer.

---

### Task 1: Targets, UTTypes and entitlements

**Files:**
- Modify: `project.yml`. Add targets `data` (application) and `data.quicklook` (app-extension, embedded in `data`), following plan 01's naming, so the bundle ids are `com.tegelapps.data` and `com.tegelapps.data.quicklook` (D7) and the extension id is prefixed by the app id. Set `PRODUCT_NAME: Tegel Data` on `data` and `PRODUCT_NAME: DataQuickLook` on `data.quicklook`, so the `.appex` path below holds. Set `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` on `data` (plan 09 CR-10). Both compile `Apps/Data/Shared/`.
- Modify: `Makefile`. The `build` recipe gets a second line, the `markdown` line with `-scheme data`, into the same `-derivedDataPath build`, so `Tegel Data.app` always lands in `build/Build/Products/Debug/` (CR-P2-6).
- Create: `Apps/Data/App/{Info.plist,Data.entitlements,DataApp.swift}`, and `Apps/Data/App/AppIcon.icon/` from plan 09's D-5 Data pick (Manganese ground). Plan 09's icon guard in `make check` covers it.
- Create: `Apps/Data/QuickLook/{Info.plist,DataQuickLook.entitlements,PreviewProvider.swift}`. `PreviewProvider` is a stub that returns the file's first 2 KB as plain text.
- Create: `Apps/Data/Shared/{DataLabels.swift,Localizable.xcstrings}`, holding `enum DataLabels { static var all: [String: String] }`, the localised strings passed to JS.
- Create: `scripts/check-data-types.swift`, and `.github/workflows/types.yml` (Step 5; `ci.yml` only runs `make test-swift`/`build`, so the matrix needs its own dispatch-only workflow, K13).
- Modify: `Config/Debug.xcconfig` and `Config/Release.xcconfig`. Add `TG_POLAR_CHECKOUT_URL_DATA` and `TG_POLAR_BENEFIT_ID_DATA` (sandbox values beside plan 03's sandbox values, filled in Task 12). In `Release.xcconfig` they hold plan 03's placeholder token until Task 12 Step 3: `TG_POLAR_CHECKOUT_URL_DATA = https:/$()/REPLACE_IN_PLAN_05.invalid` and `TG_POLAR_BENEFIT_ID_DATA = REPLACE_IN_PLAN_05`. `release.sh` greps the whole file for that token, so it refuses a non-sandbox Data build until the production ids are in. The tokens live only on `m06-app2`, so App 1 releases from `main` are unaffected.
- Modify: `.env.example`. Add `POLAR_PRODUCT_ID_{DATA,BUNDLE}`, `POLAR_BENEFIT_ID_DATA`, `POLAR_CHECKOUT_URL_DATA`, `POLAR_SANDBOX_CHECKOUT_URL_{DATA,BUNDLE}`, `POLAR_CHECKOUT_URL_BUNDLE`, `POLAR_QA_LICENSE_KEY_DATA` (Task 12; emptied in Task 16). The `_MARKDOWN` keys already exist (plan 05), and MailerLite keys are plan 08's.

**Interfaces:**
- Consumes: `options.bundleIdPrefix: com.tegelapps` (D7), the TG* xcconfig variable names (Task 0 #9), D5 entitlements, and the G0 decision (Task 0 #1).
- Produces: bundle ids `com.tegelapps.data` and `com.tegelapps.data.quicklook`, product name `Tegel Data`; Info.plist keys `TGPolarAPIBase`, `TGPolarOrganizationID`, `TGPolarCheckoutURL`, `TGPolarPortalURL` (D16) plus `TGPolarBenefitID` (plan 03, D1); `SUFeedURL` = `https://downloads.tegelapps.com/data/appcast.xml` (layout per Task 0 #9), `SUPublicEDKey` (App 1's key), and plan 03's flags with App 1's values: `SUEnableInstallerLauncherService`, `SUEnableAutomaticChecks`, `SURequireSignedFeed`, `SUVerifyUpdateBeforeExtraction` = YES [F4, K7]; and `swift scripts/check-data-types.swift <DataQuickLook.appex/Contents/Info.plist>`, which exits 0 when every expectation holds.

Type declarations (App `Info.plist`, `UTImportedTypeDeclarations`, per DF3: these are formats the system doesn't declare):

| UTTypeIdentifier | Extensions | ConformsTo | MIME |
|---|---|---|---|
| `com.tegelapps.jsonl` | `jsonl`, `ndjson` | `public.text` (not `public.json`: a JSONL file isn't one JSON document) | `application/jsonl`, `application/x-ndjson` |
| `com.tegelapps.toml` | `toml` | `public.text` | `application/toml` |
| `com.tegelapps.dotenv` | `env` | `public.text` (not `public.plain-text`, so the system text previewer doesn't claim it [DF4, DF5]; verified by the Task 7 matrix) | none |

The system types are referenced by identifier and never redeclared (DF3): `public.json`, `public.yaml`, `public.comma-separated-values-text`, `public.tab-separated-values-text` (DF1), and `public.ndjson` (DF2).

- **`CFBundleDocumentTypes`:** one entry, role `Viewer`, `LSHandlerRank` `Alternate` (we never take over the default app). `LSItemContentTypes` holds the 4 DF1 types plus `public.ndjson`, `public.toml`, the 3 imported types, and `public.data`: files named exactly `.env` or `.envrc` are typed `public.data` (DF2), so without it Open With and a drop on the Dock icon never offer Tegel Data. The window routes those files by name (Task 5) and rejects binaries (Task 8). Task 8 Step 4 checks the rank's behaviour on a real `.env`.
- **`QLSupportedContentTypes`:** the same list plus **`public.data`** (the extension-less text path, DF5). `QLIsDataBasedPreview` follows G0.
- **Entitlements:**
  - App: exactly D5 (`app-sandbox`, `files.user-selected.read-write`, `files.bookmarks.app-scope`, `network.client`, and the Sparkle mach-lookup exception for `$(PRODUCT_BUNDLE_IDENTIFIER)-spks` and `-spki`).
  - Quick Look extension: `app-sandbox`, plus `network.client` if G0 kept it. **No** `temporary-exception.files.absolute-path.read-only` (CR-4).

- [ ] **Step 1: Write the failing check.** `scripts/check-data-types.swift` writes `x.json x.yaml x.yml x.csv x.tsv x.jsonl x.ndjson x.toml prod.env .env Dockerfile CHANGELOG` into a temp dir. For each file it reads `URLResourceValues.contentType` and asserts that the identifier is in its allowed set **and** in the appex's `QLSupportedContentTypes`:
  - `.jsonl` → {`com.tegelapps.jsonl`}; `.ndjson` → {`public.ndjson`, `com.tegelapps.jsonl`}; `.toml` → {`com.tegelapps.toml`, `public.toml`};
  - `prod.env` → {`com.tegelapps.dotenv`}; `.env`, `Dockerfile`, `CHANGELOG` → {`public.data`, `com.tegelapps.dotenv`}; the four system types → their DF1 identifier.

  It prints one `name → identifier ✓/✗` line per file and exits 1 on any ✗.
- [ ] **Step 2: Run it, expect FAIL.** `swift scripts/check-data-types.swift /dev/null`. Expected: FAIL with `x.jsonl → dyn.ah62d4rv4ge80y65tr30a ✗`.
- [ ] **Step 3: Implement the targets.** Add the two targets, plists, entitlements, the icon, the xcconfig keys and the Makefile `build` line listed above. `DataApp.swift` is an empty `WindowGroup` for now.
- [ ] **Step 4: Build, register, run, expect PASS.**

```bash
xcodegen generate && make build
xcodebuild -scheme data -showBuildSettings | grep -c 'PRODUCT_BUNDLE_IDENTIFIER = com.tegelapps.data$'
xcodebuild -target data.quicklook -showBuildSettings | grep -c 'PRODUCT_BUNDLE_IDENTIFIER = com.tegelapps.data.quicklook$'
BUILT=build/Build/Products/Debug
/usr/libexec/PlistBuddy -c 'Print CFBundleIconName' "$BUILT/Tegel Data.app/Contents/Info.plist"
for k in SUEnableAutomaticChecks SURequireSignedFeed SUVerifyUpdateBeforeExtraction; do /usr/libexec/PlistBuddy -c "Print $k" "$BUILT/Tegel Data.app/Contents/Info.plist"; done
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$BUILT/Tegel Data.app"
swift scripts/check-data-types.swift "$BUILT/Tegel Data.app/Contents/PlugIns/DataQuickLook.appex/Contents/Info.plist"
codesign -d --entitlements - --xml "$BUILT/Tegel Data.app/Contents/PlugIns/DataQuickLook.appex" | plutil -p - | grep -c absolute-path
```

Expected: the two bundle-id checks print `1` each (bundle ids are permanent after W14); `CFBundleIconName` prints `AppIcon`; the three Sparkle flags print `true` (after plan 07 G7, `SUEnableAutomaticChecks` prints the string `YES`, which also passes); every type line ✓, exit 0. The last command prints `0`.
- [ ] **Step 5: Remote type matrix (K13).** Write `.github/workflows/types.yml` the way plan 09 Task 11 Step 7 writes `design-shots.yml`: `workflow_dispatch` only, no inputs, no secrets, `permissions: { contents: read }`, and the same SHA-pinned `checkout`/`upload-artifact`/`download-artifact` and checksummed xcodegen lines.
  - **Job `build`** on `macos-26`: checkout; `sudo xcode-select -s /Applications/Xcode_26.3.app`; xcodegen; `make build`; `tar -cf app.tar -C build/Build/Products/Debug "Tegel Data.app"`, uploaded as `app`.
  - **Job `types`**, `needs: build`, matrix `os: [macos-15, macos-26]`. No `macos-14` leg: GitHub retired that label on Mon 2 Nov 2026 (master D11), and macOS 14 coverage is lease L2's reinstall slot only, which predates App 2. It never builds. It checks out, downloads `app`, runs `tar -xf app.tar` and `/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "Tegel Data.app"`, then `{ swift scripts/check-data-types.swift "Tegel Data.app/Contents/PlugIns/DataQuickLook.appex/Contents/Info.plist" && echo exit=0 || echo "exit=$?"; } > types.txt 2>&1`. The leg records the answer and doesn't gate on it. It uploads `types.txt` as `types-${{ matrix.os }}`.

  Run `make test-shell`. Expected: exit 0 (plan 01's pin guard). Commit Task 1 on the branch: `project.yml Makefile Apps/Data Config/Debug.xcconfig Config/Release.xcconfig .env.example scripts/check-data-types.swift .github/workflows/types.yml`, `feat(data): add Tegel Data app and Quick Look targets with UTType declarations` + trailer. Then land the workflow on `main`, because GitHub dispatches only workflows that exist there:

```bash
git switch main && git pull --ff-only && git checkout m06-app2 -- .github/workflows/types.yml
git commit -m "ci: UTType matrix workflow, dispatch only" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

  Before pushing, a cold code-review subagent reviews `git show HEAD` for SHA pins, `permissions: contents: read`, `workflow_dispatch` only, no secrets, the checksum before `unzip`, and no build step in `types`. Fix and amend until it finds no P0/P1. Then copy the reviewed file back to the branch, so the final merge neither conflicts nor restores the unreviewed copy, and run the matrix (needs the user's `gh auth login`):

```bash
git push origin main && git switch m06-app2
git checkout main -- .github/workflows/types.yml
git diff --cached --quiet || git commit -m "ci: types.yml as reviewed on main" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git diff --quiet main m06-app2 -- .github/workflows/types.yml; echo "differs=$?"   # differs=0: the copies are identical
git push -u origin m06-app2
OLD=$(gh run list --workflow types.yml --branch m06-app2 -L1 --json databaseId -q '.[0].databaseId')
gh workflow run types.yml --ref m06-app2
for i in $(seq 30); do ID=$(gh run list --workflow types.yml --branch m06-app2 -L1 --json databaseId -q '.[0].databaseId'); [ -n "$ID" ] && [ "$ID" != "$OLD" ] && break; sleep 2; done
[ "$ID" != "$OLD" ] && gh run watch "$ID" && gh run download "$ID" -D docs/reviews/m06-types
```

  `gh workflow run` creates the run asynchronously, so the loop waits up to 60 s for a run ID that differs from the one before the dispatch (plan 09 Task 11 Step 9's pattern).

  Expected: `differs=0`; `docs/reviews/m06-types/types-macos-{15,26}/types.txt`, each with one line per file and an `exit=` line. Record macOS 14 as `n/a: image retired`. Record each OS's actual identifiers in `docs/reviews/m06.md` § "UTType matrix", and macOS 27's per Task 14. The open questions are whether macOS 14 has `public.ndjson` and whether 26/27 declare `public.toml`.
- [ ] **Step 6: Commit:** `docs/reviews/m06.md docs/reviews/m06-types`, `docs(m06): UTType matrix on macOS 15 and 26` + trailer.

---

### Task 2: Tree views for JSON, YAML and TOML

**Files:**
- Modify: `Renderer/package.json` and `Renderer/bun.lock`, via `cd Renderer && bun add --exact --ignore-scripts js-yaml@5.5.0 smol-toml@1.9.1 papaparse@5.7.0` (versions per Task 0 #14).
- Modify: the third-party notices file (Task 0 #12). Add each library's licence text; BSD-3 requires the notice in binary distributions.
- Create: `Renderer/src/data/labels.js`, `Renderer/src/data/parse.js`, `Renderer/src/data/tree.js`.
- Test: `Renderer/test/data-tree.test.js`.

**Interfaces:**
- Consumes: the renderer's escape helper if it exports one (Task 0 #8); otherwise `tree.js` exports its own.
- Produces:

```js
// labels.js
export const DEFAULT_LABELS = { line: 'line', more: 'more', openInApp: 'Open in Tegel Data to expand',
  reveal: 'Reveal value', truncated: 'Showing the first {n} of {total}', parseError: 'Parse error',
  header: 'First row is a header', user: 'User', assistant: 'Assistant', tool: 'Tool', thinking: 'Thinking',
  hidden: '{n} internal records hidden', invalidJSONValidYAML: 'Invalid JSON (valid YAML)' };
// parse.js
export function parseDocument(text, format /* 'json'|'yaml'|'toml' */)
  // -> { ok: true, value } | { ok: false, error: { line?: number /* 1-based */, column?: number, message: string } }
export function sourceErrorHTML(text, error, context = 20) // -> string
// tree.js
export function escapeHTML(s) // -> string (only if the renderer has none)
export function treeHTML(value, { budget = 2000, path = '', labels = DEFAULT_LABELS } = {}) // -> { html: string, used: number }; partial options keep the other defaults
export function nodeAt(root, path /* '/a~1b/0', RFC 6901 escaping */) // -> any
export function summarize(value) // -> 'Object · 3 keys' | 'Array · 1,204 items' | scalar text
```

- [ ] **Step 1: Write the failing test.**

```js
import { test, expect } from 'bun:test';
import { parseDocument, sourceErrorHTML } from '../src/data/parse.js';
import { treeHTML, nodeAt } from '../src/data/tree.js';

test('json, yaml and toml parse to the same value', () => {
  const j = parseDocument('{"a":[1,"x"],"b":{"c":true}}', 'json').value;
  expect(parseDocument('a:\n  - 1\n  - x\nb:\n  c: true\n', 'yaml').value).toEqual(j);
  expect(parseDocument('a = [1, "x"]\n[b]\nc = true\n', 'toml').value).toEqual(j);
});
test('BOM and CRLF are accepted', () => {
  expect(parseDocument('\uFEFF{"a":1}\r\n', 'json').value).toEqual({ a: 1 });
  expect(parseDocument('\uFEFFa: 1\r\nb: 2\r\n', 'yaml').value).toEqual({ a: 1, b: 2 });
});
test('parse errors carry the 1-based line', () => {
  expect(parseDocument('{\n"a": 1,\n"b": 2\n"c": 3\n}', 'json').error.line).toBe(4);
  expect(parseDocument('a: 1\nb: 2\nc: 3\n  d: 4\n', 'yaml').error.line).toBe(4);
  expect(parseDocument('a = 1\nb = 2\nc = 3\nd = 4\ne = \n', 'toml').error.line).toBe(5);
  const html = sourceErrorHTML('x\n<b>bad</b>\n', { line: 2, message: 'm' });
  expect(html).toContain('<mark class="err">');
  expect(html).not.toContain('<b>');
});
test('hostile keys and values are escaped', () => {
  const { html } = treeHTML({ '<b>k</b>': '<img src=x onerror=alert(1)>', s: '<script>x</script>' });
  for (const bad of ['<img', '<b>', '<script']) expect(html).not.toContain(bad);
  expect(html).toContain('&lt;img');
});
test('__proto__ keys are shown but never pollute', () => {
  for (const [src, f] of [['{"__proto__":{"polluted":1}}', 'json'], ['__proto__:\n  polluted: 1\n', 'yaml'], ['__proto__.polluted = 1\n', 'toml']]) {
    const { html } = treeHTML(parseDocument(src, f).value);
    expect(html).toContain('__proto__');
    expect(({}).polluted).toBeUndefined();
  }
});
test('big integers stay exact or are marked', () => {
  const { html } = treeHTML(parseDocument('{"id":12345678901234567891}', 'json').value);
  expect(html.includes('12345678901234567891') || html.includes('≈')).toBe(true);
  expect(treeHTML(parseDocument('id = 9223372036854775807\n', 'toml').value).html).toContain('9223372036854775807');
  expect(parseDocument('{"n":1e20}', 'json').ok).toBe(true); // integer-valued and unsafe, but not digits: BigInt('1e20') would throw
});
test('budget bounds deep nesting and alias bombs; lazy nodes are addressable', () => {
  const deep = JSON.parse('['.repeat(3000) + ']'.repeat(3000));
  const d = treeHTML(deep, { budget: 2000 });
  expect(d.used).toBeLessThanOrEqual(2000);
  expect(d.html).toContain('data-lazy');
  const bomb = 'a: &a [x,x,x,x,x,x,x,x,x]\n' + 'bcdefgh'.split('').map((k, i) => `${k}: &${k} [${Array(9).fill('*' + 'abcdefgh'[i]).join(',')}]`).join('\n');
  const t0 = performance.now();
  expect(treeHTML(parseDocument(bomb, 'yaml').value, { budget: 2000 }).used).toBeLessThanOrEqual(2000);
  expect(performance.now() - t0).toBeLessThan(200);
  const big = { 'a/b': Array.from({ length: 5000 }, (_, i) => i) };
  expect(treeHTML(big).html).toContain('[0…999]');
  expect(nodeAt(big, '/a~1b/4321')).toBe(4321);
});
```

- [ ] **Step 2: Run it, expect FAIL.** `cd Renderer && bun test test/data-tree.test.js`. Expected: FAIL, `Cannot find module '../src/data/parse.js'`.
- [ ] **Step 3: Implement the three files.**
  - **`parseDocument`** strips a leading U+FEFF, then:
    - **json:** `JSON.parse` with a reviver that returns `BigInt(ctx.source)` for unsafe integers when `ctx?.source` exists and matches `/^-?\d+$/` [DF7]; any other unsafe number (`1e20`) stays a Number, which the tree marks with `≈`. JSC errors carry no position, so on failure (if `text.length ≤ 5_000_000`) it gets the line by running js-yaml `load` on the same text (YAML is a JSON superset). If YAML parses, the message is `labels.invalidJSONValidYAML` with no line.
    - **yaml:** js-yaml `load`; line = `e.mark.line + 1`. **toml:** smol-toml `parse(text, { integersAsBigInt: 'asNeeded' })`, default `unsafeKeyBehaviour: 'keep'` (show the file truthfully); line from `TomlError`.
  - **`treeHTML`:** objects and arrays become `<details data-path>` + `<summary>` (root open), recursing until `budget` nodes are used, then childless `<details data-lazy>`. Arrays over 1,000 items are chunked into `[0…999]` groups. Strings render as `<span class="s" dir="auto">`; unsafe integers get an `≈` prefix; BigInt renders exactly. Keys come from `Object.keys` with direct reads: never spread or `Object.assign` parsed values [DF8].
- [ ] **Step 4: Run it, expect PASS.** `cd Renderer && bun test test/data-tree.test.js`. Expected: 7 pass, 0 fail.
- [ ] **Step 5: Commit:** `Renderer/package.json Renderer/bun.lock Renderer/src/data/labels.js Renderer/src/data/parse.js Renderer/src/data/tree.js Renderer/test/data-tree.test.js <notices file>`, `feat(renderer): JSON/YAML/TOML tree with error lines and node budget` + trailer.

---

### Task 3: JSONL rows, CSV/TSV tables and big fixtures

**Files:**
- Create: `Renderer/src/data/jsonl.js`, `Renderer/src/data/table.js`.
- Test: `Renderer/test/data-rows.test.js`.
- Create: `Fixtures/data/generate.js`, and committed `Fixtures/data/{sample.json,sample.jsonl,sample.yaml,sample.toml,sample.csv,sample.tsv,quoted-newline.csv}`. `quoted-newline.csv` is a header plus 3 records; record 2 has a quoted CRLF newline and `""` escapes.
- Modify: `Makefile` (`fixtures` target runs `bun Fixtures/data/generate.js Fixtures/data`), `.gitignore` (`Fixtures/data/big-*`).

**Interfaces:**
- Consumes: `escapeHTML`, `treeHTML` and `DEFAULT_LABELS` (Task 2); `Papa.parse` (papaparse).
- Produces:

```js
// jsonl.js
export function parseJSONLLine(text) // -> { ok: true, value } | { ok: false, message }
export function jsonlRowHTML(lineNo, text, labels = DEFAULT_LABELS) // -> '<div class="row" data-line="N">…</div>'; bad -> class "row bad"
// table.js
export function splitRecords(text, format /* 'csv'|'tsv' */) // -> string[][]
export function detectHeader(rows /* string[][], first ≤ 51 */) // -> boolean
export function tableRowsHTML(rows, firstIndex, header /* string[] | null */) // -> string of <tr data-row="i">
```

`Fixtures/data/generate.js` writes two deterministic files and prints `records=` counts:
- `big-200mb.jsonl`: ≥ 200,000,000 bytes. Line `i` = `{"i":i,"msg":"row i","nested":{"tags":["a","b"],"n":i}}`, and every 100,000th line is `{bad json`.
- `big-1m.csv`: a header plus 1,000,000 records `i,name-i,i*0.5`, where every 10,000th record's name is `"multi\nline ""q"""`.

- [ ] **Step 1: Write the failing test.**

```js
import { test, expect } from 'bun:test';
import { jsonlRowHTML } from '../src/data/jsonl.js';
import { splitRecords, detectHeader, tableRowsHTML } from '../src/data/table.js';

test('bad JSONL lines are flagged with their line number; the rest still show', () => {
  const html = ['{"a":1}', '{bad', '{"b":"<script>x</script>"}'].map((l, i) => jsonlRowHTML(i + 1, l)).join('');
  expect((html.match(/class="row"/g) || []).length).toBe(2);
  expect(html).toContain('class="row bad" data-line="2"');
  expect(html).not.toContain('<script');
});
test('CSV keeps quoted newlines and doubled quotes; strips BOM; TSV splits on tabs only', () => {
  expect(splitRecords('\uFEFFa,b\r\n"x\r\ny","he said ""hi"""\r\n', 'csv')).toEqual([['a', 'b'], ['x\r\ny', 'he said "hi"']]);
  expect(splitRecords('a\tb,c\n1\t"2"', 'tsv')).toEqual([['a', 'b,c'], ['1', '"2"']]);
});
test('header detection', () => {
  expect(detectHeader([['id', 'price'], ['1', '9.5'], ['2', '3']])).toBe(true);
  expect(detectHeader([['1', '9.5'], ['2', '3'], ['3', '4']])).toBe(false);
  expect(detectHeader([['name', 'city'], ['Alice', 'Paris'], ['Bob', 'Oslo']])).toBe(true);
  expect(detectHeader([['a', 'a'], ['b', 'c']])).toBe(false);
  expect(detectHeader([['only', 'row']])).toBe(false);
});
test('table cells are escaped', () => {
  expect(tableRowsHTML([['<img src=x onerror=1>']], 0, null)).not.toContain('<img');
});
```

- [ ] **Step 2: Run it, expect FAIL.** `cd Renderer && bun test test/data-rows.test.js`. Expected: FAIL, `Cannot find module '../src/data/jsonl.js'`.
- [ ] **Step 3: Implement.**
  - **`splitRecords`:** CSV goes through `Papa.parse(text.replace(/^\uFEFF/, ''), { delimiter: ',' }).data`, with a trailing empty record dropped. TSV is `line.split('\t')` with no quoting (IANA TSV).
  - **`detectHeader`:** fewer than 2 rows → `false`. Otherwise a vote in the style of Python's `csv.Sniffer.has_header` over rows 2–51: a column that is all numeric gives +1 if the header cell is non-numeric, −1 if numeric; a column of constant-length strings gives +1 if the header length differs, −1 if equal. Header if the vote is > 0. At 0 votes, header if the first-row cells are all non-empty, unique and non-numeric, and none reappears in its own column.
  - **Row HTML:** the JSONL preview is a single line, escaped and cut to 300 chars. Bad rows show `labels.line N`, the message and the escaped raw text (≤ 300 chars).
- [ ] **Step 4: Run it, expect PASS.** `cd Renderer && bun test test/data-rows.test.js`. Expected: 4 pass. Then run `make fixtures && ls -l Fixtures/data/big-*`. Expected: `big-200mb.jsonl` ≥ 200000000 bytes, and the script prints `records=1000000` for the CSV.
- [ ] **Step 5: Commit:** `Renderer/src/data/jsonl.js Renderer/src/data/table.js Renderer/test/data-rows.test.js Fixtures/data Makefile .gitignore`, `feat(renderer): JSONL rows, CSV/TSV tables, header detection, big fixtures` + trailer.

---

### Task 4: `.env` parsing and secret masking

**Files:**
- Create: `Renderer/src/data/dotenv.js`, `Fixtures/data/sample.env` (synthetic values only, e.g. `not-a-real-secret-1`).
- Modify: `Renderer/src/data/tree.js`, `Renderer/src/data/table.js`, `Renderer/src/data/jsonl.js` (the `maskNames` option).
- Test: `Renderer/test/data-dotenv.test.js`.

**Interfaces:**
- Consumes: `escapeHTML`, `DEFAULT_LABELS` (Task 2).
- Produces:

```js
export function isSecretName(name)
  // -> boolean, any case: name contains KEY, TOKEN, SECRET, PASSWORD, PASSWD or CREDENTIAL, or has AUTH or AUTHORIZATION as a
  //    whole segment between start, end, '_', '-' or '.' (`auth`, `HTTP_AUTH`, `basic-auth`; `author` stays visible)
// tree.js, table.js, jsonl.js gain an option, default false, that Quick Look turns on (Task 6):
//   treeHTML(value, { …, maskNames })         -> the value of a key passing isSecretName renders as '••••••••', with no children
//   tableRowsHTML(rows, first, header, { maskNames, nameRow = header }) -> every cell in a column whose nameRow cell passes
//                                                        isSecretName renders as '••••••••'; Quick Look passes nameRow = header ?? records[0],
//                                                        so a header the vote rejects (`user,password` over `root,p@ssw0rd`, vote −2) still masks
//   jsonlRowHTML(lineNo, text, labels, { maskNames }) -> the preview is JSON.stringify(value, replacer) instead of the raw line;
//                                                        the replacer returns '••••••••' for a secret-named key and v.toString() for a BigInt
export function parseDotenv(text)
  // -> { entries: [{ line, key, value, exported: boolean, commented: boolean }], comments: [{ line, text }], errors: [{ line, message }] }
export function envHTML(parsed, labels = DEFAULT_LABELS)
  // -> string. Values NEVER appear. Each value is <button class="secret" data-i="k" aria-label="…">••••••••</button> (always 8 bullets)
export function maskSecrets(text, { wholeFile = false, structured = false } = {})
  // -> text with secrets replaced by '••••••••' (K12). Always:
  //    PEM private-key bodies (BEGIN … PRIVATE KEY … END; each non-space run of the body is replaced, newlines and indentation kept);
  //    the password in scheme://user:password@host (.git-credentials lines, URLs in any text);
  //    token shapes sk-…, sk_live_…, rk_live_…, gh[pousr]_…, github_pat_…, glpat-…, xox[abpr]-…, AKIA…, AIza…, npm_…, hvs.…, hf_…,
  //    and a 40-char [A-Za-z0-9/+] run on the same line as an AKIA id (the secret of an AWS key pair).
  //    Unless structured: the value of NAME=value / NAME: value when isSecretName(NAME).
  //    structured (Quick Look's JSON/JSONL/YAML/TOML/CSV/TSV/.env input) skips only that pass: an unquoted replacement can
  //    break a parser, while the passes above replace key and token characters only, so the file still parses. The views
  //    apply the same name rule after parsing instead (maskNames above).
  //    wholeFile (secret dotfiles, Task 5 DataFile.secretFile): then every non-comment line keeps only its first token
  //    (`machine`, `//registry/:_authToken`, `aws_secret_access_key`, the masked credential URL, …). The list is explicit, not a scanner.
```

Parsing rules:
- Strip a BOM; CRLF and LF both end a line (and become `\n` inside multiline values). Optional `export ` prefix; KEY matches `[A-Za-z_][A-Za-z0-9_.-]*`, then `=` with optional spaces.
- `'…'` is literal; `"…"` may span lines, with `\n \t \" \\` escapes; a backtick value is literal and may span lines; an unquoted value is trimmed and ` #…` ends it.
- A `#` line whose remainder is an assignment becomes an entry with `commented: true` (masked); any other `#` line is a comment. An unterminated quote is an error at its opening line, and parsing resumes on the next line. Error messages never include the raw line.

- [ ] **Step 1: Write the failing test.**

```js
import { test, expect } from 'bun:test';
import { parseDotenv, envHTML, maskSecrets } from '../src/data/dotenv.js';
import { parseDocument } from '../src/data/parse.js';
import { treeHTML } from '../src/data/tree.js';
import { tableRowsHTML, detectHeader } from '../src/data/table.js';
import { jsonlRowHTML } from '../src/data/jsonl.js';
const SRC = ['# comment line', 'export API_KEY=sk-test-AAAA1111', "SINGLE='lit $HOME'", 'DOUBLE="line1\\nline2"',
  'MULTI="first', 'second"', '# OLD_TOKEN=tok-old-BBBB2222', 'INLINE=val-CCCC3333 # note', 'not a valid line sk-zzz', 'EMPTY='].join('\r\n');

test('parses export, quotes, multiline, commented assignments; flags bad lines', () => {
  const p = parseDotenv('\uFEFF' + SRC);
  expect(p.entries.map(e => e.key)).toEqual(['API_KEY', 'SINGLE', 'DOUBLE', 'MULTI', 'OLD_TOKEN', 'INLINE', 'EMPTY']);
  const v = Object.fromEntries(p.entries.map(e => [e.key, e]));
  expect(v.MULTI.value).toBe('first\nsecond');
  expect(v.DOUBLE.value).toBe('line1\nline2');
  expect(v.SINGLE.value).toBe('lit $HOME');
  expect(v.INLINE.value).toBe('val-CCCC3333');
  expect(v.API_KEY.exported).toBe(true);
  expect(v.OLD_TOKEN.commented).toBe(true);
  expect(p.errors.map(e => e.line)).toEqual([9]);
});
test('no value, value length or raw bad line ever reaches the HTML', () => {
  const html = envHTML(parseDotenv(SRC));
  for (const s of ['sk-test', 'AAAA1111', 'lit $HOME', 'line1', 'second', 'tok-old', 'CCCC3333', 'sk-zzz']) expect(html).not.toContain(s);
  expect(html.match(/class="secret"/g).length).toBe(7);
  expect(new Set(html.match(/>•+</g)).size).toBe(1);
  expect(html).toContain('API_KEY');
});
test('unterminated quote reports its line and parsing continues', () => {
  const p = parseDotenv('A="open\nB=2\n');
  expect(p.errors.map(e => e.line)).toEqual([1]);
  expect(p.entries.map(e => e.key)).toEqual(['B']);
});
test('hostile comments are escaped; secrets in comments are masked', () => {
  expect(envHTML(parseDotenv('# <img src=x onerror=1>\nK=v'))).not.toContain('<img');
  expect(envHTML(parseDotenv('# prod: sk-' + 'p'.repeat(40) + '\nK=v'))).not.toContain('pppppppp');
});
test('secrets are masked: PEM bodies, token shapes, secret-named values, whole secret files', () => {
  // built by concatenation so no repo file holds a real-looking secret (Task 9 scan, GitHub push protection)
  const pem = '-----BEGIN OPENSSH ' + 'PRIVATE KEY-----\nZmFrZS1ib2R5LWxpbmU=\n-----END OPENSSH ' + 'PRIVATE KEY-----';
  const toks = ['sk-' + 'a'.repeat(40), 'gh' + 'p_' + 'B'.repeat(36), 'AKIA' + 'C'.repeat(16), 'xox' + 'b-' + '1'.repeat(24)];
  const out = maskSecrets(`${pem}\nnote ${toks.join(' ')}\nDB_PASSWORD=hunter-x\nname=visible`);
  for (const s of ['ZmFrZS1ib2R5', ...toks, 'hunter-x']) expect(out).not.toContain(s);
  expect(out).toContain('name=visible');
  const netrc = maskSecrets('machine example.com login demo password not-a-real-secret-9', { wholeFile: true });
  expect(netrc).toContain('machine'); expect(netrc).not.toContain('not-a-real-secret-9');
});
test('credential URLs and newer token prefixes are masked', () => {
  const gc = maskSecrets('https://demo:' + 'not-a-real-secret-7' + '@example.com', { wholeFile: true }); // .git-credentials line
  expect(gc).toContain('https://demo:'); expect(gc).toContain('@example.com'); expect(gc).not.toContain('not-a-real-secret-7');
  const toks = ['github' + '_pat_' + 'D'.repeat(40), 'gl' + 'pat-' + 'E'.repeat(20), 'AKIA' + 'F'.repeat(16) + ' ' + 'g/H+'.repeat(10)];
  const out = maskSecrets(toks.join('\n'));
  for (const s of ['DDDDDDDD', 'EEEEEEEE', 'FFFFFFFF', 'g/H+g/H+']) expect(out).not.toContain(s);
});
test('structured masking keeps the file parseable and its line numbers', () => {
  const pem = '-----BEGIN RSA ' + 'PRIVATE KEY-----\nZmFrZS1ib2R5LWxpbmU=\nZmFrZS1ib2R5LWxpbmUy\n-----END RSA ' + 'PRIVATE KEY-----';
  const yaml = 'private_key: |\n  ' + pem.replace(/\n/g, '\n  ') + '\nmax_keys: 5\n';
  const masked = maskSecrets(yaml, { structured: true });
  expect(masked.split('\n').length).toBe(yaml.split('\n').length);
  const v = parseDocument(masked, 'yaml').value;
  expect(v.max_keys).toBe(5); expect(v.private_key).not.toContain('ZmFrZS1ib2R5');
  expect(parseDocument(maskSecrets(JSON.stringify({ private_key: pem }), { structured: true }), 'json').ok).toBe(true);
});
test.each([['stripe sk_live_', 'sk' + '_live_' + 'a'.repeat(24)], ['stripe rk_live_', 'rk' + '_live_' + 'b'.repeat(24)],
  ['google AIza', 'AI' + 'za' + 'C'.repeat(35)], ['npm_', 'np' + 'm_' + 'd'.repeat(36)], ['vault hvs.', 'hv' + 's.' + 'e'.repeat(24)],
  ['hugging face hf_', 'h' + 'f_' + 'F'.repeat(34)]])('token shape %s is masked in any file', (_, tok) => {
  expect(maskSecrets(`note ${tok}`, { structured: true })).not.toContain(tok);
});
test('secret-named keys and columns are masked in tree, row and table views', () => {
  const adc = '{"client_id":"visible-id","client_secret":"cs-not-real-1","refresh_token":"rt-not-real-2","auth":"YXV0aC1ub3QtcmVhbA==","author":"Jane"}';
  const tree = treeHTML(parseDocument(adc, 'json').value, { maskNames: true }).html;
  for (const s of ['cs-not-real-1', 'rt-not-real-2', 'YXV0aC1ub3QtcmVhbA==']) expect(tree).not.toContain(s);
  for (const s of ['client_secret', 'visible-id', 'Jane']) expect(tree).toContain(s);
  expect(jsonlRowHTML(1, adc, undefined, { maskNames: true })).not.toContain('cs-not-real-1');
  const table = tableRowsHTML([['demo', 'pw-not-real-3']], 1, ['user', 'POSTGRES_PASSWORD'], { maskNames: true });
  expect(table).not.toContain('pw-not-real-3'); expect(table).toContain('demo');
  const rows = [['user', 'password'], ['root', 'pw-not-r']];   // equal lengths per column: vote −1 −1 = −2
  expect(detectHeader(rows)).toBe(false);
  const noHeader = tableRowsHTML(rows, 0, null, { maskNames: true, nameRow: rows[0] });
  expect(noHeader).not.toContain('pw-not-r'); expect(noHeader).toContain('root');
});
```

- [ ] **Step 2: Run it, expect FAIL.** `cd Renderer && bun test test/data-dotenv.test.js`. Expected: FAIL, `Cannot find module '../src/data/dotenv.js'`.
- [ ] **Step 3: Implement `parseDotenv`, `envHTML` and `maskSecrets`.** A single line-cursor loop that applies the rules above. `envHTML` emits keys, comments (through `maskSecrets` before escaping) and error rows from `parsed`, and only the index `k` for each value. `maskSecrets` is four regex passes in the interface's order (PEM body, credential URL, token shapes, then the secret-named assignment unless `structured`) plus the `wholeFile` line rule. `isSecretName` is one case-insensitive regex, shared by that pass and the three `maskNames` options.
- [ ] **Step 4: Run it, expect PASS.** `cd Renderer && bun test test/data-dotenv.test.js`. Expected: 14 pass.
- [ ] **Step 5: Watch the two credential rules fail.** One at a time, then restore each and re-run to 14 pass:
  - delete the credential-URL pass. Expected: FAIL in `credential URLs and newer token prefixes…`, the output contains `not-a-real-secret-7`;
  - delete `github_pat_` from the token shapes. Expected: FAIL in the same test, the output contains `DDDDDDDD`.
- [ ] **Step 6: Commit:** `Renderer/src/data/dotenv.js Renderer/src/data/tree.js Renderer/src/data/table.js Renderer/src/data/jsonl.js Renderer/test/data-dotenv.test.js Fixtures/data/sample.env`, `feat(renderer): .env parser and secret masking, values kept out of the HTML` + trailer.

---

### Task 5: File access in TegelKit (`DataFormat`, `DataFile`, `RecordIndex`)

**Files:**
- Create: `Packages/TegelKit/Sources/TegelKit/DataFile.swift`.
- Test: `Packages/TegelKit/Tests/TegelKitTests/DataFileTests.swift` (XCTest, or whatever Task 0 #8 found).

**Interfaces:**
- Consumes: `TextFileLoader.load(_:maxBytes:) -> LoadedText` (UTF-8 → BOM UTF-16 → Windows-1252) and `TextFileLoader.decode(_:maxBytes:) -> LoadedText` (plan 01 Task 4, the same decoding over bytes in memory).
- Produces (CR-3):

```swift
public enum DataFormat: String, Sendable, CaseIterable {
    case json, jsonl, yaml, toml, csv, tsv, dotenv, text, transcript
    public init?(filename: String)   // case-insensitive: json geojson | jsonl ndjson | yaml yml | toml | csv | tsv tab
                                     // dotenv: ".env", ".env.*", "*.env", ".envrc"; anything else -> nil
}
public enum DataFileError: Error, Equatable { case notRegularFile, binary }
public struct DataFile: Sendable {
    public let text: String; public let format: DataFormat; public let truncated: Bool; public let byteCount: Int
    public let secretFile: Bool                      // = isSecret(filename:); Quick Look masks the whole file (K12)
    public static func load(_ url: URL, maxBytes: Int) throws -> DataFile
    // regular file only; UTF-16 BOM -> text; else a NUL byte in the first 8 KiB -> .binary;
    // format = DataFormat(filename:) ?? .text; truncated jsonl/csv/tsv are cut at the last newline
    public static func isSecret(filename: String) -> Bool
    // case-insensitive: .netrc _netrc .npmrc .pypirc .git-credentials credentials id_rsa id_ecdsa id_ed25519 (never *.pub)
}
public enum RecordIndexError: Error, Equatable { case utf16, truncated }
public final class RecordIndex: Sendable {
    public init(url: URL, quoteAware: Bool) throws   // FileHandle chunk reads, offsets only; UTF-8 BOM skipped; UTF-16 BOM -> throws .utf16
    public var count: Int { get }
    public let quoteRunaway: Bool                    // a quoted record passed 1 MB, or EOF was reached inside quotes -> rebuilt line-based
    public func records(in range: Range<Int>) throws -> [String]
    // range clamped to 0..<count; trailing "\r" stripped; each record decoded by TextFileLoader.decode(bytes, maxBytes: bytes.count).text (so a Windows-1252
    // CSV shows `é`, as in Quick Look), never lossy UTF-8. Opens a FileHandle, seeks to the first offset and reads
    // up to the end offset; if the file is now shorter than that end offset -> throws .truncated (never a mapped read, so no SIGBUS)
}
```

- [ ] **Step 1: Write the failing tests.** Each one writes into `FileManager.default.temporaryDirectory`.
  - **`testRouting`:** `.env`, `.env.local`, `prod.env` and `.envrc` give `.dotenv`; `x.NDJSON` gives `.jsonl`; `Dockerfile` gives `nil`. `DataFile.isSecret` is true for `.netrc`, `.npmrc`, `credentials`, `id_rsa` and `ID_ED25519`, and false for `id_rsa.pub`, `Dockerfile` and `.gitignore`.
  - **`testBinaryRejected`:** the bytes `[0x41, 0x00, 0x42]` throw `.binary`.
  - **`testUTF16LoadsAsText`:** a UTF-16LE BOM `{"a":1}` loads with format `.json` and text `{"a":1}`.
  - **`testFIFORejected`:** `mkfifo(path, 0o600)` throws `.notRegularFile` within 0.5 s, with no hang.
  - **`testReadsPrefixOnly`:** 50 MB of `"x\n"` loaded with `maxBytes: 2_000_000` finishes in < 0.5 s, with `truncated == true` and the text ending in `"\n"`.
  - **`testLinesCRLFAndBOM`:** `"\u{FEFF}a\r\nb\nc\n"` gives `count == 3` and `records(in: 0..<3) == ["a","b","c"]`.
  - **`testQuotedNewlineCSV`:** `Fixtures/data/quoted-newline.csv` with `quoteAware: true` gives `count == 4`, and `records(in: 2..<3)[0]` contains `"\n"`.
  - **`testUnbalancedQuoteFallsBackToLines`:** `"a,b\n\"open,1\n"` followed by 20,000 lines of `x,y` (about 80 KB, so this is the EOF-inside-quotes rule, not the 1 MB one) gives `quoteRunaway == true` and `count == 20_002`.
  - **`testStrayQuoteInUnquotedField`:** `"id,size\n1,12\" pipe\n2,3\" pipe\n3,x\n"` with `quoteAware: true` gives `count == 4`, `quoteRunaway == false` and `records(in: 1..<2) == ["1,12\" pipe"]` (a quote that toggles anywhere merges rows 1 and 2).
  - **`testWindows1252Record`:** the bytes of `"café,1\nx,2\n"` in Windows-1252 (`63 61 66 E9 2C 31 0A 78 2C 32 0A`) with `quoteAware: true` give `records(in: 0..<1) == ["café,1"]`.
  - **`testUTF16BOMThrows`:** bytes `FF FE 61 00` throw `RecordIndexError.utf16`.
  - **`testRangeClamped`:** on a 3-record file, `try records(in: 1..<10).count == 2` and `try records(in: 5..<9) == []`.
  - **`testTruncatedFileThrowsNotCrash`** (K12): index a 50 MB temp file of `"{\"i\":N}\n"` lines, then truncate it in place to 1 KB (`FileHandle(forWritingTo:).truncate(atOffset: 1024)` on the test's own temp file). `records(in: 1000..<1001)` throws `RecordIndexError.truncated`, and the test process is still alive.
  - **`testBigFixtures`:** `XCTSkip` if `Fixtures/data/big-1m.csv` is missing. Otherwise the CSV gives `count == 1_000_001` in < 3 s and `big-200mb.jsonl` gives `count == <records printed by generate.js>` in < 4 s. Record both timings on the build Mac (Intel).
- [ ] **Step 2: Run them, expect FAIL.** `swift test --package-path Packages/TegelKit --filter DataFileTests`. Expected: FAIL to compile, `cannot find 'DataFile' in scope`.
- [ ] **Step 3: Implement.**
  - `DataFile.load`: check `resourceValues(forKeys: [.isRegularFileKey])` first, then read a prefix through `TextFileLoader.load(url, maxBytes:)`. If Task 0 #2 found that it reads the whole file, read the prefix with `FileHandle.read(upToCount:)` instead. `secretFile = isSecret(filename: url.lastPathComponent)`.
  - `RecordIndex`: read the file in 4 MiB chunks with `FileHandle.read(upToCount:)`, never `Data(contentsOf:options: .alwaysMapped)`. In line mode, `memchr` for `\n`. In quote mode, an RFC 4180 byte loop: a `"` opens a quoted field only as the field's first byte (record start or after `,`); inside a quoted field `""` is an escaped quote and a lone `"` closes it (a closing quote that waits on the next byte carries across the chunk boundary); a `"` anywhere in an unquoted field is literal. EOF inside quotes rebuilds line-based. Store record starts in `[Int]` plus the end offset.
  - `records(in:)`: `FileHandle(forReadingFrom:)`, `fstat` size check against the range's end offset (throw `.truncated` if short), then `seek(toOffset:)` + `read(upToCount:)`, split at the stored offsets and decode each record with `TextFileLoader.decode`.
- [ ] **Step 4: Run them, expect PASS.** `make fixtures && swift test --package-path Packages/TegelKit --filter DataFileTests`. Expected: 14 pass, 0 skipped.
- [ ] **Step 5: Watch three guards fail.** One at a time, then restore each and re-run to PASS:
  - comment out the size check in `records(in:)`, re-run `--filter testTruncatedFileThrowsNotCrash`. Expected: FAIL (no error thrown: the short read traps on the slice or returns wrong records);
  - make every `"` toggle quote mode, re-run `--filter testStrayQuoteInUnquotedField`. Expected: FAIL, `count == 3`;
  - decode records with `String(decoding:as: UTF8.self)`, re-run `--filter testWindows1252Record`. Expected: FAIL, `caf\u{FFFD},1`.
- [ ] **Step 6: Commit:** `Packages/TegelKit/Sources/TegelKit/DataFile.swift Packages/TegelKit/Tests/TegelKitTests/DataFileTests.swift`, `feat(tegelkit): DataFormat routing, capped DataFile loading, offset-only RecordIndex` + trailer.

---

### Task 6: DOM view, Swift bridge and WebKit tests

**Files:**
- Create: `Renderer/src/data/view.js` and `Renderer/src/css/data.css` (tokens from DESIGN.md §7).
- Modify: `Renderer/build.js` (a new entry, `src/data/view.js` → `data.js`, and copy `data.css`); `Renderer/src/data/labels.js` (adds `changed: 'The file changed on disk. Reloading…'`).
- Modify: `Renderer/src/page.js`. Add stubs `window.tegel.renderData`, `openPaged` and `transcriptMarkdown`; they load `data.js` once through the Mermaid script loader (Task 0 #8). The CSP doesn't change.
- Create: `Packages/TegelKit/Sources/TegelKit/DataRender.swift`.
- Modify: `Packages/TegelKit/Sources/TegelKit/RendererWebView.swift` (plan 01's). A fresh renderer loads nothing yet (plan 01), and only `render` loads the page. Extract `render` steps 1–3 (cancel a pending render; install the continuation and start the `timeout` deadline; if the page is dirty, install the rule list, (re)load `indexURL` and await `didFinish`) into `func preparePage() async throws` (internal), which `render` calls first. The deadline stays in it, so a stalled or failed load in `renderData`/`renderPaged` ends with `RendererError.timeout` or the load error, as in plan 01's `testFailedPageLoadThrowsWithinTheTimeout`; add `testDataRenderFailedLoadThrowsWithinTheTimeout` (same setup, calling `renderData`). Markdown's behaviour doesn't change.
- Create: `Fixtures/data/hostile.{json,jsonl,yaml,toml,csv,env}`. Each embeds `<img src=x onerror="window.__pwned=1">`, `<script>window.__pwned=1</script>`, `"><svg onload=window.__pwned=1>` and `javascript:window.__pwned=1` in keys and values. `hostile.env` also carries them in a `#` comment line: comments are the only `.env` text that reaches the page (bad keys become error rows that never echo, and values are masked).
- Regenerate: `Packages/TegelKit/Sources/TegelKit/Resources/Renderer/` (`make renderer`).
- Test: `Packages/TegelKit/Tests/TegelKitTests/WebView/DataRenderTests.swift` (WebKit suites live under `WebView/`, plan 01 Task 5).

**Interfaces:**
- Consumes: Tasks 2–5 (including `maskSecrets`, `maskNames` and `DataFile.secretFile`); `RendererWebView.webView`, `RenderOptions`, and the page's sanitise function.
- Produces (CR-3):

```js
window.tegel.renderData(text, { format, mode, theme, labels, truncated, secretFile, reveal, showHidden }) // -> Promise<{ ms, records, errors: [{ line, message }] }>
//   reveal and showHidden reach transcriptHTML (Task 10's toggles); both are ignored unless mode === 'window'
window.tegel.openPaged({ format, count, quoteRunaway, mode, theme, labels }) // -> Promise<same>
//   pulls records with: await webkit.messageHandlers.tegelData.postMessage({ from, count }) -> string[] (rejects on .truncated)
window.tegel.transcriptMarkdown({ reveal }) // -> string (Task 9 fills it)
```

```swift
public struct DataIssue: Sendable, Hashable, Decodable { public let line: Int; public let message: String }
public struct DataRenderResult: Sendable, Decodable { public let ms: Double; public let records: Int; public let errors: [DataIssue] }
extension RendererWebView {
    public func renderData(_ text: String, format: DataFormat, options: RenderOptions,
                           labels: [String: String] = [:], truncated: Bool = false,
                           secretFile: Bool = false, reveal: Bool = false,
                           showHidden: Bool = false) async throws -> DataRenderResult
    public func renderPaged(_ index: RecordIndex, format: DataFormat, options: RenderOptions,
                            labels: [String: String] = [:]) async throws -> DataRenderResult
}
```

View rules:
- **Every insertion** goes through the page's sanitise function. CSV/TSV run `detectHeader` on the first 51 records (a header checkbox overrides it). A JSONL row click renders its `treeHTML` in a detail pane; `details[data-lazy]` is filled on `toggle` from `nodeAt`.
- **Paged window list, scaled virtual scroller** (K12): 22 px rows, 200 rows of overscan, 500-record pages, ≤ 20 cached pages. The spacer is `min(count × 22, MAX_SPACER_PX)` with `MAX_SPACER_PX = 16_000_000`, below WebKit's 33,554,432 px layout cap (2^31 / 64). The first visible record is `round(scrollTop / (spacer − viewport) × (count − visibleRows))`, and rows are positioned relative to the viewport, not at `i × 22`, so `big-200mb.jsonl`'s 2,747,748 records all stay reachable. *ponytail: no "Go to line" field; add one if users ask to jump to a line number.*
- **A changed file:** when a `tegelData` request is rejected (`.truncated`), the list keeps the rows it has and shows `labels.changed`; the app's `FileWatcher` rebuilds the index (Task 8).
- **`.env` reveal:** in `mode === 'window'`, clicking `.secret` toggles that one value from the in-memory entries. In `quicklook` mode there's no handler and the values are dropped after render.
- **Quick Look secrets** (K12): in `quicklook` mode, `renderData` masks the input once, before any parser or view sees it, so every format and view (tree, rows, table, `.env`, text, error source) gets it: `text = maskSecrets(text, { wholeFile: secretFile, structured: format !== 'text' })`. Because structured input skips the name pass, every tree, row and table call in `quicklook` mode (lazy fills included) passes `maskNames: true` (Task 4), table calls with `nameRow: header ?? records[0]`, and an error view runs its source through `maskSecrets(text)` again without `structured` (it shows the source and never parses it). There is no reveal.
- **Quick Look caps:** in `quicklook` mode, JSONL/CSV/TSV render statically, capped at 500 records or 1,000 rows, with a `labels.truncated` banner (also shown for `truncated: true`).
- **Swift side:** `renderData` and `renderPaged` first `try await preparePage()`, so they work on a fresh renderer. `renderData` then uses `webView.callAsyncJavaScript(… arguments:, contentWorld: .page)`. `renderPaged` swaps in a `WKScriptMessageHandlerWithReply` named `tegelData` (macOS 11+) that clamps `from ≥ 0` and `count ≤ 2000`, and replies with an error string when `records(in:)` throws.

- [ ] **Step 1: Write the failing tests** (`@MainActor final class DataRenderTests: XCTestCase`, real WKWebView).
  - **`testHostileStringsNeverExecute`:** for each `hostile.*`, `DataFile.load(url, maxBytes: 2_000_000)` then `renderData` (mode `.window`). Assert `evaluateJavaScript("String(window.__pwned)") == "undefined"`, `document.querySelectorAll('#doc img,#doc script,#doc svg,#doc iframe,#doc a[href^=javascript]').length == 0`, and the `#doc` innerText contains `<script>` (so the container exists and the empty-query assertions aren't vacuous).
  - **`testDotenvMaskedUntilClicked`:** render `sample.env` in `.window`. `documentElement.outerHTML` contains none of its values; after `document.querySelector('.secret').click()`, exactly the first value appears and the second doesn't.
  - **`testDotenvQuickLookNeverReveals`:** the same in `.quicklook`. After the click, no value appears.
  - **`testQuickLookMasksSecretFiles`** (K12): write a temp `.netrc` (`machine example.com login demo password not-a-real-secret-9`), a temp `id_rsa` whose PEM header and footer are built by concatenation around the body `ZmFrZS1ib2R5LWxpbmU=`, and a temp `key.json` holding that PEM as `{"private_key": "<PEM, newlines as \n>", "client_secret": "not-a-real-secret-5"}`. For each, `DataFile.load`, then `renderData` in mode `.quicklook` with `secretFile: file.secretFile`. `documentElement.outerHTML` contains none of `not-a-real-secret-9`, `ZmFrZS1ib2R5` and `not-a-real-secret-5`, and does contain the file's own non-secret sentinel: `machine` (`.netrc`), `-----BEGIN` (`id_rsa`: the header's first token, which the whole-file rule keeps) and `client_secret` (`key.json`'s key). For `key.json`, `document.querySelector('#doc details')` is non-null and `mark.err` is null (the tree rendered, masked, not an error view). Last, a temp `creds.csv` of `login,password` and `zq-71,pw-not-r`, whose header the vote rejects (equal lengths per column, −2): the HTML lacks `pw-not-r` and contains `zq-71`.
  - **`testYAMLErrorLine`:** the bad YAML from Task 2 gives `errors.first?.line == 4`, and `document.querySelector('mark.err') != null`.
  - **`testPaged1MRows`:** `XCTSkip` without the fixture. `renderPaged(RecordIndex(url: big-1m.csv, quoteAware: true), format: .csv, …)` returns `records == 1_000_001` in < 2 s (timed after the index is built). After `document.scrollingElement.scrollTop = 1e9` and 500 ms, the last visible row's first cell is `"999999"`.
  - **`testPaged200MBLastRecordReachable`** (K12): `XCTSkip` without the fixture. `renderPaged` over `RecordIndex(url: big-200mb.jsonl, quoteAware: false)`. After `scrollTop = 1e9` and 500 ms, the last visible row's `data-line` equals `index.count`. After scrolling to `1_600_000 / index.count` of the maximum `scrollTop`, a `.row.bad` is visible (the plain-height list stops near record 1,525,000).
- [ ] **Step 2: Run them, expect FAIL.** `swift test --package-path Packages/TegelKit --filter DataRenderTests`. Expected: FAIL to compile, `value of type 'RendererWebView' has no member 'renderData'`. If plan 01 took Branch B, run every `--filter DataRenderTests…` in this task as `xcodebuild test -project Tegel.xcodeproj -scheme TegelKitHostTests -derivedDataPath build -only-testing:TegelKitHostTests/DataRenderTests[/<test>]` instead (plan 02's rule).
- [ ] **Step 3: Implement** `view.js`, `data.css`, the `build.js` entry, the label, the `page.js` stubs, `preparePage()` and `DataRender.swift`. Then run `make renderer` to regenerate the committed bundle, and re-run plan 01's `RendererWebViewTests` (same runner) to confirm the extraction left `render` unchanged.
- [ ] **Step 4: Run them, expect PASS.** `make fixtures && swift test --package-path Packages/TegelKit --filter DataRenderTests && (cd Renderer && bun test)`. Expected: 7 pass, and the existing JS suite still passes (CSP and Markdown tests unchanged).
- [ ] **Step 5: Watch the K12 guards and the page preparation fail.** One at a time, then restore each and re-run to PASS:
  - set `MAX_SPACER_PX = Infinity` in `view.js`, `make renderer`, run `--filter testPaged200MBLastRecordReachable`. Expected: FAIL, the last visible `data-line` is about 1,525,000;
  - replace the `maskSecrets(…)` call in `view.js` with its `text` argument, `make renderer`, run `--filter testQuickLookMasksSecretFiles`. Expected: FAIL, `not-a-real-secret-9` is in the HTML;
  - pass `maskNames: false` in `quicklook` mode, `make renderer`, run `--filter testQuickLookMasksSecretFiles`. Expected: FAIL, `not-a-real-secret-5` is in the HTML;
  - drop `nameRow` from the `quicklook` table calls (so it defaults to the rejected header), `make renderer`, run `--filter testQuickLookMasksSecretFiles`. Expected: FAIL, `pw-not-r` is in the HTML;
  - remove the `preparePage()` call from `renderData`, run `--filter testHostileStringsNeverExecute`. Expected: FAIL with a JavaScript error (`window.tegel` is undefined on the unloaded page).
- [ ] **Step 6: Commit:** `Renderer/src/data/view.js Renderer/src/data/labels.js Renderer/src/css/data.css Renderer/build.js Renderer/src/page.js Packages/TegelKit/Sources/TegelKit/DataRender.swift Packages/TegelKit/Sources/TegelKit/RendererWebView.swift Packages/TegelKit/Sources/TegelKit/Resources/Renderer Packages/TegelKit/Tests/TegelKitTests/WebView/DataRenderTests.swift Fixtures/data/hostile.*`, `feat(tegelkit): data view bridge with scaled paging, masking and hostile-input tests` + trailer.

---

### Task 7: Quick Look extension (free tier) and the extension-less text path

**Files:**
- Modify: `Apps/Data/QuickLook/PreviewProvider.swift`.

**Interfaces:**
- Consumes: `DataFile.load(_:maxBytes:)`, `RendererWebView.renderData(…, options: RenderOptions(mode: .quicklook, theme: .paper, baseURL: nil), labels: DataLabels.all, truncated:, secretFile:)`, and the G0 reply mechanism used in `Apps/Markdown/QuickLook` (Task 0 #1).
- Produces: a preview for every `QLSupportedContentTypes` entry. It throws for `DataFileError`, so Quick Look shows its generic preview.

**Extension-less text decision** (DF2, DF5):
- **Claimed:** `public.data`, which reaches only files typed exactly `public.data` (`Dockerfile`, `CHANGELOG`, `.gitignore`, `.zshrc`, `.env`, and secret dotfiles such as `.netrc`, `.npmrc`, `credentials`, `id_rsa`, …). The secret ones are masked whole (Task 6, K12). Binaries are rejected by the NUL-byte sniff before any decoding, so Quick Look falls back to its generic preview. `README`, `LICENSE` and `Makefile` are already `public.plain-text`/`public.make-source` on 15.7; the system previews them and we don't touch them.
- **Cut:** `.env.local` and other `.env.*` files resolve to `dyn.*` (their "extension" is `local`). Catching them would mean declaring `local`, `production`, … for every file on the Mac, so they are **not** previewed in Quick Look. The window opens them by name (Task 5 routing).
- **Tests:** Quick Look dispatch can't be asserted from a unit test, so the Step 4 matrix is the test. The sniff and the caps are unit-tested in Task 5.

- [ ] **Step 1: Run the matrix before implementing, and record it.** `qlmanage -r && qlmanage -r cache`, then `qlmanage -p <file>` for each row below, using temp copies only, **never the repo's real `.env`**. Expected now: the Task 1 stub (plain text, no masking) for our types. That's the failing state.
- [ ] **Step 2: Implement `providePreview(for:)`.** `DataFile.load(request.fileURL, maxBytes: 2_000_000)`, then render through the G0 mechanism with `truncated: file.truncated, secretFile: file.secretFile`, adding a one-line "Tegel Data" footer so the matrix can tell our previewer from the system's.
- [ ] **Step 3: Build.** `make build`, then `pluginkit -m -v -p com.apple.quicklook.preview | grep com.tegelapps.data.quicklook`. Expected: one line with the build path.
- [ ] **Step 4: Run the matrix (build Mac, macOS 15.7, Intel), expect PASS.** Each preview must appear in < 2 s.

| File (temp copy) | Expected |
|---|---|
| `sample.json`, `.yaml`, `.toml`, `.jsonl`, `x.ndjson` | Our tree or rows, Tegel footer |
| `sample.csv`, `sample.tsv`, `quoted-newline.csv` | Our table, header detected, the quoted newline in one cell |
| `prod.env` and `.env` (copies of `sample.env`) | Keys shown; every value is `••••••••`; clicking reveals nothing |
| `.netrc`, `.git-credentials`, `credentials`, `id_rsa` (temp files with fake values, made as in `testQuickLookMasksSecretFiles`) | First tokens shown; every value, URL password and PEM body is `••••••••` |
| `big-1m.csv` | First 1,000 rows plus the truncated banner |
| `Dockerfile`, `CHANGELOG`, `.gitignore` | Our plain text |
| a NUL-containing `blob` (no extension) | System generic preview (icon), no garbage |
| `/bin/ls`, `README`, `Makefile` | Unchanged system behaviour |
| `hostile.csv` | Text shown literally; nothing executes |

If the system previewer wins for a type (DF5 says it may), write that down. The site must not claim that type (Task 13).
- [ ] **Step 5: Remote matrix.** Run the same matrix on `macos-26` (GitHub, arm64) and macOS 27 (Task 14 machine) and record the results in `docs/reviews/m06.md` § "Quick Look matrix".
- [ ] **Step 6: Commit:** `Apps/Data/QuickLook/PreviewProvider.swift docs/reviews/m06.md`, `feat(data-ql): Quick Look previews for data files, secrets masked, extension-less text` + trailer.

---

### Task 8: Window viewer (Pro), `.env` viewer and live reload

**Files:**
- Modify: `Apps/Data/App/DataApp.swift`.
- Create: `Apps/Data/App/DataWindow.swift` and `Apps/Data/App/WelcomeView.swift`.
- Modify: `project.yml`. Add `Apps/Markdown/App/ProGate.swift`, `Apps/Markdown/App/LicenceSettingsView.swift` and `Apps/Markdown/App/UpdatesSettingsView.swift` (paths from Task 0 #7) to the `data` target's sources by path; don't copy them. Add the Sparkle package product to `data` exactly as plan 03 adds it to `markdown`, and `- package: TegelKit, product: TegelStore` exactly as plan 03 Task 8 adds it to `markdown` (`LicenceSettingsView`, `LicenseManager` and `PolarConfig` live in TegelStore). [K12]
- No App 1 file changes: plan 03's `LicenceSettingsView` already takes `proSummary: LocalizedStringKey`, the text of its `.free` row, and App 1 passes its own sentence. Data passes its own: "Pro adds the window viewer for large files, the .env viewer, session transcripts with search, and Markdown export. One-time purchase for up to 2 Macs, with a 14-day refund."
- Modify: `Apps/Data/Shared/Localizable.xcstrings`. A view compiled into `data` looks its strings up in Data's bundle, so add every string the three shared views show, with NL/FR/AR copied from `Apps/Markdown/App/Localizable.xcstrings`, plus Data's `proSummary`, the `WelcomeView` strings and the not-text copy below, translated to NL/FR/AR (D6).

**Interfaces:**
- Consumes: `EnvironmentValues.isPro` (`ProGate.swift`); `LicenceSettingsView(proSummary:)` (plan 03 Task 9; no updater parameter, since Updates is its own tab); `UpdatesSettingsView(updater:)` (plan 03); `LicenseManager(client: PolarClient(config: .fromInfoPlist()))` and plan 03's 24 h refresh loop; `SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)`; `QuickLookSetup.settingsURL` and `QuickLookSetup.settingsPath(macOSMajor:)` (TegelKit, plan 02 Task 15); `RendererWebView`, `renderData`, `renderPaged`; `RecordIndex(url:quoteAware:)`, `DataFile.load(_:maxBytes:)`; `FileWatcher(url:debounce:onChange:)`; App 1's open-file pattern (Task 0 #7).
- Produces: `struct DataWindow: View { let url: URL }` and `struct WelcomeView: View`. `WelcomeView` shows when there's no Pro licence or no file:
  - the Quick Look how-to: Space in Finder, then the Settings path chosen by `QuickLookSetup.settingsPath(macOSMajor:)` (the same copy as App 1's Welcome, never hard-coded here), with an "Open System Settings" button for `QuickLookSetup.settingsURL`;
  - the Pro feature list, and "One-time purchase for 2 Macs" with a buy button (`PolarConfig.checkoutURL`). No price in the app: the checkout shows it (plan 05 Task 3 Step 1);
  - App 1's `LicenceSettingsView`, given Data's `proSummary`.

App wiring in `DataApp.swift` copies plan 03's `MarkdownApp` wiring line for line, nothing new [K12]:
- one `SPUStandardUpdaterController` held by the app; `CommandGroup(after: .appInfo) { Button("Check for Updates…") { updaterController.updater.checkForUpdates() } }`;
- one `LicenseManager`, started with `Task { while !Task.isCancelled { await m.refresh(); try? await Task.sleep(for: .seconds(86_400)) } }`, and its `isPro` injected into the environment;
- a `Settings` scene with the tabs Licence | Updates (`LicenceSettingsView(proSummary:)` with Data's summary, `UpdatesSettingsView(updater: updaterController.updater)`).

Routing rule in `DataWindow`:
- `!isPro` → `WelcomeView`. `jsonl`, `csv`, `tsv` → `RecordIndex` (`quoteAware` for csv only) → `renderPaged`; on `.utf16`, fall back to the next path.
- Every other format, including `.text` → `DataFile.load(url, maxBytes: 100_000_000)` → `renderData(mode: .window)`.
- A `DataFileError` (a binary or a non-regular file, which `public.data` in Task 1 lets through) shows "This file isn't a text file." and nothing else.
- `FileWatcher` on the file → rebuild and re-render, keeping the scroll position (and sticking to the bottom if it was there).
- Links: the window's `RendererWebView` gets `renderer.openLink = { NSWorkspace.shared.open($0) }`, as plan 02's `ReaderController` does for App 1, so only `http`, `https` and `mailto` links open, in the user's apps. The Quick Look extension (Task 7) leaves `openLink` nil and opens nothing.

- [ ] **Step 1: Write the run checklist as the failing state.** On the current build, opening `sample.csv` from Finder ("Open With › Tegel Data") shows an empty window, the app menu has no "Check for Updates…", and ⌘, opens no Licence or Updates tab. That's FAIL.
- [ ] **Step 2: Implement.** The `project.yml` entries, the three views, the app wiring and Data's strings.
- [ ] **Step 3: Build.** `xcodegen generate && make build`. Expected: `** BUILD SUCCEEDED **` with no new warnings in `Apps/Data`. Then `grep -rl 'folder mode' "build/Build/Products/Debug/Tegel Data.app" | wc -l` → `0`, and App 1 is unchanged: `make test-app ONLY=LocalizationTests` passes.
- [ ] **Step 4: Run the checklist on the build Mac, expect PASS.**
  - Debug `isPro` override **off**: opening any fixture shows `WelcomeView`.
  - Override **on**: each `sample.*` renders; `big-1m.csv` opens in < 3 s and scrolls to row 1,000,000; `big-200mb.jsonl` flags the bad lines at multiples of 100,000, still renders the rest, and ⌘↓ shows its last record; `hostile.*` render as text; in `sample.env`, one click reveals one value.
  - Live reload: `printf '{"live":1}\n' >> /tmp/live.jsonl` while the file is open adds the row within 1 s. Then `: > /tmp/live.jsonl`: the app doesn't crash, and the window shows an empty file within 1 s (the watcher rebuilds the index) [K12].
  - "Check for Updates…" in the app menu reports Sparkle's update error: no Data appcast exists until Task 16 publishes one (plan 03 Task 10 Step 4 expects the same of App 1 before 1.0.0). Settings shows Licence | Updates, and the Licence tab's free copy is Data's `proSummary`.
  - A real file named `.env` (Task 1's `public.data` claim). Make one in a temp folder, never the repo's real `.env`, and ask LaunchServices:

```bash
D=$(mktemp -d) && cp Fixtures/data/sample.env "$D/.env"
F="$D/.env" swift -e 'import AppKit; let u = URL(fileURLWithPath: ProcessInfo.processInfo.environment["F"]!); print(NSWorkspace.shared.urlsForApplications(toOpen: u).contains { $0.lastPathComponent == "Tegel Data.app" }, NSWorkspace.shared.urlForApplication(toOpen: u)?.lastPathComponent ?? "none")'
```

    Expected: `true`, then an app other than `Tegel Data.app` (`Alternate` never takes the default). In Finder (⌘⇧. shows dotfiles), Open With on it lists Tegel Data and opens it with every value masked, and so does dropping it on the Dock icon. Watch it fail first: drop `public.data` from `LSItemContentTypes`, rebuild, `lsregister -f` the app, and the `swift -e` line prints `false`; restore it. Record in `docs/reviews/m06.md` what LaunchServices did at `Alternate`, including whether a `.png` now lists Tegel Data too (it may match `public.data` by conformance; the window then shows the not-text copy).
  - Relaunch with `-AppleLanguages '(nl)'`, then `(fr)`, then `(ar)`: Welcome, Licence and Updates show no English and no Markdown feature. In Arabic the Welcome text is right-to-left and the data stays left-to-right.
- [ ] **Step 5: Commit:** `Apps/Data/App Apps/Data/Shared/Localizable.xcstrings project.yml`, `feat(data): Pro window viewer, paging, .env reveal, live reload, App 1's licence and update wiring` + trailer.

---

### Task 9: Transcript parser (Claude Code and Codex) and synthetic fixtures

**Files:**
- Create: `Renderer/src/data/transcript.js`. Modify `Renderer/src/data/view.js` so format `transcript` uses it, falling back to JSONL rows when `kind === 'unknown'` (risk 6), and fill `window.tegel.transcriptMarkdown`.
- Create these synthetic fixtures, **hand-written, not derived from any real file**; prose contains no code fences:
  - `Fixtures/data/sessions/claude/-Users-demo-sample/00000000-0000-4000-8000-000000000001.jsonl` (current format [DF9]): user text; an `isMeta` user record; assistant `thinking`, `text` and `tool_use{id:"toolu_demo1"}`; user `tool_result{tool_use_id:"toolu_demo1"}` whose content includes a ```` ``` ```` line; `ai-title`, `attachment` and `system` records; one `isSidechain` record; an unknown `{"type":"future-record"}`; one malformed line; a user text record containing `needle-42` on line 9.
  - `…/00000000-0000-4000-8000-000000000002.jsonl`: the legacy format with `{"type":"summary",…}`.
  - `Fixtures/data/sessions/codex/2027/01/05/rollout-2027-01-05T10-00-00-00000000-0000-4000-8000-000000000003.jsonl` [DF10]: `session_meta`; `response_item` messages (user, assistant), `reasoning` (with `encrypted_content: "ZmFrZQ=="`), `function_call` + `function_call_output` (`call_id: "call_demo"`), `custom_tool_call` + output; `event_msg`; an unknown type.
- Test: `Renderer/test/data-transcript.test.js`.

**Interfaces:**
- Consumes: `parseJSONLLine`, `jsonlRowHTML`, `treeHTML`, `escapeHTML`, `DEFAULT_LABELS`, `maskSecrets` (Task 4); `renderToHTML` (master §3.2, used in the test only).
- Produces:

```js
export function parseTranscript(lines /* string[] */)
  // -> { kind: 'claude'|'codex'|'unknown', title: string|null, hidden: number,
  //      items: Array<{ line, kind: 'user'|'assistant'|'thinking'|'tool'|'note'|'raw'|'bad',
  //                     text?, name?, input?, result?: { text, isError }, sidechain?, value?, message? }> }
export function transcriptHTML(t, { showHidden = false, reveal = false, labels = DEFAULT_LABELS } = {})  // items get id="L<line>"; tools are closed <details class="tool">
export function transcriptToMarkdown(t, { reveal = false, labels = DEFAULT_LABELS } = {})               // -> string
  // both: unless reveal, every item's text passes through maskSecrets before it is escaped or fenced, so every item
  // kind is covered, raw and bad items included, and a NAME=value match never reaches the markup after it [K12]
```

Mapping:
- **Claude, shown:** `user`/`assistant` text; `thinking`; `tool_use` paired with `tool_result` by id; `system` and `summary` as notes.
- **Claude, hidden by default** (counted in `hidden`, shown as `raw` with `showHidden`): `isMeta` users and the internal types in DF9.
- **Codex, shown:** `message` → user or assistant; `reasoning.summary` → thinking (never `encrypted_content`); `function_call`/`custom_tool_call` paired with their `*_output` by `call_id`; `compacted` as a note.
- **Codex, hidden:** `event_msg`, `turn_context`, `token_usage_record`, `world_state`.
- **Anything unrecognised:** `raw` (shown, collapsed).
- **Detection:** `claude` if a record has `sessionId` and type `user`/`assistant`. `codex` if a type is `session_meta` or `response_item`, or a top-level `type:"message"` with `role` (older Codex). Otherwise `unknown`.

- [ ] **Step 1: Write the failing test.**

```js
import { test, expect } from 'bun:test';
import { readFileSync } from 'node:fs';
import { parseTranscript, transcriptHTML, transcriptToMarkdown } from '../src/data/transcript.js';
import { renderToHTML } from '../src/markdown.js';
const L = p => readFileSync(new URL('../../Fixtures/data/sessions/' + p, import.meta.url), 'utf8').split(/\r?\n/); // blank lines kept: line numbers must match the file
const C = 'claude/-Users-demo-sample/00000000-0000-4000-8000-000000000001.jsonl';

test('claude: tool call paired with its result; unknown kept; bad line flagged', () => {
  const t = parseTranscript(L(C));
  expect(t.kind).toBe('claude');
  expect(t.title).not.toBeNull();
  const tool = t.items.find(i => i.kind === 'tool');
  expect(tool.name).toBeTruthy(); expect(tool.result.text).toContain('```');
  expect(t.items.some(i => i.kind === 'raw' && i.value.type === 'future-record')).toBe(true);
  expect(t.items.filter(i => i.kind === 'bad').length).toBe(1);
  expect(t.hidden).toBeGreaterThan(0);
  expect(transcriptHTML(t)).toContain('id="L9"');
});
test('codex: call_id pairing; encrypted reasoning never shown', () => {
  const t = parseTranscript(L('codex/2027/01/05/rollout-2027-01-05T10-00-00-00000000-0000-4000-8000-000000000003.jsonl'));
  expect(t.kind).toBe('codex');
  expect(t.items.filter(i => i.kind === 'tool' && i.result).length).toBe(2);
  expect(transcriptHTML(t, { showHidden: true })).not.toContain('ZmFrZQ==');
});
test('legacy summary becomes a note; plain JSONL is unknown', () => {
  expect(parseTranscript(L('claude/-Users-demo-sample/00000000-0000-4000-8000-000000000002.jsonl')).items.some(i => i.kind === 'note')).toBe(true);
  expect(parseTranscript(['{"a":1}', '{"b":2}']).kind).toBe('unknown');
});
test('hostile text escaped; markdown export keeps tool output inside one fence', () => {
  const t = parseTranscript(['{"type":"user","sessionId":"s","message":{"role":"user","content":"<script>x</script>"}}']);
  expect(transcriptHTML(t)).not.toContain('<script');
  const c = parseTranscript(L(C));
  const tools = c.items.filter(i => i.kind === 'tool').length;
  const html = renderToHTML(transcriptToMarkdown(c), { mode: 'window' });
  // fixture prose has no fences, so exactly one input block + one output block per tool; a fence that broke out changes the count
  expect((html.match(/<pre/g) || []).length).toBe(2 * tools);
});
test('token shapes masked in view and export unless revealed', () => {
  const tok = 'sk-' + 'a'.repeat(40); // built here, never stored in Fixtures/
  const t = parseTranscript([JSON.stringify({ type: 'user', sessionId: 's', message: { role: 'user', content: `key ${tok}` } }),
    JSON.stringify({ type: 'user', sessionId: 's', message: { role: 'user', content: [{ type: 'tool_result', tool_use_id: 'x', content: tok }] } }),
    JSON.stringify({ type: 'future-record', note: tok }), '{bad ' + tok]); // a raw item and a bad line
  expect(t.items.filter(i => i.kind === 'raw' || i.kind === 'bad').length).toBe(2);
  expect(transcriptHTML(t)).not.toContain(tok);
  expect(transcriptHTML(t, { showHidden: true })).not.toContain(tok);
  expect(transcriptToMarkdown(t)).not.toContain(tok);
  expect(transcriptHTML(t, { reveal: true })).toContain(tok);
  expect(transcriptToMarkdown(t, { reveal: true })).toContain(tok);
});
test('masking stays inside its item', () => {
  const u = c => JSON.stringify({ type: 'user', sessionId: 's', message: { role: 'user', content: c } });
  const html = transcriptHTML(parseTranscript([u('DB_PASSWORD=x'), u('after')]));
  expect(html).not.toContain('DB_PASSWORD=x');
  expect(html).toMatch(/<[a-z]+[^>]*\bid="L2"/); // the next item's tag survives, anchor included
  expect(html).toContain('after');
});
```

- [ ] **Step 2: Run it, expect FAIL.** `cd Renderer && bun test test/data-transcript.test.js`. Expected: FAIL, `Cannot find module '../src/data/transcript.js'`.
- [ ] **Step 3: Implement.** `parseTranscript` is one pass over the lines (blank lines skipped, numbering kept) with a `Map` from id to the pending tool item. The Markdown export uses `## User` / `## Assistant` headings with the text verbatim, renders each tool as `#### Tool: name` with input and output in fences one backtick longer than the longest backtick run inside them (CommonMark rule), and leaves out `thinking`. One helper `m = s => reveal ? s : maskSecrets(s)` wraps every text field of every item (the title, text, tool name, input and result, a note, a raw item's JSON, a bad line) before it is escaped (HTML) or fenced (Markdown, so fence lengths are measured on the masked text). Masking the joined HTML instead would let a NAME=value match run into the next item's markup. Its only insertion is `••••••••` (never `<`, `>`, `&` or a quote), and the HTML still goes through the page's sanitiser.
- [ ] **Step 4: Run it, expect PASS.** `cd Renderer && bun test test/data-transcript.test.js`. Expected: 6 pass. Then run the secret scan, which must print nothing:
  `grep -rnE 'sk-[A-Za-z0-9]{20,}|ghp_|AKIA[0-9A-Z]{16}|PRIVATE KEY|/Users/[a-z]+' Fixtures/data | grep -v '/Users/demo'`
- [ ] **Step 5: Watch the mask guards fail.** Change `m` to `s => s`, rerun the test file. Expected: FAIL in `token shapes masked…`. Restore `m`. Then apply `m` once to the joined HTML instead of each item's text: FAIL in `masking stays inside its item`. Restore it, rerun: 6 pass.
- [ ] **Step 6: Commit:** `Renderer/src/data/transcript.js Renderer/src/data/view.js Renderer/test/data-transcript.test.js Fixtures/data/sessions Packages/TegelKit/Sources/TegelKit/Resources/Renderer`, `feat(renderer): tolerant Claude Code/Codex transcript parser, Markdown export, tokens masked` + trailer.

---

### Task 10: Session mode (Pro)

**Files:**
- Modify: `Packages/TegelKit/Sources/TegelKit/FolderIndex.swift` (CR-2) and `Packages/TegelKit/Tests/TegelKitTests/FolderIndexTests.swift`.
- Create: `Apps/Data/App/SessionSources.swift` and `Apps/Data/App/SessionsView.swift`. Modify `DataApp.swift` to add the "Sessions" window and the ⌘⇧S command.

**Interfaces:**
- Consumes:
  - `BookmarkStore.save(_:)`, `BookmarkStore.resolveAll() -> [URL]` (scope handling per Task 0 #4);
  - `FolderIndex.search(_:in:limit:) -> [SearchHit]` (plan 02 Task 4: each file read through `TextFileLoader`'s 5 MB default cap);
  - `TextFileLoader.load(_:maxBytes:)`;
  - `renderData(_:format: .transcript, …)`, `scroll(toHeading:)` (plan 02: takes the DOM id and calls `getElementById`);
  - `FileWatcher`.
- Produces:

```swift
// TegelKit (master §3.3 signature): markdownFiles(in:limit:) becomes a call to this
public static func files(in root: URL, extensions: Set<String>, limit: Int = maxFiles) throws -> [FolderItem]   // same skip list and 5,000 cap as markdownFiles
// TegelKit (CR-2): search gains a per-file read cap; the default keeps App 1's 5 MB, so App 1's call sites don't change
public static func search(_ query: String, in items: [FolderItem], limit: Int = 200, maxBytesPerFile: Int = 5_000_000) -> [SearchHit]
// App
@MainActor enum SessionSources {
    static func pick() -> URL?   // NSOpenPanel: canChooseDirectories, !canChooseFiles, showsHiddenFiles = true,
                                 // directoryURL = <real home>/.claude/projects (real home via getpwuid(getuid()).pw_dir,
                                 // because the sandbox container is what homeDirectoryForCurrentUser returns); then BookmarkStore.save
    static var all: [URL] { get } // BookmarkStore.resolveAll()
}
struct SessionsView: View
// Pro (§6.2), gated exactly like DataWindow: !isPro -> WelcomeView, with no source list, search or session ever loaded.
// The "Sessions" window and its ⌘⇧S command open this view, so neither reaches session mode without Pro.
// Sidebar: sources, then sessions = FolderIndex.files(in:extensions:["jsonl"]) (default cap; a capped list says so in the sidebar footer) sorted by modification date (newest first).
// Search field: debounced 300 ms, FolderIndex.search(…, maxBytesPerFile: 128_000_000) off the main actor (the open-session cap below).
// A result row shows `relativePath · L<line>`, plus SearchHit.snippet only while "Show secrets" is on: the snippet is raw file text.
// A hit opens the session, then scroll(toHeading: "user-content-L\(line)"): the item's id="L<line>" after the page's
// SANITIZE_NAMED_PROPS pass (plan 01 CR 4; Task 0 #5).
// The open session loads through TextFileLoader.load(url, maxBytes: 128_000_000) (truncated -> banner).
// FileWatcher on the open file -> re-render, kept at the bottom if it was there. ⌘R rescans the sources.
// The session's RendererWebView sets openLink exactly as DataWindow does (Task 8): http, https and mailto only.
// A "Show internal records" toggle maps to showHidden. A "Show secrets" toggle (off on every launch, never persisted) maps to reveal [K12].
```

- [ ] **Step 1: Write the failing test.** `testFilesWithExtensions` builds a temp tree with `a.jsonl`, `b/c.jsonl`, `node_modules/x.jsonl`, `.git/y.jsonl` and `d.md`. It asserts `files(in:root, extensions:["jsonl"]).map(\.relativePath).sorted() == ["a.jsonl","b/c.jsonl"]`, `files(in:root, extensions:["jsonl"], limit: 1).count == 1` and `markdownFiles(in:root).map(\.relativePath) == ["d.md"]`. `testSearchFindsLateHitInLargeFile`: a 20 MB `.md` file with `needle` on its last line gives one hit with `search("needle", in: items, maxBytesPerFile: 128_000_000)` and none with `search("needle", in: items)` (App 1's 5 MB cap kept).
- [ ] **Step 2: Run it, expect FAIL.** `swift test --package-path Packages/TegelKit --filter FolderIndexTests`. Expected: FAIL to compile, `type 'FolderIndex' has no member 'files'`.
- [ ] **Step 3: Implement** `files(in:extensions:limit:)`, rebase `markdownFiles` onto it, and pass `maxBytesPerFile` through to `search`'s `TextFileLoader.load(_:maxBytes:)`. Then write the two app files.
- [ ] **Step 4: Run it, expect PASS, then check the app.** `swift test --package-path Packages/TegelKit --filter FolderIndexTests` gives all pass. Then `make build`, and run this checklist with temp copies of `Fixtures/data/sessions/*` in a folder the panel picks, **never the real `~/.claude`**:
  - the panel can browse hidden folders;
  - after a relaunch, the list comes back with no prompt;
  - searching `needle-42` gives one hit, and opening it scrolls to L9 (`document.getElementById('user-content-L9').getBoundingClientRect().top` is near 0 in Web Inspector);
  - tool calls are collapsed;
  - appending a synthetic user line adds it within 1 s;
  - a synthetic user line holding `[a](https://example.com) [b](file:///etc/hosts)`: transcript prose is escaped plain text (Task 9), so both show literally, clicking them does nothing, and the session stays on screen;
  - a `.jsonl` that isn't a transcript shows generic rows;
  - a synthetic user line holding `'sk-' + 40 × 'a'` (typed into the temp copy, never into `Fixtures/`) shows as `••••••••` until "Show secrets" is on, and is masked again after a relaunch. Searching `sk-aaaa` with "Show secrets" off lists the hit as `<session file> · L<n>` with no snippet; with it on, the row adds the snippet. Watch it fail first: show the snippet unconditionally, `make build`, and the off-state row shows `sk-aaaa…`; restore it;
  - **Pro gate:** with the Debug `isPro` override **off**, ⌘⇧S opens the Sessions window showing only `WelcomeView` (no sources, no search field), and so does Window › Sessions. Watch it fail first: comment out the `!isPro` branch in `SessionsView`, `make build`, and ⌘⇧S shows the session browser with the bookmarked sources. Restore it and rebuild: `WelcomeView` again. (Every row above runs with the override **on**.)
- [ ] **Step 5: Commit:** `Packages/TegelKit/Sources/TegelKit/FolderIndex.swift Packages/TegelKit/Tests/TegelKitTests/FolderIndexTests.swift Apps/Data/App`, `feat(data): session mode with bookmarked folders, cross-session search, live reload` + trailer.

---

### Task 11: Markdown export and "Open in Tegel Markdown" (Pro; the cross-sell)

**Files:**
- Create: `Apps/Data/App/ExportController.swift`. Modify `SessionsView.swift` to add the toolbar buttons "Export Markdown…" and "Open in Tegel Markdown".
- Modify: `Makefile`. Add a `readonly-gate` target and make `check` depend on it.

**Interfaces:**
- Consumes: `window.tegel.transcriptMarkdown({ reveal })` (Task 9), `RendererWebView.webView`, the session's "Show secrets" state (Task 10).
- Produces:

```swift
@MainActor enum ExportController {
    static func exportMarkdown(from renderer: RendererWebView, suggestedName: String, reveal: Bool) async throws -> URL?
    // NSSavePanel(allowedContentTypes: [UTType(filenameExtension: "md")!]) -> callAsyncJavaScript("return window.tegel.transcriptMarkdown({ reveal })", arguments: ["reveal": reveal])
    // the export masks tokens exactly as the view does (K12)
    // -> String.write(to: picked, atomically: false, encoding: .utf8): the save panel grants the file, not its folder (plan 02 Task 11). nil when cancelled.
    static var markdownAppURL: URL? { get }
    // NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.tegelapps.markdown")
    static func openInMarkdownApp(_ exported: URL, with app: URL)
    // NSWorkspace.shared.open([exported], withApplicationAt: app, configuration:)
}
```

"Open in Tegel Markdown" is shown only when `markdownAppURL` is non-nil, re-read each time the Sessions window appears. Without App 1 the button would be an in-app promotion (rule 8), so it is hidden, as plan 07 hides its own Open in Tegel Markdown action. It is enabled after an export and opens the file that was just exported. App 2 writes no temp file; the only write outside the app's container is the save-panel URL (rule 1 allows the container).

- [ ] **Step 1: Write the failing gate.** Add this to the `Makefile`:

```make
# every app and the shared sources (K12); test targets write temp files, so */*Tests/ is skipped. The allowlist names the writers:
# App 2's save-panel export, App 1's save-panel PDF write (exactly `data.write(to:` in ReaderController), and PDFExporter's private container folder
readonly-gate:
	@! git grep -nE 'write\(to(File)?:|createFile\(|removeItem\(|moveItem\(|copyItem\(|replaceItem|trashItem\(|FileHandle\(for(Writing|Updating)|\.write\(contentsOf' -- Apps Packages/TegelKit/Sources | grep -vE '/[A-Za-z]+Tests/|^Apps/Data/App/ExportController\.swift:|^Apps/Markdown/App/ReaderController\.swift:[0-9]+:.*data\.write\(to:|^Packages/TegelKit/Sources/TegelKit/PDFExporter\.swift:'
```

Add the temporary lines `try? "x".write(to: url, atomically: true, encoding: .utf8)` and `try? FileManager.default.trashItem(at: url, resultingItemURL: nil)` to `Apps/Data/App/DataWindow.swift`, and the first of them to `Apps/Markdown/App/ReaderController.swift`. Run `make readonly-gate`. Expected: FAIL, with all three lines printed: the App 1 line proves the whole of `Apps/` is scanned and that ReaderController's allowance covers only its `data.write(to:`; the `trashItem` line proves the wider API list. Remove the three lines. `git grep` sees tracked files only, so a plant in a new file must be `git add`ed first.
- [ ] **Step 2: Implement** `ExportController` and the toolbar buttons (Pro-gated through `isPro`).
- [ ] **Step 3: Run the gate and build, expect PASS.** `make readonly-gate && make build`. Expected: exit 0 and `** BUILD SUCCEEDED **`.
- [ ] **Step 4: Run the checklist on the build Mac.**
  - Export the Claude fixture session. The `.md` opens in Tegel Markdown with each tool output in a single code block.
  - Export the session holding the Task 10 synthetic `sk-…` line with "Show secrets" off: `grep -c 'sk-aaaa' <exported.md>` prints `0`. With it on, it prints `1`.
  - Unregister **every** copy of App 1 (P2-14); Debug copies under `build/` and DerivedData would otherwise still answer:

```bash
LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
mdfind "kMDItemCFBundleIdentifier == 'com.tegelapps.markdown'" > "$TMPDIR/tm-copies.txt"
while IFS= read -r app; do "$LSREG" -u "$app"; done < "$TMPDIR/tm-copies.txt"
swift -e 'import AppKit; print(NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.tegelapps.markdown") as Any)'
```

    Expected: the last line prints `nil`. Close and reopen the Sessions window: the toolbar has no "Open in Tegel Markdown" button. Watch it fail first: show the button unconditionally, `make build`, and it appears with App 1 unregistered; restore it.
  - Re-register them: `while IFS= read -r app; do "$LSREG" -f "$app"; done < "$TMPDIR/tm-copies.txt"`. The `swift -e` line prints the `/Applications` path again, and the reopened Sessions window shows the button.
- [ ] **Step 5: Commit:** `Apps/Data/App/ExportController.swift Apps/Data/App/SessionsView.swift Makefile`, `feat(data): export sessions to Markdown, open them in Tegel Markdown, read-only gate over Apps/` + trailer.

---

### Task 12: Polar products for Data and the bundle (W12)

**Why:** plan 03 ships the benefit binding in App 1 v1.0 (D1): `PolarConfig.benefitID` (Info.plist `TGPolarBenefitID`), `PolarError.wrongProduct`, `benefit_id` on validate, and the activate check that deactivates a mismatched key. So a $15 Data key never unlocks the $19 Markdown app, and the reverse [DF6]. This task creates the Data and bundle Polar objects, gives App 2 its own benefit id, and proves the binding end to end with real keys.

**Files:**
- Modify: the `Config/` xcconfigs. Fill `TG_POLAR_BENEFIT_ID_DATA` and `TG_POLAR_CHECKOUT_URL_DATA` (Task 1): sandbox values in the xcconfig that holds plan 03's sandbox values (Task 0 #9), production values in `Config/Release.xcconfig` (Step 3).
- Modify: `docs/reviews/m06.md`.
- (No site change here: the production checkout links reach `site/config.json` and the pages in Task 16 Step 4, with the download.)

**Interfaces:**
- Consumes: plan 03's `PolarConfig.benefitID`, `PolarError.wrongProduct` and its copy "This key is for another Tegel app. Each app has its own key on your Polar purchases page." (checked by Task 0 #6).
- Produces: the Polar ids in `.env` under the Task 1 key names; App 2's `TGPolarBenefitID` = the Data licence benefit; `POLAR_QA_LICENSE_KEY_DATA` and a re-issued App 1 `POLAR_QA_LICENSE_KEY` (production, for Task 14; both removed in Task 16).

**Activation UX for the bundle:** one key per app. Each app accepts only its own benefit, and the server enforces it. The bundle product carries **both** existing licence benefits (Polar lets one benefit attach to many products, DF6). No cross-key logic.

- [ ] **Step 1: Create the Polar sandbox objects** (sandbox, so no approval needed; Polar API with `POLAR_SANDBOX_ACCESS_TOKEN`, or the dashboard). Record every id in `.env` under the Task 1 key names.
  - Benefit **"Tegel Data licence"**: `license_keys`, prefix `TGDATA`, `limit_activations: 2`, `enable_customer_admin: true`, no expiry.
  - Product **"Tegel Data"**: $15 one-time and a EUR price, that benefit. Product **"Tegel Bundle"**: $29 one-time and a EUR price, benefits [Markdown licence, Data licence]. EUR amounts: €15 and €29, **pending the user's confirmation** (K10; same open question as App 1's €19/€14). Both carry plan 05's opt-in field (`marketing_opt_in`, label "Email me set-up tips and news about Tegel apps", unticked; Task 0 #11) and say "2 Macs per licence"; the bundle adds "one key per app".
  - A sandbox checkout link for each product, saved as `POLAR_SANDBOX_CHECKOUT_URL_DATA` and `POLAR_SANDBOX_CHECKOUT_URL_BUNDLE` (Step 2 buys through the second; the site never uses either).
  - Fill the sandbox `TG_POLAR_BENEFIT_ID_DATA` and `TG_POLAR_CHECKOUT_URL_DATA`, then `xcodegen generate && make build` and `/usr/libexec/PlistBuddy -c 'Print TGPolarBenefitID' "build/Build/Products/Debug/Tegel Data.app/Contents/Info.plist"`. Expected: the sandbox Data benefit id, not the Markdown one. Commit: `Config`, `build(data): sandbox Polar ids for Tegel Data` + trailer.

- [ ] **Step 2: Sandbox end-to-end** (Debug builds of both apps; test card). Buy the bundle, then confirm:
  - the portal and the email show **two** keys (the DF6 gap). If not, stop and ask the user;
  - the Data key activates App 2;
  - the Markdown key in App 2 shows the `wrongProduct` message, and the portal shows no new activation left on that key;
  - the Data key in App 1 shows `wrongProduct`.

  Record the results in `docs/reviews/m06.md`.
- [ ] **Step 3: Production** (**user approval**, H11). On Thu 28 Jan, before Task 16, create the same three objects in production with no public checkout link (check that Polar's storefront doesn't list them). Fill in `Release.xcconfig`, replacing Task 1's two `_DATA` placeholders, and `.env`. Expected: `grep -c REPLACE_IN_PLAN_05 Config/Release.xcconfig` → `0`. Every App 1 build since 1.0.0 binds keys to its own benefit (plan 03), so Data keys can't unlock App 1 from the first sale.
  - **Price and field check:** plan 05 Task 2 Step 5's price and field queries with `envget POLAR_PRODUCT_ID_MARKDOWN` changed to `envget POLAR_PRODUCT_ID_DATA`, then to `…_BUNDLE`. Expected: `[('eur', 1500), ('usd', 1500)]`, then `[('eur', 2900), ('usd', 2900)]` (or the user's EUR amounts), and the `marketing_opt_in` row ending `False` for both.
  - **BNPL check** (rule 7): run plan 05 Task 2 Step 11's procedure, unchanged, on `POLAR_CHECKOUT_URL_DATA` and `POLAR_CHECKOUT_URL_BUNDLE`; screenshots to `docs/reviews/m06-polar/checkout-{data,bundle}-{safari,chrome}-{nl,us}.png`. Its stop rule applies: BNPL shown → stop the App 2 launch prep and tell the user (B17).
  - **QA licence** 🔒 (plan 05 Task 2 Step 7's pattern): discount `QA-DATA`, 100%, single-use, ends 2027-02-05, never published; an unpublished checkout link for Tegel Data with it preset; complete it with the studio email, opt-in left unticked; save the key as `POLAR_QA_LICENSE_KEY_DATA` (`envset`). Expected: key check → `set`; the $0 order is excluded from G1b by `polar_sales.py`'s `net_amount > 0` rule.
  - **App 1 QA licence** 🔒, for Task 14 Step 4's cross-product check: plan 05 Task 10 Step 9 revoked `POLAR_QA_LICENSE_KEY` in December. Same pattern on the Tegel Markdown product: discount `QA-MD-DATA`, 100%, single-use, ends 2027-02-05, never published; an unpublished checkout link with it preset; studio email, opt-in left unticked; save the key as `POLAR_QA_LICENSE_KEY` (`envset`). Expected: key check → `set`; the $0 order counts as no sale (`net_amount > 0`).
  - **Site checkout links** wait for Task 16 Step 4, so no Buy link reaches `main` before the DMG it sells: `m06-app2` merges on Fri 29 Jan, and plan 04's twice-weekly article deploys publish whatever `main` holds.
  - Commit: `Config/Release.xcconfig docs/reviews/m06.md docs/reviews/m06-polar`, `build(data): production Polar ids and BNPL evidence` + trailer.

---

### Task 13: Site pages (with plan 04)

**Files** (plan 04's page register owns these URLs and their SEO targets; this task writes the copy, front matter `app: data`, except `bundle.md`'s `app: bundle`, so plan 04's JSON-LD offers the bundle's own name and price, not Data's):
- Create: `site/content/en/data.md`, the product page. It covers the formats and free vs Pro; `{{pricing:data}}` (price and licence limits, rule 6; the "Buy Pro" link `{{checkout:data}}` comes with the download in Task 16 Step 4); and "Bundle with Tegel Markdown: {{price:bundle}} (one key per app)" (plan 04 allows prices only through config placeholders); the 14-day refund; privacy (no network except licence checks and updates; `.env` values masked); "Not affiliated with Anthropic or OpenAI"; the Task 7 Quick Look results (claim only what was observed). No demo yet: plan 04's "every internal link and asset resolves" test fails on a missing file, so Task 14 Step 5 adds the `<video>` with the file. No download link yet: `{{download:data}}` throws while `downloadURL` is empty, so Task 16 Step 4 adds it with the URL.
- Create: `site/content/en/jsonl-viewer-mac.md` (target query "jsonl viewer mac").
- Create: `site/content/en/claude-code-transcript-viewer.md` (target query "view claude code transcripts"). It explains where the transcripts live (DF9, DF10) and that the app only reads them.
- Modify: `site/config.json`. Set `apps.data.priceEUR` and `regularPriceEUR` to Task 12's confirmed EUR amount (default `"15"`, pending the user, K10), and add `"bundle": { "name": "Tegel Bundle", "page": "/bundle/", "price": "29", "regularPrice": "29", "intro": false, "priceEUR": "29", "regularPriceEUR": "29", "launchDate": "2027-02-02", "minMacOS": "14.0", "checkoutURL": "" }` (plan 04 Task 16 assigns `apps.bundle` to this plan; `launchDate` and `minMacOS` complete its JSON-LD offer). Both `checkoutURL`s stay `""` and no page uses `{{checkout:data}}` or `{{checkout:bundle}}` until Task 16 Step 4 (plan 04's `fill` throws on an empty one; with it empty, the JSON-LD offer URL falls back to the page). **No nl or fr page prices App 2 or the bundle until these EUR amounts equal Task 12's Polar price query** (`[('eur', 1500), ('usd', 1500)]`; plan 04's build throws on an empty EUR amount).
- Modify: `site/test/pages.test.js` (plan 04's file; B19).
- Create: `site/content/en/bundle.md`, for plan 04's W14 bundle row (plan 06 owns the bundle): "Both apps, one licence each, 2 Macs per app: {{price:bundle}}. Bought separately they cost {{price:markdown}} and {{price:data}}." Both prices are current and real, so there's no "was" price and no countdown (rule 6). It states the 14-day refund and "one key per app"; its Buy link `{{checkout:bundle}}` comes in Task 16 Step 4.

**Interfaces:**
- Consumes: plan 04's page register, front-matter keys, build command and sitemap (Task 0 #10).
- Produces: `/data/`, `/jsonl-viewer-mac/`, `/claude-code-transcript-viewer/`, `/bundle/` (use the register's bundle URL if it differs).

- [ ] **Step 1: Write the failing tests in plan 04's `site/test/pages.test.js`** (B19). Its site-wide invariants already cover descriptions, "was" prices and placeholders. Add `PHASES.APP2` and its "exist" test if plan 04 Task 16 hasn't yet (same line), then:

```js
test('App 2 pages carry price and licence limits from config', () => {
  expect(s.read(page('/data/'))).toContain(fill('{{pricing:data}}', 'en', config))
  const b = s.read(page('/bundle/')); expect(b).toContain(fill('{{price:bundle}}', 'en', config)); expect(b).toContain('2 Macs per app')
  expect(scan(b).ld.find(o => o['@type'] === 'SoftwareApplication')).toMatchObject({ name: 'Tegel Bundle', offers: { price: config.apps.bundle.price } }) })
test('App 2 copy makes no claim the build Mac cannot prove', () => { for (const p of PHASES.APP2)
  expect([p, /klarna|afterpay|giveaway|apple silicon ready|works on macos 2[67]/i.test(s.read(page(p)))]).toEqual([p, false]) })
```

Run `(cd site && bun test pages)`. Expected: FAIL, `APP2 pages exist` missing `/data/`.
- [ ] **Step 2: Write the four pages.** Screenshots show only synthetic fixtures (Task 9 sessions), never a real transcript. Text and code only (rule 3).
- [ ] **Step 3: Run the tests, expect PASS.** `(cd site && bun test)`. Expected: 0 fail. Watch the JSON-LD guard fail once: set `bundle.md`'s `app` to `data`, run, see `App 2 pages carry…` fail on `name: 'Tegel Data'`; revert. Then run the preview deploy (plan 04 Task 8's command; previews need no approval) and get Lighthouse SEO ≥ 95 on the 4 URLs.
- [ ] **Step 4: Commit:** `site/content/en/data.md site/content/en/jsonl-viewer-mac.md site/content/en/claude-code-transcript-viewer.md site/content/en/bundle.md site/config.json site/test/pages.test.js`, `docs(site): Tegel Data product page, two SEO pages, the bundle page, EUR prices` + trailer.

---

### Task 14: Test matrix, release candidate and demo (W14, Tue 26 – Thu 28 Jan)

**Files:**
- Modify: `scripts/release.sh` and `scripts/release_test.sh` (plan 03 owns both; this adds the `data` app).
- Create: `scripts/entitlements/data.plist` and `scripts/entitlements/data.quicklook.plist` (plan 03's allowlist, named by bundle id minus `com.tegelapps.`).
- Modify: `scripts/smoke-dmg.sh` and `scripts/test-smoke-dmg.sh` (plan 05 owns both; the Quick Look id comes from the smoked app).
- Modify: `docs/reviews/m06.md` (§ "Test matrix").

**Interfaces:**
- Consumes: plan 03's `scripts/release.sh <app> <version> [--sandbox] [--yes] [--no-upload] [--print-config] [--from-dmg <path>]` (version `X.Y.Z[-bN|-rcN]`; `--no-upload` stops after the notarised, stapled DMG and prints its path last; the `case $app` block sets `SLUG`, `SCHEME`, `NAME` and `VOL`, and under `set -u` everything after it derives from those: `DMG_NAME=$NAME-$V.dmg`, every feed and bucket path `$SLUG/…`, K7; `check_ents` diffs each signed bundle against `scripts/entitlements/<bundle id minus com.tegelapps.>.plist`); plan 05's `scripts/smoke-dmg.sh` and `scripts/test-smoke-dmg.sh`; plan 03's RC Sparkle acceptance with a locally served test feed; `POLAR_QA_LICENSE_KEY_DATA` and the re-issued `POLAR_QA_LICENSE_KEY` (Task 12 Step 3); `scripts/check-data-types.swift`; the Task 7 and 8 checklists.
- Produces: `release.sh data …`; notarised, stapled RC1 and RC2 DMGs, and matrix evidence per machine. RC1 is a `--sandbox` build: the production ids reach `Release.xcconfig` only on Thu 28 Jan (Task 12 Step 3). RC2 carries the production ids and is the installed build Task 16 Step 5 updates from; Task 16 Step 2 builds the published 1.0.0 afresh on `main`.

- [ ] **Step 1: Add the `data` app to `release.sh`, its entitlement allowlist and `smoke-dmg.sh`.**
  - Add two `release_test.sh` cases in plan 03's style (no network, no signing, no build), right after `check print-config` in the first `fresh` block, where the clone still has every `.env` key and the `REPLACE_IN_PLAN_05` line:

    ```bash
    PC_DATA=$'out=dist-release/data/1.0.0\ndmg=TegelData-1.0.0.dmg\nfeed=https://downloads.tegelapps.com/data/appcast.xml\ndownload_prefix=https://downloads.tegelapps.com/data/\nr2=$R2_BUCKET/data/'
           check data-args         1 "Config/Release.xcconfig still has REPLACE_IN_PLAN_05" data 1.0.0-rc1 --no-upload  # got past the case and every derived name under set -u
           check data-print-config 0 "$PC_DATA"   data 1.0.0 --print-config   # K7: App 2 never names App 1's feed or bucket path
    ```

  - Run `bash scripts/release_test.sh`. Expected: `FAIL data-args (exit 2): … unknown app: data`, the same for `data-print-config`, every earlier case still passing, `2 failed`.
  - Add one line to the `case $app` block, setting the same four names as plan 03's `markdown` line: `data) SLUG=data SCHEME=data NAME=TegelData VOL="Tegel Data";;`. `DMG_NAME` (`TegelData-$V.dmg`) and every path then derive after the `case`, as for App 1.
  - Re-run `bash scripts/release_test.sh`. Expected: `0 failed`, the two new cases included.
  - **Entitlement allowlist** (plan 03 Task 12 Step 3's commands with App 2's ids; a reviewed commit, never generated from `project.yml`):

    ```bash
    P=/usr/libexec/PlistBuddy; A=scripts/entitlements/data.plist; Q=scripts/entitlements/data.quicklook.plist; G=com.apple.security.temporary-exception.mach-lookup.global-name
    for k in app-sandbox files.user-selected.read-write files.bookmarks.app-scope network.client; do $P -c "Add :com.apple.security.$k bool true" "$A"; done
    $P -c "Add :$G array" -c "Add :$G: string com.tegelapps.data-spks" -c "Add :$G: string com.tegelapps.data-spki" "$A"
    $P -c "Add :com.apple.security.app-sandbox bool true" "$Q"   # plus network.client only if Task 1 kept it (G0)
    plutil -p "$A"; plutil -p "$Q"
    ```

    Expected: the app file holds exactly D5 (four keys plus the two `com.tegelapps.data-sp*` names); the Quick Look file holds Task 1's set, with no `files.absolute-path` exception (CR-4). Step 2's RC1 build is their first real check: `check_ents` stops the build on any difference.
  - **Smoke script.** Plan 05's `quicklook` check names `com.tegelapps.markdown.quicklook`, so on the build Mac, where App 1 is installed, it passes whether or not Data's extension registered.
    - Append to `test-smoke-dmg.sh` the assertion that `smoke.txt` has a line starting `FAIL quicklook` (Calculator ships only a WidgetKit extension). Run `bash scripts/test-smoke-dmg.sh`. Expected: FAIL, `smoke.txt` has `PASS quicklook` (the hard-coded id found App 1's extension).
    - In `smoke-dmg.sh`, after the install, set `QL_ID` to the `CFBundleIdentifier` of the installed app's `Contents/PlugIns/*.appex` whose `NSExtension:NSExtensionPointIdentifier` is `com.apple.quicklook.preview` (PlistBuddy), or empty if there is none. The `quicklook` check becomes `[ -n "$QL_ID" ] && pluginkit -m -v -i "$QL_ID"`, with `${QL_ID:-none}` as its detail, and the soft `pluginkit -e use` step uses `$QL_ID`.
    - Re-run it. Expected: `test-smoke-dmg: PASS`. It stays outside `make check` (GUI, K13).
  - Commit: `scripts/release.sh scripts/release_test.sh scripts/entitlements/data.plist scripts/entitlements/data.quicklook.plist scripts/smoke-dmg.sh scripts/test-smoke-dmg.sh`, `build(data): release.sh data app and allowlist; smoke id from the smoked app` + trailer. Step 2's `release.sh` needs a clean tree.
- [ ] **Step 2: Build RC1** (Tue 26 Jan) with the sandbox Polar ids. First watch the placeholder guard cover the `_DATA` keys: `scripts/release.sh data 1.0.0-rc1 --no-upload`. Expected: exit 1, `Config/Release.xcconfig still has REPLACE_IN_PLAN_05; pass --sandbox for a beta` (App 1's placeholders went in plan 05, so only Task 1's `_DATA` ones remain). Then `scripts/release.sh data 1.0.0-rc1 --sandbox --no-upload`. Expected: `spctl -a -vvv -t open --context context:primary-signature <dmg>` (plan 03's DMG check; `-t install` is for `.pkg`) prints `accepted` and `source=Notarized Developer ID`.
- [ ] **Step 3: Run the matrix.** Every row runs `check-data-types.swift`, the Quick Look matrix, `big-1m.csv` in the window, `.env` masking and the session fixtures. Licence activation runs against the sandbox: on RC1 with Task 12 Step 2's sandbox Data key, or on Debug builds.

| Machine | Evidence source |
|---|---|
| macOS 15.7 Intel | build Mac |
| macOS 14 arm64 | none: no GitHub `macos-14` runner after 2 Nov 2026, and lease L2's macOS 14 slot predates App 2 (master D11). Record `n/a: image retired`; H12 decides the minimum |
| macOS 15 arm64 | GitHub `macos-15` |
| macOS 26 arm64 | GitHub `macos-26` |
| macOS 27 arm64 | GitHub `macos-27` if Task 0 #15 found one; otherwise lease L3, one Scaleway M1 day (≈ €3.19 incl. VAT, paid from revenue, **user approval**) |

- [ ] **Step 4: Build RC2 and prove the production path** (Thu 28 Jan, after Task 12 Step 3 put the production ids in `Release.xcconfig`).
  - `scripts/release.sh data 1.0.0-rc2 --no-upload`; `spctl` as in Step 2.
  - Bound to the right product: `. scripts/lib/env.sh; [ "$(/usr/libexec/PlistBuddy -c 'Print TGPolarBenefitID' "<rc2 app>/Contents/Info.plist")" = "$(envget POLAR_BENEFIT_ID_DATA)" ] && echo bound`. Expected: `bound`.
  - **A real Data update** (K12): install RC1 in `/Applications` with no licence active (Settings › Licence › Deactivate this Mac if Step 3 activated it: RC2 validates against production, where a sandbox key doesn't exist), then run plan 03's RC Sparkle acceptance with the test feed listing RC2. Expected: "Check for Updates…" offers 1.0.0-rc2, installs it, relaunches, and About shows `1.0.0-rc2`. This exercises App 2's own Sparkle wiring (Task 8), signed feed included.
  - **Production licence:** on RC2, while it is still free (the key field only shows then), paste the `POLAR_QA_LICENSE_KEY` value (App 1's key, re-issued in Task 12 Step 3). Expected: the `wrongProduct` copy. Then paste the `POLAR_QA_LICENSE_KEY_DATA` value. Expected: Pro. Quit and relaunch: still Pro with no prompt (the stored licence and the 24 h refresh loop from plan 03).
  - Record each result in `docs/reviews/m06.md` § "RC2".
- [ ] **Step 5: Record the demo.** A silent screen recording (no audio track; captions as text) of: Quick Look on JSONL, CSV and `.env` (masked) → window paging of 1M rows → a session transcript → export → open in Tegel Markdown. Use synthetic fixtures only. Save it as `site/static/media/tegel-data-demo.mp4` (plan 05 Task 5's encoding), so plan 04's `media-src 'self'` allows a `<video>` on `data.md`; it ships with Task 16's site deploy, not to R2. Add that `<video>` (with its caption text) to `site/content/en/data.md` now; `(cd site && bun test)` → 0 fail, the asset test included.
- [ ] **Step 6: Commit:** `docs/reviews/m06.md site/static/media/tegel-data-demo.mp4 site/content/en/data.md`, `test(data): RC1 matrix, RC2 update, production licence and demo` + trailer.

---

### Task 15: Launch drafts, cross-sell copy and segment rule, and the G1b template (W14)

**Ownership:** plan 08 owns MailerLite (account since W2) and sends the cross-sell (its Task 15 Step 2). This task supplies only the cross-sell copy and the segment rule. Plan 06 opens no MailerLite account and exports no buyer list.

**Files:**
- Create, in plan 05's launch folder (Task 0 #11; default `docs/launch/`): `data-producthunt.md`, `data-reddit-macapps.md`, `data-show-hn.md`, `data-crosssell-email.md`.
- Create: `docs/gates/G1b.md`.

**Interfaces:**
- Consumes: plan 05's sales command (`scripts/polar_sales.py`) and `POLAR_PRODUCT_ID_{DATA,BUNDLE}` (G1b); the opt-in field slug `marketing_opt_in` (Task 0 #11).
- Produces: drafts **for the user to approve**; the cross-sell copy and segment rule that plan 08 Task 15 Step 2 sends.

- [ ] **Step 1: Write the drafts.** Every draft states the price ("$15 once, 2 Macs; bundle with Tegel Markdown $29"; EUR channels use Task 12's EUR amounts), read-only with no network except licence checks and updates, `.env` values masked, "not affiliated with Anthropic or OpenAI", and the silent demo link. No "was" price, no unverified claims. Per channel:
  - **Product Hunt:** tagline ≤ 60 chars, for Tue 2 Feb 00:01 PT.
  - **r/macapps:** the PCP template, "Lifetime" flair and "I'm the developer". The 30-day rule holds only if the last promotion date (Task 0 #11) + 30 days ≤ 2 Feb.
  - **Show HN:** title `Show HN: Tegel Data – read-only Mac viewer for JSONL, CSV, .env and Claude Code/Codex transcripts`, plus a first comment covering the WKWebView, CSP and RecordIndex design.
  - **Cross-sell email** (`data-crosssell-email.md`): ≤ 150 words; subject `Tegel Data: the same quiet reader, for JSON, YAML and agent transcripts`; the three Pro features; "Quick Look for JSON/YAML/CSV is free"; checkout links carry `?reference_id=email-crosssell`; the closing line "This is the only email about Tegel Data. You're getting it because you bought Tegel Markdown and ticked ‘Email me set-up tips and news about Tegel apps’ at checkout."; plan 08's footer (identity, KvK number, postal address or number: Tw 11.7 lid 7) and MailerLite's `{$unsubscribe}` link. The legal basis is the buyer's consent (Tw art. 11.7 lid 1, K9), not soft opt-in.
- [ ] **Step 2: Write the segment rule** at the top of `data-crosssell-email.md`, for plan 08:
  - Recipients = plan 08's `buyers-markdown` group as `sync_buyers.py` keeps it: App 1 buyers with a counted sale (paid or partially refunded, `net_amount > 0`) **whose order carries `marketing_opt_in == true`**, minus refunded-only buyers, minus anyone unsubscribed. An unticked box means no email (K9).
  - One send, Tue 2 Feb 09:30 CET, by plan 08 Task 15 Step 2 (user approval there). If the group is over MailerLite Free's 250 subscribers, plan 08 asks the user before sending.
  - No recipient list is exported, by this plan or into this repo.
- [ ] **Step 3: Write the G1b template.** `docs/gates/G1b.md` holds:
  - the rule: BUSINESS-PLAN §12 G1 binds only if App 1 had < 10 sales at G1 on 7 Jan (`docs/gates/G1.md`); then App 2 < 10 sales by Thu 4 Mar 2027 → stop the studio;
  - the definition: App 2 sales = the `sales=` values of plan 05's sales command, run once per product and summed (B7: one counter, so $0 QA orders never count). If plan 07 G1's `--products` has merged, one call with both ids replaces the loop:

    ```bash
    . scripts/lib/env.sh
    for k in POLAR_PRODUCT_ID_DATA POLAR_PRODUCT_ID_BUNDLE; do
      POLAR_ACCESS_TOKEN="$(envget POLAR_ACCESS_TOKEN)" POLAR_ORGANIZATION_ID="$(envget POLAR_ORGANIZATION_ID)" \
        POLAR_PRODUCT_ID_MARKDOWN="$(envget "$k")" python3 scripts/polar_sales.py --from 2027-02-02 --to 2027-03-04
    done
    ```

  - empty Result and Decision fields.
- [ ] **Step 4: Commit:** `docs/launch/data-*.md docs/gates/G1b.md`, `docs(launch): Tegel Data launch drafts, opt-in cross-sell copy and segment rule, G1b template` + trailer.

---

### Task 16: Procedure P, merge, push, release (Fri 29 Jan – Mon 1 Feb)

**Files:**
- Modify: `docs/reviews/m06.md` (pipeline sections).

Run **Procedure P (master §11)** with these deltas (B1):
- **Id and branch:** `m06`, `m06-app2`. Stage 2 runs `make fixtures` before `make check`; the counts must be ≥ the Task 0 baseline.
- **`/cso` scope (stage 4, mandatory):**
  - **Parsers:** `parse.js`, `jsonl.js`, `table.js`, `dotenv.js`, `transcript.js`, `RecordIndex`, `DataFile` (prototype pollution, alias bombs, deep nesting, unbalanced quotes, FIFO/binary/huge input; a file truncated under an open index throws, never SIGBUS).
  - **Secrets:** `.env` values absent from the DOM until clicked and never in Quick Look; PEM bodies and secret dotfiles masked whole in Quick Look; transcript view and export mask token shapes unless "Show secrets" is on, and the toggle never persists; no secret-shaped string in `Fixtures/` (Task 9 scan).
  - **Renderer:** `view.js`, the `page.js` stubs, `tegelData` range clamping, the scaled scroller, CSP unchanged, DOMPurify on every insertion. **Exported Markdown:** prose verbatim, tool I/O fenced.
  - **Session folder access and bookmarks:** the open panel, the real-home lookup, `BookmarkStore` scope start/stop, read-only use (`readonly-gate` over all of `Apps/`).
  - **Entitlements:** App = D5; Quick Look without the `/` exception; `scripts/entitlements/data*.plist` equal those sets. **Licensing and updates:** App 2's `TGPolarBenefitID` is the Data benefit in Debug and Release; plan 03's binding, `wrongProduct` deactivation and 404 grace path are unchanged; App 2's Sparkle wiring is plan 03's, with the signed-feed flags on.
  - **Release script:** the `data)` case, `SLUG=data` and its two `release_test.sh` cases (Task 14).
- **Design review shots:** Welcome, the window views, Sessions (secrets masked and revealed), the export toolbar, the Quick Look previews (a secret dotfile included) and the four site pages, in `docs/reviews/m06-design/`, with `.env` values masked in every shot.
- **Merge:** `git merge --no-ff m06-app2 -m "merge: m06"` per P stage 11.

- [ ] **Step 1: Run Procedure P** with the deltas above. Commit: `docs/reviews/m06.md docs/reviews/m06-design`, `docs(m06): pipeline results` + trailer; then merge and push per P.
- [ ] **Step 2: Build the release DMG** (Mon 1 Feb, on `main`). `scripts/release.sh data 1.0.0 --no-upload`. Expected: notarised and stapled; `spctl` accepted; the DMG path printed last. Then `APP_NAME="Tegel Data" FIXTURES=Fixtures/data INSTALL_DIR="$(mktemp -d)" scripts/smoke-dmg.sh <dmg> docs/reviews/m06-smoke` (a scratch install, so RC2 stays in `/Applications` for Step 5; check `defaults read "/Applications/Tegel Data.app/Contents/Info" CFBundleShortVersionString` → `1.0.0-rc2` afterwards) (plan 05's script, with Task 14's Quick Look id). Expected: exit 0, and `grep -c '^PASS quicklook com.tegelapps.data.quicklook' docs/reviews/m06-smoke/smoke.txt` → `1`. Commit `docs/reviews/m06-smoke` (`docs(m06): 1.0.0 smoke evidence` + trailer), then `git status --porcelain` → empty: Step 3's `--from-dmg` still runs `release.sh`'s clean-tree check (plan 03 step 2).
- [ ] **Step 3: Publish** (**user approval**; one approval covers the DMG and the appcast). `scripts/release.sh data 1.0.0 --yes --from-dmg <Step 2 path>` publishes that tested DMG with no rebuild (K7). `--yes` goes on only after that approval (plan 05 Task 10 Step 7's rule): without a terminal, the confirmation prompt reads EOF and aborts (plan 03). Expected: `curl -s https://downloads.tegelapps.com/data/appcast.xml | grep -c 'sparkle:edSignature'` → `1`, and `https://downloads.tegelapps.com/markdown/appcast.xml` is unchanged.
- [ ] **Step 4: Site keys (plan 04 CR-5).** On `content/release-data-1.0.0`, set `apps.data.version` → `"1.0.0"` and `apps.data.downloadURL` → the URL on Step 3's `published …` line in `site/config.json`, and add the download link `{{download:data}}` with "Version {{version:data}}" to `site/content/en/data.md` (Task 13 left it out while `downloadURL` was empty). The Buy links come in the same commit: set `apps.data.checkoutURL` to the `POLAR_CHECKOUT_URL_DATA` value and `apps.bundle.checkoutURL` to `POLAR_CHECKOUT_URL_BUNDLE` without printing either (`. scripts/lib/env.sh && for k in DATA BUNDLE; do grep -qF "$(envget POLAR_CHECKOUT_URL_$k)" site/config.json && echo "match $k"; done` → `match DATA`, `match BUNDLE`), put `{{checkout:data}}` next to `{{pricing:data}}` on `data.md` and `{{checkout:bundle}}` next to the price on `bundle.md`, and add to Task 13's test `expect(s.read(page('/data/'))).toContain('reference_id=site-data')` and the same for `/bundle/` with `reference_id=site-bundle`; `(cd site && bun test)` → 0 fail; run review stages 2, 3 and 9; merge, push, and deploy with plan 04's production deploy command (plan 04 Task 10 Step 2). Expected: `curl -s https://tegelapps.com/data/ | grep -cF "<downloadURL>"` ≥ 1.
- [ ] **Step 5: A real update on the production feed** (K12). On the build Mac with RC2 (Task 14) in `/Applications`: "Check for Updates…" offers 1.0.0, installs it and relaunches; About shows `1.0.0`; the QA licence is still Pro. Then download the public DMG and confirm that a Sparkle check on it finds no update. Record both in `m06.md`.
- [ ] **Step 6: Close the QA licences** 🔒. Revoke the `POLAR_QA_LICENSE_KEY_DATA` and `POLAR_QA_LICENSE_KEY` keys in the dashboard and archive the `QA-DATA` and `QA-MD-DATA` discounts and their links. Then `. scripts/lib/env.sh; for k in POLAR_QA_LICENSE_KEY_DATA POLAR_QA_LICENSE_KEY; do envset "$k" ''; [ -z "$(envget "$k")" ] && echo "gone $k"; done`. Expected: `gone POLAR_QA_LICENSE_KEY_DATA` and `gone POLAR_QA_LICENSE_KEY`.

## Launch runbook (no code; every outward action needs user approval)

- [ ] **Mon 1 Feb:** the Task 16 release is done (production products since Thu 28 Jan, Task 12 Step 3), and its Step 4 deploy put `/data/*` live with the download link; Task 12's EUR amounts are in `site/config.json` (Task 13).
- [ ] **Tue 2 Feb:** Product Hunt at 00:01 PT (09:01 CET); the cross-sell email (plan 08 Task 15 Step 2 sends it at 09:30 CET, with Task 15's copy and segment rule); r/macapps; Show HN around 15:00 CET. Each post uses the draft as approved.
- [ ] **Daily until 4 Mar:** log support minutes (§6.4: ≤ 20 min/day).
- [ ] **Thu 4 Mar 2027:** fill in `docs/gates/G1b.md` (the Task 15 sales loop, rule, decision), commit to `main`, push, and tell the user the outcome. If the stop rule fires, the studio stops (§12) through plan 07 Task G7 (Procedure S): new sales stop first, then a final build of each app keeps Pro for every stored licence with no further online checks (K14).

## W9 re-validation record

*Filled in by Task 0. One row per check in Task 0 Step 3, plus the API diff and the baseline counts.*

| # | Answer (with evidence) | Plan edits made |
|---|---|---|
| | | |

## Contract change requests

CR 1, 5 and 6, and CR-2's `files(in:extensions:limit:)`, accepted and applied to master §3.3 and §4 and to Task 8 (27 Oct); history in `docs/reviews/m00-consolidated.md`. Open:

2. **CR-2 (TegelKit `FolderIndex.search`), applied to master §3.3 and noted in plan 02 Task 4:** plan 02 Task 4 reads each file through `TextFileLoader`'s 5 MB cap, so add `maxBytesPerFile: Int = 5_000_000` to `search(_:in:limit:)` (Task 10); App 1 keeps the default, session mode passes 128 MB.
3. **CR-3 (TegelKit and renderer additions):** Swift `DataFormat`, `DataFile`, `DataFileError`, `RecordIndex`, `RecordIndexError`, `DataIssue`, `DataRenderResult`, `RendererWebView.renderData(…)`, `RendererWebView.renderPaged(…)` and the `tegelData` reply handler. JS `window.tegel.renderData`, `openPaged`, `transcriptMarkdown({ reveal })`, and `maskSecrets` (K12). Swift `DataFile.secretFile`, `DataFile.isSecret(filename:)`, `RecordIndexError.truncated`. Layout: §3.1 gains `Renderer/src/data/` and `src/css/data.css`; the bundle gains `data.js`.
4. **CR-4 (D5, narrowing):** the Data Quick Look extension omits `temporary-exception.files.absolute-path.read-only = /`. That exception exists only for Markdown's local images, and data files load none.
<!-- numbers kept, so cross-plan references resolve -->
7. **CR-7 (§3.4 fixtures):** add `Fixtures/data/`: committed `sample.*`, `hostile.*`, `quoted-newline.csv` and `sessions/`. `make fixtures` generates `big-200mb.jsonl` and `big-1m.csv` (gitignored `Fixtures/data/big-*`).
