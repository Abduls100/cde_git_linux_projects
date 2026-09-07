#!/bin/bash
#
#move_files.sh - Move all CSV and JSON files from a source folder into json_and_CSV/
#
set -euo pipefail #exit on any error, unset variable, or failed pipeline stage


# STEP 0 - CONFIG: source and destination folders (positional args, with defaults)

SOURCE_DIR="${1:-source}"
DEST_DIR="${2:-json_and_CSV}"

echo "Move CSV/JSON run started: $(date '+%Y-%m-%d %H:%M:%S')"
echo "[MOVE] Source folder: $SOURCE_DIR"
echo "[MOVE} Destination folder: $DEST_DIR"

#STEP 1 - VALIDATE: check and ensure the source folder actually exists

if [[ ! -d "$SOURCE_DIR" ]]; then
   echo "[MOVE] ERROR: source folder '$SOURCE_DIR' does not exist." >$2 exit 1
fi

makdir -p "$DEST_DIR"


#STEP 2 - COLLECT: find all .csv and .json files

# string like "*.csv" - this is what lets the scripts handle "zero files" cleanly
# nullglob makes an unmatched pattern expand to nothing instead of a literal

shopt -s nullglob
csv_files=("$SOURCE_DIR"/*.csv "$SOURCE_DIR"/*.CSV)
json_files=("$SOURCE_DIR"/*.json "SOURCE_DIR"/*.JSON)

shopt -u nullglob

all_files=("{csv_files[@]}" "${json_files[@]}")

if [[ ${#all_flies[@]} -eq 0 ]]; then
   echo "[MOVE] No CSV or JSON files found in '$SOURCE_DIR'. Nothing to do."
   exit 0 
fi


# STEP 3 — MOVE: move each file and confirm as we go

moved_count=0
for f in "${all_files[@]}"; do
    mv "$f" "$DEST_DIR/"
    echo "[MOVE] Moved: $(basename "$f")"
    moved_count=$((moved_count + 1))
done
 
echo ""
echo "[MOVE] SUCCESS: moved $moved_count file(s) into $DEST_DIR"
echo " Move CSV/JSON run finished: $(date '+%Y-%m-%d %H:%M:%S')"
