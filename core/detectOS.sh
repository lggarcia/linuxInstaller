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
# CORE: OS DETECTOR (detectOS.sh)  #
####################################

detect_package_manager()
{
    print_info "Analyzing operating system..."

    if command -v apt-get >/dev/null 2>&1; then
        PM_UPDATE="apt-get update"
        PM_UPGRADE="apt-get upgrade -y"
        PM_INSTALL="apt-get install -y"
        PM_REMOVE="apt-get purge -y"
        PM_CLEAN="apt-get autoremove -y && apt-get clean"
        OS_FAMILY="debian"
        print_success "Debian base detected (APT)."

    elif command -v dnf >/dev/null 2>&1; then
        PM_UPDATE="dnf check-update"
        PM_UPGRADE="dnf upgrade -y"
        PM_INSTALL="dnf install -y"
        PM_REMOVE="dnf remove -y"
        PM_CLEAN="dnf autoremove -y && dnf clean all"
        OS_FAMILY="rhel"
        print_success "RHEL/Fedora base detected (DNF)."

    elif command -v pacman >/dev/null 2>&1; then
        PM_UPDATE="pacman -Sy"
        PM_UPGRADE="pacman -Syu --noconfirm"
        PM_INSTALL="pacman -S --noconfirm"
        PM_REMOVE="pacman -Rns --noconfirm"
        PM_CLEAN="pacman -Sc --noconfirm"
        OS_FAMILY="arch"
        print_success "Arch Linux base detected (Pacman)."

    elif command -v zypper >/dev/null 2>&1; then
        PM_UPDATE="zypper refresh"
        PM_UPGRADE="zypper update -y"
        PM_INSTALL="zypper install -y"
        PM_REMOVE="zypper remove -y"
        PM_CLEAN="zypper clean"
        OS_FAMILY="suse"
        print_success "openSUSE base detected (Zypper)."

    else
        print_error "Unsupported package manager. The script cannot continue safely."
        exit 1
    fi

    # Export variables so other scripts can read them
    export PM_UPDATE PM_UPGRADE PM_INSTALL PM_REMOVE PM_CLEAN OS_FAMILY
}
