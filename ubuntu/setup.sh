#!/bin/bash

# Check if the system is running Ubuntu
echo "[LOG] $(date +"%Y-%m-%d %H:%M:%S") - Checking system OS"

if ! grep -qi 'ubuntu' /etc/os-release; then
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - This system is not running Ubuntu."
    exit 1
else
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - System is running Ubuntu."
fi

# Update and upgrade Ubuntu
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Updating and Upgrading Ubuntu."
sudo apt-get update && sudo apt-get upgrade -y

# User configuration
USER_TO_CHECK="admin"
USER_HOME="/home/$USER_TO_CHECK"

if id $USER_TO_CHECK >/dev/null 2>&1; then
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - User $USER_TO_CHECK exists."

    if [[ ! -d $USER_HOME ]]; then
        echo "[WARNING] $(date +"%Y-%m-%d %H:%M:%S") - Home directory for user $USER_TO_CHECK doesn't exist."
        
        # Creating Home directory for specified user
        mkdir -p "$USER_HOME"
        chown -R "$USER_TO_CHECK":"$USER_TO_CHECK" "$USER_HOME"
        chmod 700 "$USER_HOME"

        echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Home directory created and configured."
    else
        echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Home directory exists."
    fi

else
    echo "[WARNING] $(date +"%Y-%m-%d %H:%M:%S") - User $USER_TO_CHECK doesn't exist."

    # Check if admin group exists
    if getent group $USER_TO_CHECK >/dev/null; then
        echo "[INFO] Using existing '$USER_TO_CHECK' group"
        GROUP_OPTION="-g $USER_TO_CHECK"
    else
        GROUP_OPTION=""
    fi

    # Creating user with proper group handling
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Creating $USER_TO_CHECK user."
    useradd -m -s /bin/bash $GROUP_OPTION $USER_TO_CHECK
    
    # Verify user creation before proceeding
    if ! id $USER_TO_CHECK >/dev/null 2>&1; then
        echo "[ERROR] Failed to create user $USER_TO_CHECK"
        exit 1
    fi

    chown -R $USER_TO_CHECK:$USER_TO_CHECK $USER_HOME
    chmod 700 $USER_HOME
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - $USER_TO_CHECK user created."
fi

# SSH Configuration
if [[ -f /root/.ssh/authorized_keys ]]; then

    # Checking if .ssh directory exist for specified user
    if [[ -d "$USER_HOME/.ssh" ]]; then

        # Moving authorized_keys
        mv /root/.ssh/authorized_keys "$USER_HOME/.ssh/authorized_keys"
        chown $USER_TO_CHECK:$USER_TO_CHECK "$USER_HOME/.ssh/authorized_keys"
        chmod 600 "$USER_HOME/.ssh/authorized_keys"
        echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - SSH keys moved."

    else
        # If .ssh directory doesn't exist create new
        mkdir "$USER_HOME/.ssh"

        # Moving authorized_keys
        mv /root/.ssh/authorized_keys "$USER_HOME/.ssh/authorized_keys"
        chown -R $USER_TO_CHECK:$USER_TO_CHECK "$USER_HOME/.ssh"
        chmod 600 "$USER_HOME/.ssh/authorized_keys"
        echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - SSH directory and keys configured."
    fi
else
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - No authorized_keys found in /root/.ssh"
fi

# Package installation
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Installing packages."
echo -n "[INPUT] Enter $USER_TO_CHECK password: "
read -rs USER_PASSWORD
echo ""

# Base packages
DEFAULT_PACKAGES="curl wget tree htop net-tools git build-essential"
PACKAGES_TO_INSTALL="$DEFAULT_PACKAGES"

# Append additional packages if --install is used
if [[ "$1" == "--install" ]]; then
    shift
    PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL $*"
fi

# Single sudo session for all installations
su - "$USER_TO_CHECK" -c "echo \"$USER_PASSWORD\" | sudo -S apt-get install -y $PACKAGES_TO_INSTALL"
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Installation complete."