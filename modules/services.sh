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
    print_info "Generating a clean list of active system services..."

    #Filtered only for services that are loaded and active/running to avoid clutter
    TEMP_SVC_LIST="/tmp/systemd_services_list.txt"
    > "$TEMP_SVC_LIST"

    systemctl list-units --type=service --state=active --no-pager --no-legend 2>/dev/null | \
        awk '{print $1}' | grep '\.service$' | sed 's/\.service$//' | \
        while read -r svc; do
            printf "FALSE %s " "$svc" >> "$TEMP_SVC_LIST"
        done

    SERVICE_LIST=$(cat "$TEMP_SVC_LIST")
    rm -f "$TEMP_SVC_LIST"

    if [ -z "$SERVICE_LIST" ]; then
        zenity --error --title="Service Manager Error" \
            --text="Failed to retrieve the list of active services or the list is empty." 2>/dev/null
        return 1
    fi

    # Display the checklist menu
    SELECTED_SERVICES=$(zenity --list \
        --title="Service Manager" \
        --text="Select the services you wish to immediately STOP and DISABLE from starting on boot.\n\n<span color='red'><b>WARNING:</b> Disabling critical services may break your system.</span>" \
        --checklist \
        --width=600 --height=550 \
        --separator='|' \
        --column="Select" --column="Service Name" \
        $SERVICE_LIST 2>/dev/null)

    if [ -z "$SELECTED_SERVICES" ]; then
        print_info "Service management cancelled."
        return 0
    fi

    zenity --question --title="Confirm Action" \
        --text="You are about to STOP and permanently DISABLE the selected services.\n\nDo you wish to proceed?" 2>/dev/null

    if [ $? -ne 0 ]; then
        print_info "Operation aborted by user."
        return 0
    fi

    print_info "Processing selected services..."

    FAIL_COUNT=0
    SUCCESS_COUNT=0

    echo "$SELECTED_SERVICES" | tr '|' '\n' | while read -r SERVICE; do
        CLEAN_SERVICE=$(echo "$SERVICE" | sed 's/"//g')

        [ -z "$CLEAN_SERVICE" ] && continue

        print_info "Attempting to stop $CLEAN_SERVICE..."
        if systemctl stop "$CLEAN_SERVICE" 2>/dev/null; then
            print_success "$CLEAN_SERVICE stopped."
        else
            print_error "Failed to stop $CLEAN_SERVICE."
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi

        print_info "Attempting to disable $CLEAN_SERVICE..."
        if systemctl disable "$CLEAN_SERVICE" 2>/dev/null; then
            print_success "$CLEAN_SERVICE disabled."
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            print_error "Failed to disable $CLEAN_SERVICE."
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    done

    if [ "$FAIL_COUNT" -eq 0 ]; then
        zenity --info --title="Operation Complete" \
            --text="Successfully STOPPED and DISABLED all selected services.\n\nTotal affected: $SUCCESS_COUNT" 2>/dev/null
    else
        zenity --warning --title="Completed with Errors" \
            --text="Service management finished, but some operations failed.\n\nSuccesses: $SUCCESS_COUNT\nFailures: $FAIL_COUNT\n\nCheck the terminal output for details." 2>/dev/null
    fi
}
