#!/usr/bin/env bash
# Tests for scripts/check_secrets.sh.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="$root/scripts/check_secrets.sh"
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

all_set() {
    env ASC_KEY_ID=a ASC_ISSUER_ID=b ASC_KEY_P8=c MATCH_GIT_URL=d \
        MATCH_GIT_BASIC_AUTHORIZATION=e MATCH_PASSWORD=f APPLE_TEAM_ID=g "$@"
}

all_set "$script" >/dev/null 2>&1
check "all secrets set: exit 0" 0 "$?"

output="$(all_set MATCH_PASSWORD= "$script" 2>&1)"
check "one empty secret: exit 1" 1 "$?"
check "one empty secret: named" 1 "$(grep -c 'MATCH_PASSWORD' <<<"$output")"

output="$(env -i PATH="$PATH" "$script" 2>&1)"
check "no secrets: exit 1" 1 "$?"
check "no secrets: seven errors" 7 "$(grep -c '^::error::' <<<"$output")"

exit "$failures"
