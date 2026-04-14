# EID Search Toolkit

A Bash script for auditing a codebase by finding which Encrypted IDs (EIDs) from the [UKB audit tool](https://github.com/UK-Biobank/UKB-Git-Audit-Tool) frequency report appear in a bridge file, then locating every occurrence of those EIDs across a repository — all in a single run.

---

## Script Overview

| Script | Purpose |
|---|---|
| `find_and_search_eids.sh` | Cross-references EIDs from a CSV against a bridge file, then searches the repository for every occurrence of each matched EID |

---

## `find_and_search_eids.sh`

### Input Files

| File | Location | Description |
|---|---|---|
| `eid_frequency_*.csv` | Same directory as the script | A CSV whose **first column** contains EIDs (with a header row). The script auto-detects the first file matching this glob pattern. |
| `bridge_18545_40616_47602.txt` | One directory **above** the script (`../`) | A plain-text bridge file that EIDs are matched against. Any EID from the CSV that appears as a whole word in this file is considered a match. |

### Output Files

| File | Location | Description |
|---|---|---|
| `eid_repo_matches.txt` | Same directory as the script | A human-readable report of every EID match found in the repository. If no EIDs matched the bridge file, the file is still written with a message confirming no matches were found. |

### How It Works

The script runs in two sequential steps:

**Step 1 — Find matching EIDs**
1. Extracts all EIDs from the first column of the CSV (skipping the header).
2. Searches the bridge file for whole-word matches against those EIDs using fixed-string matching (no regex).
3. If no matches are found, writes a report to `eid_repo_matches.txt` and exits early.

**Step 2 — Search the repository**
1. Takes the matched EIDs and searches all files recursively from the script's directory.
2. For each match found, records the EID, file path, line number, context, and full line content.
3. Writes everything to `eid_repo_matches.txt` with a summary count at the end.

Temporary files used during matching are held in memory and cleaned up automatically on exit — no intermediate `matching_eids.txt` file is written to disk.

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

Total repo matches found: <count>
```

If no EIDs matched the bridge file, the output will instead contain:

```
EID Search Results
Generated: <timestamp>
================================================================

No matching EIDs found between CSV and bridge file. Nothing to search.
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
- Previously generated audit files: `eid_frequency_*.csv`, `REPOSITORY_AUDIT_REPORT_*.csv`

---

## Typical Workflow

```
your-repo/
├── find_and_search_eids.sh
├── eid_frequency_[Repo name].csv   ← your EID frequency export
└── ../
    └── bridge_18545_40616_47602.txt  ← your bridge file (one level up)
```

```bash
bash find_and_search_eids.sh
```

Results are written to `eid_repo_matches.txt`.
