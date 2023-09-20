#!/bin/bash

# Define text color variables
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
NC=$(tput sgr0)  # Reset text color
CHECK_MARK="✔"
CROSS_MARK="✖"

# Function to check if a package is installed via APT
is_installed_apt() {
  dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# Function to install a package via APT
install_package_apt() {
  sudo apt-get install -y "$1"
}

# Function to uninstall a package via APT
uninstall_package_apt() {
  sudo apt-get remove -y "$1"
}

# Function to check if a package is installed via Snap
is_installed_snap() {
  snap list | grep -q "$1"
}

# Function to install a package via Snap
install_package_snap() {
  sudo snap install "$1"
}

# Function to uninstall a package via Snap
uninstall_package_snap() {
  sudo snap remove "$1"
}

# Function to display the menu
display_menu() {
  echo -e "Menu:"
  echo "a/A. Install all packages that are not installed"
  echo "Enter. Exit"
}

# Function to display the software status
display_status() {
  echo "Software Status:"
  software_names=()
  index=0
  while IFS= read -r software; do
    software_names+=("$software")
    if is_installed_apt "$software"; then
      echo -e "[$((index+1))] [${GREEN}${CHECK_MARK}${NC}] $software is installed (via APT)"
    elif is_installed_snap "$software"; then
      echo -e "[$((index+1))] [${GREEN}${CHECK_MARK}${NC}] $software is installed (via Snap)"
    else
      echo -e "[$((index+1))] [${RED}${CROSS_MARK}${NC}] $software is not installed"
    fi
    ((index++))
  done < "software_list.txt"
}

# Function to manage a package
manage_package() {
  local software="$1"
  if is_installed_apt "$software"; then
    read -p "Do you want to uninstall $software? (y/n): " choice
    if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
      uninstall_package_apt "$software"
      echo "Uninstalled: $software"
    else
      echo "No changes made to $software."
    fi
  elif is_installed_snap "$software"; then
    read -p "Do you want to uninstall $software? (y/n): " choice
    if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
      uninstall_package_snap "$software"
      echo "Uninstalled: $software"
    else
      echo "No changes made to $software."
    fi
  else
    echo "Installing $software..."
    if install_package_apt "$software"; then
      echo "Installed: $software (via APT)"
    elif install_package_snap "$software"; then
      echo "Installed: $software (via Snap)"
    else
      echo "Failed to install $software."
    fi
  fi
}

while true; do
  # Display the software status
  display_status

  # Display the menu
  display_menu

  # Prompt the user for their choice
  read -p "Enter your choice: " choice

  # Exit if the user presses Enter
  if [ -z "$choice" ]; then
    echo "Exiting."
    break
  elif [ "$choice" == "a" ] || [ "$choice" == "A" ]; then
    # Read software names from the file and install all packages that are not installed
    while IFS= read -r software; do
      manage_package "$software"
    done < "software_list.txt"
  elif (( choice >= 1 && choice <= index )); then
    # Manage the selected package by number
    manage_package "${software_names[choice-1]}"
  else
    echo "Invalid choice. Please try again."
  fi
done
