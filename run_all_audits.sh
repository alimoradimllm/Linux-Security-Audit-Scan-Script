#!/bin/bash

# ========================================================================
# CIS ULTIMATE SERVER SECURITY AUDIT - MASTER RUNNER
# ========================================================================

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this master script as root (sudo ./run_all_audits.sh)."
  exit 1
fi

REPORT_FILE="Ultimate_Security_Report_$(date +%Y%m%d_%H%M).txt"

# Initialize the report file
> "$REPORT_FILE"
echo "========================================================================" >> "$REPORT_FILE"
echo "                 CIS ULTIMATE SERVER SECURITY AUDIT                     " >> "$REPORT_FILE"
echo "========================================================================" >> "$REPORT_FILE"
echo "Date Executed : $(date)" >> "$REPORT_FILE"
echo "Hostname      : $(hostname)" >> "$REPORT_FILE"
echo "Kernel        : $(uname -r)" >> "$REPORT_FILE"
echo "========================================================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# List of all the scripts we created, in chronological order
SCRIPTS=(
    "update_check.sh"
    "autoupdate_check.sh"
    "auditd_check.sh"
    "ssh_check.sh"
    "ssh_crypto_check.sh"
    "shm_check.sh"
    "kernel_check.sh"
    "password_check.sh"
    "time_check.sh"
    "firewall_check.sh"
    "apparmor_check.sh"
    "integrity_check.sh"
    "fail2ban_check.sh"
    "boot_check.sh"
    "root_check.sh"
    "packages_check.sh"
    "usb_check.sh"
    "fs_check.sh"
    "permissions_check.sh"
    "cis_additional_checks.sh"
    "core_hardening_check.sh"
)

echo "Starting Ultimate Server Audit..."
echo "Report will be saved to: $REPORT_FILE"
echo "---------------------------------------------------"

# Loop through each script and execute it
for script in "${SCRIPTS[@]}"; do
    if [ -f "./$script" ]; then
        if [ -x "./$script" ]; then
            echo "[*] Executing module: $script"
            # Run the script and append output to the report
            ./"$script" >> "$REPORT_FILE"
            # Add a blank line between sections for readability
            echo "" >> "$REPORT_FILE"
        else
            echo "[!] Warning: $script exists but is not executable. Fixing permissions and running..."
            chmod +x "./$script"
            ./"$script" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        fi
    else
        echo "[-] Error: Module $script not found in current directory. Skipping."
        echo "=== MISSING MODULE: $script ===" >> "$REPORT_FILE"
        echo "Error: The script $script was not found in the execution directory." >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
done

# ------------------------------------------------------------------------
# TALLY THE RESULTS
# ------------------------------------------------------------------------

echo "========================================================================" >> "$REPORT_FILE"
echo "                       FINAL AUDIT SUMMARY                              " >> "$REPORT_FILE"
echo "========================================================================" >> "$REPORT_FILE"

# Count the occurrences of PASSED, FAILED, and WARNING
TOTAL_PASSED=$(grep -c "\[PASSED\]" "$REPORT_FILE")
TOTAL_FAILED=$(grep -c "\[FAILED\]" "$REPORT_FILE")
TOTAL_WARNING=$(grep -c "\[WARNING\]" "$REPORT_FILE")
TOTAL_INFO=$(grep -c "\[INFO\]" "$REPORT_FILE")

echo "Total [PASSED] Checks  : $TOTAL_PASSED" >> "$REPORT_FILE"
echo "Total [FAILED] Checks  : $TOTAL_FAILED" >> "$REPORT_FILE"
echo "Total [WARNING] Checks : $TOTAL_WARNING" >> "$REPORT_FILE"
echo "Total [INFO] Notices   : $TOTAL_INFO" >> "$REPORT_FILE"
echo "========================================================================" >> "$REPORT_FILE"

echo "---------------------------------------------------"
echo "Audit Complete! All 19 sections processed."
echo "Results:"
echo "  Passed  : $TOTAL_PASSED"
echo "  Failed  : $TOTAL_FAILED"
echo "  Warnings: $TOTAL_WARNING"
echo ""
echo "Please view the full details in: $REPORT_FILE"
