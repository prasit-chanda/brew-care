#!/bin/zsh

# Optimize globbing and file matching for safety and flexibility
setopt nullglob extended_glob localoptions no_nomatch

# ------------------------------------------------------------------------------
# Homebrew Maintenance Script for macOS
# Author: Prasit Chanda 
# Version: 1.5.8-20250630-YG2OZ
# Automates Homebrew health: fixes permissions, updates, upgrades, relinks, cleans, and logs
# Requires: Homebrew, Xcode CLT, zsh, sudo. Run in Terminal
# ------------------------------------------------------------------------------

# ───── Static Colors Variables ─────
# Use standard, high-contrast ANSI codes for best visibility on both dark and light backgrounds

BLUE=$'\e[94m'     # Bright Blue - Info/Action
CYAN=$'\e[86m'     # Bright Cyan - General Info
GREEN=$'\e[82m'    # Bright Green - Success
RED=$'\e[91m'      # Bright Red - Error/Failure
RESET=$'\e[0m'     # Reset all attributes
YELLOW=$'\e[93m'   # Bright Yellow - Warning/Skip

# ───── Global Variables ─────
# These variables are used throughout the script for various purposes

AUTHOR="Prasit Chanda"
# Homebrew installation prefix
BREW_PREFIX=$(brew --prefix)
# Current date and time (for display)
DATE=$(date "+%a, %d %b %Y %H:%M:%S %p")
# DNS server used for internet connectivity check
DNS_SERVER="1.1.1.1"
# Timestamp for unique log file naming
TS=$(date +"%Y%m%d%H%M%S")
# Log file name (without path)
LF="brew-maintenance-${TS}.log"
# Working directory (where script is run)
WD=$PWD
# Full path to log file
LOGFILE="${WD}/${LF}"
# Script version string
VER="1.5.8-20250630-YG2OZ"
# Script start time (epoch seconds)
START_TIME=$(date +%s)  # Capture start time
# Flag to check if user exited script (0 = running, 1 = user exited)
USER_EXITED=0  # Flag to check if user exited script

# ───── Static Text Variables ─────
# These variables contain static text used in the script for messages, headers, and prompts

AUTHOR_COPYRIGHT=" ${AUTHOR} © $(date +%Y) "
BREW_CASKS_UPGRADE_DONE_MSG="All Homebrew casks have been upgraded"
BREW_CLEANUP_DONE_MSG="Homebrew cleanup completed"
BREW_FINAL_CHECK_DONE_MSG="Final Homebrew check completed"    
BREW_FORMULAE_UPGRADE_DONE_MSG="All Homebrew formulae have been upgraded"
BREW_UPDATE_DONE_MSG="Homebrew update finished successfully"
BROKEN_FORMULAE_FOUND_MSG="Broken formula found:"
BROKEN_FORMULAE_MSG="Checking for broken or unlinked formulae"
BROKEN_FORMULAE_REINSTALL_MSG="Reinstalling formula"
BROKEN_LINKED_MSG="All broken links have been fixed"
CLEANUP_HEADER="Cleanup"
CLEANUP_INFO="Remove old packages to free up disk space"
DEPENDENCIES_BREW_ALREADY_INSTALLED="Homebrew is already installed"
DEPENDENCIES_BREW_FAIL="✖ Homebrew is required. Exiting brew-maintenance.zsh"
DEPENDENCIES_BREW_INSTALL_ATTEMPT="Attempting to install Homebrew..."
DEPENDENCIES_BREW_INSTALL_FAIL="✖ Homebrew installation failed"
DEPENDENCIES_BREW_INSTALL_SUCCESS="Homebrew installed successfully"
DEPENDENCIES_BREW_NOT_INSTALL="✖ Homebrew is not installed"
DEPENDENCIES_FAIL_MSG="✖ Dependency check failed"
DEPENDENCIES_HEADER="Dependencies"
DEPENDENCIES_OK_MSG="All dependencies are OK"
DEPENDENCIES_START_MSG="Starting maintenance tasks"
DEPENDENCIES_SUDO_MSG="You may need to enter your password"
DEPENDENCIES_TERMINAL_MSG="Best run directly in Terminal"
DEPENDENCIES_TERMINATE_MSG="✖ brew-maintenance.zsh might not run properly because some required dependencies are missing"
DEPENDENCIES_XCODE_INSTALL_SUCCESS="Xcode Command Line Tools are installed"
DEPENDENCIES_XCODE_NOT_INSTALL="✖ Xcode Command Line Tools are not installed"
DIAGNOSTIC_DONE_MSG="All Homebrew packages are in place and working fine"
DOCTOR_HEADER="Doctor"
DOCTOR_INFO="Checking for Homebrew issues"
FINAL_DOCTOR_HEADER="Final Check"
FINAL_DOCTOR_INFO="Doing a final check to make sure Homebrew is all cleaned up and trouble-free"
FIX_BREW_PERMISSION_MSG="Fixing ownership and access rights for Homebrew directories"
FIX_LINKS_HEADER="Broken Links"
FIX_LINKS_INFO="Checking for broken or missing Homebrew links"
FOOTER_EXECUTION_TIME_MSG="Script Execution Time"
FOOTER_LOG_FILE_MSG="Log File $LOGFILE"
FOOTER_SCRIPT_VERSION_MSG="Script Version $VER"
INTERNET_FAIL_MSG="✖ No internet or unstable connection"
INTERNET_OK_MSG="✓ Internet connection is good"
LINKING_FORMULAE_MSG="Linking all formulae to Homebrew prefix"
LINKING_FORMULA_MSG="Linking: "
MAINTENANCE_COMPLETE_MSG="All done! Homebrew is clean and running smoothly"
NO_INTERNET_LINKS_MSG="✖ Can’t fix links right now, no internet connection detected"
NO_INTERNET_RELINK_MSG="✖ Relinking tools failed due to no internet connection"
NO_INTERNET_UPDATE_MSG="✖ Update skipped, no internet connection available"
NO_INTERNET_UPGRADE_CASKS_MSG="✖ Cask upgrade failed due to missing internet connection"
NO_INTERNET_UPGRADE_FORMULAE_MSG="✖ Formulae upgrade failed due to missing internet connection"
NO_INTERNET_UPGRADE_MSG="✖ Upgrade skipped, no internet connection available"
OPEN_LOG_FAIL_MSG="✖ Failed to open log in Console"
PERMISSIONS_ADJUSTED_MSG="Permissions fixed for Homebrew directories"
PERMISSIONS_HEADER="Permissions"
PERMISSIONS_INFO="Checking Homebrew ownership and access rights"
PROMPT_USER_CONSENT_APPROVAL="✓ $(whoami) has approved the execution of brew-maintenance.zsh"
PROMPT_USER_CONSENT_DENIAL="✖ $(whoami) has denied the execution of brew-maintenance.zsh"
PROMPT_USER_CONSENT_MSG="Do you consent to continue executing the script? (y/n)"
PROMPT_USER_INSTALL_HOME_BREW="Would you like to install Homebrew on your Mac now? (y/n)"
PROMPT_VALIDATE_MSG="Please answer yes or no (y/n)"
RELINK_TOOLS_HEADER="Relinking"
RELINK_TOOLS_INFO="Making sure your Homebrew tools are installed and ready to use"
RELINK_TOOLS_MSG="Relinking essential tools"
RELINKED_MSG="Tools relinked successfully"
RELINKING_MSG="Relinking: "
SCRIPT_BOX_TITLE="brew-maintenance.zsh"
SCRIPT_DESCRIPTION="brew-maintenance.zsh is a free, all-in-one script for macOS that keeps your Homebrew 
setup healthy by checking dependencies, fixing issues, updating everything, cleaning 
up old files, and showing you exactly how much space you saved—all with one easy command"
SCRIPT_EXIT_MSG=" ● Press ⌃ + C to exit anytime"
SCRIPT_INTERNET_MSG=" ● Requires a stable internet connection"
SCRIPT_START_MSG="Running brew-maintenance"
SCRIPT_SUDO_MSG=" ● You may be asked for your password"
SCRIPT_TERMINAL_MSG=" ● Use macOS Terminal for best results"
SUMMARY_AUTHOR_LABEL="Author "
SUMMARY_BOX_TITLE="Recap"
SUMMARY_CLEANUP_MSG="✓ Remove old packages of Homebrew packages to free up space"
SUMMARY_DISK_FREED_MSG="✓ Free up space by removing "
SUMMARY_DISK_UNCHANGED_MSG="● No space change"
SUMMARY_ISSUES_MSG="Some issues remain—check manually"
SUMMARY_LINKS_MSG="✓ Fix broken Homebrew links"
SUMMARY_LOG_LABEL="Log "
SUMMARY_NO_DISK_CHANGE_MSG="● No visible space saved"
SUMMARY_PERMISSIONS_MSG="✓ Homebrew ownership and access rights corrected"
SUMMARY_RELINKED_MSG="✓ Homebrew tools are correctly set up"
SUMMARY_SCRIPT_LABEL="Version "
SUMMARY_UPDATED_MSG="✓ Hombrew available packages updated"
SUMMARY_UPGRADED_MSG="✓ Hombrew Formulae and Casks upgraded"
SYSTEM_HEADER="Homebrew"
SYSTEM_LABEL="System "
ROOT_WARNING_MSG="Warning: Root execution detected. Prefer using sudo as needed"
UNSUPPORTED_OS_MSG="✖ Unsupported OS: brew-maintenance.zsh only works for macOS"
UPDATE_HEADER="Update"
UPDATE_INFO="Checking Homebrew for available updates"
UPGRADE_CASKS_HEADER="Upgrade Casks"
UPGRADE_CASKS_INFO="Checking for upgrades to all installed Homebrew casks"
UPGRADE_FORMULAE_HEADER="Upgrade Formulae"
UPGRADE_FORMULAE_INFO="Checking for upgrades to all installed Homebrew formulae"
ZSH_REQUIRED_MSG="✖ brew-maintenance.zsh requires zsh to run. Please run it with zsh"

# ───── Custom Functions ─────

# This function asks the user for consent to continue executing the script
# It validates the input to ensure it is either 'yes' or 'no'
# If the user denies consent, it sets a flag to indicate that the user exited
# and prints a summary report before exiting
ask_user_consent() {
  while true; do
    print -nP "$PROMPT_USER_CONSENT_MSG"
    read answer
    echo ""
    case "$answer" in
      [yY][eE][sS]|[yY])
        echo "${GREEN}$PROMPT_USER_CONSENT_APPROVAL${RESET}"
        echo ""
        break
        ;;
      [nN][oO]|[nN])
        echo "${RED}$PROMPT_USER_CONSENT_DENIAL${RESET}"
        echo ""
        USER_EXITED=1     # Set the flag so summary knows user exited
        show_brew_report  # Print summary (will skip results if exited)
        exit 0
        ;;
      *)
        echo "${YELLOW}$PROMPT_VALIDATE_MSG${RESET}"
        ;;
    esac
  done
}

# This function checks if Homebrew and Xcode Command Line Tools are installed
# If Homebrew is not installed, it prompts the user to install it
# If Xcode Command Line Tools are not installed, it informs the user
# It also checks if the user has a stable internet connection 
check_brew_dependencies() {
  local dependencies_status=0
  fancy_text_header "$DEPENDENCIES_HEADER"
  echo ""
  if ! command -v brew >/dev/null 2>&1; then
    echo "${RED}$DEPENDENCIES_BREW_NOT_INSTALL${RESET}"
    while true; do
      print -nP "$PROMPT_USER_INSTALL_HOME_BREW"
      read install_brew
      echo ""
      case "$install_brew" in
        [yY][eE][sS]|[yY])
          echo "${YELLOW}$DEPENDENCIES_BREW_INSTALL_ATTEMPT${RESET}"
          /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
          if ! command -v brew >/dev/null 2>&1; then
            echo "${RED}$DEPENDENCIES_BREW_INSTALL_FAIL${RESET}"
            dependencies_status=1
          else
            echo "${GREEN}$DEPENDENCIES_BREW_INSTALL_SUCCESS${RESET}"
          fi
          break
          ;;
        [nN][oO]|[nN])
          echo "${RED}$DEPENDENCIES_BREW_FAIL${RESET}"
          dependencies_status=1
          USER_EXITED=1     # Set the flag so summary knows user exited
          show_brew_report  # Print summary (will skip results if exited)
          exit 0
          ;;
        *)
          echo "${YELLOW}$PROMPT_VALIDATE_MSG${RESET}"
          ;;
      esac
    done
  else
    echo "${GREEN}$DEPENDENCIES_BREW_ALREADY_INSTALLED${RESET}"
  fi
  if ! xcode-select -p >/dev/null 2>&1; then
    echo "${RED}$DEPENDENCIES_XCODE_NOT_INSTALL${RESET}"
    dependencies_status=1
  else
    echo "${GREEN}$DEPENDENCIES_XCODE_INSTALL_SUCCESS${RESET}"
  fi
  if [[ $dependencies_status -eq 0 ]]; then
    echo "${GREEN}$DEPENDENCIES_OK_MSG${RESET}"
    check_internet
    echo "${YELLOW}$DEPENDENCIES_START_MSG${RESET}"
  else
    echo "${RED}$DEPENDENCIES_FAIL_MSG${RESET}"
    echo "${RED}$DEPENDENCIES_TERMINATE_MSG${RESET}"
  fi
  echo ""
}

# This function ensures that all background jobs are killed and the log file is synced
# It also resets the trap to avoid recursive calls
cleanup() {
  # Kill background jobs (e.g., sudo keep-alive)
  trap - EXIT
  kill $(jobs -p) 2>/dev/null
  sync
}

# This function checks if the DNS server is reachable
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

# This function prints a fancy line divider with a specified width and character
fancy_line_divider() {
  local width=${1:-50} 
  local char="${2:-━}"        
  local line=""
  while [[ ${(L)#line} -lt $width ]]; do
    line+="$char"
  done
  print -r -- "$line"
}

# This function prints a fancy header with a label centered
fancy_text_header() {
  local label="$1"
  local total_width=25
  local padding_width=$(( (total_width - ${#label} - 2) / 2 ))
  printf '%*s' "$padding_width" '' | tr ' ' '='
  printf " %s " "$label"
  printf '%*s\n' "$padding_width" '' | tr ' ' '='
}

# This function checks for broken or unlinked formulae and attempts to fix them
# It lists all installed formulae, checks if they are linked correctly,
# and if not, it attempts to reinstall them
# It also checks if the formulae are linked to the Homebrew prefix
# If not, it relinks them
fix_brew_broken_links() {
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
    if ! echo "$brew_output" | grep -q "$BREW_PREFIX"; then
      echo "${YELLOW}$LINKING_FORMULA_MSG $formula${RESET}"
      brew link --overwrite --force "$formula" --quiet
    fi
  done
  echo "${GREEN}$BROKEN_LINKED_MSG${RESET}"
}

# This function adjusts ownership and permissions for Homebrew directories
# It ensures that the current user has the correct permissions to manage Homebrew
# It changes ownership to the current user and group, and sets group write permissions
fix_brew_permissions() {
  echo "${BLUE}$FIX_BREW_PERMISSION_MSG${RESET}"
  sudo chown -R "$(whoami):admin" "$BREW_PREFIX"
  sudo chown -R "$(whoami):admin" "$BREW_PREFIX"/{Cellar,Caskroom,Frameworks,bin,etc,include,lib,opt,sbin,share,var}
  sudo chmod -R g+w "$BREW_PREFIX"/{Cellar,Caskroom,Frameworks,bin,etc,include,lib,opt,sbin,share,var}
  echo "${GREEN}$PERMISSIONS_ADJUSTED_MSG${RESET}"
}

# Function to generate a random 5-character string (A-Z, 1-9)
# The string is formatted as XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
generate_random_string() {
  local chars=( {A..Z} {0..9})
  local num_chars=${#chars[@]}
  if (( num_chars == 0 )); then
    # echo "✖ Error: character array is empty!"
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

# This function returns the free space in bytes
get_free_space() {
  df -k / | tail -1 | awk '{print $4 * 1024}'
}

# This function converts bytes to a human-readable format (B, KB, MB, GB)
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

# This function prints hints for each step of the maintenance process
print_hints() {
  local words=(${(z)1})
  local i=1
  print -Pn "\n%F{cyan} ⓘ  "
  for word in $words; do
    print -n -P "$word "
    (( i++ % 20 == 0 )) && print
  done
  print -P "%f\n"
}

# This function prints a box around the given content 
print_title_box() {
  local content="$1"
  local padding=1
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
    local left_space=$((total_space / 1))
    local right_space=$((total_space - left_space))
    printf "%*s%s%*s\n" "$left_space" "" "$line" "$right_space" ""
  done
  echo "$border_bottom"
}

# ───── Summary and Reporting ─────
# This function prints a summary of the Homebrew maintenance tasks
# It includes the time taken, disk space freed, and the status of various tasks
# It also opens the log file in Console if available
# It uses the global variable USER_EXITED to determine if the user exited early
# and adjusts the output accordingly
show_brew_report() {
  local end_time=$(date +%s)  # Capture end time
  local duration=$(( end_time - START_TIME ))  # Calculate duration in seconds
  # Format duration as H:M:S
  local hours=$((duration / 3600))
  local mins=$(( (duration % 3600) / 60 ))
  local secs=$((duration % 60))
  local formatted_time=$(printf "%02d:%02d:%02d" $hours $mins $secs)
  # Print the summary if the user not exited
  if [[ $USER_EXITED -eq 0 ]]; then
    print_title_box "$SUMMARY_BOX_TITLE"
    echo ""
    check_internet
    local net_flag=$?
    echo "${GREEN}$SUMMARY_PERMISSIONS_MSG${RESET}"
    if [[ net_flag -eq 0 ]]; then
      echo "${GREEN}$SUMMARY_UPDATED_MSG${RESET}"
    else
      echo "${RED}$NO_INTERNET_UPDATE_MSG${RESET}"
    fi
    if [[ net_flag -eq 0 ]]; then
      echo "${GREEN}$SUMMARY_UPGRADED_MSG${RESET}"
    else
      echo "${RED}$NO_INTERNET_UPGRADE_MSG${RESET}"
    fi
    if [[ net_flag -eq 0 ]]; then
      echo "${GREEN}$SUMMARY_LINKS_MSG${RESET}"
    else
      echo "${RED}$NO_INTERNET_LINKS_MSG${RESET}"
    fi
    if [[ net_flag -eq 0 ]]; then
      echo "${GREEN}$SUMMARY_RELINKED_MSG${RESET}"
    else
      echo "${RED}$NO_INTERNET_RELINK_MSG${RESET}"
    fi
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
  fi
  # Print the footer with script details
  echo "$FOOTER_EXECUTION_TIME_MSG  $formatted_time"
  echo "$FOOTER_LOG_FILE_MSG"
  echo "$FOOTER_SCRIPT_VERSION_MSG"
  echo ""
  fancy_text_header "$AUTHOR_COPYRIGHT"
  echo ""
  sync
  exec 1>&- 2>&-
  if command -v open >/dev/null 2>&1; then
    open -a "Console" "${LOGFILE}" 2>/dev/null || echo "${YELLOW}$OPEN_LOG_FAIL_MSG${RESET}"
  fi
}

# This function relinks critical Homebrew tools like brew, curl, git, python3, ruby, and node
# It checks if each tool is installed, and if so, it relinks it
relink_brew_critical_tools() {
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

# Create log file and redirect output
exec > >(stdbuf -oL tee >(stdbuf -oL sed 's/\x1B\[[0-9;]*[JKmsu]//g' > "${LF}")) \
     2> >(stdbuf -oL tee >(stdbuf -oL sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "${LF}") >&2)

# Check if running in zsh console
if [[ -z "$ZSH_VERSION" ]]; then
  echo "${RED}$ZSH_REQUIRED_MSG${RESET}" >&2
  show_brew_report
  exit 0
fi

# Check if running in macOS
if [[ "$(uname)" != "Darwin" ]]; then
  echo "${RED}$UNSUPPORTED_OS_MSG${RESET}" >&2
  show_brew_report
  exit 0
fi

# Warn if running as root (not recommended)
if [[ "$EUID" -eq 0 ]]; then
  echo "${YELLOW}$ROOT_WARNING_MSG${RESET}"
  sleep 1
fi

# Ensure the script is run with sudo privileges
trap cleanup EXIT INT TERM

# Print script header
echo ""
print_title_box "$SCRIPT_BOX_TITLE"
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

# Print Homebrew Information
fancy_text_header "$SYSTEM_HEADER"
echo ""
echo "${GREEN}$SYSTEM_LABEL $(sw_vers -productName) $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
brew config
brew info
echo "${RESET}"

# Check for Homebrew and Xcode Command Line Tools
check_brew_dependencies

# Ask user for consent to continue (can exit here)
ask_user_consent

# Ensure sudo is available and keep it alive
sudo -v

# Keep sudo alive in the background to avoid password prompts
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Capture the initial free disk space
space_before=$(get_free_space)

# Step 1: Fix Homebrew Permissions
fancy_text_header "$PERMISSIONS_HEADER"
print_hints "$PERMISSIONS_INFO"
fix_brew_permissions
echo ""

# Step 2: Homebrew Doctor
fancy_text_header "$DOCTOR_HEADER"
print_hints "$DOCTOR_INFO"
brew doctor
echo "${GREEN}$DIAGNOSTIC_DONE_MSG${RESET}"
echo ""

# Step 3: Homebrew Update
fancy_text_header "$UPDATE_HEADER"
print_hints "$UPDATE_INFO"
check_internet
if [[ $? -eq 0 ]]; then
  brew update
  echo "${GREEN}$BREW_UPDATE_DONE_MSG${RESET}"
else
  echo "${RED}$NO_INTERNET_UPDATE_MSG${RESET}"
fi
echo ""

# Step 4: Upgrade Homebrew Formulae
fancy_text_header "$UPGRADE_FORMULAE_HEADER"
print_hints "$UPGRADE_FORMULAE_INFO"
check_internet
if [[ $? -eq 0 ]]; then
  brew upgrade
  echo "${GREEN}$BREW_FORMULAE_UPGRADE_DONE_MSG${RESET}"
else
  echo "${RED}$NO_INTERNET_UPGRADE_FORMULAE_MSG${RESET}"
fi
echo ""

# Step 5: Upgrade Homebrew Casks
fancy_text_header "$UPGRADE_CASKS_HEADER"
print_hints "$UPGRADE_CASKS_INFO"
check_internet
if [[ $? -eq 0 ]]; then
  brew upgrade --cask
  echo "${GREEN}$BREW_CASKS_UPGRADE_DONE_MSG${RESET}"
else
  echo "${RED}$NO_INTERNET_UPGRADE_CASKS_MSG${RESET}"
fi
echo ""

# Step 6: Fix Homebrew Broken Links
fancy_text_header "$FIX_LINKS_HEADER"
print_hints "$FIX_LINKS_INFO"
check_internet
if [[ $? -eq 0 ]]; then
  fix_brew_broken_links
else
  echo "${RED}$NO_INTERNET_LINKS_MSG${RESET}"
fi
echo ""

# Step 7: Relink Homebrew Critical Tools
fancy_text_header "$RELINK_TOOLS_HEADER"
print_hints "$RELINK_TOOLS_INFO"
check_internet
if [[ $? -eq 0 ]]; then
  relink_brew_critical_tools
else
  echo "${RED}$NO_INTERNET_RELINK_MSG${RESET}"
fi
echo ""

# Step 8: Homebrew Cleanup
fancy_text_header "$CLEANUP_HEADER"
print_hints "$CLEANUP_INFO"
brew cleanup
echo "${GREEN}$BREW_CLEANUP_DONE_MSG${RESET}"
echo ""

# Step 9: Final Homebrew Doctor
fancy_text_header "$FINAL_DOCTOR_HEADER"
print_hints "$FINAL_DOCTOR_INFO"
brew doctor || echo "${YELLOW}$SUMMARY_ISSUES_MSG${RESET}"
echo "${GREEN}$BREW_FINAL_CHECK_DONE_MSG${RESET}"
echo ""

echo "${GREEN}$MAINTENANCE_COMPLETE_MSG${RESET}"
echo ""

# Print the Homebrew summary at the end
show_brew_report

# Ensure all background jobs are killed on exit
trap 'kill $(jobs -p) 2>/dev/null' EXIT

exit 0