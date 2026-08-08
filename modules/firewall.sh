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
#MODULE:FIREWALL TOOL (firewall.sh)#
####################################

manage_firewall() 
{
    print_info "Detecting active firewall manager..."

    FW_TYPE="unknown"

    if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld; then
        FW_TYPE="firewalld"
        print_success "Detected: firewalld (Red Hat / Enterprise)"
    elif command -v ufw >/dev/null 2>&1 && systemctl is-active --quiet ufw; then
        FW_TYPE="ufw"
        print_success "Detected: UFW (Ubuntu / Debian)"
    elif command -v iptables >/dev/null 2>&1; then
        FW_TYPE="iptables"
        print_success "Detected: iptables (Legacy / Fallback)"
    else
        zenity --error --text="No supported active firewall found. Please install ufw or firewalld." 2>/dev/null
        return 1
    fi

    while true; do
        FW_ACTION=$(zenity --list \
            --title="Firewall Manager ($FW_TYPE)" \
            --text="Select an action to manage your network security:" \
            --width=550 --height=400 \
            --column="ID" --column="Action" --column="Description" \
            --hide-column=1 \
            "1" "Allow Port" "Open a specific port (e.g., 80, 443)." \
            "2" "Block Port" "Close a specific port." \
            "3" "List Rules" "Show currently active firewall rules." \
            "4" "Panic: Block All" "Drop all incoming connections (Keeps SSH open)." 2>/dev/null)

        if [ -z "$FW_ACTION" ]; then
            print_info "Exiting Firewall Manager."
            break
        fi

        case "$FW_ACTION" in
            1|2)
                ACTION_VERB="Allow"
                [ "$FW_ACTION" = "2" ] && ACTION_VERB="Block"

                PORT_DATA=$(zenity --forms --title="$ACTION_VERB Port" \
                    --text="Enter port details to $ACTION_VERB:" \
                    --add-entry="Port Number (e.g., 8080)" \
                    --add-combo="Protocol" --combo-values="tcp|udp" \
                    --separator="|" 2>/dev/null)

                if [ -n "$PORT_DATA" ]; then
                    PORT=$(echo "$PORT_DATA" | cut -d'|' -f1)
                    PROTO=$(echo "$PORT_DATA" | cut -d'|' -f2)

                    if [ -z "$PORT" ] || ! echo "$PORT" | grep -qE '^[0-9]+$'; then
                        zenity --error --text="Invalid port number." 2>/dev/null
                        continue
                    fi

                    print_info "Applying rule: $ACTION_VERB $PORT/$PROTO via $FW_TYPE..."

                    if [ "$FW_TYPE" = "firewalld" ]; then
                        if [ "$FW_ACTION" = "1" ]; then
                            firewall-cmd --add-port="$PORT/$PROTO" --permanent
                        else
                            firewall-cmd --remove-port="$PORT/$PROTO" --permanent
                        fi
                        firewall-cmd --reload
                    
                    elif [ "$FW_TYPE" = "ufw" ]; then
                        if [ "$FW_ACTION" = "1" ]; then
                            ufw allow "$PORT/$PROTO"
                        else
                            ufw deny "$PORT/$PROTO"
                        fi
                    
                    elif [ "$FW_TYPE" = "iptables" ]; then
                        if [ "$FW_ACTION" = "1" ]; then
                            iptables -A INPUT -p "$PROTO" --dport "$PORT" -j ACCEPT
                        else
                            iptables -A INPUT -p "$PROTO" --dport "$PORT" -j DROP
                        fi
                        # Save depends on distro, but trying standard paths
                        command -v netfilter-persistent >/dev/null && netfilter-persistent save
                        command -v service >/dev/null && service iptables save 2>/dev/null
                    fi
                    
                    print_success "Rule applied successfully."
                    zenity --info --text="Firewall rule for $PORT/$PROTO ($ACTION_VERB) applied successfully!" 2>/dev/null
                fi
                ;;
            
            3)
                print_info "Fetching firewall rules..."
                > /tmp/fw_rules.txt
                
                if [ "$FW_TYPE" = "firewalld" ]; then
                    firewall-cmd --list-all >> /tmp/fw_rules.txt
                elif [ "$FW_TYPE" = "ufw" ]; then
                    ufw status verbose >> /tmp/fw_rules.txt
                elif [ "$FW_TYPE" = "iptables" ]; then
                    iptables -L -n -v >> /tmp/fw_rules.txt
                fi

                zenity --text-info --title="Active Firewall Rules" \
                    --filename="/tmp/fw_rules.txt" --width=700 --height=500 \
                    --font="Monospace 10" 2>/dev/null
                rm -f /tmp/fw_rules.txt
                ;;

            4)
                zenity --question --title="WARNING: PANIC MODE" \
                    --text="This will BLOCK ALL incoming traffic except SSH (port 22).\nAre you absolutely sure you are under attack and want to lockdown the server?" 2>/dev/null
                
                if [ $? -eq 0 ]; then
                    print_info "Initiating SERVER LOCKDOWN..."
                    
                    if [ "$FW_TYPE" = "firewalld" ]; then
                        firewall-cmd --panic-on
                        # Note: panic-on drops everything, even SSH on some setups. 
                        # To be safer for a remote tool, it was set to default droping all and allow ssh.
                        firewall-cmd --panic-off 2>/dev/null
                        firewall-cmd --set-default-zone=drop
                        firewall-cmd --add-service=ssh --permanent
                        firewall-cmd --reload
                    elif [ "$FW_TYPE" = "ufw" ]; then
                        ufw default deny incoming
                        ufw allow ssh
                        ufw reload
                    elif [ "$FW_TYPE" = "iptables" ]; then
                        iptables -P INPUT DROP
                        iptables -A INPUT -p tcp --dport 22 -j ACCEPT
                        iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
                    fi
                    
                    print_success "Lockdown complete. Only SSH is allowed."
                    zenity --warning --text="SERVER LOCKDOWN INITIATED.\n\nAll ports except SSH have been blocked." 2>/dev/null
                fi
                ;;
        esac
    done
}
