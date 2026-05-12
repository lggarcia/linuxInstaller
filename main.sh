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
# CORE: MASTER SCRIPT (main.sh)    #
####################################

BLACK='\033[0;30m'
WHITE='\033[1;37m'
RED='\033[0;31m'
RED_LIGHT='\033[1;31m'
GREEN='\033[0;32m'
GREEN_LIGHT='\033[1;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
BLUE_LIGHT='\033[1;34m'
CYAN='\033[0;36m'
CYAN_LIGHT='\033[1;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
PURPLE_LIGHT='\033[1;35m'
GRAY_LIGHT='\033[0;37m'
GRAY_DARK='\033[1;30m'
NC='\033[0m' # No Color

printf "\n"
printf "%b\n" "${GREEN}###############################${GRAY_DARK}#${NC}"
printf "%b\n" "${GREEN}# ${YELLOW}LL${GRAY_DARK}L            ${BLUE}GGGGGGG${GRAY_DARK}G     ${GREEN} #${GRAY_DARK}##${NC}"
printf "%b\n" "${GREEN}# ${YELLOW}LL${GRAY_DARK}L            ${BLUE}GG${GRAY_DARK}G          ${GREEN} #${GRAY_DARK}##${NC}"
printf "%b\n" "${GREEN}# ${YELLOW}LL${GRAY_DARK}L            ${BLUE}GG${GRAY_DARK}G ${BLUE}GGGG${GRAY_DARK}G     ${GREEN}#${GRAY_DARK}##${NC}"
printf "%b\n" "${GREEN}# ${YELLOW}LL${GRAY_DARK}L            ${BLUE}GG${GRAY_DARK}G   ${BLUE}GG${GRAY_DARK}G     ${GREEN}#${GRAY_DARK}##${NC}"
printf "%b\n" "${GREEN}# ${YELLOW}LLLLLLL${GRAY_DARK}L ${WHITE} X${GRAY_DARK}X   ${BLUE}GGGGGGGG${GRAY_DARK}G  ${WHITE}X${GRAY_DARK}X ${GREEN}#${GRAY_DARK}##${NC}"
printf "%b\n" "${GREEN}###############################${GRAY_DARK}###${NC}"
printf "%b\n" "${GREEN}#       ${WHITE}LUCIANOGG.INFO        ${GREEN}#${GRAY_DARK}###${NC}"
printf "%b\n" "${GREEN}###############################${GRAY_DARK}###${NC}"
printf "%b\n" "${GRAY_DARK}##################################${NC}"
printf "%b\n" "${GRAY_DARK} #################################${NC}"
printf "\n"

#!/bin/sh
# =========================================================
# LINUX MASTER ASSISTANT - ENTRY POINT
# =========================================================

PRG="$0"
while [ -h "$PRG" ]; do
    ls=$(ls -ld "$PRG")
    link=$(expr "$ls" : '.*-> \(.*\)$')
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG=$(dirname "$PRG")/"$link"
    fi
done
PROJECT_ROOT=$(cd "$(dirname "$PRG")" && pwd)

#PROJECT_ROOT=$(cd "$(dirname "$0")" && pwd)
export PROJECT_ROOT

#shellcheck disable=SC1091
. "$PROJECT_ROOT/core/ui.sh"

print_msg "${GREEN}Starting system initialization...${NC}"

if [ "$(id -u)" -ne 0 ]; then
   print_error "This script must be executed as ROOT (sudo)."
   exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
   print_error "This script requires a system with 'systemd' (systemctl). Operation aborted."
   exit 1
fi

export REAL_USER=${SUDO_USER:-$(whoami)}
export REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
export REAL_SHELL=$(getent passwd "$REAL_USER" | cut -d: -f7)
print_info "Session initiated by user: $REAL_USER ($REAL_HOME)"

#shellcheck disable=SC1091
. "$PROJECT_ROOT/core/detectOS.sh"
detect_package_manager

check_dependencies()
{
    print_info "Checking system dependencies..."

    if ! command -v zenity >/dev/null 2>&1; then
        print_warning "Zenity is not installed. It is required for the GUI menu."
        printf "Do you want to install Zenity now? [Y/n] "
        read -r response

        case "$response" in
            y|Y|yes|Yes|"")
                print_info "Installing Zenity using $OS_FAMILY package manager..."

                $PM_UPDATE
                $PM_INSTALL zenity

                if [ $? -ne 0 ]; then
                    print_error "Failed to install Zenity. Aborting."
                    exit 1
                fi
                print_success "Zenity installed successfully."
                ;;
            *)
                print_error "Installation skipped. The script cannot continue without Zenity."
                exit 1
                ;;
        esac
    else
        print_success "All dependencies are met (Zenity is ready)."
    fi
}

check_dependencies


print_info "Loading main menu..."
. "$PROJECT_ROOT/core/menu.sh"

print_success "Setup complete."
