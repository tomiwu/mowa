#!/usr/bin/env bash
# Run all checks that work on Linux and macOS before a commit or a push.
# It runs the same checks as the CI jobs `format`, `lint`, `test` and `crap`,
# for the Swift packages under Packages/ and Tools/ only.
# It cannot build App/ or Keyboard/ or run the simulator tests. The macOS CI does that.
# Usage: scripts/precommit.sh            (check only)
#        scripts/precommit.sh --fix      (format the files first, then check)
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

step() { printf '\n== precommit: %s\n' "$1" >&2; }

if [ "${1:-}" = "--fix" ]; then
    step "swift format (in place)"
    swift format format --in-place --recursive .
fi

step "format check (CI job: format)"
swift format lint --strict --recursive .

step "SwiftLint (CI job: lint)"
# The dynamic Linux binary needs a newer glibc than the container has. The static binary works.
# The static binary skips the rules that need SourceKit; the CI lint job checks them.
swiftlint_bin=""
for candidate in swiftlint swiftlint-static; do
    if command -v "$candidate" >/dev/null 2>&1 && "$candidate" version >/dev/null 2>&1; then
        swiftlint_bin="$candidate"
        break
    fi
done
if [ -z "$swiftlint_bin" ]; then
    echo "precommit: no working SwiftLint found" >&2
    exit 1
fi
"$swiftlint_bin" lint --strict --quiet

mapfile -t packages < <(find Packages Tools -mindepth 2 -maxdepth 2 -name Package.swift -exec dirname {} \; | sort)

step "build packages and tests with warnings as errors (CI job: test)"
for package in "${packages[@]}"; do
    echo "precommit: swift build --build-tests in $package" >&2
    swift build --build-tests --package-path "$package" -Xswiftc -warnings-as-errors
done

step "tests with coverage and CRAP < 6 (CI jobs: test, crap)"
scripts/crap-local.sh "${packages[@]}"

printf '\nprecommit: all local checks passed. The macOS CI still checks App/, Keyboard/ and the simulator tests.\n' >&2
