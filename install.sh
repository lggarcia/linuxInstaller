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
#           INSTALLER              #
####################################

REPO_URL="https://github.com/lggarcia/linuxInstaller.git"
DEST_DIR="/opt/linuxMaster"
BIN_LINK="/usr/local/bin/linuxmaster"

echo "========================================"
echo " Installing Linux Master Assistant..."
echo "========================================"

if [ "$(id -u)" -ne 0 ]; then
   echo "Error: This installer must be run as root (sudo)."
   exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    echo "Error: 'git' is required to install. Please install it first."
    exit 1
fi

if [ -d "$DEST_DIR" ]; then
    echo "-> Updating existing installation in $DEST_DIR..."
    cd "$DEST_DIR" || exit 1
    git pull
else
    echo "-> Cloning repository to $DEST_DIR..."
    git clone "$REPO_URL" "$DEST_DIR"
fi

echo "-> Setting executable permissions..."
find "$DEST_DIR" -type f -name "*.sh" -exec chmod +x {} \;

echo "-> Creating global shortcut..."
ln -sf "$DEST_DIR/main.sh" "$BIN_LINK"

echo "========================================"
echo " Installation Complete!"
echo " You can now launch the tool from anywhere by typing:"
echo " sudo linuxmaster"
echo "========================================"
