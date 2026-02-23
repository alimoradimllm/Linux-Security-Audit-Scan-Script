#!/bin/bash

# ==========================================
# Advanced SSH Crypto & Parameter Audit Script
# ==========================================

# Ensure the script is run as root to read the effective SSH config
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./ssh_crypto_check.sh)."
  exit 1
fi

echo "=== SECTION 5: SSH SERVER CONFIGURATION (ADVANCED) ==="

# Get the effective sshd configuration
SSHD_CONFIG=$(sshd -T 2>/dev/null)

if [ -z "$SSHD_CONFIG" ]; then
    echo "Error: Could not read SSH configuration."
    exit 1
fi

# ---------------------------------------------------------
# Check 5.2.1: Ensure weak Ciphers are disabled (No CBC, RC4, 3DES)
# ---------------------------------------------------------
ID="5.2.1     "
DESC="Ensure weak SSH Ciphers are disabled"

CIPHERS=$(echo "$SSHD_CONFIG" | grep -i "^ciphers " | awk '{print tolower($2)}')

if echo "$CIPHERS" | grep -E -q '(3des|cbc|rc4)'; then
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Edit /etc/ssh/sshd_config to use strong ciphers only (e.g., chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr)."
else
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Weak ciphers are disabled."
fi

# ---------------------------------------------------------
# Check 5.2.2: Ensure SSH LogLevel is INFO or VERBOSE
# ---------------------------------------------------------
ID="5.2.2     "
DESC="Ensure SSH LogLevel is INFO"

LOG_LEVEL=$(echo "$SSHD_CONFIG" | grep -i "^loglevel " | awk '{print toupper($2)}')

if [[ "$LOG_LEVEL" == "INFO" || "$LOG_LEVEL" == "VERBOSE" ]]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Logging is capturing authentication events."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Edit /etc/ssh/sshd_config, set 'LogLevel INFO', and restart sshd."
fi

# ---------------------------------------------------------
# Check 5.2.3: Ensure SSH X11Forwarding is disabled
# ---------------------------------------------------------
ID="5.2.3     "
DESC="Ensure SSH X11Forwarding is no"

X11_FWD=$(echo "$SSHD_CONFIG" | grep -i "^x11forwarding " | awk '{print tolower($2)}')

if [ "$X11_FWD" = "no" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. X11 Forwarding is disabled."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Edit /etc/ssh/sshd_config, set 'X11Forwarding no', and restart sshd."
fi

# ---------------------------------------------------------
# Check 5.2.4: Ensure weak Key Exchange (KEX) is disabled
# ---------------------------------------------------------
ID="5.2.4     "
DESC="Ensure weak SSH KexAlgorithms are disabled"

KEX=$(echo "$SSHD_CONFIG" | grep -i "^kexalgorithms " | awk '{print tolower($2)}')

if echo "$KEX" | grep -E -q '(sha1|group1-sha1)'; then
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Edit /etc/ssh/sshd_config to remove SHA1 based KEX (use curve25519-sha256, diffie-hellman-group16-sha512, etc.)."
else
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Weak key exchange algorithms are disabled."
fi

# ---------------------------------------------------------
# Check 5.2.5: Ensure weak MACs are disabled
# ---------------------------------------------------------
ID="5.2.5     "
DESC="Ensure weak SSH MACs are disabled"

MACS=$(echo "$SSHD_CONFIG" | grep -i "^macs " | awk '{print tolower($2)}')

if echo "$MACS" | grep -E -q '(md5|sha1)'; then
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Edit /etc/ssh/sshd_config to remove MD5 and SHA1 MACs (use hmac-sha2-512-etm@openssh.com, etc.)."
else
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Weak MACs are disabled."
fi
