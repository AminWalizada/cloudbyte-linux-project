#!/bin/bash
# analyse-logs.sh: CloudByte Solutions log analysis report.
# Author: Amin Walizada
# Date: 2026-10-07
# Purpose: Analyse application logs by severity, busiest hour, and CRITICAL entries.
# Usage: sudo bash scripts/analyse-logs.sh

set -eo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Error: analyse-logs.sh must be run as root."
    echo "Hint: sudo bash $0"
    exit 1
fi

LOG_FILE="/logs/cloudbyte-app.log"
REPORT_DIR="/logs/reports"
TIMESTAMP=$(date +%F_%H-%M-%S)
REPORT_FILE="$REPORT_DIR/log-analysis-$TIMESTAMP.txt"

mkdir -p "$REPORT_DIR"

{
    echo "CloudByte Log Analysis Report"
    echo "Source log: $LOG_FILE"
    echo "Total entries: $(wc -l < "$LOG_FILE")"
    echo

    echo "=== Count by severity ==="
    awk '{ print $3}' "$LOG_FILE" | sort | uniq -c | sort -nr
    echo

    echo "=== Busiest hour ==="
    awk '{ print $2 }' "$LOG_FILE" | cut -c1-2 | sort | uniq -c | sort -nr | head -1
    echo

    echo "=== CRITICAL entries ==="
    grep '\[CRITICAL\]' "$LOG_FILE" || echo "(none)"

} | tee "$REPORT_FILE"

echo
echo "Report written to: $REPORT_FILE"
