#!/usr/bin/env bash
# Fail with one message that names each missing release secret.
set -uo pipefail

required=(
    ASC_KEY_ID
    ASC_ISSUER_ID
    ASC_KEY_P8
    MATCH_GIT_URL
    MATCH_GIT_BASIC_AUTHORIZATION
    MATCH_PASSWORD
    APPLE_TEAM_ID
)

missing=()
for name in "${required[@]}"; do
    if [ -z "${!name:-}" ]; then
        missing+=("$name")
    fi
done

if [ "${#missing[@]}" -gt 0 ]; then
    for name in "${missing[@]}"; do
        echo "::error::Missing repository secret: $name"
    done
    echo "Add the missing secrets in Settings, Secrets and variables, Actions. See README, section Signing and TestFlight."
    exit 1
fi
echo "All release secrets are set."
