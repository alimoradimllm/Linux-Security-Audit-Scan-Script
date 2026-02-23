#!/bin/bash

# ==========================================
# USB Device Protection Audit Script
# ==========================================

# Ensure the script is run as root to read kernel module configs and systemd states
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./usb_check.sh)."
  exit 1
fi

echo "=== SECTION 17: USB DEVICE PROTECTION ==="

# ---------------------------------------------------------
# Check 17.1.1: Ensure 'usb-storage' kernel module is disabled
# ---------------------------------------------------------
ID="17.1.1    "
DESC="Ensure usb-storage kernel module is disabled"

# Check if the module is loaded in the running kernel
MODULE_LOADED=$(lsmod | grep -i "^usb_storage")

# Check if it's explicitly disabled/blacklisted in modprobe.d
MODULE_DISABLED=$(modprobe --showconfig 2>/dev/null | grep -E "^install usb-storage /bin/(true|false)")

if [ -n "$MODULE_DISABLED" ] && [ -z "$MODULE_LOADED" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. USB storage module is disabled via modprobe."
elif [ -n "$MODULE_LOADED" ]; then
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: The usb-storage module is currently LOADED. Run 'modprobe -r usb-storage' and configure a blacklist."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Create a file at /etc/modprobe.d/usb-storage.conf containing 'install usb-storage /bin/true' to prevent loading."
fi

# ---------------------------------------------------------
# Check 17.1.2: Ensure auto-mounting services are disabled
# ---------------------------------------------------------
ID="17.1.2    "
DESC="Ensure auto-mounting services (autofs) are inactive"

# autofs is the most common auto-mounting daemon on Linux servers
if systemctl is-active autofs >/dev/null 2>&1 || systemctl is-enabled autofs >/dev/null 2>&1; then
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: The 'autofs' service is active or enabled. Run 'systemctl disable --now autofs' to prevent auto-mounting."
else
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. No standard auto-mounting service (autofs) is active."
fi

# ---------------------------------------------------------
# Check 17.1.3: Desktop Environments Auto-mounting Warning
# ---------------------------------------------------------
ID="17.1.3    "
DESC="Check for Desktop Environment auto-mounters"

# If a desktop environment is installed, udisks2 is usually handling auto-mounting
if pgrep -x "udisksd" >/dev/null 2>&1; then
    printf "ID: %s | [WARNING]  | %s\n" "$ID" "$DESC"
    echo "  Remediation: The 'udisks2' daemon is running (common on GUI desktops). This may automatically mount USBs. For strict server security, consider removing GUI packages or masking udisks2."
else
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. No udisksd daemon detected."
fi
