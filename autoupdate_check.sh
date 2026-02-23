#!/bin/bash

# ==========================================
# Automatic Security Updates Audit Script
# ==========================================

# Ensure the script is run as root to read configuration files
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo ./autoupdate_check.sh)."
  exit 1
fi

echo "=== SECTION 2: AUTOMATIC SECURITY UPDATES ==="

# Detect the package manager/OS family
if command -v apt-get >/dev/null 2>&1; then
    OS_FAMILY="debian"
elif command -v dnf >/dev/null 2>&1; then
    OS_FAMILY="rhel"
else
    OS_FAMILY="unknown"
fi

# ---------------------------------------------------------
# Check 2.1.1: Ensure automatic update package is installed
# ---------------------------------------------------------
ID="2.1.1     "
DESC="Ensure auto-update package is installed"

if [ "$OS_FAMILY" == "debian" ]; then
    if dpkg-query -W -f='${Status}' unattended-upgrades 2>/dev/null | grep -q "install ok installed"; then
        printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: None required. 'unattended-upgrades' is installed."
    else
        printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: Run 'apt-get install unattended-upgrades' to install the required package."
    fi
elif [ "$OS_FAMILY" == "rhel" ]; then
    if rpm -q dnf-automatic >/dev/null 2>&1; then
        printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: None required. 'dnf-automatic' is installed."
    else
        printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: Run 'dnf install dnf-automatic' to install the required package."
    fi
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Unsupported OS. Please install your distribution's automatic update agent."
fi

# ---------------------------------------------------------
# Check 2.1.2: Ensure automatic update timer is enabled
# ---------------------------------------------------------
ID="2.1.2     "
DESC="Ensure auto-update service/timer is enabled"

if [ "$OS_FAMILY" == "debian" ]; then
    # Debian uses apt-config to check if the periodic unattended upgrade is set to 1 (enabled)
    if apt-config dump 2>/dev/null | grep -q 'APT::Periodic::Unattended-Upgrade "1"'; then
        printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: None required. APT is configured to run unattended upgrades automatically."
    else
        printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: Run 'dpkg-reconfigure -plow unattended-upgrades' or set APT::Periodic::Unattended-Upgrade \"1\"; in /etc/apt/apt.conf.d/20auto-upgrades."
    fi
elif [ "$OS_FAMILY" == "rhel" ]; then
    if systemctl is-enabled dnf-automatic.timer >/dev/null 2>&1; then
        printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: None required. dnf-automatic.timer is enabled."
    else
        printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: Run 'systemctl enable --now dnf-automatic.timer' to enable automatic updates."
    fi
fi

# ---------------------------------------------------------
# Check 2.1.3: Ensure configuration applies updates (and prefers security)
# ---------------------------------------------------------
ID="2.1.3     "
DESC="Ensure config applies security updates automatically"

if [ "$OS_FAMILY" == "debian" ]; then
    # Check if the origins-pattern includes security updates
    if grep -q "origin=Debian,codename=\${distro_codename}-security" /etc/apt/apt.conf.d/50unattended-upgrades 2>/dev/null || \
       grep -q "\${distro_id}:\${distro_codename}-security" /etc/apt/apt.conf.d/50unattended-upgrades 2>/dev/null; then
        printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: None required. Security repositories are enabled in 50unattended-upgrades."
    else
        printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: Edit /etc/apt/apt.conf.d/50unattended-upgrades and ensure the '-security' origin is uncommented in Unattended-Upgrade::Allowed-Origins."
    fi
elif [ "$OS_FAMILY" == "rhel" ]; then
    # For RHEL/Fedora, we check if upgrade_type is set to security and apply_updates is yes
    if grep -q "^upgrade_type = security" /etc/dnf/automatic.conf 2>/dev/null && grep -q "^apply_updates = yes" /etc/dnf/automatic.conf 2>/dev/null; then
        printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: None required. dnf-automatic is configured to apply security updates."
    else
        printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
        echo "  Remediation: Edit /etc/dnf/automatic.conf. Set 'upgrade_type = security' and 'apply_updates = yes'."
    fi
fi
