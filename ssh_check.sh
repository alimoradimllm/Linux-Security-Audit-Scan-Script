#!/bin/bash

# ==========================================
# SSH Hardening Audit Script
# ==========================================

# Ensure the script is run as root (sshd -T usually requires root to read host keys)
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./ssh_check.sh) to read the effective SSH config."
  exit 1
fi

echo "=== SECTION 5: SSH SERVER CONFIGURATION ==="

# Get the effective sshd configuration
# We use 'sshd -T' because it evaluates all defaults and 'Include' files
SSHD_CONFIG=$(sshd -T 2>/dev/null)

if [ -z "$SSHD_CONFIG" ]; then
    echo "Error: Could not read SSH configuration. Is OpenSSH server installed?"
    exit 1
fi

# ---------------------------------------------------------
# Check 5.1.1: Ensure PasswordAuthentication is disabled
# ---------------------------------------------------------
ID="5.1.1     "
DESC="Ensure SSH PasswordAuthentication is disabled"

# Extract the value, convert to lowercase just in case
PASS_AUTH=$(echo "$SSHD_CONFIG" | grep -i "^passwordauthentication " | awk '{print tolower($2)}')

if [ "$PASS_AUTH" = "no" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Password authentication is disabled."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Edit /etc/ssh/sshd_config, set 'PasswordAuthentication no', and restart sshd. (WARNING: Ensure key-based auth works first!)"
fi

# ---------------------------------------------------------
# Check 5.1.2: Ensure PermitRootLogin is disabled
# ---------------------------------------------------------
ID="5.1.2     "
DESC="Ensure SSH PermitRootLogin is disabled"

ROOT_LOGIN=$(echo "$SSHD_CONFIG" | grep -i "^permitrootlogin " | awk '{print tolower($2)}')

if [ "$ROOT_LOGIN" = "no" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Direct root login is disabled."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Edit /etc/ssh/sshd_config, set 'PermitRootLogin no', and restart sshd."
fi

# ---------------------------------------------------------
# Check 5.1.3: Check if SSH is on a non-standard port
# ---------------------------------------------------------
ID="5.1.3     "
DESC="Check if SSH is on a non-standard port (Optional)"

SSH_PORT=$(echo "$SSHD_CONFIG" | grep -i "^port " | awk '{print $2}')

if [ "$SSH_PORT" != "22" ] && [ -n "$SSH_PORT" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. SSH is running on port $SSH_PORT, reducing automated noise."
else
    printf "ID: %s | [WARNING]  | %s\n" "$ID" "$DESC"
    echo "  Remediation: Optional: Edit /etc/ssh/sshd_config to change 'Port 22' to a non-standard port to reduce log noise."
fi
