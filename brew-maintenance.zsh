#!/bin/zsh

# ------------------------------------------------------------------------------
# Homebrew Maintenance Script
# Author: Prasit Chanda
# Description: This script checks, updates, upgrades, diagnoses, and cleans
#              Homebrew packages. It also tries to resolve common issues.
# System: macOS Sequoia
# Version: 1.0
# Last Updated: 2025-06-04
# Dependencies: Homebrew
# ------------------------------------------------------------------------------

clear

# Exit on error, unset vars, and pipe failures
set -euo pipefail
trap 'echo "\033[1;31m[ERROR]\033[0m An unexpected error occurred. Please review the output above." >&2; exit 1' ERR

# Define colors
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BLUE="\033[1;34m"
NC="\033[0m" # No Color

echo "${BLUE}Checking if Homebrew is installed...${NC}"
if ! command -v brew >/dev/null 2>&1; then
  echo "${RED}Homebrew is not installed. Please install it from https://brew.sh and rerun this script.${NC}"
  exit 1
fi
echo "${GREEN}Homebrew is installed.${NC}"

brew_prefix=$(brew --prefix)

fix_permissions() {
  echo "\n${BLUE}Fixing Homebrew directory ownership and permissions...${NC}"
  sudo chown -R "$(whoami):admin" "$brew_prefix"
  sudo chown -R "$(whoami):admin" "$brew_prefix"/{Cellar,Caskroom,Frameworks,bin,etc,include,lib,opt,sbin,share,var}
  sudo chmod -R g+w "$brew_prefix"/{Cellar,Caskroom,Frameworks,bin,etc,include,lib,opt,sbin,share,var}
  echo "${GREEN}Permissions adjusted.${NC}"
}

fix_broken_links() {
  echo "\n${BLUE}Checking for broken or unlinked Homebrew formulae...${NC}"
  for formula in $(brew list --formula); do
    if ! brew list --verbose "$formula" >/dev/null 2>&1; then
      echo "${YELLOW}Broken formula detected: $formula. Reinstalling...${NC}"
      brew reinstall "$formula" --quiet
    fi
  done

  echo "${BLUE}Ensuring all formulae are properly linked...${NC}"
  for formula in $(brew list --formula); do
    brew_output=$(brew list --verbose "$formula" 2>/dev/null || true)
    if ! echo "$brew_output" | grep -q "$brew_prefix"; then
      echo "${YELLOW}Linking formula: $formula${NC}"
      brew link --overwrite --force "$formula" --quiet
    fi
  done
}

relink_critical_tools() {
  echo "\n${BLUE}Relinking essential Homebrew tools...${NC}"
  tools=(brew curl git python3 ruby node)
  for tool in $tools; do
    if brew list --formula | grep -q "^$tool$"; then
      echo "${YELLOW}Relinking: $tool${NC}"
      brew unlink "$tool" >/dev/null 2>&1 || true
      brew link --overwrite "$tool" --quiet
    fi
  done
  echo "${GREEN}Critical tools relinking completed.${NC}"
}

install_xcode_cli() {
  echo "\n${BLUE}Checking for Xcode Command Line Tools...${NC}"
  if ! xcode-select -p >/dev/null 2>&1; then
    echo "${YELLOW}Xcode CLI tools not found. Starting installation...${NC}"
    xcode-select --install
    echo "${RED}Please complete installation and re-run this script.${NC}"
    exit 1
  fi
  echo "${GREEN}Xcode Command Line Tools are installed.${NC}"
}

# MAIN
install_xcode_cli
fix_permissions

echo "\n${BLUE}Running brew doctor...${NC}"
brew doctor || echo "${YELLOW}Some warnings detected. Attempting to continue...${NC}"

echo "\n${BLUE}Updating Homebrew...${NC}"
brew update

echo "\n${BLUE}Upgrading installed formulae...${NC}"
brew upgrade

echo "\n${BLUE}Upgrading installed casks...${NC}"
brew upgrade --cask

fix_broken_links
relink_critical_tools

before_cleanup=$(df -k / | tail -1 | awk '{ print $4 }')

echo "\n${BLUE}Cleaning up outdated downloads and files...${NC}"
brew cleanup

after_cleanup=$(df -k / | tail -1 | awk '{ print $4 }')
space_freed_kb=$((after_cleanup - before_cleanup))
space_freed_mb=$((space_freed_kb / 1024))

echo "\n${BLUE}Final brew doctor check...${NC}"
brew doctor || echo "${YELLOW}Some issues still present. Manual review may be needed.${NC}"

echo "\n${GREEN}Homebrew maintenance complete.${NC}"
if [ "$space_freed_kb" -gt 0 ]; then
  echo "${GREEN}Disk space freed: ${space_freed_mb} MB${NC}"
else
  echo "${YELLOW}No significant disk space was freed.${NC}"
fi
echo "Version 1.0.0-2025060423"
echo "Prasit Chanda © $(date +%Y)"