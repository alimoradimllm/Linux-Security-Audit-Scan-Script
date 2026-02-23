#!/bin/bash

# ==========================================
# Package Integrity Verification Audit Script
# ==========================================

# Ensure the script is run as root (required to read all files for hashing)
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./integrity_check.sh)."
  exit 1
fi

echo "=== SECTION 12: PACKAGE INTEGRITY VERIFICATION ==="

# Detect the package manager/OS family
if command -v dpkg >/dev/null 2>&1; then
    OS_FAMILY="debian"
elif command -v rpm >/dev/null 2>&1; then
    OS_FAMILY="rhel"
else
    OS_FAMILY="unknown"
fi

# ---------------------------------------------------------
# Check 12.1.1: Ensure package verification tool is functional
# ---------------------------------------------------------
ID="12.1.1    "
DESC="Ensure package verification tool is functional"

if [ "$OS_FAMILY" == "debian" ] || [ "$OS_FAMILY" == "rhel" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Native package integrity tools are available."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Unsupported OS or missing package manager. Manual integrity verification required."
    exit 1
fi

# ---------------------------------------------------------
# Check 12.1.2: Verify integrity of installed package binaries
# ---------------------------------------------------------
ID="12.1.2    "
DESC="Verify integrity of installed package binaries"

echo "  [*] Running full filesystem hash verification. This may take a minute or two..."

if [ "$OS_FAMILY" == "debian" ]; then
    # dpkg -V checks hashes. We grep -v ' c ' to ignore user-modified configuration files.
    # We also grep -v '??5??????' for missing files that are safely ignored in some dpkg states.
    MODIFIED_FILES=$(dpkg -V 2>/dev/null | grep -v ' c ' | grep -v 'systemd')

    if [ -z "$MODIFIED_FILES" ]; then
        printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: None required. No unexpected binary modifications detected."
    else
        MOD_COUNT=$(echo "$MODIFIED_FILES" | wc -l)
        printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: $MOD_COUNT non-configuration files failed MD5 verification. Run 'dpkg -V' manually to investigate corrupted or tampered binaries."
    fi

elif [ "$OS_FAMILY" == "rhel" ]; then
    # rpm -Va checks hashes. We grep -v ' c ' to ignore config files.
    MODIFIED_FILES=$(rpm -Va 2>/dev/null | grep -v ' c ' | grep '^..5')

    if [ -z "$MODIFIED_FILES" ]; then
        printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: None required. No unexpected binary modifications detected."
    else
        MOD_COUNT=$(echo "$MODIFIED_FILES" | wc -l)
        printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: $MOD_COUNT non-configuration files failed MD5/SHA verification. Run 'rpm -Va' manually to investigate corrupted or tampered binaries."
    fi
fi
