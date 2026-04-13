#!/usr/bin/env bash
# find_matching_eids.sh
# Finds EIDs from the CSV that appear in the bridge text file
# and writes matching numbers to a new output file.

# ── Paths ──────────────────────────────────────────────────────────────────────
CSV_FILE=$(ls eid_frequency_*.csv 2>/dev/null | head -n 1)
BRIDGE_FILE="../bridge_18545_40616_47602.txt"
OUTPUT_FILE="matching_eids.txt"

# ── Sanity checks ──────────────────────────────────────────────────────────────
if [[ ! -f "$CSV_FILE" ]]; then
    echo "ERROR: CSV file not found: $CSV_FILE" >&2
    exit 1
fi

if [[ ! -f "$BRIDGE_FILE" ]]; then
    echo "ERROR: Bridge file not found: $BRIDGE_FILE" >&2
    exit 1
fi

# ── Extract EIDs from the first column of the CSV (skip header row) ────────────
# Cuts the first field, skips the header, strips any carriage returns (Windows line endings)
TMP_EIDS=$(mktemp)
tail -n +2 "$CSV_FILE" | cut -d',' -f1 | tr -d '\r' | sort > "$TMP_EIDS"

echo "Total EIDs in CSV: $(wc -l < "$TMP_EIDS")"

# ── Find which of those EIDs appear in the bridge file ────────────────────────
# grep -F  : fixed strings (no regex interpretation)
# -w       : whole-word match (avoids partial number matches)
# -o       : print only the matching part
# -f       : read patterns from the EID temp file
grep -Fw -o -f "$TMP_EIDS" "$BRIDGE_FILE" | sort -u > "$OUTPUT_FILE"

MATCH_COUNT=$(wc -l < "$OUTPUT_FILE")

rm -f "$TMP_EIDS"

# ── Report ─────────────────────────────────────────────────────────────────────
if [[ "$MATCH_COUNT" -eq 0 ]]; then
    echo "No matching EIDs found between CSV and bridge file." > "$OUTPUT_FILE"
    echo "No matching EIDs found."
else
    echo "Matching EIDs found: $MATCH_COUNT"
    echo "Results written to: $OUTPUT_FILE"
fi
