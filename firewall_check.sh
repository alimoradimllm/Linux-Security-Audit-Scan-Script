
#!/bin/bash

# ==========================================
# Advanced Firewall (iptables/UFW) Audit Script
# ==========================================

# Ensure the script is run as root (required to read iptables rules)
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./firewall_check.sh)."
  exit 1
fi

echo "=== SECTION 10: FIREWALL CONFIGURATION (IPTABLES) ==="

# Check if iptables is available
if ! command -v iptables >/dev/null 2>&1; then
    echo "Error: iptables command not found. System may be using a different firewall engine entirely."
    exit 1
fi

# ---------------------------------------------------------
# Check 10.1.1: Ensure default INPUT policy is DROP or REJECT
# ---------------------------------------------------------
ID="10.1.1    "
DESC="Ensure default INPUT policy is DROP"

# Extract the policy inside the parentheses: e.g., Chain INPUT (policy DROP)
INPUT_POLICY=$(iptables -L INPUT -n | head -n 1 | awk '{print $4}' | tr -d ')')

# Sometimes tools like UFW use a catch-all DROP rule at the end instead of the default policy
CATCH_ALL_DROP=$(iptables -S INPUT 2>/dev/null | tail -n 1 | grep -E -- "-j DROP|-j REJECT")

if [ "$INPUT_POLICY" = "DROP" ] || [ "$INPUT_POLICY" = "REJECT" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Default INPUT policy is set to $INPUT_POLICY."
elif [ -n "$CATCH_ALL_DROP" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. A catch-all DROP/REJECT rule was found at the end of the INPUT chain."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Configure your firewall (e.g., 'ufw default deny incoming') to block unexpected connections."
fi

# ---------------------------------------------------------
# Check 10.1.2: Ensure default OUTPUT policy is ACCEPT
# ---------------------------------------------------------
ID="10.1.2    "
DESC="Ensure default OUTPUT policy is ACCEPT"

OUTPUT_POLICY=$(iptables -L OUTPUT -n | head -n 1 | awk '{print $4}' | tr -d ')')

if [ "$OUTPUT_POLICY" = "ACCEPT" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Default OUTPUT policy allows outbound traffic."
else
    printf "ID: %s | [WARNING]  | %s\n" "$ID" "$DESC"
    echo "  Remediation: Output policy is $OUTPUT_POLICY. This is highly secure but can break updates if not carefully managed. (Standard is 'ufw default allow outgoing')."
fi

# ---------------------------------------------------------
# Check 10.1.3: Ensure logging is enabled for dropped packets
# ---------------------------------------------------------
ID="10.1.3    "
DESC="Ensure firewall logging is enabled"

# Look for LOG or NFLOG targets in the iptables rules
LOGGING_ENABLED=$(iptables -S | grep -E "\-j LOG|\-j NFLOG")

if [ -n "$LOGGING_ENABLED" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Iptables logging rules are active."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Enable logging in your firewall manager (e.g., 'ufw logging on' or add an iptables -j LOG rule before dropping)."
fi

# ---------------------------------------------------------
# Check 10.1.4: Ensure stateful connection tracking is active
# ---------------------------------------------------------
ID="10.1.4    "
DESC="Ensure stateful tracking (ESTABLISHED,RELATED) is active"

# A secure firewall must allow return traffic for connections it initiated
STATEFUL=$(iptables -S | grep -i "state" | grep -E "ESTABLISHED|RELATED")

if [ -n "$STATEFUL" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Stateful connection tracking is configured."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Add a rule to allow established connections (e.g., iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT)."
fi
