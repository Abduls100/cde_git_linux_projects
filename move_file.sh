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

