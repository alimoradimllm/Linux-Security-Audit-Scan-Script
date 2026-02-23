#!/bin/bash

# ==========================================
# Time Synchronization Audit Script
# ==========================================

echo "=== SECTION 9: TIME SYNCHRONIZATION ==="

# ---------------------------------------------------------
# Check 9.1.1: Ensure NTP service is enabled
# ---------------------------------------------------------
ID="9.1.1     "
DESC="Ensure NTP service is enabled"

# Check if timedatectl is available
if ! command -v timedatectl >/dev/null 2>&1; then
    echo "Error: timedatectl command not found. System may not be using systemd."
    exit 1
fi

NTP_ENABLED=$(timedatectl show --property=NTP 2>/dev/null | cut -d= -f2)

if [ "$NTP_ENABLED" = "yes" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Automatic time synchronization is enabled."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Run 'sudo timedatectl set-ntp true' to enable automatic time synchronization."
fi

# ---------------------------------------------------------
# Check 9.1.2: Ensure system clock is actually synchronized
# ---------------------------------------------------------
ID="9.1.2     "
DESC="Ensure system clock is actively synchronized"

NTP_SYNCED=$(timedatectl show --property=NTPSynchronized 2>/dev/null | cut -d= -f2)

if [ "$NTP_SYNCED" = "yes" ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. The system clock is successfully synced with an NTP server."
else
    printf "ID: %s | [FAILED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: Check your network/firewall (UDP port 123 must be open outbound) or verify your NTP daemon status."
fi

# ---------------------------------------------------------
# Check 9.1.3: Ensure explicit NTP servers are configured
# ---------------------------------------------------------
ID="9.1.3     "
DESC="Ensure reliable NTP servers are configured"

# Check common configuration files for explicitly defined servers
CONFIGURED=false

# Check systemd-timesyncd
if grep -qE '^NTP=|^FallbackNTP=' /etc/systemd/timesyncd.conf 2>/dev/null; then
    CONFIGURED=true
# Check chrony (Debian/Ubuntu path)
elif grep -qE '^server |^pool ' /etc/chrony/chrony.conf 2>/dev/null; then
    CONFIGURED=true
# Check chrony (RHEL/Fedora path)
elif grep -qE '^server |^pool ' /etc/chrony.conf 2>/dev/null; then
    CONFIGURED=true
# Check legacy ntpd
elif grep -qE '^server |^pool ' /etc/ntp.conf 2>/dev/null; then
    CONFIGURED=true
fi

if [ "$CONFIGURED" = true ]; then
    printf "ID: %s | [PASSED]   | %s\n" "$ID" "$DESC"
    echo "  Remediation: None required. Explicit NTP servers or pools are configured."
else
    # We flag this as a WARNING because falling back to the default OS pools usually still works,
    # but for production environments, explicit reliable internal or regional servers are preferred.
    printf "ID: %s | [WARNING]  | %s\n" "$ID" "$DESC"
    echo "  Remediation: Default distro NTP pools are likely being used. For production, configure explicit NTP servers (e.g., in /etc/systemd/timesyncd.conf)."
fi
