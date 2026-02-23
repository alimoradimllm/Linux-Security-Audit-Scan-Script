# 🔐 Linux Security Audit Script

This repository contains a collection of security audit scripts designed
to perform comprehensive hardening and compliance checks on Linux
systems.

## 📌 Included Security Checks

-   AppArmor
-   Auditd
-   Auto Updates
-   Boot Security
-   CIS Additional Controls
-   Core Hardening
-   Fail2ban
-   Firewall Configuration
-   Filesystem Security
-   Integrity Monitoring
-   Kernel Security
-   Installed Packages
-   Password Policies
-   File Permissions
-   Root Account Security
-   Shared Memory
-   SSH Configuration
-   SSH Cryptography
-   System Time
-   System Updates
-   USB Security

All checks can be executed individually or together using the main
runner script.

------------------------------------------------------------------------

## 📂 Project Structure

    apparmor_check.sh
    auditd_check.sh
    autoupdate_check.sh
    boot_check.sh
    cis_additional_checks.sh
    core_hardening_check.sh
    fail2ban_check.sh
    firewall_check.sh
    fs_check.sh
    integrity_check.sh
    kernel_check.sh
    packages_check.sh
    password_check.sh
    permissions_check.sh
    root_check.sh
    run_all_audits.sh
    shm_check.sh
    ssh_check.sh
    ssh_crypto_check.sh
    time_check.sh
    update_check.sh
    usb_check.sh

------------------------------------------------------------------------

## 🚀 How to Use

### 1️⃣ Clone the Repository

``` bash
git clone https://github.com/your-username/linux-security-audit.git
cd linux-security-audit
```

### 2️⃣ Make Scripts Executable

``` bash
chmod +x *.sh
```

### 3️⃣ Run All Security Audits

``` bash
./run_all_audits.sh
```

This will execute all audit scripts automatically.

### 4️⃣ Review the Report

After execution, a report file will be generated:

    Ultimate_Security_Report_YYYYMMDD_HHMM.txt

Example:

    Ultimate_Security_Report_20260223_1205.txt

Open the report:

``` bash
cat Ultimate_Security_Report_*.txt
```

or

``` bash
less Ultimate_Security_Report_*.txt
```

------------------------------------------------------------------------

## ⚙️ Requirements

-   Linux system (Debian, Ubuntu, RHEL, CentOS, etc.)
-   Bash shell
-   Root privileges (recommended)

------------------------------------------------------------------------

## ⚠️ Important Notes

-   It is recommended to run the toolkit as root for accurate results.
-   Review scripts before running in production environments.
-   Designed for security auditing and hardening assessment.

------------------------------------------------------------------------

## 🛡️ Purpose

This toolkit helps:

-   Perform CIS-style security checks
-   Identify misconfigurations
-   Improve Linux server hardening
-   Prepare systems for compliance audits
