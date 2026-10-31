# M01 · G0: renderer, App 1 shell and Quick Look — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pass gate G0 by Mon 2 Nov 2026. A ≈1 MB Markdown file with Mermaid and RTL text must render in < 1 s in the App 1 window **and** in Quick Look, on macOS 15 (Intel, local) and on macOS 27 (arm64, Scaleway). The proof is measured numbers recorded in `docs/gates/G0.md`.

**Architecture:**
- **Renderer:** one JS renderer built by bun. `markdown.js` is pure and turns Markdown into an HTML string. `page.js` sanitises that HTML with DOMPurify, inserts it, lazy-loads Mermaid and posts `rendered`. The bundle is committed into the `TegelKit` SwiftPM resources.
- **TegelKit:** `RendererWebView` wraps one `WKWebView` holding that page, with navigation and network blocked and a timeout. `TextFileLoader` reads at most the first 5 MB of a regular file and decodes it.
- **App 1 and its Quick Look extension** both link TegelKit statically. A `--benchmark` flag gives headless numbers on remote Macs.

**Tech Stack:**
- Swift 6 language mode. SwiftUI `DocumentGroup(viewing:)`, AppKit, WebKit, QuickLookUI, `os.Logger`/`OSSignposter`.
- XCTest under `swift test`. XcodeGen 2.46.0.
- bun 1.4.0 (runtime, bundler, test runner).
- Exact npm pins, each checked with `npm view <pkg> time` on 27 Oct 2026: markdown-it 14.3.3, highlight.js 11.12.0, dompurify 3.4.17, mermaid 11.17.2.
- GitHub Actions; Scaleway M1 [F9].

**Spec:**
- `BUSINESS-PLAN.md` §5, §6.1, §6.3, §7.1–7.2, §11 W1, §12 G0 and §15.
- `docs/superpowers/plans/2026-10-27-00-master-roadmap.md` (§2 decisions, §3 contract, §3.4 fixtures, §5 checkpoints).
- `docs/research/2026-10-27-technical-facts.md` ([F#]). `CLAUDE.md` (product rules 1–9, the pipeline, the hardware constraint).

**Branch:** `m01-g0-renderer`, cut from `main` (Task 1, Step 0). The pipeline base is `git merge-base HEAD main`.

## Global Constraints

Master §2/§3 and CLAUDE.md apply (platform, build Mac, product rules, secrets, approvals, Procedure P). This plan's deltas:

- **Toolchain on the build Mac:** Xcode 26.3, Swift 6.2.4, bun 1.4.0 and xcodegen 2.46.0 in `~/.local/bin` (on PATH). `swift-tools-version: 6.0`, Swift 6 language mode.
- **Identifiers:** `com.tegelapps.markdown` and `com.tegelapps.markdown.quicklook` (D7). UTType `net.daringfireball.markdown`, **imported**, extensions `md, markdown, mdown, mkd, mkdn`, conforming to `public.plain-text` [F10].
- **Entitlements (D5, K4):**
  - App: `com.apple.security.app-sandbox`, `com.apple.security.files.user-selected.read-write`, `com.apple.security.files.bookmarks.app-scope`, `com.apple.security.network.client`, and `com.apple.security.temporary-exception.mach-lookup.global-name = [$(PRODUCT_BUNDLE_IDENTIFIER)-spks, $(PRODUCT_BUNDLE_IDENTIFIER)-spki]` [F4].
  - Quick Look extension: `app-sandbox` and `network.client` only, with **no** file exception. Quick Look renders with `baseURL: nil` and shows no local images.
- **Renderer security (CSP, content rule list, sanitiser, Mermaid pass):** master §3.2, built in Task 5; any change runs Procedure P.
- **Limits:** files over **5 MB** (`maxBytes = 5_000_000`) render truncated with a banner, and nothing reads past the cap. Quick Look **never takes more than 2 s**, file I/O included (K11).
- **Scratch files:** `$SCRATCH` is `$TMPDIR/tegel-m01`. Each Bash call is a fresh shell, so every command block that uses it starts with `SCRATCH="$TMPDIR/tegel-m01"; mkdir -p "$SCRATCH"`.
- **Design:** the window and Quick Look UI stay **unstyled scaffolding**: no colour, type, spacing or theme values. `DESIGN.md` arrives with plan 09 Drop A, which merges on Mon 2 Nov after this plan; plan 09 Task 6 supplies every theme value (DESIGN.md §7 names the CSS files).
- **Approvals and budget:** any Scaleway order and any trademark filing need the user's yes. Budget: one Scaleway M1 day (lease L1), €3.19 incl. 21 % VAT (€2.64 before tax) [F9].
- **Commits:** a step written "Commit `<paths>`: `<msg>`" means `git add <paths> && git commit -m "<msg>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`. Never `git add -A`.

## Review Focus

Each line names an input class the spec implies, the expected behaviour, and the test that pins it.

1. **Hostile Markdown.** `<script>`, `onerror=`, `javascript:` links, SVG with script, `<iframe>`, remote `<img>`, Mermaid `click`, HTML in a Mermaid label, an `init` directive, a `<style>` that hides the page, `file://` links, a relative link to `index.html`, an inline `style` attribute, `<meta refresh>`, `<base>`, `@import`, a `<script src>` pointing at another `file:` URL, a `# mermaid` heading.
   - Expected: no script runs, no network request, no navigation; the surrounding text still renders and stays visible.
   - Pinned by: Task 3 `link syntax never yields…` (string level); Task 5 `testHostileFixtureRunsNoScriptAndMakesNoRequest`, `testClickingHostileLinksNeverNavigates`, `testLinkToTheRendererPageIsBlockedAndKeepsTheDocument`, `testDocumentStylesAreDroppedAndTableAlignmentStays`, `testScriptFromAnotherFileURLNeverRuns` and `testMermaidBasicRendersTwoDiagrams` (WebKit level), each watched failing in Task 5 Step 9.
2. **Odd encodings and sizes.** UTF-16 with BOM, Windows-1252, a NUL byte, an empty file, a 50 MB file, a 2 GB file opened in the window, a FIFO named `.md`, a cut through a multibyte character.
   - Expected: the text decodes, or a banner shows; nothing reads past 5 MB; a FIFO fails fast; Quick Look stays under 2 s.
   - Pinned by: Task 4 tests (incl. `testFIFOFailsFastInsteadOfBlocking`), Task 7 Step 6 and Task 8 Step 7.
3. **Mixed bidi.** An Arabic paragraph with inline English and code; RTL list, table and blockquote; a Hebrew heading followed by English.
   - Expected: each top-level block takes the direction of its first strong character, and the blocks nested in it inherit that direction; code stays LTR. An Arabic list, blockquote and table are RTL containers (indent, bar and first column on the right).
   - Pinned by: Task 3 `top-level blocks get dir=auto…` and Task 5 `testMixedBidiDirections` (WebKit `:dir()` plus table geometry).
4. **Broken or huge Mermaid.** A syntax error, a 500-node graph, 30 diagrams.
   - Expected: an error box for that one diagram only, the rest renders, and the renderer never hangs.
   - Pinned by: Task 5 `testBrokenMermaidShowsOneErrorAndRendersTheRest` and `testThirtyDiagramsAndFiveHundredNodeGraphFinish`.
5. **Pathological structure.** 10,000 nested `>`, a 5,000-deep list, a 5 MB single line.
   - Expected: renders without throwing, in < 1.5 s (markdown-it's `maxNesting` caps the depth).
   - Pinned by: Task 3 `pathological structure renders quickly without throwing`.
   - The master's fifth line, licence edge cases, belongs to plan 03.

---

## File map

| Path | Task | Responsibility |
|---|---|---|
| `Makefile`, `Config/{Debug,Release}.xcconfig`, `Packages/TegelKit/Package.swift` | 1 | build entry points, signing, package |
| `scripts/lib/env.sh`, `scripts/lib/env_test.sh`, `scripts/check-guards.sh` | 1 | literal `.env` access (K1); `.env`, `bunx` and action-pin guards |
| `Packages/TegelKit/Sources/TegelKit/RendererTypes.swift` | 1 | contract value types |
| `Fixtures/markdown/*.md` (12 committed), `Fixtures/generate.js`, `.gitattributes` | 2 | shared test inputs |
| `Renderer/package.json`, `bun.lock`, `src/markdown.js`, `test/markdown.test.js` | 3 | pure Markdown → HTML |
| `Packages/TegelKit/Sources/TegelKit/TextFileLoader.swift` | 4 | bytes → text, 5 MB cap |
| `Renderer/src/{page.js,sanitize.js,index.html,css/*.css}`, `Renderer/build.js`, `Resources/Renderer/*` | 5 | DOM side, shared sanitiser, CSP, bundle |
| `Packages/TegelKit/Sources/TegelKit/RendererWebView.swift`, `Tests/TegelKitTests/WebView/*` | 5, 6 | WKWebView host + integration/perf tests |
| `project.yml`, `Apps/Markdown/App/{MarkdownApp,DocumentView}.swift` | 7 | App 1 shell, `--benchmark` |
| `Apps/Markdown/QuickLook/PreviewViewController.swift` | 8 | Quick Look (view-based) |
| `.github/workflows/ci.yml` | 10 | CI |
| `docs/gates/{G0,trademark}.md`, `docs/reviews/{m01,design-m01}.md`, `docs/reviews/m01-design/` | 6, 9, 11–14 | evidence and decisions |

## W1 schedule

| Day | Work |
|---|---|
| Tue 27 Oct | Tasks 1–3. Task 11 (trademark), which must finish by Thu 29 because H4 buys the domain on Fri 30 |
| Wed 28 Oct | Tasks 4–5. Task 12 Steps 1–2 (Scaleway account; the user adds a card for H6) |
| Thu 29 Oct | Tasks 6–8 |
| Fri 30 Oct | Tasks 9–10. Lease L1 may be ordered this evening (Task 12 Steps 3–4), once the user's yes is in |
| Sat 31 Oct | Task 12 Steps 3–9: if L1 wasn't ordered on Friday evening, order it in the morning (the non-default macOS adds about 1 h), then the remote G0 run |
| Sun 1 Nov | Task 12 Step 10: delete the server 24 h after the order (Sat 31 Oct evening if ordered on Friday evening) |
| Mon 2 Nov | Task 13 (G0 decision), Task 14 (pipeline, merge, push) |

---

### Task 1: Scaffolding — Makefile, xcconfigs, TegelKit package, contract value types, `.env` helper

**Files:**
- Create: `Makefile`, `Config/Debug.xcconfig`, `Config/Release.xcconfig`, `Packages/TegelKit/Package.swift`, `Packages/TegelKit/Sources/TegelKit/RendererTypes.swift`, `scripts/lib/env.sh`, `scripts/check-guards.sh`
- Modify: `.gitignore` (append)
- Test: `Packages/TegelKit/Tests/TegelKitTests/RendererTypesTests.swift`, `scripts/lib/env_test.sh`

**Interfaces:**
- Consumes: nothing.
- Produces (contract §3.3, verbatim):
  - `public enum RendererTheme: String, CaseIterable, Sendable { case paper, ink, studio }`
  - `public enum RenderMode: String, Sendable { case window, quicklook, print }`
  - `public struct RenderOptions: Sendable { public var mode: RenderMode; public var theme: RendererTheme; public var baseURL: URL? }`
  - `public struct Heading: Sendable, Hashable, Decodable { public let level: Int; public let text: String; public let id: String }`
  - `public struct RenderResult: Sendable, Decodable { public let ms: Double; public let headings: [Heading]; public let mermaidCount: Int; public let errors: [String] }`
- Produces (addition; the synthesised memberwise init is internal): `public init(mode: RenderMode = .window, theme: RendererTheme = .paper, baseURL: URL? = nil)` on `RenderOptions`.
- Produces: Make targets `check generate renderer test-js test-swift test-shell build fixtures clean` (master §3.1). `build` depends on `generate` (`xcodegen generate`), so a fresh clone builds; plan 02's `test-app` depends on it too (CR-P2-17). `test-js` runs `bun audit` (S27). `test-shell` runs the `.env` test and the guards.
- Produces (K1), `scripts/lib/env.sh`, loaded with `. scripts/lib/env.sh` from the repo root; the file is `${ENV_FILE:-.env}`:
  - `envget KEY` prints the value through a literal parse of the first line starting `KEY=`, in the forms `.env.example` uses. A `'…'` value (envset's form) has each `'\''` turned back into `'`; a `"…"` value is taken as written, with no escapes. Anything after the closing quote is ignored, and an unterminated quote reads as empty. An unquoted value ends where a `#` starts it or follows a blank, so `KEY=   # note` reads as empty, and surrounding blanks are trimmed. It never sources the file and prints nothing for a missing key.
  - `envset KEY VALUE` refuses a bad key name or a value with a newline (exit 1). Otherwise, under `umask 077`, it writes every other line plus `KEY='VALUE'` (each `'` escaped as `'\''`) to a `mktemp` file in the same folder, then `mv`s it over the original (atomic, mode 600). The read-modify-write holds a `mkdir "$f.lock"` lock, so parallel agents never drop each other's keys (a vendor shows some tokens only once). A subshell-scoped trap removes the lock on every exit path; a lock held for 10 s fails with exit 1 rather than hanging.
  - `need KEY...` returns 1 with `missing .env key: KEY` for the first empty key. It never prints a value.
- Produces (K1, K13): `scripts/check-guards.sh` exits 1 and lists the lines when `scripts`, `Makefile` or `site` contain `set -a` or a `bunx <pkg>` with no `@version`, or when a `uses:` line in `.github/workflows` isn't pinned to a 40-hex SHA.

- [ ] **Step 0: Cut the branch**

Run: `git checkout main && git pull --ff-only && git checkout -b m01-g0-renderer && git rev-parse --short HEAD`
Expected: `Switched to a new branch 'm01-g0-renderer'`, then the base SHA (today `68f3bf5`).

- [ ] **Step 1: Write `Package.swift` and the failing test**

```swift
// Packages/TegelKit/Package.swift
// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "TegelKit",
    platforms: [.macOS(.v14)],
    products: [.library(name: "TegelKit", targets: ["TegelKit"])],   // plan 03 adds TegelStore
    targets: [
        .target(name: "TegelKit"),                                    // Task 5 adds resources
        .testTarget(name: "TegelKitTests", dependencies: ["TegelKit"]),
    ]
)
```

```swift
// Packages/TegelKit/Tests/TegelKitTests/RendererTypesTests.swift
import XCTest
@testable import TegelKit

final class RendererTypesTests: XCTestCase {
    func testRenderResultDecodesTheRenderedMessage() throws {
        let json = #"{"type":"rendered","ms":12.5,"headings":[{"level":2,"text":"مرحبا","id":"مرحبا"}],"mermaidCount":1,"errors":["Parse error on line 2"]}"#
        let r = try JSONDecoder().decode(RenderResult.self, from: Data(json.utf8))
        XCTAssertEqual(r.ms, 12.5)
        XCTAssertEqual(r.headings, [Heading(level: 2, text: "مرحبا", id: "مرحبا")])
        XCTAssertEqual(r.mermaidCount, 1)
        XCTAssertEqual(r.errors, ["Parse error on line 2"])
    }
    func testThemeRawValuesAreTheJSThemeNames() {
        XCTAssertEqual(RendererTheme.allCases.map(\.rawValue), ["paper", "ink", "studio"])
        XCTAssertEqual(RenderMode.quicklook.rawValue, "quicklook")
    }
    func testRenderOptionsDefaultToFreeWindowRendering() {
        let o = RenderOptions()
        XCTAssertEqual(o.mode, .window); XCTAssertEqual(o.theme, .paper); XCTAssertNil(o.baseURL)
    }
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `swift test --package-path Packages/TegelKit --filter RendererTypesTests`
Expected: FAIL. The build errors with `cannot find 'RenderResult' in scope`, or with missing `Sources/TegelKit`.

- [ ] **Step 3: Implement the types in `RendererTypes.swift`**

Write the contract types exactly as in Interfaces, plus the `RenderOptions` init.

- [ ] **Step 4: Run it and watch it pass**

Run: `swift test --package-path Packages/TegelKit --filter RendererTypesTests`
Expected: `Executed 3 tests, with 0 failures`.

- [ ] **Step 5: Write the Makefile, xcconfigs and ignores**

```make
# Makefile — recipes are indented with a TAB. GNU Make 3.81 (macOS) compatible.
BUN      ?= bun
XCODEGEN ?= xcodegen
PKG      := Packages/TegelKit
G0       := Fixtures/markdown/g0-1mb.md

.PHONY: check generate renderer test-js test-swift test-shell build fixtures clean
check: test-js test-swift test-shell build
generate:
	$(XCODEGEN) generate
renderer:
	cd Renderer && $(BUN) install --frozen-lockfile --ignore-scripts && $(BUN) build.js
test-js:
	cd Renderer && $(BUN) install --frozen-lockfile --ignore-scripts && $(BUN) audit && $(BUN) test && $(BUN) build.js --check
test-swift: $(G0)
	swift test --package-path $(PKG)
test-shell:
	scripts/lib/env_test.sh && scripts/check-guards.sh
build: generate
	xcodebuild -project Tegel.xcodeproj -scheme markdown -configuration Debug -derivedDataPath build ONLY_ACTIVE_ARCH=NO build
fixtures:
	$(BUN) Fixtures/generate.js
$(G0): Fixtures/generate.js
	$(BUN) Fixtures/generate.js
clean:
	rm -rf build Tegel.xcodeproj $(PKG)/.build Fixtures/markdown/g0-1mb.md Fixtures/markdown/huge-50mb.md
```

`Config/Debug.xcconfig`. Ad-hoc signing ("sign to run locally"), because no Developer ID exists until H2:
```
CODE_SIGN_IDENTITY = -
CODE_SIGN_STYLE = Manual
DEVELOPMENT_TEAM =
MARKETING_VERSION = 0.1.0
CURRENT_PROJECT_VERSION = 1
```
`Config/Release.xcconfig`. Placeholders that plan 03 fills:
```
// plan 03 (H2): DEVELOPMENT_TEAM from .env APPLE_TEAM_ID; TG* Polar keys (D16)
CODE_SIGN_IDENTITY = Developer ID Application
CODE_SIGN_STYLE = Manual
DEVELOPMENT_TEAM =
ENABLE_HARDENED_RUNTIME = YES
ONLY_ACTIVE_ARCH = NO
MARKETING_VERSION = 0.1.0
CURRENT_PROJECT_VERSION = 1
```
Append to `.gitignore`. XcodeGen writes these files from `project.yml`, which stays the source of truth:
```
Apps/*/*/Info.plist
Apps/*/*/*.entitlements
Packages/TegelKit/TestHost/Info.plist
```

Run: `make -n test-js build`
Expected: three lines, `cd Renderer && bun install --frozen-lockfile --ignore-scripts && bun audit && bun test && bun build.js --check`, `xcodegen generate` and the `xcodebuild` line. Nothing runs. (`make -n check` would stop here with `No rule to make target 'Fixtures/generate.js'`, because Task 2 creates it.)

- [ ] **Step 6: Write the `.env` helper test and watch it fail**

```bash
#!/bin/bash
# scripts/lib/env_test.sh: tests scripts/lib/env.sh on a temporary .env. Stops at the first failure.
set -eu
. "$(dirname "$0")/env.sh"
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
ENV_FILE="$d/.env"
fail() { echo "FAIL: $*" >&2; exit 1; }
id="Developer ID Application: Jane O'Neil (AB12CD34EF)"
meta='a$(touch "'"$d"'/pwn")b`id` & ; ( ) \ "q" $HOME'
envset APPLE_DEVELOPER_ID_IDENTITY "$id"
envset PW "$meta"
envset PW2 x; envset PW2 y
for i in $(seq 20); do envset "P$i" "$i" & done; wait   # 20, not 2: two racing writers can both survive by luck
[ "$(grep -c '^P[0-9]' "$ENV_FILE")" = 20 ] && [ ! -e "$ENV_FILE.lock" ] || fail "concurrent envset calls lost a key or left the lock"
[ "$(envget APPLE_DEVELOPER_ID_IDENTITY)" = "$id" ] || fail "round-trip: spaces, colon, parentheses, quote"
[ "$(envget PW)" = "$meta" ] || fail "round-trip: shell metacharacters"
[ "$(envget PW2)" = y ] && [ "$(grep -c '^PW2=' "$ENV_FILE")" = 1 ] || fail "overwrite keeps one line"
[ -z "$(envget MISSING)" ] || fail "a missing key reads empty"
[ "$(stat -f %Lp "$ENV_FILE")" = 600 ] || fail "mode is 600"
! envset NL "$(printf 'a\nb')" 2>/dev/null || fail "a newline was accepted"
[ -z "$(envget NL)" ] || fail "a refused value was written"
[ "$(. "$ENV_FILE" 2>/dev/null; printf '%s|%s' "${APPLE_DEVELOPER_ID_IDENTITY-}" "${PW-}")" = "$id|$meta" ] || fail "a shell reading the file sees other values"
[ ! -e "$d/pwn" ] || fail "a stored value ran as code"
printf '%s\n' 'C1=        # comment only, as in .env.example' 'C2="Developer ID Application: A (B)"  # note' 'C3=tegel-notary  # note' "C4='it'\\''s' # note" 'C5=a#b' >> "$ENV_FILE"
[ -z "$(envget C1)" ] || fail ".env.example syntax: a comment-only value reads empty"
[ "$(envget C2)|$(envget C3)|$(envget C4)|$(envget C5)" = "Developer ID Application: A (B)|tegel-notary|it's|a#b" ] || fail ".env.example syntax: double quotes and inline comments"
need APPLE_DEVELOPER_ID_IDENTITY PW || fail "need on set keys"
[ "$(need PW C1 2>&1)" = "missing .env key: C1" ] || fail "need names the first empty key, nothing else"
[ "$(need PW MISSING 2>&1)" = "missing .env key: MISSING" ] || fail "need names the missing key, nothing else"
echo "env_test: PASS"
```

Run: `chmod +x scripts/lib/env_test.sh && scripts/lib/env_test.sh; echo "exit=$?"`
Expected: `scripts/lib/env.sh: No such file or directory` and `exit=1`.

- [ ] **Step 7: Write `scripts/lib/env.sh` and watch the test pass, then fail on the old writer**

```sh
# scripts/lib/env.sh: literal .env access (K1). Load it from the repo root with `. scripts/lib/env.sh`.
# .env is never sourced: a value is data, never shell code.
envget() {  # envget KEY: print KEY's value, or nothing
  awk -v k="$1" 'BEGIN { q = sprintf("%c", 39) }
    index($0, k "=") == 1 {
      v = substr($0, length(k) + 2); sub(/^[ \t]+/, "", v); c = substr(v, 1, 1)
      if (c == q) {                   # envset form; each '\'' stands for one quote
        s = substr(v, 2); v = ""
        while ((i = index(s, q)) > 0) {
          v = v substr(s, 1, i - 1); s = substr(s, i + 1)
          if (substr(s, 1, 3) != "\\" q q) break
          v = v q; s = substr(s, 4)
        }
        if (i == 0) v = ""            # unterminated: read as empty
      } else if (c == "\"") {         # "…" as in .env.example, no escapes
        v = substr(v, 2); i = index(v, "\""); v = i ? substr(v, 1, i - 1) : ""
      } else { sub(/(^|[ \t])#.*/, "", v); sub(/[ \t\r]+$/, "", v) }   # a # at the start or after a blank opens a comment
      print v; exit
    }' "${ENV_FILE:-.env}" 2>/dev/null
}
envset() {  # envset KEY VALUE: write KEY='VALUE' atomically with mode 600; a newline is refused
  case "$1" in ''|[0-9]*|*[!A-Za-z0-9_]*) echo "envset: bad key name" >&2; return 1;; esac
  case "$2" in *'
'*) echo "envset: $1: value has a newline" >&2; return 1;; esac
  (
    umask 077; f="${ENV_FILE:-.env}"; n=0
    until mkdir "$f.lock" 2>/dev/null; do   # one writer at a time: parallel agents must not drop each other's keys
      n=$((n + 1)); [ $n -lt 100 ] || { echo "envset: $f.lock held for 10 s; remove it if no envset is running" >&2; exit 1; }
      sleep 0.1
    done
    trap 'rmdir "$f.lock"' EXIT; trap 'exit 1' HUP INT TERM   # set only once the lock is ours
    t=$(mktemp "$(dirname "$f")/.env.XXXXXX") || exit 1
    { [ -f "$f" ] && grep -v "^$1=" "$f"
      printf "%s='%s'\n" "$1" "$(printf '%s' "$2" | sed "s/'/'\\\\''/g")"; } > "$t" && mv -f "$t" "$f"
  )
}
need() {  # need KEY...: fail naming the first empty key; never prints a value
  for k in "$@"; do [ -n "$(envget "$k")" ] || { echo "missing .env key: $k" >&2; return 1; }; done
}
```

Run: `scripts/lib/env_test.sh && zsh -c '. scripts/lib/env.sh && ENV_FILE=$(mktemp -d)/.env && envset A "x (y)" && envget A'`
Expected: `env_test: PASS`, then `x (y)` (the session shell is zsh; scripts run under bash; both work).

Then watch it fail on the writer plan 03 had: temporarily replace the `printf "%s='%s'\n" …` line with `printf '%s=%s\n' "$1" "$2"` and run `scripts/lib/env_test.sh; echo "exit=$?"`.
Expected: `FAIL: a shell reading the file sees other values` and `exit=1`. Revert; `env_test: PASS` again.

Then watch the `.env.example` cases fail on a reader that only unquotes: temporarily replace the unquoted branch `{ sub(/(^|[ \t])#.*/, "", v); sub(/[ \t\r]+$/, "", v) }` with `{ }` and run `scripts/lib/env_test.sh; echo "exit=$?"`.
Expected: `FAIL: .env.example syntax: a comment-only value reads empty` and `exit=1`. The reader this replaces fails the same way, which is how the comment-only `POLAR_ACCESS_TOKEN` and `CLOUDFLARE_API_TOKEN` lines in today's `.env` passed `need`. Revert; `env_test: PASS` again.

Then watch the lock fail: temporarily delete the `until mkdir … done` loop and the `trap` line, and run `scripts/lib/env_test.sh; echo "exit=$?"`.
Expected: `FAIL: concurrent envset calls lost a key or left the lock` and `exit=1` (in a scratch run on the build Mac, 20 unlocked writers kept 2 keys, under bash and zsh). Revert; `env_test: PASS` again.

- [ ] **Step 8: Write the guard and watch it fail on planted lines**

```sh
#!/bin/sh
# scripts/check-guards.sh
# K1 + K13 guards: .env is never sourced; packages run through bun and GitHub actions are pinned.
hits=$( { grep -rnE --exclude-dir=node_modules 'set[ ]-a|bun[x] +(-[a-z-]+ +)*(@[a-z0-9._-]+/)?[a-z0-9._-]+( |$)' scripts Makefile site
          grep -rnE '^[[:space:]-]*uses:' .github/workflows | grep -vE '@[0-9a-f]{40}([[:space:]]|$)'; } 2>/dev/null )
[ -z "$hits" ] && exit 0
printf '%s\n' "$hits"; echo "check-guards: read .env only through scripts/lib/env.sh; pin package versions and action SHAs" >&2; exit 1
```

The bracketed `[ ]` and `[x]` keep the patterns from matching the script's own text. Missing folders (`site`, `.github`) are fine.

Run:
```bash
chmod +x scripts/check-guards.sh
printf 'set -a; . ./.env; set +a\nbunx wrangler pages deploy site\nbunx wrangler@4.151.2 pages deploy site\n' > scripts/planted.sh
mkdir -p .github/workflows && printf '      - uses: actions/checkout@v7\n      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1\n' > .github/workflows/planted.yml
scripts/check-guards.sh; echo "exit=$?"
rm scripts/planted.sh .github/workflows/planted.yml && rmdir .github/workflows .github
make test-shell; echo "exit=$?"
```
Expected:
- First run: exactly `scripts/planted.sh:1:…`, `scripts/planted.sh:2:…` and `.github/workflows/planted.yml:1:…`, the `check-guards:` line, and `exit=1`. The pinned `wrangler@4.151.2` line and the SHA-pinned `uses:` line aren't listed.
- Then `env_test: PASS` and `exit=0`.

- [ ] **Step 9: Commit** `Makefile Config .gitignore Packages/TegelKit/Package.swift Packages/TegelKit/Sources Packages/TegelKit/Tests scripts/lib scripts/check-guards.sh`: "chore: scaffold Makefile, xcconfigs, TegelKit contract types and the literal .env helper"

---

### Task 2: Fixtures and the generator

**Files:**
- Create:
  - committed fixtures under `Fixtures/markdown/`: `gfm-kitchen-sink.md`, `rtl-arabic.md`, `rtl-hebrew.md`, `rtl-persian-urdu.md`, `mixed-bidi.md`, `mermaid-basic.md`, `mermaid-broken.md`, `hostile.md`, `frontmatter.md`, `utf16le-bom.md`, `cp1252.md`, `empty.md`;
  - `Fixtures/generate.js`;
  - `.gitattributes`.
- Modify: `.gitignore`.

**Interfaces:**
- Produces: the fixture invariants later tests rely on.
  - `hostile.md` contains `SENTINEL-TOP` and `SENTINEL-BOTTOM`, and its network bait points only at `http://127.0.0.1:47123/`. Its `<style>` would hide `#doc` if it survived (S10), its second Mermaid diagram carries label HTML and an `init` directive that asks for HTML labels (S8), and its third tries to break `themeCSS` out of Mermaid's per-SVG scope to hide `#doc`. The SVG pass keeps Mermaid's own `<style>` (plan 09's fill test needs it), so `SENTINEL-TOP` staying visible is what proves that style can't leave the diagram.
  - `mermaid-basic.md` starts with the heading `# mermaid` (without Task 5's `user-content-` prefix, its id `mermaid` would clobber `window.mermaid` through named access, S11) and has 2 valid diagrams.
  - `mermaid-broken.md` has 3 diagrams, the 2nd invalid, followed by `SENTINEL-AFTER-BROKEN`.
  - `g0-1mb.md` is 1,000,000–1,050,000 bytes, with exactly 5 ` ```mermaid ` fences, 60 other fences, 8 tables, and Arabic and Hebrew paragraphs.
  - `huge-50mb.md` is ≥ 50,000,000 bytes.
- Produces: CLI `bun Fixtures/generate.js`, which writes both generated files and **throws before writing** if any count above is off.

- [ ] **Step 1: Run the missing generator and watch it fail**

Run: `make fixtures`
Expected: FAIL with `Module not found "Fixtures/generate.js"`.

- [ ] **Step 2: Write the committed fixtures**

Required content per file:

| File | Must contain |
|---|---|
| `gfm-kitchen-sink.md` | h1–h6; emphasis and strike; nested ordered and unordered lists; an aligned table; a blockquote; fences in swift/js/json/bash/yaml; an indented code block; inline code; `---`; a bare `www.example.com`; `<kbd>` and `<details>` |
| `rtl-arabic.md` | Arabic heading, paragraphs, list, table, blockquote and a code fence, using the sentences below |
| `rtl-hebrew.md` | `# מדריך קצר`, a Hebrew paragraph, then an English paragraph, a list and a table |
| `rtl-persian-urdu.md` | `# راهنمای کوتاه`, `این یک فایل آزمایشی برای نمایش متن راست‌به‌چپ است.`, `## مختصر رہنما`, `یہ دائیں سے بائیں متن دکھانے کے لیے ایک آزمائشی فائل ہے۔` |
| `mixed-bidi.md` | exactly the block below |
| `mermaid-basic.md` | the heading `# mermaid`, then one `graph TD` and one `sequenceDiagram`, each valid, with prose between |
| `mermaid-broken.md` | valid `graph LR`; then ` ```mermaid ` / `graph TD` / `  A -->> -->` (invalid); then valid `pie`; then the paragraph `SENTINEL-AFTER-BROKEN` |
| `hostile.md` | the block below |
| `frontmatter.md` | `---` / `title: "<script>alert(1)</script>"` / `tags: [a, b]` / `---`, then `# Body` |
| `utf16le-bom.md` | `printf '\377\376' > F; printf '# UTF-16 مرحبا\n\nNeutral technical text.\n' \| iconv -f UTF-8 -t UTF-16LE >> F` |
| `cp1252.md` | `printf '# Caf\351 \223quotes\224 \200 5\n' > F` (octal escapes are portable to BSD `printf`; raw CP1252 bytes) |
| `empty.md` | 0 bytes (`: > F`) |

The only Arabic sentences to use. Each is neutral technical prose, reviewed against product rule 3:
`دليل القارئ` · `هذا ملف تجريبي لاختبار عرض النص العربي من اليمين إلى اليسار.` · `يدعم البرنامج الجداول والقوائم والمقاطع البرمجية.` · `الخطوة الأولى: افتح الملف.` · `الخطوة الثانية: اقرأ المحتوى.` · `ملاحظة: هذا النص للاختبار فقط.` · table `| الاسم | الحجم |` / `| ملف.md | 2 KB |`. Hebrew: `זהו קובץ בדיקה להצגת טקסט מימין לשמאל.`

`mixed-bidi.md`:
~~~markdown
# اختبار الاتجاه المختلط

يعرض هذا المستند نصًا عربيًا مع كلمة English وأمر `git status` داخل السطر.

## כותרת בעברית

This English paragraph follows a Hebrew heading and must stay left-to-right.

- عنصر أول في القائمة
- عنصر ثانٍ مع `code`

> اقتباس باللغة العربية.

| العمود | القيمة |
|---|---|
| حجم الملف | 1 MB |

```js
const x = 1; // code stays LTR
```
~~~

`hostile.md`:
~~~markdown
# Hostile input

SENTINEL-TOP

<script>window.__pwned = 'script'</script>
<img src="x" onerror="window.__pwned = 'onerror'">
<svg><script>window.__pwned = 'svg'</script><circle r="5"/></svg>
<svg onload="window.__pwned = 'svg-onload'"></svg>
<iframe src="http://127.0.0.1:47123/iframe"></iframe>
<object data="file:///etc/passwd"></object>
<embed src="file:///etc/passwd">
<form action="http://127.0.0.1:47123/form"><button>go</button></form>
<meta http-equiv="refresh" content="0;url=http://127.0.0.1:47123/refresh">
<base href="http://127.0.0.1:47123/">
<link rel="stylesheet" href="http://127.0.0.1:47123/link.css">
<style>@import url("http://127.0.0.1:47123/import.css"); #doc { display: none; background: url("http://127.0.0.1:47123/bg.png") }</style>
<img src="http://127.0.0.1:47123/raw-img.png">
<img src="data:text/html;base64,PHNjcmlwdD53aW5kb3cuX19wd25lZD0nZGF0YSc8L3NjcmlwdD4=">

[js link](javascript:window.__pwned='js-link') · <a href="javascript:window.__pwned='raw-js'">raw js</a>
[file link](file:///Users/Shared/secret.txt) · <a href="file:///etc/passwd">passwd</a>
<a href="http://127.0.0.1:47123/nav" id="http-link">http link</a>
![remote](http://127.0.0.1:47123/md-img.png)

```mermaid
graph TD
  A-->B
  click A callback "tip"
  click B "javascript:window.__pwned='mermaid'"
```

```mermaid
%%{init: {"htmlLabels": true, "flowchart": {"htmlLabels": true}}}%%
graph TD
  L["<img src=x onerror=window.__pwned='mermaid-label'>label"] --> M
```

```mermaid
%%{init: {"themeCSS": "} #doc { display: none } .x {"}}%%
graph TD
  P --> Q
```

SENTINEL-BOTTOM
~~~

- [ ] **Step 3: Write `Fixtures/generate.js`**

It has no dependencies, and its output is deterministic (no randomness).
- **g0:** loop over sections. Each section has a heading cycling EN/AR/HE, an Arabic paragraph, a Hebrew paragraph, an English paragraph, and one code fence, rotating swift/js/python/json/bash/yaml up to 60. Insert 5 Mermaid diagrams (flowchart, sequenceDiagram, classDiagram, stateDiagram-v2, erDiagram) and 8 tables at even intervals. Append English paragraphs until the byte length is ≥ 1,000,000.
- **Self-check:** assert 5 and 60 fences, 8 `|---|` separator lines, the size range, `/\p{Script=Arabic}/u` and `/\p{Script=Hebrew}/u`. Throw on any mismatch.
- **huge:** `await Bun.write(path, chunk.repeat(n))`, where `chunk` is a ≈10 KB Markdown section and `n = Math.ceil(50_000_000 / chunk.length)`.
- Append `Fixtures/markdown/g0-1mb.md` and `Fixtures/markdown/huge-50mb.md` to `.gitignore`.
- Write `.gitattributes` containing `Fixtures/markdown/utf16le-bom.md binary` and `Fixtures/markdown/cp1252.md binary`.

- [ ] **Step 4: Run the generator and verify the invariants**

Run: `make fixtures && wc -c Fixtures/markdown/g0-1mb.md Fixtures/markdown/huge-50mb.md && grep -c '^```mermaid$' Fixtures/markdown/g0-1mb.md && xxd -l 4 Fixtures/markdown/utf16le-bom.md && (iconv -f UTF-8 -t UTF-8 Fixtures/markdown/cp1252.md >/dev/null 2>&1 && echo valid-utf8 || echo invalid-utf8)`
Expected:
- g0 is between 1000000 and 1050000 bytes; huge is ≥ 50000000.
- The Mermaid fence count is `5`.
- `xxd` shows `fffe 2300`.
- The last line is `invalid-utf8`.

- [ ] **Step 5: Check the religious-text guard (product rule 3)**

`scan` decodes each file whole, the way `TextFileLoader` will (Task 4): a UTF-16LE BOM means UTF-16LE, then strict UTF-8, else Windows-1252. A plain `perl -CSD` line scan dies with `Malformed UTF-8 character (fatal)` on `cp1252.md` and stops there (reproduced on the build Mac, perl 5.34.1), and it reads `utf16le-bom.md` as bytes, so that file's Arabic would go unscanned. `-Mutf8` makes Perl read the Arabic words in the pattern as characters; without it they stay UTF-8 bytes and never match the decoded text, so only the `\x{…}` code points would be checked.

Watch it catch planted lines first, with `cp1252.md` listed before them, so a crash would hide them:
```bash
SCRATCH="$TMPDIR/tegel-m01"; mkdir -p "$SCRATCH"
scan() { perl -Mutf8 -MEncode -0777 -ne 'binmode STDOUT, ":utf8"; my $t = s/\A\xFF\xFE// ? decode("UTF-16LE", $_) : eval { decode("UTF-8", $_, Encode::FB_CROAK | Encode::LEAVE_SRC) } // decode("cp1252", $_); my $n = 0; for (split /\n/, $t) { $n++; print "$ARGV:$n: $_\n" if /[\x{FDFA}\x{FDFB}\x{06DD}\x{06DE}\x{06E9}\x{FD3E}\x{FD3F}]|بسم|قال رسول|سورة|آية/ }' "$@"; echo "exit=$?"; }
printf 'clean\nسورة\n' > "$SCRATCH/plant.md"
{ printf '\377\376'; printf 'clean\nآية\n' | iconv -f UTF-8 -t UTF-16LE; } > "$SCRATCH/plant16.md"
scan Fixtures/markdown/cp1252.md "$SCRATCH/plant.md" "$SCRATCH/plant16.md"
scan Fixtures/markdown/*.md Fixtures/generate.js
```
Expected:
- First call: exactly `…/plant.md:2: سورة` and `…/plant16.md:2: آية`, then `exit=0`. Remove `-Mutf8` from `scan` and repeat that call: only `exit=0`.
- Second call: no matched lines, then `exit=0` (about 3 s; `huge-50mb.md` is read whole).

Then read every Arabic, Persian and Urdu line by eye: only the sentences listed in Step 2 appear.

- [ ] **Step 6: Commit** `Fixtures .gitattributes .gitignore`: "test: add shared Markdown fixtures and the g0/huge generator"

---

### Task 3: `renderToHTML` (pure renderer)

**Files:**
- Create: `Renderer/package.json`, `Renderer/bun.lock` (written by `bun install`), `Renderer/src/markdown.js`
- Test: `Renderer/test/markdown.test.js`

**Interfaces:**
- Consumes: `Fixtures/markdown/hostile.md` (Task 2).
- Produces: `export function renderToHTML(markdown: string, opts: { mode: 'window'|'quicklook'|'print', baseHref?: string }): string`. It is pure, with no DOM.
  - `baseHref` is accepted and ignored in M01. Local images belong to plan 02 (P4).
  - Mermaid fence output: `<pre class="mermaid-src" data-mermaid="N" dir="ltr">escaped source</pre>`, with N counting from 0 within each call.

- [ ] **Step 1: Write `package.json` with exact pins and install**

```json
{
  "name": "tegel-renderer",
  "private": true,
  "type": "module",
  "dependencies": {
    "dompurify": "3.4.17",
    "highlight.js": "11.12.0",
    "markdown-it": "14.3.3",
    "mermaid": "11.17.2"
  }
}
```
Run: `cd Renderer && bun install --ignore-scripts && grep -c '"markdown-it@14.3.3"' bun.lock && bun audit; echo "exit=$?"`
Expected: the install completes, the grep prints `1`, then `No vulnerabilities found` and `exit=0`. `bun audit` asks the npm registry, so `make check` needs the network. This first install writes `bun.lock`, so it can't be `--frozen-lockfile`; every later install is (master Global constraints).

Watch the audit fail (S27) in a scratch copy, so the repo is never touched:
```bash
SCRATCH="$TMPDIR/tegel-m01"; mkdir -p "$SCRATCH"; rm -rf "$SCRATCH/audit-probe"
rsync -a --exclude node_modules Renderer/ "$SCRATCH/audit-probe/" && cd "$SCRATCH/audit-probe" && bun add --ignore-scripts dompurify@3.1.2 && bun audit; echo "exit=$?"
```
Expected: `dompurify` listed with at least one advisory (3.1.2 predates the 3.1.3 prototype-pollution fix) and `exit=1`.

markdown-it 15.0.3 and mermaid 12.2.0 also exist. The master pins majors 14 and 11, so this plan stays on them.

- [ ] **Step 2: Write the failing tests**

```js
// Renderer/test/markdown.test.js
import { test, expect } from 'bun:test';
import { renderToHTML } from '../src/markdown.js';
const r = (md) => renderToHTML(md, { mode: 'window' });
const FIX = import.meta.dir + '/../../Fixtures/markdown/';

test('top-level blocks get dir=auto, nested blocks inherit, code gets dir=ltr', () => {
  const html = r('# T\n\npara\n\n- a\n  1. b\n\n> q\n\n| h |\n|---|\n| c |\n\n```js\nx\n```\n\n    indented\n\ninline `c`\n');
  // A descendant with its own dir is skipped by its dir=auto ancestor, so li/p/th/td must carry none (CR-P1-2).
  const auto = [...html.matchAll(/<([a-z0-9]+)[^>]*\sdir="auto"/g)].map((m) => m[1]);
  expect(auto).toEqual(['h1', 'p', 'ul', 'blockquote', 'table', 'p']);
  const code = html.match(/<(pre|code)(\s[^>]*)?>/g);
  expect(code.length).toBe(5);                       // fence pre+code, indented pre+code, inline code
  for (const tag of code) expect(tag).toContain('dir="ltr"');
});

test('heading ids keep Arabic, Hebrew, Persian letters and marks; duplicates get -2, -3', () => {
  const md = ['مرحبا بالعالم', 'שלום עולם', 'Hello, World!', 'Intro', 'Intro', 'Intro', 'A', 'A 2', 'A', '!!!', 'سلام دنیا', 'مُقَدِّمَة']
    .map((h) => `# ${h}`).join('\n');
  const ids = [...r(md).matchAll(/<h1 [^>]*id="([^"]*)"/g)].map((m) => m[1]);
  expect(ids).toEqual(['مرحبا-بالعالم', 'שלום-עולם', 'hello-world', 'intro', 'intro-2', 'intro-3',
    'a', 'a-2', 'a-3', 'heading', 'سلام-دنیا', 'مُقَدِّمَة']);
});

test('slug state resets per call', () => {
  expect(r('# Intro')).toBe(r('# Intro'));
});

test('front matter renders as a collapsed, escaped details block', () => {
  const html = r('---\ntitle: "<script>x</script>"\ntags: [a, b]\n---\n# Body\n');
  expect(html.startsWith('<details class="frontmatter">')).toBe(true);
  expect(html).not.toMatch(/<details[^>]*\sopen/);
  expect(html).toContain('&lt;script&gt;');
  expect(html).not.toContain('<script>');
  expect(html).not.toContain('<hr');
  expect(html).toMatch(/<h1 [^>]*id="body"/);
});

test('a later thematic break is not front matter', () => {
  const html = r('# A\n\n---\n\ntext\n');
  expect(html).not.toContain('frontmatter');
  expect(html).toContain('<hr');
});

test('mermaid fences become numbered, escaped, unhighlighted source blocks', () => {
  const html = r('```mermaid\ngraph TD\n  A-->B["</pre><script>x</script>"]\n```\n\n```mermaid\nsequenceDiagram\n  A->>B: hi\n```\n');
  expect(html).toMatch(/<pre [^>]*class="mermaid-src"[^>]*data-mermaid="0"/);
  expect(html).toMatch(/<pre [^>]*class="mermaid-src"[^>]*data-mermaid="1"/);
  expect(html).toContain('A--&gt;B');
  expect(html).not.toContain('<script>');
  expect(html).not.toContain('hljs');
});

test('fenced code is highlighted; unknown languages stay escaped plain text', () => {
  expect(r('```swift\nlet x = 1\n```')).toContain('<span class="hljs-keyword">let</span>');
  const plain = r('```nosuchlang\n<b>x</b>\n```');
  expect(plain).toContain('&lt;b&gt;x&lt;/b&gt;');
  expect(plain).not.toContain('<b>');
});

test('markdown-it settings: linkify on, typographer off, raw HTML passed to the sanitiser', () => {
  expect(r('see www.example.com')).toContain('href="http://www.example.com"');
  expect(r('"quotes" -- (c)')).toContain('&quot;quotes&quot; -- (c)');
  expect(r('<kbd>x</kbd>')).toContain('<kbd>x</kbd>');
});

test('link syntax never yields javascript:, file: or non-image data: URLs', () => {
  const html = r('[a](javascript:alert(1)) [b](JAVASCRIPT:alert(1)) [c](file:///etc/passwd) ' +
    '![d](data:text/html;base64,PHNjcmlwdD4=) ![e](data:image/png;base64,iVBORw0KGgo=)');
  expect(html).not.toMatch(/(href|src)="\s*(javascript:|file:|data:text)/i);
  expect(html).toContain('src="data:image/png;base64,iVBORw0KGgo="');
});

test('heading text cannot inject attributes', () => {
  expect(r('# a" onmouseover="x')).not.toMatch(/<h1[^>]*\sonmouseover=/);
});

test('hostile.md renders to a string and keeps its sentinels', async () => {
  const html = r(await Bun.file(FIX + 'hostile.md').text());
  expect(html).toContain('SENTINEL-TOP');
  expect(html).toContain('SENTINEL-BOTTOM');
});

test('pathological structure renders quickly without throwing', () => {
  const t0 = performance.now();
  r('>'.repeat(10_000) + ' deep\n');
  r('- '.repeat(5_000) + 'x\n');
  r('a'.repeat(5_000_000));
  expect(performance.now() - t0).toBeLessThan(1500);
});
```

- [ ] **Step 3: Run the tests and watch them fail**

Run: `cd Renderer && bun test test/markdown.test.js`
Expected: FAIL with `Cannot find module '../src/markdown.js'`.

- [ ] **Step 4: Implement `renderToHTML` in `Renderer/src/markdown.js`**

**Setup.** Use one module-level `markdownit({ html: true, linkify: true, typographer: false, highlight })`. `highlight` calls `hljs.highlight(str, { language, ignoreIllegals: true }).value` from `highlight.js/lib/common` when `hljs.getLanguage(lang)` is truthy, and otherwise returns `''`, which makes markdown-it escape the code.

**Per-call state** lives in the markdown-it `env` (`md.render(body, env)`, with `env.slugs = new Set()` and `env.mermaid = 0`). The module keeps no globals.

**Front matter.** `/^---\r?\n([\s\S]*?)\r?\n---\r?\n?/` matches at offset 0 only. It is removed from the body and prepended as `<details class="frontmatter"><summary>Front matter</summary><pre dir="ltr"><code dir="ltr" class="language-yaml">…</code></pre></details>`, with the YAML highlighted, or escaped if hljs fails.

**Core rule after `inline`.**
- Every opening token at `level === 0` whose tag is in `p h1–h6 ul ol blockquote table dl` gets `dir="auto"`. Nested blocks (`li`, a `p` inside a list or blockquote, `th`, `td`, `dt`, `dd`) get no `dir`: HTML auto-direction skips descendants that carry their own `dir`, so a marked child would leave its container LTR (CR-P1-2). They inherit the container's direction.
- `code_inline` children get `dir="ltr"`.
- `heading_open` gets `id` from the slug of its inline children's `text` and `code_inline` content.

**Renderer rules.**
- `fence`, if `info.trim().split(/\s+/)[0] === 'mermaid'`, emits the mermaid `pre` with `md.utils.escapeHtml(content)` and `env.mermaid++`.
- Otherwise `fence` and `code_block` emit `<pre dir="ltr"><code dir="ltr" class="language-x">…</code></pre>`.

Slug algorithm. The tests pin its outputs, but not the uniqueness loop:
```js
function slug(text, used) {
  const base = text.trim().toLowerCase().replace(/[^\p{L}\p{M}\p{N}\s-]/gu, '').replace(/\s+/g, '-') || 'heading';
  let id = base, n = 1;
  while (used.has(id)) id = `${base}-${++n}`;
  used.add(id);
  return id;
}
```

- [ ] **Step 5: Run the tests and watch them pass**

Run: `cd Renderer && bun test test/markdown.test.js`
Expected: `12 pass`, `0 fail`.

- [ ] **Step 6: Commit** `Renderer/package.json Renderer/bun.lock Renderer/src/markdown.js Renderer/test/markdown.test.js`: "feat(renderer): pure renderToHTML with RTL dirs, stable bidi slugs, front matter and mermaid fences"

---

### Task 4: `TextFileLoader`

**Files:**
- Create: `Packages/TegelKit/Sources/TegelKit/TextFileLoader.swift`, `Packages/TegelKit/Tests/TegelKitTests/TestSupport.swift`
- Test: `Packages/TegelKit/Tests/TegelKitTests/TextFileLoaderTests.swift`

**Interfaces:**
- Consumes: the Task 2 fixtures.
- Produces (contract):
  - `public struct LoadedText: Sendable { public let text: String; public let encoding: String.Encoding; public let truncated: Bool; public let byteCount: Int }`
  - `public enum TextFileLoader { public static func load(_ url: URL, maxBytes: Int = 5_000_000) throws -> LoadedText }`
- `load` is synchronous and may block on slow storage, so callers run it off the main actor (Tasks 7 and 8). It opens with `open(path, O_RDONLY | O_NONBLOCK | O_CLOEXEC)`, so a FIFO can't block the open, then `fstat`s the descriptor and throws `TextFileLoaderError.notRegularFile` unless `S_ISREG` (K11). `byteCount` is `st_size`. A failed `open` throws `POSIXError` with `errno`.
- Produces (additions):
  - `public enum TextFileLoaderError: Error, Equatable { case notRegularFile }`.
  - `public static func decode(_ data: Data, maxBytes: Int = 5_000_000) -> LoadedText`, for `--benchmark`, which reads stdin.
  - `extension LoadedText { public var displayMarkdown: String }`: the text itself, or, when truncated, the banner `> **Large file:** showing the first <shown> of <total>.` and a blank line, followed by the text. Sizes come from `ByteCountFormatter` `.file`. The banner is English in M01; plan 02 localises it.
- Encoding report: `.utf8` (with or without a BOM), `.utf16LittleEndian` or `.utf16BigEndian` (BOM only), `.windowsCP1252`.
- Test helper: `func fixtureURL(_ name: String) -> URL`. It resolves `Fixtures/markdown/<name>` from `#filePath`, five directories up.

- [ ] **Step 1: Write the failing tests**

```swift
import XCTest
import os
@testable import TegelKit

final class TextFileLoaderTests: XCTestCase {
    func testPlainUTF8() {
        let t = TextFileLoader.decode(Data("# Hi\n".utf8))
        XCTAssertEqual(t.text, "# Hi\n"); XCTAssertEqual(t.encoding, .utf8)
        XCTAssertFalse(t.truncated); XCTAssertEqual(t.byteCount, 5)
    }
    func testUTF8BOMIsStripped() {
        let t = TextFileLoader.decode(Data([0xEF, 0xBB, 0xBF]) + Data("x".utf8))
        XCTAssertEqual(t.text, "x"); XCTAssertEqual(t.encoding, .utf8)
    }
    func testUTF16LEWithBOMFixture() throws {
        let t = try TextFileLoader.load(fixtureURL("utf16le-bom.md"))
        XCTAssertEqual(t.encoding, .utf16LittleEndian)
        XCTAssertTrue(t.text.hasPrefix("# UTF-16 مرحبا")); XCTAssertFalse(t.text.hasPrefix("\u{FEFF}"))
    }
    func testUTF16BEWithBOM() {
        let t = TextFileLoader.decode(Data([0xFE, 0xFF, 0x00, 0x41]))
        XCTAssertEqual(t.text, "A"); XCTAssertEqual(t.encoding, .utf16BigEndian)
    }
    func testWindows1252Fixture() throws {
        let t = try TextFileLoader.load(fixtureURL("cp1252.md"))
        XCTAssertEqual(t.encoding, .windowsCP1252)
        XCTAssertEqual(t.text, "# Café “quotes” € 5\n")
    }
    func testNULByteStillDecodesAsUTF8() {
        let t = TextFileLoader.decode(Data("a\u{0}b".utf8))
        XCTAssertEqual(t.text.unicodeScalars.count, 3); XCTAssertEqual(t.encoding, .utf8)
    }
    func testEmptyFile() throws {
        let t = try TextFileLoader.load(fixtureURL("empty.md"))
        XCTAssertEqual(t.text, ""); XCTAssertEqual(t.byteCount, 0); XCTAssertFalse(t.truncated)
        XCTAssertEqual(t.displayMarkdown, "")
    }
    func testTruncationNeverSplitsAMultibyteScalar() {
        let t = TextFileLoader.decode(Data("aعع".utf8), maxBytes: 4)        // 1 + 2 + 2 bytes; cut lands mid-scalar
        XCTAssertEqual(t.text, "aع"); XCTAssertEqual(t.encoding, .utf8)
        XCTAssertTrue(t.truncated); XCTAssertEqual(t.byteCount, 5)
    }
    func testUTF16TruncationKeepsWholeCodeUnits() {
        let t = TextFileLoader.decode(Data([0xFF, 0xFE, 0x61, 0x00, 0x62, 0x00]), maxBytes: 5)
        XCTAssertEqual(t.text, "a"); XCTAssertEqual(t.encoding, .utf16LittleEndian)
    }
    func testFiftyMegabyteFileLoadsTruncatedAndFast() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "tegel-50mb-\(UUID()).md")
        try Data(repeating: UInt8(ascii: "a"), count: 50_000_000).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let start = ContinuousClock.now
        let t = try TextFileLoader.load(url)
        XCTAssertLessThan(ContinuousClock.now - start, .milliseconds(500))     // Quick Look budget is 2 s in total
        XCTAssertTrue(t.truncated); XCTAssertEqual(t.byteCount, 50_000_000)
        XCTAssertLessThanOrEqual(t.text.utf8.count, 5_000_000)
        XCTAssertTrue(t.displayMarkdown.hasPrefix("> ")); XCTAssertTrue(t.displayMarkdown.hasSuffix(t.text))
    }
    func testMissingFileThrows() {
        XCTAssertThrowsError(try TextFileLoader.load(URL(fileURLWithPath: "/nonexistent/tegel.md")))
    }
    func testFIFOFailsFastInsteadOfBlocking() {                          // K11: a FIFO named trap.md must not hang Quick Look
        let path = FileManager.default.temporaryDirectory.appending(path: "tegel-fifo-\(UUID()).md").path
        XCTAssertEqual(mkfifo(path, 0o600), 0)
        defer { unlink(path) }
        let done = expectation(description: "load returned")
        let thrown = OSAllocatedUnfairLock<TextFileLoaderError?>(initialState: nil)
        DispatchQueue.global().async {
            do { _ = try TextFileLoader.load(URL(fileURLWithPath: path)) } catch { thrown.withLock { $0 = error as? TextFileLoaderError } }
            done.fulfill()
        }
        wait(for: [done], timeout: 1)                                    // a blocking open() never returns: the wait times out
        XCTAssertEqual(thrown.withLock { $0 }, .notRegularFile)
    }
}
```

- [ ] **Step 2: Run the tests and watch them fail**

Run: `swift test --package-path Packages/TegelKit --filter TextFileLoaderTests`
Expected: FAIL with `cannot find 'TextFileLoader' in scope`.

- [ ] **Step 3: Implement `TextFileLoader.swift`**

**`load`** opens the descriptor as in Interfaces (`O_NONBLOCK`, then `fstat` + `S_ISREG`, closing the descriptor before it throws). It wraps a regular file in `FileHandle(fileDescriptor:closeOnDealloc: true)`, reads at most `maxBytes` with `read(upToCount:)` from offset 0, and decodes that prefix with `byteCount = st_size`. It never maps or reads the whole 50 MB. `O_NONBLOCK` doesn't change reads from a regular file.

**Decode order:**
1. A UTF-8 BOM is stripped and the encoding is `.utf8`.
2. `FF FE` or `FE FF` selects UTF-16 LE or BE; the prefix is cut to an even length.
3. Strict UTF-8 via `String(data:encoding: .utf8)`. When truncated, first back off at most 3 trailing continuation bytes (`0b10xxxxxx`) and the lead byte they belong to.
4. `.windowsCP1252`.
5. A lossy `String(decoding:as: UTF8.self)`, reported as `.utf8`.

- [ ] **Step 4: Run the tests and watch them pass**

Run: `swift test --package-path Packages/TegelKit --filter TextFileLoaderTests`
Expected: `Executed 12 tests, with 0 failures` (on the build Mac, x86_64).

Then watch the FIFO guard fail: temporarily open with `FileHandle(forReadingFrom: url)` instead of the `O_NONBLOCK` descriptor and run `--filter testFIFOFailsFastInsteadOfBlocking`.
Expected: FAIL with `Exceeded timeout of 1 seconds` (the open blocks waiting for a writer). Revert; it passes.

- [ ] **Step 5: Commit** `Packages/TegelKit/Sources/TegelKit/TextFileLoader.swift Packages/TegelKit/Tests/TegelKitTests/TextFileLoaderTests.swift Packages/TegelKit/Tests/TegelKitTests/TestSupport.swift`: "feat(tegelkit): TextFileLoader with BOM/UTF-8/CP1252 detection, 5 MB truncation and FIFO refusal"

---

### Task 5: Renderer page, bundle and `RendererWebView`

**Files:**
- Create:
  - `Renderer/src/page.js`, `Renderer/src/sanitize.js`, `Renderer/src/index.html`;
  - `Renderer/src/css/base.css`, `paper.css`, `print.css`;
  - `Renderer/build.js`, `Renderer/test/page.test.js`, `Renderer/test/sanitize.test.js`.
- Create (generated, committed): `Packages/TegelKit/Sources/TegelKit/Resources/Renderer/` containing `index.html page.js mermaid.min.js base.css paper.css print.css`.
- Create: `Packages/TegelKit/Sources/TegelKit/RendererWebView.swift`.
- Modify: `Packages/TegelKit/Package.swift` (`.target(name: "TegelKit", resources: [.copy("Resources/Renderer")])`), `Packages/TegelKit/Tests/TegelKitTests/TestSupport.swift`.
- Test: `Packages/TegelKit/Tests/TegelKitTests/WebView/RendererWebViewTests.swift`, `HostileInputTests.swift`, `BeaconServer.swift`.
- Branch B only: `project.yml`, `Packages/TegelKit/TestHost/TestHostApp.swift`, `Makefile`.

**Interfaces:**
- Consumes: `renderToHTML` (Task 3), `RenderOptions`/`RenderResult` (Task 1), `TextFileLoader`/`fixtureURL` (Task 4).
- Produces (JS, contract):
  - `window.tegel.render(markdown: string, opts: { mode, theme: 'paper'|'ink'|'studio', baseHref?: string }): Promise<RenderResult>`.
  - It posts `webkit.messageHandlers.tegel.postMessage({ type: 'rendered', ms, headings: [{ level, text, id }], mermaidCount, errors })`.
  - `mermaidCount` is the number of `[data-mermaid]` blocks found. `errors` holds one message per diagram that failed.
  - `headings[].id` is the heading's id in the DOM, `user-content-<slug>`: the main sanitiser pass sets `SANITIZE_NAMED_PROPS` (Step 7, CR 4). An in-page `#<slug>` link scrolls to that heading.
- Produces (JS, `Renderer/src/sanitize.js`, contract §3.2):
  - `export const SANITIZE_CONFIG = { FORBID_TAGS: ['script','iframe','object','embed','form','base','meta','style'] }`, with no `RETURN_DOM_FRAGMENT`, so each caller picks its own return type. `style` is forbidden so a document can't restyle or hide the page (S10); app CSS and test styles are injected by the app, not the document.
  - `export function addHooks(purify, { fileImages = false } = {})` installs one `uponSanitizeAttribute` hook (K4):
    - a `data:` value other than `data:image/*` → `keepAttr = false`;
    - a `file:` value → `keepAttr = false`, always;
    - a `tegel-doc:` value → `forceKeepAttr = true` only when `fileImages` is set, the node is `IMG` and the attribute is `src` (DOMPurify's default URI allow-list would otherwise strip the unknown scheme); anywhere else `keepAttr = false`;
    - without `fileImages`, an `IMG` `src` that isn't `data:image/*` → `keepAttr = false`, relative and `http(s):` URLs included (plan 08's privacy tool, K15). With `fileImages`, an `http(s):` image passes the sanitiser and the CSP's `img-src` blocks it, which `HostileInputTests` proves.
  - Consumers: `page.js` here (with `{ fileImages: true }`; plan 02 owns the `tegel-doc:` scheme handler); plan 08's site tool calls `addHooks(DOMPurify)`; plan 07's KaTeX imports `SANITIZE_CONFIG`.
- Produces (Swift, contract): `@MainActor public final class RendererWebView { public let webView: WKWebView; public init(); public func render(_ markdown: String, options: RenderOptions) async throws -> RenderResult }`. `scroll(toHeading:)` comes from plan 02, with the outline.
- Produces (additions):
  - `public var timeout: Duration`, defaulting to `.seconds(10)`. It covers the page load plus the render.
  - `public enum RendererError: Error, Equatable { case timeout }`.
  - The network rule list (S7): `WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "tegel-no-network", encodedContentRuleList:)` with `[{"trigger":{"url-filter":"^https?:"},"action":{"type":"block"}},{"trigger":{"url-filter":"^wss?:"},"action":{"type":"block"}},{"trigger":{"url-filter":"^ftp:"},"action":{"type":"block"}}]`, compiled once per process and added to the user content controller before the first load.
  - For tests only: `internal var indexURL: URL` (a `var`, so `testFailedPageLoadThrowsWithinTheTimeout` can point it at a missing file) and `internal private(set) var blockedNavigations: Int`.
- Produces (build): `bun build.js` writes the resource folder; `bun build.js --check` exits 1 and lists differing files when the committed output ≠ a fresh build.
- Test helper: `@MainActor func js(_ r: RendererWebView, _ body: String) async throws -> Any?`, implemented as `try await r.webView.callAsyncJavaScript(body, contentWorld: .page)`.

- [ ] **Step 1: Write the failing page and sanitiser tests**

```js
// Renderer/test/page.test.js
import { test, expect } from 'bun:test';
const html = await Bun.file(import.meta.dir + '/../src/index.html').text();
test('index.html carries the exact contract CSP', () => {
  const csp = html.match(/<meta http-equiv="Content-Security-Policy" content="([^"]+)">/)?.[1];
  expect(csp).toBe("default-src 'none'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: tegel-doc:; font-src 'self'");
});
test('index.html has no inline script', () => {
  const tags = html.match(/<script[^>]*>/g) ?? [];
  expect(tags.length).toBeGreaterThan(0);
  for (const tag of tags) expect(tag).toContain('src=');
});
```

```js
// Renderer/test/sanitize.test.js
import { test, expect } from 'bun:test';
import { SANITIZE_CONFIG, addHooks } from '../src/sanitize.js';

// Stands in for DOMPurify's hook API; the real sanitiser runs in WebKit (HostileInputTests).
// Verdict: 'force' = kept past DOMPurify's URI allow-list, 'drop' = removed, 'default' = DOMPurify decides.
function hooked(opts) {
  const hooks = [];
  addHooks({ addHook: (name, fn) => hooks.push([name, fn]) }, opts);
  return (nodeName, attrName, attrValue) => {
    const data = { attrName, attrValue, keepAttr: true, forceKeepAttr: undefined };
    for (const [name, fn] of hooks) if (name === 'uponSanitizeAttribute') fn({ nodeName }, data);
    return data.forceKeepAttr ? 'force' : data.keepAttr ? 'default' : 'drop';
  };
}
const DOC = 'tegel-doc:///Users/u/notes/a.png';

test('SANITIZE_CONFIG forbids the contract tags and leaves the return type to the caller', () => {
  expect(SANITIZE_CONFIG.FORBID_TAGS).toEqual(['script', 'iframe', 'object', 'embed', 'form', 'base', 'meta', 'style']);
  expect(SANITIZE_CONFIG).not.toHaveProperty('RETURN_DOM_FRAGMENT');
});

test('the data: hook keeps data:image/* and drops every other data: URL', () => {
  const v = hooked();
  expect(v('IMG', 'src', 'data:image/png;base64,iVBORw0KGgo=')).toBe('default');
  expect(v('IMG', 'src', ' DATA:text/html;base64,PHNjcmlwdD4=')).toBe('drop');
  expect(v('A', 'href', 'data:application/pdf,x')).toBe('drop');
  expect(v('A', 'href', 'https://example.com/')).toBe('default');
});

test('tegel-doc: survives on img[src] only, and only with fileImages', () => {
  const on = hooked({ fileImages: true }), off = hooked();
  expect(on('IMG', 'src', DOC)).toBe('force');
  expect(on('A', 'href', DOC)).toBe('drop');
  expect(on('IMG', 'srcset', DOC)).toBe('drop');
  expect(off('IMG', 'src', DOC)).toBe('drop');
});

test('file: is dropped everywhere, with or without fileImages', () => {
  for (const v of [hooked(), hooked({ fileImages: true })]) {
    expect(v('IMG', 'src', 'file:///Users/u/notes/a.png')).toBe('drop');
    expect(v('A', 'href', ' FILE:///etc/passwd')).toBe('drop');
  }
});

test('without fileImages, img[src] keeps only data:image/* (plan 08 tool, K15)', () => {
  const off = hooked(), on = hooked({ fileImages: true });
  expect(off('IMG', 'src', 'a.png')).toBe('drop');                       // DOMPurify alone keeps relative URLs
  expect(off('IMG', 'src', '/a.png')).toBe('drop');
  expect(off('IMG', 'src', 'https://example.com/a.png')).toBe('drop');
  expect(off('IMG', 'src', 'data:image/png;base64,iVBORw0KGgo=')).toBe('default');
  expect(off('A', 'href', 'a.html')).toBe('default');
  expect(on('IMG', 'src', 'https://example.com/a.png')).toBe('default');  // the app: the CSP blocks it
});
```
Run: `cd Renderer && bun test test/page.test.js test/sanitize.test.js`
Expected: FAIL with `ENOENT … src/index.html` and `Cannot find module '../src/sanitize.js'`.

- [ ] **Step 2: Write `index.html` and the CSS, then run the test**

- **`index.html`:** the CSP meta, `<link rel="stylesheet" href="base.css">`, `paper.css`, `<link rel="stylesheet" href="print.css" media="print">`, `<main id="doc"></main>` and `<script src="page.js"></script>` at the end of the body.
- **`base.css`:** the bidi rules only, `[dir=auto] { unicode-bidi: plaintext }` and `pre, code { direction: ltr; unicode-bidi: isolate }`. No visual styling (Global Constraints, Design): `.mermaid-error` and `details.frontmatter` get theirs from plan 09 Task 6.
- **`paper.css`:** the empty selector `:root[data-theme="paper"] {}`, with no values. Plan 09 Task 6 fills it.
- **`print.css`:** `@page { size: A4; margin: 18mm }`; `pre, table, .mermaid { break-inside: avoid }`; `pre { white-space: pre-wrap }`.

Plan 09 Task 6 (Drop B) writes the theme CSS (paper, ink, studio and dark mode) from `DESIGN.md` §7. Tokens go under `:root[data-theme="<name>"]`, and dark values only under `@media screen and (prefers-color-scheme: dark) { :root[data-theme="<name>"]:not([data-mode="print"]) }`, so PDFs stay light. Plan 02 wires the theme picker.

Run: `cd Renderer && bun test test/page.test.js`
Expected: `2 pass`.

- [ ] **Step 3: Write `build.js`, build, and watch the freshness guard fail and recover**

- **Bundle:** `Bun.build({ entrypoints: ['src/page.js'], outdir, target: 'browser', format: 'iife', minify: true })`. `format: "iife"` is documented, experimental: https://bun.com/docs/bundler.
- **Copy:** `src/index.html` and `src/css/{base,paper,print}.css` (flat), plus `node_modules/mermaid/dist/mermaid.min.js` (3.57 MB per https://app.unpkg.com/mermaid@11.17.2/files/dist).
- **`--check`:** build into `fs.mkdtempSync(path.join(os.tmpdir(), 'tegel-'))` (`mkdtemp` appends six characters to its prefix, so a bare `os.tmpdir()` would make a sibling such as `/tmpXXXXXX`, which Linux CI can't create), compare file sets and bytes with the committed folder, print each differing name and `process.exit(1)` on any difference.

Package.swift: `.target(name: "TegelKit", resources: [.copy("Resources/Renderer")])`.

Run (`page.js` can be a stub that sets `window.tegel = {}` until Step 7):
`make renderer && ls Packages/TegelKit/Sources/TegelKit/Resources/Renderer && echo x >> Packages/TegelKit/Sources/TegelKit/Resources/Renderer/base.css && (cd Renderer && bun build.js --check); echo "exit=$?"; make renderer && (cd Renderer && bun build.js --check); echo "exit=$?"`
Expected:
- Six files listed.
- The first check prints `base.css` and `exit=1`.
- The second prints `exit=0`.

- [ ] **Step 4: Check that WKWebView works inside the `swift test` process**

Add to `RendererWebViewTests.swift`:
```swift
@MainActor func testWebKitRunsInsideSwiftTest() async throws {
    let config = WKWebViewConfiguration()
    config.preferences.inactiveSchedulingPolicy = .none      // default .suspend freezes windowless views
    let web = WKWebView(frame: CGRect(x: 0, y: 0, width: 400, height: 300), configuration: config)
    web.loadHTMLString("<p id=p>ok</p>", baseURL: nil)
    var text: String?
    let deadline = ContinuousClock.now + .seconds(5)
    while text == nil, ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(50))
        text = try? await web.callAsyncJavaScript("return document.getElementById('p')?.textContent ?? null", contentWorld: .page) as? String
    }
    XCTAssertEqual(text, "ok")
}
```
`inactiveSchedulingPolicy` is macOS 14+, with cases `none`, `suspend` and `throttle`; the default is `suspend`. Source: https://developer.apple.com/documentation/webkit/wkpreferences/inactiveschedulingpolicy-swift.property.

Run: `swift test --package-path Packages/TegelKit --filter testWebKitRunsInsideSwiftTest`
- **Branch A.** Expected `Executed 1 test, with 0 failures`. Keep every WebKit test under `swift test` and go to Step 5.
- **Branch B.** The test hangs, crashes, or reads `nil`, for example with `Could not connect to the window server` or a WebContent crash. Then do all of the following:
  1. Add `Packages/TegelKit/TestHost/TestHostApp.swift`: `@main struct TestHost: App { var body: some Scene { WindowGroup { EmptyView() } } }`.
  2. Add `exclude: ["WebView"]` to the SwiftPM test target.
  3. Create `project.yml` with the Task 7 header, plus two targets.
     - `TegelKitTestHost`: `type: application`, `platform: macOS`, `sources: [Packages/TegelKit/TestHost]`, a `TegelKit` package dependency, and `info.path: Packages/TegelKit/TestHost/Info.plist`.
     - `TegelKitHostTests`: `type: bundle.unit-test`, `sources: [Packages/TegelKit/Tests/TegelKitTests/WebView, Packages/TegelKit/Tests/TegelKitTests/TestSupport.swift]`, dependencies `[{target: TegelKitTestHost}, {package: TegelKit, product: TegelKit}]`, and `scheme: { testTargets: [TegelKitHostTests] }`.
     - XcodeGen sets `TEST_HOST` automatically "for unit tests that target an application": https://github.com/yonaskolb/XcodeGen/blob/2.46.0/Docs/ProjectSpec.md.
  4. Append to the Makefile's `test-swift` recipe: `$(XCODEGEN) generate && xcodebuild test -project Tegel.xcodeproj -scheme TegelKitHostTests -derivedDataPath build`.
  5. Re-run this probe there. Expected: `** TEST SUCCEEDED **`. Every later "Run: `swift test … --filter X`" in Tasks 5–6 becomes `xcodebuild test … -only-testing:TegelKitHostTests/<Class>/<test>`.
  6. Record the branch taken, with the error text, in the commit message.

- [ ] **Step 5: Write the failing RendererWebView tests**

```swift
@MainActor func testRenderPostsRenderedResultAndAppliesThemeAndMode() async throws {
    let r = RendererWebView()
    let res = try await r.render("# Hello\n\n## مرحبا\n\n# Hello\n", options: RenderOptions(mode: .quicklook))
    XCTAssertEqual(res.headings, [Heading(level: 1, text: "Hello", id: "user-content-hello"),      // DOM ids (CR 4)
                                  Heading(level: 2, text: "مرحبا", id: "user-content-مرحبا"),
                                  Heading(level: 1, text: "Hello", id: "user-content-hello-2")])
    XCTAssertEqual(res.mermaidCount, 0); XCTAssertEqual(res.errors, [])
    // An async call can't sit inside XCTAssert's autoclosure (CR-P1-1): bind each result first.
    let theme = try await js(r, "return document.documentElement.dataset.theme") as? String
    let mode = try await js(r, "return document.documentElement.dataset.mode") as? String
    let mermaidType = try await js(r, "return typeof window.mermaid") as? String
    XCTAssertEqual(theme, "paper"); XCTAssertEqual(mode, "quicklook")
    XCTAssertEqual(mermaidType, "undefined")                     // lazy: not loaded
}

@MainActor func testMixedBidiDirections() async throws {
    let r = RendererWebView()
    _ = try await r.render(try TextFileLoader.load(fixtureURL("mixed-bidi.md")).text, options: RenderOptions())
    let dirs = try await js(r, """
      const q = (s) => document.querySelector('#doc ' + s);
      const d = (el) => el.matches(':dir(rtl)') ? 'rtl' : 'ltr';
      return [d(q('h1')), d(q('p')), d(q('p code')), d(q('h2')), d(document.querySelectorAll('#doc p')[1]),
              d(q('ul')), d(q('li')), d(q('blockquote')), d(q('blockquote p')), d(q('table')), d(q('td')),
              d(q('pre')), d(q('pre code'))].join(',')
      """) as? String
    XCTAssertEqual(dirs, "rtl,rtl,ltr,rtl,ltr,rtl,rtl,rtl,rtl,rtl,rtl,ltr,ltr")
    // In an RTL table the first column sits on the right (CR-P1-2).
    let firstCellIsRight = try await js(r, """
      const [a, b] = document.querySelectorAll('#doc tbody td');
      return a.getBoundingClientRect().left > b.getBoundingClientRect().left
      """) as? Bool
    XCTAssertEqual(firstCellIsRight, true)
}

@MainActor func testMermaidBasicRendersTwoDiagrams() async throws {   // the fixture starts with `# mermaid` (S11)
    let r = RendererWebView()
    let res = try await r.render(try TextFileLoader.load(fixtureURL("mermaid-basic.md")).text, options: RenderOptions())
    XCTAssertEqual(res.mermaidCount, 2); XCTAssertEqual(res.errors, [])
    let svgs = try await js(r, "return document.querySelectorAll('#doc .mermaid svg').length") as? Int
    let mermaidType = try await js(r, "return typeof window.mermaid") as? String
    XCTAssertEqual(svgs, 2); XCTAssertEqual(mermaidType, "object")
}

@MainActor func testBrokenMermaidShowsOneErrorAndRendersTheRest() async throws {
    let r = RendererWebView()
    let res = try await r.render(try TextFileLoader.load(fixtureURL("mermaid-broken.md")).text, options: RenderOptions())
    XCTAssertEqual(res.mermaidCount, 3); XCTAssertEqual(res.errors.count, 1)
    let errorBoxes = try await js(r, "return document.querySelectorAll('#doc .mermaid-error').length") as? Int
    let svgs = try await js(r, "return document.querySelectorAll('#doc .mermaid svg').length") as? Int
    let after = try await js(r, "return document.body.innerText.includes('SENTINEL-AFTER-BROKEN')") as? Bool
    XCTAssertEqual(errorBoxes, 1); XCTAssertEqual(svgs, 2); XCTAssertEqual(after, true)
}

@MainActor func testThirtyDiagramsAndFiveHundredNodeGraphFinish() async throws {
    let thirty = (1...30).map { "```mermaid\ngraph LR\n  A\($0)-->B\($0)\n```" }.joined(separator: "\n\n")
    let big = "```mermaid\ngraph TD\n" + (0..<499).map { "  n\($0)-->n\($0 + 1)" }.joined(separator: "\n") + "\n```"
    let r = RendererWebView()
    let res = try await r.render(thirty + "\n\n" + big + "\n\nSENTINEL-END\n", options: RenderOptions())
    XCTAssertEqual(res.mermaidCount, 31)
    XCTAssertLessThanOrEqual(res.errors.count, 1)                 // 499 edges < maxEdges 500; an error box is also acceptable
    let end = try await js(r, "return document.body.innerText.includes('SENTINEL-END')") as? Bool
    XCTAssertEqual(end, true)
}

@MainActor func testTimeoutThrowsAndRendererStaysUsable() async throws {
    let r = RendererWebView()
    _ = try await r.render("warm", options: RenderOptions())
    r.timeout = .milliseconds(1)
    do { _ = try await r.render(try TextFileLoader.load(fixtureURL("mermaid-basic.md")).text, options: RenderOptions()); XCTFail("expected timeout") }
    catch RendererError.timeout {}
    r.timeout = .seconds(10)
    let again = try await r.render("# Again", options: RenderOptions())
    XCTAssertEqual(again.headings.map(\.id), ["user-content-again"])
}

@MainActor func testSecondRenderSupersedesFirst() async throws {
    let r = RendererWebView()
    let md = try TextFileLoader.load(fixtureURL("mermaid-basic.md")).text
    let first = Task { try await r.render(md, options: RenderOptions()) }
    await Task.yield()                                   // first is now pending (waiting for the page load)
    let s = try await r.render("# Second", options: RenderOptions())
    XCTAssertEqual(s.headings.map(\.id), ["user-content-second"])
    do { _ = try await first.value; XCTFail("expected cancellation") } catch is CancellationError {}
}

@MainActor func testFailedPageLoadThrowsWithinTheTimeout() async throws {
    let r = RendererWebView(); r.timeout = .seconds(1)
    r.indexURL = r.indexURL.deletingLastPathComponent().appending(path: "missing.html")   // the page load fails
    let thrown = expectation(description: "render threw")
    let task = Task { do { _ = try await r.render("# x", options: RenderOptions()) } catch { thrown.fulfill() } }
    await fulfillment(of: [thrown], timeout: 2)                 // a hang fails here instead of stalling the suite
    task.cancel()
}

@MainActor func testHeadingNamedLikeADocumentPropertyKeepsItsIdAndLinksJumpToIt() async throws {
    // C10: DOMPurify's SANITIZE_DOM alone drops id="title" ('title' in document); so do images, links, name, open, style.
    let r = RendererWebView()
    let filler = (1...150).map { "Filler \($0)" }.joined(separator: "\n\n")
    let res = try await r.render("[to title](#title)\n\n\(filler)\n\n# Title\n\n\(filler)\n", options: RenderOptions())
    XCTAssertEqual(res.headings.map(\.id), ["user-content-title"])
    _ = try await js(r, "document.querySelector('#doc a[href=\"#title\"]').click(); return 0")
    let top = try await js(r, "return document.getElementById('user-content-title').getBoundingClientRect().top") as? Double ?? -1
    XCTAssertTrue((0...40).contains(top), "top=\(top)")
    XCTAssertEqual(r.webView.url, r.indexURL)                   // scrolled in place, no navigation
}
```

Run: `swift test --package-path Packages/TegelKit --filter RendererWebViewTests`
Expected: FAIL to compile with `cannot find 'RendererWebView' in scope`.

- [ ] **Step 6: Write the hostile-input tests and the beacon**

`BeaconServer`: `final class BeaconServer: @unchecked Sendable { init(port: UInt16) throws; func start() async throws; var connectionCount: Int { get }; func stop() }`. It wraps an `NWListener` bound to `127.0.0.1:<port>` with `allowLocalEndpointReuse = true`, so consecutive tests can rebind 47123. It counts every accepted connection in an `OSAllocatedUnfairLock<Int>` and never replies. `start()` returns once the state is `.ready`.

```swift
@MainActor final class HostileInputTests: XCTestCase {
    func testBeaconServerCountsConnections() async throws {      // positive control: the beacon can see a request
        let beacon = try BeaconServer(port: 47124); try await beacon.start(); defer { beacon.stop() }
        var req = URLRequest(url: URL(string: "http://127.0.0.1:47124/ping")!); req.timeoutInterval = 1
        _ = try? await URLSession.shared.data(for: req)
        XCTAssertGreaterThanOrEqual(beacon.connectionCount, 1)
    }
    func testHostileFixtureRunsNoScriptAndMakesNoRequest() async throws {
        let beacon = try BeaconServer(port: 47123); try await beacon.start(); defer { beacon.stop() }
        let r = RendererWebView()
        _ = try await r.render("", options: RenderOptions())       // page loaded; install the CSP listener
        _ = try await js(r, "window.__csp = []; document.addEventListener('securitypolicyviolation', e => window.__csp.push(e.violatedDirective)); return 0")
        _ = try await r.render(try TextFileLoader.load(fixtureURL("hostile.md")).text, options: RenderOptions())
        try await Task.sleep(for: .milliseconds(500))
        let pwned = try await js(r, "return typeof window.__pwned") as? String
        XCTAssertEqual(pwned, "undefined")
        XCTAssertEqual(beacon.connectionCount, 0)
        XCTAssertEqual(r.webView.url, r.indexURL)
        let text = try await js(r, "return document.body.innerText") as? String ?? ""   // innerText skips display:none (S10)
        XCTAssertTrue(text.contains("SENTINEL-TOP")); XCTAssertTrue(text.contains("SENTINEL-BOTTOM"))
        let banned = try await js(r, "return document.querySelectorAll('#doc script,#doc iframe,#doc object,#doc embed,#doc form,#doc base,#doc meta,#doc link,#doc style:not(.mermaid style)').length") as? Int
        let handlers = try await js(r, "return [...document.querySelectorAll('#doc *')].filter(e => [...e.attributes].some(a => a.name.startsWith('on'))).length") as? Int
        let badURLs = try await js(r, #"return [...document.querySelectorAll('#doc [href],#doc [src]')].map(e => e.getAttribute('href') ?? e.getAttribute('src')).filter(u => /^\s*(javascript:|file:|data:(?!image\/))/i.test(u)).length"#) as? Int
        let htmlLabels = try await js(r, "return document.querySelectorAll('#doc .mermaid foreignObject').length") as? Int   // S8
        XCTAssertEqual(banned, 0); XCTAssertEqual(handlers, 0); XCTAssertEqual(badURLs, 0); XCTAssertEqual(htmlLabels, 0)
        let csp = try await js(r, "return window.__csp") as? [String] ?? []
        XCTAssertTrue(csp.contains { $0.hasPrefix("img-src") }, "CSP must be active and blocking: \(csp)")
    }
    func testClickingHostileLinksNeverNavigates() async throws {
        let beacon = try BeaconServer(port: 47123); try await beacon.start(); defer { beacon.stop() }
        let r = RendererWebView()
        _ = try await r.render(try TextFileLoader.load(fixtureURL("hostile.md")).text, options: RenderOptions())
        // Mermaid wraps node B's `click` in an SVG <a>, which has no .click(): dispatch the event instead.
        _ = try await js(r, "document.querySelectorAll('#doc a').forEach(a => a.dispatchEvent(new MouseEvent('click', {bubbles: true, cancelable: true}))); return 0")
        try await Task.sleep(for: .milliseconds(500))
        XCTAssertEqual(r.webView.url, r.indexURL)
        XCTAssertEqual(beacon.connectionCount, 0)
        XCTAssertGreaterThanOrEqual(r.blockedNavigations, 1)     // #http-link survives the sanitiser, so the guard must fire
    }
    func testLinkToTheRendererPageIsBlockedAndKeepsTheDocument() async throws {
        // `index.html` resolves to indexURL: a URL-only policy would allow it, reload the page and blank the document.
        let r = RendererWebView()
        _ = try await r.render("[home](index.html)\n\nSENTINEL-KEEP\n", options: RenderOptions())
        let before = r.blockedNavigations
        _ = try await js(r, "document.querySelector('#doc a').dispatchEvent(new MouseEvent('click', {bubbles: true, cancelable: true})); return 0")
        try await Task.sleep(for: .milliseconds(500))
        XCTAssertGreaterThan(r.blockedNavigations, before)
        let text = try await js(r, "return document.body.innerText") as? String ?? ""
        XCTAssertTrue(text.contains("SENTINEL-KEEP"))
    }
    func testDocumentStylesAreDroppedAndTableAlignmentStays() async throws {
        // The CSP allows inline styles, so a kept document `style` could cover or restyle the text.
        let r = RendererWebView()
        _ = try await r.render("<p style=\"position:fixed;inset:0\">cover</p>\n\n| n |\n|--:|\n| 1 |\n", options: RenderOptions())
        let styled = try await js(r, "return document.querySelector('#doc p').hasAttribute('style')") as? Bool
        let align = try await js(r, "return getComputedStyle(document.querySelector('#doc td')).textAlign") as? String
        XCTAssertEqual(styled, false); XCTAssertEqual(align, "right")
    }
    func testScriptFromAnotherFileURLNeverRuns() async throws {  // S6: a sanitiser bypass that injects <script src> next to the document
        let dir = FileManager.default.temporaryDirectory.appending(path: "tegel-s6-\(UUID())")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let evil = dir.appending(path: "evil.js")
        try Data("window.__pwned = 'file-script'".utf8).write(to: evil)
        let r = RendererWebView()
        _ = try await r.render("# probe", options: RenderOptions())
        let state = try await js(r, """
          window.__csp = []; document.addEventListener('securitypolicyviolation', e => window.__csp.push(e.violatedDirective));
          const s = document.createElement('script'); s.src = '\(evil.absoluteString)'; document.body.append(s);
          await new Promise(res => setTimeout(res, 500));
          return [typeof window.__pwned, window.__csp.some(d => d.startsWith('script-src'))].join(',')
          """) as? String
        // The CSP must be what stops it (a script-src violation), not only the WebContent read sandbox.
        XCTAssertEqual(state, "undefined,true")
    }
}
```

- [ ] **Step 7: Implement `sanitize.js`, `page.js` and `RendererWebView.swift`**

**`sanitize.js`** (plain ES module, no DOM access):
- `SANITIZE_CONFIG` exactly as in Interfaces. DOMPurify's defaults already drop `on*` handlers and `javascript:` and `file:` URLs; the hook drops `file:` again so no option can bring it back.
- `addHooks` installs the one `uponSanitizeAttribute` hook with the four rules in Interfaces. The hook trims `data.attrValue` and lower-cases it itself, and tests the scheme on that copy; the attribute keeps its original value. The tests pass raw values such as `' FILE:///etc/passwd'` and `' DATA:text/html…'`. `forceKeepAttr` is DOMPurify's documented way for a hook to keep an attribute its URI allow-list would drop.

Run: `cd Renderer && bun test test/sanitize.test.js`
Expected: `5 pass`, `0 fail`.

Watch the K15 rule fail: temporarily delete the no-`fileImages` `IMG` `src` rule and re-run. Expected: `4 pass`, `1 fail`, in `without fileImages, img[src] keeps only data:image/*`, where `off('IMG', 'src', 'a.png')` is `default`. Revert; `5 pass`.

**`page.js`** (bundled IIFE; imports `renderToHTML`, `dompurify` and `sanitize.js`):
- At load, call `addHooks(DOMPurify, { fileImages: true })` once. Hooks are global DOMPurify state, so they're never installed per render (they also run on the Mermaid SVG pass).
- At load, also add one `click` listener on `#doc` for `a[href^="#"]`. It calls `preventDefault()`, takes `frag = decodeURIComponent(href.slice(1))`, and runs `scrollIntoView()` on `document.getElementById('user-content-' + frag) ?? document.getElementById(frag)`. No navigation happens.
- `render` runs these steps:
  1. Set `<html data-theme data-mode>`.
  2. Sanitise with `DOMPurify.sanitize(renderToHTML(markdown, opts), { ...SANITIZE_CONFIG, SANITIZE_NAMED_PROPS: true, RETURN_DOM_FRAGMENT: true })`. In that fragment, remove every `style` attribute whose trimmed value doesn't match `/^text-align:\s*(left|right|center);?$/i` (markdown-it's table alignment is the only style the renderer emits; the CSP's `'unsafe-inline'` would let any other document style cover or restyle the text). Then call `#doc.replaceChildren(fragment)`. This filter is not a DOMPurify hook: hooks are global, and Mermaid's SVG pass (step 4) and plan 07's KaTeX pass need their generated inline styles. `SANITIZE_NAMED_PROPS` prefixes every `id` and `name` with `user-content-`. That keeps DOMPurify's clobbering protection, but a heading slugged `title`, `images`, `links`, `name`, `open` or `style` keeps its id: the default `SANITIZE_DOM` check alone deletes any id that exists on `document` or a form (C10, CR 4).
  3. `await new Promise(r => setTimeout(r, 0))`, so the text paints before Mermaid. Don't use `requestAnimationFrame`, which doesn't fire in windowless views.
  4. If `#doc pre[data-mermaid]` exists:
     - load Mermaid once through a module-scoped promise: inject `<script src="mermaid.min.js">`, and in its `load` handler take `globalThis.mermaid` once (the bundle's last line assigns it, so it shadows any `id="mermaid"` element) and keep it in that module variable. Every later call uses the module variable. **Never** test `window.mermaid` (or any page global) to decide whether to load: `# mermaid` would give a heading `id="mermaid"`, and named access would make that test pass with the heading (S11). The `user-content-` prefix (step 2) already prevents that; this rule is the second layer;
     - call `mermaid.initialize({ startOnLoad: false, securityLevel: 'strict', suppressErrorRendering: true, htmlLabels: false, secure: ['secure', 'securityLevel', 'startOnLoad', 'maxTextSize', 'suppressErrorRendering', 'maxEdges', 'htmlLabels'] })`. In Mermaid 11.17 the root `htmlLabels` overrides the deprecated per-diagram ones, so labels are SVG `<text>`, not `foreignObject` HTML. `secure` is Mermaid's six default keys plus `htmlLabels`, so a document's `%%{init: {"htmlLabels": true}}%%` can't turn HTML labels back on; the SVG pass would strip them and leave that diagram's labels blank;
     - for each block, `const { svg } = await mermaid.render('tegel-mermaid-' + n, pre.textContent)`. On success, replace the block with `div.mermaid` and fill it with `DOMPurify.sanitize(svg, { USE_PROFILES: { svg: true, svgFilters: true }, RETURN_DOM_FRAGMENT: true })` (S8). The svg profile drops `foreignObject` and every HTML element but keeps Mermaid's own `<style>`, whose rules Mermaid scopes to `#tegel-mermaid-<n>`; so this pass doesn't reuse `SANITIZE_CONFIG`, which forbids `style`. On failure, use `div.mermaid-error`, set its text with `textContent`, and push the message to `errors`.
  5. Collect headings from `#doc h1…h6`.
  6. Post the `rendered` message and return the same object.
- Mermaid reference: `securityLevel: 'strict'` and `maxEdges` default 500, per https://mermaid.js.org/config/schema-docs/config.html. Mermaid 11.17.2's `mermaid.min.js` bundles its own DOMPurify 3.4.12 (`grep -oE 'version="[0-9.]+",[A-Za-z_$]+\.removed=\[\]' Renderer/node_modules/mermaid/dist/mermaid.min.js` → `version="3.4.12",t.removed=[]`, checked on unpkg 27 Oct); our pass uses the pinned 3.4.17.
- Plan 09 Task 7 later adds `theme: 'base'` with `themeVariables` from the `--tg-*` tokens, the source in each `div.mermaid`'s `dataset.src`, and the redraw on an appearance change (master §3.2), through this same sanitised insertion. Plan 01 uses Mermaid's default theme.

**`RendererWebView`:**
- **`init`** builds a `WKWebViewConfiguration`:
  - `websiteDataStore = .nonPersistent()`;
  - `preferences.inactiveSchedulingPolicy = .none`;
  - a `"tegel"` script-message handler;
  - a navigation delegate. Both the handler and the delegate are one private `NSObject` proxy that holds the renderer `weak`.
- It uses a 1024×768 frame and starts with the page marked dirty, so it loads nothing yet. `indexURL` is `Bundle.module.url(forResource: "index", withExtension: "html", subdirectory: "Renderer")!`. Every load is `loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())`.
- **Network rule list (S7):** compiled once per process (a `@MainActor` static cached `Task`), from the JSON in Interfaces. Before the first load, `render` awaits it and calls `configuration.userContentController.add(list)`.
- **Navigation policy (master §3.2):**
  - `.cancel` and `blockedNavigations += 1` for every action whose `navigationType == .linkActivated`, whatever its URL. A relative `index.html`, `index.html#x` or `[x]()` link resolves to `indexURL`, so a URL check alone would let it reload the page and blank the document, in the window and in Quick Look.
  - Any other action is allowed only when its request URL, with the fragment dropped, equals `indexURL`, so only the renderer's own loads pass. Otherwise `.cancel` and `blockedNavigations += 1`.
  - Opening links is plan 02's (Task 6, the window only); this plan opens nothing.
- **`render` steps:**
  1. If a render is pending, resume it with `CancellationError()` and mark the page dirty. "Pending" includes still waiting for the page load. A timed-out render also marks the page dirty.
  2. Install a continuation tagged with a token and start the deadline: a `Task.sleep(for: timeout)` resumes it with `.timeout` if the token is still pending. Both happen before any preparation or loading, so a stalled rule-list compile or page load also ends at the deadline.
  3. If the page is dirty, install the rule list if it isn't installed yet, (re)load `indexURL` and wait for `didFinish`. `didFail` and `didFailProvisionalNavigation` for that load resume the token with their error, and the page stays dirty. A reload kills any in-flight JS, so a stale `rendered` can't be misattributed.
  4. Call `callAsyncJavaScript("await window.tegel.render(markdown, opts)", arguments: ["markdown": md, "opts": ["mode": …, "theme": …, "baseHref": …]], in: nil, in: .page)`. A JS error resumes with that error.
  5. Resume with the decoded `rendered` message body (`JSONSerialization` → `JSONDecoder`) only while that token is awaiting. Ignore every other message.

**`tegel-renderer://` fallback (S6).** Switch to it if Step 8 shows either:
- `page.js` never loads (a `script-src` violation on the `file:` page, so WebKit's `'self'` doesn't match `file:`); or
- `testScriptFromAnotherFileURLNeverRuns` fails (no `script-src` violation, so `'self'` on a `file:` page admits any `file:` URL and only the read sandbox stood in the way).

Then serve the renderer folder through a `WKURLSchemeHandler` registered for `tegel-renderer` and load `tegel-renderer://renderer/index.html`, which becomes `indexURL`. The handler serves only files whose standardised path lies inside the renderer folder (compared by `pathComponents`; anything else is a 404), with `text/html`, `text/javascript` or `text/css`. The CSP string and the contract stay the same; `'self'` now means the bundle only. Record which case triggered it in the commit. Re-run Step 8.

- [ ] **Step 8: Run the tests and watch them pass**

Run: `make renderer && swift test --package-path Packages/TegelKit --filter 'RendererWebViewTests|HostileInputTests'`
Expected: `Executed 16 tests, with 0 failures` (10 + 6).

- [ ] **Step 9: Watch every guard fail, one at a time, then restore it**

For each row: make the temporary edit, run `make renderer` if the edit touches `Renderer/src`, run `swift test --package-path Packages/TegelKit --filter <test>`, check the failure, then revert.

| # | Temporary edit | `--filter` | Expected failure |
|---|---|---|---|
| 1 | `sed -i '' '/Content-Security-Policy/d' Packages/TegelKit/Sources/TegelKit/Resources/Renderer/index.html` | `testHostileFixtureRunsNoScriptAndMakesNoRequest\|testScriptFromAnotherFileURLNeverRuns` | Both fail: "CSP must be active", and `undefined,false` (no `script-src` violation). `connectionCount` stays 0, because the rule list held (S7) |
| 2 | Row 1, plus comment out the rule-list `add` in `RendererWebView` | `testHostileFixtureRunsNoScriptAndMakesNoRequest` | `connectionCount` ≥ 1: the positive control for row 1 |
| 3 | The navigation policy returns `.allow` for everything | `testClickingHostileLinksNeverNavigates` | `webView.url` changed or the beacon was hit |
| 4 | In `page.js`, replace the main `DOMPurify.sanitize(…)` with `Object.assign(document.createElement('template'), { innerHTML: html }).content` (no sanitising, S9) | `testHostileFixtureRunsNoScriptAndMakesNoRequest` | `banned`, `handlers` or `badURLs` is non-zero |
| 5 | Remove `'style'` from `FORBID_TAGS` (S10) | `testHostileFixtureRunsNoScriptAndMakesNoRequest` | `SENTINEL-TOP` is missing from `innerText`: the document's `<style>` hid `#doc` |
| 6 | Insert Mermaid's SVG without the svg-profile pass **and** drop `htmlLabels: false` and `secure` (S8) | `testHostileFixtureRunsNoScriptAndMakesNoRequest` | `htmlLabels` (the `foreignObject` count) ≥ 1. Then restore only the svg-profile pass: it passes, so the pass alone strips them |
| 7 | In `page.js`, load Mermaid only `if (!window.mermaid)` **and** drop `SANITIZE_NAMED_PROPS` (S11) | `testMermaidBasicRendersTwoDiagrams` | The `# mermaid` heading answers the test, Mermaid never loads: the render throws or `svgs` is 0 |
| 8 | In `markdown.js`, also give `li`, `th`, `td` and nested `p` a `dir="auto"` (CR-P1-2) | `testMixedBidiDirections` | `ul`, `blockquote` and `table` read `ltr`, and `firstCellIsRight` is false |
| 9 | Drop `SANITIZE_NAMED_PROPS: true` from the main pass (C10) | `testHeadingNamedLikeADocumentPropertyKeepsItsIdAndLinksJumpToIt` | The heading ids are `[""]`: `SANITIZE_DOM` deleted `id="title"` |
| 10 | Remove the `#doc` `click` listener | `testHeadingNamedLikeADocumentPropertyKeepsItsIdAndLinksJumpToIt` | `top` is well over 40: the native jump looks for `id="title"`, which no longer exists |
| 11 | Drop the `.linkActivated` rule from the navigation policy (the `indexURL` check alone) | `testLinkToTheRendererPageIsBlockedAndKeepsTheDocument` | `blockedNavigations` is unchanged and `SENTINEL-KEEP` is gone: the link reloaded the page blank |
| 12 | Remove the main pass's `style` filter. Then, separately, make it remove every `style`, alignment included | `testDocumentStylesAreDroppedAndTableAlignmentStays` | First `styled` is `true`; then `align` is `start` |
| 13 | Start the deadline after `didFinish` again (the old order) and ignore `didFail`/`didFailProvisionalNavigation` | `testFailedPageLoadThrowsWithinTheTimeout` | `Asynchronous wait failed: Exceeded timeout of 2 seconds`: the render never returns |

After the last row: `make renderer`, re-run Step 8 (`Executed 16 tests, with 0 failures`), and `git status --short Renderer/src Packages/TegelKit/Sources/TegelKit/Resources` prints only this task's intended files.

- [ ] **Step 10: Run the full JS suite**

Run: `make test-js`
Expected: `bun audit` clean, `19 pass`, `0 fail` (12 markdown, 2 page, 5 sanitize), and `build.js --check` exits 0.

- [ ] **Step 11: Commit** `Renderer/src Renderer/build.js Renderer/test/page.test.js Renderer/test/sanitize.test.js Packages/TegelKit` (Branch B: also `project.yml Makefile`): "feat(tegelkit): sandboxed renderer page (CSP, DOMPurify, network rule list, sanitised strict Mermaid) and RendererWebView with nav block and timeout"

---

### Task 6: G0 performance test and the G0 record

**Files:**
- Create: `Packages/TegelKit/Tests/TegelKitTests/WebView/PerformanceTests.swift`, `docs/gates/G0.md`

**Interfaces:**
- Consumes: `RendererWebView`, `TextFileLoader`, and `g0-1mb.md` (generated by `make test-swift`).
- Produces: the `docs/gates/G0.md` skeleton that Tasks 7–13 append rows to.

- [ ] **Step 1: Write the test**

```swift
@MainActor final class PerformanceTests: XCTestCase {
    func testG0OneMegabyteRendersUnderOneSecondCold() async throws {
        var runs: [Double] = []
        for _ in 0..<3 {
            let start = ContinuousClock.now
            let r = RendererWebView()                                   // cold: new web view + page load each run
            let res = try await r.render(try TextFileLoader.load(fixtureURL("g0-1mb.md")).displayMarkdown, options: RenderOptions())
            let d = ContinuousClock.now - start
            runs.append(Double(d.components.seconds) * 1000 + Double(d.components.attoseconds) / 1e15)
            XCTAssertEqual(res.mermaidCount, 5); XCTAssertEqual(res.errors, [])
        }
        print("G0 swift-test ms=\(runs.map { Int($0) })")
        for ms in runs { XCTAssertLessThan(ms, 1000) }
    }
}
```

- [ ] **Step 2: Run it**

Run: `make test-swift 2>&1 | grep -E 'G0 swift-test|Executed'`
Expected on the build Mac: `G0 swift-test ms=[…]` and 0 failures.

If the test fails **only on the < 1000 ms assertion**, don't change the threshold. Record the numbers and continue. The test stays red until G0 is decided (Task 13), and the pipeline baseline notes it. While it is red, run `make -k check` wherever this plan says `make check`: plain `make` stops at the first failed prerequisite, so `test-shell` and `build` would never run.

- [ ] **Step 3: Create `docs/gates/G0.md`**

Give it these sections:
- **Rule:** BUSINESS-PLAN §12 G0, quoted.
- **Fixture:** `shasum -a 256 Fixtures/markdown/g0-1mb.md` and `wc -c`.
- **Method:** cold runs; the median of 5 for app and Quick Look; 3 for `swift test`.
- **Results table**, columns: `Machine | macOS | Arch | Evidence (local / run URL / lease) | swift test ms | --benchmark median ms | Window median ms | Quick Look median ms | QL blank or failed (of 5) | mermaidCount / Mermaid errors | Pass?`.
- **Quick Look variant**, filled by Task 9.
- **Decision**, filled by Task 13.

Fill the first row's `swift test` cell from Step 2 (`iMac19,1 · 15.7.7 · x86_64 · local`).

- [ ] **Step 4: Commit** `Packages/TegelKit/Tests/TegelKitTests/WebView/PerformanceTests.swift docs/gates/G0.md`: "test(g0): cold 1 MB render budget and G0 evidence record"

---

### Task 7: App 1 shell, `DocumentGroup(viewing:)` and `--benchmark`

**Files:**
- Create: `project.yml`, `Apps/Markdown/App/MarkdownApp.swift`, `Apps/Markdown/App/DocumentView.swift`
- Generated, gitignored: `Apps/Markdown/App/Info.plist`, `Apps/Markdown/App/Markdown.entitlements`

**Interfaces:**
- Consumes: `RendererWebView`, `RenderOptions`, `TextFileLoader.load` (window), `TextFileLoader.decode` (`--benchmark`), `LoadedText.displayMarkdown`.
- Produces:
  - `@main struct MarkdownApp: App`, containing `DocumentGroup(viewing: MarkdownFile.self) { DocumentView(file: $0.document, fileURL: $0.fileURL) }` and an `@NSApplicationDelegateAdaptor(AppDelegate.self)`.
  - `struct MarkdownFile: FileDocument`:
    - `static let readableContentTypes = [UTType(importedAs: "net.daringfireball.markdown")]`;
    - `init(configuration:)` stores only `let openedAt: ContinuousClock.Instant` and **never** touches `configuration.file.regularFileContents`, which would read the whole file however large (K11);
    - `fileWrapper` throws `CocoaError(.featureUnsupported)` (read-only, rule 1).
  - `struct DocumentView: View`, which hosts `renderer.webView` through `NSViewRepresentable`. In `.task` it runs `try await Task.detached { try TextFileLoader.load(fileURL) }.value` (an `fstat` size check, then at most 5 MB read, off the main actor), renders `displayMarkdown`, and logs `window ms=<n> bytes=<byteCount> truncated=<0|1> mermaid=<n> errors=<n>` (`errors.count`, since `mermaidCount` counts blocks found, not diagrams drawn) at `.notice` to `Logger(subsystem: Bundle.main.bundleIdentifier!, category: "g0")`. The time runs from `openedAt`. A load error shows its `localizedDescription` in place of the document.
  - `enum Benchmark { @MainActor static func run() async -> Int32 }`. CLI: `"Tegel Markdown" --benchmark < file.md`.
    - It prints exactly one JSON line `{"ms":<number>,"mermaidCount":<int>,"errors":<int>}` to stdout, where `errors` is `errors.count`. The line itself carries the Mermaid failures, because every pipe and loop below drops the exit code.
    - The time covers stdin decode, `RendererWebView()`, load and render.
    - Exit 0 on success; 2 if `errors` is non-empty; 1 on timeout. If stdin is a TTY it prints usage and exits 64.
    - stdin is used, not a path, because the sandboxed binary can't read an arbitrary path given on the command line.
  - `AppDelegate.applicationDidFinishLaunching` runs `Benchmark` when `CommandLine.arguments.contains("--benchmark")`, then `exit(code)`.

- [ ] **Step 1: Write the failing check**

Run:
```
APP="build/Build/Products/Debug/Tegel Markdown.app"
"$APP/Contents/MacOS/Tegel Markdown" --benchmark < Fixtures/markdown/g0-1mb.md | python3 -c 'import json,sys; d=json.loads(sys.stdin.readline()); assert set(d)=={"ms","mermaidCount","errors"} and d["mermaidCount"]==5 and d["errors"]==0, d; print("ms", d["ms"])'
```
Expected: FAIL with `no such file or directory`.

- [ ] **Step 2: Write `project.yml`**

```yaml
name: Tegel
options:
  bundleIdPrefix: com.tegelapps          # D7: bundle id = prefix + "." + target name
  deploymentTarget: { macOS: "14.0" }
configFiles: { Debug: Config/Debug.xcconfig, Release: Config/Release.xcconfig }
settings: { base: { SWIFT_VERSION: "6.0" } }
packages: { TegelKit: { path: Packages/TegelKit } }
targets:
  markdown:                              # → com.tegelapps.markdown
    type: application
    platform: macOS
    sources: [Apps/Markdown/App]
    dependencies: [{ package: TegelKit, product: TegelKit }]
    settings: { base: { PRODUCT_NAME: Tegel Markdown } }
    scheme: {}
    info:
      path: Apps/Markdown/App/Info.plist
      properties:
        CFBundleDisplayName: Tegel Markdown
        CFBundleShortVersionString: $(MARKETING_VERSION)
        CFBundleVersion: $(CURRENT_PROJECT_VERSION)
        LSApplicationCategoryType: public.app-category.developer-tools
        CFBundleDocumentTypes:
          - { CFBundleTypeName: Markdown document, CFBundleTypeRole: Viewer, LSHandlerRank: Alternate,
              LSItemContentTypes: [net.daringfireball.markdown] }
        UTImportedTypeDeclarations:
          - UTTypeIdentifier: net.daringfireball.markdown
            UTTypeDescription: Markdown document
            UTTypeConformsTo: [public.plain-text]
            UTTypeTagSpecification:
              public.filename-extension: [md, markdown, mdown, mkd, mkdn]
              public.mime-type: [text/markdown]
    entitlements:
      path: Apps/Markdown/App/Markdown.entitlements
      properties:
        com.apple.security.app-sandbox: true
        com.apple.security.files.user-selected.read-write: true
        com.apple.security.files.bookmarks.app-scope: true
        com.apple.security.network.client: true
        com.apple.security.temporary-exception.mach-lookup.global-name:   # Sparkle, wired in plan 03 [F4]
          - $(PRODUCT_BUNDLE_IDENTIFIER)-spks
          - $(PRODUCT_BUNDLE_IDENTIFIER)-spki
```
In Branch B, keep the Task 5 targets in the same file.

`LSHandlerRank: Alternate` means the app doesn't take over `.md` from the user's editor. The user picks it with "Open With".

- [ ] **Step 3: Implement `MarkdownApp.swift` and `DocumentView.swift`**

Signatures as in Interfaces. Render with `RenderOptions(mode: .window, theme: .paper, baseURL: fileURL)`. Per master §3.3, `baseURL` is the document's own file URL, not its folder; plan 02 turns it into the `tegel-doc:` `baseHref`, which M01 ignores.

- [ ] **Step 4: Build and verify the bundle**

Run:
```
make build
APP="build/Build/Products/Debug/Tegel Markdown.app"
xcodebuild -project Tegel.xcodeproj -scheme markdown -showBuildSettings | grep ' PRODUCT_BUNDLE_IDENTIFIER '
lipo -archs "$APP/Contents/MacOS/Tegel Markdown"
plutil -extract CFBundleDocumentTypes.0.CFBundleTypeRole raw "$APP/Contents/Info.plist"
plutil -extract UTImportedTypeDeclarations.0.UTTypeIdentifier raw "$APP/Contents/Info.plist"
codesign -d --entitlements - --xml "$APP" | plutil -convert json -o - - | python3 -c 'import json,sys; print(sorted(set(json.load(sys.stdin)) - {"com.apple.security.get-task-allow"}))'
find "$APP" -name TegelKit_TegelKit.bundle
```
Expected:
- `** BUILD SUCCEEDED **`.
- `PRODUCT_BUNDLE_IDENTIFIER = com.tegelapps.markdown`.
- `x86_64 arm64`, `Viewer`, `net.daringfireball.markdown`.
- `['com.apple.security.app-sandbox', 'com.apple.security.files.bookmarks.app-scope', 'com.apple.security.files.user-selected.read-write', 'com.apple.security.network.client', 'com.apple.security.temporary-exception.mach-lookup.global-name']`. Debug builds also carry `get-task-allow`, which the filter drops.
- One `Contents/Resources/TegelKit_TegelKit.bundle`.

- [ ] **Step 5: Run the Step 1 check again**

Expected: `ms <number>` and exit 0. Run it 5 times and put the median in the `--benchmark` cell of the iMac row in G0.md.

Then watch a diagram failure show up in the line: `APP="build/Build/Products/Debug/Tegel Markdown.app"; "$APP/Contents/MacOS/Tegel Markdown" --benchmark < Fixtures/markdown/mermaid-broken.md; echo "exit=$?"`.
Expected: `"mermaidCount":3,"errors":1` in the JSON line, then `exit=2`.

- [ ] **Step 6: Check the window path by hand on the build Mac**

Run: `SCRATCH="$TMPDIR/tegel-m01"; mkdir -p "$SCRATCH"; APP="build/Build/Products/Debug/Tegel Markdown.app"; open -a "$PWD/$APP" Fixtures/markdown/mixed-bidi.md`, then screenshot with `screencapture -x "$SCRATCH/win-bidi.png"` and read the image.
Expected: the Arabic blocks are right-aligned, the English paragraph after the Hebrew heading is left-aligned, and the code is LTR.

Then, 5 times: `APP="build/Build/Products/Debug/Tegel Markdown.app"; open -a "$PWD/$APP" Fixtures/markdown/g0-1mb.md`, then `osascript -e 'quit app "Tegel Markdown"'`. Read the timings with `/usr/bin/log show --last 5m --style compact --predicate 'subsystem BEGINSWITH "com.tegelapps.markdown" AND category == "g0"' | grep 'window ms='`. Always call `/usr/bin/log` by its path: in zsh, the session shell and the remote Mac's login shell, a bare `log` is a builtin that fails with `log: too many arguments`.
Expected: 5 lines, each with `mermaid=5 errors=0`. Put the median in the Window cell of the iMac row.

Then the 2 GB file (K11). Run:
```
SCRATCH="$TMPDIR/tegel-m01"; mkdir -p "$SCRATCH"; APP="build/Build/Products/Debug/Tegel Markdown.app"
cp Fixtures/markdown/huge-50mb.md "$SCRATCH/huge-2gb.md"
python3 -c 'import os,sys; os.truncate(sys.argv[1], 2_000_000_000)' "$SCRATCH/huge-2gb.md"   # sparse: no 2 GB on disk
open -a "$PWD/$APP" "$SCRATCH/huge-2gb.md"; sleep 5
ps -o rss= -p "$(pgrep -x 'Tegel Markdown')"
screencapture -x "$SCRATCH/win-2gb.png"; osascript -e 'quit app "Tegel Markdown"'
/usr/bin/log show --last 2m --style compact --predicate 'subsystem BEGINSWITH "com.tegelapps.markdown" AND category == "g0"' | grep 'window ms=' | tail -1
```
Expected: RSS below `400000` (KB), the screenshot shows the `Large file` banner, and the log line has `bytes=2000000000 truncated=1`.

Watch it fail: temporarily add `_ = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self)` to `MarkdownFile.init`, rebuild and repeat. A bare `regularFileContents` isn't enough: `FileWrapper` memory-maps the file, and on the build Mac reading it from a 2 GB sparse file left RSS at about 4 MB, while decoding it took RSS to about 3.9 GB. Expected: RSS above `2000000`, or the app is killed. Revert. If RSS is high **without** that line, SwiftUI reads the whole file itself: record it in G0.md and switch the window to an `NSDocument` subclass whose `read(from url:ofType:)` calls `TextFileLoader.load(url)`, then repeat.

- [ ] **Step 7: Commit** `project.yml Apps/Markdown/App/MarkdownApp.swift Apps/Markdown/App/DocumentView.swift docs/gates/G0.md`: "feat(app1): sandboxed DocumentGroup viewer with imported Markdown UTType, bounded file load and --benchmark"

---

### Task 8: Quick Look preview extension (view-based)

**Files:**
- Modify: `project.yml`
- Create: `Apps/Markdown/QuickLook/PreviewViewController.swift`
- Generated, gitignored: `Apps/Markdown/QuickLook/Info.plist`, `MarkdownQuickLook.entitlements`

**Interfaces:**
- Consumes: `RendererWebView` (with `timeout`), `TextFileLoader.load` (default `maxBytes` 5_000_000), `LoadedText.displayMarkdown`.
- Produces: `final class PreviewViewController: NSViewController, QLPreviewingController`.
  - `loadView()` sets `view = renderer.webView` and `preferredContentSize = NSSize(width: 820, height: 900)`.
  - Implement `func preparePreviewOfFile(at url: URL) async throws`, Swift's async import of the documented `preparePreviewOfFile(at:completionHandler:)` (https://developer.apple.com/documentation/quicklookui/qlpreviewingcontroller). If the compiler rejects the async form, implement the completion-handler form.
  - **One 1.8 s deadline covers the whole preview, load included (K11).** It starts on entry. The load runs in `Task.detached { try TextFileLoader.load(url) }` (5 MB cap, `fstat` first) and is raced against the deadline through a `withCheckedThrowingContinuation` that resumes once (an `OSAllocatedUnfairLock<Bool>` flag). A task group won't do, because it waits for a child stuck in `read`. If the deadline wins, it throws `CocoaError(.fileReadUnknown)` and leaves the detached task to finish on its own.
  - Then `renderer.timeout` is the remaining budget, and it renders with `mode: .quicklook` and `baseURL: nil`. On `RendererError.timeout` it still returns normally and shows whatever has rendered. Other errors propagate.
  - An `OSSignposter` interval `"preview"` wraps the work. One `.notice` line goes out, via `Logger(subsystem: Bundle.main.bundleIdentifier!, category: "quicklook")`: `preview ms=<n> bytes=<byteCount> truncated=<0|1> mermaid=<n|-1> errors=<n|-1> timedOut=<0|1>` on success, or `preview failed ms=<n> error=<String(describing: error)>` before an error propagates. `ms` runs from entry, so it includes the load. The `error` string is interpolated with `privacy: .public`: `os.Logger` shows an interpolated string as `<private>` by default (numbers are public), and Step 7 has to read it. Never log the file's URL.

- [ ] **Step 1: Write the failing check**

Run: `pluginkit -m -v -p com.apple.quicklook.preview | grep -c com.tegelapps.markdown.quicklook`
Expected: `0`.

- [ ] **Step 2: Add the target to `project.yml`**

```yaml
  markdown.quicklook:                    # → com.tegelapps.markdown.quicklook
    type: app-extension
    platform: macOS
    sources: [Apps/Markdown/QuickLook]
    dependencies: [{ package: TegelKit, product: TegelKit }]
    settings: { base: { PRODUCT_NAME: MarkdownQuickLook } }
    info:
      path: Apps/Markdown/QuickLook/Info.plist
      properties:
        CFBundleDisplayName: Tegel Markdown Preview
        CFBundleShortVersionString: $(MARKETING_VERSION)
        CFBundleVersion: $(CURRENT_PROJECT_VERSION)
        NSExtension:
          NSExtensionPointIdentifier: com.apple.quicklook.preview
          NSExtensionPrincipalClass: $(PRODUCT_MODULE_NAME).PreviewViewController
          NSExtensionAttributes:
            QLSupportedContentTypes: [net.daringfireball.markdown]
            QLSupportsSearchableItems: false
    entitlements:
      path: Apps/Markdown/QuickLook/MarkdownQuickLook.entitlements
      properties:
        com.apple.security.app-sandbox: true
        com.apple.security.network.client: true   # WKWebView in a sandbox [F5]
```
No `/` read exception (K4): Quick Look renders with `baseURL: nil` and shows no local images, so the extension needs no file access beyond the previewed file Quick Look hands it.
Also add `- target: markdown.quicklook` to the `markdown` target's `dependencies`. XcodeGen embeds it into `Contents/PlugIns`.

- [ ] **Step 3: Implement `PreviewViewController.swift`**

Signature and behaviour as in Interfaces.

- [ ] **Step 4: Build, install and register**

Run:
```
make build
APP="build/Build/Products/Debug/Tegel Markdown.app"; EXT="$APP/Contents/PlugIns/MarkdownQuickLook.appex"
codesign -d --entitlements - --xml "$EXT" | plutil -convert json -o - - | python3 -c 'import json,sys; print(sorted(set(json.load(sys.stdin)) - {"com.apple.security.get-task-allow"}))'
find "$APP" -name TegelKit_TegelKit.bundle | wc -l
ditto "$APP" ~/Applications/"Tegel Markdown.app"
LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
"$LSREG" -u "$APP"; "$LSREG" -f -R ~/Applications/"Tegel Markdown.app"
pluginkit -e use -i com.tegelapps.markdown.quicklook
pluginkit -m -v -p com.apple.quicklook.preview | grep com.tegelapps.markdown.quicklook
qlmanage -r && qlmanage -r cache
printf 'import UniformTypeIdentifiers\nprint(UTType(filenameExtension: "md")!.identifier)\n' | swift -
```
Expected:
- `['com.apple.security.app-sandbox', 'com.apple.security.network.client']`, and `2` resource bundles (app and appex).
- One pluginkit line with `+` (enabled) and the `~/Applications` path.
- `net.daringfireball.markdown`.

If the ad-hoc-signed extension is **not** listed, record the output. Then re-sign Debug with an `Apple Development` identity of the studio's team: `CODE_SIGN_IDENTITY = Apple Development` and `DEVELOPMENT_TEAM = 23N7947PKX` in a gitignored `Config/Local.xcconfig`. The Keychain's existing `Apple Development: Hamza Bouzaggou (W3Q9G8NSHG)` belongs to Stichting Tarbiyah Consultancy (team `72PF8SBQR6`) and is never used (CLAUDE.md "Accounts"). The studio's `Apple Development: Created via API (6KX9955LTJ)` (team `23N7947PKX`, valid to 27 Oct 2027) is already in the Keychain; only if it is gone, create one at developer.apple.com → Certificates with the CSR flow of plan 03 Task 3 (free, part of the membership), signed in as `marketing@snelverhuizen.nl`. The xcconfig is included by `#include? "Local.xcconfig"` as the **last** line of `Debug.xcconfig` (later lines win, so an include at the top would be overridden by `CODE_SIGN_IDENTITY = -`). Then repeat this step; after its build, `codesign -dv` on the app and on the appex must both print `TeamIdentifier=23N7947PKX`.

- [ ] **Step 5: Run the manual previews and screenshots (build Mac, macOS 15.7.7, x86_64)**

For each of `mermaid-basic.md`, `mixed-bidi.md`, `hostile.md` and `rtl-arabic.md`, run `SCRATCH="$TMPDIR/tegel-m01"; mkdir -p "$SCRATCH"; qlmanage -p Fixtures/markdown/<f> >/dev/null 2>&1 & QL=$!; sleep 3; screencapture -x "$SCRATCH/ql-<f>.png"; kill $QL`, then read each PNG.
Expected:
- Diagrams are drawn.
- RTL is correct.
- `hostile.md` shows both sentinels, with no alert and no blank page. Its second diagram (the `init` directive asking for HTML labels) still shows the word `label` (`secure`, Task 5 Step 7).

- [ ] **Step 6: Time Quick Look for G0 (5 cold previews)**

Repeat 5 times: `qlmanage -p Fixtures/markdown/g0-1mb.md` (background), wait 3 s, kill. Then:
`/usr/bin/log show --last 10m --style compact --predicate 'subsystem BEGINSWITH "com.tegelapps.markdown" AND category == "quicklook"' | grep 'preview ms='`
Expected: 5 lines with `mermaid=5 errors=0 timedOut=0`. Put the median and the blank/failed count in the iMac row of G0.md.

- [ ] **Step 7: Check the 2 s deadline, the 5 MB truncation and a FIFO (K11)**

Run `qlmanage -p Fixtures/markdown/huge-50mb.md` (background), wait 3 s, take a screenshot, kill. Then repeat the Step 6 `log show`.
Expected:
- The log line has `bytes=50…` and `truncated=1`, with `ms` < 2000. `ms` includes the load.
- The screenshot shows the `Large file` banner.

Then a FIFO named like a document:
```
SCRATCH="$TMPDIR/tegel-m01"; mkdir -p "$SCRATCH"; rm -f "$SCRATCH/trap.md"; mkfifo "$SCRATCH/trap.md"
qlmanage -p "$SCRATCH/trap.md" >/dev/null 2>&1 & QL=$!; sleep 3; kill $QL
/usr/bin/log show --last 1m --style compact --predicate 'subsystem BEGINSWITH "com.tegelapps.markdown" AND category == "quicklook"' | grep 'preview failed'
```
Expected: one line with `error=notRegularFile` and `ms` < 100. `error=<private>` means the `privacy: .public` is missing.

Watch the deadline fire on the load: temporarily start the load with `try await Task.sleep(for: .seconds(5))` inside the detached task, rebuild, re-register, and preview `mermaid-basic.md`. Expected: `preview failed ms=18…` (about 1800) with `Code=256` (`fileReadUnknown`) in the error, and Quick Look falls back to its generic preview instead of hanging. Revert.

- [ ] **Step 8: Commit** `project.yml Apps/Markdown/QuickLook/PreviewViewController.swift docs/gates/G0.md`: "feat(quicklook): view-based Markdown preview on RendererWebView with 5 MB cap, a 1.8 s deadline over load and render, and signposts"

---

### Task 9: Spike — data-based Quick Look (`QLIsDataBasedPreview`)

The question [F5]: does JS (and so Mermaid) run in a data-based HTML preview, and which variant do we ship? The spike code lives on `spike/ql-data` and is **not merged**. Only the finding lands, in `docs/gates/G0.md`.

**Files:**
- On `spike/ql-data` only: `Apps/Markdown/QuickLook/PreviewProvider.swift` and `project.yml`.
- On `m01-g0-renderer`: modify `docs/gates/G0.md`.

**Interfaces:**
- Consumes: Task 8's target.
- Uses the verified API https://developer.apple.com/documentation/quicklookui/qlpreviewreply:
  - `final class PreviewProvider: QLPreviewProvider, QLPreviewingController`;
  - `func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply`;
  - which returns `QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 820, height: 900)) { _ in Data(html.utf8) }`;
  - with resources added through `reply.attachments["name"] = QLPreviewReplyAttachment(data:contentType:)` and referenced as `cid:name`.
- Produces: the "Quick Look variant" section of G0.md.

- [ ] **Step 1: Branch and switch the extension to data-based**

Run: `git checkout -b spike/ql-data`. In `project.yml`, set `NSExtensionAttributes.QLIsDataBasedPreview: true` and `NSExtensionPrincipalClass: $(PRODUCT_MODULE_NAME).PreviewProvider`.

- [ ] **Step 2: Probe whether JS runs**

The reply HTML is `<p id="s">JS: no</p><script>document.getElementById('s').textContent='JS: inline yes'</script><script src="cid:probe.js"></script>`. `probe.js` is an attachment that appends ` + cid yes`. The probe HTML has no CSP; it is a probe only.

Run: `make build`, re-register as in Task 8 Step 4, then `qlmanage -p Fixtures/markdown/mermaid-basic.md` and take a screenshot.
Expected: one of `JS: no`, `JS: inline yes`, or `JS: inline yes + cid yes`. Record which, and the macOS version.

- [ ] **Step 3: Only if JS runs, probe Mermaid**

Attach `mermaid.min.js` as `cid:mermaid.min.js`, plus an inline `mermaid.render` of one `graph TD`. Take a screenshot. Record whether an SVG appears.

- [ ] **Step 4: Only if view-based failed G0 anywhere (Tasks 8 and 12)**

Try a snapshot variant. Inside `providePreview`, render with an off-screen `RendererWebView`. Return `document.documentElement.outerHTML`, with the CSS inlined and the `<script>` tags removed, as HTML data. Time 5 runs with the Task 8 log line and record them.

- [ ] **Step 5: Record and choose**

Add to G0.md: the probe results (macOS 15.7.7 Intel; macOS 27 too if Task 12 ran the spike build) and the snapshot timings, if any. Then apply this rule:
- **Ship view-based** if it passed G0 on 15 and 27.
- Otherwise ship data-based **only if** it runs Mermaid (natively or by snapshot) inside the budget.
- Otherwise the G0 kill branch applies (Task 13).

Then: `git checkout m01-g0-renderer`. The spike branch stays local; delete it after Task 13.

- [ ] **Step 6: Commit (on `m01-g0-renderer`)** `docs/gates/G0.md`: "docs(g0): record data-based vs view-based Quick Look spike result"

---

### Task 10: CI workflow

**Files:**
- Create: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: Make targets `test-js`, `test-swift`, `build`; `--benchmark`; `scripts/check-guards.sh` (Task 1).
- Produces:
  - job `js`, on every push (Linux);
  - job `macos`, a matrix of `macos-15` and `macos-26` (both arm64 [F7]) on `workflow_dispatch` only. Plan 03 adds tags.
  - The benchmark JSON goes to the run summary.
- K13:
  - Every `uses:` is pinned to a full commit SHA, with the tag in a comment. `check-guards.sh` fails `make check` on an unpinned one.
  - Every macOS job runs `sudo xcode-select -s "$XCODE"` with `XCODE: /Applications/Xcode_26.3.app`, the build Mac's Xcode. Both images have it (runner-images READMEs, checked 27 Oct); the default is newer on `macos-26`.
  - xcodegen 2.46.0 comes from its release zip, checked against its sha256 (equal to the digest GitHub lists for the asset, 27 Oct). No `brew install`.
  - `ci.yml` lands on `main` first, in its own reviewed commit. GitHub only dispatches a workflow that exists on the default branch.

| Action | Tag | Commit SHA (resolved 27 Oct via the GitHub API) |
|---|---|---|
| `actions/checkout` | v7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
| `oven-sh/setup-bun` | v2.2.0 | `0c5077e51419868618aeaa5fe8019c62421857d6` |

- [ ] **Step 1: Write the workflow and check the pins**

```yaml
name: ci
on: { push: {}, workflow_dispatch: {} }
permissions: { contents: read }
jobs:
  js:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1    # v7.0.1
      - uses: oven-sh/setup-bun@0c5077e51419868618aeaa5fe8019c62421857d6   # v2.2.0
        with: { bun-version: 1.4.0 }
      - run: make test-js                  # bun install --frozen-lockfile --ignore-scripts, bun audit, bun test, build.js --check
  macos:
    if: github.event_name == 'workflow_dispatch'
    strategy: { fail-fast: false, matrix: { os: [macos-15, macos-26] } }
    runs-on: ${{ matrix.os }}
    timeout-minutes: 45
    env:
      OS_LABEL: "${{ matrix.os }}"
      XCODE: /Applications/Xcode_26.3.app
      XCODEGEN_URL: https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip
      XCODEGEN_SHA256: 4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1    # v7.0.1
      - uses: oven-sh/setup-bun@0c5077e51419868618aeaa5fe8019c62421857d6   # v2.2.0
        with: { bun-version: 1.4.0 }
      - run: sudo xcode-select -s "$XCODE"
      - name: xcodegen 2.46.0, sha256-pinned
        run: |
          curl -fsSL -o "$RUNNER_TEMP/xcodegen.zip" "$XCODEGEN_URL"
          echo "$XCODEGEN_SHA256  $RUNNER_TEMP/xcodegen.zip" | shasum -a 256 -c -
          unzip -q "$RUNNER_TEMP/xcodegen.zip" -d "$RUNNER_TEMP"
          echo "$RUNNER_TEMP/xcodegen/bin" >> "$GITHUB_PATH"
      - run: sw_vers && uname -m && xcodebuild -version && xcodegen --version
      - run: make test-swift              # red while the G0 perf test is (Task 6); the job then fails, after the steps below
      - run: make build
        if: ${{ !cancelled() }}
      - name: G0 benchmark (5 cold runs)
        if: ${{ !cancelled() }}
        run: |
          BIN="build/Build/Products/Debug/Tegel Markdown.app/Contents/MacOS/Tegel Markdown"
          for i in 1 2 3 4 5; do "$BIN" --benchmark < Fixtures/markdown/g0-1mb.md; done | tee bench.jsonl
          { echo "### $OS_LABEL · $(sw_vers -productVersion) · $(uname -m)"; echo '```'; cat bench.jsonl; echo '```'; } >> "$GITHUB_STEP_SUMMARY"
```

Run:
```
make test-shell
for r in actions/checkout@v7.0.1 oven-sh/setup-bun@v2.2.0; do curl -s "https://api.github.com/repos/${r%@*}/commits/${r#*@}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["sha"])'; done
T=$(mktemp -d); curl -fsSL -o "$T/xcodegen.zip" https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip
echo "4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806  $T/xcodegen.zip" | shasum -a 256 -c -; echo "exit=$?"
echo "0000000000000000000000000000000000000000000000000000000000000000  $T/xcodegen.zip" | shasum -a 256 -c -; echo "exit=$?"
```
Expected:
- `env_test: PASS` and exit 0: the guard accepts the workflow. Task 1 Step 8 already watched it fail on an unpinned `uses:`.
- The two SHAs in the table.
- The workflow's checksum line, run locally: `…/xcodegen.zip: OK`, `exit=0`; then, with a wrong digest, `…/xcodegen.zip: FAILED` and `exit=1`, so a swapped zip stops the job before `unzip`.

- [ ] **Step 2: Land `ci.yml` on `main` first, reviewed**

Run:
```
git switch main && git pull --ff-only          # the untracked ci.yml comes along
git add .github/workflows/ci.yml
git commit -m "ci: js job on push, on-demand macOS 15/26 matrix with G0 benchmark [skip ci]" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
`[skip ci]` stops the push run on `main`, which has no Makefile until the m01 merge. It applies only to this commit's own push, so later pushes still run.

Before pushing, a cold code-review subagent reviews `git show HEAD` for: SHAs equal to the table, `permissions: contents: read`, no `pull_request_target`, no secrets, the sha256 check before `unzip`, and `xcode-select` before the first `xcodebuild`. Expected: no P0/P1. Fix and amend until clean.

Then run `git push origin main && git switch m01-g0-renderer && git checkout main -- .github/workflows/ci.yml`, and commit `.github/workflows/ci.yml` on the branch: "ci: js job on push, on-demand macOS 15/26 matrix with G0 benchmark". The branch doesn't merge `main`, so ci.yml stays inside the m01 review diff; the final merge adds an identical file and merges cleanly. Then `make test-shell && git push -u origin m01-g0-renderer`. Git pushes over the SSH alias `github-mus`.

- [ ] **Step 3: Watch the JS job**

Run `gh auth status`.
- If it isn't logged in, **ask the user to run `gh auth login`**, or to open the repo's Actions tab and check the run there.
- When logged in: `gh run list --workflow ci.yml --branch m01-g0-renderer -L 1 --json conclusion,url`.

Expected: `"conclusion":"success"` for the push run (job `js`).

If `build.js --check` fails only on Linux, compare `bun build.js` output between the two OSes. Fix the non-determinism; don't skip the check.

- [ ] **Step 4: Dispatch the macOS matrix**

Run (the pattern from plan 09 Task 11; `--event workflow_dispatch`, because `ci.yml` also runs on every push):
```bash
last() { gh run list --workflow ci.yml --branch m01-g0-renderer --event workflow_dispatch -L1 --json databaseId -q '.[0].databaseId'; }
OLD=$(last)
gh workflow run ci.yml --ref m01-g0-renderer
for i in $(seq 30); do ID=$(last); [ -n "$ID" ] && [ "$ID" != "$OLD" ] && break; sleep 2; done
[ -n "$ID" ] && [ "$ID" != "$OLD" ] && gh run watch "$ID" && gh run view "$ID" --log | grep -E 'Xcode 26|"mermaidCount"|G0 swift-test'
```
`gh workflow run` creates the run asynchronously, so the loop waits up to 60 s for a dispatch run ID that differs from the one before; `-L1` alone can return the previous run or the push run.
Expected: each matrix leg prints `Xcode 26.3` and 5 JSON lines with `"mermaidCount":5,"errors":0`, and both legs succeed. While the G0 perf test is still red (Task 6), a leg's `make test-swift` step fails on that test alone; `make build` and the benchmark still run (`if: ${{ !cancelled() }}`), so the rows below still get their numbers. Add two G0.md rows: `GitHub macos-15 · arm64` and `GitHub macos-26 · arm64`, each with the run URL as evidence. These rows are supporting evidence; the G0 legs are the Intel 15 and Scaleway 27 rows.

- [ ] **Step 5: Commit** `docs/gates/G0.md`: "docs(g0): CI arm64 macOS 15/26 benchmark results"

---

### Task 11: Trademark check for "Tegel" (W1, H4 depends on it)

Run this by **Thu 29 Oct**. It is independent of the code tasks.

**Files:**
- Create: `docs/gates/trademark.md`

**Interfaces:**
- Consumes: the Playwright MCP browser tools (`browser_navigate`, `browser_snapshot`, `browser_type`, `browser_click`). Never `claude-in-chrome`.
- Produces: a verdict for D7 as the file's last line, exactly one of `Decision: GO`, `Decision: NO-GO (<reason>)` or `Decision: ASK`, plus the fallback outcome. Plan 04 Task 3 greps `^Decision: GO` before buying the domain.

- [ ] **Step 1: Search the registers**

These URLs returned HTTP 200 on 27 Oct (eSearch plus timed out from the build Mac and may need the browser):

| Register | URL | Query |
|---|---|---|
| TMview (EUIPO + BOIP + national + USPTO data) | https://www.tmdn.org/tmview/ | word `TEGEL`; Nice classes 9 and 42; live marks |
| EUIPO eSearch plus | https://euipo.europa.eu/eSearch/ | `TEGEL`, classes 9 and 42. If it's unreachable, write "unreachable; covered by TMview office EM" |
| BOIP | https://www.boip.int/en/trademarks-register | `tegel`, classes 9 and 42 |
| USPTO | https://tmsearch.uspto.gov/search/search-information | wordmark `TEGEL`, live, classes 009 and 042 |

Also query `TEGEL APPS`, `TEGELAPPS` and `TEGELWERK`. For each live hit, record the mark, number, owner, classes, status and URL.

- [ ] **Step 2: Write `docs/gates/trademark.md` with the verdict**

**Rule:**
- `NO-GO` if any live mark is identical to `TEGEL`, or `TEGEL` plus a descriptive word, in class 9 or 42 in the EU, Benelux or US.
- `ASK` if there are similar marks or hits in related classes (35, 41).
- `GO` otherwise.

On `NO-GO`, repeat Step 1 for **Kadeworks** and **Netjes** (§15) and recommend one. Add the line "Desk search, not legal clearance".

End the file with the verdict line: `Decision: GO`, `Decision: NO-GO (<reason>)` or `Decision: ASK`, unformatted.

Check: `grep -E '^Decision: (GO|NO-GO|ASK)' docs/gates/trademark.md`
Expected: one line.

- [ ] **Step 3: Tell the user**

The `Decision:` line decides H4 (plan 04 Task 3):
- `GO`: buy `tegelapps.com` on Fri 30 Oct.
- `ASK`: the user decides before the purchase.
- `NO-GO`: stop and ask.

Then commit `docs/gates/trademark.md`: "docs(gates): trademark desk search for Tegel (EUIPO/TMview, BOIP, USPTO)"

---

### Task 12: Scaleway M1 on macOS 27 — the remote G0 leg (H6)

**Files:**
- Modify: `.env` (values, gitignored), `.env.example` (key names: `SCALEWAY_EMAIL=`, `REMOTE_MAC_VNC_PORT=`), `docs/gates/G0.md`

**Interfaces:**
- Consumes:
  - H3 (studio email). If it's unanswered, ask the user first.
  - The universal `Tegel Markdown.app` from `make build` (Task 8).
  - The fixtures.
- Produces:
  - the Keychain password `tegel-scaleway` (master §6);
  - `.env` keys `SCALEWAY_EMAIL`, `REMOTE_MAC_HOST`, `REMOTE_MAC_USER`, `REMOTE_MAC_PASSWORD`, `REMOTE_MAC_VNC_PORT`;
  - the `Scaleway M1 · 27.x · arm64` row in G0.md;
  - a deleted server.
- Facts:
  - M1 €0.11/h before tax, 24 h minimum [F9]: €2.64 before tax, **€3.19 incl. 21 % VAT** per lease. The M1 is offered only in PARIS 3.
  - A non-default macOS adds about 1 h.
  - The server can't be deleted until 24 h after the lease starts.
  - SSH is `ssh <user>@<ip>`; VNC uses the port shown on the Overview page, not 5900.
  - Sources: https://www.scaleway.com/en/docs/apple-silicon/quickstart/ and https://www.scaleway.com/en/docs/apple-silicon/how-to/access-remote-desktop-mac-mini/.

- [ ] **Step 1: Create the account (Wed 28 Oct)**

Run: `. scripts/lib/env.sh; envset SCALEWAY_EMAIL "$(envget STUDIO_EMAIL)" && security add-generic-password -a "$(envget STUDIO_EMAIL)" -s tegel-scaleway -w "$(openssl rand -base64 24)-"`. The password is never echoed. With Playwright, sign up at https://console.scaleway.com/register with that email; the user pastes the `tegel-scaleway` password and submits the form themselves, and Claude waits until the page has moved on (master §6). Add the two key names to `.env.example`.

Check: `. scripts/lib/env.sh; need SCALEWAY_EMAIL && security find-generic-password -a "$(envget STUDIO_EMAIL)" -s tegel-scaleway -w >/dev/null && echo ok`. After sign-up, the exposure search (master §6) for `tegel-scaleway` → `clean`.
Expected: `ok`.

- [ ] **Step 2: H6 — the user adds the card and 2FA**

Ask the user. Then check the console billing page with `browser_snapshot`.
Expected: a payment method is listed.

- [ ] **Step 3: Ask before ordering (lease L1: Fri 30 Oct evening or Sat 31 Oct morning)**

Ask in this week's question round, so the yes is in by Fri 30 Oct. Ask the user exactly: "Order 1 × Scaleway Mac mini M1, PARIS 3, macOS 27, 24 h minimum, €3.19 incl. VAT, on Fri 30 Oct evening or Sat 31 Oct morning, deleted 24 h after the order? (yes/no)". Wait for `yes`.

- [ ] **Step 4: Order and save access**

In the console: Bare Metal → Apple silicon → Create → M1 → PARIS 3 → macOS 27. Record the order time in G0.md. When the server is ready, store the host, user and VNC port from the Overview page with `envset REMOTE_MAC_HOST …` (and `REMOTE_MAC_USER`, `REMOTE_MAC_VNC_PORT`), and the password from the pasteboard: after Claude has recorded those, the **user** reveals and copies the password, and Claude makes no Playwright call while it is shown, then `. scripts/lib/env.sh && envset REMOTE_MAC_PASSWORD "$(pbpaste)" && pbcopy </dev/null` (master §6).

Every remote block from here on starts with this prefix line, **P**. `R` is a function, not a string, so it works in zsh, which doesn't word-split `$R`:
```
. scripts/lib/env.sh; SCRATCH="$TMPDIR/tegel-m01"; mkdir -p "$SCRATCH"; U="$(envget REMOTE_MAC_USER)@$(envget REMOTE_MAC_HOST)"; R() { ssh -i ~/.ssh/id_ed25519_scaleway "$U" "$@"; }
```

Install a key without printing the password:
```
<P>
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519_scaleway
printf '#!/bin/sh\nprintf "%%s\\n" "$REMOTE_MAC_PASSWORD"\n' > "$SCRATCH/askpass" && chmod 700 "$SCRATCH/askpass"
REMOTE_MAC_PASSWORD="$(envget REMOTE_MAC_PASSWORD)" SSH_ASKPASS="$SCRATCH/askpass" SSH_ASKPASS_REQUIRE=force ssh-copy-id -o StrictHostKeyChecking=accept-new -i ~/.ssh/id_ed25519_scaleway.pub "$U"
R 'sw_vers -productVersion; uname -m; who'
```
The password reaches only `ssh-copy-id`'s environment, never argv or the shell. `accept-new` records the new server's host key on first contact, and every later `R` and `rsync` checks against it. Without it, forced askpass also answers ssh's `yes/no` host-key question with the password, and ssh asks again forever (seen on the build Mac against a host missing from `known_hosts`). Expected: `27.x`, `arm64`, and a `console` line in `who`, meaning a GUI session exists. If `console` is missing, ask the user to log in once through `open "vnc://$U:$(envget REMOTE_MAC_VNC_PORT)"` (after P).

- [ ] **Step 5: Copy the app and register Quick Look**

```
<P>
rsync -a -e "ssh -i ~/.ssh/id_ed25519_scaleway" "build/Build/Products/Debug/Tegel Markdown.app" "$U:Applications/"
rsync -a -e "ssh -i ~/.ssh/id_ed25519_scaleway" Fixtures/markdown/ "$U:g0/"
R 'L=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister; $L -f -R ~/Applications/"Tegel Markdown.app"; pluginkit -e use -i com.tegelapps.markdown.quicklook; pluginkit -m -v -p com.apple.quicklook.preview | grep tegel; qlmanage -r; lipo -archs ~/Applications/"Tegel Markdown.app/Contents/MacOS/Tegel Markdown"; mdls -name kMDItemContentType ~/g0/g0-1mb.md'
```
Expected:
- One enabled pluginkit line.
- `x86_64 arm64`.
- `net.daringfireball.markdown`. If `mdls` returns `(null)` because Spotlight hasn't indexed yet, note it.

- [ ] **Step 6: Run the benchmark 5 times**

Try plain SSH first (after P):
`R 'for i in 1 2 3 4 5; do ~/Applications/"Tegel Markdown.app/Contents/MacOS/Tegel Markdown" --benchmark < ~/g0/g0-1mb.md; done'`
- Expected: 5 JSON lines with `"mermaidCount":5,"errors":0`.
- If it fails with a WindowServer or WebContent error, run it inside the GUI session, with the password on stdin and never in argv:
  `R 'sudo -S -p "" launchctl asuser "$(id -u)" sudo -u "$USER" /bin/sh -c "for i in 1 2 3 4 5; do \"$HOME/Applications/Tegel Markdown.app/Contents/MacOS/Tegel Markdown\" --benchmark < $HOME/g0/g0-1mb.md; done"' <<< "$(envget REMOTE_MAC_PASSWORD)"`
- Last resort: the user runs the same loop in Terminal over VNC and pastes the output into `$SCRATCH/bench-27.jsonl`.

Record which path was used.

- [ ] **Step 7: Time the window and Quick Look on macOS 27**

Inside the GUI session (the same `launchctl asuser` wrapper):
- 5× `open -a ~/Applications/"Tegel Markdown.app" ~/g0/g0-1mb.md; sleep 4; osascript -e 'quit app "Tegel Markdown"'`;
- 5× `qlmanage -p ~/g0/g0-1mb.md & sleep 3; kill $!`;
- once each for `mermaid-basic.md`, `mixed-bidi.md`, `hostile.md` and `huge-50mb.md`, with `screencapture -x ~/g0/ql-<f>.png`.

Then, after P:
`R "/usr/bin/log show --last 20m --style compact --predicate 'subsystem BEGINSWITH \"com.tegelapps.markdown\"' | grep -E 'window ms=|preview ms='"`
and `rsync` `~/g0/*.png` back to `$SCRATCH/` and read them.

Expected:
- 5 `window ms=` lines and ≥ 9 `preview ms=` lines; the 10 `g0-1mb.md` lines (`bytes=10…`) show `mermaid=5 errors=0`.
- The huge file shows `truncated=1` with `ms` < 2000.
- The screenshots show rendered diagrams, correct RTL and both hostile sentinels.

Fill the Scaleway row in G0.md. If Task 9 Step 4 applies, run the spike build here the same way.

- [ ] **Step 8: Commit the evidence** `docs/gates/G0.md .env.example`: "docs(g0): macOS 27 arm64 results from Scaleway M1"

- [ ] **Step 9: Leave the server idle**

The console won't allow deletion before 24 h have passed. Note the earliest deletion time in G0.md.

- [ ] **Step 10: Delete the server (≥ 24 h after the order: Sat 31 Oct evening or Sun 1 Nov)**

With Playwright: Bare Metal → Apple silicon → ⋯ → Delete → type `DELETE`. Check with `browser_snapshot` of the Apple silicon list.
Expected: no servers listed. Add "deleted <date time>, billed <€ from the console>" to G0.md and remove `~/.ssh/id_ed25519_scaleway*` and the host key that Step 4 accepted (`. scripts/lib/env.sh; ssh-keygen -R "$(envget REMOTE_MAC_HOST)"`) from the build Mac.

The second lease (W5) is plan 05's.

---

### Task 13: G0 decision (Mon 2 Nov)

**Files:**
- Modify: `docs/gates/G0.md`

**Interfaces:**
- Consumes: the rows from Tasks 6, 7, 8, 10 and 12, and the Task 9 variant.
- Produces: `**Decision:** PASS | FAIL-QL | FAIL-SPEED`, with the chosen Quick Look variant.

- [ ] **Step 1: Apply the rule**

- **PASS:** on the **iMac 15.7.7** row and the **Scaleway 27** row, Window median < 1000 ms, Quick Look median < 1000 ms, 0 of 5 blank or failed, `mermaidCount` 5 with 0 Mermaid errors in every run.
- **FAIL-QL:** Quick Look is blank or failed in any run, or > 2 s, on either machine. BUSINESS-PLAN §12 then says "drop Quick Look from both apps and re-scope App 1 to window-only (or backlog #1)".
- **FAIL-SPEED:** every run works but a median is ≥ 1000 ms.

The CI rows are reported, not decisive.

Check: `grep -E '^\*\*Decision:\*\* (PASS|FAIL-QL|FAIL-SPEED)' docs/gates/G0.md`
Expected: one line.

- [ ] **Step 2: On FAIL-QL or FAIL-SPEED, stop and ask the user**

A kill/change gate changes product scope. Present:
- the numbers;
- the failing machine;
- the options: re-scope per §12; a data-based snapshot (Task 9 Step 4); for FAIL-SPEED only, render the text first and leave Mermaid out of the < 1 s budget.

Record the user's choice under Decision. Plan 02 starts only after that.

- [ ] **Step 3: Commit** `docs/gates/G0.md`: "docs(g0): gate decision"

---

### Task 14: 9-stage review pipeline, merge and push

**Files:**
- Create: `docs/reviews/m01.md`, `docs/reviews/design-m01.md`, `docs/reviews/m01-design/*.png`
- Modify: whatever the P0/P1 fixes touch.

Run **Procedure P (master §11)** with id `m01` and branch `m01-g0-renderer`. Every command block that uses `$SCRATCH` or `$BASE` starts with `SCRATCH="$TMPDIR/tegel-m01"; mkdir -p "$SCRATCH"; BASE=$(git merge-base HEAD main)`. This plan's deltas:

- [ ] **Step 1: Stages 1–3 as in P.** Stage 2 lists the red G0 perf test (Task 6) as known, if it is still red, and then runs `make -k check`, so `test-shell` and `build` still run and are counted; the expected result is that one failure and nothing else.

- [ ] **Step 2: Stage 4, `/cso` scope**
- `Renderer/src/{index.html,page.js,sanitize.js,markdown.js}`, `build.js` and the committed `Resources/Renderer/`;
- `RendererWebView.swift`: the navigation policy, the message handling, the network rule list and the `tegel-renderer://` handler if Task 5 needed it;
- `TextFileLoader.swift` (`O_NONBLOCK`, `fstat`) and the Quick Look deadline in `PreviewViewController.swift`;
- the `project.yml` entitlements (app and Quick Look; the Sparkle mach-lookup is unused until plan 03);
- `scripts/lib/env.sh` and `scripts/check-guards.sh`;
- `.github/workflows/ci.yml` (SHA pins, permissions, the xcodegen checksum).

- [ ] **Step 3: Stage 5 input.** Hand codex `hostile.md`, the CSP, `sanitize.js` and the rule-list JSON, and ask for a working script, network or navigation escape.

- [ ] **Step 4: Stage 10, design review: screenshots**

First `make build`, then install and re-register as in Task 8 Step 4, so the shots show the branch tip. Screenshot the Quick Look preview on the build Mac (macOS 15.7.7, x86_64) in light and dark, with `rtl-arabic.md` as the Arabic case. The preview has no app chrome of ours to localise. Restore the user's appearance afterwards:
```
ORIG=$(osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode')
mkdir -p docs/reviews/m01-design
for MODE in false true; do
  osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to $MODE"
  S=$([ $MODE = true ] && echo dark || echo light)
  for f in rtl-arabic mixed-bidi mermaid-basic; do
    qlmanage -p Fixtures/markdown/$f.md >/dev/null 2>&1 & QL=$!; sleep 3
    screencapture -x "docs/reviews/m01-design/ql-$f-$S.png"; kill $QL
  done
done
osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to $ORIG"
ls docs/reviews/m01-design/*.png | wc -l
```
Expected: `6`. If `osascript` is refused (Automation permission), ask the user to switch System Settings › Appearance, and run the inner loop once per mode.

Read each PNG, then run gstack `/design-review` on the six. Write `docs/reviews/design-m01.md` with plan 09's gate sections (Inputs, Findings P0/P1/P2, Guard output, Verdict); Guard output is "none yet: plan 09's `design.test.js` arrives with Drop A, after this merge". The review covers structure only: RTL alignment, LTR code, diagrams drawn, no horizontal overflow, text legible in both appearances. Colour, type and spacing findings are deferred to plan 09 Task 6 (Global Constraints, Design). Findings at P1 or above join stage 6.

- [ ] **Step 5: Stages 6–9 as in P.** Run the design review (Step 4) before stage 6, so its findings are consolidated with the rest.

- [ ] **Step 6: Merge and push as in P (stage 11).** First commit `docs/reviews/m01.md docs/reviews/design-m01.md docs/reviews/m01-design`: "docs(review): m01 nine-stage pipeline record". The merge message is "merge: m01". After the push, `git branch -d spike/ql-data`.

---

## Not in this plan

- `scroll(toHeading:)`, the `tegel-doc:` scheme handler and "Show images", i18n of the banner and the summary string (plan 02).
- Every theme value, the ink and studio themes, dark mode and Mermaid theming (plan 09 Tasks 6–7).
- TegelStore and Release signing (plan 03).
- Third-party notices file (plan 03 release). The release checklist records Mermaid's bundled DOMPurify version (3.4.12 in 11.17.2; Task 5 Step 7 has the grep).
- W1 items with no owner here: the Google Trends check, and the Cloudflare and Polar sandbox accounts.

## Contract change requests

CR 1–3 accepted and applied to master §3.1 and §3.2 (27 Oct); history in `docs/reviews/m00-consolidated.md`.

- **CR-P1-2 (`dir="auto"` on top-level blocks only), applied to master §3.2 on 27 Oct (cubic C14).** Master §3.2 still put `dir="auto"` on `li`, `th`, `td`, `dt` and `dd`. On the build Mac (WebKit, macOS 15.7.7), with content inserted as a fragment the way `page.js` does it: an Arabic `ul dir=auto` whose `li`s also carry `dir=auto` resolves to `ltr`, and a `table dir=auto` with `td dir=auto` cells puts its first column on the left. Without the per-cell `dir`, the same list and table resolve to `rtl`, with the first column on the right. The cost is accepted: an English item in an Arabic list takes the list's RTL direction.
- **CR 4 (§3.2 Steps; cubic C10 and C51): applied to master §3.2 (27 Oct).** The Mermaid options gain `secure`: Mermaid's six default keys plus `htmlLabels` (Task 5 Step 7). `page.js`'s main pass becomes `DOMPurify.sanitize(html, {...SANITIZE_CONFIG, SANITIZE_NAMED_PROPS: true, RETURN_DOM_FRAGMENT: true})`. Every `id` and `name` in `#doc` then carries `user-content-`, `RenderResult.headings[].id` is that DOM id, and `page.js` scrolls an in-page `#x` link to `user-content-x` (or `x`). `SANITIZE_CONFIG` itself is unchanged. Also affected: plan 07's footnote ids (`fn<N>` becomes `user-content-fn<N>` in the DOM) and its conditional `a[href^="#"]` handler, which this plan now owns.
