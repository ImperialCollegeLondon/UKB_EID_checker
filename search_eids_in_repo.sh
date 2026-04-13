#!/usr/bin/env bash
# search_eids_in_repo.sh
# Recursively searches all files in a repo for EIDs listed in matching_eids.txt
# Output: a txt file with the matching EID, file path, and the line containing it.

# ── Paths ──────────────────────────────────────────────────────────────────────
EIDS_FILE="matching_eids.txt"       # produced by find_matching_eids.sh
REPO_DIR="."                        # root of the cloned repo (same directory)
OUTPUT_FILE="eid_repo_matches.txt"  # results file

# ── Sanity checks ──────────────────────────────────────────────────────────────
if [[ ! -f "$EIDS_FILE" ]]; then
    echo "ERROR: EID list not found: $EIDS_FILE" >&2
    echo "Run find_matching_eids.sh first to generate it." >&2
    exit 1
fi

if [[ ! -d "$REPO_DIR" ]]; then
    echo "ERROR: Repo directory not found: $REPO_DIR" >&2
    exit 1
fi

EID_COUNT=$(wc -l < "$EIDS_FILE")
echo "Searching for $EID_COUNT EIDs in: $(realpath "$REPO_DIR")"
echo "This may take a moment..."

# ── Write header to output file ────────────────────────────────────────────────
{
    echo "EID Search Results"
    echo "Generated: $(date)"
    echo "EIDs searched: $EID_COUNT"
    echo "Repo searched: $(realpath "$REPO_DIR")"
    echo "================================================================"
    echo ""
} > "$OUTPUT_FILE"

# ── Search ─────────────────────────────────────────────────────────────────────
# Scans all files except images and the script's own input/output files.
MATCH_COUNT=0

while IFS= read -r EID; do
    [[ -z "$EID" ]] && continue  # skip blank lines

    while IFS= read -r RESULT; do
        FILE_PATH=$(echo "$RESULT" | cut -d':' -f1)
        LINE_NUM=$(echo "$RESULT"  | cut -d':' -f2)
        LINE_CONTENT=$(echo "$RESULT" | cut -d':' -f3-)

        # Extract 10 characters either side of the EID for context
        CONTEXT=$(echo "$LINE_CONTENT" | grep -oP ".{0,10}${EID}.{0,10}")

        {
            echo "EID       : $EID"
            echo "File      : $FILE_PATH"
            echo "Line      : $LINE_NUM"
            echo "Context   : ...${CONTEXT}..."
            echo "Full line : ${LINE_CONTENT:0:256}"
            echo "----------------------------------------------------------------"
        } >> "$OUTPUT_FILE"

        (( MATCH_COUNT++ ))

    done < <(grep -rFwHn "$EID" "$REPO_DIR" \
        --exclude="*.png"  \
        --exclude="*.PNG"  \
        --exclude="*.jpg"  \
        --exclude="*.JPG"  \
        --exclude="*.jpeg" \
        --exclude="*.JPEG" \
        2>/dev/null \
        | grep -v "/eid_repo_matches\.txt:" \
        | grep -v "/matching_eids\.txt:" \
        | grep -v "/eid_frequency_[^:]*\.csv:" \
        | grep -v "/REPOSITORY_AUDIT_REPORT_[^:]*\.csv:")

done < "$EIDS_FILE"

# ── Summary ────────────────────────────────────────────────────────────────────
echo "" >> "$OUTPUT_FILE"
echo "Total matches found: $MATCH_COUNT" >> "$OUTPUT_FILE"

echo "Done. Total matches found: $MATCH_COUNT"
echo "Results written to: $OUTPUT_FILE"
