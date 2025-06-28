#!/bin/zsh

#----------------------------------------------------------------------------------------------
# Homebrew Maintenance Script for macOS
# Author: Prasit Chanda 
# Version: 1.5.6-20250629-EQ82H
# Automates Homebrew health: fixes permissions, updates, 
#           upgrades, relinks, cleans, and logs.
# Requires: Homebrew, Xcode CLT, zsh, sudo. Run in Terminal. 
#           Generates a summary and log.
#----------------------------------------------------------------------------------------------

# ───── Static Colors Variables ─────
BLUE=$'\e[94m'
CYAN=$'\e[36m'
GREEN=$'\e[32m'
RED=$'\e[31m'
RESET=$'\e[0m'
WHITE='\e[97m'
YELLOW=$'\e[33m'

# ───── Static Text Variables ─────
BROKEN_FORMULAE_FOUND_MSG="Broken formula found:"
BROKEN_FORMULAE_MSG="Checking for broken or unlinked formulae..."
BROKEN_FORMULAE_REINSTALL_MSG="Reinstalling formula..."
CLEANUP_HEADER="Cleanup"
CLEANUP_INFO="Remove old versions to free up space"
DEPENDENCIES_FAIL_MSG="Dependency check failed"
DEPENDENCIES_HEADER="Dependencies"
DEPENDENCIES_OK_MSG="All dependencies are OK"
DEPENDENCIES_START_MSG="Starting maintenance tasks..."
DEPENDENCIES_SUDO_MSG="You may need to enter your password"
DEPENDENCIES_TERMINAL_MSG="Best run directly in Terminal"
DEPENDENCIES_TERMINATE_MSG="❌ Script stopped due to errors"
DOCTOR_HEADER="Doctor"
DOCTOR_INFO="Check for Homebrew issues"
FINAL_DOCTOR_HEADER="Final Check"
FINAL_DOCTOR_INFO="Rechecking for any remaining issues"
FIX_LINKS_HEADER="Broken Links"
FIX_LINKS_INFO="Scan and fix broken Homebrew links"
FIX_PERMISSIONS_MSG="Fixing file permissions..."
INTERNET_FAIL_MSG="No internet or unstable connection"
INTERNET_OK_MSG="Internet connection is good"
LINKING_FORMULAE_MSG="Linking all formulae..."
LINKING_FORMULA_MSG="Linking:"
MAINTENANCE_COMPLETE_MSG="✅ Maintenance complete"
NO_INTERNET_LINKS_MSG="Can't fix links: No internet"
NO_INTERNET_RELINK_MSG="Can't relink tools: No internet"
NO_INTERNET_UPDATE_MSG="Can't update: No internet"
NO_INTERNET_UPGRADE_CASKS_MSG="Can't upgrade casks: No internet"
NO_INTERNET_UPGRADE_FORMULAE_MSG="Can't upgrade formulae: No internet"
OPEN_LOG_FAIL_MSG="Failed to open log in Console"
PERMISSIONS_ADJUSTED_MSG="Permissions fixed"
PERMISSIONS_HEADER="Permissions"
PERMISSIONS_INFO="Fix ownership and access rights"
RELINK_TOOLS_HEADER="Relinking"
RELINK_TOOLS_INFO="Ensure tools are correctly set up"
RELINK_TOOLS_MSG="Relinking essential tools..."
RELINKED_MSG="Tools relinked"
RELINKING_MSG="Relinking:"
SCRIPT_BOX_TITLE="brew-maintenance.zsh"
SCRIPT_DESCRIPTION="All-in-one Homebrew script: updates, fixes, cleans, and saves space"
SCRIPT_EXIT_MSG="  ● Press ⌃ + C to exit anytime"
SCRIPT_INTERNET_MSG="  ● Requires a stable internet connection"
SCRIPT_START_MSG="Running brew-maintenance"
SCRIPT_SUDO_MSG="  ● You may be asked for your password"
SCRIPT_TERMINAL_MSG="  ● Use macOS Terminal for best results"
SUMMARY_AUTHOR_LABEL="Author:"
SUMMARY_BOX_TITLE="Summary"
SUMMARY_CLEANUP_MSG="✔ Cleanup done"
SUMMARY_DISK_FREED_MSG="✔ Space saved:"
SUMMARY_DISK_UNCHANGED_MSG="No space change"
SUMMARY_ISSUES_MSG="Some issues remain—check manually"
SUMMARY_LINKS_MSG="✔ Links fixed"
SUMMARY_LOG_LABEL="Log:"
SUMMARY_NO_DISK_CHANGE_MSG="No visible space saved"
SUMMARY_PERMISSIONS_MSG="✔ Permissions corrected"
SUMMARY_RELINKED_MSG="✔ Tools relinked"
SUMMARY_SCRIPT_LABEL="Version:"
SUMMARY_UPDATED_MSG="✔ Updated successfully"
SYSTEM_HEADER="Homebrew"
SYSTEM_LABEL="System:"
UPDATE_HEADER="Update"
UPDATE_INFO="Update formulas and definitions"
UPGRADE_CASKS_HEADER="Upgrade Casks"
UPGRADE_CASKS_INFO="Update all installed casks"
UPGRADE_FORMULAE_HEADER="Upgrade Formulae"
UPGRADE_FORMULAE_INFO="Update all installed formulae"

# ───── Global Variables ─────
AUTHOR="Prasit Chanda"
brew_prefix=$(brew --prefix)
DATE=$(date "+%a, %d %b %Y %H:%M:%S %p")
DNS_SERVER="1.1.1.1"
TS=$(date +"%Y%m%d%H%M%S")
LF="brew-maintenance-${TS}.log"
WD=$PWD
LOGFILE="${WD}/${LF}"
VER="1.5.6-20250629-EQ82H"

# ───── Custom Methods ─────

# Function to ask user if they want to exit
ask_user_consent() {
  print -nP "%F{yellow}Do you want to continue running the script? (y/n)"
  read answer
  echo ""
  case "$answer" in
    [nN]* )
      echo "❌ ${RED}Execution of brew-maintenance.zsh cancelled by $(whoami)${RESET}"
      echo ""
      USER_EXITED=1 # Set the flag so summary knows user exited
      show_brew_report # Print summary (will skip results if exited)
      exit 0
      ;;
    * )
      echo "${GREEN}$(whoami) gave the green light — launching brew-maintenance.zsh${RESET}"
      echo ""
      ;;
  esac
}

# Check for Homebrew and Xcode Command Line Tools
check_brew_dependencies() {
    local dependencies_status=0
    fancy_header "$DEPENDENCIES_HEADER"
    echo "${YELLOW}"
    if ! command -v brew >/dev/null 2>&1; then
        echo "${RED}❌ Homebrew is not installed"
        dependencies_status=1
    else
        echo "${GREEN}Homebrew is installed"
    fi
    if ! xcode-select -p >/dev/null 2>&1; then
        echo "${RED}❌ Xcode Command Line Tools are not installed"
        dependencies_status=1
    else
        echo "${GREEN}Xcode Command Line Tools are installed"
    fi
    if [[ $dependencies_status -eq 0 ]]; then
        echo "${GREEN}$DEPENDENCIES_OK_MSG"
        check_internet
        echo "$DEPENDENCIES_START_MSG"
    else
        echo "${RED}$DEPENDENCIES_FAIL_MSG"
        echo "$DEPENDENCIES_TERMINATE_MSG"
        exit 1
    fi
    echo "${RESET}"
}

# Check internet connectivity
check_internet() {
  local timeout=2
  if ping -c 1 -W $timeout "$DNS_SERVER" >/dev/null 2>&1; then
    echo "${GREEN}$INTERNET_OK_MSG${RESET}"
    return 0
  else
    echo "${RED}$INTERNET_FAIL_MSG${RESET}"
    return 1
  fi
}

# Fancy Header and Divider Functions
fancy_divider() {
    local width=${1:-50} 
    local char="${2:-━}"        
    local line=""
    while [[ ${(L)#line} -lt $width ]]; do
        line+="$char"
    done
    print -r -- "$line"
}

# Fancy Header Function
fancy_header() {
    local label="$1"
    local total_width=30
    local padding_width=$(( (total_width - ${#label} - 2) / 2 ))
    printf '%*s' "$padding_width" '' | tr ' ' '='
    printf " %s " "$label"
    printf '%*s\n' "$padding_width" '' | tr ' ' '='
}

fix_broken_links() {
    echo "${BLUE}$BROKEN_FORMULAE_MSG${RESET}"
    for formula in $(brew list --formula); do
        if ! brew list --verbose "$formula" >/dev/null 2>&1; then
            echo "${YELLOW}$BROKEN_FORMULAE_FOUND_MSG $formula. $BROKEN_FORMULAE_REINSTALL_MSG${RESET}"
            brew reinstall "$formula" --quiet
        fi
    done
    echo "${BLUE}$LINKING_FORMULAE_MSG${RESET}"
    for formula in $(brew list --formula); do
        brew_output=$(brew list --verbose "$formula" 2>/dev/null || true)
        if ! echo "$brew_output" | grep -q "$brew_prefix"; then
            echo "${YELLOW}$LINKING_FORMULA_MSG $formula${RESET}"
            brew link --overwrite --force "$formula" --quiet
        fi
    done
}

# Fix Permissions
fix_permissions() {
    echo "${BLUE}$FIX_PERMISSIONS_MSG${RESET}"
    sudo chown -R "$(whoami):admin" "$brew_prefix"
    sudo chown -R "$(whoami):admin" "$brew_prefix"/{Cellar,Caskroom,Frameworks,bin,etc,include,lib,opt,sbin,share,var}
    sudo chmod -R g+w "$brew_prefix"/{Cellar,Caskroom,Frameworks,bin,etc,include,lib,opt,sbin,share,var}
    echo "${GREEN}$PERMISSIONS_ADJUSTED_MSG${RESET}"
}

# Function to generate a random 5-character string (A-Z, 1-9)
generate_random_string() {
  local chars=( {A..Z} {0..9})
  local num_chars=${#chars[@]}
  if (( num_chars == 0 )); then
    # echo "❌ Error: character array is empty!"
    return 1
  fi
  local str=""
  for i in {1..25}; do
    str+="${chars[RANDOM % num_chars]}"
    if (( i % 5 == 0 && i != 25 )); then
      str+="-"
    fi
  done
  echo "$str"
}

# Get free disk space in bytes
get_free_space() {
    df -k / | tail -1 | awk '{print $4 * 1024}'
}

# Convert bytes to human-readable format
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

# Print hints for each step
print_hints() {
    local words=(${(z)1})
    local i=1
    print -Pn "\n%F{cyan} ⓘ "
    for word in $words; do
        print -n -P "$word "
        (( i++ % 20 == 0 )) && print
    done
    print -P "%f\n"
}

# Print a box around the content
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

# Show the summary report
show_brew_report() {
    echo ""
    print_box "$SUMMARY_BOX_TITLE"
    echo ""
    echo "${GREEN}$SUMMARY_PERMISSIONS_MSG${RESET}"
    echo "${GREEN}$SUMMARY_UPDATED_MSG${RESET}"
    echo "${GREEN}$SUMMARY_LINKS_MSG${RESET}"
    echo "${GREEN}$SUMMARY_RELINKED_MSG${RESET}"
    echo "${GREEN}$SUMMARY_CLEANUP_MSG${RESET}"
    space_after=$(get_free_space)
    space_freed=$(( space_after - space_before ))
    if (( space_freed > 0 )); then
        echo "${GREEN}$SUMMARY_DISK_FREED_MSG $(human_readable_space $space_freed)${RESET}"
    elif (( space_freed < 0 )); then
        echo "${YELLOW}$SUMMARY_NO_DISK_CHANGE_MSG${RESET}"
    else
        echo "${YELLOW}$SUMMARY_DISK_UNCHANGED_MSG${RESET}"
    fi
    echo ""
    echo "Log File $LOGFILE"
    echo "Script Version $VER"
    echo ""
    fancy_header " ${AUTHOR} © $(date +%Y) "
    echo ""
    sync
    exec 1>&- 2>&-
    if command -v open >/dev/null 2>&1; then
        open -a "Console" "${LOGFILE}" 2>/dev/null || echo "${YELLOW}$OPEN_LOG_FAIL_MSG${RESET}"
    fi
}

# Relink critical tools
relink_critical_tools() {
    echo "${BLUE}$RELINK_TOOLS_MSG${RESET}"
    tools=(brew curl git python3 ruby node)
    for tool in $tools; do
        if brew list --formula | grep -q "^$tool$"; then
            echo "${YELLOW}$RELINKING_MSG $tool${RESET}"
            brew unlink "$tool" >/dev/null 2>&1 || true
            brew link --overwrite "$tool" --quiet
        fi
    done
    echo "${GREEN}$RELINKED_MSG${RESET}"
}

# ───── Script Starts ─────
clear

# Check if running in zsh
if [[ -z "$ZSH_VERSION" ]]; then
  echo "❌ ${RED}This script requires zsh to run. Please run it with zsh${RESET}" >&2
  show_brew_report
  exit 0
fi

# Check if running in macOS
if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ ${RED}Unsupported OS: This script only works for macOS${RESET}" >&2
  show_brew_report
  exit 1
fi

#
setopt nullglob extended_glob

# Create log file and redirect output
exec > >(stdbuf -oL tee >(stdbuf -oL sed 's/\x1B\[[0-9;]*[JKmsu]//g' > "${LF}")) \
     2> >(stdbuf -oL tee >(stdbuf -oL sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "${LF}") >&2)

# Print script header
echo ""
print_box "$SCRIPT_BOX_TITLE"
echo "${CYAN}"
echo "$SCRIPT_DESCRIPTION"
echo "${RESET}${GREEN}"
echo "$DATE"
echo "SCAN ID $(generate_random_string)"
echo "Version $VER"
echo "Author  $AUTHOR"
echo "${RESET}"
echo "${GREEN}$SCRIPT_START_MSG${RESET}"
echo "${GREEN}$SCRIPT_SUDO_MSG${RESET}"
echo "${GREEN}$SCRIPT_TERMINAL_MSG${RESET}"
echo "${YELLOW}$SCRIPT_INTERNET_MSG${RESET}"
echo "${RED}$SCRIPT_EXIT_MSG${RESET}"
echo ""

# Print homebrew information
fancy_header "$SYSTEM_HEADER"
echo "${BLUE}$SYSTEM_LABEL $(sw_vers -productName) $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
brew config
brew info
echo "${RESET}"

check_brew_dependencies

# Ask user for consent to continue (can exit here)
ask_user_consent

sudo -v

while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

space_before=$(get_free_space)

# Step 1: Fix permissions
fancy_header "$PERMISSIONS_HEADER"
print_hints "$PERMISSIONS_INFO"
fix_permissions
echo ""

# Step 2: Doctor
fancy_header "$DOCTOR_HEADER"
print_hints "$DOCTOR_INFO"
brew doctor
echo ""

# Step 3: Update
fancy_header "$UPDATE_HEADER"
print_hints "$UPDATE_INFO"
check_internet
if [[ $? -eq 0 ]]; then
  brew update
else
  echo "${RED}$NO_INTERNET_UPDATE_MSG${RESET}"
fi
echo ""

# Step 4: Upgrade Formulae
fancy_header "$UPGRADE_FORMULAE_HEADER"
print_hints "$UPGRADE_FORMULAE_INFO"
check_internet
if [[ $? -eq 0 ]]; then
  brew upgrade
else
  echo "${RED}$NO_INTERNET_UPGRADE_FORMULAE_MSG${RESET}"
fi
echo ""

# Step 5: Upgrade Casks
fancy_header "$UPGRADE_CASKS_HEADER"
print_hints "$UPGRADE_CASKS_INFO"
check_internet
if [[ $? -eq 0 ]]; then
  brew upgrade --cask
else
  echo "${RED}$NO_INTERNET_UPGRADE_CASKS_MSG${RESET}"
fi
echo ""

# Step 6: Fix Broken Links
fancy_header "$FIX_LINKS_HEADER"
print_hints "$FIX_LINKS_INFO"
check_internet
if [[ $? -eq 0 ]]; then
  fix_broken_links
else
  echo "${RED}$NO_INTERNET_LINKS_MSG${RESET}"
fi
echo ""

# Step 7: Relink Critical Tools
fancy_header "$RELINK_TOOLS_HEADER"
print_hints "$RELINK_TOOLS_INFO"
check_internet
if [[ $? -eq 0 ]]; then
  relink_critical_tools
else
  echo "${RED}$NO_INTERNET_RELINK_MSG${RESET}"
fi
echo ""

# Step 8: Cleanup
fancy_header "$CLEANUP_HEADER"
print_hints "$CLEANUP_INFO"
brew cleanup
echo ""

# Step 9: Final Doctor
fancy_header "$FINAL_DOCTOR_HEADER"
print_hints "$FINAL_DOCTOR_INFO"
brew doctor || echo "${YELLOW}$SUMMARY_ISSUES_MSG${RESET}"
echo ""
echo "${GREEN}$MAINTENANCE_COMPLETE_MSG${RESET}"

# Print the cleanup summary at the end
show_brew_report

# Ensure all background jobs are killed on exit
trap 'kill $(jobs -p) 2>/dev/null' EXIT

exit 0