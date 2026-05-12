#!/bin/sh
####################################
#        __    ______  ______      #
#       |  |  |  ____||  ____|     #
#       |  |  | | __  | | __       #
#       |  |__| ||_ | | ||_ |      #
#       |_____|\____| |_____|      #
# -------------------------------- #
#   >> https://lucianogg.info      #
######################################
#MODULE:SERVICES MANAGER(services.sh)#
######################################

manage_services()
{
    ACTION=$(zenity --list --title="Service Manager" \
        --text="Select the desired operation:" \
        --column="ID" --column="Action" --hide-column=1 \
        "1" "Stop and Disable (Active Services)" \
        "2" "Start and Enable (Disabled Services)" \
        "3" "Restart (Active Services)" 2>/dev/null)

    [ -z "$ACTION" ] && return 0

    print_info "Generating service list..."
    TEMP_SVC_LIST="/tmp/systemd_services_list.txt"
    > "$TEMP_SVC_LIST"

    if [ "$ACTION" = "1" ] || [ "$ACTION" = "3" ]; then
        systemctl list-units --type=service --state=active --no-pager --no-legend 2>/dev/null | \
            awk '{print $1}' | grep '\.service$' | sed 's/\.service$//' | \
            while read -r svc; do printf "FALSE %s " "$svc" >> "$TEMP_SVC_LIST"; done
    elif [ "$ACTION" = "2" ]; then
        systemctl list-unit-files --type=service --state=disabled --no-pager --no-legend 2>/dev/null | \
            awk '{print $1}' | grep '\.service$' | sed 's/\.service$//' | \
            while read -r svc; do printf "FALSE %s " "$svc" >> "$TEMP_SVC_LIST"; done
    fi

    SERVICE_LIST=$(cat "$TEMP_SVC_LIST")
    rm -f "$TEMP_SVC_LIST"

    if [ -z "$SERVICE_LIST" ]; then
        zenity --error --title="Service Manager" --text="No services found for this operation." 2>/dev/null
        return 1
    fi

    SELECTED_SERVICES=$(zenity --list \
        --title="Service Manager" \
        --text="Select the services from the list below:" \
        --checklist --width=600 --height=550 --separator='|' \
        --column="Select" --column="Service Name" \
        $SERVICE_LIST 2>/dev/null)

    [ -z "$SELECTED_SERVICES" ] && { print_info "Operation cancelled."; return 0; }

    FAIL_COUNT=0
    SUCCESS_COUNT=0

    # Solução do Subshell Trap: Usar IFS e for loop em vez de pipe para while
    OLD_IFS="$IFS"
    IFS='|'

    for SERVICE in $SELECTED_SERVICES; do
        IFS="$OLD_IFS" # Restaura o IFS dentro do loop para não quebrar outros comandos

        CLEAN_SERVICE=$(echo "$SERVICE" | sed 's/"//g')
        [ -z "$CLEAN_SERVICE" ] && { IFS='|'; continue; }

        case "$ACTION" in
            1)
                print_info "Stopping and disabling $CLEAN_SERVICE..."
                systemctl stop "$CLEAN_SERVICE" 2>/dev/null && systemctl disable "$CLEAN_SERVICE" 2>/dev/null
                STATUS=$?
                ;;
            2)
                print_info "Enabling and starting $CLEAN_SERVICE..."
                systemctl enable "$CLEAN_SERVICE" 2>/dev/null && systemctl start "$CLEAN_SERVICE" 2>/dev/null
                STATUS=$?
                ;;
            3)
                print_info "Restarting $CLEAN_SERVICE..."
                systemctl restart "$CLEAN_SERVICE" 2>/dev/null
                STATUS=$?
                ;;
        esac

        if [ "$STATUS" -eq 0 ]; then
            print_success "$CLEAN_SERVICE processed successfully."
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            print_error "Failed to process $CLEAN_SERVICE."
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi

        IFS='|' # Configura o IFS de volta para continuar o loop
    done
    IFS="$OLD_IFS" # Restaura o IFS permanentemente ao final

    if [ "$FAIL_COUNT" -eq 0 ]; then
        zenity --info --title="Operation Complete" --text="All services processed successfully!\n\nTotal affected: $SUCCESS_COUNT" 2>/dev/null
    else
        zenity --warning --title="Completed with Errors" --text="Some service operations failed.\n\nSuccesses: $SUCCESS_COUNT\nFailures: $FAIL_COUNT" 2>/dev/null
    fi
}

