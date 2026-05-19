#!/bin/sh
####################################
#        __    ______  ______      #
#       |  |  |  ____||  ____|     #
#       |  |  | | __  | | __       #
#       |  |__| ||_ | | ||_ |      #
#       |_____|\____| |_____|      #
# -------------------------------- #
#   >> https://lucianogg.info      #
####################################
# MODULE: PC INFO (hardware.sh)    #
####################################

# ==========================================
# 1. UNIVERSAL EXPORT MODULE
# ==========================================
display_and_export_report() {
    local REPORT_FILE="$1"
    local REPORT_TITLE="$2"
    local PREFIX="$3"
    
    local TARGET_USER=${SUDO_USER:-$USER}
    local TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

    # Show the report
    zenity --text-info --title="$REPORT_TITLE" \
        --filename="$REPORT_FILE" --width=850 --height=750 \
        --font="Monospace 10" 2>/dev/null

    # Auto-save prompt
    zenity --question --title="Export Report" \
        --text="Would you like to save this report to your home folder?" --width=350 2>/dev/null
    
    if [ $? -eq 0 ]; then
        EXPORT_PATH="${TARGET_HOME}/${PREFIX}_$(date +%Y%m%d_%H%M%S).txt"
        cp "$REPORT_FILE" "$EXPORT_PATH"
        chown "$TARGET_USER:$TARGET_USER" "$EXPORT_PATH" 2>/dev/null
        
        print_success "$REPORT_TITLE saved successfully to $EXPORT_PATH"
        zenity --info --title="Success" --text="Report saved to:\n$EXPORT_PATH" --width=350 2>/dev/null
    fi

    rm -f "$REPORT_FILE"
}

# ==========================================
# 2. THERMAL MONITOR TOOL
# ==========================================
deploy_thermal_monitor()
{
    TOOL_PATH="$REAL_HOME/tempTool.sh"
    LOG_PATH="$REAL_HOME/thermal_monitor.log"

    FREQ_CHOICE=$(zenity --list \
        --title="Standalone Thermal Monitor" \
        --text="Create an independent temperature monitor script (~/tempTool.sh)\nHow often should it collect data?" \
        --width=550 --height=350 \
        --column="ID" --column="Frequency" --column="Cron Expression" \
        --hide-column=1 \
        "1" "Every 15 minutes" "*/15 * * * *" \
        "2" "Every Hour" "0 * * * *" \
        "3" "Twice a Day (12h/00h)" "0 0,12 * * *" \
        "4" "Daily at Midnight" "0 0 * * *" \
        "5" "Disable / Remove Tool" "REMOVE" 2>/dev/null)

    if [ -z "$FREQ_CHOICE" ]; then
        print_info "Thermal Tool setup canceled."
        return 0
    fi

    if [ "$FREQ_CHOICE" = "5" ]; then
        zenity --question --text="This will remove the scheduled task.\nDo you also want to delete the script and the log file?" 2>/dev/null
        if [ $? -eq 0 ]; then
            rm -f "$TOOL_PATH" "$LOG_PATH"
            print_info "Files removed: tempTool.sh and thermal_monitor.log"
        fi

        CURRENT_CRON=$(crontab -u "$REAL_USER" -l 2>/dev/null | grep -v "$TOOL_PATH")
        echo "$CURRENT_CRON" | crontab -u "$REAL_USER" -

        print_success "Thermal monitoring disabled."
        zenity --info --text="Monitor removed successfully." 2>/dev/null
        return 0
    fi

    print_info "Generating standalone script at $TOOL_PATH..."

    cat << 'EOF' > "$TOOL_PATH"
#!/bin/sh
# Independent Thermal Monitoring Tool
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LOG_FILE="$(dirname "$0")/thermal_monitor.log"

{
    echo "========================================"
    echo " Thermal Report: $(date)"
    echo "========================================"

    echo "[CPU]"
    if command -v sensors >/dev/null 2>&1; then
        sensors | grep -v "ALARM" | grep -E 'temp|Core|Package'
    else
        for zone in /sys/class/thermal/thermal_zone*; do
            if [ -f "$zone/temp" ] && [ -f "$zone/type" ]; then
                type=$(cat "$zone/type")
                temp=$(cat "$zone/temp")
                if [ "$temp" -gt 0 ] 2>/dev/null; then
                    echo "$type: $((temp / 1000))°C"
                fi
            fi
        done
    fi

    echo "[GPU]"
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "NVIDIA: $(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null)°C"
    elif command -v rocm-smi >/dev/null 2>&1; then
        rocm-smi -t | grep -i temp
    else
        echo "No dedicated GPU tools detected."
    fi

    echo "[DISKS]"
    if command -v hddtemp >/dev/null 2>&1; then
        hddtemp /dev/sd* /dev/nvme* 2>/dev/null
    elif command -v smartctl >/dev/null 2>&1; then
        for disk in $(lsblk -nd -o NAME | grep -E "^(sd|nvme)"); do
            T=$(smartctl -A "/dev/$disk" 2>/dev/null | grep -iE "Temperature_Celsius|Temperature:|Temperature Sensor" | awk '{print $NF}' | head -n 1)
            [ -n "$T" ] && echo "/dev/$disk: ${T}°C"
        done
    else
        echo "No disk temp tools detected."
    fi
    echo ""
} >> "$LOG_FILE"
EOF

    chown "$REAL_USER:$REAL_USER" "$TOOL_PATH"
    chmod +x "$TOOL_PATH"

    case "$FREQ_CHOICE" in
        1) EXPR="*/15 * * * *" ;;
        2) EXPR="0 * * * *" ;;
        3) EXPR="0 0,12 * * *" ;;
        4) EXPR="0 0 * * *" ;;
    esac

    CURRENT_CRON=$(crontab -u "$REAL_USER" -l 2>/dev/null | grep -v "$TOOL_PATH")
    (echo "$CURRENT_CRON"; echo "$EXPR $TOOL_PATH") | crontab -u "$REAL_USER" -
    touch "$LOG_PATH"
    chown "$REAL_USER:$REAL_USER" "$LOG_PATH"

    print_success "Thermal Tool scheduled."
    zenity --info --title="Setup Complete" \
        --text="Tool generated at:\n$TOOL_PATH\n\nFrequency: $EXPR" 2>/dev/null
}


# ==========================================
# 3. UNIFIED DATA GATHERING BLOCKS
# ==========================================

do_os() {
    echo "" >> "$CURRENT_REPORT"
    echo "--- OPERATING SYSTEM & SOFTWARE ---" >> "$CURRENT_REPORT"
    grep -E "^PRETTY_NAME=" /etc/os-release | cut -d= -f2 | sed 's/"//g' | awk '{print "Distribution: "$0}' >> "$CURRENT_REPORT"
    echo "Kernel: $(uname -r)" >> "$CURRENT_REPORT"
    echo "Uptime: $(uptime -p)" >> "$CURRENT_REPORT"
    
    local DEF_SHELL=$(getent passwd "$TARGET_USER" | cut -d: -f7)
    echo "Default Shell ($TARGET_USER): $DEF_SHELL" >> "$CURRENT_REPORT"
    
    echo "" >> "$CURRENT_REPORT"
    echo "--- GRAPHICAL ENVIRONMENT ---" >> "$CURRENT_REPORT"
    local SESSION_ID=$(loginctl list-sessions 2>/dev/null | grep "$TARGET_USER" | awk '{print $1}' | head -n 1)
    local DISP_SERVER=""
    if [ -n "$SESSION_ID" ]; then
        DISP_SERVER=$(loginctl show-session "$SESSION_ID" -p Type --value 2>/dev/null)
    else
        if pgrep -x "Xorg" >/dev/null; then DISP_SERVER="x11"
        elif pgrep -x "Xwayland" >/dev/null; then DISP_SERVER="wayland"
        else DISP_SERVER="tty/headless"
        fi
    fi
    echo "Display Server: ${DISP_SERVER:-Unknown}" >> "$CURRENT_REPORT"

    local DE_NAME="None / CLI"
    if pgrep -x "cinnamon" >/dev/null; then DE_NAME="Cinnamon"
    elif pgrep -x "gnome-shell" >/dev/null; then DE_NAME="GNOME"
    elif pgrep -x "plasmashell" >/dev/null; then DE_NAME="KDE Plasma"
    elif pgrep -x "xfce4-session" >/dev/null; then DE_NAME="XFCE"
    elif pgrep -x "mate-panel" >/dev/null; then DE_NAME="MATE"
    elif pgrep -x "lxsession" >/dev/null; then DE_NAME="LXDE/LXQt"
    fi
    echo "Desktop Environment: $DE_NAME" >> "$CURRENT_REPORT"
    
    if [ -e /etc/systemd/system/display-manager.service ]; then
        DM_NAME=$(basename $(readlink /etc/systemd/system/display-manager.service) | sed 's/\.service//')
    elif [ -f /etc/X11/default-display-manager ]; then
        DM_NAME=$(basename $(cat /etc/X11/default-display-manager))
    else
        if pgrep -x "gdm3" >/dev/null; then DM_NAME="gdm3"
        elif pgrep -x "sddm" >/dev/null; then DM_NAME="sddm"
        elif pgrep -x "lightdm" >/dev/null; then DM_NAME="lightdm"
        else DM_NAME="None"
        fi
    fi
    echo "Display Manager: $DM_NAME" >> "$CURRENT_REPORT"
    
    echo "" >> "$CURRENT_REPORT"
    echo "--- SERVICES & DAEMONS ---" >> "$CURRENT_REPORT"
    echo "Init System: $(ps -p 1 -o comm=)" >> "$CURRENT_REPORT"
    
    if systemctl is-active --quiet systemd-journald 2>/dev/null; then echo "Primary Logger: systemd-journald" >> "$CURRENT_REPORT"
    elif systemctl is-active --quiet rsyslog 2>/dev/null; then echo "Primary Logger: rsyslog" >> "$CURRENT_REPORT"
    else echo "Primary Logger: Unknown / Custom" >> "$CURRENT_REPORT"
    fi
    
    if systemctl is-active --quiet NetworkManager 2>/dev/null; then
        NET_MGR="NetworkManager (nmcli)"
    elif systemctl is-active --quiet systemd-networkd 2>/dev/null; then
        if command -v netplan >/dev/null 2>&1 && ls /etc/netplan/*.yaml >/dev/null 2>&1; then
            NET_MGR="Netplan (systemd-networkd backend)"
        else
            NET_MGR="systemd-networkd"
        fi
    elif systemctl is-active --quiet networking 2>/dev/null; then
        NET_MGR="ifupdown (/etc/network/interfaces)"
    else
        NET_MGR="Unknown / Manual"
    fi
    echo "Network Stack: $NET_MGR" >> "$CURRENT_REPORT"
    echo "" >> "$CURRENT_REPORT"
}

do_network() {
    echo "" >> "$CURRENT_REPORT"
    echo "--- NETWORK & SECURITY ---" >> "$CURRENT_REPORT"
    
    # Identify Network Manager
    local NET_MGR="Unknown / Manual"
    if systemctl is-active --quiet NetworkManager 2>/dev/null; then NET_MGR="NetworkManager (nmcli)"
    elif systemctl is-active --quiet systemd-networkd 2>/dev/null; then
        if command -v netplan >/dev/null 2>&1 && ls /etc/netplan/*.yaml >/dev/null 2>&1; then NET_MGR="Netplan (systemd-networkd)"
        else NET_MGR="systemd-networkd"
        fi
    elif systemctl is-active --quiet networking 2>/dev/null; then NET_MGR="ifupdown (/etc/network/interfaces)"
    fi
    echo "Network Stack: $NET_MGR" >> "$CURRENT_REPORT"

    if command -v getenforce >/dev/null 2>&1; then echo "SELinux: $(getenforce)" >> "$CURRENT_REPORT"
    elif command -v aa-status >/dev/null 2>&1; then echo "AppArmor: $(aa-status --enabled 2>/dev/null && echo "Enabled" || echo "Disabled")" >> "$CURRENT_REPORT"
    else echo "MAC System: None detected" >> "$CURRENT_REPORT"
    fi

    echo "" >> "$CURRENT_REPORT"
    echo "[Interfaces & IP Addresses]" >> "$CURRENT_REPORT"
    if command -v ip >/dev/null 2>&1; then ip -brief address show >> "$CURRENT_REPORT"
    elif command -v ifconfig >/dev/null 2>&1; then ifconfig -a >> "$CURRENT_REPORT"
    fi
    
    echo "" >> "$CURRENT_REPORT"
    echo "[Listening Services & Open Ports]" >> "$CURRENT_REPORT"
    if command -v ss >/dev/null 2>&1; then
        if command -v column >/dev/null 2>&1; then ss -tulpn | column -t >> "$CURRENT_REPORT" 2>/dev/null
        else ss -tulpn >> "$CURRENT_REPORT" 2>/dev/null
        fi
    elif command -v netstat >/dev/null 2>&1; then netstat -tulpn >> "$CURRENT_REPORT" 2>/dev/null
    fi
}

do_core() {
    echo "" >> "$CURRENT_REPORT"
    echo "--- CPU INFORMATION ---" >> "$CURRENT_REPORT"
    lscpu | grep -E "Model name|Architecture|CPU\(s\):|Thread\(s\) per core|Core\(s\) per socket|CPU MHz|BogoMIPS" >> "$CURRENT_REPORT"

    echo "" >> "$CURRENT_REPORT"
    echo "--- MEMORY (RAM) ---" >> "$CURRENT_REPORT"
    free -h >> "$CURRENT_REPORT"
}

do_storage() {
    echo "" >> "$CURRENT_REPORT"
    echo "--- STORAGE & DISK USAGE ---" >> "$CURRENT_REPORT"
    echo "[Mounted Partitions]" >> "$CURRENT_REPORT"
    df -h -T -x tmpfs -x devtmpfs -x squashfs -x efivarfs >> "$CURRENT_REPORT"

    echo "" >> "$CURRENT_REPORT"
    echo "[Block Devices / Physical Drives]" >> "$CURRENT_REPORT"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT >> "$CURRENT_REPORT"
}

do_thermals() {
    echo "" >> "$CURRENT_REPORT"
    echo "--- THERMAL SENSORS ---" >> "$CURRENT_REPORT"

    echo "[CPU & Motherboard]" >> "$CURRENT_REPORT"
    if command -v sensors >/dev/null 2>&1; then
        sensors | grep -v "ALARM" >> "$CURRENT_REPORT"
    else
        echo "(lm-sensors not found. Reading raw kernel sysfs instead)" >> "$CURRENT_REPORT"
        for zone in /sys/class/thermal/thermal_zone*; do
            if [ -f "$zone/temp" ] && [ -f "$zone/type" ]; then
                local type=$(cat "$zone/type")
                local temp=$(cat "$zone/temp")
                if [ "$temp" -gt 0 ] 2>/dev/null; then
                    echo "$type: $((temp / 1000))°C" >> "$CURRENT_REPORT"
                fi
            fi
        done
    fi

    echo "" >> "$CURRENT_REPORT"
    echo "[GPU Temperatures]" >> "$CURRENT_REPORT"
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "NVIDIA GPU: $(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null)°C" >> "$CURRENT_REPORT"
    elif command -v rocm-smi >/dev/null 2>&1; then rocm-smi -t | grep -i temp >> "$CURRENT_REPORT"
    else echo "No dedicated NVIDIA/AMD tools detected." >> "$CURRENT_REPORT"
    fi

    echo "" >> "$CURRENT_REPORT"
    echo "[Disk Temperatures]" >> "$CURRENT_REPORT"
    if command -v hddtemp >/dev/null 2>&1; then hddtemp /dev/sd* /dev/nvme* 2>/dev/null >> "$CURRENT_REPORT"
    elif command -v smartctl >/dev/null 2>&1; then
        for disk in $(lsblk -nd -o NAME | grep -E "^(sd|nvme)"); do
            local TEMP=$(smartctl -A "/dev/$disk" 2>/dev/null | grep -iE "Temperature_Celsius|Temperature:|Temperature Sensor" | awk '{print $NF}' | head -n 1)
            if [ -n "$TEMP" ]; then echo "/dev/$disk: ${TEMP}°C" >> "$CURRENT_REPORT"; fi
        done
    else echo "Please install 'hddtemp' or 'smartmontools' to read disk temperatures." >> "$CURRENT_REPORT"
    fi
}

# ==========================================
# 4. MAIN AUDITOR CONTROLLER
# ==========================================
run_system_auditor()
{
    ACTION=$(zenity --list \
        --title="System & Hardware Auditor" \
        --text="Select an auditing module to run:" \
        --width=650 --height=500 \
        --column="ID" --column="Action" --column="Description" \
        --hide-column=1 \
        "1" "Operating System" "Report: OS version, Kernel, GUI Environment, Daemons." \
        "2" "Network & Security" "Report: IP addresses, MAC rules, Listening Ports." \
        "3" "Core Hardware" "Report: CPU Architecture and Memory (RAM)." \
        "4" "Storage & Disks" "Report: Mounted partitions, usage, and block devices." \
        "5" "Thermal Sensors" "Report: Current Temperatures for CPU, GPU, and Disks." \
        "6" "Full System Master" "Report: Combines ALL system and hardware reports." \
        "7" "Deploy Thermal Tool" "Utility: Create a standalone background temp tracker." 2>/dev/null)

    if [ -z "$ACTION" ]; then
        print_info "Auditor canceled."
        return 0
    fi

    if [ "$ACTION" = "7" ]; then
        deploy_thermal_monitor
        return 0
    fi

    print_info "Gathering system metrics..."
    
    # Setup global variables for the reporting blocks
    export TARGET_USER=${SUDO_USER:-$USER}
    export CURRENT_REPORT="/tmp/audit_report_$(date +%Y%m%d_%H%M%S).txt"
    
    # Write Universal Header
    echo "============================================================" > "$CURRENT_REPORT"
    echo "                 LINUX MASTER AUDIT REPORT                  " >> "$CURRENT_REPORT"
    echo "============================================================" >> "$CURRENT_REPORT"
    echo "Date Generated : $(date)" >> "$CURRENT_REPORT"
    echo "Target Hostname: $(hostname)" >> "$CURRENT_REPORT"
    echo "Requested By   : $REAL_USER" >> "$CURRENT_REPORT"

    # Stack the Lego bricks based on choice
    case "$ACTION" in
        1) do_os ;;
        2) do_network ;;
        3) do_core ;;
        4) do_storage ;;
        5) do_thermals ;;
        6) do_os; do_network; do_core; do_storage; do_thermals ;;
    esac

    echo "" >> "$CURRENT_REPORT"
    echo "============================================================" >> "$CURRENT_REPORT"
    echo "                     END OF REPORT                          " >> "$CURRENT_REPORT"
    echo "============================================================" >> "$CURRENT_REPORT"

    # Display and Export
    display_and_export_report "$CURRENT_REPORT" "System Audit Report" "linux_audit"
}
