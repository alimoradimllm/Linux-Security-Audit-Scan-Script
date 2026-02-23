#!/bin/bash

# ==========================================
# AppArmor MAC Audit Script
# ==========================================

# Ensure the script is run as root to read kernel security interfaces
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./apparmor_check.sh)."
  exit 1
fi

echo "=== SECTION 11: MANDATORY ACCESS CONTROL (APPARMOR) ==="

# Note: If this is a RHEL/CentOS system, SELinux is typically used instead of AppArmor.
if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" != "Disabled" ]; then
    echo "Note: This system appears to be using SELinux ($(getenforce)) instead of AppArmor."
    echo "AppArmor checks may fail or be inapplicable."
    echo "---------------------------------------------------------"
fi

# ---------------------------------------------------------
# Check 11.1.1: Ensure AppArmor is enabled in the kernel
# ---------------------------------------------------------
ID="11.1.1    "
DESC="Ensure AppArmor is enabled in the kernel"

if [ -f /sys/module/apparmor/parameters/enabled ] && grep -qi "y" /sys/module/apparmor/parameters/enabled; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. AppArmor kernel module is active."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Enable AppArmor in your bootloader (e.g., add 'apparmor=1 security=apparmor' to GRUB_CMDLINE_LINUX) and reboot."
fi

# ---------------------------------------------------------
# Check 11.1.2: Ensure AppArmor utilities are installed
# ---------------------------------------------------------
ID="11.1.2    "
DESC="Ensure AppArmor utilities are installed"

if command -v aa-status >/dev/null 2>&1; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. AppArmor user-space utilities are present."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Run 'apt-get install apparmor-utils' (Debian/Ubuntu) or equivalent for your distro."
fi

# ---------------------------------------------------------
# Check 11.1.3: Ensure AppArmor profiles are loaded
# ---------------------------------------------------------
ID="11.1.3    "
DESC="Ensure AppArmor profiles are loaded"

# We check the kernel interface directly to see how many profiles are actively loaded
if [ -d /sys/kernel/security/apparmor ]; then
    PROF_COUNT=$(cat /sys/kernel/security/apparmor/profiles 2>/dev/null | wc -l)

    if [ "$PROF_COUNT" -gt 0 ]; then
        printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: None required. $PROF_COUNT profiles are currently loaded into the kernel."
    else
        printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: Install 'apparmor-profiles' and run 'systemctl restart apparmor' to load baseline protections."
    fi
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: AppArmor securityfs is not mounted. Is AppArmor disabled?"
fi

# ---------------------------------------------------------
# Check 11.1.4: Check for profiles in Complain mode
# ---------------------------------------------------------
ID="11.1.4    "
DESC="Check for profiles in complain mode"

if [ -d /sys/kernel/security/apparmor ]; then
    # Profiles in complain mode are explicitly tagged in the profiles file
    COMPLAIN_COUNT=$(grep -c "complain" /sys/kernel/security/apparmor/profiles 2>/dev/null || echo 0)

    if [ "$COMPLAIN_COUNT" -eq 0 ]; then
        printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: None required. All loaded profiles are strictly enforcing."
    else
        printf "ID: %s | [WARNING]  | %s\n" "$ID" "$DESC"
        echo "  Remediation: $COMPLAIN_COUNT profiles are in 'complain' mode (logging only). Once you verify the logs, run 'aa-enforce <profile>' to lock them down."
    fi
fi
