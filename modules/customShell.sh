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
#     Script p/ LFS Project        #
##########################################
#MODULE:SHELL CUSTOMIZER (customShell.sh)#
##########################################

configure_shell() {
    CHOICES=$(zenity --list --checklist \
        --title="Configure Shell" \
        --text="Select the options to apply globally to your shell environment:" \
        --width=600 --height=550 \
        --column="Install" --column="ID" --column="Description" \
        --hide-column=2 \
        --separator="|" \
        TRUE "1" "Safe File Operations (cp, mv, rm, rmf)" \
        TRUE "2" "Enhanced Navigation & Listing (ls, lss, ..)" \
        TRUE "3" "System Info Aliases (dff, lsblk)" \
        TRUE "4" "History Optimization (HISTSIZE, ignoredups)" \
        TRUE "5" "cpp Function (Visual copy with progress bar)" \
        TRUE "6" "up Function (Go up multiple directories)" \
        TRUE "7" "cd Function (Auto ls after changing directory)" \
        FALSE "8" "BASH ONLY: Install and apply Fancy Prompt" 2>/dev/null)

    if [ -z "$CHOICES" ]; then
        print_info "Shell configuration cancelled by user."
        return 0
    fi

    #REAL_USER=${SUDO_USER:-$(whoami)}
    #REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    #REAL_SHELL=$(getent passwd "$REAL_USER" | cut -d: -f7)
    #print_info "Applying settings for user: $REAL_USER at $REAL_HOME"
    CONFIG_FILE="$REAL_HOME/.shell_customizations.sh"
    
    echo "# --- LINUX MASTER ASSISTANT CUSTOMIZATIONS ---" > "$CONFIG_FILE"

    PADDED_CHOICES="|${CHOICES}|"

    # --- OPTION 1: Safe File Operations ---
    if echo "$PADDED_CHOICES" | grep -q "|1|"; then
        zenity --warning --text="rm ALIAS uses TRASH-CLI.\n\ncat ALIAS uses BAT.\n\n In case you don't have this packages installed,\nyou should install them or remove those ALIASES."
        cat <<'EOF' >> "$CONFIG_FILE"
# Safe File Operations
alias cp="cp -i"
alias mv="mv -i"
alias rm="trash -v"
alias rmf="/sbin/rm --recursive --force --verbose"
alias cat="batcat"
alias autoUpdate="~/update.sh"
EOF
    fi

    # --- OPTION 2: Enhanced Navigation & Listing ---
    if echo "$PADDED_CHOICES" | grep -q "|2|"; then
        cat <<'EOF' >> "$CONFIG_FILE"
# Navigation & Listing
alias ls='ls --color=auto'
alias lss="ls -claksh"
alias ..="cd .."
EOF
    fi

    # --- OPTION 3: System Info Aliases ---
    if echo "$PADDED_CHOICES" | grep -q "|3|"; then
        cat <<'EOF' >> "$CONFIG_FILE"
# System Information
alias dff='df -hT'
alias ddf="duf -hide special"
alias lsblk="lsblk -o NAME,SIZE,TYPE,FSTYPE,UUID,MOUNTPOINT"
EOF
    fi

    # --- OPTION 4: History Optimization ---
    if echo "$PADDED_CHOICES" | grep -q "|4|"; then
        cat <<'EOF' >> "$CONFIG_FILE"
# History Optimization
export HISTFILESIZE=10000
export HISTSIZE=500
export HISTTIMEFORMAT="%F %T "
export HISTCONTROL=erasedups:ignoredups
EOF
    fi

    # --- OPTION 5: cpp Function (POSIX Compliant) ---
    if echo "$PADDED_CHOICES" | grep -q "|5|"; then
        cat <<'EOF' >> "$CONFIG_FILE"
# Visual Copy (cpp)
cpp() {
    set -e
    strace -q -ewrite cp -- "${1}" "${2}" 2>&1 | awk '{
        count += $NF; 
        if(count%10==0) printf "\rCopied: %d bytes", count
    }' total_size="$(stat -c '%s' "${1}")" count=0
    echo ""
}
EOF
    fi

    # --- OPTION 6: up Function (POSIX Compliant loop) ---
    if echo "$PADDED_CHOICES" | grep -q "|6|"; then
        cat <<'EOF' >> "$CONFIG_FILE"
# Up function
up() {
    d=""
    limit=${1:-1}
    i=1
    while [ "$i" -le "$limit" ]; do
        d="$d/.."
        i=$((i + 1))
    done
    command cd "$d" || return
}
EOF
    fi

    # --- OPTION 7: cd Function (POSIX Compliant override) ---
    if echo "$PADDED_CHOICES" | grep -q "|7|"; then
        cat <<'EOF' >> "$CONFIG_FILE"
# Auto ls after cd
cd() {
    if [ "$#" -gt 0 ]; then
        command cd "$@" && ls
    else
        command cd "$HOME" && ls
    fi
}
EOF
    fi

    # Setting configs to Shell
    chmod +x "$CONFIG_FILE"
    chown "$REAL_USER:$REAL_USER" "$CONFIG_FILE"
    
    CURRENT_SHELL=$(basename "$REAL_SHELL")
    TARGET_PROFILE=""

    case "$CURRENT_SHELL" in
        bash) TARGET_PROFILE="$REAL_HOME/.bashrc" ;;
        zsh)  TARGET_PROFILE="$REAL_HOME/.zshrc" ;;
        ksh)  TARGET_PROFILE="$REAL_HOME/.kshrc" ;;
        *)    TARGET_PROFILE="$REAL_HOME/.profile" ;;
    esac

    print_info "Detected default shell: $CURRENT_SHELL. Targeting $TARGET_PROFILE"

    if [ ! -f "$TARGET_PROFILE" ]; then
        touch "$TARGET_PROFILE"
        chown "$REAL_USER:$REAL_USER" "$TARGET_PROFILE"
    fi

    INJECTION_STRING="[ -f \"$CONFIG_FILE\" ] && . \"$CONFIG_FILE\""

    if ! grep -q ".shell_customizations.sh" "$TARGET_PROFILE"; then
        echo "" >> "$TARGET_PROFILE"
        echo "$INJECTION_STRING" >> "$TARGET_PROFILE"
    fi
    
    # --- OPTION 8: Fancy Prompt ---
    if echo "$PADDED_CHOICES" | grep -q "|8|"; then
    INSTALL_FANCY="yes"
    
    if [ "$CURRENT_SHELL" != "bash" ]; then
        zenity --question --title="Compatibility Warning" \
            --text="Fancy Prompt was specifically designed for Bash.\nYour current shell is detected as: $CURRENT_SHELL.\n\nDo you really want to attempt installing it into $TARGET_PROFILE anyway?" 2>/dev/null
        
        if [ $? -ne 0 ]; then
            INSTALL_FANCY="no"
            print_info "Fancy Prompt installation skipped by user."
        fi
    fi

    if [ "$INSTALL_FANCY" = "yes" ]; then
        print_info "Downloading and configuring Fancy Prompt..."
        FANCY_FILE="$REAL_HOME/.fancy-prompt.sh"
        BASHRC_FILE="$REAL_HOME/.bashrc"

        if command -v wget >/dev/null 2>&1; then
            if wget -O "$FANCY_FILE" https://raw.githubusercontent.com/pombadev/fancy-linux-prompt/master/fancy-prompt.sh 2>/dev/null; then
                chown "$REAL_USER:$REAL_USER" "$FANCY_FILE"
                chmod +x "$FANCY_FILE"
                
                #if ! grep -q ".fancy-prompt.sh" "$BASHRC_FILE" 2>/dev/null; then
                    echo "" >> "$BASHRC_FILE"
                    echo "# Fancy Prompt" >> "$BASHRC_FILE"
                    echo "[ -f \"$FANCY_FILE\" ] && . \"$FANCY_FILE\"" >> "$BASHRC_FILE"
                #fi
                print_success "Fancy Prompt added to .bashrc."
            else
                zenity --error --text="Failed to download Fancy Prompt. Verify the URL." 2>/dev/null
            fi
        else
            zenity --warning --text="'wget' is not installed. Failed to download Fancy Prompt." 2>/dev/null
        fi
    fi
fi
}
