#!/bin/bash

# ========================================================================
# SECTION 21: CORE OS HARDENING (UMASK, CRON, TMP, CORE DUMPS)
# ========================================================================

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

echo "=== SECTION 21: CORE OS HARDENING ==="

# --- Helper Functions (Standard Output) ---
check_custom() {
    local ID="$1"; local TITLE="$2"; local PASSED="$3"; local REM="$4"
    if [ "$PASSED" = true ]; then STAT="[PASSED]"; else STAT="[FAILED]"; fi
    printf "ID: %-10s | %-10s | %s\n  Remediation: %s\n" "$ID" "$STAT" "$TITLE" "$REM"
}

check_perm() {
    local ID="$1"; local FILE="$2"; local EXPECTED="$3"; local TITLE="Ensure permissions on $FILE are $EXPECTED"
    local REM="chmod $EXPECTED $FILE && chown root:root $FILE"
    if [ -e "$FILE" ]; then
        local CURRENT=$(stat -c "%a" "$FILE" 2>/dev/null)
        if [ "$CURRENT" == "$EXPECTED" ] || [ "0$CURRENT" == "$EXPECTED" ]; then STAT="[PASSED]"
        else STAT="[FAILED] (Found: $CURRENT)"; fi
    else
        STAT="[PASSED] (File missing)"
    fi
    printf "ID: %-10s | %-10s | %s\n  Remediation: %s\n" "$ID" "$STAT" "$TITLE" "$REM"
}

# ------------------------------------------------------------------------

echo "--- 21.1 DEFAULT UMASK ---"
# Check if bashrc or profile sets umask to 027
if grep -q "umask 027" /etc/bashrc 2>/dev/null || grep -q "umask 027" /etc/profile 2>/dev/null; then UMASK=true; else UMASK=false; fi
check_custom "21.1.1" "Ensure default user umask is 027" $UMASK "Add 'umask 027' to /etc/bashrc or /etc/profile to prevent world-readable file creation."

echo "--- 21.2 CORE DUMPS ---"
# Check sysctl for suid_dumpable
if sysctl kernel.core_pattern 2>/dev/null | grep -q "|/bin/false" || sysctl fs.suid_dumpable 2>/dev/null | grep -q "0"; then DUMP=true; else DUMP=false; fi
check_custom "21.2.1" "Ensure core dumps are restricted" $DUMP "Set 'fs.suid_dumpable = 0' in sysctl and set '* hard core 0' in /etc/security/limits.conf."

echo "--- 21.3 /TMP MOUNT OPTIONS ---"
TMP_MOUNT=$(findmnt -n -o OPTIONS /tmp 2>/dev/null)
if [[ "$TMP_MOUNT" == *"nodev"* && "$TMP_MOUNT" == *"nosuid"* && "$TMP_MOUNT" == *"noexec"* ]]; then TMP_SEC=true; else TMP_SEC=false; fi
check_custom "21.3.1" "Ensure /tmp has nodev, nosuid, noexec" $TMP_SEC "Configure /etc/fstab to mount /tmp as a separate partition with 'nodev,nosuid,noexec'."

echo "--- 21.4 RESTRICT 'SU' COMMAND ---"
if grep -q "pam_wheel.so use_uid" /etc/pam.d/su 2>/dev/null; then SU_RESTRICT=true; else SU_RESTRICT=false; fi
check_custom "21.4.1" "Ensure access to 'su' command is restricted" $SU_RESTRICT "Uncomment 'auth required pam_wheel.so use_uid' in /etc/pam.d/su so only admins can use su."

echo "--- 21.5 CRON SUBSYSTEM PERMISSIONS ---"
check_perm "21.5.1" "/etc/crontab" "600"
check_perm "21.5.2" "/etc/cron.hourly" "700"
check_perm "21.5.3" "/etc/cron.daily" "700"
check_perm "21.5.4" "/etc/cron.weekly" "700"
check_perm "21.5.5" "/etc/cron.monthly" "700"
check_perm "21.5.6" "/etc/cron.d" "700"

# Check cron.allow vs cron.deny
if [ -f "/etc/cron.allow" ] && [ ! -f "/etc/cron.deny" ]; then CRON_ACCESS=true; else CRON_ACCESS=false; fi
check_custom "21.5.7" "Ensure cron.allow exists and cron.deny is removed" $CRON_ACCESS "Run 'rm /etc/cron.deny' and 'touch /etc/cron.allow; chmod 600 /etc/cron.allow'."
