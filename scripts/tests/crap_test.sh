#!/usr/bin/env bash
# Tests for scripts/crap.sh with fake lizard, xccov and CrapGate commands.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0

check() {
    local name="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "ok   $name"
    else
        echo "FAIL $name: expected '$expected', got '$actual'"
        failures=$((failures + 1))
    fi
}

cat >"$work/lizard" <<'FAKE'
#!/usr/bin/env bash
echo "$@" >"$FAKE_LOG"
echo '1,1,1,0,1,"f@1-2@App/A.swift","App/A.swift","f","f",1,2'
FAKE
cat >"$work/xccov" <<'FAKE'
#!/usr/bin/env bash
echo '{"targets":[]}'
FAKE
cat >"$work/gate" <<'FAKE'
#!/usr/bin/env bash
echo "gate $# $2" >>"$FAKE_LOG"
exit "${FAKE_GATE_EXIT:-0}"
FAKE
chmod +x "$work/lizard" "$work/xccov" "$work/gate"
mkdir "$work/a.xcresult" "$work/b.xcresult"

run() {
    FAKE_LOG="$work/log" LIZARD="$work/lizard" XCCOV="$work/xccov" CRAPGATE="$work/gate" \
        "$root/scripts/crap.sh" "$@" >/dev/null 2>&1
    echo $?
}
export FAKE_LOG="$work/log"

check "no argument is a usage error" 2 "$(run)"
check "missing bundle is an error" 2 "$(run "$work/missing.xcresult")"
check "passing gate exits 0" 0 "$(run "$work/a.xcresult")"
check "one bundle reaches the gate" "gate 4 6" "$(grep '^gate' "$work/log")"
check "lizard skips tests" 1 "$(grep -c -- '-x \*/Tests/\*' "$work/log")"
check "failing gate exits 1" 1 "$(FAKE_GATE_EXIT=1 run "$work/a.xcresult" "$work/b.xcresult")"
check "gate gets two xccov files" "gate 5 6" "$(grep '^gate' "$work/log")"

if [ "$failures" -ne 0 ]; then
    exit 1
fi
