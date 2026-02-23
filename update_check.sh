#!/bin/bash

# ==========================================
# System Security & Update Audit Script
# ==========================================

# Print Section Header
echo "=== SECTION 1: SYSTEM UPDATES ==="

# Initialize variables
STATUS="[FAILED]"
REMEDIATION=""
ID="1.1.1     "
DESCRIPTION="Ensure system packages are up to date"

# Detect package manager and check for updates
if command -v apt-get &>/dev/null; then
    # Debian/Ubuntu system check
    # Note: For the most accurate results, 'apt-get update' should be run before this script,
    # but we avoid running it here to keep the script read-only/non-intrusive.
    UPDATES=$(apt-get -s upgrade 2>/dev/null | grep -P '^\d+ upgraded' | awk '{print $1}')

    if [[ "$UPDATES" == "0" || -z "$UPDATES" ]]; then
        STATUS="[PASSED]"
        REMEDIATION="None required. System is up to date."
    else
        STATUS="[FAILED]"
        REMEDIATION="Run 'sudo apt-get update && sudo apt-get upgrade' to install $UPDATES pending updates."
    fi

elif command -v dnf &>/dev/null; then
    # RHEL/Rocky/Alma/Fedora system check (modern)
    dnf check-update -q >/dev/null 2>&1
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        STATUS="[PASSED]"
        REMEDIATION="None required. System is up to date."
    elif [ $EXIT_CODE -eq 100 ]; then
        STATUS="[FAILED]"
        REMEDIATION="Run 'sudo dnf upgrade' to install pending updates."
    else
        STATUS="[FAILED]"
        REMEDIATION="Error checking dnf updates. Verify network or repo configuration."
    fi

elif command -v yum &>/dev/null; then
    # Legacy RHEL/CentOS system check
    yum check-update -q >/dev/null 2>&1
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        STATUS="[PASSED]"
        REMEDIATION="None required. System is up to date."
    elif [ $EXIT_CODE -eq 100 ]; then
        STATUS="[FAILED]"
        REMEDIATION="Run 'sudo yum upgrade' to install pending updates."
    else
        STATUS="[FAILED]"
        REMEDIATION="Error checking yum updates. Verify network or repo configuration."
    fi

else
    STATUS="[FAILED]"
    REMEDIATION="Unsupported package manager. Please update your packages manually."
fi

# Print the formatted output
printf "ID: %s | %-10s | %s\n" "$ID" "$STATUS" "$DESCRIPTION"
echo "  Remediation: $REMEDIATION"
