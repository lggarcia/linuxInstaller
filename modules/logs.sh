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
# MODULE: LOGS UTILITY (logs.sh)   #
####################################

manage_logs() 
{
    while true; do
        LOG_ACTION=$(zenity --list \
            --title="Log & Audit Manager" \
            --text="Select an action for system logs and logrotate:\n(Uses systemd journalctl for universal compatibility)" \
            --width=650 --height=450 \
            --column="ID" --column="Action" --column="Description" \
            --hide-column=1 \
            "1" "View System Events" "Shows the last 200 general system/app errors." \
            "2" "View Kernel Logs (dmesg)" "Hardware and driver initialization logs." \
            "3" "View Login History" "See Success/Fail records for Local & SSH logins." \
            "4" "Force Log Rotation" "Manually trigger logrotate (Useful to free up space)." \
            "5" "Create Custom Logrotate" "Build a logrotate rule for a custom app." \
            "6" "Check Disk Usage (/var/log)" "See how much space logs are consuming." 2>/dev/null)

        if [ -z "$LOG_ACTION" ]; then
            print_info "Exiting Log Manager."
            break
        fi

        case "$LOG_ACTION" in
            1)
                TMP_LOG="/tmp/sys_log.txt"
                if command -v journalctl >/dev/null 2>&1; then
                    journalctl -n 200 --no-pager > "$TMP_LOG"
                else
                    tail -n 200 /var/log/syslog > "$TMP_LOG" 2>/dev/null || echo "Log não encontrado." > "$TMP_LOG"
                fi
                zenity --text-info --title="System Logs" --filename="$TMP_LOG" --width=850 --height=600 2>/dev/null
                rm -f "$TMP_LOG"
                ;;
            2)
                TMP_LOG="/tmp/kern_log.txt"
                if command -v journalctl >/dev/null 2>&1; then
                    journalctl -k -n 200 --no-pager > "$TMP_LOG"
                else
                    dmesg | tail -n 200 > "$TMP_LOG"
                fi
                zenity --text-info --title="Kernel Logs" --filename="$TMP_LOG" --width=850 --height=600 2>/dev/null
                rm -f "$TMP_LOG"
                ;;
            3)
                print_info "Generating comprehensive login report..."
                LOG_EXPORT="$REAL_HOME/authLog_export_$(date +%Y%m%d_%H%M%S).txt"
                
                echo "============================================================" > "$LOG_EXPORT"
                echo " 🟢 SUCCESSFUL LOGINS (Local & SSH)" >> "$LOG_EXPORT"
                echo "============================================================" >> "$LOG_EXPORT"
                last -a -F | head -n 15 >> "$LOG_EXPORT"
                echo "" >> "$LOG_EXPORT"
                
                echo "============================================================" >> "$LOG_EXPORT"
                echo " 🔴 FAILED LOGINS  (Local & SSH)" >> "$LOG_EXPORT"
                echo "============================================================" >> "$LOG_EXPORT"
                lastb -a -F 2>/dev/null | head -n 15 >> "$LOG_EXPORT"
                echo "" >> "$LOG_EXPORT"
                
                echo "============================================================" >> "$LOG_EXPORT"
                echo " 📜 RAW AUTHENTICATION LOGS (Systemd Journal)" >> "$LOG_EXPORT"
                echo "============================================================" >> "$LOG_EXPORT"
                journalctl _COMM=sshd _COMM=login -n 100 --no-pager >> "$LOG_EXPORT"
                
                # Ensure the user owns the file, not root
                chown "$REAL_USER:$REAL_USER" "$LOG_EXPORT"

                zenity --text-info --title="Security: Login & Authentication" \
                    --filename="$LOG_EXPORT" --width=850 --height=750 \
                    --font="Monospace 10" 2>/dev/null
                
                print_success "Login report exported and saved to: $LOG_EXPORT"
                ;;
            4)
                print_info "Forcing global log rotation..."
                logrotate -v -f /etc/logrotate.conf > /tmp/logrotate_out.txt 2>&1
                zenity --text-info --title="Logrotate Execution Results" \
                    --filename="/tmp/logrotate_out.txt" --width=700 --height=500 \
                    --font="Monospace 10" 2>/dev/null
                rm -f /tmp/logrotate_out.txt
                print_success "Log rotation triggered."
                ;;
            5)
                LR_DATA=$(zenity --forms --title="Custom Logrotate Builder" \
                    --text="Create a rule to prevent a custom app from filling the disk:" \
                    --add-entry="Rule Name (e.g., my_app)" \
                    --add-entry="Log Path (e.g., /var/log/myapp/*.log)" \
                    --add-combo="Rotation Frequency" --combo-values="daily|weekly|monthly" \
                    --add-entry="Files to keep (e.g., 7 for a week)" \
                    --separator="|" 2>/dev/null)

                if [ -n "$LR_DATA" ]; then
                    LR_NAME=$(echo "$LR_DATA" | cut -d'|' -f1 | tr -d ' ')
                    LR_PATH=$(echo "$LR_DATA" | cut -d'|' -f2)
                    LR_FREQ=$(echo "$LR_DATA" | cut -d'|' -f3)
                    LR_KEEP=$(echo "$LR_DATA" | cut -d'|' -f4)

                    if [ -n "$LR_NAME" ] && [ -n "$LR_PATH" ]; then
                        CONF_FILE="/etc/logrotate.d/$LR_NAME"
                        
                        cat <<EOF > "$CONF_FILE"
# Generated by Linux Master Assistant
$LR_PATH {
    $LR_FREQ
    rotate $LR_KEEP
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
}
EOF
                        print_success "Logrotate rule created at $CONF_FILE"
                        AUDIT_FILE="$REAL_HOME/logrotate_modifications.txt"
                        LOG_MSG="$(date '+%Y-%m-%d %H:%M:%S') - File $CONF_FILE was modified by $REAL_USER to edit log rotate rule for service $LR_NAME"
                        
                        echo "$LOG_MSG" >> "$AUDIT_FILE"
                        chown "$REAL_USER:$REAL_USER" "$AUDIT_FILE"
                        
                        zenity --info --title="Success" \
                            --text="File modified:\n$CONF_FILE\n\nAudit log updated at:\n$AUDIT_FILE" 2>/dev/null
                    else
                        zenity --error --text="Rule Name and Log Path are mandatory." 2>/dev/null
                    fi
                fi
                ;;
            6)
                print_info "Analyzing /var/log size..."
                LOG_SIZE=$(du -sh /var/log 2>/dev/null | awk '{print $1}')
                TOP_FILES=$(du -ah /var/log 2>/dev/null | sort -rh | head -n 6 | tail -n 5)
                
                zenity --info --title="Log Directory Usage" \
                    --text="<b>Total Size of /var/log:</b> $LOG_SIZE\n\n<b>Top 5 Largest Log Files/Folders:</b>\n$TOP_FILES" 2>/dev/null
                ;;
        esac
    done
}
