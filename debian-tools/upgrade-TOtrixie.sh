#!/bin/sh
####################################
#       __    ______  ______       #
#      |  |  |  ____||  ____|      #
#      |  |  | | __  | | __        #
#      |  |__| ||_ | | ||_ |       #
#      |_____|\____| |_____|       #
# -------------------------------- #
#   >> https://lucianogg.info      #
########################################
#DEBIAN TOOLS:Update Bookworm to Trixie#
########################################

upgrade_to_trixie()
{
    zenity --warning --title="DANGEROUS OPERATION" \
        --text="This will upgrade your system sources from 'bookworm' to 'trixie'.\n\nEnsure you have backups. Do you want to proceed?" 2>/dev/null || return 1

    print_info "Starting upgrade process to Debian 13 (Trixie)..."

    apt update
    apt upgrade -y
    apt dist-upgrade -y
    apt clean
    apt autoremove -y
    apt --fix-broken install -y
    dpkg --configure -a

    print_info "Updating APT sources from Bookworm to Trixie..."
    sed -i 's/bookworm/trixie/g' /etc/apt/sources.list
    find /etc/apt/sources.list.d -name "*.list" -exec sed -i 's/bookworm/trixie/g' {} \;

    print_info "Fetching new Trixie packages..."
    apt update
    print_info "Running minimal upgrade without new packages..."
    apt upgrade --without-new-pkgs -y
    print_info "Running full system upgrade..."
    apt full-upgrade -y

    apt autoremove -y
    apt autoclean -y
    apt update

    print_success "Upgrade completed. System version verification:"
    cat /etc/debian_version
    lsb_release -a
    cat /etc/os-release
    apt list --upgradable

    zenity --info --text="Upgrade to Debian 13 (Trixie) finished successfully.\n\nIt is highly recommended to reboot the system now." 2>/dev/null
}
