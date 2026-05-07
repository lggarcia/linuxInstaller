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
#MODULE: APPS INSTALLER packages.sh#
####################################

run_updater()
{
    zenity --question \
        --title="System Update" \
        --text="Do you want to run a full system update now?\n\nIf you have already updated the system recently, you can safely skip this step." \
        --width=400 2>/dev/null

    if [ $? -ne 0 ]; then
        print_info "System update skipped by user."
        return 0
    fi

    print_info "Starting system update using $OS_FAMILY package manager..."
    $PM_UPDATE
    $PM_UPGRADE
    $PM_CLEAN

    print_success "System update complete."
    zenity --info --title="Updater" --text="System successfully updated and cleaned." 2>/dev/null
}

remove_apps()
{
    print_info "Generating installed packages list..."

    if [ "$OS_FAMILY" = "debian" ]; then
        PACKAGE_LIST=$(apt list --installed 2>/dev/null | cut -d/ -f1 | grep -v "Listing")
    elif [ "$OS_FAMILY" = "rhel" ]; then
        PACKAGE_LIST=$(dnf list installed 2>/dev/null | awk 'NR>1 {print $1}')
    elif [ "$OS_FAMILY" = "arch" ]; then
        PACKAGE_LIST=$(pacman -Q 2>/dev/null | awk '{print $1}')
    else
        zenity --error --text="Unsupported package manager for dynamic removal." 2>/dev/null
        return 1
    fi

    TEMP_PKG_LIST="/tmp/pkg_remove_list.txt"
    > "$TEMP_PKG_LIST"
    for pkg in $PACKAGE_LIST; do
        printf "FALSE\n%s\n" "$pkg" >> "$TEMP_PKG_LIST"
    done

    SELECTED_PACKAGES=$(cat "$TEMP_PKG_LIST" | xargs zenity --list \
        --title="Uninstall Applications" \
        --text="Select the packages you wish to remove:" \
        --checklist --column="Select" --column="Package Name" \
        --width=600 --height=550 --separator=' ' 2>/dev/null)

    rm -f "$TEMP_PKG_LIST"

    if [ -z "$SELECTED_PACKAGES" ]; then
        print_info "Uninstallation cancelled."
        return 0
    fi

    zenity --question --title="Confirm" --text="Are you sure you want to completely remove these packages?\n\n$SELECTED_PACKAGES" 2>/dev/null
    if [ $? -eq 0 ]; then
        print_info "Removing selected packages..."
        $PM_REMOVE $SELECTED_PACKAGES
        $PM_CLEAN
        print_success "Packages removed successfully."
        zenity --info --text="Uninstallation complete." 2>/dev/null
    fi
}

install_apps()
{
    SELECTED_APPS=$(zenity --list --checklist \
        --title="Install Applications" \
        --text="Select the applications to install.\nNotes: Some tools are Debian-only. Other are has a special script." \
        --width=700 --height=600 \
        --column="Install" --column="App" --column="Description" \
        --separator='|' \
        TRUE "htop"                  "System Monitor" \
        TRUE "ncdu"                  "Disk Usage Viewer" \
        TRUE "ranger"                "Terminal File Manager" \
        TRUE "ntfs-3g"               "NTFS Support" \
        TRUE "exfat-fuse"            "exFAT Support" \
        TRUE "git"                   "Git Version Control" \
        TRUE "wget"                  "Command Line Downloader" \
        TRUE "gcc"                   "GNU C Compiler" \
        TRUE "make"                  "Build Automation Tool" \
        TRUE "cmake"                 "Cross-Platform Build Tool" \
        TRUE "gparted"               "Partition Editor" \
        TRUE "gnome-disk-utility"    "GNOME Disk Utility" \
        TRUE "p7zip-full"            "7-Zip Compression" \
        TRUE "lsb-release"           "LSB Release Info" \
        TRUE "python3"               "Python 3" \
        TRUE "python3-pip"           "Pip for Python 3" \
        TRUE "apt-transport-https"   "APT HTTPS Transport (Debian only)" \
        TRUE "curl"                  "Command Line HTTP Client" \
        TRUE "ca-certificates"       "CA Certificates" \
        TRUE "unzip"                 "Unzip Utility" \
        TRUE "unrar-free"            "RAR Utility" \
        TRUE "ethtool"               "Network Tool Kit" \
        TRUE "dnsutils"              "DNS Utilities" \
        TRUE "net-tools"             "Network Tools" \
        TRUE "vlc"                   "VLC Media Player" \
        FALSE "fail2ban"             "Security: Ban Brute Force (Requires Config)" \
        FALSE "endlessh"             "Honeypot for SSH (Requires Config)" \
        FALSE "ufw"                  "Uncomplicated Firewall (Debian/Ubuntu)" \
        FALSE "firewalld"            "Firewall Manager (RHEL/CentOS/Fedora)" \
        FALSE "docker"               "Docker Container Engine (Custom Script)" \
        TRUE  "screen"               "Terminal Multiplexer" \
        TRUE "bat"                   "Cat Clone with Syntax Highlighting" \
        TRUE  "zoxide"               "Smarter cd" \
        TRUE "trash-cli"             "Trash Manager" \
        TRUE  "fzf"                  "Fuzzy Finder" \
        TRUE "bash-completion"       "Bash Autocompletion" \
        TRUE "cifs-utils"            "Windows Share Support" \
        FALSE "arduino"              "Arduino IDE" \
        FALSE "bluefish"             "Web Editor" \
        FALSE "codeblocks"           "C++ IDE" \
        FALSE "libreoffice"          "Office Suite" \
        FALSE "gimp"                 "Image Editor" \
        FALSE "dia"                  "Diagram Editor" \
        FALSE "inkscape"             "Vector Graphics Editor" \
        FALSE "fritzing"             "Electronics Tool" \
        FALSE "filezilla"            "FTP Client" \
        FALSE "qbittorrent"          "Torrent Client" \
        FALSE "soundkonverter"       "Audio Converter" \
        FALSE "sound-juicer"         "CD Ripper" \
        FALSE "audacity"             "Audio Editor" \
        FALSE "audacious"            "Audio Player" \
        FALSE "kdenlive"             "Video Editor" \
        FALSE "k3b"                  "Disc Burning" \
        FALSE "handbrake"            "Video Converter" \
        FALSE "obs-studio"           "Streaming Software" \
        FALSE "wine"                 "Wine Compatibility Layer" \
        FALSE "wine64"               "Wine 64-bit" \
        FALSE "wine64-tools"         "Wine Tools" \
        TRUE "grub-customizer"       "GRUB GUI Tool (May fail on Kali/Mint)" \
        FALSE "freefilesync"         "Folder Sync Tool" \
        FALSE "torbrowser-launcher"  "Tor Browser Installer" \
        FALSE "lm-sensors"           "Sensor Monitor" \
        FALSE "nvme-cli"             "NVMe Tools" \
        FALSE "cmatrix"              "Matrix Screensaver" \
        FALSE "hollywood"            "Hollywood Terminal FX" 2>/dev/null)

    if [ -z "$SELECTED_APPS" ]; then
        print_info "Installation cancelled."
        return 0
    fi

    PADDED_APPS="|${SELECTED_APPS}|"

    # Fail2Ban Configs
    F2B_BANTIME="1h"
    F2B_MAXRETRY="5"
    if echo "$PADDED_APPS" | grep -q "|fail2ban|"; then
        F2B_DATA=$(zenity --forms --title="Fail2Ban Configuration" \
            --text="Configure basic protection for SSH:" \
            --add-entry="Ban Time (e.g., 1h, 1d, 10m)" \
            --add-entry="Max Retries before ban" \
            --separator="|" 2>/dev/null)
        [ -n "$F2B_DATA" ] && F2B_BANTIME=$(echo "$F2B_DATA" | cut -d'|' -f1)
        [ -n "$F2B_DATA" ] && F2B_MAXRETRY=$(echo "$F2B_DATA" | cut -d'|' -f2)
        F2B_BANTIME=${F2B_BANTIME:-1h}
        F2B_MAXRETRY=${F2B_MAXRETRY:-5}
    fi

    # Endlessh Configs
    ENDLESS_PORT="22"
    REAL_SSH_PORT="2222"
    if echo "$PADDED_APPS" | grep -q "|endlessh|"; then
        ENDLESS_DATA=$(zenity --forms --title="Endlessh & SSH Configuration" \
            --text="Set up the SSH Honeypot and move your real SSH port to avoid conflicts:" \
            --add-entry="Endlessh Port (Tarpit/Trap - usually 22)" \
            --add-entry="New Real SSH Port (e.g., 2222)" \
            --separator="|" 2>/dev/null)
        
        [ -n "$ENDLESS_DATA" ] && ENDLESS_PORT=$(echo "$ENDLESS_DATA" | cut -d'|' -f1)
        [ -n "$ENDLESS_DATA" ] && REAL_SSH_PORT=$(echo "$ENDLESS_DATA" | cut -d'|' -f2)
        
        # Default fallbacks
        ENDLESS_PORT=${ENDLESS_PORT:-22}
        REAL_SSH_PORT=${REAL_SSH_PORT:-2222}
    fi

    #custom/special apps
    STANDARD_APPS=$(echo "$SELECTED_APPS" | tr '|' ' ' | sed 's/docker//g; s/fail2ban//g; s/endlessh//g')

    #Debian-only
    if [ "$OS_FAMILY" != "debian" ]; then
        STANDARD_APPS=$(echo "$STANDARD_APPS" | sed 's/apt-transport-https//g; s/grub-customizer//g')
    fi

    $PM_UPDATE

    if [ -n "$(echo "$STANDARD_APPS" | tr -d ' ')" ]; then
        print_info "Installing standard applications..."
        $PM_INSTALL $STANDARD_APPS
    fi

    # Docker Installation
    if echo "$PADDED_APPS" | grep -q "|docker|"; then
        if [ -f "$PROJECT_ROOT/modules/pkg-configs/docker.sh" ]; then
            print_info "Running custom Docker installation..."
            . "$PROJECT_ROOT/modules/pkg-configs/docker.sh"
            install_docker "$REAL_USER"
        else
            print_error "Docker install script not found at modules/pkg-configs/docker.sh"
        fi
    fi

    # Fail2Ban Installation & Config
    if echo "$PADDED_APPS" | grep -q "|fail2ban|"; then
        print_info "Installing Fail2Ban..."
        $PM_INSTALL fail2ban

        if [ -f "$PROJECT_ROOT/modules/pkg-configs/fail2ban.sh" ]; then
            print_info "Configuring Fail2Ban..."
            . "$PROJECT_ROOT/modules/pkg-configs/fail2ban.sh"
            configure_fail2ban "$F2B_BANTIME" "$F2B_MAXRETRY"
        else
            print_error "Fail2Ban config script not found."
        fi
    fi

    # Endlessh Installation & Config
    if echo "$PADDED_APPS" | grep -q "|endlessh|"; then
        print_info "Installing Endlessh..."
        $PM_INSTALL endlessh
        
        if [ -f "$PROJECT_ROOT/modules/pkg-configs/endlessh.sh" ]; then
            print_info "Configuring Endlessh..."
            . "$PROJECT_ROOT/modules/pkg-configs/endlessh.sh"
            configure_endlessh "$ENDLESS_PORT" "$REAL_SSH_PORT"
        else
            print_error "Endlessh config script not found."
        fi
    fi

    # Firewall Basic Hardening
    if echo "$PADDED_APPS" | grep -qE "|ufw|firewalld|"; then
        zenity --question --title="Firewall Safety" \
            --text="Would you like to apply a 'Safety First' configuration?\n(Blocks all incoming except SSH)" 2>/dev/null
        if [ $? -eq 0 ]; then
            if command -v ufw >/dev/null; then
                ufw default deny incoming
                ufw allow ssh
                ufw --force enable
                print_success "UFW activated with Safety First rules."
            elif command -v firewall-cmd >/dev/null; then
                systemctl enable --now firewalld
                firewall-cmd --set-default-zone=drop --permanent
                firewall-cmd --add-service=ssh --permanent
                firewall-cmd --reload
                print_success "Firewalld activated with Safety First rules."
            fi
        fi
    fi

    print_success "All requested packages and configurations have been applied."
    zenity --info --title="Installation Complete" --text="All selected applications were installed successfully." 2>/dev/null
}
