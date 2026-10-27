# App 1 reader features (M02) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the G0 renderer into the sellable App 1. That means folder mode with cross-document search and live reload, an outline, find in page, local images, three themes with light/dark, paginated RTL-correct PDF, four UI languages and Copy Diagnostics. Every paid feature sits behind the `isPro` seam.

**Architecture:**
- **TegelKit:** new logic goes here as small tested units: `BookmarkStore`, `FolderIndex`, `FileWatcher`, `DocumentImageHandler`, `PDFExporter`, `Diagnostics`, plus navigation methods on `RendererWebView`.
- **App:** thin SwiftUI over those units: a folder `WindowGroup`, an outline inspector, a find bar, a Settings `TabView`, a Welcome window and a Pro window.
- **Renderer:** print CSS (the theme CSS is plan 09 Task 6's), plus small JS additions: source-line anchors, image-failure reporting, and relative images rewritten to `tegel-doc:` URLs, which a `WKURLSchemeHandler` serves from the grant root (K4).

**Tech Stack:**
- Swift 6.2.4 (Swift 6 mode), SwiftUI + AppKit, WebKit, PDFKit, CoreServices FSEvents, XCTest.
- bun (renderer build and tests), XcodeGen, String Catalogs.

**Spec:**
- `BUSINESS-PLAN.md` §4 (App 1 gap), §6.1, §6.3, §6.4.
- `docs/superpowers/plans/2026-10-27-00-master-roadmap.md` §3 (contract) and §4 row 02.
- `docs/research/2026-10-27-technical-facts.md` [F5] [F6] [F10].

**Branch and dates:** `m02-app1-features`, cut from `main` after plan 01 merges.
- W2 (Tue 3 – Mon 9 Nov): Tasks 1–9. Needs plan 09 Drop A in `main` (`DESIGN.md`, `docs/design/app-ui-spec.md`; Mon 2 Nov).
- W3 (Tue 10 – Mon 16 Nov): Tasks 10–17. Needs plan 09 Drop B in `main` (theme CSS, `docs/design/samples/`, `scripts/window-shot.sh`; Mon 9 Nov), merged into the branch by Task 10 Step 0.

**Shell:** `export PATH="$HOME/.local/bin:$PATH"` (bun, xcodegen). Build Mac: Intel iMac19,1, macOS 15.7, Xcode 26.3. This plan reads nothing from `.env`.

**Commits:** every commit step means `git add <paths> && git commit -m "<message>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`; the steps give only the paths and the message.

**UI tasks:** read `DESIGN.md` and the `docs/design/app-ui-spec.md` steps each task names under "UI spec"; no UI value outside them.

## Assumed from plan 01 (checked in Task 1, Step 1)

| Thing | Assumed name |
|---|---|
| Xcode project / app target + scheme / Quick Look target | `Tegel.xcodeproj` / `markdown` (product `Tegel Markdown.app`, Swift module `Tegel_Markdown`, Xcode's default `PRODUCT_MODULE_NAME` for `PRODUCT_NAME: Tegel Markdown`) / `markdown.quicklook` |
| App entry | `Apps/Markdown/App/MarkdownApp.swift`: `@main struct MarkdownApp: App`, `DocumentGroup(viewing: MarkdownFile.self) { DocumentView(file: $0.document, fileURL: $0.fileURL) }`, `@NSApplicationDelegateAdaptor(AppDelegate.self)` |
| Reader view | `Apps/Markdown/App/DocumentView.swift`, hosting `RendererWebView.webView` through `NSViewRepresentable` |
| Swift API | `RenderOptions` has a `public init(mode: RenderMode = .window, theme: RendererTheme = .paper, baseURL: URL? = nil)`; `RendererWebView.render` resolves after the `rendered` message |
| Makefile | targets per master §3.1; `make check` = `test-js test-swift build`; derived data in `build` (`build/Build/Products/<Config>/Tegel Markdown.app`) |
| K4 renderer pieces | CSP `img-src 'self' data: tegel-doc:` (no `file:`); `addHooks(purify, { fileImages: true })` in `sanitize.js` keeps `src` only on `img` and only when it starts with `tegel-doc:` (plan 01 owns the hook and its tests); Quick Look renders with `baseURL: nil` |
| Make | a `generate` target (`xcodegen generate`, CR-P2-17) |
| Tests | `Packages/TegelKit/Tests/TegelKitTests/TestSupport.swift` holds `fixtureURL(_:) -> URL` and `@MainActor js(_:_:) async throws -> Any?`. `js` runs its body through `callAsyncJavaScript`, so every script `return`s its value. WebKit test files go under `TegelKitTests/WebView/` (plan 01 Task 5); if plan 01 took Branch B, run them with `xcodebuild test -project Tegel.xcodeproj -scheme TegelKitHostTests -derivedDataPath build -only-testing:TegelKitHostTests/<Class>` instead of `swift test --filter <Class>` |

If plan 01 used other names, substitute them in every command and path below. Don't rename plan 01's files.

## Global Constraints

Master §2/§3 and CLAUDE.md apply (platform, read-only, no network, imagery, honest pricing, contract names). Deltas for this plan:
- **Writes:** the only file write is the PDF at the save-panel URL (Task 12), plus the app's own container (bookmarks, settings, `makePDFData`'s private folder, which is gone before the call returns).
- **Renderer security:** this plan changes no CSP and no DOMPurify config (plan 01 owns both, K4). Document images reach the page only as `tegel-doc:` URLs that `DocumentImageHandler` serves from the grant root (Task 8). Navigation stays blocked; Mermaid keeps `securityLevel: 'strict'`.
- **Free:** Quick Look, single-file window, highlighting, Mermaid, RTL, local images, find, outline, all four UI languages (D6), the paper theme.
- **Pro:** folder mode (sidebar, cross-document search, live reload), PDF export, the ink and studio themes.
- **Copy:** state the licence limits ("one-time", "2 Macs", "14-day refund"); no price in the app (it changes by hand on 15 Dec, D15); no urgency, no counters. Screenshots use `Fixtures/markdown/` and `docs/design/samples/` only.
- **Contract:** additions go in each task's Interfaces block; changes only under "Contract change requests" at the end.
- **Evidence:**
  - Local runs prove macOS 15.7 Intel only.
  - arm64 and macOS 15/26 → GitHub Actions `macos-15`/`macos-26` via `workflow_dispatch` [F7]; one matrix run per milestone (Task 17).
  - macOS 27 → Scaleway M1 lease L2, Thu 26 Nov 09:00 → Fri 27 Nov 09:00 (booked by plan 05) [F9]. Plan 02's pending checks run third on it, after plan 05's matrix and plan 03's acceptance.

## Review Focus

1. **Folder trees that are huge, looped or partly locked.** Examples: opening `~` or a monorepo, a symlink pointing at an ancestor, a `chmod 000` subfolder.
   - Expected: indexing ends, shows at most 5,000 files with a visible notice, never follows symlinked folders, and skips locked folders without an error.
   - Pinned by Task 3: `testDoesNotFollowSymlinkedDirectories`, `testSkipsUnreadableSubfolder`, `testStopsAtLimit`.
2. **Files changing under the reader.** Examples: an editor's atomic save (write and rename), a formatter's burst of saves, the open file deleted.
   - Expected: one reload per burst; atomic saves are still seen; a deleted file clears the selection and the window stays usable.
   - Pinned by Task 5: `testBurstOfWritesFiresOnce`, `testAtomicReplaceFiresFileWatcher`; Task 9: `testDeletingOpenFileClearsSelection`.
3. **Stale grants at launch.** Example: a bookmarked folder that was deleted, moved, or lives on an unmounted disk.
   - Expected: it's dropped silently, with no mount prompt and no launch delay.
   - Pinned by Task 2: `testResolveAllDropsDeletedFolder`.
4. **Search input that isn't plain ASCII.** Examples: an empty or whitespace query, regex metacharacters, Arabic with harakat, CRLF endings, Windows-1252 files, 600-character lines.
   - Expected: literal, case- and diacritic-insensitive matches; correct 1-based line numbers; short snippets.
   - Pinned by Task 4's tests.
5. **PDF of awkward documents.** Examples: an empty file, 40+ pages (FB20581927 [F6]), a 600-character code line, a broken Mermaid diagram, mixed bidi.
   - Expected: an empty file gives one page; every section and the end marker are present; long lines wrap; there are no blank pages; no heading ends a page.
   - Pinned by Task 11's tests.
6. **Hostile image references.** Examples: `../` and `%2E%2E` escapes, a symlink out of the grant root, a sibling folder whose name extends the root's (`notes-old`), a hidden 1 px image from outside the document's folder.
   - Expected: nothing outside the grant root is served (404); a sibling prefix never counts as inside; PDF export lists outside-folder images and asks before writing.
   - Pinned by Task 8: `testDotDotEscapeIs404`, `testEverythingElseIs404`, `testRootContainingComparesPathComponents`, `testHiddenOutsideFolderImageIsListedForExport`.
7. **Huge files and fast typing.** Examples: a 266 MB `.md` opened from Finder; a query typed faster than the 200 ms debounce over 5,000 files.
   - Expected: the window never reads the whole file; a superseded query never scans, and an older, slower scan never overwrites newer results.
   - Pinned by Task 1: `testOpeningAHugeFileNeverReadsItWhole`; Task 4: `testCancelledScanStopsBeforeReading`; Task 9: `testStaleSearchIsDropped`.

---

## File map

| Path | Responsibility | Task |
|---|---|---|
| `Apps/Markdown/App/ProGate.swift` | `isPro` environment value, Debug override, effective theme | 1 |
| `Apps/Markdown/App/ProUpsellView.swift` | `UpsellFeature`, `ProUpsellView` in the `pro` window | 1 |
| `Apps/Markdown/AppTests/*` | Hosted (sandboxed) app tests | 1, 8–10, 12–14, 16 |
| `Packages/TegelKit/Sources/TegelKit/{BookmarkStore,FolderIndex,FileWatcher,PDFExporter,Diagnostics}.swift` | Contract units plus `Diagnostics` | 2–5, 11, 13 |
| `Packages/TegelKit/Sources/TegelKit/DocumentImageHandler.swift` | the `tegel-doc:` scheme handler and `URL.isInside(_:)` | 8 |
| `Packages/TegelKit/Sources/TegelKit/QuickLookSetup.swift` | Quick Look settings path and deep link (plan 08's interface) | 15 |
| `Packages/TegelKit/Sources/TegelKit/RendererWebView.swift` | + `scroll(toLine:)`, `find`, `readAccessURL`, `loadedImages(outside:)` | 6, 7, 8 |
| `Apps/Markdown/App/MarkdownApp.swift` (plan 01) | `isPro` environment, `pro` window | 1 |
| `Renderer/src/{markdown.js,page.js,build.js}` | line anchors, scroll, relative images → `tegel-doc:` via `baseHref`, image wait and errors, version file | 6, 8, 13 |
| `Renderer/src/css/{base,print}.css` | `.tg-hit`, print breaks (theme CSS: plan 09 Task 6) | 6, 11 |
| `Apps/Markdown/App/{ReaderController,FindBar,OutlineView,AppCommands}.swift` | per-window model, find, outline, menus, toolbar | 7 |
| `Apps/Markdown/App/{Grants,ImageGrantBar}.swift` | granted roots, "Show Images" bar | 8 |
| `Apps/Markdown/App/{FolderModel,FolderWindow}.swift` | folder mode | 9 |
| `Apps/Markdown/App/SettingsView.swift` | Settings `TabView`: General (paper size), Appearance (theme, text size) | 10, 12 |
| `Apps/Markdown/App/DropRouter.swift` | window drops | 14 |
| `Apps/Markdown/App/{WelcomeView.swift,Samples/Welcome.md,Samples/Welcome-ar.md}` | Welcome window and its bundled samples | 15 |
| `Apps/Markdown/App/Localizable.xcstrings` | en/nl/fr/ar | 16 |
| `docs/reviews/m02.md`, `docs/reviews/design-m02.md`, `docs/reviews/m02-design/*.png` | pipeline and design-review records, screenshots | 8, 10–12, 15–17 |

---

### Task 1: App test target, bounded-open test and the Pro seam

**UI spec:** app-ui-spec Step 6 (Pro window).

**Files:**
- Modify: `project.yml`: add a `MarkdownAppTests` target (`type: bundle.unit-test`, `platform: macOS`, `sources: Apps/Markdown/AppTests`, `dependencies: [{target: markdown}]`, hosted by the app) and add it to the `markdown` scheme's test targets (`scheme: { testTargets: [MarkdownAppTests] }`).
- Modify: `Makefile`: add `test-app` and `run-app`, and make `check` also run `test-app`.
- Create: `Apps/Markdown/App/ProGate.swift`, `Apps/Markdown/App/ProUpsellView.swift`
- Modify: `Apps/Markdown/App/MarkdownApp.swift`: inject `.environment(\.isPro, isPro)` into every scene, and add `WindowGroup("Tegel Markdown Pro", id: "pro", for: UpsellFeature.self) { $feature in ProUpsellView(feature: feature) }.windowResizability(.contentSize)`.
- Test: `Apps/Markdown/AppTests/ProGateTests.swift`, `Apps/Markdown/AppTests/LargeFileOpenTests.swift`

**Interfaces:**
- Consumes: `RendererTheme` (contract); plan 01 Task 7's bounded open (`DocumentView` loads through `TextFileLoader.load`).
- Produces:
```swift
extension EnvironmentValues { @Entry var isPro: Bool = false }
enum ProGate {
    static let forceProKey = "TGForcePro"
    #if DEBUG
    static let overrideLabel = "Pro (debug override)"   // ≥ 16 bytes, so it's a __cstring literal Step 6's Release check can see; Copy Diagnostics shows it (Task 13)
    #endif
    static func isPro(licensed: Bool, defaults: UserDefaults = .standard) -> Bool
    static func effectiveTheme(_ stored: RendererTheme, isPro: Bool) -> RendererTheme
}
// ProUpsellView.swift
enum UpsellFeature: String, Codable, Hashable, CaseIterable, Sendable { case folder, pdf, theme }   // stays app-side (K18)
struct ProUpsellView: View { let feature: UpsellFeature? }   // opened anywhere with openWindow(id: "pro", value: UpsellFeature.<x>)
```
- The upsell is a small window rather than a sheet, so menu commands can open it when no document window is focused. Each call site passes the triggering feature: `.folder` (Open Folder…, folder drops, licence lapse), `.pdf` (Export as PDF…), `.theme` (a Pro theme). Plan 02 shows the same copy for every feature. Plan 08 Task 12 adds the feature-specific copy and, for `.pdf`, a preview of at most two page images (`PDFExporter.makePDFData` → `PDFDocument(data:)` → `PDFPage.thumbnail`; no file left after the call), shown once per feature per launch through `UpsellContext.previewShown: Set<UpsellFeature>` (K18).
- Make targets:
  - `make test-app [ONLY=Class[/testMethod]]`: depends on `generate` (CR-P2-17), then `xcodebuild test -project Tegel.xcodeproj -scheme markdown -derivedDataPath build -only-testing:MarkdownAppTests[/$(ONLY)]`.
  - `make run-app [FILES="path…"] [ARGS="…"]`: Debug build into `build` (plan 01's derived-data path), then `open -n -a "build/Build/Products/Debug/Tegel Markdown.app" $(FILES) --args $(ARGS)`.
- `MarkdownApp` computes `isPro = ProGate.isPro(licensed: false)` until plan 03 feeds it from `LicenseManager`.

- [ ] **Step 1: Check plan 01's names**

Run: `grep -nE '^name:|type: (application|app-extension)' project.yml; ls Apps/Markdown/App; grep -nE '^[a-z-]+:' Makefile; xcodebuild -project Tegel.xcodeproj -scheme markdown -showBuildSettings | grep ' PRODUCT_MODULE_NAME '; grep -n 'tegel-doc' Renderer/src/sanitize.js Renderer/src/index.html`
Expected: the names in "Assumed from plan 01"; `PRODUCT_MODULE_NAME = Tegel_Markdown`; a `tegel-doc` hit in both renderer files. Write down any differences and substitute them from here on. If `tegel-doc` is missing from either file, stop: Task 8 depends on plan 01's K4 pieces.

- [ ] **Step 2: Branch and baseline**

Run: `git checkout main && git pull --ff-only && git checkout -b m02-app1-features && git merge-base HEAD main && make check`
Expected: all green. Create `docs/reviews/m02.md` with that SHA and the pass counts; later tasks append to it.

- [ ] **Step 3: Write the failing test** (`Apps/Markdown/AppTests/ProGateTests.swift`)

```swift
import XCTest
@testable import Tegel_Markdown
import TegelKit

final class ProGateTests: XCTestCase {
    private func defaults(forcePro: Bool?) -> UserDefaults {
        let d = UserDefaults(suiteName: "ProGateTests-\(UUID().uuidString)")!
        if let forcePro { d.set(forcePro, forKey: ProGate.forceProKey) }
        return d
    }
    func testFreeWithoutLicenceOrOverride() { XCTAssertFalse(ProGate.isPro(licensed: false, defaults: defaults(forcePro: nil))) }
    func testLicenceUnlocksPro()            { XCTAssertTrue(ProGate.isPro(licensed: true, defaults: defaults(forcePro: nil))) }
    func testDebugOverrideUnlocksPro()      { XCTAssertTrue(ProGate.isPro(licensed: false, defaults: defaults(forcePro: true))) } // tests build Debug
    func testProThemesFallBackToPaperWhenFree() {
        XCTAssertEqual(ProGate.effectiveTheme(.ink, isPro: false), .paper)
        XCTAssertEqual(ProGate.effectiveTheme(.studio, isPro: false), .paper)
        XCTAssertEqual(ProGate.effectiveTheme(.paper, isPro: false), .paper)
        XCTAssertEqual(ProGate.effectiveTheme(.studio, isPro: true), .studio)
    }
}
```

- [ ] **Step 4: Add the target and make targets, then run**

Run: `xcodegen generate && make test-app ONLY=ProGateTests`
Expected: FAIL, `cannot find 'ProGate' in scope`.

- [ ] **Step 5: Implement `ProGate.swift` and `ProUpsellView.swift`**

- `isPro` returns `licensed || override`. The override is `defaults.bool(forKey: forceProKey)` inside `#if DEBUG` and the constant `false` otherwise. The launch argument `-TGForcePro YES` reaches `UserDefaults.standard` through the argument domain, so no parsing is needed.
- `effectiveTheme` returns `stored` when `isPro || stored == .paper`, otherwise `.paper`.
- `ProUpsellView` (in `ProUpsellView.swift`) copy (exact English; translated in Task 16):
  - Title: "Tegel Markdown Pro"
  - Intro: "Pro adds the tools for reading whole projects and sharing them as PDF."
  - Bullet: "Folder mode: a sidebar of every Markdown file, search across files, live reload"
  - Bullet: "PDF export in A4 or Letter, with correct right-to-left pages"
  - Bullet: "The Ink and Studio themes, in light and dark"
  - Terms: "One-time purchase for 2 Macs. No subscription. 14-day refund."
  - What stays free: "Single files, Quick Look, Mermaid, right-to-left text and all four languages stay free."
  - Buttons:
    - "Buy Pro…" and "Enter Licence Key…": both `.disabled(true)`; plan 03 wires them.
    - "Not Now": closes the window.

- [ ] **Step 6: Run the tests, then prove the override is gone from Release** (CR-P2-18)

Run: `make test-app ONLY=ProGateTests`
Expected: `Executed 4 tests, with 0 failures` … `** TEST SUCCEEDED **`.

`TGForcePro` is 10 bytes, a Swift small string stored as immediates, so `strings` can't see it; the check looks for the 20-byte `overrideLabel` instead. Debug builds keep app code in `Contents/MacOS/*.debug.dylib`, hence the glob.

Run (positive control): `xcodebuild -project Tegel.xcodeproj -scheme markdown -configuration Debug -derivedDataPath build CODE_SIGNING_ALLOWED=NO build >/dev/null && strings "build/Build/Products/Debug/Tegel Markdown.app/Contents/MacOS/"* | grep -c 'Pro (debug override)'`
Expected: `1` or more. This is the check failing on a build that has the override.

Run: `xcodebuild -project Tegel.xcodeproj -scheme markdown -configuration Release -derivedDataPath build CODE_SIGNING_ALLOWED=NO build >/dev/null && strings "build/Build/Products/Release/Tegel Markdown.app/Contents/MacOS/"* | grep -c 'Pro (debug override)'`
Expected: `0`.

- [ ] **Step 7: Write the bounded-open test** (`Apps/Markdown/AppTests/LargeFileOpenTests.swift`)

```swift
import XCTest
import AppKit
@testable import Tegel_Markdown

@MainActor final class LargeFileOpenTests: XCTestCase {
    private func peakRSS() -> Int { var u = rusage(); getrusage(RUSAGE_SELF, &u); return u.ru_maxrss }   // bytes on macOS
    func testOpeningAHugeFileNeverReadsItWhole() async throws {        // Review Focus 7; K11
        let url = FileManager.default.temporaryDirectory.appending(path: "huge-\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: url.path(percentEncoded: false), contents: nil)
        let h = try FileHandle(forWritingTo: url); let chunk = Data(String(repeating: "Line of text\n", count: 80_000).utf8)   // 1,040,000 bytes
        for _ in 0..<256 { try h.write(contentsOf: chunk) }; try h.close()                                                    // 266 MB
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        let before = peakRSS()
        let (doc, _) = try await NSDocumentController.shared.openDocument(withContentsOf: url, display: true)   // the Finder/Open… path
        try await Task.sleep(for: .seconds(3))                                                                  // DocumentView loads its prefix and renders
        let grown = peakRSS() - before; doc.close()
        XCTAssertLessThan(grown, 128 << 20, "peak RSS grew \(grown >> 20) MB opening a 266 MB file")
    }
}
```

Run: `make test-app ONLY=LargeFileOpenTests`
Expected: `Executed 1 test, with 0 failures` (plan 01 Task 7 made the open bounded).

- [ ] **Step 8: Watch the guard fail**

Add `_ = try? String(contentsOf: fileURL!, encoding: .utf8)` (a whole-file read) as the first line of `DocumentView`'s load task, rerun, and expect FAIL (`peak RSS grew` ≥ 256 MB). Remove the line and rerun: `Executed 1 test, with 0 failures`.

- [ ] **Step 9: Commit** `project.yml Makefile Apps/Markdown/App Apps/Markdown/AppTests/ProGateTests.swift Apps/Markdown/AppTests/LargeFileOpenTests.swift docs/reviews/m02.md`, "feat(app): isPro seam with Debug-only override, Pro window, bounded-open regression test"

---

### Task 2: BookmarkStore

**Files:**
- Create: `Packages/TegelKit/Sources/TegelKit/BookmarkStore.swift`
- Modify: `Packages/TegelKit/Tests/TegelKitTests/TestSupport.swift` (plan 01 Task 4 created it; add `tempDir` and `write`)
- Test: `Packages/TegelKit/Tests/TegelKitTests/BookmarkStoreTests.swift`

**Interfaces:**
- Produces (contract): `BookmarkStore.save(_ url: URL) throws`, `BookmarkStore.resolveAll() -> [URL]`.
- Produces (additions):
  - `static let maxEntries = 20`
  - internal `save(_ url: URL, defaults: UserDefaults) throws`
  - internal `resolveAll(defaults: UserDefaults) -> [URL]`
  - The public calls use `.standard`. Storage key `"TGBookmarks"`, a `[Data]` array, newest last.
- Semantics:
  - `save` stores `url.bookmarkData(options: .withSecurityScope)`. It replaces an entry with the same `resolvingSymlinksInPath().path` and drops the oldest entries past 20.
  - `resolveAll` resolves with `[.withSecurityScope, .withoutUI, .withoutMounting]`.
    - Drops entries that fail or no longer exist. Re-saves stale ones.
    - Calls `startAccessingSecurityScopedResource()` once per returned URL, then writes back the pruned list.
    - Call it **once per launch**. `// ponytail: grants are held for the process lifetime; ≤ 20 of them.`
- TestSupport: `func tempDir() throws -> URL` (a fresh `UUID` folder under `FileManager.default.temporaryDirectory`) and `func write(_ text: String, _ rel: String, in root: URL) throws -> URL` (creates intermediate folders).

- [ ] **Step 1: Write the failing test**

```swift
final class BookmarkStoreTests: XCTestCase {
    var defaults: UserDefaults!
    override func setUp() { defaults = UserDefaults(suiteName: "BookmarkStoreTests-\(UUID().uuidString)") }
    private func paths(_ urls: [URL]) -> [String] { urls.map { $0.resolvingSymlinksInPath().path } }

    func testSaveThenResolveReturnsSameFolder() throws {
        let dir = try tempDir()
        try BookmarkStore.save(dir, defaults: defaults)
        XCTAssertEqual(paths(BookmarkStore.resolveAll(defaults: defaults)), paths([dir]))
    }
    func testSavingSameFolderTwiceKeepsOneEntry() throws {
        let dir = try tempDir()
        try BookmarkStore.save(dir, defaults: defaults); try BookmarkStore.save(dir, defaults: defaults)
        XCTAssertEqual(BookmarkStore.resolveAll(defaults: defaults).count, 1)
    }
    func testResolveAllDropsDeletedFolder() throws {               // Review Focus 3
        let dir = try tempDir()
        try BookmarkStore.save(dir, defaults: defaults)
        try FileManager.default.removeItem(at: dir)
        XCTAssertEqual(BookmarkStore.resolveAll(defaults: defaults), [])
        XCTAssertEqual((defaults.array(forKey: "TGBookmarks") as? [Data])?.count ?? 0, 0)
    }
    func testKeepsOnlyNewestTwenty() throws {
        let dirs = try (0..<21).map { _ in try tempDir() }
        for d in dirs { try BookmarkStore.save(d, defaults: defaults) }
        let got = paths(BookmarkStore.resolveAll(defaults: defaults))
        XCTAssertEqual(got.count, BookmarkStore.maxEntries)
        XCTAssertFalse(got.contains(paths([dirs[0]])[0]))
    }
}
```

- [ ] **Step 2: Run**

Run: `swift test --package-path Packages/TegelKit --filter BookmarkStoreTests`
Expected: FAIL, `cannot find 'BookmarkStore' in scope`.

- [ ] **Step 3: Implement `BookmarkStore` with the semantics above**

- [ ] **Step 4: Run**

Run: `swift test --package-path Packages/TegelKit --filter BookmarkStoreTests`
Expected: `Executed 4 tests, with 0 failures`.

- [ ] **Step 5: Commit** `Packages/TegelKit/Sources/TegelKit/BookmarkStore.swift Packages/TegelKit/Tests/TegelKitTests/BookmarkStoreTests.swift Packages/TegelKit/Tests/TegelKitTests/TestSupport.swift`, "feat(tegelkit): security-scoped BookmarkStore, deduped and capped at 20"

---

### Task 3: FolderIndex.markdownFiles

**Files:**
- Create: `Packages/TegelKit/Sources/TegelKit/FolderIndex.swift`
- Test: `Packages/TegelKit/Tests/TegelKitTests/FolderIndexFilesTests.swift`

**Interfaces:**
- Produces (contract): `FolderItem`, `FolderIndex.markdownFiles(in root: URL, limit: Int = maxFiles) throws -> [FolderItem]`.
- Produces (additions):
  - `public static let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn"]` (lower-case, [F10])
  - `public static let maxFiles = 5_000`
- Rules:
  - **Skip:** folders named `.git`, `node_modules`, `.build`, `DerivedData`, `Pods`, `dist` at any depth. Symlinked folders are never entered. Unreadable subfolders are skipped (the enumerator's `errorHandler` returns `true`).
  - **Keep:** other hidden folders stay in (`.github/` and `.claude/` hold agent docs).
  - **Match:** extensions match case-insensitively. `relativePath` uses `/` separators. It comes from `pathComponents` after `resolvingSymlinksInPath()` on the root and on the item's parent folder, never on the item itself (a file link such as `AGENTS.md -> CLAUDE.md` keeps its own name) and never a string prefix: test roots are `/var/folders/…` while the enumerator returns `/private/var/…` (CR-P2-28).
  - **Order:**
    - rank 0: root `CLAUDE.md`;
    - rank 1: root `AGENTS.md`;
    - rank 2: anything under the top-level `docs/`;
    - rank 3: everything else.
    - Inside a rank: `localizedStandardCompare` on `relativePath`.
  - **Limit:** stop enumerating at `limit`, then sort. `// ponytail: in trees over the limit, which files are kept depends on enumeration order; root CLAUDE.md/AGENTS.md are checked first so they're always in.`

- [ ] **Step 1: Write the failing test**

```swift
final class FolderIndexFilesTests: XCTestCase {
    private func tree(_ rels: [String]) throws -> URL { let r = try tempDir(); for p in rels { _ = try write("# x\n", p, in: r) }; return r }
    private func rels(_ root: URL, limit: Int = FolderIndex.maxFiles) throws -> [String] { try FolderIndex.markdownFiles(in: root, limit: limit).map(\.relativePath) }

    func testListsMarkdownExtensionsCaseInsensitive() throws {
        let r = try tree(["a.md", "b.MARKDOWN", "c.mdown", "d.mkd", "e.mkdn", "f.txt", "g.md.bak"])
        XCTAssertEqual(Set(try rels(r)), ["a.md", "b.MARKDOWN", "c.mdown", "d.mkd", "e.mkdn"])
    }
    func testSkipsBuildAndVendorFolders() throws {
        let r = try tree([".git/x.md", "node_modules/p/README.md", ".build/x.md", "DerivedData/x.md", "Pods/x.md",
                          "dist/x.md", "src/dist/y.md", "keep.md", ".github/CONTRIBUTING.md"])
        XCTAssertEqual(Set(try rels(r)), ["keep.md", ".github/CONTRIBUTING.md"])
    }
    func testAgentFilesAndDocsComeFirst() throws {
        let r = try tree(["zeta.md", "AGENTS.md", "CLAUDE.md", "docs/b.md", "docs/a.md", "alpha.md", "src/CLAUDE.md", "note10.md", "note2.md"])
        XCTAssertEqual(try rels(r), ["CLAUDE.md", "AGENTS.md", "docs/a.md", "docs/b.md", "alpha.md", "note2.md", "note10.md", "src/CLAUDE.md", "zeta.md"])
    }
    func testDoesNotFollowSymlinkedDirectories() throws {          // Review Focus 1
        let r = try tree(["real/a.md"])
        try FileManager.default.createSymbolicLink(at: r.appending(path: "loop"), withDestinationURL: r)
        XCTAssertEqual(try rels(r), ["real/a.md"])
    }
    func testFileSymlinkKeepsItsOwnName() throws {                 // AGENTS.md -> CLAUDE.md is a common repo layout
        let r = try tree(["CLAUDE.md"])
        try FileManager.default.createSymbolicLink(at: r.appending(path: "AGENTS.md"), withDestinationURL: r.appending(path: "CLAUDE.md"))
        XCTAssertEqual(try rels(r), ["CLAUDE.md", "AGENTS.md"])
    }
    func testSkipsUnreadableSubfolder() throws {                   // Review Focus 1
        let r = try tree(["locked/x.md", "open.md"])
        let locked = r.appending(path: "locked").path
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: locked)
        addTeardownBlock { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: locked) }
        XCTAssertEqual(try rels(r), ["open.md"])
    }
    func testStopsAtLimit() throws {                               // Review Focus 1
        let r = try tree((1...15).map { "f\($0).md" })
        XCTAssertEqual(try rels(r, limit: 10).count, 10)
    }
}
```

- [ ] **Step 2: Run**

Run: `swift test --package-path Packages/TegelKit --filter FolderIndexFilesTests`
Expected: FAIL, `cannot find 'FolderIndex' in scope`.

- [ ] **Step 3: Implement `markdownFiles(in:limit:)`**

Use `FileManager.enumerator(at:includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey], options: [], errorHandler: { _, _ in true })`. Call `skipDescendants()` on skip-list names and symlinks.

- [ ] **Step 4: Run**

Run: `swift test --package-path Packages/TegelKit --filter FolderIndexFilesTests`
Expected: `Executed 7 tests, with 0 failures`.

Then also resolve the item itself (`item.resolvingSymlinksInPath()`) and rerun `--filter testFileSymlinkKeepsItsOwnName`. Expected: FAIL, `["CLAUDE.md", "CLAUDE.md"]`. Restore and rerun: PASS.

- [ ] **Step 5: Commit** `Packages/TegelKit/Sources/TegelKit/FolderIndex.swift Packages/TegelKit/Tests/TegelKitTests/FolderIndexFilesTests.swift`, "feat(tegelkit): FolderIndex.markdownFiles with skip rules and agent-first ordering"

---

### Task 4: FolderIndex.search

**Files:**
- Modify: `Packages/TegelKit/Sources/TegelKit/FolderIndex.swift`
- Test: `Packages/TegelKit/Tests/TegelKitTests/FolderSearchTests.swift`

**Interfaces:**
- Consumes: `TextFileLoader.load(_:maxBytes:)` (plan 01), `FolderItem` (Task 3).
- Produces (contract): `FolderIndex.search(_ query: String, in items: [FolderItem], limit: Int = 200) -> [SearchHit]`; `SearchHit { item, line, snippet }`.
- Semantics:
  - **Query:** trimmed; empty → `[]`. Literal matching via `range(of:options: [.caseInsensitive, .diacriticInsensitive])`, never a regex.
  - **Hits:** one hit per matching line. Lines are split on markdown-it's line breaks only, so `line` matches `data-line` (Task 6): `split(omittingEmptySubsequences: false, whereSeparator: { $0 == "\n" || $0 == "\r\n" || $0 == "\r" })`. CRLF is one `Character`, so it counts once; `\.isNewline` would also split on VT, FF, NEL, U+2028 and U+2029. `line` is 1-based.
  - **Reading:** files are read through `TextFileLoader` (encodings and the 5 MB cap come with it); unreadable files are skipped.
  - **Order:** item order, then line; stop at `limit`.
  - **Cancellation (K11):** before each file, check `Task.isCancelled` and return the hits so far when it's set, so a superseded query stops reading files.
  - **Snippet:** the trimmed line. If it's longer than 160 Characters, take a 160-Character window starting 60 before the match, with `…` on each cut side.

- [ ] **Step 1: Write the failing test**

```swift
final class FolderSearchTests: XCTestCase {
    private func items(_ files: [String: String]) throws -> [FolderItem] {
        let r = try tempDir(); for (p, t) in files { _ = try write(t, p, in: r) }
        return try FolderIndex.markdownFiles(in: r)
    }
    private func pairs(_ h: [SearchHit]) -> [String] { h.map { "\($0.item.relativePath):\($0.line)" } }

    func testFindsLineNumbersAcrossFiles() throws {
        let its = try items(["a.md": "one\ntwo needle\nthree", "b.md": "needle first"])
        XCTAssertEqual(pairs(FolderIndex.search("needle", in: its)), ["a.md:2", "b.md:1"])
    }
    func testCRLFLineNumbers() throws {
        XCTAssertEqual(pairs(FolderIndex.search("needle", in: try items(["a.md": "x\r\ny\r\nneedle\r\n"]))), ["a.md:3"])
        XCTAssertEqual(pairs(FolderIndex.search("needle", in: try items(["a.md": "x\u{2028}y\nneedle"]))), ["a.md:2"])   // not a markdown-it break
    }
    func testCaseAndDiacriticInsensitive() throws {
        XCTAssertEqual(FolderIndex.search("cafe needle", in: try items(["a.md": "Café NEEDLE"])).count, 1)
    }
    func testArabicIgnoresHarakat() throws {                       // Review Focus 4 ("a test file")
        XCTAssertEqual(FolderIndex.search("ملف تجريبي", in: try items(["a.md": "هذا مَلَفٌّ تَجْرِيبِيٌّ"])).count, 1)
    }
    func testQueryIsLiteralNotRegex() throws {
        let its = try items(["a.md": "a.*b and (x"])
        XCTAssertEqual(FolderIndex.search(".*b", in: its).count, 1)
        XCTAssertEqual(FolderIndex.search("(x", in: its).count, 1)
    }
    func testBlankQueryReturnsNothing() throws {
        XCTAssertEqual(FolderIndex.search("  \n ", in: try items(["a.md": "  \n "])), [])
    }
    func testSnippetWindowsLongLines() throws {
        let line = String(repeating: "a", count: 300) + "needle" + String(repeating: "b", count: 300)
        let s = try XCTUnwrap(FolderIndex.search("needle", in: try items(["a.md": line])).first).snippet
        XCTAssertTrue(s.contains("needle")); XCTAssertLessThanOrEqual(s.count, 162)
        XCTAssertTrue(s.hasPrefix("…")); XCTAssertTrue(s.hasSuffix("…"))
    }
    func testDecodesWindows1252Files() throws {
        let r = try tempDir(); let u = r.appending(path: "w.md")
        try Data(Array("caf".utf8) + [0xE9] + Array(" needle".utf8)).write(to: u)
        let hit = try XCTUnwrap(FolderIndex.search("needle", in: try FolderIndex.markdownFiles(in: r)).first)
        XCTAssertEqual(hit.snippet, "café needle")
    }
    func testRespectsLimit() throws {
        let its = try items(["a.md": Array(repeating: "needle", count: 300).joined(separator: "\n")])
        XCTAssertEqual(FolderIndex.search("needle", in: its).count, 200)
    }
    func testCancelledScanStopsBeforeReading() async throws {      // Review Focus 7; K11
        let its = try items(Dictionary(uniqueKeysWithValues: (1...50).map { ("f\($0).md", "needle") }))
        let hits = await Task { withUnsafeCurrentTask { $0?.cancel() }; return FolderIndex.search("needle", in: its) }.value
        XCTAssertEqual(hits, [])
    }
}
```

- [ ] **Step 2: Run**

Run: `swift test --package-path Packages/TegelKit --filter FolderSearchTests`
Expected: FAIL, `type 'FolderIndex' has no member 'search'`.

- [ ] **Step 3: Implement `search(_:in:limit:)` with the semantics above** (`SearchHit` as in the contract)

- [ ] **Step 4: Run**

Run: `swift test --package-path Packages/TegelKit --filter FolderSearchTests`
Expected: `Executed 10 tests, with 0 failures`.

Then comment out the `Task.isCancelled` check and rerun `--filter testCancelledScanStopsBeforeReading`. Expected: FAIL, 50 hits instead of `[]`. Restore the check and rerun: PASS.

Then split on `\.isNewline` instead and rerun `--filter testCRLFLineNumbers`. Expected: FAIL, `a.md:3` for the U+2028 file. Restore and rerun: PASS.

- [ ] **Step 5: Commit** `Packages/TegelKit/Sources/TegelKit/FolderIndex.swift Packages/TegelKit/Tests/TegelKitTests/FolderSearchTests.swift`, "feat(tegelkit): literal cross-file search with line numbers and windowed snippets"

---

### Task 5: FileWatcher

**Files:**
- Create: `Packages/TegelKit/Sources/TegelKit/FileWatcher.swift`
- Test: `Packages/TegelKit/Tests/TegelKitTests/FileWatcherTests.swift`

**Interfaces:**
- Produces (contract): `FileWatcher(url:debounce:onChange:)`, `stop()`.
- Approach: an FSEvents stream ([File System Events](https://developer.apple.com/documentation/coreservices/file_system_events)).
  - **Watched path:** `url` if it's a folder, otherwise its parent.
  - **Flags:** `kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes`, from `kFSEventStreamEventIdSinceNow`.
  - **Debounce:** latency = `debounce` in seconds. FSEvents batches everything inside that window, and that batching is the debounce.
  - **Queue:** a private serial `DispatchQueue`.
  - **Filtering:** for a file `url`, fire only when some event path equals the file's path. Compare `resolvingSymlinksInPath().path` on both sides, because FSEvents reports `/private/var/…`.
  - **Callback:** one `onChange()` per delivered batch.
  - **Teardown:** `stop()` is idempotent (stop, invalidate, release); `deinit` calls it.

- [ ] **Step 1: Write the failing test**

```swift
final class Counter: @unchecked Sendable { private let lock = NSLock(); private var n = 0
    func hit() { lock.withLock { n += 1 } }; var value: Int { lock.withLock { n } } }

final class FileWatcherTests: XCTestCase {
    private func settle() async throws { try await Task.sleep(for: .milliseconds(300)) }   // let creation events pass before watching
    func testBurstOfWritesFiresOnce() async throws {               // Review Focus 2
        let r = try tempDir(); let f = try write("0", "a.md", in: r); try await settle()
        let c = Counter(); let w = FileWatcher(url: f) { c.hit() }; defer { w.stop() }
        for i in 1...5 { try "\(i)".write(to: f, atomically: false, encoding: .utf8); try await Task.sleep(for: .milliseconds(5)) }
        try await Task.sleep(for: .seconds(1)); XCTAssertEqual(c.value, 1)
    }
    func testSeparateBurstsFireSeparately() async throws {
        let r = try tempDir(); let f = try write("0", "a.md", in: r); try await settle()
        let c = Counter(); let w = FileWatcher(url: f) { c.hit() }; defer { w.stop() }
        try "1".write(to: f, atomically: false, encoding: .utf8); try await Task.sleep(for: .milliseconds(600))
        try "2".write(to: f, atomically: false, encoding: .utf8); try await Task.sleep(for: .milliseconds(600))
        XCTAssertEqual(c.value, 2)
    }
    func testSiblingChangeDoesNotFireFileWatcher() async throws {
        let r = try tempDir(); let f = try write("0", "a.md", in: r); try await settle()
        let c = Counter(); let w = FileWatcher(url: f) { c.hit() }; defer { w.stop() }
        _ = try write("x", "b.md", in: r); try await Task.sleep(for: .milliseconds(800)); XCTAssertEqual(c.value, 0)
    }
    func testAtomicReplaceFiresFileWatcher() async throws {        // Review Focus 2
        let r = try tempDir(); let f = try write("0", "a.md", in: r); try await settle()
        let c = Counter(); let w = FileWatcher(url: f) { c.hit() }; defer { w.stop() }
        try Data("new".utf8).write(to: f, options: .atomic); try await Task.sleep(for: .seconds(1)); XCTAssertGreaterThanOrEqual(c.value, 1)
    }
    func testNestedChangeFiresFolderWatcher() async throws {
        let r = try tempDir(); try await settle()
        let c = Counter(); let w = FileWatcher(url: r) { c.hit() }; defer { w.stop() }
        _ = try write("x", "sub/deep/x.md", in: r); try await Task.sleep(for: .seconds(1)); XCTAssertGreaterThanOrEqual(c.value, 1)
    }
    func testStopSilencesWatcher() async throws {
        let r = try tempDir(); let f = try write("0", "a.md", in: r); try await settle()
        let c = Counter(); let w = FileWatcher(url: f) { c.hit() }; w.stop()
        try "1".write(to: f, atomically: false, encoding: .utf8); try await Task.sleep(for: .milliseconds(800)); XCTAssertEqual(c.value, 0)
    }
}
```

- [ ] **Step 2: Run**

Run: `swift test --package-path Packages/TegelKit --filter FileWatcherTests`
Expected: FAIL, `cannot find 'FileWatcher' in scope`.

- [ ] **Step 3: Implement `FileWatcher` as specified**

- [ ] **Step 4: Run three times, to catch timing flakiness**

Run: `for i in 1 2 3; do swift test --package-path Packages/TegelKit --filter FileWatcherTests || break; done`
Expected: `Executed 6 tests, with 0 failures`, three times.

- [ ] **Step 5: Commit** `Packages/TegelKit/Sources/TegelKit/FileWatcher.swift Packages/TegelKit/Tests/TegelKitTests/FileWatcherTests.swift`, "feat(tegelkit): FSEvents FileWatcher with latency-based debounce"

---

### Task 6: Source-line anchors and scroll APIs

**Files:**
- Modify: `Renderer/src/markdown.js` (add `data-line`)
- Modify: `Renderer/src/page.js` (add `window.tegel.scrollToLine`)
- Modify: `Renderer/src/css/base.css` (add `.tg-hit`, a background of `color-mix(in srgb, var(--tg-link) 14%, transparent)`)
- Modify: `Packages/TegelKit/Sources/TegelKit/RendererWebView.swift`
- Modify: `Packages/TegelKit/Tests/TegelKitTests/TestSupport.swift` (add `hosted` only; `fixtureURL(_:)` and `js(_:_:)` are plan 01's)
- Regenerate: `Packages/TegelKit/Sources/TegelKit/Resources/Renderer/`
- Test: `Renderer/test/lines.test.js`, `Packages/TegelKit/Tests/TegelKitTests/WebView/NavigationTests.swift`

**Interfaces:**
- Consumes: `RendererWebView.render`, `RenderResult.headings` (contract).
- Produces:
  - **HTML:** every block-level opening token with a markdown-it `map` gets `data-line="<map[0] + 1 + front-matter line offset>"`. That is the 1-based line in the file as loaded, which is the same numbering as `SearchHit.line`.
  - **JS:** `window.tegel.scrollToLine(line: number): boolean`.
    - It picks the last element in document order whose `data-line` ≤ `line`, calls `scrollIntoView({block: 'start'})`, and moves the class `tg-hit` onto it.
    - It returns `false` when there are no anchors.
  - **Swift:**
    - `public func scroll(toLine line: Int) async -> Bool` on `RendererWebView` (addition).
    - `public func scroll(toHeading id: String) async` (contract; implement it if plan 01 left it a stub).
  - **TestSupport:**
    - `@MainActor func hosted(width: CGFloat = 800, height: CGFloat = 600) -> RendererWebView`: puts the web view in an offscreen borderless `NSWindow` that's kept alive.
    - Reused from plan 01, not redeclared: `fixtureURL(_ name: String) -> URL` and `@MainActor js(_ r: RendererWebView, _ body: String) async throws -> Any?`. `js` runs a function body, so each script below `return`s its value.

- [ ] **Step 1: Write the failing tests**

```js
// Renderer/test/lines.test.js
import { test, expect } from "bun:test";
import { renderToHTML } from "../src/markdown.js";
test("block elements carry 1-based source lines", () => {
  const html = renderToHTML("# Title\n\nFirst para\n\n- item\n\n```js\nx\n```\n", { mode: "window" });
  expect(html).toMatch(/<h1[^>]*data-line="1"/);
  expect(html).toMatch(/<p[^>]*data-line="3"/);
  expect(html).toMatch(/<ul[^>]*data-line="5"/);
  expect(html).toMatch(/data-line="7"/);
});
test("line numbers count YAML front matter lines", () => {
  expect(renderToHTML("---\ntitle: x\n---\n\nBody line\n", { mode: "window" })).toMatch(/<p[^>]*data-line="5"/);
});
```

```swift
@MainActor final class NavigationTests: XCTestCase {
    private let filler = (1...100).map { "Filler \($0)" }.joined(separator: "\n\n")
    // Plan 09's base.css smooth-scrolls under prefers-reduced-motion: no-preference, and WebKit on macOS 15.7 has no
    // scrollend event: turn smooth scrolling off so a read right after a scroll sees where it ends.
    private func instantScroll(_ r: RendererWebView) async throws { _ = try await js(r, "document.documentElement.style.scrollBehavior = 'auto'; return true") }

    func testScrollToLineMovesViewport() async throws {
        let r = hosted()
        let md = (1...200).map { "Paragraph \($0)" }.joined(separator: "\n\n")        // paragraph N sits on line 2N-1
        _ = try await r.render(md, options: RenderOptions(mode: .window, theme: .paper, baseURL: nil)); try await instantScroll(r)
        let moved = await r.scroll(toLine: 301)
        let y = try await js(r, "return scrollY") as? Double ?? 0
        let hit = try await js(r, "return document.querySelector('.tg-hit').textContent.trim()") as? String
        XCTAssertTrue(moved); XCTAssertGreaterThan(y, 0); XCTAssertEqual(hit, "Paragraph 151")
    }
    func testScrollToHeadingMovesViewport() async throws {
        let r = hosted()
        let md = filler + "\n\n## Target heading\n\n" + filler                          // filler after it too, so it can reach the top
        let res = try await r.render(md, options: RenderOptions(mode: .window, theme: .paper, baseURL: nil)); try await instantScroll(r)
        let id = try XCTUnwrap(res.headings.last).id
        await r.scroll(toHeading: id)
        let top = try await js(r, "return document.getElementById('\(id)').getBoundingClientRect().top") as? Double ?? -1
        XCTAssertTrue((-1...40).contains(top), "top \(top)")                          // scrollY is whole pixels: -0.09 seen on the build Mac
    }
    func testScrollToArabicHeading() async throws {
        let r = hosted(); let url = fixtureURL("rtl-arabic.md")
        let res = try await r.render(try TextFileLoader.load(url).text + "\n\n" + filler, options: RenderOptions(mode: .window, theme: .paper, baseURL: url))
        try await instantScroll(r)
        let h = try XCTUnwrap(res.headings.last)
        await r.scroll(toHeading: h.id)
        let top = try await js(r, "return document.getElementById(\(String(reflecting: h.id))).getBoundingClientRect().top") as? Double ?? -1
        XCTAssertTrue((-1...40).contains(top), "top \(top)")
    }
}
// XCTest assertions take autoclosures, which can't `await`: bind async results to a `let` first (applies to every test in this plan).
```

- [ ] **Step 2: Run**

Run: `(cd Renderer && bun test test/lines.test.js); swift test --package-path Packages/TegelKit --filter NavigationTests`
Expected:
- bun: 2 failures (no `data-line`);
- swift: `value of type 'RendererWebView' has no member 'scroll(toLine:)'`.

- [ ] **Step 3: Implement**

- **markdown.js:** a core rule after `block` sets `data-line` on tokens with `map` and `nesting !== -1`. It adds the number of lines the front-matter step removed.
- **page.js:** `scrollToLine` as specified.
- **Swift:** `scroll(toLine:)` calls `evaluateJavaScript("window.tegel.scrollToLine(\(line))")` and casts the result to `Bool`.
- Then run `make renderer`.

- [ ] **Step 4: Run**

Run: `(cd Renderer && bun test) && swift test --package-path Packages/TegelKit --filter NavigationTests`
Expected: bun `0 fail` (plan 01's tests still pass); swift `Executed 3 tests, with 0 failures`.

Then drop the second `filler` from `testScrollToHeadingMovesViewport` (the heading becomes the last block) and rerun `--filter testScrollToHeadingMovesViewport`. Expected: FAIL, `top` ≈ 550: the page can't scroll past its end (measured on the build Mac). Restore and rerun: PASS. Task 10 Step 0 watches `instantScroll` fail once plan 09's smooth scrolling is in.

- [ ] **Step 5: Commit** `Renderer/src Renderer/test/lines.test.js Packages/TegelKit/Sources/TegelKit Packages/TegelKit/Tests/TegelKitTests/WebView/NavigationTests.swift Packages/TegelKit/Tests/TegelKitTests/TestSupport.swift`, "feat(renderer): source-line anchors, scroll(toLine:) and heading scroll"

---

### Task 7: Outline inspector and find in page

**UI spec:** DESIGN.md (§9 symbols) and app-ui-spec (Steps 1, 3, 7).

**Files:**
- Modify: `Packages/TegelKit/Sources/TegelKit/RendererWebView.swift` (add `find`)
- Create: `Apps/Markdown/App/ReaderController.swift`. If plan 01 already has a per-window model, add these members to it instead.
- Create: `Apps/Markdown/App/FindBar.swift`, `Apps/Markdown/App/OutlineView.swift`, `Apps/Markdown/App/AppCommands.swift`
- Modify: `Apps/Markdown/App/DocumentView.swift` (toolbar), `Apps/Markdown/App/MarkdownApp.swift` (add `.commands { AppCommands(isPro:); InspectorCommands() }`)
- Test: `Packages/TegelKit/Tests/TegelKitTests/WebView/FindTests.swift`

**Interfaces:**
- Produces (TegelKit, addition): `public func find(_ text: String, backwards: Bool = false) async -> Bool`.
  - It wraps `WKWebView.find(_:configuration:)`; the API is public on macOS 11.0+ ([find(_:configuration:completionHandler:)](https://developer.apple.com/documentation/webkit/wkwebview/find(_:configuration:completionhandler:))).
  - It uses a `WKFindConfiguration` with `caseSensitive = false`, `wraps = true` and `backwards`, macOS 10.15.4+ ([WKFindConfiguration](https://developer.apple.com/documentation/webkit/wkfindconfiguration)).
  - It returns `WKFindResult.matchFound` ([WKFindResult](https://developer.apple.com/documentation/webkit/wkfindresult)).
  - WebKit selects the match and scrolls to it.
- Produces (app):
```swift
@MainActor @Observable final class ReaderController {
    let renderer: RendererWebView
    private(set) var headings: [Heading]
    var findVisible: Bool; var findQuery: String; private(set) var findMissed: Bool
    func render(_ text: String, baseURL: URL?) async          // Task 10 adds the theme
    func findNext(backwards: Bool) async                       // sets findMissed
}
extension FocusedValues { @Entry var reader: ReaderController? }
struct AppCommands: Commands { let isPro: Bool }
```
- Menus, in this task:
  - Edit ▸ Find, via `CommandGroup(replacing: .textEditing)` so the system's own ⌘F item isn't duplicated: "Find…" ⌘F (shows the bar and focuses it), "Find Next" ⌘G, "Find Previous" ⇧⌘G.
  - Outline toggle: View ▸ Show/Hide Inspector, from `InspectorCommands()`.
- The outline is `.inspector(isPresented:)` (macOS 14.0+). Rows are indented `(level - 1) * 12` pt; a click calls `scroll(toHeading:)`; the empty state is "No headings". It's free.
- Find bar: a `.safeAreaInset(edge: .top)` holding:
  - a TextField with placeholder "Find" (Return = next);
  - "Previous" and "Next" buttons;
  - "Not found" when `findMissed`;
  - "Done", which Esc also triggers.
  - It's free.
- Toolbar (`DESIGN.md` §9; app-ui-spec Step 1): icon-only items with text labels, customisable. This task adds Find (`magnifyingglass`) and, last on the trailing side, Show/Hide Outline (`sidebar.trailing`). Task 10 adds Theme (`textformat`, a menu) and Task 12 adds Export as PDF (`arrow.up.doc`), both in a `ToolbarItemGroup(placement: .primaryAction)`.

- [ ] **Step 1: Write the failing test**

```swift
@MainActor final class FindTests: XCTestCase {
    func testFindReportsMatchAndMiss() async throws {
        let r = hosted(); _ = try await r.render("alpha beta gamma", options: RenderOptions(mode: .window, theme: .paper, baseURL: nil))
        let hit = await r.find("BETA"); let miss = await r.find("zzzq")
        XCTAssertTrue(hit); XCTAssertFalse(miss)
    }
    func testFindInsideCodeBlock() async throws {
        let r = hosted(); _ = try await r.render("```\nlet needle = 1\n```", options: RenderOptions(mode: .window, theme: .paper, baseURL: nil))
        let found = await r.find("needle"); XCTAssertTrue(found)
    }
    func testFindArabicWord() async throws {
        let r = hosted(); _ = try await r.render("فقرة عربية للتجربة", options: RenderOptions(mode: .window, theme: .paper, baseURL: nil))
        let found = await r.find("عربية"); XCTAssertTrue(found)
    }
}
```

- [ ] **Step 2: Run**

Run: `swift test --package-path Packages/TegelKit --filter FindTests`
Expected: FAIL, `value of type 'RendererWebView' has no member 'find'`.

- [ ] **Step 3: Implement `find`, then the app views and commands as specified**

- [ ] **Step 4: Run, then check by hand**

Run: `swift test --package-path Packages/TegelKit --filter FindTests && make test-app && make run-app FILES="Fixtures/markdown/gfm-kitchen-sink.md Fixtures/markdown/rtl-arabic.md"`
Expected: `Executed 3 tests, with 0 failures`, then `** TEST SUCCEEDED **`. Then check by hand:
- ⌘F focuses the bar; Return selects the first match.
- ⌘G and ⇧⌘G move through matches; "zzzq" shows "Not found"; Esc closes the bar.
- The inspector toggles from the View menu and the toolbar; clicking an Arabic heading scrolls to it.

- [ ] **Step 5: Commit** `Packages/TegelKit/Sources/TegelKit/RendererWebView.swift Packages/TegelKit/Tests/TegelKitTests/WebView/FindTests.swift Apps/Markdown/App`, "feat(app): outline inspector and find bar on the public WKWebView find API"

---

### Task 8: Local images through `tegel-doc:` (risk P4; K4)

**UI spec:** app-ui-spec, the "Show Images" bar.

Local images never load from `file:`. WebKit asks a `WKURLSchemeHandler` for `tegel-doc:` URLs, and the handler reads with the app's own security-scoped grant ([`WKURLSchemeHandler`](https://developer.apple.com/documentation/webkit/wkurlschemehandler), [`setURLSchemeHandler(_:forURLScheme:)`](https://developer.apple.com/documentation/webkit/wkwebviewconfiguration/seturlschemehandler(_:forurlscheme:))). So the sandboxed WebContent process needs no read access to user folders, and nothing outside the grant root is ever served. Plan 01 owns the CSP (`img-src 'self' data: tegel-doc:`) and the `fileImages` sanitiser branch that keeps `tegel-doc:` on `img[src]` only, with their tests.

**Files:**
- Create: `Packages/TegelKit/Sources/TegelKit/DocumentImageHandler.swift` (the handler and `URL.isInside(_:)`)
- Modify: `Packages/TegelKit/Sources/TegelKit/RendererWebView.swift` (register the handler in `init`; `readAccessURL`; `loadedImages(outside:)`; `baseHref` as a `tegel-doc:` URL)
- Modify: `Renderer/src/markdown.js` (relative image `src` → `tegel-doc:` via `baseHref`), `Renderer/src/page.js` (image wait and `image:` errors); regenerate the resources
- Modify: `Packages/TegelKit/Tests/TegelKitTests/TestSupport.swift` (add `squarePNG`)
- Create: `Fixtures/markdown/local-image.md` (`# Local image` / `![Grey square](assets/square.png)`) and `Fixtures/markdown/assets/square.png`
- Create: `Apps/Markdown/App/Grants.swift`, `Apps/Markdown/App/ImageGrantBar.swift`
- Create: `Apps/Markdown/AppTests/AppTestSupport.swift`, holding app-target copies of `tempDir`, `write`, `hosted`, `js` (plan 01's signature and body) and `squarePNG` (test helpers can't be shared across test targets)
- Modify: `ReaderController.swift`; `DocumentView.swift` (render with `baseURL: fileURL`, the document, per master §3.3: plan 01's `fileURL?.deletingLastPathComponent()` would resolve `assets/x.png` one folder too high and widen the default root); `MarkdownApp.swift` (`App.init` runs `Grants.roots = BookmarkStore.resolveAll()`)
- Test: `Renderer/test/images.test.js`, `Packages/TegelKit/Tests/TegelKitTests/DocumentImageHandlerTests.swift`, `Packages/TegelKit/Tests/TegelKitTests/WebView/LocalImageTests.swift`, `Apps/Markdown/AppTests/{SandboxImageTests,GrantsTests}.swift`

**Interfaces:**
- Produces (TegelKit):
```swift
extension URL {
    /// True when this file URL is `root` or lies under it. Compares `pathComponents` after
    /// `standardizedFileURL.resolvingSymlinksInPath()` on both sides, never a string prefix.
    public func isInside(_ root: URL) -> Bool
}
@MainActor final class DocumentImageHandler: NSObject, WKURLSchemeHandler {   // RendererWebView.init registers it for "tegel-doc"
    var root: URL?                                                           // set by every render
    private(set) var served: [URL]                                           // resolved files answered 200; reset when a render starts
    nonisolated static func response(for request: URL, root: URL?) -> (HTTPURLResponse, Data)   // 200 + bytes, or 404 + no body
}
// RendererWebView additions
public var readAccessURL: URL?                           // the grant root the handler serves images from; nil → the document's folder; no baseURL → nothing
public func loadedImages(outside folder: URL) -> [URL]   // served since the last render began, not inside `folder`; request order, no duplicates
```
- `response(for:root:)` answers 200 only when all hold, otherwise 404 with no body:
  1. `root` is non-nil and the scheme is `tegel-doc`. The host is ignored.
  2. `let file = URL(fileURLWithPath: request.path(percentEncoded: false))`. Decoding first turns `%2E%2E` into `..`, which `isInside` then standardises.
  3. `file.isInside(root)`.
  4. `resourceValues(forKeys: [.isRegularFileKey, .contentTypeKey])` gives a regular file whose content type conforms to `UTType.image`.
  5. `Data(contentsOf: file, options: .mappedIfSafe)` succeeds.
  The 200 carries `Content-Type: <contentType.preferredMIMEType>`. `webView(_:start:)` sends the response, the data and `didFinish()`, and appends the resolved file to `served` on 200. `webView(_:stop:)` does nothing, because the answer was already sent. `// ponytail: synchronous mapped read on the main actor; move to a detached read if large images stall the window.`
- `render` sets `handler.root = options.baseURL.map { readAccessURL ?? $0.deletingLastPathComponent() }` (no `baseURL` → nil, even with `readAccessURL` set; master §3.3), clears `served`, and passes `baseHref` = `options.baseURL` with its scheme set to `tegel-doc` through `URLComponents` (`tegel-doc:///Users/u/notes/my%20doc.md`). Quick Look passes `baseURL: nil`, so its root is nil and it serves nothing.
- Produces (JS):
  - **Relative images:** when `opts.baseHref` is set, `renderToHTML`'s `image` render rule (reading `baseHref` from markdown-it's `env`) rewrites a relative `src` (no scheme, not starting `//` or `#`) to `new URL(src, baseHref).href`, a `tegel-doc:` URL. Nothing else is rewritten. Don't use `<base>`: it would re-point the lazy `mermaid.min.js` load.
  - **Image wait:** when `mode !== 'quicklook'`, `page.js` waits for every `img` whose `src` starts with `tegel-doc:` (`load`/`error`, at most 1,500 ms in total) before posting `rendered`. Each failure is appended to `errors` as `"image: " + src`. This also makes print mode wait for images.
- Produces (app):
```swift
@MainActor enum Grants { static var roots: [URL]; static func root(containing url: URL) -> URL? }   // the first root with url.isInside(root)
extension ReaderController { var needsImageGrant: Bool { get } }  // any error hasPrefix("image: ") && Grants.root(containing: doc) == nil
```
- Bar copy:
  - Text: "Some images in this document are in a folder Tegel Markdown hasn't been allowed to read."
  - Button: "Show Images…".
- Button action:
  1. `NSOpenPanel` with `canChooseDirectories = true`, `canChooseFiles = false`, `directoryURL` = the document's folder, `prompt` "Allow", `message` "Choose a folder that holds both this document and its images. Tegel Markdown only reads from it."
  2. If the document isn't inside the chosen folder (`!doc.isInside(folder)`; master §3.2: the grant root contains the document), show an `NSAlert` sheet, message "This folder doesn't contain the document.", informative text "Choose the document's folder, or a folder above it that also holds the images." Nothing is saved and the bar stays.
  3. `BookmarkStore.save`, then append the folder to `Grants.roots`.
  4. Set `renderer.readAccessURL` to the chosen folder and re-render.
- Single-file windows set `renderer.readAccessURL = Grants.root(containing: fileURL)`. Other `errors` keep plan 01's display; `image:` entries only drive the bar.

- [ ] **Step 1: Create the fixture PNG** (the standard 1×1 PNG)

Run: `mkdir -p Fixtures/markdown/assets && echo 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==' | base64 -D > Fixtures/markdown/assets/square.png && sips -g pixelWidth Fixtures/markdown/assets/square.png`
Expected: `pixelWidth: 1`. Add `squarePNG: Data` (the same base64) to TestSupport.

- [ ] **Step 2: Write the failing tests**

```js
// Renderer/test/images.test.js
import { test, expect } from "bun:test";
import { renderToHTML } from "../src/markdown.js";

test("relative images become tegel-doc: URLs against baseHref; nothing else is rewritten", () => {
  const md = "![sq](assets/square.png) ![up](../shared/up.png) ![w](https://example.com/w.png) ![d](data:image/png;base64,AA==)";
  const html = renderToHTML(md, { mode: "window", baseHref: "tegel-doc:///Users/u/notes/doc.md" });
  expect(html).toContain('src="tegel-doc:///Users/u/notes/assets/square.png"');
  expect(html).toContain('src="tegel-doc:///Users/u/shared/up.png"');
  expect(html).toContain('src="https://example.com/w.png"');
  expect(html).toContain('src="data:image/png;base64,AA=="');
});
test("without baseHref an image src is left alone", () => {
  expect(renderToHTML("![sq](assets/square.png)", { mode: "window" })).toContain('src="assets/square.png"');
});
```

```swift
final class DocumentImageHandlerTests: XCTestCase {
    private var root: URL!
    override func setUpWithError() throws {
        let base = try tempDir(); root = base.appending(path: "notes")
        try FileManager.default.createDirectory(at: root.appending(path: "assets"), withIntermediateDirectories: true)
        try squarePNG.write(to: root.appending(path: "assets/in.png")); _ = try write("# x", "a.md", in: root)
        try squarePNG.write(to: base.appending(path: "secret.png"))
        try FileManager.default.createSymbolicLink(at: root.appending(path: "link.png"), withDestinationURL: base.appending(path: "secret.png"))
        try FileManager.default.createSymbolicLink(at: root.appending(path: "shared"), withDestinationURL: base)   // a folder link out of the root
    }
    private func req(_ rel: String) -> URL { URL(string: "tegel-doc://" + root.path(percentEncoded: true) + "/" + rel)! }
    private func status(_ u: URL, root: URL?) -> Int { DocumentImageHandler.response(for: u, root: root).0.statusCode }

    func testServesImageInsideRoot() {
        let (resp, data) = DocumentImageHandler.response(for: req("assets/in.png"), root: root)
        XCTAssertEqual(resp.statusCode, 200); XCTAssertEqual(resp.value(forHTTPHeaderField: "Content-Type"), "image/png")
        XCTAssertEqual(data, squarePNG)
    }
    func testDotDotEscapeIs404() {                                 // Review Focus 6; S12
        XCTAssertEqual(status(req("../secret.png"), root: root), 404)
        XCTAssertEqual(status(req("%2E%2E/secret.png"), root: root), 404)
    }
    func testEverythingElseIs404() {                               // Review Focus 6
        XCTAssertEqual(status(req("shared/secret.png"), root: root), 404) // through a symlinked folder: only isInside stops it
        XCTAssertEqual(status(req("link.png"), root: root), 404)          // file symlink: its resource values describe the link, not an image
        XCTAssertEqual(status(req("a.md"), root: root), 404)              // not an image
        XCTAssertEqual(status(req("assets/nope.png"), root: root), 404)   // missing
        XCTAssertEqual(status(req("assets/in.png"), root: nil), 404)      // no root: Quick Look
    }
}
```

```swift
@MainActor final class LocalImageTests: XCTestCase {
    private func setUpDoc(_ md: String, at rel: String) throws -> (root: URL, doc: URL) {
        let root = try tempDir(); let doc = try write(md, rel, in: root)
        try FileManager.default.createDirectory(at: root.appending(path: "assets"), withIntermediateDirectories: true)
        try squarePNG.write(to: root.appending(path: "assets/square.png")); return (root, doc)
    }
    private func width(_ r: RendererWebView) async throws -> Int? { try await js(r, "return document.images[0].naturalWidth") as? Int }

    func testRelativeImageLoadsNextToDocument() async throws {
        let (_, doc) = try setUpDoc("![sq](assets/square.png)", at: "doc.md"); let r = hosted()
        let res = try await r.render("![sq](assets/square.png)", options: RenderOptions(mode: .window, theme: .paper, baseURL: doc))
        let w = try await width(r)
        XCTAssertEqual(w, 1); XCTAssertFalse(res.errors.contains { $0.hasPrefix("image: ") })
    }
    func testParentRelativeImageLoadsWithReadAccessRoot() async throws {
        let (root, doc) = try setUpDoc("![sq](../assets/square.png)", at: "docs/page.md"); let r = hosted(); r.readAccessURL = root
        _ = try await r.render("![sq](../assets/square.png)", options: RenderOptions(mode: .window, theme: .paper, baseURL: doc))
        let w = try await width(r)
        XCTAssertEqual(w, 1)
    }
    func testImageAboveTheRootIsNotServed() async throws {          // default root = the document's folder
        let (_, doc) = try setUpDoc("![sq](../assets/square.png)", at: "docs/page.md"); let r = hosted()
        let res = try await r.render("![sq](../assets/square.png)", options: RenderOptions(mode: .window, theme: .paper, baseURL: doc))
        let w = try await width(r)
        XCTAssertEqual(w, 0); XCTAssertTrue(res.errors.contains { $0.hasPrefix("image: ") && $0.hasSuffix("square.png") })
    }
    func testMissingImageIsReported() async throws {
        let (_, doc) = try setUpDoc("![x](assets/nope.png)", at: "doc.md"); let r = hosted()
        let res = try await r.render("![x](assets/nope.png)", options: RenderOptions(mode: .window, theme: .paper, baseURL: doc))
        XCTAssertTrue(res.errors.contains { $0.hasPrefix("image: ") && $0.hasSuffix("nope.png") })
    }
    func testHiddenOutsideFolderImageIsListedForExport() async throws {   // Review Focus 6; S3 option A
        let md = "![in](assets/square.png)\n\n<span style=\"display:inline-block;width:1px;height:1px;overflow:hidden\">![](../outside.png)</span>\n"
        let root = try tempDir(); let doc = try write(md, "docs/page.md", in: root)
        try FileManager.default.createDirectory(at: root.appending(path: "docs/assets"), withIntermediateDirectories: true)
        try squarePNG.write(to: root.appending(path: "docs/assets/square.png")); try squarePNG.write(to: root.appending(path: "outside.png"))
        let r = RendererWebView(); r.readAccessURL = root                                  // the export path: fresh, offscreen, print mode
        _ = try await r.render(md, options: RenderOptions(mode: .print, theme: .paper, baseURL: doc))
        XCTAssertEqual(r.loadedImages(outside: doc.deletingLastPathComponent()).map(\.lastPathComponent), ["outside.png"])
    }
}
```

- [ ] **Step 3: Run**

Run: `(cd Renderer && bun test test/images.test.js); swift test --package-path Packages/TegelKit --filter 'DocumentImageHandlerTests|LocalImageTests'`
Expected:
- bun: 1 fail (the `tegel-doc:` rewrite), 1 pass (nothing rewrites yet);
- swift: FAIL, `cannot find 'DocumentImageHandler' in scope`.

- [ ] **Step 4: Implement `isInside`, `DocumentImageHandler`, the `RendererWebView` changes, the `baseHref` image rule and the `page.js` image wait, then `make renderer`**

Plan 01's `render` already sends a `baseHref` key; it now carries the `tegel-doc:` form.

- [ ] **Step 5: Run the unsandboxed tests**

Run: `(cd Renderer && bun test) && swift test --package-path Packages/TegelKit --filter 'DocumentImageHandlerTests|LocalImageTests'`
Expected: bun `0 fail` (plan 01's tests, including its `fileImages` hook tests, still pass); swift `Executed 8 tests, with 0 failures`.

- [ ] **Step 6: Write the app tests, then run**

```swift
@MainActor final class GrantsTests: XCTestCase {
    func testRootContainingComparesPathComponents() throws {        // Review Focus 6; S12
        let base = try tempDir(); let notes = base.appending(path: "notes"), old = base.appending(path: "notes-old")
        for d in [notes, old] { try FileManager.default.createDirectory(at: d, withIntermediateDirectories: true) }
        let saved = Grants.roots; Grants.roots = [notes]; defer { Grants.roots = saved }
        XCTAssertNil(Grants.root(containing: old.appending(path: "a.md")))
        XCTAssertEqual(Grants.root(containing: notes.appending(path: "sub/a.md")), notes)
    }
}

@MainActor final class SandboxImageTests: XCTestCase {
    private func width(_ r: RendererWebView) async throws -> Int? { try await js(r, "return document.images[0].naturalWidth") as? Int }
    func testImageLoadsInsideSandboxedApp() async throws {          // tempDir() is in the app container
        let root = try tempDir(); let doc = try write("![sq](assets/square.png)", "doc.md", in: root)
        try FileManager.default.createDirectory(at: root.appending(path: "assets"), withIntermediateDirectories: true)
        try squarePNG.write(to: root.appending(path: "assets/square.png"))
        let r = hosted(); _ = try await r.render("![sq](assets/square.png)", options: RenderOptions(mode: .window, theme: .paper, baseURL: doc))
        let w = try await width(r)
        XCTAssertEqual(w, 1)
    }
    func testBookmarkedFolderOutsideContainerServesImages() async throws {   // CR-P2-24; needs Step 8's grant
        guard let root = Grants.roots.first(where: { $0.pathComponents.suffix(2) == ["Fixtures", "markdown"] })
        else { throw XCTSkip("Grant Fixtures/markdown through Show Images… first (Task 8 Step 8)") }
        let doc = root.appending(path: "local-image.md"); let r = hosted(); r.readAccessURL = Grants.root(containing: doc)
        _ = try await r.render(try TextFileLoader.load(doc).text, options: RenderOptions(mode: .window, theme: .paper, baseURL: doc))
        let w = try await width(r)
        XCTAssertEqual(w, 1)
    }
}
```

Run: `make test-app ONLY=GrantsTests`
Expected: FAIL, `cannot find 'Grants' in scope`.

- [ ] **Step 7: Implement `Grants`, `ImageGrantBar` and the wiring, then run**

Run: `make test-app ONLY=GrantsTests && make test-app ONLY=SandboxImageTests`
Expected: `Executed 1 test, with 0 failures`; then `testImageLoadsInsideSandboxedApp` passed and `testBookmarkedFolderOutsideContainerServesImages` skipped ("Grant Fixtures/markdown…").

- [ ] **Step 8: Grant a folder outside the container by hand, then prove it serves images**

Run: `make run-app FILES="Fixtures/markdown/local-image.md"`
Expected:
1. The bar shows (the 1×1 image failed: the repo is outside the container).
2. "Show Images…" opens the panel at `Fixtures/markdown`. Choose `Fixtures/markdown/assets` first: the "This folder doesn't contain the document." alert shows and the bar stays. Then "Show Images…" again and "Allow" on `Fixtures/markdown`: the bar goes.
3. After ⌘Q and the same command again, there's no bar: the bookmark resolved at launch.

Then quit the app and run: `make test-app ONLY=SandboxImageTests`
Expected: `Executed 2 tests, with 0 failures`, with `testBookmarkedFolderOutsideContainerServesImages` passed, not skipped. If it still skips after the grant (the Debug rebuild changed the code signature and the bookmark no longer resolves), record that in `docs/reviews/m02.md` and repeat the grant and the test without rebuilding in between.

- [ ] **Step 9: Watch the path guards fail**

Replace `isInside`'s body with `path(percentEncoded: false).hasPrefix(root.path(percentEncoded: false))` (the naive string prefix), then run: `swift test --package-path Packages/TegelKit --filter DocumentImageHandlerTests; make test-app ONLY=GrantsTests`
Expected: FAIL in `testDotDotEscapeIs404` and `testEverythingElseIs404` (the `shared/` folder case; `link.png` 404s on its type either way), and in `testRootContainingComparesPathComponents` (`notes-old`). Restore the body and rerun both: `Executed 3 tests, with 0 failures` and `Executed 1 test, with 0 failures`.

- [ ] **Step 10: Commit** `Packages/TegelKit Renderer/src/markdown.js Renderer/src/page.js Renderer/test/images.test.js Fixtures/markdown/local-image.md Fixtures/markdown/assets Apps/Markdown/App Apps/Markdown/AppTests docs/reviews/m02.md`, "feat: local images through the tegel-doc: scheme handler, grant-root check, failure reporting and Show Images grant"

---

### Task 9: Folder window (Pro)

**UI spec:** app-ui-spec (Steps 2, 7).

**Files:**
- Create: `Apps/Markdown/App/FolderModel.swift`, `Apps/Markdown/App/FolderWindow.swift`
- Modify: `Apps/Markdown/AppTests/AppTestSupport.swift` (add `eventually`)
- Modify: `MarkdownApp.swift` (`WindowGroup("Folder", id: "folder", for: URL.self) { $url in FolderWindow(root: url) }`), `AppCommands.swift`
- Test: `Apps/Markdown/AppTests/FolderModelTests.swift`

**Interfaces:**
- Consumes:
  - `FolderIndex.markdownFiles(in:)`, `FolderIndex.search(_:in:limit:)`, `FolderIndex.maxFiles`;
  - `FileWatcher`, `BookmarkStore.save`, `TextFileLoader.load`;
  - `Grants`, `ReaderController`, `RendererWebView.scroll(toLine:)`, `readAccessURL`.
- Produces:
```swift
@MainActor @Observable final class FolderModel {
    init(root: URL)
    private(set) var items: [FolderItem]; private(set) var capped: Bool      // capped = items.count == FolderIndex.maxFiles
    var selection: FolderItem.ID?
    var query: String; private(set) var hits: [SearchHit]
    private(set) var pendingLine: Int?                                         // consumed after the next render
    func start()                      // index off the main actor, then FileWatcher(url: root) → re-index
    func stop()
    func search() async               // K11: below
    func open(_ hit: SearchHit)       // selection = hit.item.id; pendingLine = hit.line
}
func eventually(_ timeout: Duration = .seconds(3), _ cond: @MainActor () -> Bool) async -> Bool   // AppTestSupport
```
- `search()` (K11): cancellation reaches the scan, and a stale result never lands.
```swift
func search() async {
    generation += 1; let gen = generation, q = query, its = items          // private var generation = 0
    let scan = Task.detached(priority: .userInitiated) { FolderIndex.search(q, in: its) }
    let found = await withTaskCancellationHandler { await scan.value } onCancel: { scan.cancel() }
    guard !Task.isCancelled, gen == generation else { return }             // superseded: drop it
    hits = found
}
```
- Behaviour:
  - **Open Folder… (⇧⌘O, File menu, `CommandGroup(after: .newItem)`):**
    - Pro: `NSOpenPanel` (folders only, prompt "Open") → `BookmarkStore.save` → append to `Grants.roots` → `openWindow(id: "folder", value: url)`.
    - Free: `openWindow(id: "pro", value: UpsellFeature.folder)`.
  - **Window:** a `NavigationSplitView`.
    - Sidebar: `List(selection:)` of `relativePath`, with `.searchable(text:, placement: .sidebar, prompt: "Search in Folder")`. A 200 ms debounce comes from `.task(id: model.query) { do { try await Task.sleep(for: .milliseconds(200)) } catch { return }; await model.search() }`: a keystroke cancels the previous task, which returns instead of scanning (`try?` would swallow the cancellation and scan anyway).
    - While searching, rows show `relativePath:line` plus the snippet; clicking one calls `open(_:)`.
    - Notices: "Showing the first 5,000 Markdown files." when capped (a footer note); "No Markdown files in this folder." when empty (`ContentUnavailableView`, `folder` symbol).
    - Detail: a `DocumentView` (fed from `TextFileLoader.load` of the selected file) with `baseURL` = the file and `readAccessURL` = `root`. When `pendingLine` is set, render, then `scroll(toLine:)`.
    - Initial selection: the first item. Window title: the folder name.
  - **Live reload:**
    - A root change re-indexes. The selection is kept if the file still exists, otherwise cleared.
    - A change to the open file reloads the text and re-renders, keeping `scrollY` (read with `evaluateJavaScript("scrollY")` before, `scrollTo({top: y, behavior: 'instant'})` after: a plain `scrollTo(0, y)` would animate under plan 09's smooth scrolling).
  - **Restoration:**
    - SwiftUI "persists the value of the binding for the purposes of state restoration" and brings an already-open window to front instead of opening a duplicate ([WindowGroup](https://developer.apple.com/documentation/swiftui/windowgroup)).
    - `BookmarkStore.resolveAll()` in `App.init` restores access before any restored window builds its body.
    - If the root can't be read: "Tegel Markdown can't read this folder any more." plus an "Open Folder…" button, in a `ContentUnavailableView` with `folder`.
  - **Licence lapse:** when `isPro` is false, the window body shows `ProUpsellView(feature: .folder)` and hides the folder content.

- [ ] **Step 1: Write the failing test** (hosted; temp folders live in the app container)

```swift
@MainActor final class FolderModelTests: XCTestCase {
    func testIndexesOnStart() async throws {
        let r = try tempDir(); _ = try write("# a", "a.md", in: r); _ = try write("x\ny\nneedle", "docs/b.md", in: r)
        let m = FolderModel(root: r); m.start(); defer { m.stop() }
        let indexed = await eventually { m.items.map(\.relativePath) == ["docs/b.md", "a.md"] }; XCTAssertTrue(indexed)
    }
    func testReindexesWhenFileAdded() async throws {
        let r = try tempDir(); _ = try write("# a", "a.md", in: r)
        let m = FolderModel(root: r); m.start(); defer { m.stop() }
        _ = await eventually { m.items.count == 1 }; _ = try write("# c", "c.md", in: r)
        let added = await eventually { m.items.contains { $0.relativePath == "c.md" } }; XCTAssertTrue(added)
    }
    func testDeletingOpenFileClearsSelection() async throws {      // Review Focus 2
        let r = try tempDir(); let a = try write("# a", "a.md", in: r); _ = try write("# b", "b.md", in: r)
        let m = FolderModel(root: r); m.start(); defer { m.stop() }
        _ = await eventually { m.items.count == 2 }; m.selection = m.items.first { $0.relativePath == "a.md" }?.id
        XCTAssertNotNil(m.selection)
        try FileManager.default.removeItem(at: a)
        let cleared = await eventually { m.selection == nil && m.items.count == 1 }; XCTAssertTrue(cleared)
    }
    func testSearchHitCarriesLineAndOpensIt() async throws {
        let r = try tempDir(); _ = try write("x\ny\nneedle", "b.md", in: r)
        let m = FolderModel(root: r); m.start(); defer { m.stop() }
        _ = await eventually { m.items.count == 1 }; m.query = "needle"; await m.search()
        let hit = try XCTUnwrap(m.hits.first); XCTAssertEqual(hit.line, 3)
        m.open(hit); XCTAssertEqual(m.selection, hit.item.id); XCTAssertEqual(m.pendingLine, 3)
    }
    func testStaleSearchIsDropped() async throws {                  // Review Focus 7; K11
        let r = try tempDir()
        _ = try write(Array(repeating: "beta", count: 250).joined(separator: "\n"), "a-beta.md", in: r)   // first in order; fills the 200 limit at once
        let filler = String(repeating: "filler text line\n", count: 6_000)                              // ≈ 100 KB each
        for i in 1...300 { _ = try write(filler, "m\(i).md", in: r) }
        _ = try write("alpha", "z-alpha.md", in: r)                                                      // last: "alpha" scans ≈ 30 MB first
        let m = FolderModel(root: r); m.start(); defer { m.stop() }
        _ = await eventually { m.items.count == 302 }
        m.query = "alpha"; let older = Task { await m.search() }; await Task.yield()   // the older search starts and suspends in its scan
        m.query = "beta"; await m.search()
        await older.value
        XCTAssertEqual(Set(m.hits.map(\.item.relativePath)), ["a-beta.md"]); XCTAssertEqual(m.hits.count, 200)
    }
}
```

- [ ] **Step 2: Run**

Run: `make test-app ONLY=FolderModelTests`
Expected: FAIL, `cannot find 'FolderModel' in scope`.

- [ ] **Step 3: Implement `FolderModel`, `FolderWindow` and the command as specified**

- [ ] **Step 4: Run, then check by hand**

Run: `make test-app ONLY=FolderModelTests`
Expected: `Executed 5 tests, with 0 failures`.

Then delete `gen == generation` from `search()`'s guard and run `make test-app ONLY=FolderModelTests/testStaleSearchIsDropped`. Expected: FAIL, the hits are `z-alpha.md`'s. Restore the guard and rerun: PASS.

Run: `make run-app ARGS="-TGForcePro YES -NSQuitAlwaysKeepsWindows YES"`, then by hand:
1. Open Folder… on `Fixtures/markdown` gives a sidebar.
2. Searching "Mermaid" and clicking a hit opens the file scrolled to that block, highlighted.
3. `echo "Live line" >> Fixtures/markdown/frontmatter.md` re-renders in under 1 s at the same scroll position. Afterwards run `git checkout Fixtures/markdown/frontmatter.md`.
4. ⌘Q, then relaunch with the same command: the folder window returns with its sidebar filled.
5. Relaunch without `-TGForcePro`: Open Folder… opens the Pro window.

- [ ] **Step 5: Commit** `Apps/Markdown/App Apps/Markdown/AppTests/FolderModelTests.swift Apps/Markdown/AppTests/AppTestSupport.swift`, "feat(app): Pro folder mode with sidebar, search jump, live reload and restoration"

---

### Task 10: Theme picker, Settings tabs and zoom

**UI spec:** DESIGN.md (§7 themes, §9 symbols) and app-ui-spec (Steps 3, 4).

**Files:**
- Consumes, no edit: the theme CSS (`Renderer/src/css/{base,paper,ink,studio,print}.css`, `index.html` link order) from plan 09 Task 6, with values in `DESIGN.md` §7; in `main` since Drop B (Mon 9 Nov), and in this branch from Step 0. `page.js` already sets `data-theme` (plan 01 Task 5).
- Create: `Apps/Markdown/App/SettingsView.swift`
- Modify: `MarkdownApp.swift` (add a `Settings { SettingsView() }` scene), `AppCommands.swift` (View ▸ Theme picker; View ▸ Actual Size, Zoom In, Zoom Out), `ReaderController.swift` (render with `ProGate.effectiveTheme(stored, isPro:)`; re-render on change; apply `pageZoom`; `enum Zoom`), `DocumentView.swift` (toolbar Theme menu, Task 7)
- Test: `Packages/TegelKit/Tests/TegelKitTests/WebView/ThemeTests.swift`, `Apps/Markdown/AppTests/ZoomTests.swift`

**Interfaces:**
- CSS: plan 09 Task 6 owns it. Tokens sit under `:root[data-theme="<name>"]`; dark values only under `@media screen and (prefers-color-scheme: dark)` with `:not([data-mode="print"])`. WKWebView follows the view's `NSAppearance`, so no app code is needed for dark mode.
- App: `@AppStorage("TGTheme") var theme: RendererTheme = .paper`.
  - Settings is a `TabView` (app-ui-spec Step 4). This task adds the Appearance tab (`textformat.size`): picker "Theme" ("Paper", "Ink (Pro)", "Studio (Pro)") and "Text size" (mirrors `TGZoom`). Task 12 adds the General tab (`gearshape`) first; plan 03 adds Licence and Updates.
  - Picking a Pro theme while free calls `openWindow(id: "pro", value: UpsellFeature.theme)` and leaves the stored value at `.paper`.
  - The same picker appears under View ▸ Theme and as the toolbar Theme menu (`textformat`).
- Zoom (app-ui-spec Step 3): View ▸ Actual Size ⌘0, Zoom In ⌘+, Zoom Out ⌘− set `@AppStorage("TGZoom") var zoom: Double = 1.0` through `Zoom.step`; `ReaderController` applies `renderer.webView.pageZoom = zoom` (macOS 11.0+).
```swift
enum Zoom { static func step(_ zoom: Double, _ direction: Int) -> Double }   // 0 → 1.0; ±1 → next multiple of 0.1, clamped to 0.75…2.0
```

- [ ] **Step 0: Merge plan 09 Drop B into the branch** (Tue 10 Nov). The branch was cut on 3 Nov, before Drop B merged; Tasks 10–17 need its theme CSS, `docs/design/samples/`, `scripts/window-shot.sh` and `design-shots.yml`.

Run: `git switch main && git pull --ff-only && git switch m02-app1-features && git merge main -m "merge: main (plan 09 Drop B) into m02-app1-features" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" && test -f Renderer/src/css/ink.css && test -f docs/design/samples/ar-spec.md && test -x scripts/window-shot.sh && test -f .github/workflows/design-shots.yml && echo ok`
Expected: `ok`. A failing `test` means Drop B hasn't merged yet: wait for plan 09 Task 14, and don't start Tasks 10–17. On a conflict, keep both sides in `Renderer/src`, regenerate `Packages/TegelKit/Sources/TegelKit/Resources/Renderer/` with `make renderer` instead of merging it by hand, then `git add` the files and `git commit --no-edit`.

Run: `make check`
Expected: green. Record the new pass counts (plan 09's guards are now in) in `docs/reviews/m02.md`.

Then delete the `instantScroll(r)` call from `testScrollToHeadingMovesViewport` (Task 6) and run `swift test --package-path Packages/TegelKit --filter NavigationTests`. Expected: FAIL, `top` far above 40: Drop B's `scroll-behavior: smooth` is still animating when the test reads it. Restore the call and rerun: `Executed 3 tests, with 0 failures`.

- [ ] **Step 1: Write the tests** (1400×900 host; contrast uses WCAG 2 relative luminance: sRGB channels linearised, `L = 0.2126R + 0.7152G + 0.0722B`, ratio `(L1 + 0.05)/(L2 + 0.05)`)

```swift
@MainActor final class ThemeTests: XCTestCase {
    private func render(_ md: String, _ t: RendererTheme, dark: Bool = false) async throws -> RendererWebView {
        let r = hosted(width: 1400, height: 900); r.webView.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        _ = try await r.render(md, options: RenderOptions(mode: .window, theme: t, baseURL: nil)); return r
    }
    private func style(_ r: RendererWebView, _ sel: String, _ prop: String) async throws -> String {
        try await js(r, "return getComputedStyle(document.querySelector('\(sel)')).\(prop)") as? String ?? ""
    }
    func testEachThemeMeetsContrastInLightAndDark() async throws {
        for t in RendererTheme.allCases { for dark in [false, true] {
            let r = try await render("Body text and [a link](#x).", t, dark: dark)
            let bg = try await style(r, "html", "backgroundColor"), fg = try await style(r, "p", "color"), link = try await style(r, "a", "color")
            XCTAssertGreaterThanOrEqual(contrast(fg, bg), 4.5, "\(t) dark=\(dark) text")
            XCTAssertGreaterThanOrEqual(contrast(link, bg), 4.5, "\(t) dark=\(dark) link")
        } }
    }
    func testInkIsSerifPaperAndStudioAreSans() async throws {
        for (t, first) in [(RendererTheme.ink, "ui-serif"), (.paper, "system-ui"), (.studio, "system-ui")] {
            let family = try await style(try await render("x", t), "p", "fontFamily")
            let real = family.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).hasPrefix("TG ") }   // drop "TG …" local() aliases
            XCTAssertEqual(real.first, first, "\(t): \(family)")
        }
    }
    func testRTLBlockquoteAndListUseRightSide() async throws {    // "test text", "first item"
        for t in RendererTheme.allCases {
            let r = try await render("> نص تجريبي\n\n- عنصر أول\n", t)
            let bqR = try await style(r, "blockquote", "borderRightWidth"), bqL = try await style(r, "blockquote", "borderLeftWidth")
            let ulR = try await style(r, "ul", "paddingRight"), ulL = try await style(r, "ul", "paddingLeft")
            XCTAssertNotEqual(bqR, "0px", "\(t)"); XCTAssertEqual(bqL, "0px", "\(t)")
            XCTAssertNotEqual(ulR, "0px", "\(t)"); XCTAssertEqual(ulL, "0px", "\(t)")
        }
    }
    func testArabicParagraphGetsTallerLines() async throws {      // "an Arabic paragraph for testing"
        let r = try await render("English paragraph text.\n\nفقرة عربية للتجربة.", .paper)
        let en = try await js(r, "return parseFloat(getComputedStyle(document.querySelectorAll('p')[0]).lineHeight)") as? Double ?? 0
        let ar = try await js(r, "return parseFloat(getComputedStyle(document.querySelectorAll('p')[1]).lineHeight)") as? Double ?? 0
        XCTAssertGreaterThan(ar, en)
    }
    func testMeasureCapsLineLength() async throws {
        let long = String(repeating: "word ", count: 400)
        for (t, maxW) in [(RendererTheme.paper, 700.0), (.ink, 700), (.studio, 800)] {
            let w = try await js(try await render(long, t), "return document.querySelector('p').getBoundingClientRect().width") as? Double ?? 0
            XCTAssertTrue((500...maxW).contains(w), "\(t) width \(w)")
        }
    }
}
// contrast(_ a: String, _ b: String) -> Double parses "rgb(r, g, b)" / "rgba(…)"; defined in this file.
```

```swift
final class ZoomTests: XCTestCase {
    func testStepsByTenthsWithinBounds() {
        XCTAssertEqual(Zoom.step(1.0, 1), 1.1); XCTAssertEqual(Zoom.step(1.0, -1), 0.9)
        XCTAssertEqual(Zoom.step(0.8, -1), 0.75); XCTAssertEqual(Zoom.step(0.75, -1), 0.75); XCTAssertEqual(Zoom.step(0.75, 1), 0.8)
        XCTAssertEqual(Zoom.step(2.0, 1), 2.0); XCTAssertEqual(Zoom.step(1.7, 0), 1.0)
    }
}
```

- [ ] **Step 2: Run, and watch a theme guard fail**

Run: `swift test --package-path Packages/TegelKit --filter ThemeTests; make test-app ONLY=ZoomTests`
Expected:
- `Executed 5 tests, with 0 failures`: these are acceptance checks on plan 09's CSS, which Step 0 merged in;
- ZoomTests FAIL, `cannot find 'Zoom' in scope`.

Then delete the `ink.css` `<link>` from `Packages/TegelKit/Sources/TegelKit/Resources/Renderer/index.html` and rerun ThemeTests.
Expected: FAIL on ink (`testInkIsSerifPaperAndStudioAreSans`). Then `make renderer`, and `git status --short Packages/TegelKit/Sources/TegelKit/Resources` is empty.

- [ ] **Step 3: Implement `Zoom.step` (in whole percent: `75…200`, steps snap to multiples of 10), the Settings `TabView`, the View menu items, `pageZoom` and the toolbar Theme menu. No CSS here.**

- [ ] **Step 4: Run, then capture the review screenshots**

Run: `swift test --package-path Packages/TegelKit --filter ThemeTests && make test-app ONLY=ZoomTests`
Expected: `Executed 5 tests, with 0 failures`, then `Executed 1 test, with 0 failures`.

Then run `make run-app FILES="Fixtures/markdown/gfm-kitchen-sink.md" ARGS="-TGForcePro YES"`. For each theme × light/dark (switch with System Settings ▸ Appearance), run `mkdir -p docs/reviews/m02-design && screencapture -x -o -w docs/reviews/m02-design/theme-<name>-<light|dark>.png` and click the reader window. Check by hand that ⌘+ / ⌘− / ⌘0 change the text size and that Settings ▸ Appearance shows the same value.
Expected: 6 PNGs showing fixture text only, inputs for Task 17's design review.

- [ ] **Step 5: Commit** `Packages/TegelKit/Tests/TegelKitTests/WebView/ThemeTests.swift Apps/Markdown/App Apps/Markdown/AppTests/ZoomTests.swift docs/reviews/m02-design`, "feat(app): theme picker in Settings ▸ Appearance, View menu and toolbar; page zoom; ThemeTests on plan 09's CSS"

---

### Task 11: Print CSS and PDFExporter

**Files:**
- Modify: `Renderer/src/css/print.css`; regenerate
- Create: `Packages/TegelKit/Sources/TegelKit/PDFExporter.swift`
- Test: `Packages/TegelKit/Tests/TegelKitTests/WebView/PDFExporterTests.swift`

**Interfaces:**
- Produces (contract): `PaperSize`, `PDFExporter.export(_ renderer: RendererWebView, to url: URL, paper: PaperSize) async throws`, which is `try await makePDFData(renderer, paper: paper).write(to: url)` (not `.atomic`: the save panel grants the file, not its folder).
- Produces (additions):
  - `public static func makePDFData(_ renderer: RendererWebView, paper: PaperSize) async throws -> Data` on `PDFExporter` (K18). Task 12 calls it so the export check sits between printing and writing; plan 08's upsell preview turns it into at most two page images with `PDFDocument(data:)` and `PDFPage.thumbnail(of:for:)`.
  - `extension PaperSize { public var points: CGSize }`: a4 = 595.28×841.89, letter = 612×792.
  - `public enum PDFExportError: Error, Equatable { case printFailed }`.
- print.css keeps only the `@page` and break rules. Colour in print (light-only pages, code backgrounds, print sizes) belongs to plan 09 Task 6 (`DESIGN.md` §7).
  - `@page { size: auto; margin: 18mm 16mm 20mm 16mm }`
  - Inside `@media print`:
    - `pre, table, svg, blockquote, img, .mermaid-error { break-inside: avoid }`
    - `h1, h2, h3, h4, h5, h6 { break-after: avoid }`
    - `pre, pre code { white-space: pre-wrap; overflow-wrap: anywhere }`
- Approach for `makePDFData` ([F6]; save-to-file through [`jobSavingURL`](https://developer.apple.com/documentation/appkit/nsprintinfo/attributekey/jobsavingurl) with `jobDisposition = .save`):
  - WebKit has no public in-memory paginated print. `WKPrintingView` must be driven by its own `NSPrintOperation` (it asserts `currentOperation` is the one it stored), and `createPDF` makes one tall page. So the bytes pass through one file in a private folder that never outlives the call.
  0. Create `FileManager.default.temporaryDirectory/tegel-pdf-<UUID>` with `posixPermissions: 0o700`; `defer` removes it.
  1. Copy `NSPrintInfo.shared`.
     - `paperSize = paper.points`; all four margins `0` (CSS `@page` owns the margins).
     - `horizontalPagination = .fit`; `verticalPagination = .automatic`.
     - `jobDisposition = .save`; `dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = <private folder>/out.pdf`.
  2. `let op = renderer.webView.printOperation(with: info)` (macOS 11+, [printOperation(with:)](https://developer.apple.com/documentation/webkit/wkwebview/printoperation(with:))).
     - `showsPrintPanel = false`, `showsProgressPanel = false`.
     - `op.view?.frame = renderer.webView.bounds`.
  3. If `webView.window == nil`, host it in an offscreen borderless `NSWindow` sized to `paper.points` until done.
  4. `op.run()`, synchronous (CR-P2-25): under `swift test` no `NSApplication` is running, so a sheet's `didRun` callback would never fire and the tests would hang.
  5. Throw `.printFailed` unless `run()` returned true and the file exists; return `Data(contentsOf:)` of it.

- [ ] **Step 1: Write the failing test**

```swift
import PDFKit
@MainActor final class PDFExporterTests: XCTestCase {
    private func export(_ md: String, baseURL: URL? = nil, paper: PaperSize = .a4) async throws -> PDFDocument {
        let r = RendererWebView()
        _ = try await r.render(md, options: RenderOptions(mode: .print, theme: .paper, baseURL: baseURL))
        let out = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).pdf")
        try await PDFExporter.export(r, to: out, paper: paper); return try XCTUnwrap(PDFDocument(url: out))
    }
    private func exportFixture(_ n: String, paper: PaperSize = .a4) async throws -> PDFDocument {
        let u = fixtureURL(n); return try await export(try TextFileLoader.load(u).text, baseURL: u, paper: paper)
    }
    private func pages(_ d: PDFDocument) -> [String] { (0..<d.pageCount).map { d.page(at: $0)?.string ?? "" } }
    private func norm(_ s: String) -> String {
        s.precomposedStringWithCompatibilityMapping.filter { !$0.isWhitespace && !"\u{200E}\u{200F}\u{061C}".contains($0) }
    }
    /// 40 sections, 3–5 paragraphs of 80 words; heading markers S<n>Z; end marker on the last line.
    private func longDocument() -> String {
        let para = Array(repeating: "Plain technical prose about rendering documents", count: 12).joined(separator: " ")
        return (1...40).map { n in "## Section \(n) S\(n)Z\n\n" + Array(repeating: para, count: 3 + n % 3).joined(separator: "\n\n") }
            .joined(separator: "\n\n") + "\n\nEND-OF-DOCUMENT-7F3A\n"
    }

    func testA4PageSize() async throws {
        let d = try await exportFixture("gfm-kitchen-sink.md"); let b = try XCTUnwrap(d.page(at: 0)).bounds(for: .mediaBox)
        XCTAssertEqual(b.width, 595.28, accuracy: 1); XCTAssertEqual(b.height, 841.89, accuracy: 1)
    }
    func testLetterPageSize() async throws {
        let d = try await exportFixture("gfm-kitchen-sink.md", paper: .letter); let b = try XCTUnwrap(d.page(at: 0)).bounds(for: .mediaBox)
        XCTAssertEqual(b.width, 612, accuracy: 1); XCTAssertEqual(b.height, 792, accuracy: 1)
    }
    func testLongDocumentPaginatesWithoutTruncation() async throws {   // FB20581927 [F6]; Review Focus 5
        let d = try await export(longDocument()); let all = pages(d).joined(separator: "\n")
        XCTAssertGreaterThan(d.pageCount, 1)
        XCTAssertTrue((25...60).contains(d.pageCount), "pageCount \(d.pageCount)")   // tightened in Step 5
        for n in 1...40 { XCTAssertTrue(all.contains("S\(n)Z"), "section \(n) missing") }
        XCTAssertTrue(pages(d).last?.contains("END-OF-DOCUMENT-7F3A") == true)
    }
    func testHeadingsNeverEndAPage() async throws {
        let p = pages(try await export(longDocument()))
        for (i, s) in p.dropLast().enumerated() {
            let last = s.split(whereSeparator: \.isNewline).last { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? ""
            XCTAssertNil(last.firstMatch(of: /S\d+Z\s*$/), "page \(i + 1) ends with heading: \(last)")
        }
    }
    func testLongCodeLinesWrapInsteadOfClipping() async throws {
        let d = try await export("```\n" + String(repeating: "x", count: 600) + "WRAPTAIL\n```\n")
        XCTAssertTrue(pages(d).joined().contains("WRAPTAIL"))
    }
    func testArabicAndEnglishTextSurviveExtraction() async throws {
        let src = try TextFileLoader.load(fixtureURL("rtl-arabic.md")).text
        let line = try XCTUnwrap(src.split(whereSeparator: \.isNewline).first { $0.first.map { ("\u{0621}"..."\u{064A}").contains($0) } ?? false })
        let arabic = line.split(separator: " ").prefix(2).joined(separator: " ")
        let d = try await export(src + "\n\nEnglish control sentence for extraction.\n")
        let text = norm(pages(d).joined())
        XCTAssertTrue(text.contains(norm(arabic)), "Arabic phrase '\(arabic)' not found in logical order")
        XCTAssertTrue(text.contains(norm("English control sentence for extraction")))
    }
    func testMixedBidiAndBrokenMermaidHaveNoBlankPage() async throws {
        for n in ["mixed-bidi.md", "mermaid-broken.md"] {
            let d = try await exportFixture(n); XCTAssertGreaterThanOrEqual(d.pageCount, 1)
            for (i, s) in pages(d).enumerated() { XCTAssertFalse(s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(n) page \(i + 1) blank") }
        }
    }
    func testEmptyDocumentGivesOnePage() async throws {
        let d = try await exportFixture("empty.md"); XCTAssertEqual(d.pageCount, 1)
    }
    func testMarginsAndReadableBodySize() async throws {
        let d = try await export(longDocument()); let page = try XCTUnwrap(d.page(at: 0)); let box = page.bounds(for: .mediaBox)
        let text = try XCTUnwrap(page.selection(for: box)).bounds(for: page)
        XCTAssertGreaterThanOrEqual(text.minX, 36); XCTAssertLessThanOrEqual(text.maxX, box.width - 36)
        XCTAssertGreaterThanOrEqual(text.minY, 36); XCTAssertLessThanOrEqual(text.maxY, box.height - 36)
        var sizes: [CGFloat: Int] = [:]
        page.attributedString?.enumerateAttribute(.font, in: NSRange(location: 0, length: page.attributedString?.length ?? 0)) { v, r, _ in
            if let f = v as? NSFont { sizes[f.pointSize.rounded(), default: 0] += r.length } }
        let body = try XCTUnwrap(sizes.max { $0.value < $1.value }?.key)
        XCTAssertTrue((9...14).contains(body), "body font \(body) pt")
    }
    func testMakePDFDataIsPaginatedAndLeavesNoFile() async throws {   // K18: the upsell preview's path
        let r = RendererWebView(); _ = try await r.render(longDocument(), options: RenderOptions(mode: .print, theme: .paper, baseURL: nil))
        let tmp = FileManager.default.temporaryDirectory.path(percentEncoded: false)
        let before = Set(try FileManager.default.contentsOfDirectory(atPath: tmp))
        let data = try await PDFExporter.makePDFData(r, paper: .a4)
        let left = Set(try FileManager.default.contentsOfDirectory(atPath: tmp)).subtracting(before).filter { $0.hasPrefix("tegel-pdf-") }
        let d = try XCTUnwrap(PDFDocument(data: data))
        XCTAssertGreaterThan(d.pageCount, 1); XCTAssertEqual(left, [])
        XCTAssertNotNil(d.page(at: 1)?.thumbnail(of: CGSize(width: 120, height: 170), for: .mediaBox))
    }
}
```

- [ ] **Step 2: Run**

Run: `swift test --package-path Packages/TegelKit --filter PDFExporterTests`
Expected: FAIL, `cannot find 'PDFExporter' in scope`.

- [ ] **Step 3: Implement `PDFExporter` (`makePDFData`, then `export` on top of it), `PaperSize.points`, `PDFExportError` and print.css as specified, then `make renderer`**

- [ ] **Step 4: Run**

Run: `swift test --package-path Packages/TegelKit --filter PDFExporterTests`
Expected: `Executed 10 tests, with 0 failures`. If a test fails, apply its rule below and don't weaken any assertion:
- **Pages come out blank, or `run()` never returns:** use `op.runModal(for: window, delegate: bridge, didRun: #selector(Bridge.printOperationDidRun(_:success:contextInfo:)), contextInfo: nil)`, with a `Bridge: NSObject` that resumes a `CheckedContinuation`, and run `PDFExporterTests` in plan 01's hosted `TegelKitHostTests` scheme instead of `swift test` (CR-P2-25). Record which path shipped in m02.md.
- **`testMarginsAndReadableBodySize` fails on the margins:** WebKit ignored `@page` margins. Set NSPrintInfo margins to top/bottom 57 pt and left/right 45 pt, and change print.css to `@page { margin: 0 }`.
- **`testHeadingsNeverEndAPage` fails:** add `page-break-after: avoid` next to `break-after`. If it still fails, mark it `XCTExpectFailure("WebKit ignores break-after: avoid; see docs/reviews/m02.md")` and record it as a P2 in m02.md.
- **`testArabicAndEnglishTextSurviveExtraction` fails because the Arabic comes out reversed:** that's a real defect for copy and search in PDF readers. Stop and report it; don't loosen the test.

Then comment out the `defer` that removes the private folder and rerun `--filter testMakePDFDataIsPaginatedAndLeavesNoFile`. Expected: FAIL, `left` names one `tegel-pdf-…`. Restore the `defer` and rerun: PASS.

- [ ] **Step 5: Tighten the page-count range**

Note the observed `pageCount` from Step 4. Replace `25...60` with `observed×0.85...observed×1.15` (rounded), then rerun.
Expected: PASS. Record the observed count in `docs/reviews/m02.md` under "PDF calibration (macOS 15.7 Intel)".

- [ ] **Step 6: Commit** `Renderer/src/css/print.css Packages/TegelKit/Sources/TegelKit Packages/TegelKit/Tests/TegelKitTests/WebView/PDFExporterTests.swift docs/reviews/m02.md`, "feat(tegelkit): paginated A4/Letter PDFExporter via printOperation with print.css"

---

### Task 12: Export as PDF command (Pro)

**UI spec:** app-ui-spec (Steps 1, 3, 4).

**Files:**
- Modify: `AppCommands.swift`, `ReaderController.swift`, `SettingsView.swift` (General tab), `DocumentView.swift` (toolbar Export item, Task 7)
- Create: `Apps/Markdown/App/PaperDefault.swift`
- Test: `Apps/Markdown/AppTests/PaperDefaultTests.swift`

**Interfaces:**
- Consumes: `PDFExporter.makePDFData`, `PaperSize`, `RendererWebView.loadedImages(outside:)`, `ProGate.effectiveTheme`, `Grants`.
- Produces:
  - `func defaultPaper(for locale: Locale) -> PaperSize`: `.letter` when `locale.measurementSystem == .us`, else `.a4`.
  - `@AppStorage("TGPaperSize")`, defaulting to `defaultPaper(for: .current)`, with a picker "PDF paper size" offering "A4" and "Letter" in the Settings General tab (`gearshape`), which this task adds as the first tab.
  - `ReaderController.exportPDF()`.
- Flow for File ▸ "Export as PDF…" (⇧⌘E) and the toolbar's Export as PDF item (`arrow.up.doc`), enabled when `FocusedValues.reader` is set:
  1. Free → `openWindow(id: "pro", value: UpsellFeature.pdf)`.
  2. Pro → `NSSavePanel` as a sheet: `allowedContentTypes = [.pdf]`, `nameFieldStringValue = "<file name without extension>.pdf"`, `canCreateDirectories = true`.
  3. Render in a fresh offscreen `RendererWebView`: mode `.print`, the effective theme, the same `baseURL` and `readAccessURL` as on screen.
  4. `let data = try await PDFExporter.makePDFData(renderer, paper:)`.
  5. **Outside-folder check (K4, S3 option A):** `let outside = renderer.loadedImages(outside: <the document's folder>)`. It runs after printing, so it covers every image the print loaded, hidden or not. If it isn't empty, an `NSAlert` as a sheet:
     - Message: "This PDF includes images from outside the document's folder."
     - Informative text: "Export only if you meant to include these files:", then one path per line (`(path as NSString).abbreviatingWithTildeInPath`).
     - Buttons, added in this order: "Cancel" (default, so Return and Esc both cancel) and "Export".
     - "Cancel" ends the flow; nothing is written.
  6. `try data.write(to: url)` (not `.atomic`: the save panel grants the file, not its folder). This is the app's only file write.
  7. On error, an `NSAlert` with the message "The PDF couldn't be saved." and `error.localizedDescription` as informative text.

- [ ] **Step 1: Write the failing test**

```swift
final class PaperDefaultTests: XCTestCase {
    func testUSLocaleGetsLetter()       { XCTAssertEqual(defaultPaper(for: Locale(identifier: "en_US")), .letter) }
    func testEuropeAndArabicGetA4() {
        for id in ["nl_NL", "fr_FR", "ar_SA", "en_GB"] { XCTAssertEqual(defaultPaper(for: Locale(identifier: id)), .a4, id) }
    }
}
```

- [ ] **Step 2: Run**

Run: `make test-app ONLY=PaperDefaultTests`
Expected: FAIL, `cannot find 'defaultPaper' in scope`.

- [ ] **Step 3: Implement `defaultPaper`, the setting, the command and `exportPDF()`**

- [ ] **Step 4: Run, then check by hand**

Run: `make test-app ONLY=PaperDefaultTests && make run-app FILES="Fixtures/markdown/rtl-arabic.md Fixtures/markdown/mixed-bidi.md" ARGS="-TGForcePro YES"`
Expected: `Executed 2 tests, with 0 failures`. Then export both files in A4 and Letter and open them in Preview. Check that:
- pages are paginated;
- Arabic is right-aligned and code stays LTR;
- no heading sits alone at a page bottom;
- each PDF matches its window rendering.

Record the result in `docs/reviews/m02.md`. Without `-TGForcePro`, ⇧⌘E opens the Pro window.

Then the outside-folder check, with a hidden 1 px image outside the document's folder:
Run: `T=$(mktemp -d) && mkdir "$T/docs" && cp Fixtures/markdown/assets/square.png "$T/outside.png" && printf 'Invoice\n\n<span style="display:inline-block;width:1px;height:1px;overflow:hidden">![](../outside.png)</span>\n' > "$T/docs/page.md" && make run-app FILES="$T/docs/page.md" ARGS="-TGForcePro YES"`
Expected, by hand:
1. The image bar shows; "Show Images…" → choose `$T` → the bar goes.
2. ⇧⌘E → save as `out.pdf` → the alert lists `…/outside.png`. "Cancel": no `out.pdf` exists.
3. ⇧⌘E again → "Export": `out.pdf` exists.
Record the result in m02.md. Task 8's `testHiddenOutsideFolderImageIsListedForExport` pins the list itself.

- [ ] **Step 5: Commit** `Apps/Markdown/App Apps/Markdown/AppTests/PaperDefaultTests.swift docs/reviews/m02.md`, "feat(app): Pro Export as PDF with save panel and locale paper default"

---

### Task 13: Copy Diagnostics

**UI spec:** app-ui-spec (Step 3, Help menu).

**Files:**
- Create: `Packages/TegelKit/Sources/TegelKit/Diagnostics.swift`
- Modify: `Renderer/build.js` (writes `renderer-version.txt`); regenerate
- Modify: `AppCommands.swift` (Help menu, via `CommandGroup(after: .help)`)
- Test: `Packages/TegelKit/Tests/TegelKitTests/DiagnosticsTests.swift`, `Renderer/test/version.test.js`, `Apps/Markdown/AppTests/SandboxDiagnosticsTests.swift`

**Interfaces:**
- Produces (TegelKit addition; App 2 reuses it):
```swift
public struct DiagnosticsInfo: Sendable, Equatable {
    public var appName: String, appVersion: String, build: String, macOS: String, arch: String
    public var sandboxed: Bool, rendererVersion: String, licence: String
}
public enum Diagnostics {
    public static func current(licence: String, bundle: Bundle = .main) -> DiagnosticsInfo
    public static func report(_ info: DiagnosticsInfo) -> String
}
```
- Sources for each field:
  - `appName` / `appVersion` / `build`: `CFBundleName` / `CFBundleShortVersionString` / `CFBundleVersion`.
  - `macOS`: `ProcessInfo.processInfo.operatingSystemVersionString`.
  - `arch`:
    - `#if arch(arm64)` gives `"arm64"`, otherwise `"x86_64"`;
    - the value becomes `"x86_64 (Rosetta)"` when `sysctlbyname("sysctl.proc_translated")` returns 1 ([Apple: Rosetta](https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment)).
  - `sandboxed`: `ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil`. No Apple doc states this, so the hosted test pins it.
  - `rendererVersion`: the trimmed `Bundle.module` `Renderer/renderer-version.txt`, or `"unknown"`.
  - `licence`: the caller's summary.
    - Plan 02 passes `ProGate.overrideLabel` when the Debug override is on (inside `#if DEBUG`), otherwise `"Free"`; plan 03 passes a `LicenseState` summary.
    - **The key is never an input.**
- `build.js` writes `renderer-version.txt`. Its content is the first 12 hex characters of the SHA-256 over every other output file, sorted by relative path, each hashed as `path + "\0" + bytes`.
- Help ▸ "Copy Diagnostics" runs `NSPasteboard.general.clearContents()` and then `setString(Diagnostics.report(.current(licence:)), forType: .string)`.

- [ ] **Step 1: Write the failing tests**

```swift
final class DiagnosticsTests: XCTestCase {
    func testReportFormat() {
        let i = DiagnosticsInfo(appName: "Tegel Markdown", appVersion: "1.0", build: "7", macOS: "Version 15.7.7 (Build 24G720)",
                                arch: "x86_64", sandboxed: true, rendererVersion: "3f9a0c1b2d4e", licence: "Free")
        XCTAssertEqual(Diagnostics.report(i), """
            Tegel Markdown 1.0 (7)
            macOS: Version 15.7.7 (Build 24G720)
            CPU: x86_64
            Sandbox: on
            Renderer: 3f9a0c1b2d4e
            Licence: Free
            """)
    }
    func testCurrentFillsEveryField() {
        let i = Diagnostics.current(licence: "Free")
        XCTAssertNotNil(i.rendererVersion.wholeMatch(of: /[0-9a-f]{12}/))
        XCTAssertFalse(i.macOS.isEmpty); XCTAssertTrue(["arm64", "x86_64", "x86_64 (Rosetta)"].contains(i.arch))
        XCTAssertFalse(i.sandboxed)                                  // swift test is not sandboxed
    }
    func testReportHasNoUserPaths() {
        let s = Diagnostics.report(.current(licence: "Free"))
        XCTAssertFalse(s.contains(NSHomeDirectory())); XCTAssertFalse(s.contains("/Users/"))
    }
}
```
`SandboxDiagnosticsTests.testHostedAppIsSandboxed`: `XCTAssertTrue(Diagnostics.current(licence: "Free").sandboxed)` and `XCTAssertEqual(Diagnostics.current(licence: "Free").appName, "Tegel Markdown")`.

`Renderer/test/version.test.js`: walk the output folder `../Packages/TegelKit/Sources/TegelKit/Resources/Renderer`, recompute the hash as defined above, and `expect(readFileSync(".../renderer-version.txt","utf8").trim()).toBe(hash.slice(0, 12))`.

- [ ] **Step 2: Run**

Run: `(cd Renderer && bun test test/version.test.js); swift test --package-path Packages/TegelKit --filter DiagnosticsTests`
Expected: bun fails with ENOENT on `renderer-version.txt`; swift fails with `cannot find 'Diagnostics' in scope`.

- [ ] **Step 3: Implement `build.js`, run `make renderer`, then implement `Diagnostics` and the Help command**

- [ ] **Step 4: Run, then check by hand**

Run: `(cd Renderer && bun test) && swift test --package-path Packages/TegelKit --filter DiagnosticsTests && make test-app ONLY=SandboxDiagnosticsTests`
Expected: bun `0 fail`; `Executed 3 tests, with 0 failures`; `** TEST SUCCEEDED **`. Then in the app, Help ▸ Copy Diagnostics followed by `pbpaste` prints 6 lines, with `Sandbox: on`.

- [ ] **Step 5: Commit** `Packages/TegelKit Renderer/build.js Renderer/test/version.test.js Apps/Markdown/App/AppCommands.swift Apps/Markdown/AppTests/SandboxDiagnosticsTests.swift`, "feat: Copy Diagnostics (version, macOS, arch, sandbox, renderer hash, licence summary)"

---

### Task 14: Drag-and-drop and Open Recent

**Files:**
- Create: `Apps/Markdown/App/DropRouter.swift`
- Modify: `DocumentView.swift`, `FolderWindow.swift` (add `.dropDestination(for: URL.self) { urls, _ in … }`, macOS 13+)
- Test: `Apps/Markdown/AppTests/DropRouterTests.swift`

**Interfaces:**
- Consumes: `FolderIndex.markdownExtensions`, `BookmarkStore.save`, `Grants`, `openWindow`.
- Produces:
```swift
enum DropAction: Equatable { case document(URL), folder(URL), ignore }
enum DropRouter { static func route(_ url: URL) -> DropAction }   // directory → .folder; markdown extension (any case) → .document; else .ignore
```
- Handling:
  - `.document` → `NSDocumentController.shared.openDocument(withContentsOf:display: true)`.
  - `.folder`: Pro → `BookmarkStore.save`, add to `Grants`, `openWindow(id: "folder", value:)`; free → `openWindow(id: "pro", value: UpsellFeature.folder)`.
  - `.ignore` → returns `false`.
- Dock icon: Markdown files are handled natively by `DocumentGroup` plus plan 01's imported `net.daringfireball.markdown` type [F10].
  - Folder drops on the Dock icon aren't supported in v1: they'd need an app-delegate open handler competing with `DocumentGroup`. Open Folder… and window drops cover the need.
  - Open Recent comes from `DocumentGroup` and lists documents only.

- [ ] **Step 1: Write the failing test**

```swift
final class DropRouterTests: XCTestCase {
    func testRoutesByKind() throws {
        let r = try tempDir()
        let md = try write("#", "a.md", in: r), upper = try write("#", "B.MD", in: r), mk = try write("#", "c.markdown", in: r)
        let png = try write("x", "d.png", in: r)
        let dir = r.appending(path: "notes.md", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        XCTAssertEqual(DropRouter.route(md), .document(md)); XCTAssertEqual(DropRouter.route(upper), .document(upper))
        XCTAssertEqual(DropRouter.route(mk), .document(mk)); XCTAssertEqual(DropRouter.route(png), .ignore)
        XCTAssertEqual(DropRouter.route(dir), .folder(dir))         // a folder named *.md is still a folder
    }
}
```

- [ ] **Step 2: Run**

Run: `make test-app ONLY=DropRouterTests`
Expected: FAIL, `cannot find 'DropRouter' in scope`.

- [ ] **Step 3: Implement `DropRouter`** (`resourceValues(forKeys: [.isDirectoryKey])` first, then the extension check) **and the drop handlers**

- [ ] **Step 4: Run, then check by hand**

Run: `make test-app ONLY=DropRouterTests && make run-app ARGS="-TGForcePro YES"`
Expected: `Executed 1 test, with 0 failures`. Then by hand:
1. Drag `Fixtures/markdown/gfm-kitchen-sink.md` onto the Dock icon, with the app running and again with it quit: it opens.
2. Drag `Fixtures/markdown` onto a reader window: a folder window opens.
3. A `.png` drop does nothing.
4. Open two fixtures, ⌘Q, relaunch: File ▸ Open Recent lists both and reopens them under the sandbox.

- [ ] **Step 5: Commit** `Apps/Markdown/App Apps/Markdown/AppTests/DropRouterTests.swift`, "feat(app): window drag-and-drop for files and folders"

---

### Task 15: Welcome window and Quick Look setup

**UI spec:** app-ui-spec (Step 5, Welcome).

One first-run window. It absorbs plan 08 Task 11's Quick Look guide, so the app has no second onboarding window; plan 08 Task 11 keeps only the deep-link verification on macOS 14/15/27 and the copy review.

**Files:**
- Create: `Packages/TegelKit/Sources/TegelKit/QuickLookSetup.swift` (TegelKit, because App 2's Welcome reuses it)
- Create: `Apps/Markdown/App/WelcomeView.swift`, `Apps/Markdown/App/Samples/Welcome.md` (a copy of `docs/design/samples/en-spec.md`), `Apps/Markdown/App/Samples/Welcome-ar.md` (a copy of `ar-spec.md`)
- Modify: `MarkdownApp.swift` (the `welcome` window and its first-launch trigger), `AppCommands.swift` (Help menu item)
- Test: `Packages/TegelKit/Tests/TegelKitTests/QuickLookSetupTests.swift`

**Interfaces:**
- Produces (TegelKit; plan 08 Task 11's interface, unchanged):
```swift
public enum QuickLookSetup {
    public static let settingsURL: URL      // x-apple.systempreferences:com.apple.ExtensionsPreferences
    public enum SettingsPath: Sendable, Equatable { case privacySecurityExtensions, loginItemsExtensions }
    public static func settingsPath(macOSMajor: Int) -> SettingsPath   // 14 → .privacySecurityExtensions; ≥ 15 → .loginItemsExtensions
}
```
- Produces (app): `Window("Welcome to Tegel Markdown", id: "welcome") { WelcomeView() }.windowResizability(.contentSize)`, `@AppStorage("TGWelcomeShown")`, and Help ▸ "Welcome to Tegel Markdown" (`CommandGroup(after: .help)`, before Copy Diagnostics).
- First launch: when `TGWelcomeShown` is false, the window opens by itself once and sets the key to `true`; afterwards only the Help item opens it.
  - macOS 15+: `.defaultLaunchBehavior(welcomeShown ? .suppressed : .presented)` on the `Window` scene (macOS 15.0+).
  - macOS 14 has no such modifier: `AppDelegate.applicationDidFinishLaunching` performs the Help menu's "Welcome to Tegel Markdown" item once.
  - Record the mechanism that worked in the commit body.
- Copy (exact English; translated in Task 16). Layout, type styles and symbols per app-ui-spec Step 5:
  - Title: "Welcome to Tegel Markdown"
  - Intro: "Read Markdown on your Mac, in Finder and in a window. Files you open stay unchanged."
  - Heading (`eye`): "Preview in Finder"
  - Body, chosen by `QuickLookSetup.settingsPath(macOSMajor: ProcessInfo.processInfo.operatingSystemVersion.majorVersion)`:
    - `.loginItemsExtensions`: "Select a Markdown file and press Space. If Finder shows plain text, turn on Tegel Markdown in System Settings › General › Login Items & Extensions › Quick Look."
    - `.privacySecurityExtensions`: "Select a Markdown file and press Space. If Finder shows plain text, turn on Tegel Markdown in System Settings › Privacy & Security › Extensions › Quick Look."
    - Then: "If another Markdown previewer is installed, turn it off in the same list."
  - Button "Open System Settings…": `NSWorkspace.shared.open(QuickLookSetup.settingsURL)`; if that returns `false`, open `x-apple.systempreferences:` (the Settings home).
  - Heading (`doc.text`): "Open a file or folder"
  - Buttons:
    - "Open Sample": opens the bundled `Welcome.md`, or `Welcome-ar.md` when `Bundle.main.preferredLocalizations.first == "ar"`, with `NSDocumentController.shared.openDocument(withContentsOf:display: true)`.
    - "Open…": `NSDocumentController.shared.openDocument(nil)`.
    - "Done": the default button (Return); closes the window.
  - No price, no licensing copy, no Pro prompt (`DESIGN.md` §11).

- [ ] **Step 1: Write the failing test** (plan 08 Task 11's assertions, in XCTest like the rest of this suite)

```swift
final class QuickLookSetupTests: XCTestCase {
    func testSettingsPathFollowsMacOSVersion() {
        XCTAssertEqual(QuickLookSetup.settingsPath(macOSMajor: 14), .privacySecurityExtensions)
        XCTAssertEqual(QuickLookSetup.settingsPath(macOSMajor: 15), .loginItemsExtensions)
        XCTAssertEqual(QuickLookSetup.settingsPath(macOSMajor: 27), .loginItemsExtensions)
        XCTAssertEqual(QuickLookSetup.settingsURL.absoluteString, "x-apple.systempreferences:com.apple.ExtensionsPreferences")
    }
}
```

- [ ] **Step 2: Run**

Run: `swift test --package-path Packages/TegelKit --filter QuickLookSetupTests`
Expected: FAIL, `cannot find 'QuickLookSetup' in scope`.

- [ ] **Step 3: Implement `QuickLookSetup`, then run again**

Run: `swift test --package-path Packages/TegelKit --filter QuickLookSetupTests`
Expected: `Executed 1 test, with 0 failures`.

- [ ] **Step 4: Bundle the samples**

Run: `mkdir -p Apps/Markdown/App/Samples && cp docs/design/samples/en-spec.md Apps/Markdown/App/Samples/Welcome.md && cp docs/design/samples/ar-spec.md Apps/Markdown/App/Samples/Welcome-ar.md && cmp docs/design/samples/en-spec.md Apps/Markdown/App/Samples/Welcome.md && cmp docs/design/samples/ar-spec.md Apps/Markdown/App/Samples/Welcome-ar.md && echo same`
Expected: `same`. XcodeGen copies `.md` files under `Apps/Markdown/App` as resources.

- [ ] **Step 5: Implement `WelcomeView`, the window, the first-launch trigger and the Help item, then check by hand** (build Mac, macOS 15.7)

Run: `xcodegen generate && make test-app && make run-app ARGS="-TGWelcomeShown NO"`
Expected: `** TEST SUCCEEDED **`. Then by hand:
1. Welcome appears with no document Open panel on top. If the panel covers it, register `NSShowAppCentricOpenPanelInsteadOfUntitledFile = false` in `UserDefaults.register(defaults:)` and check again.
2. The Quick Look paragraph shows the macOS 15 path. "Open System Settings…" lands on Login Items & Extensions; save `screencapture -x -w docs/reviews/m02-design/welcome-settings-15.png`.
3. "Open Sample" opens `Welcome.md` read-only; "Open…" shows the standard open panel; Return closes Welcome.
4. ⌘Q, then `make run-app`: no Welcome. Help ▸ Welcome to Tegel Markdown opens it.

The Arabic sample is checked in Task 16, once the `ar` localisation exists. The macOS 14 copy, the macOS 14 launch trigger and the deep link on 14 and 27 are checked remotely (Task 17's pending list; plan 08 Task 11 Step 2).

- [ ] **Step 6: Commit** `Packages/TegelKit/Sources/TegelKit/QuickLookSetup.swift Packages/TegelKit/Tests/TegelKitTests/QuickLookSetupTests.swift Apps/Markdown/App docs/reviews/m02-design`, "feat(app): Welcome window with the Quick Look guide and QuickLookSetup deep link"

---

### Task 16: Localisation (en, nl, fr, ar)

**UI spec:** DESIGN.md (voice; §11 banned patterns) and app-ui-spec (Step 8, Arabic UI mirror).

**Files:**
- Create: `Apps/Markdown/App/Localizable.xcstrings`
- Modify: `project.yml`:
  - `options.developmentLanguage: en`;
  - app settings `LOCALIZATION_PREFERS_STRING_CATALOGS: YES` and `SWIFT_EMIT_LOC_STRINGS: YES`;
  - Info.plist `CFBundleLocalizations: [en, nl, fr, ar]`.
- Test: `Apps/Markdown/AppTests/LocalizationTests.swift`
- Create: `docs/reviews/m02-design/ar-ui.png`

**Interfaces:**
- Consumes: every user-facing string literal from Tasks 1–15. SwiftUI `Text`/`Button` literals are extracted automatically. AppKit strings (panels, alerts) use `String(localized:)`.
- Glossary, applied in every language:
  - Never translated: "Tegel Markdown", "Pro", "Markdown", "PDF", "Mermaid", "Quick Look", "A4".
  - English spelling is British ("Licence").
  - Arabic is Modern Standard Arabic.

- [ ] **Step 1: Write the failing test**

The hosted test runs inside the sandbox and can't read the repo. It therefore checks the compiled tables in the app bundle, which is also what ships.

```swift
final class LocalizationTests: XCTestCase {
    private let untranslated: Set = ["Tegel Markdown", "Tegel Markdown Pro", "Pro", "PDF", "A4", "Markdown"]
    private func table(_ lang: String) throws -> [String: String] {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: lang), "\(lang) table missing")
        return try XCTUnwrap(NSDictionary(contentsOfFile: path) as? [String: String])
    }
    private func placeholders(_ s: String) -> [String] { s.matches(of: /%(\d+\$)?(lld|@|d|f)/).map { String($0.output.0) }.sorted() }

    func testBundleShipsFourLanguages() { XCTAssertTrue(Set(["en", "nl", "fr", "ar"]).isSubset(of: Set(Bundle.main.localizations))) }
    func testEveryKeyTranslatedWithSamePlaceholders() throws {
        let en = try table("en"); XCTAssertGreaterThanOrEqual(en.count, 30)
        for lang in ["nl", "fr", "ar"] { let t = try table(lang)
            for (key, value) in en where !untranslated.contains(value) {
                let v = try XCTUnwrap(t[key], "\(lang) missing: \(key)")
                XCTAssertFalse(v.isEmpty); XCTAssertEqual(placeholders(v), placeholders(value), "\(lang) placeholders: \(key)")
            }
        }
    }
    func testArabicValuesAreArabic() throws {
        for (key, v) in try table("ar") where key.replacing(/%(\d+\$)?(lld|@|d|f)/, with: "").contains(where: \.isLetter) && !untranslated.contains(v) {   // "%@:%lld" has no words
            XCTAssertTrue(v.unicodeScalars.contains { (0x0600...0x06FF).contains($0.value) }, "ar not Arabic: \(key)")
        }
    }
}
```

- [ ] **Step 2: Run** (the build extracts the keys into the catalog; the translations are still missing)

Run: `xcodegen generate && make test-app ONLY=LocalizationTests`
Expected: FAIL with `nl table missing` or `nl missing: …`. If the message is `en table missing`, the catalog wasn't compiled: check the two build settings before going on.

- [ ] **Step 3: Translate every key into nl, fr and ar using the glossary**

Mark brand-only keys `shouldTranslate: false`. The founder reviews the ar and fr tables (see open questions).

- [ ] **Step 4: Run, then check the Arabic UI**

Run: `make test-app ONLY=LocalizationTests && make run-app FILES="Fixtures/markdown/rtl-arabic.md" ARGS='-AppleLanguages "(ar)" -TGForcePro YES'`
Expected: `Executed 3 tests, with 0 failures`.

Then set one `ar` value in the catalog to its English text and rerun `make test-app ONLY=LocalizationTests/testArabicValuesAreArabic`. Expected: FAIL, `ar not Arabic: <that key>`. Restore it and rerun: PASS.

Then open `Fixtures/markdown` as a folder, show the find bar and the inspector, and run `screencapture -x -w docs/reviews/m02-design/ar-ui.png` (click the folder window). Check and record pass/fail per item in `docs/reviews/m02.md`:
- sidebar on the right, inspector on the left, toolbar mirrored;
- find-bar Previous/Next mirrored, text fields right-aligned;
- the Pro window, Welcome and Settings mirrored;
- Help ▸ Welcome to Tegel Markdown ▸ "Open Sample" opens the Arabic sample (`Welcome-ar.md`);
- document content follows its own direction (English fixtures stay LTR, code stays LTR).

Repeat the run with `"(nl)"` and `"(fr)"` and check that nothing is truncated.

- [ ] **Step 5: Commit** `project.yml Apps/Markdown/App Apps/Markdown/AppTests/LocalizationTests.swift docs/reviews/m02-design`, "feat(i18n): en/nl/fr/ar string catalog with placeholder and RTL checks"

---

### Task 17: Remote checks, Procedure P, merge

**Files:**
- Modify (only if needed): `.github/workflows/ci.yml`. Its macOS `workflow_dispatch` job must run `swift test --package-path Packages/TegelKit` on `macos-15` and `macos-26`. Hosted app tests stay local, because they need a signed sandboxed host.
- Modify: `docs/reviews/m02.md` (created in Task 1). Create: `docs/reviews/design-m02.md`

- [ ] **Step 1: Remote arm64 runs** (local evidence is Intel/macOS 15.7 only)

GitHub dispatches a workflow only if it exists on the default branch, and `--ref` then runs the branch's copy (K13).
- Run: `git fetch origin && git ls-tree --name-only origin/main .github/workflows/`. Expected: `ci.yml` (plan 01) and `design-shots.yml` (plan 09 Drop B) are listed.
- If `ci.yml` needs the change above, it lands on `main` first: `git switch main`, make the edit, run stage 3 (code review) on that one diff, `git commit` + `git push origin main` (D14), `git switch m02-app1-features && git merge main -m "merge: main (ci.yml) into m02-app1-features" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"` (a merge, not a rebase: a rebase would drop Task 10 Step 0's merge and replay its conflicts). The branch then carries it too.

Read the CI minutes as plan 05 Task 3 Step 3 defines (B20). If what's left can't cover the two dispatches below, don't dispatch: ask the user.

Run: `git push -u origin m02-app1-features && gh workflow run ci.yml --ref m02-app1-features && gh workflow run design-shots.yml --ref m02-app1-features -f run_app_shots=true && gh run watch`
- These two dispatches are the milestone's macOS runs: one matrix run each, not one per push. Re-dispatch only after a fix to the code under test, and read the minutes again first.
- This needs `gh auth login` by the user. Without it, ask the user to press "Run workflow" for the branch under Actions.
- Expected: `ci.yml` green on `macos-15` and `macos-26` (arm64), including `PDFExporterTests` (FB20581927 is a recent WebKit bug, so `macos-26` matters most), `ThemeTests`, `DocumentImageHandlerTests`, `LocalImageTests` and `FindTests`. `design-shots.yml` uploads `design-shots-macos-26`; download it with `gh run download -D docs/reviews/m02-design/runner` for Step 2.
- Record the run URLs in m02.md.
- macOS 27 isn't tested in this milestone. Add a "Pending remote checks (lease L2, Thu 26 Nov 09:00 → Fri 27 Nov 09:00; third in its order, after plan 05's matrix and plan 03's acceptance)" list to m02.md: PDF suite, local images under the sandbox, folder restore, Arabic UI, all on macOS 27 arm64. On L2's last leg (macOS 14, if offered): Welcome's first-launch trigger and its macOS 14 Quick Look copy.

- [ ] **Step 2: Run Procedure P stages 1–10 (master §11)** for id `m02`, branch `m02-app1-features`; the record is `docs/reviews/m02.md`. Deltas:
- **Stage 4 `/cso` scope** (the diff touches bookmarks, file access, the export path and renderer JS/CSS):
  - `BookmarkStore`: grant lifetime, the 20 cap, stale and unmounted handling.
  - `DocumentImageHandler`: serves only regular `UTType.image` files inside the grant root (`isInside`: path components after resolving symlinks); `..`, `%2E%2E`, symlinks out, sibling prefixes and non-images get 404; no root (Quick Look) serves nothing.
  - Export: every handler-served image outside the document's folder is listed before the PDF is written; "Cancel" writes nothing. `makePDFData`'s private folder is 0700 and gone when the call returns.
  - `markdown.js`: the `baseHref` rewrite touches only relative image `src`. (The `fileImages` hook and the CSP are plan 01's, under its own stage 4.)
  - `page.js`: `image:` error strings are never inserted as HTML; `scrollToLine` and `data-line` stay harmless with hostile raw HTML; `data-theme` can't be set by content.
  - `FolderIndex`: symlinks, the read cap via `TextFileLoader`, search cancellation. The window open path: no whole-file read (Task 1).
  - `Diagnostics`: no key, no paths. Welcome: opens only `QuickLookSetup.settingsURL` or the Settings home, and bundled samples.
  - Quick Look: plan 01's hostile-Markdown tests (in `make check`).
- **Stage 10 design review** (the m02 gate in `DESIGN.md` §12): capture in **light, dark and Arabic UI** into `docs/reviews/m02-design/`, with `scripts/window-shot.sh "Tegel Markdown" docs/reviews/m02-design/<name>-<light|dark>.png` (plan 09 Task 12) and `ARGS='-AppleLanguages "(ar)"'` for the Arabic UI:
  - the window × paper/ink/studio (Task 10's PNGs count);
  - Arabic UI with an English document; English UI with `docs/design/samples/ar-spec.md`;
  - the folder window; Settings, each tab (General and Appearance; plan 03 adds Licence and Updates); the Pro window; Welcome; the export confirmation (Task 12);
  - the Quick Look panel, and Quick Look at 260 px;
  - PDF page 1 of an English and an Arabic export (`sips -s format png`);
  - the `macos-26` runner set from Step 1 (`docs/reviews/m02-design/runner/`).

  Write `docs/reviews/design-m02.md` with the sections Inputs (paths), Findings (P0/P1/P2), Guard output, Verdict. Pass criteria: `design.test.js` and `DesignRenderTests` green; RTL mirror correct; every toolbar item labelled in the VoiceOver rotor; Liquid Glass only on system chrome. Fix every P0/P1 in the owning task's files and re-run that task's tests.

Expected: every stage recorded in m02.md (or named as not run, with the reason and the substitute); two consecutive cubic rounds with no new P0/P1.

- [ ] **Step 3: Commit** `docs/reviews/m02.md docs/reviews/design-m02.md docs/reviews/m02-design`, "docs(review): M02 Procedure P and design-review record"

- [ ] **Step 4: Procedure P stage 11: merge and push** with the message `merge: M02 App 1 reader features`.
Expected: `make check` green on `main`; the push succeeds; `graphify update .` runs.

---

## Self-review

- **Gaps left on purpose:** folder drops on the Dock icon (Task 14); folders in Open Recent (`DocumentGroup` recents hold documents only); renderer-made strings stay English (CR-2); Quick Look shows no local images (K4).

## Contract change requests

CR 1, 3 and 4 accepted and applied to master §3.2 and §3.3 (27 Oct); history in `docs/reviews/m00-consolidated.md`. Open:

- **CR-2: add a language option to the renderer.**
  - **Change:** add `lang?: string` to `window.tegel.render` opts and `RenderOptions.language: String?`.
  - **Reason:** the renderer's own strings (truncation notice, Mermaid error label, front-matter summary) would follow the UI language (D6). Without it, the Arabic, Dutch and French UIs show those few strings in English inside the document view. Plan 02 ships without it; it can land in v1.0.1.
