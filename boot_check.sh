#!/bin/bash

# ==========================================
# Boot Security Verification Audit Script
# ==========================================

# Ensure the script is run as root (required to read firmware vars and GRUB configs)
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./boot_check.sh)."
  exit 1
fi

echo "=== SECTION 14: BOOT SECURITY VERIFICATION ==="

# ---------------------------------------------------------
# Check 14.1.1: Check Boot Mode (UEFI vs Legacy BIOS)
# ---------------------------------------------------------
ID="14.1.1    "
DESC="Check firmware boot mode (UEFI/BIOS)"

if [ -d /sys/firmware/efi ]; then
    UEFI_MODE=true
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. System is booted in UEFI mode, which supports hardware-backed Secure Boot."
else
    UEFI_MODE=false
    # This is a WARNING rather than FAILED because legacy hardware or certain cloud instances might not support UEFI.
    printf "ID: %s | [WARNING]  | %s\n" "$ID" "$DESC"
    echo "  Remediation: System is booted in Legacy BIOS mode. Secure Boot is impossible. Consider migrating to UEFI if your hardware/hypervisor supports it."
fi

# ---------------------------------------------------------
# Check 14.1.2: Check if Secure Boot is actively enabled
# ---------------------------------------------------------
ID="14.1.2    "
DESC="Ensure Secure Boot is enabled"

if [ "$UEFI_MODE" = true ]; then
    if command -v mokutil >/dev/null 2>&1; then
        SB_STATE=$(mokutil --sb-state 2>/dev/null)

        if echo "$SB_STATE" | grep -qi "enabled"; then
            printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
            echo "  Remediation: None required. Hardware-level Secure Boot is enforcing kernel signatures."
        else
            printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
            echo "  Remediation: Secure Boot is disabled. You must reboot into your motherboard's UEFI/BIOS settings and enable it (ensure you are using a signed distro kernel)."
        fi
    else
        printf "ID: %s | [INFO]     | %s\n" "$ID" "$DESC"
        echo "  Remediation: The 'mokutil' package is missing. Install it ('apt install mokutil' or 'dnf install mokutil') to query Secure Boot state, or check manually in BIOS."
    fi
else
    printf "ID: %s | [INFO]     | %s\n" "$ID" "$DESC"
    echo "  Remediation: Skipping Secure Boot check because the system is running Legacy BIOS."
fi

# ---------------------------------------------------------
# Check 14.1.3: Ensure GRUB Bootloader Password is Set
# ---------------------------------------------------------
ID="14.1.3    "
DESC="Ensure GRUB bootloader is password protected"

# Look for PBKDF2 password hashes in standard GRUB configuration locations
GRUB_PW_FOUND=false

# We use find to locate the active grub.cfg just in case it's in an unusual EFI path
GRUB_PATHS=$(find /boot/grub /boot/grub2 /boot/efi/EFI -name "grub.cfg" 2>/dev/null)

for conf in $GRUB_PATHS; do
    if grep -qE "^password_pbkdf2" "$conf" 2>/dev/null || grep -qE "set superusers=" "$conf" 2>/dev/null; then
        GRUB_PW_FOUND=true
        break
    fi
done

if [ "$GRUB_PW_FOUND" = true ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. GRUB is protected, preventing unauthorized single-user mode access."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Run 'grub-mkpasswd-pbkdf2' to generate a hash, then configure 'set superusers' and 'password_pbkdf2' in /etc/grub.d/40_custom and update-grub."
fi
