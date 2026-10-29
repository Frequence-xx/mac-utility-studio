#!/usr/bin/env bash
# Standing rule 4's mechanical half: keep the graph current without anyone remembering.
# Stop-scoped (once per turn, not per edit) and lock-guarded so concurrent turns
# can't corrupt graphify-out.
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0
[ -d graphify-out ] || exit 0
command -v graphify >/dev/null 2>&1 || exit 0
lock="${TMPDIR:-/tmp}/graphify-tegel.lock"
mkdir "$lock" 2>/dev/null || exit 0
trap 'rmdir "$lock" 2>/dev/null' EXIT
graphify update . >/dev/null 2>&1
exit 0
