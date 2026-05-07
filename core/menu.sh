#!/bin/sh
####################################
#       __    ______  ______       #
#      |  |  |  ____||  ____|      #
#      |  |  | | __  | | __        #
#      |  |__| ||_ | | ||_ |       #
#      |_____|\____| |_____|       #
# -------------------------------- #
#   >> https://lucianogg.info      #
####################################
# CORE: MAIN MENU (menu.sh)        #
####################################

get_dynamic_height()
{
    item_count="$1"
    row_height=30
    ui_padding=160
    calculated_height=$(( (item_count * row_height) + ui_padding ))

    if command -v xdpyinfo >/dev/null 2>&1; then
        screen_h=$(xdpyinfo | awk '/dimensions:/ {split($2, dim, "x"); print dim[2]; exit}')
    elif command -v xrandr >/dev/null 2>&1; then
        screen_h=$(xrandr --current 2>/dev/null | grep '\*' | awk '{print $1}' | cut -d 'x' -f2 | head -n 1)
    else
        screen_h=1080
    fi

    # POSIX sanity check: ensure screen_h is a valid integer
    case "$screen_h" in
        *[!0-9]*) screen_h=1080 ;;
        "") screen_h=1080 ;;
    esac

    max_height=$(( screen_h - 100 ))

    if [ "$calculated_height" -gt "$max_height" ]; then
        echo "$max_height"
    else
        echo "$calculated_height"
    fi
}

show_menu()
{
    while true; do
        total_options=10
        perfect_height=$(get_dynamic_height "$total_options")

        choice=$(zenity --list \
            --title="Linux Master Assistant" \
            --text="Select an action to perform:" \
            --column="ID" --column="Action" \
            "1" "New Machine Deploy Assistant" \
            "2" "System Updater" \
            "3" "Install Applications" \
            "4" "Uninstall Applications" \
            "5" "Services Management" \
            "6" "Shell Customizer" \
            "7" "Firewall Manager" \
            "8" "Task Scheduler (Cron)"\
            "9" "Log & Audit Manager"\
            "10" "Hardware Information" \
            "11" "Debian Upgrade -> Bullseye (11) to Bookworm(12) - DANGEROUS" \
            "12" "Debian Upgrade -> Bookworm(12) to Trixie(13) - DANGEROUS" \
            "0" "Exit" \
            --height="$perfect_height" --width=500 2>/dev/null)

        if [ -z "$choice" ] || [ "$choice" = "0" ]; then
            print_info "Exiting Linux Master Assistant. Goodbye!"
            break
        fi

        case "$choice" in
            1)
                if [ -f "$PROJECT_ROOT/modules/deploy.sh" ]; then
                    . "$PROJECT_ROOT/modules/deploy.sh"
                    run_deploy
                else
                    zenity --error --text="Module 'deploy.sh' not found." 2>/dev/null
                fi
                ;;
            2|3|4)
                if [ -f "$PROJECT_ROOT/modules/packages.sh" ]; then
                    . "$PROJECT_ROOT/modules/packages.sh"
                    case "$choice" in
                        2) run_updater ;;
                        3) install_apps ;;
                        4) remove_apps ;;
                    esac
                else
                    zenity --error --text="Module 'packages.sh' not found." 2>/dev/null
                fi
                ;;
            5)
                if [ -f "$PROJECT_ROOT/modules/services.sh" ]; then
                    . "$PROJECT_ROOT/modules/services.sh"
                    manage_services
                else
                    zenity --error --text="Module 'services.sh' not found." 2>/dev/null
                fi
                ;;
            6)
                if [ -f "$PROJECT_ROOT/modules/customShell.sh" ]; then
                    . "$PROJECT_ROOT/modules/customShell.sh"
                    configure_shell
                else
                    zenity --error --text="Module 'customShell.sh' not found." 2>/dev/null
                fi
                ;;
            7)
                . "$PROJECT_ROOT/modules/firewall.sh"
                manage_firewall
                ;;
            8)
                . "$PROJECT_ROOT/modules/cron.sh"
                manage_cron
                ;;    
            9)
                . "$PROJECT_ROOT/modules/logs.sh"
                manage_logs
                ;;         
            10)
                if [ -f "$PROJECT_ROOT/modules/hardware.sh" ]; then
                    . "$PROJECT_ROOT/modules/hardware.sh"
                    get_hardware_info
                else
                    zenity --error --text="Module 'hardware.sh' not found." 2>/dev/null
                fi
                ;;
            11)
                if [ "$OS_FAMILY" = "debian" ]; then
                    if [ -f "$PROJECT_ROOT/debian-tools/upgrade-TObookworm.sh" ]; then
                        . "$PROJECT_ROOT/debian-tools/upgrade-TObookworm.sh"
                        upgrade_to_bookworm
                    else
                        zenity --error --text="Module 'upgrade-TObookworm.sh' not found." 2>/dev/null
                    fi
                else
                    zenity --warning --text="This feature is exclusive to Debian systems." 2>/dev/null
                fi
                ;;
            12)
                if [ "$OS_FAMILY" = "debian" ]; then
                    if [ -f "$PROJECT_ROOT/debian-tools/upgrade-TOtrixie.sh" ]; then
                        . "$PROJECT_ROOT/debian-tools/upgrade-TOtrixie.sh"
                        upgrade_to_trixie
                    else
                        zenity --error --text="Module 'upgrade-TOtrixie.sh' not found." 2>/dev/null
                    fi
                else
                    zenity --warning --text="This feature is exclusive to Debian systems." 2>/dev/null
                fi
                ;;
        esac
    done
}

show_menu
