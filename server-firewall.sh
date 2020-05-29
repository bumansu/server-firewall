#!/bin/bash
# https://github.com/complexorganizations/server-firewall

# Require script to be run as root (or with sudo)
function super-user-check() {
  if [ "$EUID" -ne 0 ]; then
    echo "You need to run this script as super user."
    exit
  fi
}

# Check for root
super-user-check

# Pre-Checks
function check-system-requirements() {
  # System requirements (jq)
  if ! [ -x "$(command -v jq)" ]; then
    echo "Error: jq is not installed, please install jq." >&2
    exit
  fi
}

# Run the function and check for requirements
check-system-requirements

# Detect Operating System
function dist-check() {
  # shellcheck disable=SC1090
  if [ -e /etc/os-release ]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    DISTRO=$ID
    # shellcheck disable=SC2034
    DISTRO_VERSION=$VERSION_ID
  fi
}

# Check Operating System
dist-check

