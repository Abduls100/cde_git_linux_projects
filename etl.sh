
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

