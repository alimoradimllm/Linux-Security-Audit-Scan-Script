#!/bin/bash

# ==========================================
# Fail2Ban (Optional) Audit Script
# ==========================================

# Ensure the script is run as root to read fail2ban client and sshd config
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./fail2ban_check.sh)."
  exit 1
fi

echo "=== SECTION 13: FAIL2BAN (OPTIONAL) ==="

# ---------------------------------------------------------
# Check 13.1.1: Check if fail2ban is installed
# ---------------------------------------------------------
ID="13.1.1    "
DESC="Check if fail2ban is installed"

if command -v fail2ban-client >/dev/null 2>&1; then
    printf "ID: %s | [INFO]     | %s\n" "$ID" "$DESC"
    echo "  Remediation: fail2ban is installed on this system."
    F2B_INSTALLED=true
else
    printf "ID: %s | [INFO]     | %s\n" "$ID" "$DESC"
    echo "  Remediation: fail2ban is NOT installed. This is perfectly fine if you only use SSH with key-based authentication."
    F2B_INSTALLED=false
fi

# ---------------------------------------------------------
# Check 13.1.2: Check if fail2ban service is active
# ---------------------------------------------------------
ID="13.1.2    "
DESC="Check if fail2ban service is active"

if [ "$F2B_INSTALLED" = true ]; then
    if systemctl is-active fail2ban >/dev/null 2>&1; then
        printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: None required. fail2ban service is actively running."
    else
        printf "ID: %s | [WARNING]  | %s\n" "$ID" "$DESC"
        echo "  Remediation: fail2ban is installed but NOT running. Start it with 'systemctl start fail2ban' or remove the package."
    fi
fi

# ---------------------------------------------------------
# Check 13.1.3: Check active fail2ban jails
# ---------------------------------------------------------
ID="13.1.3    "
DESC="Check active fail2ban jails"

if [ "$F2B_INSTALLED" = true ] && systemctl is-active --quiet fail2ban; then
    JAILS=$(fail2ban-client status 2>/dev/null | grep "Jail list:" | sed -E 's/^[^:]+:[ \t]+//')

    if [ -n "$JAILS" ]; then
        printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: None required. Active jails: $JAILS"
    else
        printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: fail2ban is running but has NO active jails. Configure jails in /etc/fail2ban/jail.local."
    fi
fi

# ---------------------------------------------------------
# Check 13.1.4: Contextual Analysis (Is this Security Theater?)
# ---------------------------------------------------------
ID="13.1.4    "
DESC="Contextual Analysis: Is fail2ban necessary here?"

# Get the effective sshd configuration to check if passwords are disabled
SSHD_CONFIG=$(sshd -T 2>/dev/null)
PASS_AUTH=$(echo "$SSHD_CONFIG" | grep -i "^passwordauthentication " | awk '{print tolower($2)}')

if [ "$F2B_INSTALLED" = true ] && [ "$PASS_AUTH" = "no" ]; then
    # We flag this as an INFO notice based on the user's architectural philosophy
    printf "ID: %s | [INFO]     | %s\n" "$ID" "$DESC"
    echo "  Remediation: SSH password auth is DISABLED. If SSH is your only public service, fail2ban is security theater and wasting resources. Consider uninstalling it."
elif [ "$F2B_INSTALLED" = false ] && [ "$PASS_AUTH" = "yes" ]; then
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: SSH password auth is ENABLED and fail2ban is MISSING. Either disable passwords (preferred) or install fail2ban immediately to prevent brute force."
else
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Setup context looks logical based on your current configuration."
fi
