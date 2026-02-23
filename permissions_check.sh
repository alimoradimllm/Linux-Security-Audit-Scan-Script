#!/bin/bash

# ==========================================
# Critical Files & Accounts Audit Script
# ==========================================

# Ensure the script is run as root to read /etc/shadow and stat files
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./permissions_check.sh)."
  exit 1
fi

echo "=== SECTION 19: CRITICAL FILES & ACCOUNTS ==="

# ---------------------------------------------------------
# Check 19.1.1: Ensure /etc/passwd permissions are configured correctly
# ---------------------------------------------------------
ID="19.1.1    "
DESC="Ensure /etc/passwd permissions are secure"

# We expect 644 (rw-r--r--) and root ownership
PASSWD_PERMS=$(stat -c "%a" /etc/passwd 2>/dev/null)
PASSWD_OWNER=$(stat -c "%U:%G" /etc/passwd 2>/dev/null)

if [ "$PASSWD_PERMS" -le 644 ] && [ "$PASSWD_OWNER" = "root:root" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. /etc/passwd permissions are secure."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Run 'chown root:root /etc/passwd' and 'chmod 644 /etc/passwd'."
fi

# ---------------------------------------------------------
# Check 19.1.2: Ensure /etc/shadow permissions are strictly locked down
# ---------------------------------------------------------
ID="19.1.2    "
DESC="Ensure /etc/shadow permissions are secure"

# We expect 000, 600, or 640 (depending on distro) and root/shadow ownership
SHADOW_PERMS=$(stat -c "%a" /etc/shadow 2>/dev/null)
SHADOW_OWNER=$(stat -c "%U:%G" /etc/shadow 2>/dev/null)

if [ "$SHADOW_PERMS" = "0" ] || [ "$SHADOW_PERMS" = "000" ] || [ "$SHADOW_PERMS" = "600" ] || [ "$SHADOW_PERMS" = "640" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. /etc/shadow is locked down ($SHADOW_PERMS)."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: /etc/shadow is too permissive ($SHADOW_PERMS). Run 'chmod 640 /etc/shadow' (or 600) immediately."
fi

# ---------------------------------------------------------
# Check 19.1.3: Ensure no rogue UID 0 (root) accounts exist
# ---------------------------------------------------------
ID="19.1.3    "
DESC="Ensure only 'root' has UID 0"

# Find any users in /etc/passwd with a UID of 0
UID_ZERO_USERS=$(awk -F: '($3 == "0") {print $1}' /etc/passwd 2>/dev/null)

if [ "$UID_ZERO_USERS" = "root" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Only the default root account has UID 0."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    # Format the users onto a single line for display
    ROGUE_USERS=$(echo "$UID_ZERO_USERS" | grep -v "root" | tr '\n' ' ')
    echo "  Remediation: CRITICAL! Rogue root accounts found: ${ROGUE_USERS}. Investigate and remove these accounts immediately."
fi

# ---------------------------------------------------------
# Check 19.1.4: Ensure no accounts have empty passwords
# ---------------------------------------------------------
ID="19.1.4    "
DESC="Ensure no accounts have empty passwords"

# Look for empty password fields in /etc/shadow
EMPTY_PASSWORDS=$(awk -F: '($2 == "") {print $1}' /etc/shadow 2>/dev/null)

if [ -z "$EMPTY_PASSWORDS" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. No accounts with blank passwords found."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    BAD_USERS=$(echo "$EMPTY_PASSWORDS" | tr '\n' ' ')
    echo "  Remediation: Accounts with empty passwords found: ${BAD_USERS}. Lock these accounts or set strong passwords immediately."
fi
