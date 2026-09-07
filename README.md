# CDE Exercise — Linux & Git: ETL Pipeline

A small bash-based ETL pipeline that downloads the Stats NZ Annual Enterprise
Survey (AES) dataset, transforms it, and loads it into a Gold layer. Includes
a second utility script for organizing loose CSV/JSON files, and a cron
schedule for daily automation.

## Folder structure

```
.
├── raw/              # extracted source data (created by etl.sh)
├── Transformed/       # cleaned/selected columns (created by etl.sh)
├── Gold/               # final output layer (created by etl.sh)
├── json_and_CSV/       # destination for move_files.sh
├── etl.sh
├── move_files.sh
├── crontab.txt
└── README.md
```

`raw/`, `Transformed/`, `Gold/`, and `json_and_CSV/` are not committed empty —
they're created automatically the first time the relevant script runs
(`mkdir -p`).

## Prerequisites

- A Linux shell (WSL/Ubuntu, native Linux, or macOS)
- `bash`, `curl`, `awk` — all standard on Ubuntu, nothing extra to install
- `git`

## Scripts

### `etl.sh`

Extract → Transform → Load pipeline for the AES dataset.

| Stage | What happens |
|---|---|
| **Extract** | Downloads the CSV (URL set via the `CSV_URL` env var) into `raw/` |
| **Transform** | Renames `Variable_code` → `variable_code` and selects `year, Value, Units, variable_code` into `Transformed/2023_year_finance.csv` |
| **Load** | Copies the transformed file into `Gold/2023_year_finance.csv` |

Column matching is done **by header name, case-insensitively** rather than by
column position — this keeps the script working even if Stats NZ reorders
columns in a future release of the dataset.

**Usage:**
```bash
chmod +x etl.sh
./etl.sh
```

Each stage prints progress and row counts, and the script exits immediately
(`set -euo pipefail`) if a download fails or a step produces an empty file.

### `move_files.sh`

Moves all `.csv` and `.json` files from a source folder into `json_and_CSV/`.

**Usage:**
```bash
chmod +x move_files.sh
./move_files.sh [source_folder] [dest_folder]
```

- `source_folder` defaults to `source` if omitted
- `dest_folder` defaults to `json_and_CSV` if omitted
- Uses `shopt -s nullglob` so it doesn't error out when zero matching files
  exist — it just reports "nothing to do" and exits cleanly
- Non-CSV/JSON files (e.g. `.txt`) are left untouched in the source folder

## Scheduling with cron

`etl.sh` is scheduled to run daily via cron. The full line lives in
[`crontab.txt`](./crontab.txt) — see that file for install steps. Summary:

```
0 1 * * * /home/<user>/CDE-exercise/etl.sh >> /home/<user>/CDE-exercise/etl.log 2>&1
```

This runs at 01:00 daily and appends all output to `etl.log` for auditing.
**Absolute paths are required** — cron does not inherit your interactive
shell's `$PATH` or working directory, so a relative path like `./etl.sh`
will silently fail.

Install it with:
```bash
crontab -e
# paste the line from crontab.txt, replacing the path with your repo's
# actual absolute path (find it with: cd ~/CDE-exercise && pwd)
```

Verify it's active:
```bash
crontab -l
```

## Testing

Both scripts were syntax-checked with `bash -n` and dry-run tested before
being committed:

```bash
bash -n etl.sh
bash -n move_files.sh
```

To manually test `move_files.sh` without real data:
```bash
mkdir -p source
echo '{"name":"test"}' > source/config.json
printf "id,value\n1,100\n2,200\n" > source/sample.csv
./move_files.sh source json_and_CSV
```

## Notes / known limitations

- `etl.sh` requires outbound network access to `stats.govt.nz` — if that
  domain is blocked in your environment, the extract step will fail loudly
  rather than silently producing an empty file.
- The dataset's exact column names are assumed to match the current Stats NZ
  AES release schema (`Year`, `Value`, `Units`, `Variable_code`, plus others
  not used here). If Stats NZ renames a column outright (not just reorders
  it), the transform step will need the relevant `tolower(name)==` check in
  `etl.sh` updated to match.
