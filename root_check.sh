#!/bin/bash

# ==========================================
# Disable Direct Root Login Audit Script
# ==========================================

# Ensure the script is run as root (required to read /etc/shadow and sudoers)
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./root_check.sh)."
  exit 1
fi

echo "=== SECTION 15: DISABLE DIRECT ROOT LOGIN ==="

# ---------------------------------------------------------
# Check 15.1.1: Ensure the root account password is locked
# ---------------------------------------------------------
ID="15.1.1    "
DESC="Ensure root account password is locked"

# Read the password hash field for root from /etc/shadow
ROOT_HASH=$(awk -F: '$1=="root" {print $2}' /etc/shadow 2>/dev/null)

# A hash starting with '!' or '*' means the account is locked and cannot be logged into with a password
if [[ "$ROOT_HASH" == "!"* ]] || [[ "$ROOT_HASH" == "*"* ]]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Root account password login is disabled."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: The root account has an active password. Run 'passwd -l root' to lock it."
fi

# ---------------------------------------------------------
# Check 15.1.2: Ensure 'sudo' is installed
# ---------------------------------------------------------
ID="15.1.2    "
DESC="Ensure 'sudo' is installed"

if command -v sudo >/dev/null 2>&1; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Sudo is available for privilege escalation."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Install sudo ('apt install sudo' or 'dnf install sudo') so users can elevate privileges."
fi

# ---------------------------------------------------------
# Check 15.1.3: Ensure at least one user has sudo privileges
# ---------------------------------------------------------
ID="15.1.3    "
DESC="Ensure at least one user is in sudo/wheel group"

# Debian/Ubuntu uses 'sudo', RHEL/CentOS uses 'wheel'. We check both.
ADMIN_USERS=$(getent group sudo wheel 2>/dev/null | awk -F: '{print $4}' | tr ',' '\n' | grep -v '^\s*$')

if [ -n "$ADMIN_USERS" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Users found with admin privileges: $(echo $ADMIN_USERS | tr '\n' ' ')"
else
    printf "ID: %s | [WARNING]  | %s\n" "$ID" "$DESC"
    echo "  Remediation: CRITICAL: No users found in the 'sudo' or 'wheel' groups! If you lock root now, you will lose admin access. Run 'usermod -aG sudo <username>' first."
fi

# ---------------------------------------------------------
# Check 15.1.4: Check for unrestricted NOPASSWD rules
# ---------------------------------------------------------
ID="15.1.4    "
DESC="Check for unrestricted NOPASSWD sudo rules"

# Look for NOPASSWD tags in the sudoers file and drop-in directory
NOPASSWD_RULES=$(grep -r -E "^[^#].*NOPASSWD" /etc/sudoers /etc/sudoers.d/ 2>/dev/null)

if [ -z "$NOPASSWD_RULES" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. All sudo commands require re-authentication."
else
    printf "ID: %s | [WARNING]  | %s\n" "$ID" "$DESC"
    echo "  Remediation: NOPASSWD directives found in sudoers. While sometimes used for automation, this bypasses the audit/security benefits of sudo for interactive users. Review /etc/sudoers."
fi
