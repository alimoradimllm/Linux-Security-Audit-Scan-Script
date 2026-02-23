#!/bin/bash

# ==========================================
# Password Policy Configuration Audit Script
# ==========================================

# Ensure the script is run as root to read security files
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./password_check.sh)."
  exit 1
fi

echo "=== SECTION 8: PASSWORD POLICY CONFIGURATION ==="

# ---------------------------------------------------------
# Check 8.1.1: Ensure minimum password length is 12+
# ---------------------------------------------------------
ID="8.1.1     "
DESC="Ensure minimum password length is 12+"

# Check pwquality.conf first, fallback to login.defs
MIN_LEN=$(grep -E '^ *minlen' /etc/security/pwquality.conf 2>/dev/null | grep -o '[0-9]*' | head -n 1)

if [ -z "$MIN_LEN" ]; then
    MIN_LEN=$(grep -E '^ *PASS_MIN_LEN' /etc/login.defs 2>/dev/null | awk '{print $2}')
fi

# Default to 0 if we couldn't find a setting
MIN_LEN=${MIN_LEN:-0}

if [ "$MIN_LEN" -ge 12 ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Minimum length is set to $MIN_LEN."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Edit /etc/security/pwquality.conf to set 'minlen = 14' (or edit PASS_MIN_LEN in /etc/login.defs)."
fi

# ---------------------------------------------------------
# Check 8.1.2: Ensure password complexity is required
# ---------------------------------------------------------
ID="8.1.2     "
DESC="Ensure password complexity is configured"

# Look for minclass (requires N different character classes) or specific credit requirements
COMPLEX_CLASS=$(grep -E '^ *minclass' /etc/security/pwquality.conf 2>/dev/null | grep -o '[0-9]*' | head -n 1)
CREDITS=$(grep -E '^ *(dcredit|ucredit|lcredit|ocredit)' /etc/security/pwquality.conf 2>/dev/null)

if [ -n "$COMPLEX_CLASS" ] && [ "$COMPLEX_CLASS" -ge 3 ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Password complexity (minclass) is configured."
elif [ -n "$CREDITS" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Password complexity (credits) is configured."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Edit /etc/security/pwquality.conf and set 'minclass = 3' or configure specific character credits."
fi

# ---------------------------------------------------------
# Check 8.1.3: Ensure password history is enforced
# ---------------------------------------------------------
ID="8.1.3     "
DESC="Ensure password history prevents reuse"

# Check PAM files for remember=X or pam_pwhistory.so
HISTORY_CHECK=$(grep -E -i 'remember=[0-9]+|pam_pwhistory\.so' /etc/pam.d/common-password /etc/pam.d/system-auth /etc/pam.d/password-auth 2>/dev/null)

if [ -n "$HISTORY_CHECK" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Password history is being tracked."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Configure pam_pwhistory.so in your PAM password files to remember at least 5 previous passwords."
fi

# ---------------------------------------------------------
# Check 8.1.4: Ensure account lockout after failed attempts
# ---------------------------------------------------------
ID="8.1.4     "
DESC="Ensure account lockout on failed logins"

# Check PAM files for faillock or tally2
LOCKOUT_CHECK=$(grep -E -i 'pam_faillock\.so|pam_tally2\.so' /etc/pam.d/common-auth /etc/pam.d/system-auth /etc/pam.d/password-auth 2>/dev/null)

if [ -n "$LOCKOUT_CHECK" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Account lockout module (faillock/tally2) is present."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Configure pam_faillock.so in your PAM authentication files to lock accounts after N failed attempts."
fi
