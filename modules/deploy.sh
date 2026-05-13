#!/bin/sh
####################################
#        __    ______  ______      #
#       |  |  |  ____||  ____|     #
#       |  |  | | __  | | __       #
#       |  |__| ||_ | | ||_ |      #
#       |_____|\____| |_____|      #
# -------------------------------- #
#   >> https://lucianogg.info      #
#######################################
#MODULE:MACHINE DEPLOY TOOL(deploy.sh)#
#######################################

run_deploy()
{
    print_info "Starting Corporate Deploy Assistant..."

    #REAL_USER=${SUDO_USER:-$(whoami)}
    #REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

    DEPLOY_TASKS=$(zenity --list --checklist \
        --title="VM Deploy Assistant" \
        --text="Select the configurations you want to apply to this virtual machine:" \
        --width=650 --height=550 \
        --column="Select" --column="ID" --column="Configuration Task" \
        --hide-column=2 \
        --separator="|" \
        TRUE "1" "Set System Hostname" \
        FALSE "2" "Add custom entries to /etc/hosts" \
        TRUE "3" "Configure Static IP & Network" \
        FALSE "4" "Set System Timezone" \
        FALSE "5" "Create New Admin User (Sudo/Wheel privileges)" \
        TRUE "6" "Configure SSH (Port, Root Login, X11 Forwarding)" \
        TRUE "7" "Update Existing Passwords (root & $REAL_USER)" 2>/dev/null)

    if [ -z "$DEPLOY_TASKS" ]; then
        print_info "Deploy cancelled by user."
        return 0
    fi

    PADDED_TASKS="|${DEPLOY_TASKS}|"

    NEW_HOST=""
    CUSTOM_HOSTS=""
    NEW_IP=""
    NEW_CIDR="16"
    NEW_GW="10.1.1.1"
    NEW_TZ=""
    NEW_ADMIN=""
    NEW_SSH_PORT=""
    DISABLE_ROOT_SSH="no"
    ENABLE_X11="yes"

    #Gathering info

    if echo "$PADDED_TASKS" | grep -q "|1|"; then
        NEW_HOST=$(zenity --entry --title="Hostname" --text="Enter the new System Hostname (e.g., srv-web-01):" 2>/dev/null)
        [ -z "$NEW_HOST" ] && return 1
    fi

    if echo "$PADDED_TASKS" | grep -q "|2|"; then
        TEMP_HOSTS="/tmp/custom_hosts.txt"
        touch "$TEMP_HOSTS"
        CUSTOM_HOSTS=$(zenity --text-info --editable --filename="$TEMP_HOSTS" \
            --title="Custom /etc/hosts Entries" \
            --text="Enter your hosts (One per line). Format: [IP] [HOSTNAME]\nExample: 10.1.1.50 db-server" \
            --width=500 --height=300 2>/dev/null)
        rm -f "$TEMP_HOSTS"
    fi

    if echo "$PADDED_TASKS" | grep -q "|3|"; then
        NET_DATA=$(zenity --forms --title="Network Configuration" \
            --text="Enter Static IP details:" \
            --add-entry="Static IP (e.g., 10.1.2.3)" \
            --add-entry="CIDR Mask (e.g., 16 for 255.255.0.0)" \
            --add-entry="Gateway / DNS (e.g., 10.1.1.1)" \
            --separator="|" 2>/dev/null)
        [ -z "$NET_DATA" ] && return 1

        NEW_IP=$(echo "$NET_DATA" | cut -d'|' -f1)
        TEMP_CIDR=$(echo "$NET_DATA" | cut -d'|' -f2)
        TEMP_GW=$(echo "$NET_DATA" | cut -d'|' -f3)
        [ -n "$TEMP_CIDR" ] && NEW_CIDR="$TEMP_CIDR"
        [ -n "$TEMP_GW" ] && NEW_GW="$TEMP_GW"
    fi

    if echo "$PADDED_TASKS" | grep -q "|4|"; then
        TZ_LIST=$(timedatectl list-timezones 2>/dev/null)
        NEW_TZ=$(echo "$TZ_LIST" | zenity --list --title="Timezone Configuration" \
            --text="Search and select your timezone:" \
            --column="Available Timezones" --width=400 --height=500 2>/dev/null)
        [ -z "$NEW_TZ" ] && return 1
    fi

    if echo "$PADDED_TASKS" | grep -q "|5|"; then
        NEW_ADMIN=$(zenity --entry --title="Admin User" --text="Enter the username for the new Admin account:" 2>/dev/null)
        [ -z "$NEW_ADMIN" ] && return 1
    fi

    if echo "$PADDED_TASKS" | grep -q "|6|"; then
        SSH_DATA=$(zenity --forms --title="SSH Security & Hardening" \
            --text="Configure SSH Access:" \
            --add-entry="New SSH Port (Leave blank to keep current)" \
            --add-combo="Disable Root SSH Login?" --combo-values="yes|no" \
            --add-combo="Enable X11 Forwarding?" --combo-values="yes|no" \
            --separator="|" 2>/dev/null)
        [ -z "$SSH_DATA" ] && return 1

        NEW_SSH_PORT=$(echo "$SSH_DATA" | cut -d'|' -f1)
        DISABLE_ROOT_SSH=$(echo "$SSH_DATA" | cut -d'|' -f2)
        ENABLE_X11=$(echo "$SSH_DATA" | cut -d'|' -f3)
    fi

    zenity --question --title="Confirm Changes" --text="Data collected successfully. Ready to apply all selected configurations to the system. Proceed?" 2>/dev/null
    if [ $? -ne 0 ]; then
        print_info "Deploy cancelled before applying changes."
        return 0
    fi

    print_info "Applying configurations..."

    #Setting configs

    if [ -n "$NEW_HOST" ]; then
        print_info "Setting hostname to $NEW_HOST..."
        hostnamectl set-hostname "$NEW_HOST"
        echo "$NEW_HOST" > /etc/hostname
        sed -i '/127.0.1.1/d' /etc/hosts
        echo "127.0.1.1\t$NEW_HOST" >> /etc/hosts
        print_success "Hostname updated."
    fi

    if [ -n "$CUSTOM_HOSTS" ]; then
        print_info "Appending custom entries to /etc/hosts..."
        echo "" >> /etc/hosts
        echo "# Custom Hosts added by Linux Master Deploy" >> /etc/hosts
        echo "$CUSTOM_HOSTS" >> /etc/hosts
        print_success "Custom hosts appended."
    fi

    if [ -n "$NEW_IP" ]; then
        print_info "Configuring network interface..."
        IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1 | tr -d ' ')

        if [ -n "$IFACE" ]; then
            if command -v netplan >/dev/null 2>&1 && ls /etc/netplan/*.yaml >/dev/null 2>&1; then
                NETPLAN_FILE="/etc/netplan/99-deploy-static.yaml"
                cat <<EOF > "$NETPLAN_FILE"
network:
  version: 2
  ethernets:
    $IFACE:
      dhcp4: no
      addresses: [$NEW_IP/$NEW_CIDR]
      routes:
        - to: default
          via: $NEW_GW
      nameservers:
        addresses: [$NEW_GW, 8.8.8.8]
EOF
                chmod 600 "$NETPLAN_FILE"
                netplan apply
                print_success "Network configured via Netplan."
            
            elif command -v nmcli >/dev/null 2>&1; then
                CON_NAME=$(nmcli -t -f NAME,DEVICE con show | grep ":$IFACE" | cut -d: -f1 | head -n1)
                [ -z "$CON_NAME" ] && CON_NAME="$IFACE"
                
                nmcli con mod "$CON_NAME" ipv4.addresses "$NEW_IP/$NEW_CIDR" ipv4.gateway "$NEW_GW" ipv4.dns "$NEW_GW" ipv4.method manual
                nmcli con up "$CON_NAME" >/dev/null 2>&1
                print_success "Network configured via NetworkManager."
            
            elif [ -d /etc/network ]; then
                cp /etc/network/interfaces /etc/network/interfaces.bak.deploy 2>/dev/null
                cat <<EOF > /etc/network/interfaces
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback
auto $IFACE
iface $IFACE inet static
    address $NEW_IP/$NEW_CIDR
    gateway $NEW_GW
    dns-nameservers $NEW_GW 8.8.8.8
    dns-search local
EOF
                print_success "Network configured via /etc/network/interfaces."
            else
                print_error "No supported network manager found. Configure manually."
            fi
        else
            print_error "Could not detect a valid physical/virtual network interface."
        fi
    fi

    if [ -n "$NEW_TZ" ]; then
        print_info "Setting Timezone to $NEW_TZ..."
        timedatectl set-timezone "$NEW_TZ"
        print_success "Timezone updated."
    fi

    if [ -n "$NEW_ADMIN" ]; then
        print_info "Creating user $NEW_ADMIN..."
        if ! id "$NEW_ADMIN" >/dev/null 2>&1; then
            useradd -m -s /bin/bash "$NEW_ADMIN"

            if grep -q "^sudo:" /etc/group; then
                usermod -aG sudo "$NEW_ADMIN"
            elif grep -q "^wheel:" /etc/group; then
                usermod -aG wheel "$NEW_ADMIN"
            fi

            ADMIN_PASS=$(zenity --password --title="Set password for $NEW_ADMIN" 2>/dev/null)
            if [ -n "$ADMIN_PASS" ]; then
                echo "$NEW_ADMIN:$ADMIN_PASS" | chpasswd
            fi
            print_success "User $NEW_ADMIN created and added to admin group."
        else
            print_warning "User $NEW_ADMIN already exists."
        fi
    fi

    if echo "$PADDED_TASKS" | grep -q "|6|"; then
        print_info "Updating SSH configuration..."

        ACTIVE_SSH_SVC=""
        if systemctl list-unit-files 2>/dev/null | grep -q "^ssh\.socket"; then
            ACTIVE_SSH_SVC="ssh.socket"
        elif systemctl is-active --quiet ssh 2>/dev/null || systemctl is-enabled --quiet ssh 2>/dev/null; then
            ACTIVE_SSH_SVC="ssh"
        elif systemctl is-active --quiet sshd 2>/dev/null || systemctl is-enabled --quiet sshd 2>/dev/null; then
            ACTIVE_SSH_SVC="sshd"
        fi

        if [ -z "$ACTIVE_SSH_SVC" ]; then
            print_error "Could not detect an active SSH service. Skipping SSH restart."
        else
            if [ -n "$NEW_SSH_PORT" ]; then
                if [ "$ACTIVE_SSH_SVC" = "ssh.socket" ]; then
                    mkdir -p /etc/systemd/system/ssh.socket.d
                    cat <<EOF > /etc/systemd/system/ssh.socket.d/listen.conf
[Socket]
ListenStream=
ListenStream=$NEW_SSH_PORT
EOF
                    systemctl daemon-reload
                    print_success "SSH Port set to $NEW_SSH_PORT via systemd socket override."
                else
                    sed -i -E '/^#?Port /d' /etc/ssh/sshd_config
                    echo "Port $NEW_SSH_PORT" >> /etc/ssh/sshd_config
                    print_success "SSH Port set to $NEW_SSH_PORT in sshd_config."
                fi
            fi

            if [ "$DISABLE_ROOT_SSH" = "yes" ]; then
                sed -i -E "s/^#?PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
                print_success "Root SSH Login disabled."
            fi

            if [ "$ENABLE_X11" = "yes" ]; then
                sed -i -E "s/^#?X11Forwarding.*/X11Forwarding yes/" /etc/ssh/sshd_config
                print_success "X11 Forwarding enabled."
            else
                sed -i -E "s/^#?X11Forwarding.*/X11Forwarding no/" /etc/ssh/sshd_config
                print_success "X11 Forwarding disabled."
            fi

            print_info "Restarting detected service: $ACTIVE_SSH_SVC..."
            if systemctl restart "$ACTIVE_SSH_SVC"; then
                print_success "Successfully applied changes to $ACTIVE_SSH_SVC."
            else
                print_error "Failed to restart $ACTIVE_SSH_SVC. Please check the service status manually."
            fi
        fi
    fi

    if echo "$PADDED_TASKS" | grep -q "|7|"; then
        ROOT_PASS=$(zenity --password --title="New password for ROOT" 2>/dev/null)
        if [ -n "$ROOT_PASS" ]; then
            echo "root:$ROOT_PASS" | chpasswd
            print_success "Root password updated."
        fi

        if [ "$REAL_USER" != "root" ]; then
            USER_PASS=$(zenity --password --title="New password for current user: $REAL_USER" 2>/dev/null)
            if [ -n "$USER_PASS" ]; then
                echo "$REAL_USER:$USER_PASS" | chpasswd
                print_success "Password for $REAL_USER updated."
            fi
        fi
    fi

    zenity --info --title="Deploy Complete" --text="Selected deployment tasks are complete!\n\nIt is highly recommended to reboot the machine now." 2>/dev/null
}
