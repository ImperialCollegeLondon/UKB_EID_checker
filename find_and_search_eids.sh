#!/usr/bin/env bash
# find_and_search_eids.sh
# 1. Finds EIDs from the CSV that appear in the bridge text file.
# 2. Searches a repo for every matched EID and reports file locations.

set -euo pipefail

# ── Paths ──────────────────────────────────────────────────────────────────────
CSV_FILE=$(ls eid_frequency_*.csv 2>/dev/null | head -n 1)
BRIDGE_FILE="../bridge_18545_40616_47602.txt"
REPO_DIR="."
OUTPUT_FILE="eid_repo_matches.txt"

# ── Sanity checks ──────────────────────────────────────────────────────────────
if [[ ! -f "$CSV_FILE" ]]; then
    echo "ERROR: CSV file not found (expected eid_frequency_*.csv)" >&2
    exit 1
fi

if [[ ! -f "$BRIDGE_FILE" ]]; then
    echo "ERROR: Bridge file not found: $BRIDGE_FILE" >&2
    exit 1
fi

if [[ ! -d "$REPO_DIR" ]]; then
    echo "ERROR: Repo directory not found: $REPO_DIR" >&2
    exit 1
fi

# ── Step 1: Extract EIDs from CSV and match against bridge file ────────────────
echo "=== Step 1: Finding matching EIDs ==="

TMP_EIDS=$(mktemp)
trap 'rm -f "$TMP_EIDS"' EXIT

tail -n +2 "$CSV_FILE" | cut -d',' -f1 | tr -d '\r' | sort > "$TMP_EIDS"
echo "Total EIDs in CSV: $(wc -l < "$TMP_EIDS")"

TMP_MATCHED=$(mktemp)
trap 'rm -f "$TMP_EIDS" "$TMP_MATCHED"' EXIT

grep -Fw -o -f "$TMP_EIDS" "$BRIDGE_FILE" | sort -u > "$TMP_MATCHED" || true
MATCH_COUNT=$(wc -l < "$TMP_MATCHED")

if [[ "$MATCH_COUNT" -eq 0 ]]; then
    {
        echo "EID Search Results"
        echo "Generated: $(date)"
        echo "================================================================"
        echo ""
        echo "No matching EIDs found between CSV and bridge file. Nothing to search."
    } > "$OUTPUT_FILE"
    echo "No matching EIDs found. Results written to: $OUTPUT_FILE"
    exit 0
fi

echo "Matching EIDs found: $MATCH_COUNT"

# ── Step 2: Search repo for each matched EID ──────────────────────────────────
echo ""
echo "=== Step 2: Searching repo for matched EIDs ==="
echo "Searching in: $(realpath "$REPO_DIR")"
echo "This may take a moment..."

{
    echo "EID Search Results"
    echo "Generated: $(date)"
    echo "EIDs searched: $MATCH_COUNT"
    echo "Repo searched: $(realpath "$REPO_DIR")"
    echo "================================================================"
    echo ""
} > "$OUTPUT_FILE"

REPO_MATCH_COUNT=0

while IFS= read -r EID; do
    [[ -z "$EID" ]] && continue

    while IFS= read -r RESULT; do
        FILE_PATH=$(echo "$RESULT"    | cut -d':' -f1)
        LINE_NUM=$(echo "$RESULT"     | cut -d':' -f2)
        LINE_CONTENT=$(echo "$RESULT" | cut -d':' -f3-)

        CONTEXT=$(echo "$LINE_CONTENT" | grep -oP ".{0,10}${EID}.{0,10}")

        {
            echo "EID       : $EID"
            echo "File      : $FILE_PATH"
            echo "Line      : $LINE_NUM"
            echo "Context   : ...${CONTEXT}..."
            echo "Full line : ${LINE_CONTENT:0:256}"
            echo "----------------------------------------------------------------"
        } >> "$OUTPUT_FILE"

        (( REPO_MATCH_COUNT++ ))

    done < <(grep -rFwHn "$EID" "$REPO_DIR"  \
        --exclude="*.png"                     \
        --exclude="*.PNG"                     \
        --exclude="*.jpg"                     \
        --exclude="*.JPG"                     \
        --exclude="*.jpeg"                    \
        --exclude="*.JPEG"                    \
        2>/dev/null                           \
        | grep -v "/eid_repo_matches\.txt:"   \
        | grep -v "/eid_frequency_[^:]*\.csv:" \
        | grep -v "/REPOSITORY_AUDIT_REPORT_[^:]*\.csv:" \
        || true)

done < "$TMP_MATCHED"

# ── Summary ────────────────────────────────────────────────────────────────────
{
    echo ""
    echo "Total repo matches found: $REPO_MATCH_COUNT"
} >> "$OUTPUT_FILE"

echo ""
echo "=== Done ==="
echo "EIDs matched in bridge file : $MATCH_COUNT"
echo "Repo occurrences found      : $REPO_MATCH_COUNT"
echo "Results written to          : $OUTPUT_FILE"
