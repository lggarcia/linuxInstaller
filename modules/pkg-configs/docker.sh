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
# PKG-CONFIGS: DOCKER (docker.sh)  #
####################################

install_docker() 
{
    TARGET_USER="$1"
    
    if command -v docker >/dev/null 2>&1; then
        print_warning "Docker is already installed. Skipping base installation."
    else
        print_info "Downloading official Docker installation script..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        print_info "Executing Docker installation..."
        sh get-docker.sh
        rm -f get-docker.sh
        
        print_success "Docker Engine installed."
    fi

    if [ "$TARGET_USER" != "root" ]; then
        print_info "Adding $TARGET_USER to the 'docker' group..."
        if ! grep -q "^docker:" /etc/group; then
            groupadd docker
        fi
        usermod -aG docker "$TARGET_USER"
        print_success "User $TARGET_USER authorized. (Note: A logout/login is required to take effect)."
    fi

    print_info "Applying Log Rotation..."
    mkdir -p /etc/docker
    
    cat <<EOF > /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "5"
  }
}
EOF

    print_info "Enabling and restarting Docker service..."
    systemctl enable docker 2>/dev/null
    systemctl restart docker 2>/dev/null
    
    print_success "Docker is perfectly configured and ready for production."
}
