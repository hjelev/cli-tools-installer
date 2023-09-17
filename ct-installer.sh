#!/bin/bash

# Define text color variables
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
NC=$(tput sgr0)  # Reset text color
CHECK_MARK="✔"
CROSS_MARK="✖"

# Define the path to the software list file
software_list_file="software_list.txt"

# Check if the input file exists
if [ ! -f "$software_list_file" ]; then
    echo "Error: Software list file '$software_list_file' not found."
    exit 1
fi

# Function to check if a package is installed via APT
check_apt_package() {
    if dpkg -l | grep -q "ii  $1 "; then
        return 0
    fi
    return 1
}

# Function to check if a package is installed via npm
check_npm_package() {
    if npm ls -g "$1" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Function to check if a Snap package is installed
check_snap_package() {
    if snap list | grep -q "$1"; then
        return 0
    fi
    return 1
}

# Function to install a package via APT
install_apt_package() {
    sudo apt-get update
    sudo apt-get install -y "$1"
}

# Function to install a package via npm
install_npm_package() {
    sudo npm install -g "$1"
}

# Function to install a package via Snap
install_snap_package() {
    sudo snap install "$1"
}

# Function to uninstall a package via APT
uninstall_apt_package() {
    sudo apt-get remove -y "$1"
}

# Function to uninstall a package via npm
uninstall_npm_package() {
    sudo npm uninstall -g "$1"
}

# Function to uninstall a package via Snap
uninstall_snap_package() {
    sudo snap remove "$1"
}

# Redirect standard input to file descriptor 3
exec 3<&0

while true; do
    # Arrays to store software names and installation methods
    software_names=()
    install_methods=()
    
    # Read the software list file and store the lines in an array
    mapfile -t software_names < <(sort "$software_list_file")

    for software_name in "${software_names[@]}"; do
        # Check if the software is installed via APT
        if check_apt_package "$software_name"; then
            install_methods+=("${GREEN}${CHECK_MARK}${NC}")
            continue
        fi
        
        # Check if the software is installed via npm
        if check_npm_package "$software_name"; then
            install_methods+=("${GREEN}${CHECK_MARK}${NC}")
            continue
        fi
        
        # Check if the software is available as a Snap
        if check_snap_package "$software_name"; then
            install_methods+=("${GREEN}${CHECK_MARK}${NC}")
            continue
        fi
        
        # If it's not found in APT, npm, or Snap, then it's not installed
        install_methods+=("${RED}${CROSS_MARK}${NC}")
    done

    # Display software list with numbers
    echo "Software List:"
    for i in "${!software_names[@]}"; do
        echo "$((i+1)). ${software_names[$i]} (Status: ${install_methods[$i]})"
    done

    # Offer options to install or uninstall software or install all not installed
    read -p "Enter the number of the software to manage, 'A' to install all not installed, 'S' to skip, or press Enter to exit: " choice

    if [ -z "$choice" ]; then
        break
    elif [[ "${choice^^}" == "S" ]]; then
        break
    elif [[ "${choice^^}" == "A" ]]; then
        for ((i=0; i<${#software_names[@]}; i++)); do
            if [[ "${install_methods[$i]}" == "${RED}${CROSS_MARK}${NC}" ]]; then
                software_name="${software_names[$i]}"
                if [ -n "$(apt-cache search --names_only "^$software_name\$")" ]; then
                    install_apt_package "$software_name"
                elif [ -n "$(npm info -g "$software_name" 2>/dev/null)" ]; then
                    install_npm_package "$software_name"
                else
                    install_snap_package "$software_name"
                fi
            fi
        done
    elif [[ "$choice" =~ ^[0-9]+$ ]]; then
        index=$((choice - 1))
        software_name="${software_names[$index]}"
        install_method="${install_methods[$index]}"
        
        if [[ "${install_method}" == "${GREEN}${CHECK_MARK}${NC}" ]]; then
            read -p "$software_name is installed. Do you want to uninstall it? (y/n): " uninstall_choice
            if [ "$uninstall_choice" == "y" ]; then
                if check_apt_package "$software_name"; then
                    uninstall_apt_package "$software_name"
                else
                    uninstall_npm_package "$software_name"
                fi
            fi
        elif [[ "${install_method}" == "${RED}${CROSS_MARK}${NC}" ]]; then
            read -p "Do you want to install $software_name? (y/n): " install_choice
            if [ "$install_choice" == "y" ]; then
                if [ -n "$(apt-cache search --names_only "^$software_name\$")" ]; then
                    install_apt_package "$software_name"
                elif [ -n "$(npm info -g "$software_name" 2>/dev/null)" ]; then
                    install_npm_package "$software_name"
                else
                    install_snap_package "$software_name"
                fi
            fi
        fi
    fi
done

# Close file descriptor 3
exec 3<&-
