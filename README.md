# EID Search Toolkit

A pair of Bash scripts for auditing a codebase by finding which Encrypted IDs (EIDs) from the [UKB audit tool](https://github.com/UK-Biobank/UKB-Git-Audit-Tool) frequency report appear in a bridge file, then locating every occurrence of those EIDs across a repository.

---

## Scripts Overview

| Script | Purpose |
|---|---|
| `find_matching_eids.sh` | Cross-references EIDs from a CSV against a bridge file, producing a filtered list of matched EIDs |
| `search_eids_in_repo.sh` | Takes that filtered list and searches an entire repository for every occurrence of each EID |

Run them **in order**: `find_matching_eids.sh` first, then `search_eids_in_repo.sh`.

---

## `find_matching_eids.sh`

### Input Files

| File | Location | Description |
|---|---|---|
| `eid_frequency_*.csv` | Same directory as the script | A CSV whose **first column** contains EIDs (with a header row). The script auto-detects the first file matching this glob pattern. |
| `bridge_18545_40616_47602.txt` | One directory **above** the script (`../`) | A plain-text bridge file that EIDs are matched against. Any EID from the CSV that appears as a whole word in this file is considered a match. |

### Output Files

| File | Location | Description |
|---|---|---|
| `matching_eids.txt` | Same directory as the script | A plain-text file with one matched EID per line, sorted and deduplicated. This file is used as the input to `search_eids_in_repo.sh`. If no matches are found, the file will contain the message `No matching EIDs found between CSV and bridge file.` |

### How It Works

1. Extracts all EIDs from the first column of the CSV (skipping the header).
2. Searches the bridge file for whole-word matches against those EIDs using fixed-string matching (no regex).
3. Writes the deduplicated matches to `matching_eids.txt`.

---

## `search_eids_in_repo.sh`

### Input Files

| File | Location | Description |
|---|---|---|
| `matching_eids.txt` | Same directory as the script | The output from `find_matching_eids.sh` — one EID per line. |
| Repository files | Same directory as the script (`.`) | The script searches all files recursively from its own directory. Place the script at the root of the repository you want to audit. |

### Output Files

| File | Location | Description |
|---|---|---|
| `eid_repo_matches.txt` | Same directory as the script | A human-readable report of every EID match found in the repository (see format below). |

### Output Format

`eid_repo_matches.txt` contains a header block followed by one record per match, separated by dashed lines:

```
EID Search Results
Generated: <timestamp>
EIDs searched: <count>
Repo searched: <absolute path>
================================================================

EID       : <matched EID>
File      : <relative path to file containing the match>
Line      : <line number>
Context   : ...<up to 10 characters either side of the EID>...
Full line : <first 256 characters of the matching line>
----------------------------------------------------------------

...

Total matches found: <count>
```

**Field descriptions:**

| Field | Description |
|---|---|
| `EID` | The Entity ID that was matched |
| `File` | Path to the file containing the match, relative to the repo root |
| `Line` | Line number within that file |
| `Context` | Up to 10 characters on either side of the EID, for quick inline review |
| `Full line` | The full content of the matching line, truncated to 256 characters |

### Excluded Files

The following are automatically excluded from the search to avoid noise and self-referential matches:

- Image files: `*.png`, `*.PNG`, `*.jpg`, `*.JPG`, `*.jpeg`, `*.JPEG`
- The script's own output file: `eid_repo_matches.txt`
- The EID input file: `matching_eids.txt`
- Previously generated audit files: `eid_frequency_*.csv`, `REPOSITORY_AUDIT_REPORT_*.csv`

---

## Typical Workflow

```
your-repo/
├── find_matching_eids.sh
├── search_eids_in_repo.sh
├── eid_frequency_2024-01-01.csv   ← your EID frequency export
└── ../
    └── bridge_18545_40616_47602.txt  ← your bridge file (one level up)
```

```bash
# Step 1 — find which EIDs from the CSV appear in the bridge file
bash find_matching_eids.sh

# Step 2 — search the repo for every occurrence of those EIDs
bash search_eids_in_repo.sh
```

Results are written to `matching_eids.txt` and `eid_repo_matches.txt` respectively.
