#!/bin/bash
#==============================================================
#  Script: increment_build_number.sh
#  Purpose:
#    Safely increment CURRENT_PROJECT_VERSION in an Xcode project.
#
#  Rules enforced:
#    - Build number must exist in project.pbxproj
#    - Increment occurs before build
#
#  Usage:
#    ./Tools/increment_build_number.sh [path-to-xcodeproj]
#
#  Behaviour:
#    - auto-detects the first .xcodeproj in repo root unless one
#      is passed explicitly
#    - finds all CURRENT_PROJECT_VERSION values
#    - selects the highest numeric value as the active build number
#    - increments all matching occurrences
#    - verifies the update
#==============================================================

set -euo pipefail

if [ "${VERBOSE:-false}" = "true" ]; then
    echo "🔢 Incrementing build number..."
fi

PROJECT_PATH="${1:-}"

if [ -z "$PROJECT_PATH" ]; then
    PROJECT_PATH=$(find . -maxdepth 1 -name "*.xcodeproj" | head -n 1)
fi

if [ -z "$PROJECT_PATH" ]; then
    echo "❌ ERROR: No .xcodeproj found in repo root"
    exit 1
fi

PBXPROJ="$PROJECT_PATH/project.pbxproj"

if [ ! -f "$PBXPROJ" ]; then
    echo "❌ ERROR: project.pbxproj not found at $PBXPROJ"
    exit 1
fi

if [ "${VERBOSE:-false}" = "true" ]; then
    echo "📦 Using project: $PROJECT_PATH"
fi

BUILD_VALUES=$(grep -E 'CURRENT_PROJECT_VERSION = [0-9]+;' "$PBXPROJ" \
    | sed -E 's/.*CURRENT_PROJECT_VERSION = ([0-9]+);/\1/' \
    | sort -n -u)

if [ -z "$BUILD_VALUES" ]; then
    echo "❌ ERROR: No CURRENT_PROJECT_VERSION values found"
    exit 1
fi

CURRENT=$(echo "$BUILD_VALUES" | tail -n 1)
NEXT_VALUE=$((CURRENT + 1))

echo "🔍 Found CURRENT_PROJECT_VERSION values"
if [ "${VERBOSE:-false}" = "true" ]; then
    echo "$BUILD_VALUES"
fi
echo "➡️  Using highest value as active build number: $CURRENT → $NEXT_VALUE"

MATCH_COUNT=$(grep -c "CURRENT_PROJECT_VERSION = $CURRENT;" "$PBXPROJ" || true)

if [ "$MATCH_COUNT" -lt 1 ]; then
    echo "❌ ERROR: Could not find any occurrences of CURRENT_PROJECT_VERSION = $CURRENT;"
    exit 1
fi

TMP_FILE=$(mktemp)

awk -v current="$CURRENT" -v next_value="$NEXT_VALUE" '
{
    gsub("CURRENT_PROJECT_VERSION = " current ";", "CURRENT_PROJECT_VERSION = " next_value ";")
    print
}
' "$PBXPROJ" > "$TMP_FILE"

mv "$TMP_FILE" "$PBXPROJ"

UPDATED_VALUES=$(grep -E 'CURRENT_PROJECT_VERSION = [0-9]+;' "$PBXPROJ" \
    | sed -E 's/.*CURRENT_PROJECT_VERSION = ([0-9]+);/\1/' \
    | sort -n -u)

if ! grep -q "^$NEXT_VALUE$" <<< "$UPDATED_VALUES"; then
    echo "❌ ERROR: Verification failed. Expected updated build number $NEXT_VALUE not found."
    echo "Current values after update:"
    echo "$UPDATED_VALUES"
    exit 1
fi

if [ "${VERBOSE:-false}" = "true" ]; then
    echo "✅ Build number incremented successfully"
    echo "✅ Updated $MATCH_COUNT occurrence(s) from $CURRENT to $NEXT_VALUE"
fi
