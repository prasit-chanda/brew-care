#!/bin/zsh

# Stricter error handling: exit on error, unset variable, or failed pipeline
# set -euo pipefail

# Optimize globbing and file matching for safety and flexibility
setopt nullglob extended_glob localoptions no_nomatch

# ------------------------------------------------------------------------------
# Homebrew Maintenance Script for macOS
# Author: Prasit Chanda 
# Version: 1.6.3-20250702-RM5B1
# Automates Homebrew health: fixes permissions, updates, upgrades, relinks, cleans, and logs
# Requires: Homebrew, Xcode CLT, zsh, sudo. Run in Terminal
# ------------------------------------------------------------------------------

# ───── Static Colors Variables ─────
# Use standard, high-contrast ANSI codes for best visibility on both dark and light backgrounds

BLUE=$'\e[94m'     # Bright Blue - Info/Action
CYAN=$'\e[96m'     # Bright Cyan - General Info
GREEN=$'\e[92m'    # Bright Green - Success
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
# TS=$(print -n (date +"%s") | openssl dgst -shake128 -xoflen 16 | awk '{print $2}')
TS=$(date +"%s")
# Log file name (without path)
LF="brew-care-${TS}.log"
# Working directory (where script is run)
WD=$PWD
# Full path to log file
LOGFILE="${WD}/${LF}"
# Script version string
VER="1.6.3-20250702-RM5B1"
# Script start time (epoch seconds)
START_TIME=$(date +%s)  # Capture start time
# Flag to check if user exited script (0 = running, 1 = user exited)
USER_EXITED=0  # Flag to check if user exited script

# ───── Static Text Variables ─────
# These variables contain static text used in the script for messages, headers, and prompts

AUTHOR_COPYRIGHT=" ${AUTHOR} © $(date +%Y) "
BREW_CASKS_UPGRADE_DONE_MSG="Casks upgraded. Go sip your coffee"
BREW_CLEANUP_DONE_MSG="Cleanup done. Took out the digital trash"
BREW_FINAL_CHECK_DONE_MSG="Final check complete. You're welcome"
BREW_FORMULAE_UPGRADE_DONE_MSG="Formulae upgraded. The nerd juice is fresh"
BREW_UPDATE_DONE_MSG="Homebrew updated. Try not to mess it up again"
BROKEN_FORMULAE_FOUND_MSG="Oh look, something’s broken: "
BROKEN_FORMULAE_MSG="Hunting for sad, broken formulae"
BROKEN_FORMULAE_REINSTALL_MSG="Reinstalling the fragile stuff"
BROKEN_LINKED_MSG="Broken links fixed. Duct tape applied!"
CLEANUP_HEADER="Cleanup"
CLEANUP_INFO="Removing dusty old packages. You're hoarding again"
DEPENDENCIES_BREW_ALREADY_INSTALLED="Homebrew is already here. Shocking, I know!"
DEPENDENCIES_BREW_FAIL="✖ No Homebrew. No fun. Bye."
DEPENDENCIES_BREW_INSTALL_ATTEMPT="Installing Homebrew, unless it throws a tantrum"
DEPENDENCIES_BREW_INSTALL_FAIL="✖ Homebrew install failed. It's probably your fault!"
DEPENDENCIES_BREW_INSTALL_SUCCESS="Homebrew installed. Finally something works!"
DEPENDENCIES_BREW_NOT_INSTALL="✖ Homebrew is missing. Like your priorities"
DEPENDENCIES_FAIL_MSG="✖ Dependencies failed harder than expected"
DEPENDENCIES_HEADER="Dependencies"
DEPENDENCIES_OK_MSG="All good. Miraculously!"
DEPENDENCIES_START_MSG="Starting because someone has to clean up your Homebrew mess"
DEPENDENCIES_SUDO_MSG="Might ask for your password. Don't panic!"
DEPENDENCIES_TERMINAL_MSG="Pro tip: Run this in macOS native Terminal, not Notepad!"
DEPENDENCIES_TERMINATE_MSG="✖ Missing stuff. Script might explode"
DEPENDENCIES_XCODE_INSTALL_ATTEMPT="Trying to install Xcode tools, wish me luck"
DEPENDENCIES_XCODE_INSTALL_PROMPT="Need Xcode CLI Tools. Install now? (y/n) "
DEPENDENCIES_XCODE_INSTALL_SUCCESS="Xcode tools installed. Miracles do happen"
DEPENDENCIES_XCODE_NOT_INSTALL="✖ Xcode CLI tools not found. Sad"
DIAGNOSTIC_DONE_MSG="All clear. No visible disasters"
DOCTOR_HEADER="Doctor"
DOCTOR_INFO="Running checks. Hold your breath"
FINAL_DOCTOR_HEADER="Final Check"
FINAL_DOCTOR_INFO="Final inspection. Nothing to see here, hopefully"
FIX_BREW_PERMISSION_MSG="Fixing Brew permissions. Stop breaking stuff"
FIX_LINKS_HEADER="Broken Links"
FIX_LINKS_INFO="Checking links. Finding disappointment"
FOOTER_EXECUTION_TIME_MSG="Runtime"
FOOTER_LOG_DIR_MSG="Folder   $WD"
FOOTER_LOG_FILE_MSG="Log      $LF"
FOOTER_SCRIPT_VERSION_MSG="Tag      $VER"
INTERNET_FAIL_MSG="✖ No internet. What is this, 1998?"
INTERNET_OK_MSG="✓ Internet’s alive. Miraculously"
LINKING_FORMULAE_MSG="Linking all formulae. Herding cats"
LINKING_FORMULA_MSG="Linking: "
MAINTENANCE_COMPLETE_MSG="Maintenance done. Your system is now slightly less embarrassing"
NO_INTERNET_LINKS_MSG="✖ Can’t fix links. No internet. No hope"
NO_INTERNET_RELINK_MSG="✖ Relinking failed. Still offline, genius"
NO_INTERNET_UPDATE_MSG="✖ No internet. No updates. No surprise"
NO_INTERNET_UPGRADE_CASKS_MSG="✖ Casks not upgraded. Blame your Wi‑Fi"
NO_INTERNET_UPGRADE_FORMULAE_MSG="✖ Formulae upgrade skipped. Internet took a nap"
NO_INTERNET_UPGRADE_MSG="✖ Upgrade skipped. Offline like a cave troll"
OPEN_LOG_FAIL_MSG="✖ Log won’t open. Probably shy"
PERMISSIONS_ADJUSTED_MSG="Permissions fixed. Stop using sudo for everything"
PERMISSIONS_HEADER="Permissions"
PERMISSIONS_INFO="Checking who broke the access rights this time"
PROMPT_USER_CONSENT_APPROVAL="✓ $(whoami) said yes. Brave choice"
PROMPT_USER_CONSENT_DENIAL="✖ $(whoami) chickened out. Script denied"
PROMPT_USER_CONSENT_MSG="Do you even want to run this? (y/n) "
PROMPT_USER_INSTALL_HOME_BREW="Install Homebrew now? (y/n) "
PROMPT_VALIDATE_MSG="Please just type 'y' or 'n'. It's not that hard!"
RELINK_TOOLS_HEADER="Relinking"
RELINK_TOOLS_INFO="Making sure your tools aren’t lost again"
RELINK_TOOLS_MSG="Relinking essential nonsense"
RELINKED_MSG="Tools relinked. Shocking success!"
RELINKING_MSG="Relinking: "
ROOT_WARNING_MSG="Oh, running this as root? Bold choice\nLiving dangerously, are we? \nThat's a hard no—exiting now before something explodes"
SCRIPT_BOX_TITLE="brew-maintenance.zsh"
SCRIPT_DESCRIPTION="This script updates, fixes, and babysits your Homebrew setup"
SCRIPT_EXIT_MSG=" ● Press ⌃ + C to rage quit"
SCRIPT_INTERNET_MSG=" ● Requires internet—magic doesn't work offline!"
SCRIPT_START_MSG="Kicking off brew-maintenance.zsh, ready or not?"
SCRIPT_SUDO_FAIL_MSG="✖ No sudo, no glory. Exiting script before things get messy"
SCRIPT_SUDO_MSG=" ● Might ask for password. It’s not a trap"
SCRIPT_TERMINAL_MSG=" ● Please run this in macOS native Terminal, not Stickies"
SUMMARY_BOX_TITLE="Recap"
SUMMARY_CLEANUP_MSG="✓ Cleaned up some digital junk. You’re welcome"
SUMMARY_DISK_FREED_MSG="✓ Freed up some bytes. Don’t spend it all at once"
SUMMARY_DISK_UNCHANGED_MSG="● No disk space saved. Better luck next run!"
SUMMARY_ISSUES_MSG="Still got problems. DIY time"
SUMMARY_LINKS_MSG="✓ Fixed your mess of links"
SUMMARY_NO_DISK_CHANGE_MSG="● Zero space freed. Digital clutter wins again"
SUMMARY_PERMISSIONS_MSG="✓ Permissions sorted. Try not to ruin it"
SUMMARY_RELINKED_MSG="✓ Relinked tools. Brew’s not confused anymore"
SUMMARY_UPDATED_MSG="✓ Packages updated. Feeling modern?"
SUMMARY_UPGRADED_MSG="✓ Formulae & casks upgraded. Fancy stuff"
SYSTEM_HEADER="Homebrew"
SYSTEM_LABEL="System "
UNSUPPORTED_OS_MSG="✖ Not macOS. Not happening"
UPDATE_HEADER="Update"
UPDATE_INFO="Checking for updates. Brace for disappointment"
UPGRADE_CASKS_HEADER="Upgrade Casks"
UPGRADE_CASKS_INFO="Looking for cask upgrades. Or reasons to crash"
UPGRADE_FORMULAE_HEADER="Upgrade Formulae"
UPGRADE_FORMULAE_INFO="Looking for newer, shinier formulae"
XCODE_INSTALL_FAIL_MSG="Xcode CLI install failed. Blame Apple?"
XCODE_REQUIRED_MSG="Need Xcode CLI tools. No tools, no party!"
ZSH_REQUIRED_MSG="✖ This script needs zsh. Bash isn't cool anymore"

# ───── Custom Functions ─────

# This function asks the user for consent to continue
# Exits if user denies consent
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
        USER_EXITED=1
        show_brew_report
        exit 1
        ;;
      *)
        echo "${YELLOW}$PROMPT_VALIDATE_MSG${RESET}"
        ;;
    esac
  done
}

# Checks for Homebrew and Xcode CLT, prompts to install if missing
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
          USER_EXITED=1
          show_brew_report
          exit 1
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
    while true; do
      print -nP "$DEPENDENCIES_XCODE_INSTALL_PROMPT"
      read install_xcode
      echo ""
      case "$install_xcode" in
        [yY][eE][sS]|[yY])
          echo "${YELLOW}$DEPENDENCIES_XCODE_INSTALL_ATTEMPT${RESET}"
          xcode-select --install >/dev/null 2>&1
          # Wait for installation to complete
          until xcode-select -p >/dev/null 2>&1; do
            sleep 2
          done
          if xcode-select -p >/dev/null 2>&1; then
            echo "${GREEN}$DEPENDENCIES_XCODE_INSTALL_SUCCESS${RESET}"
          else
            echo "${RED}$XCODE_INSTALL_FAIL_MSG${RESET}"
            dependencies_status=1
          fi
          break
          ;;
        [nN][oO]|[nN])
          echo "${RED}$XCODE_REQUIRED_MSG${RESET}"
          dependencies_status=1
          USER_EXITED=1
          show_brew_report
          exit 1
          ;;
        *)
          echo "${YELLOW}$PROMPT_VALIDATE_MSG${RESET}"
          ;;
      esac
    done
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

# Cleanup function: kills background jobs and syncs log file
cleanup() {
  trap - EXIT
  kill $(jobs -p) 2>/dev/null
  sync
}

# Checks if DNS server is reachable
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

# Prints a divider line
fancy_line_divider() {
  local width=${1:-50}
  local char="${2:-━}"
  local line=""
  while [[ ${(L)#line} -lt $width ]]; do
    line+="$char"
  done
  print -r -- "$line"
}

# Prints a centered header
fancy_text_header() {
  local label="$1"
  local total_width=25
  local padding_width=$(( (total_width - ${#label} - 2) / 2 ))
  printf '%*s' "$padding_width" '' | tr ' ' '='
  printf " %s " "$label"
  printf '%*s\n' "$padding_width" '' | tr ' ' '='
}

# Checks for broken/unlinked formulae and attempts to fix them
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

# Fixes Homebrew directory permissions
fix_brew_permissions() {
  echo "${BLUE}$FIX_BREW_PERMISSION_MSG${RESET}"
  sudo chown -R "$(whoami):admin" "$BREW_PREFIX"
  sudo chown -R "$(whoami):admin" "$BREW_PREFIX"/{Cellar,Caskroom,Frameworks,bin,etc,include,lib,opt,sbin,share,var}
  sudo chmod -R g+w "$BREW_PREFIX"/{Cellar,Caskroom,Frameworks,bin,etc,include,lib,opt,sbin,share,var}
  echo "${GREEN}$PERMISSIONS_ADJUSTED_MSG${RESET}"
}

# Generates a random string in XXXXX-XXXXX-XXXXX-XXXXX-XXXXX format
generate_random_string() {
  local chars=( {A..Z} {0..9})
  local num_chars=${#chars[@]}
  if (( num_chars == 0 )); then
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

# Returns free space in bytes
get_free_space() {
  df -k / | tail -1 | awk '{print $4 * 1024}'
}

# Converts bytes to human-readable format
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

# Prints step hints
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

# Prints a box around content
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

# Prints summary and opens log if available
show_brew_report() {
  local end_time=$(date +%s)
  local duration=$(( end_time - START_TIME ))
  local hours=$((duration / 3600))
  local mins=$(( (duration % 3600) / 60 ))
  local secs=$((duration % 60))
  local formatted_time=$(printf "%02d:%02d:%02d" $hours $mins $secs)
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
  echo "$FOOTER_EXECUTION_TIME_MSG  $formatted_time"
  echo "$FOOTER_LOG_DIR_MSG"
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

# Relinks critical Homebrew tools
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

# ───── Check Runtime Environment ─────

# Check if running in zsh console
if [[ -z "$ZSH_VERSION" ]]; then
  echo ""
  echo "${RED}$ZSH_REQUIRED_MSG${RESET}" >&2
  echo ""
  exit 1
fi

# Check if running in macOS
if [[ "$(uname)" != "Darwin" ]]; then
  echo ""
  echo "${RED}$UNSUPPORTED_OS_MSG${RESET}" >&2
  echo ""
  exit 1
fi

# Warn if running as root (not recommended)
if [[ "$EUID" -eq 0 ]]; then
  echo ""
  echo "${RED}$ROOT_WARNING_MSG${RESET}"  >&2
  echo ""
  exit 1
fi

# ───── Script Starts ─────

clear

# Capture the initial free disk space
space_before=$(get_free_space)

# Create log file and redirect output
exec > >(stdbuf -oL tee >(stdbuf -oL sed 's/\x1B\[[0-9;]*[JKmsu]//g' > "${LF}")) \
     2> >(stdbuf -oL tee >(stdbuf -oL sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "${LF}") >&2)

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

# Prompt for sudo and handle interruption
sudo -v
if ! sudo -v; then
  echo "${RED}$SCRIPT_SUDO_FAIL_MSG${RESET}"
  echo ""
  USER_EXITED=1
  show_brew_report
  exit 1
else
  # Keep sudo alive in the background to avoid password prompts
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

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