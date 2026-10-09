#!/bin/bash
# admin-menu.sh: CloudByte Linux administration menu.
# Author: Amin Walizada
# Purpose: Run existing administration tools from one menu.
# Usage: sudo bash scripts/admin-menu.sh
#        sudo bash scripts/admin-menu.sh --help

set -o pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: sudo bash scripts/admin-menu.sh"
    exit 0
fi


if [ "$EUID" -ne 0 ]; then
    echo "Error: admin-menu.sh must be run as root."
    echo "Usage: sudo bash $0"
    exit 1
fi

if [ "$#" -gt 0 ]; then
    case "$1" in
        --help|-h)
            echo "Usage: sudo bash scripts/admin-menu.sh"
            echo "Opens the CloudByte administration menu."
            exit 0
            ;;
        *)
            echo "Error: unknown argument '$1'"
            echo "Usage: sudo bash scripts/admin-menu.sh"
            exit 2
            ;;
    esac
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "$SCRIPT_DIR" ]; then
    echo "Error: scripts directory not found: $SCRIPT_DIR"
    exit 1
fi

run_tool() {
    local name="$1"
    local file="$2"

if [ ! -f "$SCRIPT_DIR/$file" ]; then
    echo "Error: $file isn't installed in $SCRIPT_DIR"
    read -r -p "Press Enter to return to the menu..."
    return 1
fi
 
   echo
    echo "Running: $name"
    echo "----------------------------------------"

    if bash "$SCRIPT_DIR/$file"; then
        echo "Finished: $name"
    else
        local status=$?
        echo "Error: $name exited with status $status"
    fi

    echo
    read -r -p "Press Enter to return to the menu..."
}

while true; do
    echo
    echo "========================================"
    echo "   CloudByte Administration Menu"
    echo "========================================"
    echo "1) Onboard a new user"
    echo "2) Back up shared files"
    echo "3) Clean up old backups"
    echo "4) Generate test logs"
    echo "5) Analyse application logs"
    echo "6) Run system health report"
    echo "0) Exit"
    echo "----------------------------------------"

    read -r -p "Choose an option [0-6]: " choice

    case "$choice" in
        1) run_tool "User onboarding" "onboard-user.sh" ;;
        2) run_tool "Shared backup" "backup-shared.sh" ;;
        3) run_tool "Backup cleanup" "cleanup-backups.sh" ;;
        4) run_tool "Log generation" "log-generator.sh" ;;
        5) run_tool "Log analysis" "analyse-logs.sh" ;;
        6) run_tool "System health report" "system-health.sh" ;;
        0)
            echo "Goodbye. Exiting CloudByte Administration Menu."
            exit 0
            ;;
        *)
            echo "Invalid option: '$choice'. Please enter a number from 0 to 6."
            ;;
    esac
done
