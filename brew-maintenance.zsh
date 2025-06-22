#!/bin/zsh

# ------------------------------------------------------------------------------
# Homebrew Maintenance Script
# Author: Prasit Chanda
# Platform: macOS
# Version: 1.1.0
# Description: Checks, updates, upgrades, diagnoses, and cleans Homebrew packages.
# Last Updated: 2025-06-22
# ------------------------------------------------------------------------------

# ───── Colors Variables ─────
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
RED=$'\e[31m'
BLUE=$'\e[34m'
CYAN=$'\e[36m'
RESET=$'\e[0m'

# ───── Global Variables ─────
VER="1.1.0-2025062201"
DATE=$(date)
TS=$(date +"%Y%m%d%H%M%S")
LF="brew-maintenance-${TS}.log"
WD=$PWD
LOGFILE="${WD}/${LF}"

# ───── Custom Methods ─────
print_box() {
  local content="$1"
  local padding=2
  local IFS=$'\n'
  local lines=($content)
  local max_length=0
  for line in "${lines[@]}"; do
    (( ${#line} > max_length )) && max_length=${#line}
  done
  local box_width=$((max_length + padding * 2))
  local border_top="╔$(printf '═%.0s' $(seq 1 $box_width))╗"
  local border_bottom="╚$(printf '═%.0s' $(seq 1 $box_width))╝"
  echo "$border_top"
  for line in "${lines[@]}"; do
    local total_space=$((box_width - ${#line}))
    local left_space=$((total_space / 2))
    local right_space=$((total_space - left_space))
    printf "%*s%s%*s\n" "$left_space" "" "$line" "$right_space" ""
  done
  echo "$border_bottom"
}
fancy_divider() {
  local width=${1:-50}
  local char="${2:-━}"
  local line=""
  while [[ ${(L)#line} -lt $width ]]; do
    line+="$char"
  done
  print -r -- "$line"
}
fancy_header() {
  local label="$1"
  local total_width=80
  local padding_width=$(( (total_width - ${#label} - 2) / 2 ))
  printf '%*s' "$padding_width" '' | tr ' ' '='
  printf " %s " "$label"
  printf '%*s\n' "$padding_width" '' | tr ' ' '='
}
get_free_space() {
  df -k / | tail -1 | awk '{print $4 * 1024}'
}
human_readable_space() {
  local bytes=$1
  if (( bytes < 1024 )); then
    echo "${bytes} Bytes"
  elif (( bytes < 1024 * 1024 )); then
    echo "$(( bytes / 1024 )) KB"
  elif (( bytes < 1024 * 1024 * 1024 )); then
    echo "$(( bytes / 1024 / 1024 )) MB"
  else
    echo "$(( bytes / 1024 / 1024 / 1024 )) GB"
  fi
}
check_brew_dependencies() {
  local dependencies_status=0
  fancy_header "Checking Dependencies"
  echo "${YELLOW}"
  if ! command -v brew >/dev/null 2>&1; then
    echo "❌ Homebrew is not installed"
    dependencies_status=1
  else
    echo "Homebrew is installed"
  fi
  if ! xcode-select -p >/dev/null 2>&1; then
    echo "❌ Xcode Command Line Tools are not installed"
    dependencies_status=1
  else
    echo "Xcode Command Line Tools are installed"
  fi
  if [[ $dependencies_status -eq 0 ]]; then
    echo "Dependency check complete. Ready to execute script."
  else
    echo "❌ Dependencies did not comply."
    echo "🚫 Terminating script execution."
    exit 1
  fi
  echo "${RESET}"
}

# ───── Script Starts ─────
setopt local_options nullglob extended_glob
clear

exec > >(stdbuf -oL tee >(stdbuf -oL sed 's/\x1B\[[0-9;]*[JKmsu]//g' > "${LF}")) \
     2> >(stdbuf -oL tee >(stdbuf -oL sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "${LF}") >&2)

echo ""
print_box "Homebrew Maintenance Script"
echo ""
echo "${CYAN}${DATE}${RESET}"
echo ""
fancy_header " Homebrew Maintenance "
echo "${GREEN}System: $(sw_vers -productName) $(sw_vers -productVersion) ($(sw_vers -buildVersion))${RESET}"
echo "${CYAN}Starting Homebrew maintenance tasks${RESET}"
echo ""

check_brew_dependencies

brew_prefix=$(brew --prefix)

fix_permissions() {
  echo "${BLUE}Fixing Homebrew directory ownership and permissions...${RESET}"
  sudo chown -R "$(whoami):admin" "$brew_prefix"
  sudo chown -R "$(whoami):admin" "$brew_prefix"/{Cellar,Caskroom,Frameworks,bin,etc,include,lib,opt,sbin,share,var}
  sudo chmod -R g+w "$brew_prefix"/{Cellar,Caskroom,Frameworks,bin,etc,include,lib,opt,sbin,share,var}
  echo "${GREEN}Permissions adjusted.${RESET}"
}

fix_broken_links() {
  echo "${BLUE}Checking for broken or unlinked Homebrew formulae...${RESET}"
  for formula in $(brew list --formula); do
    if ! brew list --verbose "$formula" >/dev/null 2>&1; then
      echo "${YELLOW}Broken formula detected: $formula. Reinstalling...${RESET}"
      brew reinstall "$formula" --quiet
    fi
  done
  echo "${BLUE}Ensuring all formulae are properly linked...${RESET}"
  for formula in $(brew list --formula); do
    brew_output=$(brew list --verbose "$formula" 2>/dev/null || true)
    if ! echo "$brew_output" | grep -q "$brew_prefix"; then
      echo "${YELLOW}Linking formula: $formula${RESET}"
      brew link --overwrite --force "$formula" --quiet
    fi
  done
}

relink_critical_tools() {
  echo "${BLUE}Relinking essential Homebrew tools...${RESET}"
  tools=(brew curl git python3 ruby node)
  for tool in $tools; do
    if brew list --formula | grep -q "^$tool$"; then
      echo "${YELLOW}Relinking: $tool${RESET}"
      brew unlink "$tool" >/dev/null 2>&1 || true
      brew link --overwrite "$tool" --quiet
    fi
  done
  echo "${GREEN}Critical tools relinking completed.${RESET}"
}

# Ask for sudo once at the start
sudo -v

# Keep sudo session alive
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Measure free disk space before
space_before=$(get_free_space)

# Step 1: Fix permissions
fancy_header " Fixing Permissions "
fix_permissions
echo ""

# Step 2: Doctor
fancy_header " Brew Doctor "
brew doctor || echo "${YELLOW}Some warnings detected. Attempting to continue...${RESET}"
echo ""

# Step 3: Update
fancy_header " Brew Update "
brew update
echo ""

# Step 4: Upgrade Formulae
fancy_header " Brew Upgrade (Formulae) "
brew upgrade
echo ""

# Step 5: Upgrade Casks
fancy_header " Brew Upgrade (Casks) "
brew upgrade --cask
echo ""

# Step 6: Fix Broken Links
fancy_header " Fixing Broken Links "
fix_broken_links
echo ""

# Step 7: Relink Critical Tools
fancy_header " Relinking Critical Tools "
relink_critical_tools
echo ""

# Step 8: Cleanup
fancy_header " Brew Cleanup "
brew cleanup
echo ""

# Measure free disk space after
space_after=$(get_free_space)
space_freed=$(( space_after - space_before ))

# Step 9: Final Doctor
fancy_header " Final Brew Doctor "
brew doctor || echo "${YELLOW}Some issues still present. Manual review may be needed.${RESET}"
echo ""

# Display result
echo "${GREEN}Homebrew maintenance complete.${RESET}"
if (( space_freed > 0 )); then
  echo "${GREEN}Disk Freed $(human_readable_space $space_freed)${RESET}"
elif (( space_freed < 0 )); then
  echo "${YELLOW}No noticeable disk space change due to background processes${RESET}"
else
  echo "${YELLOW}Disk space unchanged${RESET}"
fi
echo "${GREEN}Log PATH ${LOGFILE}${RESET}"
echo ""

# Footer
fancy_divider 25 "="
echo "Version ${VER}"
echo "Prasit Chanda © $(date +%Y)"
fancy_divider 25 "="
echo ""
setopt nomatch

sync "${LOGFILE}"
exec 1>&- 2>&-
open -a "Console" "${LOGFILE}"
exit