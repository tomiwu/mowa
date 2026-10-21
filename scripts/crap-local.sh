#!/usr/bin/env bash
# Local CRAP gate for Linux and macOS: runs `swift test --enable-code-coverage` for each
# Swift package under Packages/ and Tools/, joins lizard complexity with the llvm-cov JSON,
# and fails if any function has CRAP >= 4. It does not measure App/ or Keyboard/ (they need
# Xcode). It skips functions that are not compiled on this platform (no coverage entry).
# The macOS CI job "crap" (scripts/crap.sh) measures all code.
# Usage: scripts/crap-local.sh [package-dir]...   (default: all packages)
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
threshold="${CRAP_THRESHOLD:-4}"
cd "$root"

if [ "$#" -gt 0 ]; then
    packages=("$@")
else
    mapfile -t packages < <(find Packages Tools -mindepth 2 -maxdepth 2 -name Package.swift -exec dirname {} \; | sort)
fi

swift build -c release --package-path Tools/CrapGate >&2
crapgate="$(swift build -c release --package-path Tools/CrapGate --show-bin-path)/CrapGate"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

json_files=()
index=0
for package in "${packages[@]}"; do
    index=$((index + 1))
    echo "crap-local: swift test --enable-code-coverage in $package" >&2
    swift test --enable-code-coverage --package-path "$package" >&2
    cp "$(swift test --show-codecov-path --package-path "$package")" "$work/cov-$index.json"
    json_files+=("$work/cov-$index.json")
done

lizard --csv -l swift -x "*/Tests/*" -x "*/.build/*" "${packages[@]}" >"$work/lizard.csv"

"$crapgate" --only-compiled "$root" "$threshold" "$work/lizard.csv" "${json_files[@]}" >"$work/crap.csv"
echo "crap-local: all functions have CRAP < $threshold" >&2
