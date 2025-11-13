###########################
#!/bin/bash
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
###########################
BANNER="${YELLOW}# ${WHITE}# ${GRAY_LIGHT}# ${GRAY_DARK}# ${BLACK}# ${GRAY_LIGHT}# ${WHITE}# ${RED_LIGHT}# ${RED}# ${RED_LIGHT}# ${ORANGE}# ${GREEN_LIGHT}# ${GREEN}# ${GREEN_LIGHT}# ${CYAN_LIGHT}# ${CYAN}# ${BLUE_LIGHT}# ${BLUE}# ${BLUE_LIGHT}# ${CYAN}# ${CYAN_LIGHT}# ${PURPLE_LIGHT}# ${PURPLE}# ${PURPLE_LIGHT}# ${WHITE}# ${GRAY_LIGHT}# ${GRAY_DARK}# ${BLACK}# ${GRAY_LIGHT}# ${WHITE}# ${YELLOW} #${NC}"
###########################

logo()
{
    echo -e "${GREEN}###############################${GRAY_DARK}#${NC}"
    echo -e "${GREEN}# ${YELLOW}LL${GRAY_DARK}L           ${BLUE}GGGGGGG${GRAY_DARK}G     ${GREEN} #${GRAY_DARK}##${NC}"
    echo -e "${GREEN}# ${YELLOW}LL${GRAY_DARK}L           ${BLUE}GG${GRAY_DARK}G          ${GREEN} #${GRAY_DARK}###${NC}"
    echo -e "${GREEN}# ${YELLOW}LL${GRAY_DARK}L           ${BLUE}GG${GRAY_DARK}G ${BLUE}GGGG${GRAY_DARK}G     ${GREEN}#${GRAY_DARK}###${NC}"
    echo -e "${GREEN}# ${YELLOW}LL${GRAY_DARK}L           ${BLUE}GG${GRAY_DARK}G   ${BLUE}GG${GRAY_DARK}G     ${GREEN}#${GRAY_DARK}###${NC}"
    echo -e "${GREEN}# ${YELLOW}LLLLLLL${GRAY_DARK}L ${WHITE} X${GRAY_DARK}X  ${BLUE}GGGGGGGG${GRAY_DARK}G  ${WHITE}X${GRAY_DARK}X ${GREEN}#${GRAY_DARK}###${NC}"
    echo -e "${GREEN}###############################${GRAY_DARK}###${NC}"
    echo -e "${GREEN}#       ${WHITE}LUCIANOGG.INFO        ${GREEN}#${GRAY_DARK}###${NC}"
    echo -e "${GREEN}###############################${GRAY_DARK}###${NC}"
    echo -e "${GRAY_DARK}##################################${NC}"
    echo -e "${GRAY_DARK} #################################${NC}"
}


check_zenity()
{
	if ! command -v zenity &> /dev/null; then
        echo -e "\n${RED}[!] Zenity is required for this script but is not installed.${NC}"
        read -r -p "Do you want to install Zenity now? [Y/n] " response
        
        case "${response,,}" in
            y|yes|"")
                echo "${GREEN}Proceeding with installation...${NC}"
                sudo apt-get update && sudo apt-get install -y zenity
                
                if [ $? -ne 0 ]; then
                    echo "${YELLOW}Error: Failed to install Zenity. The script cannot continue.${NC}"
                    exit 1
                fi
                ;;
            *)
                # Matches anything else (No)
                echo "${YELLOW}Installation skipped. The script cannot continue.${NC}"
                exit 1
                ;;
        esac
    fi
}


updater()
{
	zenity --info --title="Creating script" --text="Creating and then executing update script."
	touch ~/update.sh
	sudo chmod +x ~/update.sh
    crontab -l | { cat; echo "0 0 * * * sudo ~/update.sh"; } | crontab -
	sudo tee -a ~/update.sh <<EOF
###########################
#!/bin/bash
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
###########################
BANNER="${YELLOW}# ${WHITE}# ${GRAY_LIGHT}# ${GRAY_DARK}# ${BLACK}# ${GRAY_LIGHT}# ${WHITE}# ${RED_LIGHT}# ${RED}# ${RED_LIGHT}# ${ORANGE}# ${GREEN_LIGHT}# ${GREEN}# ${GREEN_LIGHT}# ${CYAN_LIGHT}# ${CYAN}# ${BLUE_LIGHT}# ${BLUE}# ${BLUE_LIGHT}# ${CYAN}# ${CYAN_LIGHT}# ${PURPLE_LIGHT}# ${PURPLE}# ${PURPLE_LIGHT}# ${WHITE}# ${GRAY_LIGHT}# ${GRAY_DARK}# ${BLACK}# ${GRAY_LIGHT}# ${WHITE}# ${YELLOW} #${NC}"
###########################
echo "$BANNER"
echo "$BANNER"
echo "$BANNER"
echo "${CYAN}Preparing and updating things!${NC}"
#Configure APT sources
#sudo apt-add-repository contrib
#sudo apt-add-repository non-free
#sudo apt-add-repository non-free-firmware

#Update
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y
sudo apt-get clean
sudo apt-get autoclean -y

echo "$BANNER"
echo "$BANNER"
echo "$BANNER"
EOF

    sudo ./update.sh
}


installApps()
{
    local app_options=(
		TRUE "htop"                  "System Monitor"
		TRUE "ncdu"                  "Disk Usage Viewer"
		TRUE "ranger"                "Terminal File Manager"
		TRUE "ntfs-3g"               "NTFS Support"
		TRUE "exfat-fuse"            "exFAT Support"
		TRUE "git"                   "Git Version Control"
		TRUE "wget"                  "Command Line Downloader"
		TRUE "gcc"                   "GNU C Compiler"
		TRUE "make"                  "Build Automation Tool"
		TRUE "cmake"                 "Cross-Platform Build Tool"
		TRUE "gparted"               "Partition Editor"
		TRUE "gnome-disk-utility"    "GNOME Disk Utility"
		TRUE "p7zip-full"            "7-Zip Compression"
		TRUE "lsb-release"           "LSB Release Info"
		TRUE "python3"               "Python 3"
		TRUE "python3-pip"           "Pip for Python 3"
		TRUE "apt-transport-https"   "APT HTTPS Transport"
		TRUE "curl"                  "Command Line HTTP Client"
		TRUE "ca-certificates"       "CA Certificates"
		TRUE "unzip"                 "Unzip Utility"
		TRUE "unrar-free"            "RAR Utility"
		TRUE "ethtool"               "Network Tool Kit"
		TRUE "dnsutils"              "DNS Utilities"
		TRUE "net-tools"             "Network Tools"
		TRUE "vlc"                   "VLC Media Player"
		FALSE "fail2ban"             "Security: Ban Brute Force"
		FALSE "endlessh"             "Honeypot for SSH"
		FALSE "screen"               "Terminal Multiplexer"
		TRUE "bat"                   "Cat Clone with Syntax Highlighting"
		FALSE "zoxide"               "Smarter cd"
		TRUE "trash-cli"             "Trash Manager"
		FALSE "fzf"                  "Fuzzy Finder"
		TRUE "bash-completion"       "Bash Autocompletion"
		TRUE "cifs-utils"            "Windows Share Support"
		FALSE "arduino"              "Arduino IDE"
		FALSE "bluefish"             "Web Editor"
		FALSE "codeblocks"           "C++ IDE"
		FALSE "libreoffice"          "Office Suite"
		FALSE "gimp"                 "Image Editor"
		FALSE "dia"                  "Diagram Editor"
		FALSE "inkscape"             "Vector Graphics Editor"
		FALSE "fritzing"             "Electronics Tool"
		FALSE "filezilla"            "FTP Client"
		FALSE "qbittorrent"          "Torrent Client"
		FALSE "soundkonverter"       "Audio Converter"
		FALSE "sound-juicer"         "CD Ripper"
		FALSE "audacity"             "Audio Editor"
		FALSE "audacious"            "Audio Player"
		FALSE "kdenlive"             "Video Editor"
		FALSE "k3b"                  "Disc Burning"
		FALSE "handbrake"            "Video Converter"
		FALSE "obs-studio"           "Streaming Software"
		FALSE "wine"                 "Wine Compatibility Layer"
		FALSE "wine64"               "Wine 64-bit"
		FALSE "wine64-tools"         "Wine Tools"
		TRUE "grub-customizer"       "GRUB GUI Tool"
		FALSE "freefilesync"         "Folder Sync Tool"
		FALSE "torbrowser-launcher"  "Tor Browser Installer"
		FALSE "lm-sensors"           "Sensor Monitor"
		FALSE "nvme-cli"             "NVMe Tools"
		FALSE "cmatrix"              "Matrix Screensaver"
		FALSE "hollywood"            "Hollywood Terminal FX"
		FALSE "mupen64plus-qt"       "N64 Emulator"
		FALSE "pcsxr"                "PS1 Emulator"
    )

	SCREEN_HEIGHT=$(xdpyinfo | awk '/dimensions:/ {print $2; exit}' | cut -d 'x' -f2)
	: ${SCREEN_HEIGHT:=1080}
	ZENITY_HEIGHT=$((SCREEN_HEIGHT - 100))
    # Show Zenity checklist
    local selected=$(zenity --list \
        --title="Select apps to install" \
        --checklist \
        --width=400 \
        --height=$ZENITY_HEIGHT \
        --column="Install" --column="App" --column="Description" \
        "${app_options[@]}")

    # Cancel or empty
    if [[ -z "$selected" ]]; then
        zenity --info --text="No apps selected. Exiting."
        return
    fi

    # Convert pipe-separated string to space-separated list
    local apps_to_install=$(echo "$selected" | tr '|' ' ')

    # Run apt install
    sudo apt install -y $apps_to_install
}


removeApps()
{	
	echo -e "${CYAN}Generating list of installed applications... This may take a moment.${NC}"

	PACKAGE_LIST=$(apt list --installed | cut -d/ -f1 | grep -v "Listing")
	
	# Zenity Command: Create a checklist dialog
	ZENITY_TITLE="Select Packages to Uninstall"
	ZENITY_TEXT="Check the applications you wish to remove and click OK."
	ZENITY_WIDTH=800
	ZENITY_HEIGHT=$((SCREEN_HEIGHT - 200)) # Make it larger than the old static 400

	# Run Zenity and capture the selected packages
	SELECTED_PACKAGES=$(zenity --list \
		--title="$ZENITY_TITLE" \
		--checklist \
		--width=$ZENITY_WIDTH \
		--height=$ZENITY_HEIGHT \
		--text="$ZENITY_TEXT" \
		--separator=' ' \
		--column="Select" \
		--column="Package Name" \
		$PACKAGE_LIST 2>/dev/null)

	if [ -z "$SELECTED_PACKAGES" ]; then
		zenity --info --title="Uninstallation Cancelled" --text="No packages were selected for uninstallation or the process was cancelled."
		return 0
	fi

	IFS=' ' read -r -a PACKAGES_TO_REMOVE <<< "$SELECTED_PACKAGES"

	UNINSTALL_COMMAND="sudo apt purge -y ${PACKAGES_TO_REMOVE[*]}"

	zenity --question --title="Confirm Uninstallation" --text="The following packages will be removed:\n\n${PACKAGES_TO_REMOVE[*]}\n\nDo you wish to proceed? You will be prompted for your sudo password."

	if [ $? -eq 0 ]; then
		# Proceed with uninstallation
		zenity --info --title="Starting Uninstallation" --text="Please enter your sudo password in the terminal to continue with the removal of selected packages."
		
		echo ""
		echo "--- Executing Uninstallation Command ---"
		echo "$UNINSTALL_COMMAND"
		echo "----------------------------------------"
		
		# Execute the command
		eval $UNINSTALL_COMMAND
		
		if [ $? -eq 0 ]; then
			zenity --info --title="Uninstallation Complete" --text="Successfully removed the selected packages."
		else
			zenity --error --title="Uninstallation Failed" --text="The uninstallation process failed. Check the terminal for error messages."
		fi
	else
		zenity --info --title="Uninstallation Cancelled" --text="Uninstallation aborted by user confirmation."
	fi
}


services()
{
	echo -e "${CYAN}Generating clean list of system services...${NC}"
    SERVICE_LIST_LINES=$(systemctl list-unit-files --type=service | awk 'NR>1 {print $1}' | sed 's/\.service$//' | while read P; do echo "FALSE $P"; done)
    
    # Convert newlines to spaces for Zenity list processing
    SERVICE_LIST=$(echo "$SERVICE_LIST_LINES" | tr '\n' ' ')
    # Check if the list is empty
    if [ -z "$SERVICE_LIST" ]; then
        zenity --error --title="Error" --text="Failed to retrieve the list of services or the list is empty. Aborting."
        return 1
    fi

	ZENITY_TITLE="Select Services to Stop and Disable"
	ZENITY_TEXT="Check the services you wish to immediately STOP and permanently DISABLE from starting on boot.\n\nWARNING: Disabling critical services may break your system."
	ZENITY_COL1="Select" # MANDATORY CHECKBOX COLUMN
	ZENITY_COL2="Service Name" # The only data column
	ZENITY_WIDTH=600 
	ZENITY_HEIGHT=$((SCREEN_HEIGHT - 200))

	SELECTED_SERVICES=$(zenity --list \
        --title="$ZENITY_TITLE" \
        --checklist \
        --width=$ZENITY_WIDTH \
        --height=$ZENITY_HEIGHT \
        --text="$ZENITY_TEXT" \
        --separator=' ' \
        --column="$ZENITY_COL1" \
        --column="$ZENITY_COL2" \
        $SERVICE_LIST 2>/dev/null)

	if [ -z "$SELECTED_SERVICES" ]; then
		zenity --info --title="Operation Cancelled" --text="No services were selected or the process was cancelled."
		return 0
	fi

	# Convert the space-separated list into an array for safer iteration
	IFS=' ' read -r -a SERVICES_TO_MANAGE <<< "$SELECTED_SERVICES"

	SERVICE_COUNT=${#SERVICES_TO_MANAGE[@]}
	CONFIRMATION_TEXT="You are about to STOP and DISABLE $SERVICE_COUNT service(s):\n\n${SERVICES_TO_MANAGE[*]}\n\nDo you wish to proceed? You will be prompted for your sudo password."
	zenity --question --title="Confirm Service Management" --text="$CONFIRMATION_TEXT"

	if [ $? -eq 0 ]; then
		zenity --info --title="Starting Service Management" --text="Please enter your sudo password in the terminal to STOP and DISABLE the selected services."
		FAIL_COUNT=0
		for SERVICE in "${SERVICES_TO_MANAGE[@]}"; do
			echo ""
			echo "--- Processing Service: $SERVICE ---"
			# Ensure the service variable is clean before calling systemctl
			CLEAN_SERVICE=$(echo "$SERVICE" | sed 's/"//g') # Final safety strip
			echo "Attempting to stop $CLEAN_SERVICE..."
			sudo systemctl stop "$CLEAN_SERVICE"
			if [ $? -ne 0 ]; then
				echo "ERROR: Failed to stop $CLEAN_SERVICE."
				FAIL_COUNT=$((FAIL_COUNT + 1))
			fi			
			echo "Attempting to disable $CLEAN_SERVICE..."
			sudo systemctl disable "$CLEAN_SERVICE"
			if [ $? -ne 0 ]; then
				echo "ERROR: Failed to disable $CLEAN_SERVICE."
				FAIL_COUNT=$((FAIL_COUNT + 1))
			fi			
		done		
		echo "-------------------------------------"		
		
		if [ $FAIL_COUNT -eq 0 ]; then
			zenity --info --title="Operation Complete" --text="Successfully STOPPED and DISABLED all selected services."
		else
			zenity --warning --title="Operation Completed with Errors" --text="Service management finished, but some operations failed ($FAIL_COUNT total failures). Check the terminal for details."
		fi		
	else
		zenity --info --title="Operation Cancelled" --text="Service management aborted by user confirmation."
	fi
}


configureBashrc()
{
	# Declare options as "ID|Label|FunctionName"
    local options=(
        "1|Configure SSH|configureSSH"
        "2|Configure Network Shares|configureNetShare"
        "3|Configure bash Aliases|configureAlias"
        "0|Back"
    )

    while true; do
        # Build Zenity menu columns from options
        local menu_list=()
        for opt in "${options[@]}"; do
            IFS="|" read -r id label func <<< "$opt"
            menu_list+=("$id" "$label")
        done

        local choice=$(zenity --list \
            --title="Main Menu" \
            --column="ID" --column="Action" \
            "${menu_list[@]}" \
            --height=325 --width=400)
            
        if [[ -z "$choice" || "$choice" == "0" ]]; then
			break
        fi

        # Find and execute selected function
        for opt in "${options[@]}"; do
            IFS="|" read -r id label func <<< "$opt"
            if [[ "$id" == "$choice" && -n "$func" ]]; then
                $func
                break
            fi
        done
    done
}


configureSSH()
{
	ZENITY_TITLE="SSH Alias and Key Setup"
    ZENITY_TEXT="Please enter the details for the new SSH alias and key copy."
    
    FORM_FIELDS=(
        "--text=$ZENITY_TEXT"
        "--add-entry=Alias Name (e.g., myvps)"
        "--add-entry=Remote User (e.g., root)"
        "--add-entry=IP Address or Hostname"
        "--add-entry=Port Number (Leave empty for 22)"
    )
    INPUT_STRING=$(zenity --forms --title="$ZENITY_TITLE" \
        --width=400 --height=350 \
        "${FORM_FIELDS[@]}" 2>/dev/null)

    if [ $? -ne 0 ]; then
        zenity --info --title="Setup Cancelled" --text="SSH setup was cancelled by the user."
        return 0
    fi

    # Use IFS to split the input string by the '|' delimiter
    IFS='|' read -r ALIAS_NAME SSH_USER SSH_HOST SSH_PORT <<< "$INPUT_STRING"
    # Input validation (basic check for empty essential fields)
    if [[ -z "$ALIAS_NAME" || -z "$SSH_USER" || -z "$SSH_HOST" ]]; then
        zenity --error --title="Input Error" --text="Alias Name, User, and IP/Host cannot be empty. Aborting."
        return 1
    fi
    
    # Ensure Port defaults to 22 if the user cleared the default field
    if [[ -z "$SSH_PORT" ]]; then
        SSH_PORT="22"
    fi
 
    NEW_ALIAS="alias $ALIAS_NAME=\"ssh -p $SSH_PORT $SSH_USER@$SSH_HOST\""
    
    zenity --question --title="Confirm Alias" --text="The following alias will be added to ~/.bashrc:\n\n$NEW_ALIAS\n\nDo you want to proceed?"

    if [ $? -eq 0 ]; then
        echo "$NEW_ALIAS" | tee -a ~/.bashrc > /dev/null
        source ~/.bashrc
        zenity --info --title="Alias Added" --text="Alias '$ALIAS_NAME' added successfully to ~/.bashrc."
    else
        zenity --info --title="Alias Skipped" --text="Alias creation skipped."
    fi
    
    zenity --info --title="Starting Key Copy" --text="Now executing ssh-copy-id.\n\nPlease check the terminal to enter the password for:\n\n$SSH_USER@$SSH_HOST:$SSH_PORT"    
    echo -e "\n--- Executing ssh-copy-id: -oPort=$SSH_PORT $SSH_USER@$SSH_HOST ---\n"    
    ssh-copy-id -oPort="$SSH_PORT" "$SSH_USER@$SSH_HOST"    
    source ~/.bashrc
    
    if [ $? -eq 0 ]; then
        zenity --info --title="Key Copy Success" --text="Key copy successful! You can now use the alias '$ALIAS_NAME' to connect without a password."
    else
        zenity --warning --title="Key Copy Warning" --text="Key copy failed (check terminal output for errors). You may need to manually run ssh-copy-id."
    fi
}


configureNetShare()
{
	# Check for required packages
	REQUIRED_PKG="cifs-utils"
	if ! dpkg -s "$REQUIRED_PKG" &> /dev/null; then
        zenity --question --title="Missing Dependency" \
            --text="The package '$REQUIRED_PKG' is required.\n\nDo you want to install it now?"
        if [ $? -ne 0 ]; then
            z_error "Installation cancelled. Cannot proceed."
            return 1
        fi
    fi
   
    ZENITY_TITLE="CIFS/SMB Network Share Setup"
    ZENITY_TEXT="Please enter the details for the new network share mount (CIFS/SMB)."
    
    FORM_FIELDS=(
        "--text" "$ZENITY_TEXT"
        "--add-entry" "Share IP/Host (e.g., 10.1.3.4)"
        "--add-entry" "Remote Share Name (e.g., 8tb)"
        "--add-entry" "Local Mount Point Name (in /mnt/)"
        "--add-entry" "Username for Share Access"
    )

    # Zenity form to collect IP, Share Name, Mount Name, and Username
    INPUT_STRING=$(zenity --forms --title="$ZENITY_TITLE" --text="$ZENITY_TEXT" \
        --width=450 --height=350 \
        "${FORM_FIELDS[@]}" 2>/dev/null)

    # Check if the user cancelled the dialog
    if [ $? -ne 0 ]; then
        zenity --info --title="Setup Cancelled" --text="Network share setup was cancelled by the user."
        return 0
    fi

    # Parse essential input (Fields 1-4)
    IFS='|' read -r SHARE_IP SHARE_NAME MOUNT_POINT_NAME SMB_USER <<< "$INPUT_STRING"

    # Input validation
    if [[ -z "$SHARE_IP" || -z "$SHARE_NAME" || -z "$MOUNT_POINT_NAME" || -z "$SMB_USER" ]]; then
        zenity --error --title="Input Error" --text="All fields must be filled out. Aborting."
        return 1
    fi
    
    # Get Password separately for security
    SMB_PASS=$(zenity --password --title="Enter Password for $SMB_USER on $SHARE_IP/$SHARE_NAME" 2>/dev/null)
    
    if [ -z "$SMB_PASS" ]; then
        zenity --warning --title="Setup Cancelled" --text="Password not entered. Aborting setup."
        return 1
    fi

    # --- Define File Paths and Mount Point ---
    MOUNT_PATH="/mnt/$MOUNT_POINT_NAME"
    CREDENTIALS_FILE="/root/.smbcredentials_$MOUNT_POINT_NAME"
    REMOTE_SHARE="//${SHARE_IP}/${SHARE_NAME}"
    zenity --info --title="Sudo Required" --text="You will now be prompted for your sudo password to create the mount point ($MOUNT_PATH) and credentials file."
    echo -e "\n--- Creating mount point: $MOUNT_PATH ---"
    sudo mkdir -p "$MOUNT_PATH"
    if [ $? -ne 0 ]; then
        zenity --error --title="Permission Error" --text="Failed to create mount point. Check terminal for sudo errors."
        return 1
    fi
    
    # --- Create Credentials File ---
    echo -e "\n--- Creating and securing credentials file: $CREDENTIALS_FILE ---"
    echo "username=$SMB_USER" | sudo tee "$CREDENTIALS_FILE" > /dev/null
    echo "password=$SMB_PASS" | sudo tee -a "$CREDENTIALS_FILE" > /dev/null
    sudo chmod 400 "$CREDENTIALS_FILE"
    if [ $? -ne 0 ]; then
        zenity --error --title="Permission Error" --text="Failed to create credentials file. Check terminal for sudo errors."
        return 1
    fi

    # --- Add Entry to /etc/fstab ---
    FSTAB_LINE="#Share $MOUNT_POINT_NAME\n$REMOTE_SHARE $MOUNT_PATH cifs credentials=$CREDENTIALS_FILE,noperm,nofail,rw 0 0"

    zenity --question --title="Confirm fstab Addition" --text="The following entry will be added to /etc/fstab (requires sudo):\n\n$FSTAB_LINE\n\nDo you want to proceed?"

    if [ $? -eq 0 ]; then
        echo -e "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null
        zenity --info --title="fstab Updated" --text="/etc/fstab has been updated successfully. Attempting to mount now."
        
        # --- Attempt Immediate Mount ---
        echo -e "\n--- Attempting to mount the new share: mount $MOUNT_PATH ---"
        sudo mount "$MOUNT_PATH"
        
        if [ $? -eq 0 ]; then
            zenity --info --title="Mount Success" --text="The share '$SHARE_NAME' was successfully mounted at '$MOUNT_PATH' and configured to auto-mount on boot."
        else
            zenity --warning --title="Mount Failed" --text="The fstab entry was added, but the initial 'mount' command failed. Check the terminal for errors. You may need to install 'cifs-utils' (sudo apt install cifs-utils)."
        fi
        
    else
        zenity --info --title="Setup Complete" --text="The mount point and credentials were created, but the fstab entry was skipped. The setup is incomplete."
    fi
}


configureAlias()
{
	# Zenity Menu with the 5 options
	CHOICES=$(zenity --list --checklist \
		--title="Configure .bashrc" \
		--text="Check the options to append to your ~/.bashrc:" \
		--width=550 --height=450 \
		--column="Install" --column="ID" --column="Description" \
		--hide-column=2 \
		TRUE "1" "Aliases Function (ls, cp, mv, trash, settings)" \
		TRUE "2" "cpp Function (Visual copy with progress bar)" \
		TRUE "3" "up Function (Go up multiple directories)" \
		TRUE "4" "cd Function (Auto ls after changing directory)" \
		TRUE "5" "Fancy Prompt (Download and apply fancy-prompt)")

	if [ -z "$CHOICES" ]; then
		echo "Cancelled by user."
		exit 0
	fi

	cp ~/.bashrc ~/.bashrc.backup.$(date +%s)
	echo ">> Backup created at ~/.bashrc.backup.$(date +%s)"

	echo "" >> ~/.bashrc
	echo "### NEW CONFIGURATIONS ADDED ###" >> ~/.bashrc

	# --- OPTION 1: Aliases and History ---
	if [[ "$CHOICES" == *"1"* ]]; then
		echo "Adding Option 1 (Aliases & Settings)..."
		cat <<'EOF' >> ~/.bashrc

	#Aliases and Settings
	alias atualizar="~/update.sh"
	alias lss="ls -claksh"
	alias ..="cd .."
	alias cp="cp -i"
	alias mv="mv -i"
	alias rm="trash -v"
	alias rmf="/sbin/rm --recursive --force --verbose"
	alias cat="batcat"

	export HISTFILESIZE=10000
	export HISTSIZE=500
	export HISTTIMEFORMAT="%F %T "
	export HISTCONTROL=erasedups:ignoredups
	shopt -s checkwinsize
	shopt -s histappend
EOF
	fi

	# --- OPTION 2: cpp Function ---
	if [[ "$CHOICES" == *"2"* ]]; then
		echo "Adding Option 2 (cpp function)..."
		cat <<'EOF' >> ~/.bashrc

	#Visual Copy (cpp)
	cpp() {
		set -e
		strace -q -ewrite cp -- "${1}" "${2}" 2>&1 |
		awk '{
			count += $NF
			if (count % 10 == 0) {
				percent = count / total_size * 100
				printf "%3d%% [", percent
				for (i=0;i<=percent;i++)
					printf "="
				printf ">"
				for (i=percent;i<100;i++)
					printf " "
				printf "]\r"
			}
		}
		END { print "" }' total_size="$(stat -c '%s' "${1}")" count=0
	}
EOF
	fi

	# --- OPTION 3: up Function ---
	if [[ "$CHOICES" == *"3"* ]]; then
		echo "Adding Option 3 (up function)..."
		cat <<'EOF' >> ~/.bashrc

	#Up function
	up() {
		local d=""
		limit=$1
		for ((i = 1; i <= limit; i++)); do
			d=$d/..
		done
		d=$(echo $d | sed 's/^\///')
		if [ -z "$d" ]; then
			d=..
		fi
		cd $d
	}
EOF
	fi

	# --- OPTION 4: cd Function ---
	if [[ "$CHOICES" == *"4"* ]]; then
		echo "Adding Option 4 (Auto ls)..."
		cat <<'EOF' >> ~/.bashrc

	#Auto ls after cd
	cd ()
	{
		if [ -n "$1" ]; then
			builtin cd "$@" && ls
		else
			builtin cd ~ && ls
		fi
	}
EOF
	fi

	# --- OPTION 5: Fancy Prompt ---
	if [[ "$CHOICES" == *"5"* ]]; then
		echo "Configuring Option 5 (Fancy Prompt)..."
		wget -O ~/.fancy-prompt.sh https://raw.githubusercontent.com/pjmp/fancy-linux-prompt/master/fancy-prompt.sh
		cat <<'EOF' >> ~/.bashrc

	#Fancy Prompt
	if [ -f ~/.fancy-prompt.sh ]; then
		source ~/.fancy-prompt.sh
	fi
EOF
	fi
	echo "### END OF CONFIGURATIONS ###" >> ~/.bashrc
	source ~/.bashrc
	zenity --info --text="Success! Settings appended to ~/.bashrc."
}


pcInfo ()
{
    echo -e "$BANNER"
    echo -e "$BANNER"
    echo -e "$BANNER"
    ##################SysInfo
    echo -e "${CYAN}Getting System Info${NC}"
    BANNER2="######################################################"
    ###########################

    #Sever Identity
    echo -e "$BANNER"
    echo -e "${BLUE}System name: ${NC}"
    read name

    ###########################

    #Preparation

    rm ~/SYSinfo-$name.txt
    touch ~/SYSinfo-$name.txt
    echo -e "$BANNER"

    ###########################

    #Identification
    echo "$BANNER2"  >> SYSinfo-$name.txt
    echo "Server $name"  >> SYSinfo-$name.txt
    echo "Server Serian Number: " >> SYSinfo-$name.txt
    sudo dmidecode -t system | grep Serial >> SYSinfo-$name.txt
    echo -e "$BANNER"
    echo -e "$BANNER"
    echo -e "${BLUE}Server $name${NC}"
    echo -e "${BLUE}Server Serial Number: ${NC}"
    sudo dmidecode -t system | grep Serial


    ###########################

    echo "$BANNER2"  >> SYSinfo-$name.txt
    echo -e "$BANNER"
    echo -e "${GREEN_LIGHT}PROCESSOR${NC}"

    #Sockets Number
    echo "Number os Sockets" >> SYSinfo-$name.txt
    lscpu | grep "«Socket(s)»" >> SYSinfo-$name.txt
    echo "Number os Sockets"
    lscpu | grep "«Socket(s)»"

    echo "" >> SYSinfo-$name.txt
    echo ""

    #Processor Model
    echo "CPU Model/Name: " >> SYSinfo-$name.txt
    sudo dmidecode -t processor | grep "Version" >> SYSinfo-$name.txt
    echo "CPU Model/Name: "
    sudo dmidecode -t processor | grep "Version"

    #Other Methods
    #cat /proc/cpuinfo | grep "model name"

    echo "" >> SYSinfo-$name.txt
    echo ""

    #Processor Speed
    echo "CPU Speed " >> SYSinfo-$name.txt
    echo -e "Current Speed: " >> SYSinfo-$name.txt
    sudo dmidecode -t processor | grep "Current Speed" >> SYSinfo-$name.txt
    echo "MAX Speed: " >> SYSinfo-$name.txt
    sudo dmidecode -t processor | grep "Max Speed" >> SYSinfo-$name.txt

    echo -e "${PURPLE}CPU Speed ${NC}"
    echo -e "${YELLOW}Current Speed: ${NC}"
    sudo dmidecode -t processor | grep "Current Speed"
    echo -e "${YELLOW}MAX Speed: ${NC}"
    sudo dmidecode -t processor | grep "Max Speed"

    echo "" >> SYSinfo-$name.txt
    echo ""

    #Processor Cores
    echo "CPU Cores " >> SYSinfo-$name.txt
    echo "Cores Count: " >> SYSinfo-$name.txt
    sudo dmidecode -t processor | grep "Core Count" >> SYSinfo-$name.txt
    echo "Thread Count: " >> SYSinfo-$name.txt
    sudo dmidecode -t processor | grep "Thread Count" >> SYSinfo-$name.txt

    echo -e "${PURPLE}CPU Cores ${NC}"
    echo -e "${YELLOW}Cores Count: ${NC}"
    sudo dmidecode -t processor | grep "Core Count"
    echo -e "${YELLOW}Thread Count: ${NC}"
    sudo dmidecode -t processor | grep "Thread Count"

    #Other methods
    #cat /proc/cpuinfo | grep "cpu cores"
    #nproc
    #lscpu | grep "CPU(s):"

    ###########################

    echo "$BANNER2"  >> SYSinfo-$name.txt
    echo "RAM" >> SYSinfo-$name.txt
    cat /proc/meminfo | grep MemTotal >> SYSinfo-$name.txt

    echo -e "$BANNER"
    echo -e "${GREEN_LIGHT}RAM${NC}"
    cat /proc/meminfo | grep MemTotal

    #Prototipo para transformar Mb to Gb
    #touch tmp.txt
    #free -h --giga -t | grep Total > tmp.txt
    #sed 's/G/G\n/' tmp.txt >> SYSinfo-$name.txt
    #rm tmp.txt

    #Other methods
    #free -h --giga -t | grep Total

    ###########################

    echo "$BANNER2"  >> SYSinfo-$name.txt
    echo "NETWORK" >> SYSinfo-$name.txt
    echo "Wifi: " >> SYSinfo-$name.txt
    lspci | grep Network >> SYSinfo-$name.txt
    echo "Ethernet: " >> SYSinfo-$name.txt
    lspci | grep Ethernet >> SYSinfo-$name.txt


    echo -e "$BANNER"
    echo -e "${GREEN_LIGHT}NETWORK${NC}"
    echo -e "${PURPLE}Wifi: ${NC}"
    lspci | grep Network
    echo -e "${PURPLE}Ethernet: ${NC}"
    lspci | grep Ethernet

    ###########################

    echo "$BANNER2"  >> SYSinfo-$name.txt
    echo "DISKS" >> SYSinfo-$name.txt
    lsblk >> SYSinfo-$name.txt

    echo -e "$BANNER"
    echo -e "${GREEN_LIGHT}DISKS${NC}"
    lsblk

    ###########################

    echo -e "$BANNER"  >> SYSinfo-$name.txt
    echo -e "$BANNER"
    echo -e "${RED}INFO EXPORTED TO SYSinfo-$name.txt${NC}"
    echo -e "$BANNER"

    ###########################

    echo -e "$BANNER"
    echo -e "$BANNER"
    echo -e "$BANNER"
}


cleaner ()
{
    echo -e "${CYAN}Cleaning myself and going home${NC}"
    echo -e "${CYAN}There is no place like /home${NC}"
    SCRIPT_DIR="$(pwd)"
    rm $SCRIPT_DIR/MasterInstallerV2.sh

    echo -e "$BANNER"
    echo -e "$BANNER"
    echo -e "$BANNER"
}


runall()
{
	updater
	installApps
	removeApps
	services
	configureSSH
	configureNetShare
	configureAlias
	cleaner
	pcInfo
}


menu()
{
	check_zenity
	# Declare options as "ID|Label|FunctionName"
    local options=(
        "1|Create Updater and update|updater"
        "2|Apps INstaller|installApps"
        "3|Apps UNinstaller|removeApps"
        "4|Stop System Services|services"
        "5|Configure Terminal|configureBashrc"
        "6|Get PC Info|pcInfo"
        "7|DO IT ALL|runall"
        "0|Exit|"
    )

    while true; do
        # Build Zenity menu columns from options
        local menu_list=()
        for opt in "${options[@]}"; do
            IFS="|" read -r id label func <<< "$opt"
            menu_list+=("$id" "$label")
        done

        local choice=$(zenity --list \
            --title="Main Menu" \
            --column="ID" --column="Action" \
            "${menu_list[@]}" \
            --height=420 --width=400)

        # If cancel or empty, exit
        if [[ -z "$choice" || "$choice" == "0" ]]; then
            #cleaner
            break
        fi

        # Find and execute selected function
        for opt in "${options[@]}"; do
            IFS="|" read -r id label func <<< "$opt"
            if [[ "$id" == "$choice" && -n "$func" ]]; then
                $func
                break
            fi
        done
    done
}

logo
menu

#falta melhorar pcInfo

