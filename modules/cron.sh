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
# MODULE: CRON UTILITY (CRON.sh)   #
####################################

manage_cron()
{
    while true; do
        CRON_ACTION=$(zenity --list \
            --title="Task Scheduler (Cron)" \
            --text="Manage recurring tasks for user: $REAL_USER" \
            --width=650 --height=450 \
            --column="ID" --column="Action" --column="Description" \
            --hide-column=1 \
            "1" "List My Tasks" "Show all active scheduled tasks." \
            "2" "Add New Task" "Create a new scheduled job." \
            "3" "Remove Selected Tasks" "Choose specific tasks to delete." \
            "4" "Clear All Tasks" "Wipe the entire crontab for this user." \
            "5" "Cron Tutorial" "Quick guide on how timing works." 2>/dev/null)

        if [ -z "$CRON_ACTION" ]; then break; fi

        case "$CRON_ACTION" in
            1)
                crontab -u "$REAL_USER" -l > /tmp/cron_list.txt 2>/dev/null
                if [ ! -s /tmp/cron_list.txt ]; then
                    zenity --info --text="No active tasks found for $REAL_USER." 2>/dev/null
                else
                    zenity --text-info --title="Current Tasks" --filename="/tmp/cron_list.txt" --width=700 --height=400 2>/dev/null
                fi
                rm -f /tmp/cron_list.txt
                ;;

            2)
                NEW_JOB=$(zenity --forms --title="Add Scheduled Task" \
                    --text="Enter timing and command (Timezone: Madrid):\nExample: 0 3 * * * /path/to/script.sh" \
                    --add-entry="Timing (m h dom mon dow)" \
                    --add-entry="Command to execute" \
                    --separator="|" 2>/dev/null)

                if [ -n "$NEW_JOB" ]; then
                    TIMING=$(echo "$NEW_JOB" | cut -d'|' -f1)
                    CMD=$(echo "$NEW_JOB" | cut -d'|' -f2)
                    (crontab -u "$REAL_USER" -l 2>/dev/null; echo "$TIMING $CMD") | crontab -u "$REAL_USER" -
                    print_success "New task added for $REAL_USER."
                fi
                ;;

            3)
                CRON_LIST=$(crontab -u "$REAL_USER" -l 2>/dev/null | grep -v "^#" | grep -v "^$")

                if [ -z "$CRON_LIST" ]; then
                        zenity --warning --title="Crontab Vazio" \
                            --text="Nenhuma tarefa agendada encontrada para o usuário $REAL_USER." 2>/dev/null
                        return 0
                    fi

                TASK_TO_REMOVE=$(echo "$CRON_LIST" | zenity --list \
                        --title="Remover Tarefa Cron" \
                        --text="Selecione a tarefa exata que deseja remover:" \
                        --column="Comandos Agendados" --width=700 --height=300 2>/dev/null)

                    if [ -n "$TASK_TO_REMOVE" ]; then
                    crontab -u "$REAL_USER" -l 2>/dev/null | grep -F -v "$TASK_TO_REMOVE" | crontab -u "$REAL_USER" -

                    print_success "Tarefa removida."
                    zenity --info --title="Sucesso" --text="A tarefa foi removida do crontab." 2>/dev/null
                    fi
                ;;
            4)
                zenity --question --text="Are you sure you want to WIPE ALL tasks for $REAL_USER?" 2>/dev/null
                if [ $? -eq 0 ]; then
                    crontab -u "$REAL_USER" -r 2>/dev/null
                    print_success "Crontab cleared."
                fi
                ;;

            5)
                zenity --info --title="Cron Guide" \
                    --text="The five fields are:\n1. Minute (0-59)\n2. Hour (0-23)\n3. Day of Month (1-31)\n4. Month (1-12)\n5. Day of Week (0-6)\n\nExample: '30 22 * * *' runs every day at 22:30." 2>/dev/null
                ;;
        esac
    done
}
