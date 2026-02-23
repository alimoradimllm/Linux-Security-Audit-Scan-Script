#!/bin/bash

# ==========================================
# Kernel Parameter Hardening Audit Script
# ==========================================

# Ensure the script is run as root (sysctl reads are safer as root)
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./kernel_check.sh)."
  exit 1
fi

echo "=== SECTION 7: KERNEL PARAMETER HARDENING ==="

# ---------------------------------------------------------
# Check 7.1.1: Address Space Layout Randomization (ASLR)
# ---------------------------------------------------------
ID="7.1.1     "
DESC="Ensure ASLR is fully enabled"
VAL=$(sysctl -n kernel.randomize_va_space 2>/dev/null)

if [ "$VAL" = "2" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. ASLR is fully enabled."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Set 'kernel.randomize_va_space = 2' in /etc/sysctl.d/99-security.conf and run 'sysctl -p'."
fi

# ---------------------------------------------------------
# Check 7.1.2: SYN Cookies (tcp_syncookies)
# ---------------------------------------------------------
ID="7.1.2     "
DESC="Ensure TCP SYN Cookies are enabled"
VAL=$(sysctl -n net.ipv4.tcp_syncookies 2>/dev/null)

if [ "$VAL" = "1" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. SYN flood protection is active."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Set 'net.ipv4.tcp_syncookies = 1' in /etc/sysctl.d/99-security.conf and run 'sysctl -p'."
fi

# ---------------------------------------------------------
# Check 7.1.3: ICMP Redirect Acceptance
# ---------------------------------------------------------
ID="7.1.3     "
DESC="Ensure ICMP redirects are not accepted"
VAL_ALL=$(sysctl -n net.ipv4.conf.all.accept_redirects 2>/dev/null)
VAL_DEF=$(sysctl -n net.ipv4.conf.default.accept_redirects 2>/dev/null)

if [ "$VAL_ALL" = "0" ] && [ "$VAL_DEF" = "0" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Malicious routing table manipulation is blocked."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Set 'net.ipv4.conf.all.accept_redirects = 0' and 'net.ipv4.conf.default.accept_redirects = 0' in /etc/sysctl.d/99-security.conf."
fi

# ---------------------------------------------------------
# Check 7.1.4: Source Routing
# ---------------------------------------------------------
ID="7.1.4     "
DESC="Ensure source routed packets are not accepted"
VAL_ALL=$(sysctl -n net.ipv4.conf.all.accept_source_route 2>/dev/null)
VAL_DEF=$(sysctl -n net.ipv4.conf.default.accept_source_route 2>/dev/null)

if [ "$VAL_ALL" = "0" ] && [ "$VAL_DEF" = "0" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Source routing is disabled."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Set 'net.ipv4.conf.all.accept_source_route = 0' and 'net.ipv4.conf.default.accept_source_route = 0' in /etc/sysctl.d/99-security.conf."
fi

# ---------------------------------------------------------
# Check 7.1.5: Martian Packet Logging
# ---------------------------------------------------------
ID="7.1.5     "
DESC="Ensure suspicious packets are logged (Martians)"
VAL_ALL=$(sysctl -n net.ipv4.conf.all.log_martians 2>/dev/null)
VAL_DEF=$(sysctl -n net.ipv4.conf.default.log_martians 2>/dev/null)

if [ "$VAL_ALL" = "1" ] && [ "$VAL_DEF" = "1" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Martian packet logging is enabled."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Set 'net.ipv4.conf.all.log_martians = 1' and 'net.ipv4.conf.default.log_martians = 1' in /etc/sysctl.d/99-security.conf."
fi

# ---------------------------------------------------------
# Check 7.1.6: IP Forwarding (Docker-Aware)
# ---------------------------------------------------------
ID="7.1.6     "
DESC="Ensure IP forwarding is securely configured"
VAL=$(sysctl -n net.ipv4.ip_forward 2>/dev/null)

# Check if Docker is installed and running
DOCKER_ACTIVE=false
if command -v docker >/dev/null 2>&1 && systemctl is-active --quiet docker; then
    DOCKER_ACTIVE=true
fi

if [ "$VAL" = "0" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. IP forwarding is disabled."
elif [ "$VAL" = "1" ] && [ "$DOCKER_ACTIVE" = true ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. IP forwarding is enabled, but Docker is detected (Required for containers)."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Set 'net.ipv4.ip_forward = 0' in /etc/sysctl.d/99-security.conf (Unless this server is a router)."
fi
