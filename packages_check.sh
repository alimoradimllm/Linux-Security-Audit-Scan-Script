#!/bin/bash

# ==========================================
# Unnecessary Packages Audit Script
# ==========================================

# Ensure the script is run as root for consistent PATH and systemctl access
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./packages_check.sh)."
  exit 1
fi

echo "=== SECTION 16: REMOVE UNNECESSARY PACKAGES ==="

# ---------------------------------------------------------
# Check 16.1.1: Check for compilers and build tools
# ---------------------------------------------------------
ID="16.1.1    "
DESC="Check for compilers and build tools"

FOUND_COMPILERS=""
for pkg in gcc g++ make clang rustc; do
    if command -v $pkg >/dev/null 2>&1; then
        FOUND_COMPILERS="$FOUND_COMPILERS $pkg"
    fi
done

if [ -z "$FOUND_COMPILERS" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. No common compilers found in PATH."
else
    # We flag this as a WARNING, as dev/staging servers might legitimately need these.
    printf "ID: %s | [WARNING]  | %s\n" "$ID" "$DESC"
    echo "  Remediation: Compilers found:${FOUND_COMPILERS}. If this is a PRODUCTION server, remove them to hinder local exploit compilation."
fi

# ---------------------------------------------------------
# Check 16.1.2: Check for legacy/insecure network services
# ---------------------------------------------------------
ID="16.1.2    "
DESC="Check for legacy/insecure network services"

FOUND_SERVICES=""
# Check if common legacy daemon packages are installed/configured via systemd
for svc in telnetd ftpd rsh-server rsh-redone-server inetd xinetd; do
    if systemctl list-unit-files 2>/dev/null | grep -iq "^${svc}\."; then
        FOUND_SERVICES="$FOUND_SERVICES $svc"
    fi
done

if [ -z "$FOUND_SERVICES" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. No common insecure legacy daemons detected."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Insecure services found:${FOUND_SERVICES}. Disable and remove these packages immediately."
fi

# ---------------------------------------------------------
# Check 16.1.3: Check for unnecessary network utilities
# ---------------------------------------------------------
ID="16.1.3    "
DESC="Check for unnecessary network utilities"

FOUND_UTILS=""
for util in telnet ftp nmap nc netcat tcpdump tftp; do
    if command -v $util >/dev/null 2>&1; then
        FOUND_UTILS="$FOUND_UTILS $util"
    fi
done

if [ -z "$FOUND_UTILS" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. No unnecessary network pivoting utilities found."
else
    printf "ID: %s | [WARNING]  | %s\n" "$ID" "$DESC"
    echo "  Remediation: Utilities found:${FOUND_UTILS}. Attackers use these to pivot or exfiltrate data. Consider removing them if not explicitly required."
fi
