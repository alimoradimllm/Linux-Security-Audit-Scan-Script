#!/bin/bash

# ==========================================
# Unused Filesystems Audit Script
# ==========================================

# Ensure the script is run as root to read kernel module configs
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./fs_check.sh)."
  exit 1
fi

echo "=== SECTION 18: UNUSED FILESYSTEMS ==="

# Define the list of exotic/legacy filesystems to check
FILESYSTEMS="cramfs freevxfs jffs2 hfs hfsplus udf"
ID_NUM=1

for fs in $FILESYSTEMS; do
    # Format the ID to match our standard 10-character padding
    ID=$(printf "18.1.%-4s" "$ID_NUM")
    DESC="Ensure '$fs' filesystem is disabled"

    # Check if it's loaded in the running kernel
    MODULE_LOADED=$(lsmod | grep -iw "^$fs")

    # Check if it's explicitly disabled/blacklisted in modprobe.d
    # CIS Benchmarks require routing the install command to /bin/true or /bin/false
    MODULE_DISABLED=$(modprobe --showconfig 2>/dev/null | grep -E "^install $fs /bin/(true|false)")

    if [ -n "$MODULE_DISABLED" ] && [ -z "$MODULE_LOADED" ]; then
        printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: None required. The $fs module is disabled via modprobe."
    elif [ -n "$MODULE_LOADED" ]; then
        printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: The $fs module is currently LOADED in memory. Run 'rmmod $fs' and blacklist it."
    else
        printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: Create a file at /etc/modprobe.d/disable-fs.conf and add 'install $fs /bin/true'."
    fi

    ((ID_NUM++))
done
