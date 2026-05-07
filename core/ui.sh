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
# CORE: USER INTERFACE (ui.sh)     #
####################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
NC='\033[0m'

print_msg()
{
    printf "%b\n" "$*"
}

print_info()
{
    printf "%b\n" "${ORANGE}[INFO]${NC} $*"
}

print_success()
{
    printf "%b\n" "${GREEN}[OK]${NC} $*"
}

print_error()
{
    printf "%b\n" "${RED}[ERRO]${NC} $*"
}

print_warning()
{
    printf "%b\n" "${YELLOW}[AVISO]${NC} $*"
}
