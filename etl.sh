#!/bin/bash
#
# etl.sh — Simple ETL pipeline for the Annual Enterprise Survey (AES) data
#          Extract -> Transform -> Load
#
# Usage:   ./etl.sh
# Cron:    schedule this to run daily at 00:00 (see README for the crontab line)
#
set -euo pipefail   # exit on any error, unset variable, or failed pipe stage

# STEP 0 — CONFIG: environment variables

# The source URL is set as an environment variable per the assignment spec.
export CSV_URL="https://www.stats.govt.nz/assets/Uploads/Annual-enterprise-survey/Annual-enterprise-survey-2023-financial-year-provisional/Download-data/annual-enterprise-survey-2023-financial-year-provisional.csv"

RAW_DIR="raw"
TRANSFORMED_DIR="Transformed"
GOLD_DIR="Gold"

RAW_FILE="$RAW_DIR/annual-enterprise-survey-2023-financial-year-provisional.csv"
TRANSFORMED_FILE="$TRANSFORMED_DIR/2023_year_finance.csv"
GOLD_FILE="$GOLD_DIR/2023_year_finance.csv"

echo " ETL run started: $(date '+%Y-%m-%d %H:%M:%S')"

# STEP 1 — EXTRACT: download the CSV into raw/

echo ""
echo "[EXTRACT] Downloading CSV from \$CSV_URL ..."

mkdir -p "$RAW_DIR"

# -s (silent) -S (show errors) -L (follow redirects)
curl -sSL -o "$RAW_FILE" "$CSV_URL"

# Confirm the file actually landed and isn't empty before moving on.
if [[ -f "$RAW_FILE" && -s "$RAW_FILE" ]]; then
    echo "[EXTRACT] SUCCESS: file saved to $RAW_FILE"
    echo "[EXTRACT] Row count (incl. header): $(wc -l < "$RAW_FILE")"
else
    echo "[EXTRACT] ERROR: download failed or file is empty." >&2
    exit 1
fi

# STEP 2 — TRANSFORM: rename Variable_code -> variable_code, select 4 columns

echo ""
echo "[TRANSFORM] Renaming 'Variable_code' -> 'variable_code' and selecting columns..."

mkdir -p "$TRANSFORMED_DIR"

# We look up each source column by name (case-insensitive) instead of hardcoding
# a column number, so the script keeps working even if the source file's column
# order changes in a future release.
awk -F',' '
BEGIN { OFS="," }
NR==1 {
    for (i=1; i<=NF; i++) {
        name=$i
        gsub(/\r/,"",name)                    # strip stray carriage returns
        if (tolower(name)=="year")          year_i=i
        if (tolower(name)=="value")         value_i=i
        if (tolower(name)=="units")         units_i=i
        if (tolower(name)=="variable_code") varcode_i=i
    }
    # This header line IS the rename: Variable_code -> variable_code
    print "year", "Value", "Units", "variable_code"
    next
}
{
    gsub(/\r/,"")
    print $year_i, $value_i, $units_i, $varcode_i
}
' "$RAW_FILE" > "$TRANSFORMED_FILE"

if [[ -f "$TRANSFORMED_FILE" && -s "$TRANSFORMED_FILE" ]]; then
    echo "[TRANSFORM] SUCCESS: file saved to $TRANSFORMED_FILE"
    echo "[TRANSFORM] Row count (incl. header): $(wc -l < "$TRANSFORMED_FILE")"
else
    echo "[TRANSFORM] ERROR: transform step failed." >&2
    exit 1
fi

# STEP 3 — LOAD: copy the transformed file into Gold/

echo ""
echo "[LOAD] Loading transformed data into $GOLD_DIR ..."

mkdir -p "$GOLD_DIR"
cp "$TRANSFORMED_FILE" "$GOLD_FILE"

if [[ -f "$GOLD_FILE" && -s "$GOLD_FILE" ]]; then
    echo "[LOAD] SUCCESS: file saved to $GOLD_FILE"
else
    echo "[LOAD] ERROR: load step failed." >&2
    exit 1
fi

echo ""
echo " ETL run finished: $(date '+%Y-%m-%d %H:%M:%S')"
