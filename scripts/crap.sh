#!/usr/bin/env bash
# CRAP gate: joins lizard complexity with xccov coverage and fails if any CRAP >= 4.
# Usage: scripts/crap.sh <result.xcresult>...
# Test hooks: LIZARD, XCCOV and CRAPGATE replace the real commands.
set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "usage: scripts/crap.sh <result.xcresult>..." >&2
    exit 2
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
threshold="${CRAP_THRESHOLD:-4}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

for bundle in "$@"; do
    if [ ! -e "$bundle" ]; then
        echo "crap.sh: result bundle not found: $bundle" >&2
        exit 2
    fi
done

if [ -z "${CRAPGATE:-}" ]; then
    swift build -c release --package-path "$root/Tools/CrapGate" >&2
    CRAPGATE="$(swift build -c release --package-path "$root/Tools/CrapGate" --show-bin-path)/CrapGate"
fi

cd "$root"
${LIZARD:-lizard} --csv -l swift -x "*/Tests/*" -x "*/.build/*" App Keyboard Packages Tools \
    >"$work/lizard.csv"

json_files=()
index=0
for bundle in "$@"; do
    index=$((index + 1))
    ${XCCOV:-xcrun xccov} view --report --json "$bundle" >"$work/xccov-$index.json"
    json_files+=("$work/xccov-$index.json")
done

"$CRAPGATE" "$root" "$threshold" "$work/lizard.csv" "${json_files[@]}"
