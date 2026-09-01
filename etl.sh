
#!/bin/bash
#
#etl.sh - Simple ETL piplein for the Annual Enterprise Survey (AES) data
#
# Usage: ./etl.sh
#Cron: schedule this ptocess to run daily at 00:00
#
set -euo pipefail #exit on any erro, unset variable, or fail pipeline stage

#STEP 0 -CONFIG: environment variables

# Set the sourse URL as environment variable
export CSV_URL="https://www.stats.govt.nz/assets/Uploads/Annual-enterprise-survey/Annual-enterprise-survey-2023-financial-year-provisional/Download-data/annual-enterprise-survey-2023-financial-year-provisional.csv

RAW_DIR ="raw"
TRANSFORMED_DIR="Transformed"
GOLD_DIR="Gold"

RAW_FILE="$RAW_DIR/annual-enterprise-survey-2023-financial-year-provisional.csv"
TRANSFORMED_FILE="$TRANSFORMED_DIR/2023_year_finance.csv"
GOLD_DIR="$GOLD_DIR/2023_year_finance.csv"

echo "ETL run started: $(date '+%Y-%m-%d %H:%M:%S')"

#STEP 1 - EXTRACT: download the CSV into raw/

#

echo ""
echo "[EXTRACT] Donwloading CSV from \$CSV_URL .."

mkdir -p "$RAW_DIR"

curl -sSL -o "$RAW_FILE" "CSV_URL"

#Confirm the file arrived and not empty before moving on
if [[ -f" $RAW_FILE" && -s "$RAW_FILE" ]]; then
   echo "[EXTRACT] SUCCESS: file save to $RAW_FILE"
   echo "[EXTRACT] Row count (incl. header): $(wc -l < "RAW_FILE")"
else
  echo "[EXTRACT] ERROR: download failed or file is empty." >&2
  exit 1
fi

#STEP 2 - TRANSFORM: rename Variable_code -> variable code, select 4 columns


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
