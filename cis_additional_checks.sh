#!/bin/bash

# ========================================================================
# SECTION 20: ADDITIONAL CIS BENCHMARK CHECKS
# ========================================================================

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "=== SECTION 20: ADDITIONAL STRICT CIS BENCHMARKS ==="

# --- Helper Functions (Modified to print to standard output) ---

check_module() {
    local ID="$1"; local MOD="$2"; local TITLE="Ensure $MOD is disabled"
    local REM="echo 'install $MOD /bin/true' >> /etc/modprobe.d/cis.conf"

    if modprobe -n -v "$MOD" 2>/dev/null | grep -q "install /bin/true"; then
        STAT="[PASSED]"
    else
        STAT="[FAILED]"
    fi
    printf "ID: %-10s | %-10s | %s\n  Remediation: %s\n" "$ID" "$STAT" "$TITLE" "$REM"
}

check_sysctl() {
    local ID="$1"; local PARAM="$2"; local EXPECTED="$3"
    local TITLE="Ensure $PARAM is set to $EXPECTED"
    local REM="sysctl -w $PARAM=$EXPECTED && echo '$PARAM=$EXPECTED' >> /etc/sysctl.d/99-cis.conf"

    local CURRENT=$(sysctl -n "$PARAM" 2>/dev/null)
    if [ "$CURRENT" == "$EXPECTED" ]; then
        STAT="[PASSED]"
    else
        STAT="[FAILED]"
    fi
    printf "ID: %-10s | %-10s | %s\n  Remediation: %s\n" "$ID" "$STAT" "$TITLE" "$REM"
}

check_service() {
    local ID="$1"; local SVC="$2"; local STATE="$3" # "disabled" or "enabled"
    local TITLE="Ensure $SVC is $STATE"
    local REM="systemctl $STATE --now $SVC"

    local IS_ENABLED=$(systemctl is-enabled "$SVC" 2>/dev/null)
    if [ "$STATE" == "disabled" ]; then
        [[ "$IS_ENABLED" == "disabled" || "$IS_ENABLED" == "masked" || -z "$IS_ENABLED" ]] && STAT="[PASSED]" || STAT="[FAILED]"
    else
        [[ "$IS_ENABLED" == "enabled" ]] && STAT="[PASSED]" || STAT="[FAILED]"
    fi
    printf "ID: %-10s | %-10s | %s\n  Remediation: %s\n" "$ID" "$STAT" "$TITLE" "$REM"
}

check_sshd() {
    local ID="$1"; local PARAM="$2"; local EXPECTED="$3"
    local TITLE="Ensure SSH $PARAM is $EXPECTED"
    local REM="Edit /etc/ssh/sshd_config, set '$PARAM $EXPECTED', restart sshd"

    local CURRENT=$(sshd -T 2>/dev/null | grep -i "^$PARAM " | awk '{print $2}')
    if [[ "${CURRENT,,}" == "${EXPECTED,,}" ]]; then
        STAT="[PASSED]"
    else
        STAT="[FAILED]"
    fi
    printf "ID: %-10s | %-10s | %s\n  Remediation: %s\n" "$ID" "$STAT" "$TITLE" "$REM"
}

check_perm() {
    local ID="$1"; local FILE="$2"; local EXPECTED="$3"
    local TITLE="Ensure permissions on $FILE are $EXPECTED"
    local REM="chmod $EXPECTED $FILE"

    if [ -e "$FILE" ]; then
        local CURRENT=$(stat -c "%a" "$FILE" 2>/dev/null)
        if [ "$CURRENT" == "$EXPECTED" ] || [ "0$CURRENT" == "$EXPECTED" ]; then
            STAT="[PASSED]"
        else
            STAT="[FAILED] (Found: $CURRENT)"
        fi
    else
        STAT="[PASSED] (File missing)"
    fi
    printf "ID: %-10s | %-10s | %s\n  Remediation: %s\n" "$ID" "$STAT" "$TITLE" "$REM"
}

# --- Executing the Checks ---

echo "--- 20.1 FILESYSTEMS & MODULES ---"
check_module "1.1.1.1" "cramfs"
check_module "1.1.1.2" "freevxfs"
check_module "1.1.1.3" "jffs2"
check_module "1.1.1.4" "hfs"
check_module "1.1.1.5" "hfsplus"
check_module "1.1.1.6" "squashfs"
check_module "1.1.1.7" "udf"
check_module "1.1.1.8" "usb-storage"

echo "--- 20.2 SELINUX ---"
if [ "$(getenforce 2>/dev/null)" == "Enforcing" ]; then
    printf "ID: 1.6.1.2    | [PASSED]   | Ensure SELinux is enforcing\n  Remediation: None required.\n"
else
    printf "ID: 1.6.1.2    | [FAILED]   | Ensure SELinux is enforcing\n  Remediation: setenforce 1\n"
fi

echo "--- 20.3 SERVICES (DISABLE UNNECESSARY) ---"
check_service "2.2.1" "xinetd" "disabled"
check_service "2.2.3" "avahi-daemon" "disabled"
check_service "2.2.4" "cups" "disabled"
check_service "2.2.5" "dhcpd" "disabled"
check_service "2.2.6" "slapd" "disabled"
check_service "2.2.7" "nfs-server" "disabled"
check_service "2.2.8" "rpcbind" "disabled"
check_service "2.2.9" "vsftpd" "disabled"
check_service "2.2.10" "httpd" "disabled"
check_service "2.2.11" "dovecot" "disabled"
check_service "2.2.12" "smb" "disabled"
check_service "2.2.13" "squid" "disabled"
check_service "2.2.14" "snmpd" "disabled"
check_service "2.2.15" "postfix" "disabled"
check_service "2.2.16" "rsyncd" "disabled"
check_service "2.2.17" "nis-domain" "disabled"

echo "--- 20.4 KERNEL PARAMETERS (NETWORK) ---"
check_sysctl "3.1.1" "net.ipv4.ip_forward" "0"
check_sysctl "3.1.2" "net.ipv4.conf.all.send_redirects" "0"
check_sysctl "3.1.2" "net.ipv4.conf.default.send_redirects" "0"
check_sysctl "3.2.1" "net.ipv4.conf.all.accept_source_route" "0"
check_sysctl "3.2.1" "net.ipv4.conf.default.accept_source_route" "0"
check_sysctl "3.2.2" "net.ipv4.conf.all.accept_redirects" "0"
check_sysctl "3.2.2" "net.ipv4.conf.default.accept_redirects" "0"
check_sysctl "3.2.3" "net.ipv4.conf.all.secure_redirects" "0"
check_sysctl "3.2.3" "net.ipv4.conf.default.secure_redirects" "0"
check_sysctl "3.2.4" "net.ipv4.conf.all.log_martians" "1"
check_sysctl "3.2.4" "net.ipv4.conf.default.log_martians" "1"
check_sysctl "3.2.5" "net.ipv4.icmp_echo_ignore_broadcasts" "1"
check_sysctl "3.2.6" "net.ipv4.icmp_ignore_bogus_error_responses" "1"
check_sysctl "3.2.7" "net.ipv4.conf.all.rp_filter" "1"
check_sysctl "3.2.7" "net.ipv4.conf.default.rp_filter" "1"
check_sysctl "3.2.8" "net.ipv4.tcp_syncookies" "1"
check_sysctl "3.3.1" "net.ipv6.conf.all.accept_ra" "0"
check_sysctl "3.3.1" "net.ipv6.conf.default.accept_ra" "0"
check_sysctl "3.3.2" "net.ipv6.conf.all.accept_redirects" "0"
check_sysctl "3.3.2" "net.ipv6.conf.default.accept_redirects" "0"
check_sysctl "3.3.3" "net.ipv6.conf.all.disable_ipv6" "1"

echo "--- 20.5 SSH SERVER CONFIGURATION ---"
check_sshd "5.2.2" "LogLevel" "INFO"
check_sshd "5.2.3" "X11Forwarding" "no"
check_sshd "5.2.4" "MaxAuthTries" "4"
check_sshd "5.2.5" "IgnoreRhosts" "yes"
check_sshd "5.2.6" "HostbasedAuthentication" "no"
check_sshd "5.2.7" "PermitRootLogin" "no"
check_sshd "5.2.8" "PermitEmptyPasswords" "no"
check_sshd "5.2.9" "PermitUserEnvironment" "no"
check_sshd "5.2.11" "ClientAliveInterval" "300"
check_sshd "5.2.12" "ClientAliveCountMax" "3"
check_sshd "5.2.13" "LoginGraceTime" "60"
check_sshd "5.2.14" "AllowTcpForwarding" "no"
check_sshd "5.2.15" "Banner" "/etc/issue.net"
check_sshd "5.2.16" "MaxStartups" "10:30:100"
check_sshd "5.2.17" "MaxSessions" "10"

echo "--- 20.6 FILE PERMISSIONS ---"
check_perm "6.1.2" "/etc/passwd" "644"
check_perm "6.1.3" "/etc/shadow" "000"
check_perm "6.1.4" "/etc/group" "644"
check_perm "6.1.5" "/etc/gshadow" "000"
check_perm "6.1.6" "/etc/passwd-" "644"
check_perm "6.1.7" "/etc/shadow-" "000"
check_perm "6.1.8" "/etc/group-" "644"
check_perm "6.1.9" "/etc/gshadow-" "000"
check_perm "6.1.10" "/etc/issue" "644"
check_perm "6.1.11" "/etc/issue.net" "644"
check_perm "6.1.12" "/etc/motd" "644"
check_perm "6.2.1" "/etc/ssh/sshd_config" "600"
