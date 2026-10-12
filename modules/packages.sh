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
    UPDATE_FILE="$REAL_HOME/update.sh"

    if command -v apt-get >/dev/null; then
        CMD="apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y && apt-get autoremove -y && apt-get clean && apt-get autoclean"
    elif command -v dnf >/dev/null; then
        CMD="dnf update -y && dnf autoremove -y && dnf clean all"
    elif command -v pacman >/dev/null; then
        CMD="pacman -Syu --noconfirm && pacman -Sc --noconfirm"
    fi

    cat << EOF > "$UPDATE_FILE"
#!/bin/sh
# Auto-generated Update Script
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
echo "--- Start: \$(date) ---" >> "$REAL_HOME/update_log.txt"
$CMD >> "$REAL_HOME/update_log.txt" 2>&1
echo "--- End: \$(date) ---" >> "$REAL_HOME/update_log.txt"
EOF

    chmod +x "$UPDATE_FILE"
    chown "$REAL_USER:$REAL_USER" "$UPDATE_FILE"
    print_success "Update script successfully generated at: $UPDATE_FILE"

    zenity --question --title="Update Now" \
        --text="Would you like to install system updates immediately?" --width=400 2>/dev/null
    if [ $? -eq 0 ]; then
        print_info "Updating system..."
        $UPDATE_FILE
    fi

    zenity --question --title="Schedule Daily Update" \
        --text="Schedule it in Crontab for daily execution at 05:00 AM?" --width=400 2>/dev/null
    if [ $? -eq 0 ]; then
        (crontab -l 2>/dev/null | grep -v "$UPDATE_FILE"; echo "0 5 * * * $UPDATE_FILE") | crontab -
        print_success "Script scheduled for daily execution at 05:00 AM."
        zenity --info --text="Success!\n\nScript: $UPDATE_FILE\nSchedule: Daily at 05:00\nLog: ~/update_log.txt" 2>/dev/null
    fi
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

translate_packages()
{
    local RAW_LIST="$1"
    local FINAL_LIST=""

    for app in $(echo "$RAW_LIST" | tr '|' ' '); do
        if [ "$app" = "docker" ] || [ "$app" = "fail2ban" ] || [ "$app" = "endlessh" ] || [ "$app" = "ufw" ] || [ "$app" = "firewalld" ]; then
            continue
        fi

        case "$app" in
            "p7zip")
                [ "$OS_FAMILY" = "debian" ] && FINAL_LIST="$FINAL_LIST p7zip-full"
                [ "$OS_FAMILY" = "rhel" ] && FINAL_LIST="$FINAL_LIST p7zip p7zip-plugins"
                [ "$OS_FAMILY" = "arch" ] && FINAL_LIST="$FINAL_LIST p7zip"
                ;;
            "exfat-fuse")
                [ "$OS_FAMILY" = "rhel" ] && FINAL_LIST="$FINAL_LIST exfatprogs" || FINAL_LIST="$FINAL_LIST exfat-fuse"
                ;;
            "pip")
                [ "$OS_FAMILY" = "arch" ] && FINAL_LIST="$FINAL_LIST python-pip" || FINAL_LIST="$FINAL_LIST python3-pip"
                ;;
            "dnsutils")
                [ "$OS_FAMILY" = "debian" ] && FINAL_LIST="$FINAL_LIST dnsutils"
                [ "$OS_FAMILY" = "rhel" ] && FINAL_LIST="$FINAL_LIST bind-utils"
                [ "$OS_FAMILY" = "arch" ] && FINAL_LIST="$FINAL_LIST bind"
                ;;
            "lsb")
                [ "$OS_FAMILY" = "rhel" ] && FINAL_LIST="$FINAL_LIST redhat-lsb-core" || FINAL_LIST="$FINAL_LIST lsb-release"
                ;;
            "sensors")
                [ "$OS_FAMILY" = "debian" ] && FINAL_LIST="$FINAL_LIST lm-sensors" || FINAL_LIST="$FINAL_LIST lm_sensors"
                ;;
            "wine")
                [ "$OS_FAMILY" = "debian" ] && FINAL_LIST="$FINAL_LIST wine64 wine64-tools"
                [ "$OS_FAMILY" = "rhel" ] || [ "$OS_FAMILY" = "arch" ] && FINAL_LIST="$FINAL_LIST wine"
                ;;
            "grub-customizer")
                [ "$OS_FAMILY" = "debian" ] && FINAL_LIST="$FINAL_LIST grub-customizer"
                ;;
            "apt-transport-https")
                [ "$OS_FAMILY" = "debian" ] && FINAL_LIST="$FINAL_LIST apt-transport-https"
                ;;
            "libreoffice" | "gimp" | "fritzing" | "filezilla" | "qbittorrent" | "soundkonverter" | "audacity" | "audacious" | "kdenlive" | "obs-studio" | "torbrowser-launcher")
                [ "$OS_FAMILY" = "rhel" ] || FINAL_LIST="$FINAL_LIST $app"
                ;;
            "drawio")
                # Install via flatpak across all OS families, skipped here
                ;;
            "ranger" | "zoxide" | "trash-cli" | "gparted" | "cmatrix" | "hollywood")
                [ "$OS_FAMILY" = "rhel" ] || FINAL_LIST="$FINAL_LIST $app"
                ;;
            *)
                FINAL_LIST="$FINAL_LIST $app"
                ;;
        esac
    done
    echo "$FINAL_LIST"
}

install_apps()
{
    SELECTED_APPS=$(zenity --list --checklist \
        --title="Install Applications" \
        --text="Select the applications to install.\nThe installer will automatically resolve names for your distro ($OS_FAMILY)." \
        --width=750 --height=650 \
        --column="Install" --column="App ID" --column="Description" \
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
        TRUE "f3"                    "Disk Integrity Test" \
        TRUE "p7zip"                 "7-Zip Compression (Multi-distro mapped)" \
        TRUE "lsb"                   "LSB Release Info (Multi-distro mapped)" \
        TRUE "python3"               "Python 3" \
        TRUE "pip"                   "Pip for Python (Multi-distro mapped)" \
        TRUE "apt-transport-https"   "APT HTTPS Transport (Debian only)" \
        TRUE "curl"                  "Command Line HTTP Client" \
        TRUE "ca-certificates"       "CA Certificates" \
        TRUE "unzip"                 "Unzip Utility" \
        TRUE "unrar-free"            "RAR Utility" \
        TRUE "ethtool"               "Network Tool Kit" \
        TRUE "dnsutils"              "DNS Utilities (Multi-distro mapped)" \
        TRUE "net-tools"             "Network Tools" \
        TRUE "vlc"                   "VLC Media Player" \
        TRUE "bat"                   "Cat Clone with Syntax Highlighting" \
        TRUE "zoxide"                "Smarter cd" \
        TRUE "trash-cli"             "Trash Manager" \
        TRUE "fzf"                   "Fuzzy Finder" \
        TRUE "thefuck"               "CLI correction tool" \
        TRUE "shellcheck"            "script checker for CLI" \
        TRUE "bash-completion"       "Bash Autocompletion" \
        TRUE "cifs-utils"            "Windows Share Support" \
        TRUE "tmux"                  "Terminal Multiplexer" \
        FALSE "screen"               "Terminal Multiplexer" \
        FALSE "fail2ban"             "Security: Ban Brute Force (Requires Config)" \
        FALSE "endlessh"             "Honeypot for SSH (Requires Config)" \
        FALSE "ufw"                  "Uncomplicated Firewall (Debian/Ubuntu)" \
        FALSE "firewalld"            "Firewall Manager (RHEL/CentOS/Fedora)" \
        FALSE "docker"               "Docker Container Engine (Custom Script)" \
        FALSE "arduino"              "Arduino IDE" \
        FALSE "bluefish"             "Web Editor" \
        FALSE "codeblocks"           "C++ IDE" \
        FALSE "libreoffice"          "Office Suite" \
        FALSE "gimp"                 "Image Editor" \
        FALSE "flameshot"            "Screenshot tool" \
        FALSE "drawio"               "Draw.io Diagram Editor (Flatpak)" \
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
        FALSE "wine"                 "Wine Compatibility Layer (Multi-distro mapped)" \
        FALSE "grub-customizer"      "GRUB GUI Tool (Debian/Ubuntu only)" \
        FALSE "freefilesync"         "Folder Sync Tool" \
        FALSE "sensors"              "Sensor Monitor (Multi-distro mapped)" \
        FALSE "nvme-cli"             "NVMe Tools" \
        FALSE "cmatrix"              "Matrix Screensaver" \
        FALSE "hollywood"            "Hollywood Terminal FX" 2>/dev/null)

    if [ -z "$SELECTED_APPS" ]; then
        print_info "Installation cancelled."
        return 0
    fi

    PADDED_APPS="|${SELECTED_APPS}|"

    # thefuck config
    if echo "$PADDED_APPS" | grep -q "|thefuck|"; then
        print_info "Configuring 'thefuck' alias in user shell profile..."
        CURRENT_SHELL=$(basename "$REAL_SHELL")
        TARGET_PROFILE=""
        case "$CURRENT_SHELL" in
            bash) TARGET_PROFILE="$REAL_HOME/.bashrc" ;;
            zsh)  TARGET_PROFILE="$REAL_HOME/.zshrc" ;;
            ksh)  TARGET_PROFILE="$REAL_HOME/.kshrc" ;;
            *)    TARGET_PROFILE="$REAL_HOME/.profile" ;;
        esac

        if [ -f "$TARGET_PROFILE" ]; then
            if ! grep -q "thefuck --alias" "$TARGET_PROFILE"; then
                echo "" >> "$TARGET_PROFILE"
                echo "# TheFuck CLI correction tool" >> "$TARGET_PROFILE"
                echo 'eval "$(thefuck --alias)"' >> "$TARGET_PROFILE"
                print_success "'thefuck' successfully configured in $TARGET_PROFILE."
            else
                print_info "'thefuck' configuration already present in $TARGET_PROFILE."
            fi
        else
            print_warning "Shell profile $TARGET_PROFILE not found. Skipping 'thefuck' auto-configuration."
        fi
    fi

    # fzf config
    CURRENT_SHELL=$(basename "$REAL_SHELL")
    FZF_BINDING_FILE=""
    if [ "$CURRENT_SHELL" = "bash" ]; then
        for path in "/usr/share/doc/fzf/examples/key-bindings.bash" "/usr/share/fzf/key-bindings.bash" "/etc/fzf.bash"; do
            if [ -f "$path" ]; then
                FZF_BINDING_FILE="$path"
                break
            fi
        done
    elif [ "$CURRENT_SHELL" = "zsh" ]; then
        for path in "/usr/share/doc/fzf/examples/key-bindings.zsh" "/usr/share/fzf/key-bindings.zsh" "/etc/fzf.zsh"; do
            if [ -f "$path" ]; then
                FZF_BINDING_FILE="$path"
                break
            fi
        done
    fi

    # Se encontrou o arquivo de bindings para o shell atual, injeta de forma limpa
    if [ -n "$FZF_BINDING_FILE" ]; then
        cat <<EOF >> "$CONFIG_FILE"
# FZF Key Bindings and Completion ($CURRENT_SHELL)
[ -f "$FZF_BINDING_FILE" ] && source "$FZF_BINDING_FILE"
EOF
        print_success "FZF key-bindings integrated for $CURRENT_SHELL."
    else
        print_warning "FZF key-bindings file not found for shell: $CURRENT_SHELL. Skipping integration."
    fi

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

        ENDLESS_PORT=${ENDLESS_PORT:-22}
        REAL_SSH_PORT=${REAL_SSH_PORT:-2222}
    fi

    print_info "Syncing package repositories..."
    $PM_UPDATE

    if [ "$OS_FAMILY" = "rhel" ]; then
        PM_INSTALL="dnf install -y --skip-broken"
        print_info "RHEL/Rocky system detected. Ensuring EPEL and CRB repositories..."
        $PM_INSTALL epel-release
        if command -v crb >/dev/null 2>&1; then
            crb enable >/dev/null 2>&1
        elif command -v dnf-config-manager >/dev/null 2>&1; then
            dnf-config-manager --set-enabled crb >/dev/null 2>&1
        fi
        sudo dnf install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm -y
        sudo dnf install --nogpgcheck https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm -y
        $PM_UPDATE
    fi

    STANDARD_APPS=$(translate_packages "$SELECTED_APPS")

    if [ -n "$(echo "$STANDARD_APPS" | tr -d ' ')" ]; then
        print_info "Installing standard applications in batch mode..."
        $PM_INSTALL $STANDARD_APPS

        if [ $? -ne 0 ]; then
            print_warning "Batch installation failed. Attempting one-by-one installation..."
            for pkg in $STANDARD_APPS; do
                print_info "Attempting to install: $pkg"
                $PM_INSTALL "$pkg"
            done
        fi
    fi

    FLATPAK_APPS=""
    for app in $(echo "$SELECTED_APPS" | tr '|' ' '); do
        if [ "$app" = "drawio" ]; then
            FLATPAK_APPS="$FLATPAK_APPS drawio"
        fi
        case "$app" in
            "libreoffice"|"gimp"|"fritzing"|"filezilla"|"qbittorrent"|"soundkonverter"|"audacity"|"audacious"|"kdenlive"|"obs-studio"|"torbrowser-launcher")
                if [ "$OS_FAMILY" = "rhel" ]; then
                    FLATPAK_APPS="$FLATPAK_APPS $app"
                fi
                ;;
        esac
    done

    if [ -n "$(echo "$FLATPAK_APPS" | tr -d ' ')" ]; then
        print_info "Desktop apps detected. Ensuring flatpack support..."
        $PM_INSTALL flatpak
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

        for f_app in $FLATPAK_APPS; do
            case "$f_app" in
                "libreoffice") f_id="org.libreoffice.LibreOffice" ;;
                "gimp") f_id="org.gimp.GIMP" ;;
                "drawio") f_id="com.jgraph.drawio.desktop" ;;
                "fritzing") f_id="org.fritzing.Fritzing" ;;
                "filezilla") f_id="org.filezillaproject.Filezilla" ;;
                "qbittorrent") f_id="org.qbittorrent.qBittorrent" ;;
                "soundkonverter") f_id="com.github.dfaust.soundkonverter" ;;
                "audacity") f_id="org.audacityteam.Audacity" ;;
                "audacious") f_id="org.atheme.audacious" ;;
                "kdenlive") f_id="org.kde.kdenlive" ;;
                "obs-studio") f_id="com.obsproject.Studio" ;;
                "torbrowser-launcher") f_id="com.github.micahflee.torbrowser-launcher" ;;
                *) f_id="$f_app" ;;
            esac
            print_info "Installing $f_app via Flatpak Flathub..."
            flatpak install -y flathub "$f_id"
        done
    fi

    if echo "$PADDED_APPS" | grep -q "|docker|"; then
        if [ -f "$PROJECT_ROOT/modules/pkg-configs/docker.sh" ]; then
            print_info "Running custom Docker installation..."
            . "$PROJECT_ROOT/modules/pkg-configs/docker.sh"
            install_docker "$REAL_USER"
        else
            print_error "Docker install script not found at modules/pkg-configs/docker.sh"
        fi
    fi

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

    if echo "$PADDED_APPS" | grep -q "|ufw|" || echo "$PADDED_APPS" | grep -q "|firewalld|"; then
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
