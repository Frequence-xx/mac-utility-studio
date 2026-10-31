#!/usr/bin/env bash
# Fires once per session, on the first Write/Edit. Reminds of the standing rules
# that nothing else enforces (local-docs/SESSION-START-PROMPT.md, "What is already
# automatic"). Once per session on purpose: an always-on reminder teaches the agent
# to ignore hooks.
sid=$(jq -r '.session_id // "nosid"' 2>/dev/null)
marker="${TMPDIR:-/tmp}/claude-tegel-standing-rules-${sid}"
[ -e "$marker" ] && exit 0
: > "$marker"
cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"STANDING RULES CHECK (once per session, first file edit).\n(4) GRAPHIFY: before editing shared code (Renderer/, Packages/TegelKit), run `graphify path \"<A>\" \"<B>\"` for blast radius; add --undirected when the directed search returns nothing. Pass real symbols, not file stems.\n(6) DELEGATE: push substantive work to subagents; keep main-session turns short so the user never waits.\n(7) SUBAGENTS INHERIT NOTHING: every brief names the superpowers skills, says follow ponytail + karpathy, demands literal command output as evidence, states the `make check` baseline, lists the files it must NOT touch, and forbids push, release upload, live Polar changes, production deploys, purchases, posts, emails and the shared Playwright browser.\n(10) ACCOUNTS: only marketing@snelverhuizen.nl and Apple team 23N7947PKX; never Stichting Tarbiyah Consultancy (72PF8SBQR6). Read the signed-in account before any dashboard change.\nAlso: the 9-stage pipeline before a milestone is called done. This Intel Mac can't speak for Apple Silicon or macOS 26/27."},"systemMessage":"Standing-rules reminder (the rules nothing else enforces)."}
JSON
