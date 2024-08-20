#!/bin/bash

# Initial message for the user
echo "If you are unsure which option to pick, please just pick Y."
read -p "Do you understand? (y/n): " user_confirmation

# Check if the user confirmed understanding
if [[ "$user_confirmation" != "y" && "$user_confirmation" != "Y" ]]; then
    echo "User did not confirm understanding. Continuing anyway..."
fi

# Function to unhold Nvidia packages if they were held
unhold_nvidia_packages() {
    echo "Removing hold on Nvidia packages..."
    sudo apt-mark unhold nvidia* libnvidia*
}

# Function to identify the installed Nvidia GPU model
get_nvidia_gpu_model() {
    lspci | grep -i nvidia
}

# Function to uninstall existing Nvidia drivers
uninstall_nvidia_drivers() {
    echo "Uninstalling existing Nvidia drivers..."
    sudo apt-get purge -y 'nvidia-*'
    sudo apt-get autoremove -y
    sudo apt-get autoclean -y
}

# Function to add the Nvidia PPA and update package lists
add_nvidia_ppa() {
    echo "Adding Nvidia PPA..."
    sudo add-apt-repository ppa:graphics-drivers/ppa -y
    sudo apt-get update
}

# Function to install ubuntu-drivers-common if not installed
install_ubuntu_drivers_common() {
    if ! dpkg -l | grep -q ubuntu-drivers-common; then
        echo "Installing ubuntu-drivers-common package..."
        sudo apt-get install -y ubuntu-drivers-common
    fi
}

# Function to install the latest Nvidia drivers
install_latest_nvidia_drivers() {
    echo "Installing the latest Nvidia drivers..."
    sudo ubuntu-drivers autoinstall
}

# Function to install nvidia-smi if not installed
install_nvidia_smi() {
    if ! command -v nvidia-smi &> /dev/null; then
        echo "Installing nvidia-smi..."
        sudo apt-get install -y nvidia-utils-$(nvidia-driver --query-gpu=driver_version | grep -Po '\d+')
    fi
}

# Function to check dmesg for GPU/Nvidia errors
check_dmesg_for_errors() {
    echo "Checking dmesg for GPU/Nvidia errors..."
    sudo dmesg | grep -E 'GPU|nvidia|RmInitAdapter|failed' | tee /tmp/gpu_errors.log
}

# Main script
echo "Removing hold on Nvidia packages..."
unhold_nvidia_packages

echo "Checking for Nvidia GPU..."
gpu_info=$(get_nvidia_gpu_model)

if [[ -n "$gpu_info" ]]; then
    echo "Nvidia GPU detected:"
    echo "$gpu_info"
    
    check_dmesg_for_errors
    if ([[ -s /tmp/gpu_errors.log ]]; then
        echo "Errors found in dmesg related to GPU/Nvidia:"
        cat /tmp/gpu_errors.log
        read -p "ERROR FOUND WITH GPU. INSTALLING DRIVERS MAY NOT WORK. DO YOU WISH TO TRY? (y/n): " user_choice
    else
        read -p "No GPU/Nvidia errors found in dmesg. Do you wish to install the Nvidia drivers? (y/n): " user_choice
    fi

    if [[ "$user_choice" == "y" || "$user_choice" == "Y" ]]; then
        uninstall_nvidia_drivers
        add_nvidia_ppa
        install_ubuntu_drivers_common
        install_latest_nvidia_drivers
        install_nvidia_smi
        echo "Nvidia drivers and nvidia-smi installed successfully. Please reboot your system."
    else
        echo "Installation aborted by user."
    fi
else
    echo "No Nvidia GPU detected. Exiting script."
fi

# Thank you message
echo "Joe at TensorDock thanks you for using our service!"

# Reboot the system
echo "Rebooting the system now..."
sudo reboot
