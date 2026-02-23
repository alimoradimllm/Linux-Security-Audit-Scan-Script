#!/bin/bash

# ==========================================
# Audit Logging (auditd) Check Script
# ==========================================

# Ensure the script is run as root (auditctl requires root privileges)
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./auditd_check.sh)"
  exit 1
fi

echo "=== SECTION 4: AUDIT LOGGING (AUDITD) ==="

# ---------------------------------------------------------
# Check 4.1.1: Ensure auditd is installed
# ---------------------------------------------------------
ID="4.1.1     "
DESC="Ensure auditd is installed"

if command -v auditd >/dev/null 2>&1 || command -v auditctl >/dev/null 2>&1; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Package is installed."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Install auditd (e.g., 'apt-get install auditd' or 'dnf install audit')."
fi

# ---------------------------------------------------------
# Check 4.1.2: Ensure auditd service is enabled
# ---------------------------------------------------------
ID="4.1.2     "
DESC="Ensure auditd service is enabled"

if systemctl is-enabled auditd >/dev/null 2>&1; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Service is configured to start on boot."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Run 'systemctl enable auditd' to ensure it starts on boot."
fi

# ---------------------------------------------------------
# Check 4.1.3: Ensure auditd service is active
# ---------------------------------------------------------
ID="4.1.3     "
DESC="Ensure auditd service is active"

if systemctl is-active auditd >/dev/null 2>&1; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Service is actively running."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Run 'systemctl start auditd' to start the service."
fi

# ---------------------------------------------------------
# Check 4.1.4: Ensure audit rules are configured
# ---------------------------------------------------------
ID="4.1.4     "
DESC="Ensure audit rules are configured"

# auditctl -l outputs "No rules" if the rule list is empty
if auditctl -l 2>/dev/null | grep -qi "No rules"; then
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Add rules to /etc/audit/rules.d/ (e.g., to log failed logins or sudo usage) and run 'augenrules --load'."
elif [ $(auditctl -l 2>/dev/null | wc -l) -gt 0 ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Audit rules are loaded into the kernel."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Unable to verify rules or auditd is not running."
fi
