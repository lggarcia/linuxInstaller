# 🐧 Linux Master Assistant

A modular, and distro-agnostic/shell-agnostic SysAdmin tool with a Zenity GUI designed to automate deployment, hardening, and daily maintenance of Linux servers and workstations.

## Core Features & Capabilities

* **VM Deploy Assistant (Provisioning):** Automate your fresh OS installs. Configure static IPs (auto-detects NetworkManager, Netplan, or interfaces), append to `/etc/hosts`, adjust timezones, create `sudo`/`wheel` users in a single workflow.
* **Smart App Installer & Uninstaller:** Much more than an `apt/dnf install` wrapper. It handles over 60 essential sysadmin tools with **Pre-Flight Configurations** for complex services:
    * **Docker:** Uses official scripts, assigns user groups, and automatically configures `daemon.json` for container Log Rotation to prevent disk exhaustion.
    * **Fail2Ban:** Dynamically detects your active SSH port and generates safe `jail.local` rules to block brute-force attacks.
    * **Endlessh (SSH Tarpit):** Seamlessly moves your real SSH service to a secure high port and binds a honeypot to port 22 to trap botnets.
* **Universal Firewall Manager:** Auto-detects the active firewall (`firewalld`, `ufw`, or `iptables`). Open or close ports without worrying about underlying syntax. Features a **Panic Mode** to instantly drop all incoming connections (except SSH) during an active attack.
* **Cron Task Scheduler:** A user-friendly interface to manage the `crontab`. Add, list, or selectively delete scheduled jobs without needing to memorize the `* * * * *` syntax.
* **Log & Security Auditor:** Export detailed system events, kernel logs, and comprehensive authentication reports (combining `last`, `lastb`, and `journalctl` to show successful vs. failed logins). Create custom `logrotate` rules dynamically with an audit trail.
* **Service Manager:** Safely parse, stop, and permanently disable active background services using `systemd` to free up resources.
* **Shell & Terminal Customizer:** Enhance your default terminal experience with Quality of Life (QoL) improvements. Optimizes Bash-specific settings (custom PS1 fancy-prompt, larger history limits, timestamped tracking).
* **Hardware Auditor & Thermal Monitor:** A dual-layer diagnostics suite for system health:
    * **Instant Audit:** Generates comprehensive, exportable reports covering CPU architecture, RAM health, Network interfaces, and Storage usage (with smart filtering for clean disk reads).
    * **Thermal Intelligence:** Real-time temperature tracking for CPU (via `lm-sensors` or direct kernel sysfs), NVIDIA/AMD GPUs, and physical drives (NVMe/SATA).
    * **Standalone Deployment:** Capability to "spawn" an independent monitoring tool (`~/tempTool.sh`) that resides permanently on the host. It can be scheduled via Cron to create an autonomous thermal history log, functioning even if the main assistant is removed.
* **Maintenance & OS Upgrades:** Keep your system clean and updated. Includes specialized, automated upgrade paths for major Debian releases (11 to 12, and 12 to 13).

## Supported Operating Systems

The core scripts automatically detect the OS and adjust commands for:
* **Debian Family:** Debian, Ubuntu, Kali, Mint, Pop!_OS.
* **Red Hat Family:** RHEL, CentOS, Fedora, AlmaLinux, Rocky Linux.
* **Arch Family:** Arch Linux, Manjaro.

## Installation

Run the following one-liner to install or update the assistant globally:

## ⚠️ Disclaimer & Testing

While this assistant is built following DevOps best practices, it has **NOT** been exhaustively tested across all possible OS versions, hypervisors, and edge cases. 

Because this tool performs critical system-level modifications (networking, firewall rules, SSH hardening, and package management), it is provided **"as is"**, without warranty of any kind. **Please use it at your own risk.**

**Best Practice:** We strongly recommend testing the assistant on a virtual machine or a staging environment before running it on a live production server. 

*Did you find a bug or successfully test it on a specific distro? Feel free to open an issue or submit a Pull Request!*

```sh
curl -sL https://raw.githubusercontent.com/SeuUsuario/linuxMaster/main/install.sh | sudo sh
