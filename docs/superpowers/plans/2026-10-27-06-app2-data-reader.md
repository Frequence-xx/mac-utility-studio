# Tegel Data (App 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship Tegel Data 1.0.0, a read-only JSON/JSONL/YAML/TOML/CSV/TSV/`.env` reader. It has a free Quick Look pack and a Pro window with session-transcript mode and Markdown export. Notarised by Mon 1 Feb 2027, launched Tue 2 Feb 2027.

**Architecture:**
- **Renderer:** data views are pure JS functions in `Renderer/src/data/` that return escaped HTML strings, bundled as a lazily loaded `data.js` inside the same CSP page and DOMPurify path as Markdown.
- **TegelKit** gains `DataFormat`/`DataFile` (routing, capped loading), a memory-mapped `RecordIndex`, and a `renderData`/`renderPaged` bridge. The window pages through 200 MB files over a reply-message handler; Quick Look renders a capped prefix.
- **Apps:** `Apps/Data/{App,QuickLook}` are thin shells: routing, the `isPro` gate, session folders via `BookmarkStore`, export through a save panel.

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

- **Platform:** macOS 14.0 deployment target; universal binary; Swift 6 language mode; sandboxed (D5).
- **Bundle ids:** `com.tegelapps.data` and `com.tegelapps.data.quicklook` (D7).
- **Read-only:** the apps never write to user files. The only writes are a Markdown export to a save-panel URL and the app's own container (§5 rule B).
- **Network:** none except Polar licence calls and Sparkle. The renderer CSP is unchanged: no `connect-src`.
- **`.env`:** values masked by default and revealed per click in the window only. They never appear in any Quick Look DOM and are never sent anywhere.
- **Untrusted input:** every string is escaped by our code **and** the result goes through the page's DOMPurify sanitiser.
- **Pricing:** $15 once, 2 Macs. Bundle $29 grants both licences. Licence limits are stated before purchase. No "was" price. 14-day refund (rule 6).
- **Free tier:** Quick Look for every format.
- **Pro tier:** window viewer, `.env` viewer, session mode, export (§6.2).
- **UI languages:** EN, NL, FR, AR in all tiers (D6).
- **Fixtures:** synthetic and secret-free. Never copy a real transcript. Fixture filenames must not be `.env` or `.env.*`, because `.gitignore` ignores both.
- **Quick Look limits:** reads ≤ 2 MB and shows ≤ 500 JSONL records or 1,000 CSV/TSV rows. It answers in < 2 s.
- **Machines:**
  - Commands run on the build Mac: Intel, macOS 15.7, Xcode 26.3, Swift 6.2.4. `bun` is at `~/.local/bin/bun`; `xcodegen` is at `~/.local/bin/xcodegen`.
  - arm64 and macOS 26/27 evidence always names its machine: GitHub `macos-14`/`macos-15`/`macos-26`, or the Scaleway M1 on macOS 27.
- Product rules 1–9 apply. Outward-facing actions need the user's approval (H11).

## Review Focus

1. **A CSV with an unbalanced quote** (`"abc` never closed at row 10 of 1M rows). Expect the index not to swallow the rest of the file into one record: it falls back to line records and shows a banner. *Task 5, `testUnbalancedQuoteFallsBackToLines`.*
2. **A huge extension-less binary, or a FIFO, previewed with Space in Finder.** Expect Quick Look to return to the system's generic preview in < 2 s, without decoding garbage or blocking. *Task 5: `testBinaryRejected`, `testFIFORejected`, `testReadsPrefixOnly`.*
3. **A UTF-16 (BOM) CSV or JSONL opened in the window.** Expect correct text through the capped whole-text path, not mojibake rows. *Task 5: `testUTF16BOMThrows` + `testUTF16LoadsAsText`.*
4. **Integers above 2^53 in JSON or TOML** (snowflake ids). Expect exact digits or a visible "≈", never a silently rounded id. *Task 2, `big integers stay exact or are marked`.*
5. **Commented-out secrets in `.env` (`# API_KEY=…`) and `.envrc` files.** Expect those values masked too, and error rows that never echo the raw line. *Task 4 tests; `.envrc` routing in Task 5.*

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
Packages/TegelKit/Tests/TegelKitTests/ DataFileTests.swift, DataRenderTests.swift (+FolderIndexTests)
Apps/Data/App/AppIcon.icon/            plan 09's Data icon (D-5)
Fixtures/data/            sample.*, quoted-newline.csv, hostile.*, sessions/…, generate.js (big-* generated)
scripts/check-data-types.swift
site/content/en/          data.md, jsonl-viewer-mac.md, claude-code-transcript-viewer.md, bundle.md (plan 04's URLs)
docs/launch/data-*.md, docs/gates/G1b.md, docs/reviews/m06.md
Modified: project.yml, Config/{Debug,Release}.xcconfig, Makefile, .gitignore, .env.example,
          scripts/{release.sh,release_test.sh},
          Renderer/{package.json,bun.lock,build.js,src/page.js}, TegelKit Resources/Renderer (generated)
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
| 5 | Does `scroll(toHeading:)` use `getElementById` (so `id="L<line>"` works)? Is `RenderOptions` given a public `init(mode:theme:baseURL:)`? | `grep -n 'getElementById\|public init' Packages/TegelKit/Sources/TegelKit/*.swift` | Tasks 6, 10 |
| 6 | Does TegelStore send `benefit_id` on validate and check `license_key.benefit_id` on activate (plan 03, D1)? If not, stop and ask the user: no Data product goes live without it. | `grep -rn benefit Packages/TegelKit/Sources/TegelStore` | Task 12 |
| 7 | App 1's patterns:<br>• opening a file from Finder (`application(_:open:)` or `WindowGroup(for: URL.self)`);<br>• the `ProGate.swift` and `LicenceSettingsView.swift` paths, and the Debug override;<br>• the localisation format (`.xcstrings`) | `ls Apps/Markdown/App; grep -rn 'onOpenURL\|open urls\|WindowGroup' Apps/Markdown/App` | Tasks 1, 8 |
| 8 | `page.js`:<br>• the lazy script-loader function (the Mermaid one);<br>• the sanitise function and DOMPurify config;<br>• whether an escape helper is exported;<br>• the content container id;<br>• the test framework (XCTest or Swift Testing) and whether there's a DOM test helper | `grep -nE 'function \|export ' Renderer/src/page.js Renderer/src/markdown.js; ls Packages/TegelKit/Tests/TegelKitTests` | Tasks 2, 6 |
| 9 | `scripts/release.sh`:<br>• the `<app>` values;<br>• the RC/no-upload flag;<br>• the appcast and DMG URL layout;<br>• how pre-release versions are named | `sed -n 1,80p scripts/release.sh` | Tasks 1, 14, 16 |
| 10 | Site: content front-matter keys; App 1 page URL; build and preview-deploy commands; how the sitemap picks up new pages | `ls site/content/en; sed -n 1,40p site/build.js` | Tasks 11, 13 |
| 11 | Polar and launch history:<br>• slug of the checkout **opt-out custom field** on the App 1 product;<br>• date of the last r/macapps promotion;<br>• folder of the App 1 launch drafts | `grep -rn 'custom_field\|opt' docs/launch docs/reviews 2>/dev/null \| head` + Polar dashboard | Task 15 |
| 12 | Path of the third-party notices file | `grep -rln 'DOMPurify' --include='*.md' --include='*.txt' . \| grep -v node_modules` | Task 2 |
| 13 | How the `make fixtures` target and the generated-fixture `.gitignore` lines are written | `grep -n 'fixtures' Makefile .gitignore` | Task 3 |
| 14 | Newest js-yaml / smol-toml / papaparse release that is ≥ 14 days old | `for p in js-yaml smol-toml papaparse; do npm view $p time --json \| tail -4; done` | Task 2 |
| 15 | Does a GitHub `macos-27` runner image exist? | `curl -s https://raw.githubusercontent.com/actions/runner-images/main/README.md \| grep -n 'macos-2[67]'` | Task 14 |

- [ ] **Step 4: Baseline.** Run `make check`. Expected: PASS. Record the JS/Swift/build pass counts in the record.
- [ ] **Step 5: Commit** (no product code is written before this commit exists):

```bash
git add docs/superpowers/plans/2026-10-27-06-app2-data-reader.md
git commit -m "docs(m06): re-validate plan 06 against shipped TegelKit/TegelStore

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 1: Targets, UTTypes and entitlements

**Files:**
- Modify: `project.yml`. Add targets `data` (application) and `data.quicklook` (app-extension, embedded in `data`), following plan 01's naming, so the bundle ids are `com.tegelapps.data` and `com.tegelapps.data.quicklook` (D7) and the extension id is prefixed by the app id. Set `PRODUCT_NAME: Tegel Data` on `data` and `PRODUCT_NAME: DataQuickLook` on `data.quicklook`, so the `.appex` path below holds. Set `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` on `data` (plan 09 CR-10). Both compile `Apps/Data/Shared/`. Add `data` to the Makefile `build` scheme list if `build` lists schemes.
- Create: `Apps/Data/App/{Info.plist,Data.entitlements,DataApp.swift}`, and `Apps/Data/App/AppIcon.icon/` from plan 09's D-5 Data pick (Manganese ground). Plan 09's icon guard in `make check` covers it.
- Create: `Apps/Data/QuickLook/{Info.plist,DataQuickLook.entitlements,PreviewProvider.swift}`. `PreviewProvider` is a stub that returns the file's first 2 KB as plain text.
- Create: `Apps/Data/Shared/{DataLabels.swift,Localizable.xcstrings}`, holding `enum DataLabels { static var all: [String: String] }`, the localised strings passed to JS.
- Create: `scripts/check-data-types.swift`.
- Modify: `Config/Debug.xcconfig` and `Config/Release.xcconfig`. Add `TG_POLAR_CHECKOUT_URL_DATA` and `TG_POLAR_BENEFIT_ID_DATA` (sandbox values beside plan 03's sandbox values, production values in Release, filled in Task 12).
- Modify: `.env.example`. Add `POLAR_PRODUCT_ID_{DATA,BUNDLE}`, `POLAR_BENEFIT_ID_DATA`, `POLAR_CHECKOUT_URL_DATA`, `POLAR_SANDBOX_CHECKOUT_URL_DATA`, `POLAR_CHECKOUT_URL_BUNDLE`. The `_MARKDOWN` keys already exist (plan 05), and MailerLite keys are plan 08's.

**Interfaces:**
- Consumes: `options.bundleIdPrefix: com.tegelapps` (D7), the TG* xcconfig variable names (Task 0 #9), D5 entitlements, and the G0 decision (Task 0 #1).
- Produces: bundle ids `com.tegelapps.data` and `com.tegelapps.data.quicklook`, product name `Tegel Data`; Info.plist keys `TGPolarAPIBase`, `TGPolarOrganizationID`, `TGPolarCheckoutURL`, `TGPolarPortalURL` (D16) plus `TGPolarBenefitID` (plan 03, D1); `SUFeedURL` = `https://downloads.tegelapps.com/data/appcast.xml` (layout per Task 0 #9), `SUPublicEDKey` (App 1's key), `SUEnableInstallerLauncherService` = YES [F4]; and `swift scripts/check-data-types.swift <DataQuickLook.appex/Contents/Info.plist>`, which exits 0 when every expectation holds.

Type declarations (App `Info.plist`, `UTImportedTypeDeclarations`, per DF3: these are formats the system doesn't declare):

| UTTypeIdentifier | Extensions | ConformsTo | MIME |
|---|---|---|---|
| `com.tegelapps.jsonl` | `jsonl`, `ndjson` | `public.text` (not `public.json`: a JSONL file isn't one JSON document) | `application/jsonl`, `application/x-ndjson` |
| `com.tegelapps.toml` | `toml` | `public.text` | `application/toml` |
| `com.tegelapps.dotenv` | `env` | `public.text` (not `public.plain-text`, so the system text previewer doesn't claim it [DF4, DF5]; verified by the Task 7 matrix) | none |

The system types are referenced by identifier and never redeclared (DF3): `public.json`, `public.yaml`, `public.comma-separated-values-text`, `public.tab-separated-values-text` (DF1), and `public.ndjson` (DF2).

- **`CFBundleDocumentTypes`:** one entry, role `Viewer`, `LSHandlerRank` `Alternate` (we never take over the default app). `LSItemContentTypes` holds the 4 DF1 types plus `public.ndjson`, `public.toml`, and the 3 imported types.
- **`QLSupportedContentTypes`:** the same list plus **`public.data`** (the extension-less text path, DF5). `QLIsDataBasedPreview` follows G0.
- **Entitlements:**
  - App: exactly D5 (`app-sandbox`, `files.user-selected.read-write`, `files.bookmarks.app-scope`, `network.client`, and the Sparkle mach-lookup exception for `$(PRODUCT_BUNDLE_IDENTIFIER)-spks` and `-spki`).
  - Quick Look extension: `app-sandbox`, plus `network.client` if G0 kept it. **No** `temporary-exception.files.absolute-path.read-only` (CR-4).

- [ ] **Step 1: Write the failing check.** `scripts/check-data-types.swift` writes `x.json x.yaml x.yml x.csv x.tsv x.jsonl x.ndjson x.toml prod.env .env Dockerfile CHANGELOG` into a temp dir. For each file it reads `URLResourceValues.contentType` and asserts that the identifier is in its allowed set **and** in the appex's `QLSupportedContentTypes`:
  - `.jsonl` → {`com.tegelapps.jsonl`}; `.ndjson` → {`public.ndjson`, `com.tegelapps.jsonl`}; `.toml` → {`com.tegelapps.toml`, `public.toml`};
  - `prod.env` → {`com.tegelapps.dotenv`}; `.env`, `Dockerfile`, `CHANGELOG` → {`public.data`, `com.tegelapps.dotenv`}; the four system types → their DF1 identifier.

  It prints one `name → identifier ✓/✗` line per file and exits 1 on any ✗.
- [ ] **Step 2: Run it, expect FAIL.** `swift scripts/check-data-types.swift /dev/null`. Expected: FAIL with `x.jsonl → dyn.ah62d4rv4ge80y65tr30a ✗`.
- [ ] **Step 3: Implement the targets.** Add the two targets, plists, entitlements, the icon and xcconfig keys listed above. `DataApp.swift` is an empty `WindowGroup` for now.
- [ ] **Step 4: Build, register, run, expect PASS.**

```bash
xcodegen generate && make build
xcodebuild -scheme data -showBuildSettings | grep -c 'PRODUCT_BUNDLE_IDENTIFIER = com.tegelapps.data$'
xcodebuild -target data.quicklook -showBuildSettings | grep -c 'PRODUCT_BUNDLE_IDENTIFIER = com.tegelapps.data.quicklook$'
BUILT=$(xcodebuild -scheme data -showBuildSettings 2>/dev/null | awk '/ BUILT_PRODUCTS_DIR /{print $3}')
/usr/libexec/PlistBuddy -c 'Print CFBundleIconName' "$BUILT/Tegel Data.app/Contents/Info.plist"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$BUILT/Tegel Data.app"
swift scripts/check-data-types.swift "$BUILT/Tegel Data.app/Contents/PlugIns/DataQuickLook.appex/Contents/Info.plist"
codesign -d --entitlements - --xml "$BUILT/Tegel Data.app/Contents/PlugIns/DataQuickLook.appex" | plutil -p - | grep -c absolute-path
```

Expected: the two bundle-id checks print `1` each (bundle ids are permanent after W14); `CFBundleIconName` prints `AppIcon`; every type line ✓, exit 0. The last command prints `0`.
- [ ] **Step 5: Remote type matrix.** Run the same script on `macos-14`, `macos-15` and `macos-26` through `gh workflow run ci.yml --ref m06-app2` (needs the user's `gh auth login`), and on macOS 27 per Task 14. Record each OS's actual identifiers in `docs/reviews/m06.md` § "UTType matrix". The open questions are whether macOS 14 has `public.ndjson` and whether 26/27 declare `public.toml`.
- [ ] **Step 6: Commit.**

```bash
git add project.yml Makefile Apps/Data Config/Debug.xcconfig Config/Release.xcconfig .env.example scripts/check-data-types.swift docs/reviews/m06.md
git commit -m "feat(data): add Tegel Data app and Quick Look targets with UTType declarations

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Tree views for JSON, YAML and TOML

**Files:**
- Modify: `Renderer/package.json` and `Renderer/bun.lock`, via `cd Renderer && bun add --exact js-yaml@5.5.0 smol-toml@1.9.1 papaparse@5.7.0` (versions per Task 0 #14).
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
export function treeHTML(value, opts = { budget: 2000, path: '', labels: DEFAULT_LABELS }) // -> { html: string, used: number }
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
    - **json:** `JSON.parse` with a reviver that returns `BigInt(ctx.source)` for unsafe integers when `ctx?.source` exists [DF7]. JSC errors carry no position, so on failure (if `text.length ≤ 5_000_000`) it gets the line by running js-yaml `load` on the same text (YAML is a JSON superset). If YAML parses, the message is `labels.invalidJSONValidYAML` with no line.
    - **yaml:** js-yaml `load`; line = `e.mark.line + 1`. **toml:** smol-toml `parse(text, { integersAsBigInt: 'asNeeded' })`, default `unsafeKeyBehaviour: 'keep'` (show the file truthfully); line from `TomlError`.
  - **`treeHTML`:** objects and arrays become `<details data-path>` + `<summary>` (root open), recursing until `budget` nodes are used, then childless `<details data-lazy>`. Arrays over 1,000 items are chunked into `[0…999]` groups. Strings render as `<span class="s" dir="auto">`; unsafe integers get an `≈` prefix; BigInt renders exactly. Keys come from `Object.keys` with direct reads: never spread or `Object.assign` parsed values [DF8].
- [ ] **Step 4: Run it, expect PASS.** `cd Renderer && bun test test/data-tree.test.js`. Expected: 7 pass, 0 fail.
- [ ] **Step 5: Commit.**

```bash
git add Renderer/package.json Renderer/bun.lock Renderer/src/data/labels.js Renderer/src/data/parse.js Renderer/src/data/tree.js Renderer/test/data-tree.test.js <notices file>
git commit -m "feat(renderer): JSON/YAML/TOML tree with error lines and node budget

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: JSONL rows, CSV/TSV tables and big fixtures

**Files:**
- Create: `Renderer/src/data/jsonl.js`, `Renderer/src/data/table.js`.
- Test: `Renderer/test/data-rows.test.js`.
- Create: `Fixtures/data/generate.js`, and committed `Fixtures/data/{sample.json,sample.jsonl,sample.yaml,sample.toml,sample.csv,sample.tsv,quoted-newline.csv}`. `quoted-newline.csv` is a header plus 3 records; record 2 has a quoted CRLF newline and `""` escapes.
- Modify: `Makefile` (`fixtures` target runs `bun Fixtures/data/generate.js Fixtures/data`), `.gitignore` (`Fixtures/data/big-*`).

**Interfaces:**
- Consumes: `escapeHTML` and `treeHTML` (Task 2); `Papa.parse` (papaparse).
- Produces:

```js
// jsonl.js
export function parseJSONLLine(text) // -> { ok: true, value } | { ok: false, message }
export function jsonlRowHTML(lineNo, text, labels) // -> '<div class="row" data-line="N">…</div>'; bad -> class "row bad"
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
- [ ] **Step 5: Commit.**

```bash
git add Renderer/src/data/jsonl.js Renderer/src/data/table.js Renderer/test/data-rows.test.js Fixtures/data Makefile .gitignore
git commit -m "feat(renderer): JSONL rows, CSV/TSV tables, header detection, big fixtures

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: `.env` parsing with masking

**Files:**
- Create: `Renderer/src/data/dotenv.js`, `Fixtures/data/sample.env` (synthetic values only, e.g. `not-a-real-secret-1`).
- Test: `Renderer/test/data-dotenv.test.js`.

**Interfaces:**
- Consumes: `escapeHTML`, `DEFAULT_LABELS` (Task 2).
- Produces:

```js
export function parseDotenv(text)
  // -> { entries: [{ line, key, value, exported: boolean, commented: boolean }], comments: [{ line, text }], errors: [{ line, message }] }
export function envHTML(parsed, labels = DEFAULT_LABELS)
  // -> string. Values NEVER appear. Each value is <button class="secret" data-i="k" aria-label="…">••••••••</button> (always 8 bullets)
```

Parsing rules:
- Strip a BOM; CRLF and LF both end a line (and become `\n` inside multiline values). Optional `export ` prefix; KEY matches `[A-Za-z_][A-Za-z0-9_.-]*`, then `=` with optional spaces.
- `'…'` is literal; `"…"` may span lines, with `\n \t \" \\` escapes; a backtick value is literal and may span lines; an unquoted value is trimmed and ` #…` ends it.
- A `#` line whose remainder is an assignment becomes an entry with `commented: true` (masked); any other `#` line is a comment. An unterminated quote is an error at its opening line, and parsing resumes on the next line. Error messages never include the raw line.

- [ ] **Step 1: Write the failing test.**

```js
import { test, expect } from 'bun:test';
import { parseDotenv, envHTML } from '../src/data/dotenv.js';
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
test('hostile comments are escaped', () => {
  expect(envHTML(parseDotenv('# <img src=x onerror=1>\nK=v'))).not.toContain('<img');
});
```

- [ ] **Step 2: Run it, expect FAIL.** `cd Renderer && bun test test/data-dotenv.test.js`. Expected: FAIL, `Cannot find module '../src/data/dotenv.js'`.
- [ ] **Step 3: Implement `parseDotenv` and `envHTML`.** A single line-cursor loop that applies the rules above. `envHTML` emits keys, comments and error rows from `parsed`, and only the index `k` for each value.
- [ ] **Step 4: Run it, expect PASS.** `cd Renderer && bun test test/data-dotenv.test.js`. Expected: 4 pass.
- [ ] **Step 5: Commit.**

```bash
git add Renderer/src/data/dotenv.js Renderer/test/data-dotenv.test.js Fixtures/data/sample.env
git commit -m "feat(renderer): .env parser with values masked out of the HTML

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: File access in TegelKit (`DataFormat`, `DataFile`, `RecordIndex`)

**Files:**
- Create: `Packages/TegelKit/Sources/TegelKit/DataFile.swift`.
- Test: `Packages/TegelKit/Tests/TegelKitTests/DataFileTests.swift` (XCTest, or whatever Task 0 #8 found).

**Interfaces:**
- Consumes: `TextFileLoader.load(_:maxBytes:) -> LoadedText` (UTF-8 → BOM UTF-16 → Windows-1252).
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
    public static func load(_ url: URL, maxBytes: Int) throws -> DataFile
    // regular file only; UTF-16 BOM -> text; else a NUL byte in the first 8 KiB -> .binary;
    // format = DataFormat(filename:) ?? .text; truncated jsonl/csv/tsv are cut at the last newline
}
public enum RecordIndexError: Error, Equatable { case utf16 }
public final class RecordIndex: Sendable {
    public init(url: URL, quoteAware: Bool) throws   // mmap; UTF-8 BOM skipped; UTF-16 BOM -> throws .utf16
    public var count: Int { get }
    public let quoteRunaway: Bool                    // a quoted record passed 1 MB -> rebuilt line-based
    public func records(in range: Range<Int>) -> [String]   // range clamped to 0..<count; trailing "\r" stripped; lossy UTF-8
}
```

- [ ] **Step 1: Write the failing tests.** Each one writes into `FileManager.default.temporaryDirectory`.
  - **`testRouting`:** `.env`, `.env.local`, `prod.env` and `.envrc` give `.dotenv`; `x.NDJSON` gives `.jsonl`; `Dockerfile` gives `nil`.
  - **`testBinaryRejected`:** the bytes `[0x41, 0x00, 0x42]` throw `.binary`.
  - **`testUTF16LoadsAsText`:** a UTF-16LE BOM `{"a":1}` loads with format `.json` and text `{"a":1}`.
  - **`testFIFORejected`:** `mkfifo(path, 0o600)` throws `.notRegularFile` within 0.5 s, with no hang.
  - **`testReadsPrefixOnly`:** 50 MB of `"x\n"` loaded with `maxBytes: 2_000_000` finishes in < 0.5 s, with `truncated == true` and the text ending in `"\n"`.
  - **`testLinesCRLFAndBOM`:** `"\u{FEFF}a\r\nb\nc\n"` gives `count == 3` and `records(in: 0..<3) == ["a","b","c"]`.
  - **`testQuotedNewlineCSV`:** `Fixtures/data/quoted-newline.csv` with `quoteAware: true` gives `count == 4`, and `records(in: 2..<3)[0]` contains `"\n"`.
  - **`testUnbalancedQuoteFallsBackToLines`:** `"a,b\n\"open,1\n"` followed by 20,000 lines of `x,y` gives `quoteRunaway == true` and `count == 20_002`.
  - **`testUTF16BOMThrows`:** bytes `FF FE 61 00` throw `RecordIndexError.utf16`.
  - **`testRangeClamped`:** on a 3-record file, `records(in: 1..<10).count == 2` and `records(in: 5..<9) == []`.
  - **`testBigFixtures`:** `XCTSkip` if `Fixtures/data/big-1m.csv` is missing. Otherwise the CSV gives `count == 1_000_001` in < 3 s and `big-200mb.jsonl` gives `count == <records printed by generate.js>` in < 4 s. Record both timings on the build Mac (Intel).
- [ ] **Step 2: Run them, expect FAIL.** `swift test --package-path Packages/TegelKit --filter DataFileTests`. Expected: FAIL to compile, `cannot find 'DataFile' in scope`.
- [ ] **Step 3: Implement.**
  - `DataFile.load`: check `resourceValues(forKeys: [.isRegularFileKey])` first, then read a prefix through `TextFileLoader.load(url, maxBytes:)`. If Task 0 #2 found that it reads the whole file, read the prefix with `FileHandle.read(upToCount:)` instead.
  - `RecordIndex`: `Data(contentsOf:options: .alwaysMapped)`. In line mode, `memchr` for `\n`. In quote mode, a byte loop that toggles on `0x22` (this handles `""` too). Store record starts in `[Int]`.
- [ ] **Step 4: Run them, expect PASS.** `make fixtures && swift test --package-path Packages/TegelKit --filter DataFileTests`. Expected: 11 pass, 0 skipped.
- [ ] **Step 5: Commit.**

```bash
git add Packages/TegelKit/Sources/TegelKit/DataFile.swift Packages/TegelKit/Tests/TegelKitTests/DataFileTests.swift
git commit -m "feat(tegelkit): DataFormat routing, capped DataFile loading, mmap RecordIndex

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: DOM view, Swift bridge and WebKit tests

**Prerequisite:** read `DESIGN.md`; no UI value outside it (`data.css` takes its tokens from DESIGN.md §7).

**Files:**
- Create: `Renderer/src/data/view.js` and `Renderer/src/css/data.css`.
- Modify: `Renderer/build.js` (a new entry, `src/data/view.js` → `data.js`, and copy `data.css`).
- Modify: `Renderer/src/page.js`. Add stubs `window.tegel.renderData`, `openPaged` and `transcriptMarkdown`; they load `data.js` once through the Mermaid script loader (Task 0 #8). The CSP doesn't change.
- Create: `Packages/TegelKit/Sources/TegelKit/DataRender.swift`.
- Create: `Fixtures/data/hostile.{json,jsonl,yaml,toml,csv,env}`. Each embeds `<img src=x onerror="window.__pwned=1">`, `<script>window.__pwned=1</script>`, `"><svg onload=window.__pwned=1>` and `javascript:window.__pwned=1` in keys and values.
- Regenerate: `Packages/TegelKit/Sources/TegelKit/Resources/Renderer/` (`make renderer`).
- Test: `Packages/TegelKit/Tests/TegelKitTests/DataRenderTests.swift`.

**Interfaces:**
- Consumes: Tasks 2–5; `RendererWebView.webView`, `RenderOptions`, and the page's sanitise function.
- Produces (CR-3):

```js
window.tegel.renderData(text, { format, mode, theme, labels, truncated }) // -> Promise<{ ms, records, errors: [{ line, message }] }>
window.tegel.openPaged({ format, count, quoteRunaway, mode, theme, labels }) // -> Promise<same>
//   pulls records with: await webkit.messageHandlers.tegelData.postMessage({ from, count }) -> string[]
window.tegel.transcriptMarkdown() // -> string (Task 9 fills it)
```

```swift
public struct DataIssue: Sendable, Hashable, Decodable { public let line: Int; public let message: String }
public struct DataRenderResult: Sendable, Decodable { public let ms: Double; public let records: Int; public let errors: [DataIssue] }
extension RendererWebView {
    public func renderData(_ text: String, format: DataFormat, options: RenderOptions,
                           labels: [String: String] = [:], truncated: Bool = false) async throws -> DataRenderResult
    public func renderPaged(_ index: RecordIndex, format: DataFormat, options: RenderOptions,
                            labels: [String: String] = [:]) async throws -> DataRenderResult
}
```

View rules:
- **Every insertion** goes through the page's sanitise function. Paged window list: fixed 22 px rows, 200 rows of overscan, 500-record pages, ≤ 20 cached pages. CSV/TSV run `detectHeader` on the first 51 records (a header checkbox overrides it). A JSONL row click renders its `treeHTML` in a detail pane; `details[data-lazy]` is filled on `toggle` from `nodeAt`.
- **`.env` reveal:** in `mode === 'window'`, clicking `.secret` toggles that one value from the in-memory entries. In `quicklook` mode there's no handler and the values are dropped after render.
- **Quick Look caps:** in `quicklook` mode, JSONL/CSV/TSV render statically, capped at 500 records or 1,000 rows, with a `labels.truncated` banner (also shown for `truncated: true`).
- **Swift side:** `renderData` uses `webView.callAsyncJavaScript(… arguments:, contentWorld: .page)`. `renderPaged` swaps in a `WKScriptMessageHandlerWithReply` named `tegelData` (macOS 11+) that clamps `from ≥ 0` and `count ≤ 2000`.

- [ ] **Step 1: Write the failing tests** (`@MainActor final class DataRenderTests: XCTestCase`, real WKWebView).
  - **`testHostileStringsNeverExecute`:** for each `hostile.*`, `DataFile.load(url, maxBytes: 2_000_000)` then `renderData` (mode `.window`). Assert `evaluateJavaScript("String(window.__pwned)") == "undefined"`, `document.querySelectorAll('#doc img,#doc script,#doc svg,#doc iframe,#doc a[href^=javascript]').length == 0`, and the `#doc` innerText contains `<script>` (so the container exists and the empty-query assertions aren't vacuous).
  - **`testDotenvMaskedUntilClicked`:** render `sample.env` in `.window`. `documentElement.outerHTML` contains none of its values; after `document.querySelector('.secret').click()`, exactly the first value appears and the second doesn't.
  - **`testDotenvQuickLookNeverReveals`:** the same in `.quicklook`. After the click, no value appears.
  - **`testYAMLErrorLine`:** the bad YAML from Task 2 gives `errors.first?.line == 4`, and `document.querySelector('mark.err') != null`.
  - **`testPaged1MRows`:** `XCTSkip` without the fixture. `renderPaged(RecordIndex(url: big-1m.csv, quoteAware: true), format: .csv, …)` returns `records == 1_000_001` in < 2 s (timed after the index is built). After `document.scrollingElement.scrollTop = 1e9` and 500 ms, the last visible row's first cell is `"999999"`.
- [ ] **Step 2: Run them, expect FAIL.** `swift test --package-path Packages/TegelKit --filter DataRenderTests`. Expected: FAIL to compile, `value of type 'RendererWebView' has no member 'renderData'`.
- [ ] **Step 3: Implement** `view.js`, `data.css`, the `build.js` entry, the `page.js` stubs and `DataRender.swift`. Then run `make renderer` to regenerate the committed bundle.
- [ ] **Step 4: Run them, expect PASS.** `make fixtures && swift test --package-path Packages/TegelKit --filter DataRenderTests && (cd Renderer && bun test)`. Expected: 5 pass, and the existing JS suite still passes (CSP and Markdown tests unchanged).
- [ ] **Step 5: Commit.**

```bash
git add Renderer/src/data/view.js Renderer/src/css/data.css Renderer/build.js Renderer/src/page.js Packages/TegelKit/Sources/TegelKit/DataRender.swift Packages/TegelKit/Sources/TegelKit/Resources/Renderer Packages/TegelKit/Tests/TegelKitTests/DataRenderTests.swift Fixtures/data/hostile.*
git commit -m "feat(tegelkit): data view bridge with paging, masking and hostile-input tests

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Quick Look extension (free tier) and the extension-less text path

**Prerequisite:** read `DESIGN.md`; no UI value outside it.

**Files:**
- Modify: `Apps/Data/QuickLook/PreviewProvider.swift`.

**Interfaces:**
- Consumes: `DataFile.load(_:maxBytes:)`, `RendererWebView.renderData(…, options: RenderOptions(mode: .quicklook, theme: .paper, baseURL: nil), labels: DataLabels.all, truncated:)`, and the G0 reply mechanism used in `Apps/Markdown/QuickLook` (Task 0 #1).
- Produces: a preview for every `QLSupportedContentTypes` entry. It throws for `DataFileError`, so Quick Look shows its generic preview.

**Extension-less text decision** (DF2, DF5):
- **Claimed:** `public.data`, which reaches only files typed exactly `public.data` (`Dockerfile`, `CHANGELOG`, `.gitignore`, `.zshrc`, `.env`, …). Binaries are rejected by the NUL-byte sniff before any decoding, so Quick Look falls back to its generic preview. `README`, `LICENSE` and `Makefile` are already `public.plain-text`/`public.make-source` on 15.7; the system previews them and we don't touch them.
- **Cut:** `.env.local` and other `.env.*` files resolve to `dyn.*` (their "extension" is `local`). Catching them would mean declaring `local`, `production`, … for every file on the Mac, so they are **not** previewed in Quick Look. The window opens them by name (Task 5 routing).
- **Tests:** Quick Look dispatch can't be asserted from a unit test, so the Step 4 matrix is the test. The sniff and the caps are unit-tested in Task 5.

- [ ] **Step 1: Run the matrix before implementing, and record it.** `qlmanage -r && qlmanage -r cache`, then `qlmanage -p <file>` for each row below, using temp copies only, **never the repo's real `.env`**. Expected now: the Task 1 stub (plain text, no masking) for our types. That's the failing state.
- [ ] **Step 2: Implement `providePreview(for:)`.** `DataFile.load(request.fileURL, maxBytes: 2_000_000)`, then render through the G0 mechanism with `truncated: file.truncated`, adding a one-line "Tegel Data" footer so the matrix can tell our previewer from the system's.
- [ ] **Step 3: Build.** `make build`, then `pluginkit -m -v -p com.apple.quicklook.preview | grep com.tegelapps.data.quicklook`. Expected: one line with the build path.
- [ ] **Step 4: Run the matrix (build Mac, macOS 15.7, Intel), expect PASS.** Each preview must appear in < 2 s.

| File (temp copy) | Expected |
|---|---|
| `sample.json`, `.yaml`, `.toml`, `.jsonl`, `x.ndjson` | Our tree or rows, Tegel footer |
| `sample.csv`, `sample.tsv`, `quoted-newline.csv` | Our table, header detected, the quoted newline in one cell |
| `prod.env` and `.env` (copies of `sample.env`) | Keys shown; every value is `••••••••`; clicking reveals nothing |
| `big-1m.csv` | First 1,000 rows plus the truncated banner |
| `Dockerfile`, `CHANGELOG`, `.gitignore` | Our plain text |
| a NUL-containing `blob` (no extension) | System generic preview (icon), no garbage |
| `/bin/ls`, `README`, `Makefile` | Unchanged system behaviour |
| `hostile.csv` | Text shown literally; nothing executes |

If the system previewer wins for a type (DF5 says it may), write that down. The site must not claim that type (Task 13).
- [ ] **Step 5: Remote matrix.** Run the same matrix on `macos-26` (GitHub, arm64) and macOS 27 (Task 14 machine) and record the results in `docs/reviews/m06.md` § "Quick Look matrix".
- [ ] **Step 6: Commit.**

```bash
git add Apps/Data/QuickLook/PreviewProvider.swift docs/reviews/m06.md
git commit -m "feat(data-ql): Quick Look previews for data files, .env masked, extension-less text

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Window viewer (Pro), `.env` viewer and live reload

**Prerequisite:** read `DESIGN.md`; no UI value outside it.

**Files:**
- Modify: `Apps/Data/App/DataApp.swift`.
- Create: `Apps/Data/App/DataWindow.swift` and `Apps/Data/App/WelcomeView.swift`.
- Modify: `project.yml`. Add `Apps/Markdown/App/ProGate.swift` and `Apps/Markdown/App/LicenceSettingsView.swift` (paths from Task 0 #7) to the `data` target's sources by path; don't copy them (CR 06-6).

**Interfaces:**
- Consumes: `EnvironmentValues.isPro` (`ProGate.swift`); `LicenceSettingsView` (plan 03; no updater parameter, since Updates is its own tab); `LicenseManager(client:keychain:)`, `PolarConfig.fromInfoPlist()`; `QuickLookSetup.settingsURL` and `QuickLookSetup.settingsPath(macOSMajor:)` (TegelKit, plan 02 Task 15); `RendererWebView`, `renderData`, `renderPaged`; `RecordIndex(url:quoteAware:)`, `DataFile.load(_:maxBytes:)`; `FileWatcher(url:debounce:onChange:)`; App 1's open-file pattern (Task 0 #7).
- Produces: `struct DataWindow: View { let url: URL }` and `struct WelcomeView: View`. `WelcomeView` shows when there's no Pro licence or no file:
  - the Quick Look how-to: Space in Finder, then the Settings path chosen by `QuickLookSetup.settingsPath(macOSMajor:)` (the same copy as App 1's Welcome, never hard-coded here), with an "Open System Settings" button for `QuickLookSetup.settingsURL`;
  - the Pro feature list, and "One-time purchase for 2 Macs" with a buy button (`PolarConfig.checkoutURL`). No price in the app: the checkout shows it (plan 05 CR-5);
  - App 1's `LicenceSettingsView`.

Routing rule in `DataWindow`:
- `!isPro` → `WelcomeView`. `jsonl`, `csv`, `tsv` → `RecordIndex` (`quoteAware` for csv only) → `renderPaged`; on `.utf16`, fall back to the next path.
- Every other format, including `.text` → `DataFile.load(url, maxBytes: 100_000_000)` → `renderData(mode: .window)`.
- `FileWatcher` on the file → rebuild and re-render, keeping the scroll position (and sticking to the bottom if it was there).

- [ ] **Step 1: Write the run checklist as the failing state.** On the current build, opening `sample.csv` from Finder ("Open With › Tegel Data") shows an empty window. That's FAIL.
- [ ] **Step 2: Implement** the three views and the `project.yml` source entry.
- [ ] **Step 3: Build.** `xcodegen generate && make build`. Expected: `** BUILD SUCCEEDED **` with no new warnings in `Apps/Data`.
- [ ] **Step 4: Run the checklist on the build Mac, expect PASS.**
  - Debug `isPro` override **off**: opening any fixture shows `WelcomeView`.
  - Override **on**: each `sample.*` renders; `big-1m.csv` opens in < 3 s and scrolls to row 1,000,000; `big-200mb.jsonl` flags the bad lines at multiples of 100,000 and still renders the rest; `hostile.*` render as text; in `sample.env`, one click reveals one value.
  - Live reload: `printf '{"live":1}\n' >> /tmp/live.jsonl` while the file is open adds the row within 1 s.
  - Switch the system language to Arabic: the Welcome text is right-to-left and the data stays left-to-right.
- [ ] **Step 5: Commit.**

```bash
git add Apps/Data/App project.yml
git commit -m "feat(data): Pro window viewer with paging, .env reveal and live reload

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

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
- Consumes: `parseJSONLLine`, `jsonlRowHTML`, `treeHTML`, `escapeHTML`, `DEFAULT_LABELS`; `renderToHTML` (master §3.2, used in the test only).
- Produces:

```js
export function parseTranscript(lines /* string[] */)
  // -> { kind: 'claude'|'codex'|'unknown', title: string|null, hidden: number,
  //      items: Array<{ line, kind: 'user'|'assistant'|'thinking'|'tool'|'note'|'raw'|'bad',
  //                     text?, name?, input?, result?: { text, isError }, sidechain?, value?, message? }> }
export function transcriptHTML(t, { showHidden = false, labels = DEFAULT_LABELS } = {})  // items get id="L<line>"; tools are closed <details class="tool">
export function transcriptToMarkdown(t, { labels = DEFAULT_LABELS } = {})               // -> string
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
```

- [ ] **Step 2: Run it, expect FAIL.** `cd Renderer && bun test test/data-transcript.test.js`. Expected: FAIL, `Cannot find module '../src/data/transcript.js'`.
- [ ] **Step 3: Implement.** `parseTranscript` is one pass over the lines (blank lines skipped, numbering kept) with a `Map` from id to the pending tool item. The Markdown export uses `## User` / `## Assistant` headings with the text verbatim, renders each tool as `#### Tool: name` with input and output in fences one backtick longer than the longest backtick run inside them (CommonMark rule), and leaves out `thinking`.
- [ ] **Step 4: Run it, expect PASS.** `cd Renderer && bun test test/data-transcript.test.js`. Expected: 4 pass. Then run the secret scan, which must print nothing:
  `grep -rnE 'sk-[A-Za-z0-9]{20,}|ghp_|AKIA[0-9A-Z]{16}|PRIVATE KEY|/Users/[a-z]+' Fixtures/data | grep -v '/Users/demo'`
- [ ] **Step 5: Commit.**

```bash
git add Renderer/src/data/transcript.js Renderer/src/data/view.js Renderer/test/data-transcript.test.js Fixtures/data/sessions Packages/TegelKit/Sources/TegelKit/Resources/Renderer
git commit -m "feat(renderer): tolerant Claude Code/Codex transcript parser and Markdown export

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Session mode (Pro)

**Prerequisite:** read `DESIGN.md`; no UI value outside it.

**Files:**
- Modify: `Packages/TegelKit/Sources/TegelKit/FolderIndex.swift` (CR-2) and `Packages/TegelKit/Tests/TegelKitTests/FolderIndexTests.swift`.
- Create: `Apps/Data/App/SessionSources.swift` and `Apps/Data/App/SessionsView.swift`. Modify `DataApp.swift` to add the "Sessions" window and the ⌘⇧S command.

**Interfaces:**
- Consumes:
  - `BookmarkStore.save(_:)`, `BookmarkStore.resolveAll() -> [URL]` (scope handling per Task 0 #4);
  - `FolderIndex.search(_:in:limit:) -> [SearchHit]`;
  - `TextFileLoader.load(_:maxBytes:)`;
  - `renderData(_:format: .transcript, …)`, `scroll(toHeading:)`;
  - `FileWatcher`.
- Produces:

```swift
// TegelKit (CR-2): markdownFiles(in:) becomes a call to this
public static func files(in root: URL, extensions: Set<String>) throws -> [FolderItem]   // same skip list as markdownFiles
// App
@MainActor enum SessionSources {
    static func pick() -> URL?   // NSOpenPanel: canChooseDirectories, !canChooseFiles, showsHiddenFiles = true,
                                 // directoryURL = <real home>/.claude/projects (real home via getpwuid(getuid()).pw_dir,
                                 // because the sandbox container is what homeDirectoryForCurrentUser returns); then BookmarkStore.save
    static var all: [URL] { get } // BookmarkStore.resolveAll()
}
struct SessionsView: View
// Sidebar: sources, then sessions = FolderIndex.files(in:extensions:["jsonl"]) sorted by modification date (newest first).
// Search field: debounced 300 ms, FolderIndex.search off the main actor; a hit opens the session, then scroll(toHeading: "L\(line)").
// The open session loads through TextFileLoader.load(url, maxBytes: 128_000_000) (truncated -> banner).
// FileWatcher on the open file -> re-render, kept at the bottom if it was there. ⌘R rescans the sources.
// A "Show internal records" toggle maps to showHidden.
```

- [ ] **Step 1: Write the failing test.** `testFilesWithExtensions` builds a temp tree with `a.jsonl`, `b/c.jsonl`, `node_modules/x.jsonl`, `.git/y.jsonl` and `d.md`. It asserts `files(in:root, extensions:["jsonl"]).map(\.relativePath).sorted() == ["a.jsonl","b/c.jsonl"]` and `markdownFiles(in:root).map(\.relativePath) == ["d.md"]`. If Task 0 #3 found a 5 MB per-file cap in `search`, also add `testSearchFindsLateHitInLargeFile`: a 20 MB file with `needle` on its last line returns one hit.
- [ ] **Step 2: Run it, expect FAIL.** `swift test --package-path Packages/TegelKit --filter FolderIndexTests`. Expected: FAIL to compile, `type 'FolderIndex' has no member 'files'`.
- [ ] **Step 3: Implement** `files(in:extensions:)`, rebase `markdownFiles` onto it, then write the two app files.
- [ ] **Step 4: Run it, expect PASS, then check the app.** `swift test --package-path Packages/TegelKit --filter FolderIndexTests` gives all pass. Then `make build`, and run this checklist with temp copies of `Fixtures/data/sessions/*` in a folder the panel picks, **never the real `~/.claude`**:
  - the panel can browse hidden folders;
  - after a relaunch, the list comes back with no prompt;
  - searching `needle-42` gives one hit, and opening it scrolls to L9;
  - tool calls are collapsed;
  - appending a synthetic user line adds it within 1 s;
  - a `.jsonl` that isn't a transcript shows generic rows.
- [ ] **Step 5: Commit.**

```bash
git add Packages/TegelKit/Sources/TegelKit/FolderIndex.swift Packages/TegelKit/Tests/TegelKitTests/FolderIndexTests.swift Apps/Data/App
git commit -m "feat(data): session mode with bookmarked folders, cross-session search, live reload

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11: Markdown export and "Open in Tegel Markdown" (Pro; the cross-sell)

**Prerequisite:** read `DESIGN.md`; no UI value outside it.

**Files:**
- Create: `Apps/Data/App/ExportController.swift`. Modify `SessionsView.swift` to add the toolbar buttons "Export Markdown…" and "Open in Tegel Markdown".
- Modify: `Makefile`. Add a `readonly-gate` target and make `check` depend on it.

**Interfaces:**
- Consumes: `window.tegel.transcriptMarkdown()` (Task 9), `RendererWebView.webView`.
- Produces:

```swift
@MainActor enum ExportController {
    static func exportMarkdown(from renderer: RendererWebView, suggestedName: String) async throws -> URL?
    // NSSavePanel(allowedContentTypes: [UTType(filenameExtension: "md")!]) -> callAsyncJavaScript("return window.tegel.transcriptMarkdown()")
    // -> String.write(to: picked, atomically: true, encoding: .utf8). nil when cancelled.
    static func openInMarkdownApp(_ exported: URL)
    // NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.tegelapps.markdown")
    //   -> open([exported], withApplicationAt:configuration:), else NSWorkspace.shared.open(URL(string: "https://tegelapps.com/markdown/")!) (path per Task 0 #10)
}
```

"Open in Tegel Markdown" is enabled after an export; it opens the file that was just exported. There are no temp files, so the only write stays the save-panel URL (rule 1).

- [ ] **Step 1: Write the failing gate.** Add this to the `Makefile`:

```make
readonly-gate:
	@! git grep -nE 'write\(to:|createFile\(|removeItem\(|moveItem\(|copyItem\(|FileHandle\(forWriting|\.write\(contentsOf' -- Apps/Data Packages/TegelKit/Sources | grep -vE 'Apps/Data/App/ExportController.swift|TegelKit/PDFExporter.swift'
```

Add a temporary line `try? "x".write(to: url, atomically: true, encoding: .utf8)` to `DataWindow.swift`. Run `make readonly-gate`. Expected: FAIL, with the line printed. Then remove the line.
- [ ] **Step 2: Implement** `ExportController` and the toolbar buttons (Pro-gated through `isPro`).
- [ ] **Step 3: Run the gate and build, expect PASS.** `make readonly-gate && make build`. Expected: exit 0 and `** BUILD SUCCEEDED **`.
- [ ] **Step 4: Run the checklist on the build Mac.**
  - Export the Claude fixture session. The `.md` opens in Tegel Markdown with each tool output in a single code block.
  - Unregister App 1 (`lsregister -u "/Applications/Tegel Markdown.app"`). The button now opens `https://tegelapps.com/markdown/` in the browser.
  - Re-register App 1 (`lsregister -f …`).
- [ ] **Step 5: Commit.**

```bash
git add Apps/Data/App/ExportController.swift Apps/Data/App/SessionsView.swift Makefile
git commit -m "feat(data): export sessions to Markdown and open them in Tegel Markdown

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 12: Polar products for Data and the bundle (W12)

**Why:** plan 03 ships the benefit binding in App 1 v1.0 (D1): `PolarConfig.benefitID` (Info.plist `TGPolarBenefitID`), `PolarError.wrongProduct`, `benefit_id` on validate, and the activate check that deactivates a mismatched key. So a $15 Data key never unlocks the $19 Markdown app, and the reverse [DF6]. This task creates the Data and bundle Polar objects, gives App 2 its own benefit id, and proves the binding end to end with real keys.

**Files:**
- Modify: the `Config/` xcconfigs. Fill `TG_POLAR_BENEFIT_ID_DATA` and `TG_POLAR_CHECKOUT_URL_DATA` (Task 1): sandbox values in the xcconfig that holds plan 03's sandbox values (Task 0 #9), production values in `Config/Release.xcconfig` (Step 3).
- Modify: `docs/reviews/m06.md`.

**Interfaces:**
- Consumes: plan 03's `PolarConfig.benefitID`, `PolarError.wrongProduct` and its copy "This key is for another Tegel app. Each app has its own key on your Polar purchases page." (checked by Task 0 #6).
- Produces: the Polar ids in `.env` under the Task 1 key names; App 2's `TGPolarBenefitID` = the Data licence benefit.

**Activation UX for the bundle:** one key per app. Each app accepts only its own benefit, and the server enforces it. The bundle product carries **both** existing licence benefits (Polar lets one benefit attach to many products, DF6). No cross-key logic.

- [ ] **Step 1: Create the Polar sandbox objects** (sandbox, so no approval needed; Polar API with `POLAR_SANDBOX_ACCESS_TOKEN`, or the dashboard). Record every id in `.env` under the Task 1 key names.
  - Benefit **"Tegel Data licence"**: `license_keys`, prefix `TGDATA`, `limit_activations: 2`, `enable_customer_admin: true`, no expiry.
  - Product **"Tegel Data"**: $15 one-time, that benefit. Product **"Tegel Bundle"**: $29 one-time, benefits [Markdown licence, Data licence]. Both carry the opt-out checkbox field (Task 0 #11) and say "2 Macs per licence"; the bundle adds "one key per app".
  - Fill the sandbox `TG_POLAR_BENEFIT_ID_DATA` and `TG_POLAR_CHECKOUT_URL_DATA`, then `xcodegen generate && make build` and `/usr/libexec/PlistBuddy -c 'Print TGPolarBenefitID' "<built Tegel Data.app>/Contents/Info.plist"`. Expected: the sandbox Data benefit id, not the Markdown one. Commit:

```bash
git add Config
git commit -m "build(data): sandbox Polar ids for Tegel Data

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 2: Sandbox end-to-end** (Debug builds of both apps; test card). Buy the bundle, then confirm:
  - the portal and the email show **two** keys (the DF6 gap). If not, stop and ask the user;
  - the Data key activates App 2;
  - the Markdown key in App 2 shows the `wrongProduct` message, and the portal shows no new activation left on that key;
  - the Data key in App 1 shows `wrongProduct`.

  Record the results in `docs/reviews/m06.md`.
- [ ] **Step 3: Production** (**user approval**, H11). On Thu 28 Jan, before Task 16, create the same three objects in production with no public checkout link (check that Polar's storefront doesn't list them). Fill in `Release.xcconfig` and `.env`, then commit on `m06-app2` (`git add Config/Release.xcconfig`). Every App 1 build since 1.0.0 binds keys to its own benefit (plan 03), so Data keys can't unlock App 1 from the first sale.
  - **BNPL check** (rule 7; plan 05 Task 2 Step 11's check, repeated because Polar or Stripe defaults can change). Open `POLAR_CHECKOUT_URL_DATA` and `POLAR_CHECKOUT_URL_BUNDLE` in Safari (Apple Pay set up) and in Chrome. Then set the billing country to Netherlands, then United States. **Do not pay.**
  - Screenshot each payment section to `docs/reviews/m06-polar/checkout-{data,bundle}-{safari,chrome}-{nl,us}.png`.
  - Expected: no Klarna, Afterpay/Clearpay, Affirm, "pay later" or "pay in N instalments". Cash App Pay is a wallet, not BNPL; record it if shown.
  - **If BNPL appears:** stop the App 2 launch prep, tell the user, and ask Polar support to remove it. Lemon Squeezy is the fallback (§13 risk 7, user decision).
  - Commit the screenshots with `docs/reviews/m06.md`.

---

### Task 13: Site pages (with plan 04)

**Prerequisite:** read `DESIGN.md`; no UI value outside it.

**Files** (plan 04's page register owns these URLs and their SEO targets; this task writes the copy, front matter `app: data`):
- Create: `site/content/en/data.md`, the product page. It covers the formats and free vs Pro; "$15 once, 2 Macs" and "Bundle with Tegel Markdown: $29 (one key per app)"; the 14-day refund; privacy (no network except licence checks and updates; `.env` values masked); "Not affiliated with Anthropic or OpenAI"; the Task 7 Quick Look results (claim only what was observed); the silent demo (Task 14); and a download link (Task 0 #9 URL).
- Create: `site/content/en/jsonl-viewer-mac.md` (target query "jsonl viewer mac").
- Create: `site/content/en/claude-code-transcript-viewer.md` (target query "view claude code transcripts"). It explains where the transcripts live (DF9, DF10) and that the app only reads them.
- Create: `site/content/en/bundle.md`, for plan 04's W14 bundle row (plan 06 owns the bundle, CR-5): "Both apps, one licence each, 2 Macs per app: $29. Bought separately they cost $19 and $15." Both prices are current and real, so there's no "was" price and no countdown (rule 6). It states the 14-day refund and "one key per app".

**Interfaces:**
- Consumes: plan 04's page register, front-matter keys, build command and sitemap (Task 0 #10).
- Produces: `/data/`, `/jsonl-viewer-mac/`, `/claude-code-transcript-viewer/`, `/bundle/` (use the register's bundle URL if it differs).

- [ ] **Step 1: Write the failing check.** After the site build (Task 0 #10 command), this loop must print nothing:

```bash
for p in data jsonl-viewer-mac claude-code-transcript-viewer bundle; do
  f=site/public/$p/index.html; test -f $f || echo "missing $f"
  grep -q '<meta name="description"' $f || echo "no description $p"
  grep -qiE '\bwas \$|klarna|afterpay|giveaway|apple silicon ready|works on macos 27' $f && echo "forbidden copy $p"
done
grep -q '\$15' site/public/data/index.html && grep -q '2 Macs' site/public/data/index.html || echo "price/limit missing"
grep -q '\$29' site/public/bundle/index.html && grep -q '2 Macs' site/public/bundle/index.html || echo "bundle price/limit missing"
```

Before the pages exist it prints `missing …`. That's FAIL.
- [ ] **Step 2: Write the four pages.** Screenshots show only synthetic fixtures (Task 9 sessions), never a real transcript. Text and code only (rule 3).
- [ ] **Step 3: Build and run the check, expect PASS.** No output. Then run the preview deploy (plan 04 command; previews need no approval) and get Lighthouse SEO ≥ 95 on the 4 URLs.
- [ ] **Step 4: Commit.**

```bash
git add site/content/en/data.md site/content/en/jsonl-viewer-mac.md site/content/en/claude-code-transcript-viewer.md site/content/en/bundle.md
git commit -m "docs(site): Tegel Data product page, two SEO pages and the bundle page

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 14: Test matrix, release candidate and demo (W14, Tue 26 – Thu 28 Jan)

**Prerequisite** (the demo): read `DESIGN.md`; no UI value outside it.

**Files:**
- Modify: `scripts/release.sh` and `scripts/release_test.sh` (plan 03 owns both; this adds the `data` app).
- Modify: `docs/reviews/m06.md` (§ "Test matrix").

**Interfaces:**
- Consumes: plan 03's `scripts/release.sh <app> <version> [--sandbox] [--yes] [--no-upload]` (version `X.Y.Z[-bN|-rcN]`; `--no-upload` stops after the notarised, stapled DMG and prints its path last); `scripts/check-data-types.swift`; the Task 7 and 8 checklists.
- Produces: `release.sh data …`; a notarised, stapled RC DMG, and matrix evidence per machine.

- [ ] **Step 1: Add the `data` app to `release.sh`.**
  - Add a `release_test.sh` case in the style of plan 03's cases (no network, no signing, no build): `release.sh data 1.0.0-rc1 --no-upload` gets past argument parsing with `SCHEME=data`, `DMG_NAME=TegelData-1.0.0-rc1.dmg` and `VOL="Tegel Data"`. Run `bash scripts/release_test.sh`. Expected: FAIL on the new case, `unknown app: data`.
  - Add one line to the `case $app` block: `data) SCHEME=data; DMG_NAME=TegelData-$V.dmg; VOL="Tegel Data";;`.
  - Re-run `bash scripts/release_test.sh`. Expected: every case passes, the new one included.
- [ ] **Step 2: Build the RC.** `scripts/release.sh data 1.0.0-rc1 --no-upload`. Expected: `spctl -a -vvv -t open --context context:primary-signature <dmg>` (plan 03's DMG check; `-t install` is for `.pkg`) prints `accepted` and `source=Notarized Developer ID`.
- [ ] **Step 3: Run the matrix.** Every row runs `check-data-types.swift`, the Quick Look matrix, `big-1m.csv` in the window, `.env` masking and the session fixtures. Licence activation runs on Debug builds against the sandbox.

| Machine | Evidence source |
|---|---|
| macOS 15.7 Intel | build Mac |
| macOS 14 arm64 | GitHub `macos-14` (automated tests only) |
| macOS 15 arm64 | GitHub `macos-15` |
| macOS 26 arm64 | GitHub `macos-26` |
| macOS 27 arm64 | GitHub `macos-27` if Task 0 #15 found one; otherwise lease L3, one Scaleway M1 day (≈ €3.19 incl. VAT, paid from revenue, **user approval**) |

- [ ] **Step 4: Record the demo.** A silent screen recording (no audio track; captions as text) of: Quick Look on JSONL, CSV and `.env` (masked) → window paging of 1M rows → a session transcript → export → open in Tegel Markdown. Use synthetic fixtures only. It goes up to R2 next to the DMG when Task 16 ships, under the same release approval (no separate ask).
- [ ] **Step 5: Commit.**

```bash
git add scripts/release.sh scripts/release_test.sh docs/reviews/m06.md
git commit -m "test(data): release.sh data app; RC1 matrix across macOS 14/15/26/27 and Intel/arm64

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 15: Launch drafts, cross-sell copy and segment rule, and the G1b template (W14)

**Ownership:** plan 08 owns MailerLite (account since W2) and sends the cross-sell (its Task 15 Step 2). This task supplies only the cross-sell copy and the segment rule. Plan 06 opens no MailerLite account and exports no buyer list.

**Files:**
- Create, in plan 05's launch folder (Task 0 #11; default `docs/launch/`): `data-producthunt.md`, `data-reddit-macapps.md`, `data-show-hn.md`, `data-crosssell-email.md`.
- Create: `docs/gates/G1b.md`.

**Interfaces:**
- Consumes: `POLAR_ACCESS_TOKEN` (scope `orders:read`) and `POLAR_PRODUCT_ID_{DATA,BUNDLE}` (G1b); the opt-out field slug (Task 0 #11).
- Produces: drafts **for the user to approve**; the cross-sell copy and segment rule that plan 08 Task 15 Step 2 sends.

- [ ] **Step 1: Write the drafts.** Every draft states the price ("$15 once, 2 Macs; bundle with Tegel Markdown $29"), read-only with no network except licence checks and updates, `.env` values masked, "not affiliated with Anthropic or OpenAI", and the silent demo link. No "was" price, no unverified claims. Per channel:
  - **Product Hunt:** tagline ≤ 60 chars, for Tue 2 Feb 00:01 PT.
  - **r/macapps:** the PCP template, "Lifetime" flair and "I'm the developer". The 30-day rule holds only if the last promotion date (Task 0 #11) + 30 days ≤ 2 Feb.
  - **Show HN:** title `Show HN: Tegel Data – read-only Mac viewer for JSONL, CSV, .env and Claude Code/Codex transcripts`, plus a first comment covering the WKWebView, CSP and RecordIndex design.
  - **Cross-sell email** (`data-crosssell-email.md`): ≤ 150 words; subject `Tegel Data: the same quiet reader, for JSON, YAML and agent transcripts`; the three Pro features; "Quick Look for JSON/YAML/CSV is free"; checkout links carry `?reference_id=email-crosssell`; the closing line "This is the only email about Tegel Data. You're getting it because you bought Tegel Markdown and didn't opt out at checkout."; plan 08's footer (identity, KvK number, postal address or number: Tw 11.7 lid 7) and MailerLite's `{$unsubscribe}` link (Tw art. 11.7 soft opt-in for own similar products [BUSINESS-PLAN S⁴⁶]).
- [ ] **Step 2: Write the segment rule** at the top of `data-crosssell-email.md`, for plan 08:
  - Recipients = plan 08's `buyers-markdown` group as `sync_buyers.py` keeps it: App 1 buyers with a counted sale (paid or partially refunded, `net_amount > 0`), minus anyone who ticked the checkout opt-out (the Task 0 #11 field), minus refunded-only buyers, minus anyone unsubscribed.
  - One send, Tue 2 Feb 09:30 CET, by plan 08 Task 15 Step 2 (user approval there). If the group is over MailerLite Free's 250 subscribers, plan 08 asks the user before sending.
  - No recipient list is exported, by this plan or into this repo.
- [ ] **Step 3: Write the G1b template.** `docs/gates/G1b.md` holds:
  - the rule: BUSINESS-PLAN §12 G1 binds only if App 1 had < 10 sales at G1 on 7 Jan (`docs/gates/G1.md`); then App 2 < 10 sales by Thu 4 Mar 2027 → stop the studio;
  - the definition: App 2 sales = paid or partially-refunded orders for `POLAR_PRODUCT_ID_DATA` + `POLAR_PRODUCT_ID_BUNDLE` created ≥ 2 Feb, counted per product with `curl … | jq '[.items[] | select(.status=="paid" or .status=="partially_refunded")] | length'` and summed;
  - empty Result and Decision fields.
- [ ] **Step 4: Commit.**

```bash
git add docs/launch/data-*.md docs/gates/G1b.md
git commit -m "docs(launch): Tegel Data launch drafts, cross-sell copy and segment rule, G1b template

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 16: 9-stage pipeline, merge, push, release (Fri 29 Jan – Mon 1 Feb)

**Files:**
- Modify: `docs/reviews/m06.md` (pipeline sections).

**Interfaces:**
- Consumes: the whole branch. `BASE=$(git merge-base HEAD main)`.
- Produces: `main` with the milestone merged, and Tegel Data 1.0.0 released.

**If a stage can't run:** write in `m06.md` which stage, why, and what ran instead. Never skip one silently.

- [ ] **Stage 1: Bloat audit (pre).** Follow `~/.claude/skills/code-upgrade/bloat-audit.md` over `git diff $BASE...HEAD` and the touched files. Strip self-introduced bloat, and list pre-existing findings as questions for the user in `m06.md`.
- [ ] **Stage 2: Baseline.** `git status` (clean), then `make fixtures && make check`. Record the JS, Swift and build counts. They must be ≥ the Task 0 baseline.
- [ ] **Stage 3: Code review.** gstack `/review`, or a fresh code-review subagent, on `git diff $BASE...HEAD`: bugs, security, correctness.
- [ ] **Stage 4: `/cso` (mandatory).** Scope:
  - **Parsers:** `parse.js`, `jsonl.js`, `table.js`, `dotenv.js`, `transcript.js`, `RecordIndex`, `DataFile` (prototype pollution, alias bombs, deep nesting, unbalanced quotes, FIFO/binary/huge input).
  - **`.env` masking:** values absent from the DOM until clicked and never in Quick Look; error rows; commented assignments.
  - **Renderer:** `view.js`, the `page.js` stubs, `tegelData` range clamping, CSP unchanged, DOMPurify on every insertion. **Exported Markdown:** prose verbatim, tool I/O fenced.
  - **Session folder access and bookmarks:** the open panel, the real-home lookup, `BookmarkStore` scope start/stop, read-only use (`readonly-gate`).
  - **Entitlements:** App = D5; Quick Look without the `/` exception. **Licensing:** App 2's `TGPolarBenefitID` is the Data benefit in Debug and Release (non-empty, not the Markdown id); plan 03's binding, `wrongProduct` deactivation and 404 grace path are unchanged.
  - **Release script:** the `data)` case in `scripts/release.sh` and its `release_test.sh` case (Task 14).
- [ ] **Stage 5: Adversarial challenge.** `/codex` challenge mode on the same diff, or the closest agent fallback; name it if you use one.
- [ ] **Stage 6: Consolidate.** Dedupe all findings into `m06.md` as P0/P1/P2, each with the fix decision.
- [ ] **Stage 7: Patch and re-review.** Fix every P0/P1 and the actionable P2s, each with a test that fails before the fix. Re-run the targeted tests and the reviewers that raised them until they're closed.
- [ ] **Stage 8: Bloat audit (post).** The same as stage 1, over the final cumulative diff.
- [ ] **Stage 9: `/review` + cubic.** Run `/review`, then `cubic review -b $BASE -j` from the repo root (read `.issues`). Repeat after each fix batch until **two consecutive rounds show no new P0/P1**, and only with no agent writing to the tree.
- [ ] **Design review.** `design-review` on the built app (Welcome, the window views, Sessions, the export toolbar), the Quick Look previews and the four site pages. Screenshots in light, dark and Arabic UI, with `.env` values masked in every shot, go to `docs/reviews/m06-design/`. Fix every P0/P1 finding; if that changes code, re-run stage 9.
- [ ] **Commit, merge, push.**

```bash
git add docs/reviews/m06.md
git commit -m "docs(m06): pipeline results

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git checkout main && git pull && git merge --no-ff m06-app2 -m "Merge m06-app2: Tegel Data 1.0.0

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" && git push origin main
graphify update .
```

- [ ] **Release** (Mon 1 Feb; one **user approval** covers the DMG, the appcast and the Task 14 demo upload to R2). Run `scripts/release.sh data 1.0.0` on `main`. Expected: notarised and stapled; `spctl` accepted; appcast `data/appcast.xml` live. Then download the DMG on the build Mac and confirm that a Sparkle check finds no update.

## Launch runbook (no code; every outward action needs user approval)

- [ ] **Mon 1 Feb:** the Task 16 release is done (production products since Thu 28 Jan, Task 12 Step 3). The site deploy is staged.
- [ ] **Tue 2 Feb:** production site deploy of `/data/*` before 09:00 CET; Product Hunt at 00:01 PT (09:01 CET); the cross-sell email (plan 08 Task 15 Step 2 sends it at 09:30 CET, with Task 15's copy and segment rule); r/macapps; Show HN around 15:00 CET. Each post uses the draft as approved.
- [ ] **Daily until 4 Mar:** log support minutes (§6.4: ≤ 20 min/day).
- [ ] **Thu 4 Mar 2027:** fill in `docs/gates/G1b.md` (counts, rule, decision), commit to `main`, push, and tell the user the outcome. If the stop rule fires, the studio stops (§12).

## W9 re-validation record

*Filled in by Task 0. One row per check in Task 0 Step 3, plus the API diff and the baseline counts.*

| # | Answer (with evidence) | Plan edits made |
|---|---|---|
| | | |

## Contract change requests

1. **CR-1 (P0, TegelStore, D16): moved to plan 03 (D1, CR 06-1).** `PolarConfig.benefitID` from the Info.plist key `TGPolarBenefitID`; `PolarError.wrongProduct`; `validate` sends `benefit_id`; `activate` checks `license_key.benefit_id` and deactivates on a mismatch. **Why:** without it, any key in the organisation unlocks any Tegel app [DF6]. It ships in App 1 v1.0, so there's no App 1 licensing release in January. Plan 06 only adds `TG_POLAR_BENEFIT_ID_DATA` (Task 1) and fills it (Task 12).
2. **CR-2 (TegelKit `FolderIndex`):** add `files(in root: URL, extensions: Set<String>) throws -> [FolderItem]`; `markdownFiles(in:)` becomes a call to it. If Task 0 #3 finds a 5 MB per-file cap in `search`, add `maxBytesPerFile: Int = 5_000_000` to `search(_:in:limit:)`; session mode passes 128 MB.
3. **CR-3 (TegelKit and renderer additions):** Swift `DataFormat`, `DataFile`, `DataFileError`, `RecordIndex`, `RecordIndexError`, `DataIssue`, `DataRenderResult`, `RendererWebView.renderData(…)`, `RendererWebView.renderPaged(…)` and the `tegelData` reply handler. JS `window.tegel.renderData`, `openPaged`, `transcriptMarkdown`. Layout: §3.1 gains `Renderer/src/data/` and `src/css/data.css`; the bundle gains `data.js`.
4. **CR-4 (D5, narrowing):** the Data Quick Look extension omits `temporary-exception.files.absolute-path.read-only = /`. That exception exists only for Markdown's local images, and data files load none.
5. **CR-5 (roadmap §8 item 5; accepted):** the $29 bundle moves from post-launch into plan 06, which owns it (Tasks 12, 13). BUSINESS-PLAN §6.2 sells it with App 2. It reuses both existing licence benefits. Plan 07 C1 only verifies it.
6. **CR-6 (decided, CR 06-6):** App 2 compiles App 1's `Apps/Markdown/App/LicenceSettingsView.swift` by path, like `ProGate.swift` (Task 8). It takes no updater, since Updates is its own Settings tab (plan 03), so no package change is needed.
7. **CR-7 (§3.4 fixtures):** add `Fixtures/data/`: committed `sample.*`, `hostile.*`, `quoted-newline.csv` and `sessions/`. `make fixtures` generates `big-200mb.jsonl` and `big-1m.csv` (gitignored `Fixtures/data/big-*`).
