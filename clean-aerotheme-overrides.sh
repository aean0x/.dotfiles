#!/bin/bash

# Script to check for and delete aerotheme-related files in the home directory
# that would override the ones installed from Nix

echo "Checking for aerotheme files in your home directory that might override Nix-installed versions..."

# Define the base directories to check (based on aerothemeplasma.nix installPhase)
HOME_DIRS=(
  "$HOME/.local/share/plasma/desktoptheme"
  "$HOME/.local/share/plasma/look-and-feel"
  "$HOME/.local/share/plasma/plasmoids"
  "$HOME/.local/share/plasma/layout-templates"
  "$HOME/.local/share/plasma/shells"
  "$HOME/.local/share/kwin/effects"
  "$HOME/.local/share/kwin/tabbox"
  "$HOME/.local/share/kwin/outline"
  "$HOME/.local/share/kwin/scripts"
  "$HOME/.local/share/color-schemes"
  "$HOME/.local/share/Kvantum"
  "$HOME/.local/share/sddm/themes"
  "$HOME/.local/share/mime/packages"
  "$HOME/.local/share/icons/Windows 7 Aero"
  "$HOME/.local/share/sounds/Windows 7"
  "$HOME/.local/share/smod"
)

# Files to check specifically (patterns that might indicate aerotheme files)
THEME_PATTERNS=(
  "*aero*"
  "*win7*"
  "*windows*"
  "*smod*"
  "*seven*"
)

# Counter for found items
found_count=0

# Function to check and ask for deletion
check_and_delete() {
  local dir="$1"
  local pattern="$2"
  
  if [ -d "$dir" ]; then
    local files=$(find "$dir" -name "$pattern" 2>/dev/null)
    if [ -n "$files" ]; then
      echo -e "\nFound potential aerotheme files in $dir:"
      echo "$files"
      found_count=$((found_count + 1))
      
      echo -n "Would you like to delete these files? (y/n): "
      read -r response
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Deleting files..."
        find "$dir" -name "$pattern" -exec rm -rf {} \; 2>/dev/null
        echo "Files deleted."
      else
        echo "Keeping files."
      fi
    fi
  fi
}

# Check each directory for theme-related files
for dir in "${HOME_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo "Checking $dir..."
    for pattern in "${THEME_PATTERNS[@]}"; do
      check_and_delete "$dir" "$pattern"
    done
  fi
done

# Special cases for specific aerotheme components
special_cases=(
  "$HOME/.local/share/sddm/themes/sddm-theme-mod"
)

for case in "${special_cases[@]}"; do
  if [ -e "$case" ]; then
    echo -e "\nFound special case: $case"
    found_count=$((found_count + 1))
    
    echo -n "Would you like to delete it? (y/n): "
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      echo "Deleting $case..."
      rm -rf "$case"
      echo "Deleted."
    else
      echo "Keeping $case."
    fi
  fi
done

if [ $found_count -eq 0 ]; then
  echo -e "\nNo aerotheme-related files found in your home directory that would override the Nix-installed versions."
else
  echo -e "\nCompleted checking for aerotheme overrides."
fi

echo "Done!" 