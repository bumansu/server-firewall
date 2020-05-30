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

# Install
function install-firewall() {
    if [ "$DISTRO" == "debian" ]; then
      apt-get update
      apt-get install haveged fail2ban -y
    fi
    if [ "$DISTRO" == "ubuntu" ]; then
      apt-get update
      apt-get install haveged fail2ban -y
    fi
    if [ "$DISTRO" == "raspbian" ]; then
      apt-get update
      apt-get install haveged fail2ban -y
    fi
    if [ "$DISTRO" == "arch" ]; then
      pacman -Syu
      pacman -Syu --noconfirm haveged fail2ban
    fi
    if [ "$DISTRO" == "fedora" ]; then
      dnf update -y
      dnf install haveged fail2ban -y
    fi
    if [ "$DISTRO" == "centos" ]; then
      yum update -y
      yum install haveged fail2ban -y
    fi
    if [ "$DISTRO" == "rhel" ]; then
      yum update -y
      yum install haveged fail2ban -y
    fi
    if pgrep systemd-journal; then
      systemctl enable fail2ban
      systemctl restart fail2ban
    else
      service fail2ban enable
      service fail2ban restart
    fi
}

install-firewall

function secure-ssh() {
    if [ ! -f "/root/.ssh/authorized_keys" ]; then
      chmod 600 /root/.ssh && chmod 700 /root/.ssh/authorized_keys
      sed -i 's|#PasswordAuthentication yes|PasswordAuthentication no|' /etc/ssh/sshd_config
      sed -i 's|#PermitEmptyPasswords no|PermitEmptyPasswords no|' /etc/ssh/sshd_config
      sed -i 's|AllowTcpForwarding yes|AllowTcpForwarding no|' /etc/ssh/sshd_config
      sed -i 's|X11Forwarding yes|X11Forwarding no|' /etc/ssh/sshd_config
      sed -i 's|#LogLevel INFO|LogLevel VERBOSE|' /etc/ssh/sshd_config
      sed -i 's|#Port 22|Port 22|' /etc/ssh/sshd_config
    fi
    if pgrep systemd-journal; then
      systemctl enable sshd
      systemctl restart sshd
    else
      service ssh enable
      service ssh restart
    fi
}
