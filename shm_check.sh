#!/bin/bash

# ==========================================
# Shared Memory Security Audit Script
# ==========================================

echo "=== SECTION 6: SHARED MEMORY SECURITY ==="

# Get the current mount options for /dev/shm
# Using findmnt is more reliable than parsing the mount command
SHM_OPTS=$(findmnt -n -o OPTIONS /dev/shm 2>/dev/null)

# If we can't find /dev/shm, it might not be mounted or the system is unusual
if [ -z "$SHM_OPTS" ]; then
    echo "Error: Could not determine mount options for /dev/shm."
    exit 1
fi

# ---------------------------------------------------------
# Check 6.1.1: Ensure /dev/shm is mounted with nodev
# ---------------------------------------------------------
ID="6.1.1     "
DESC="Ensure /dev/shm is mounted with nodev"

if echo "$SHM_OPTS" | grep -q '\bnodev\b'; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Device file creation is blocked."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Add or update /dev/shm in /etc/fstab to include 'nodev' in mount options, then run 'mount -o remount /dev/shm'."
fi

# ---------------------------------------------------------
# Check 6.1.2: Ensure /dev/shm is mounted with nosuid
# ---------------------------------------------------------
ID="6.1.2     "
DESC="Ensure /dev/shm is mounted with nosuid"

if echo "$SHM_OPTS" | grep -q '\bnosuid\b'; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. SUID bit execution is blocked."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Add or update /dev/shm in /etc/fstab to include 'nosuid' in mount options, then run 'mount -o remount /dev/shm'."
fi

# ---------------------------------------------------------
# Check 6.1.3: Ensure /dev/shm is mounted with noexec
# ---------------------------------------------------------
ID="6.1.3     "
DESC="Ensure /dev/shm is mounted with noexec (Servers)"

if echo "$SHM_OPTS" | grep -q '\bnoexec\b'; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Program execution from shared memory is blocked."
else
    # We flag this as a WARNING rather than an outright FAILED because of the desktop/browser caveat
    printf "ID: %s | [WARNING]  | %s\n" "$ID" "$DESC"
    echo "  Remediation: If this is a SERVER, add 'noexec' to /etc/fstab for /dev/shm and remount. If this is a DESKTOP, leave as is (noexec breaks browsers like Chrome/Firefox)."
fi
