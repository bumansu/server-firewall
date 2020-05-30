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
  # System requirements (sed)
  if ! [ -x "$(command -v sed)" ]; then
    echo "Error: sed is not installed, please install sed." >&2
    exit
  fi
  # System requirements (chmod)
  if ! [ -x "$(command -v chmod)" ]; then
    echo "Error: chmod is not installed, please install chmod." >&2
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
      apt-get install haveged fail2ban ufw -y
    fi
    if [ "$DISTRO" == "ubuntu" ]; then
      apt-get update
      apt-get install haveged fail2ban ufw -y
    fi
    if [ "$DISTRO" == "raspbian" ]; then
      apt-get update
      apt-get install haveged fail2ban ufw -y
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
    if ! [ -x "$(command -v ufw)" ]; then
      sed -i "s|# IPV6=yes;|IPV6=yes;|" /etc/default/ufw
      ufw enable
      ufw default deny incoming
      ufw default allow outgoing
    fi
}

# install the basic firewall
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
      sed -i 's|#PubkeyAuthentication yes|PubkeyAuthentication yes|' /etc/ssh/sshd_config
      sed -i 's|#ChallengeResponseAuthentication no|ChallengeResponseAuthentication yes|' /etc/ssh/sshd_config
    if pgrep systemd-journal; then
      systemctl enable sshd
      systemctl restart sshd
    else
      service ssh enable
      service ssh restart
    fi
    if ! [ -x "$(command -v ufw)" ]; then
      ufw allow 22/tcp
    fi
  fi
}

# Secure SSH
secure-ssh

function secure-nginx() {
  if [ ! -f "/etc/nginx/nginx.conf" ]; then
      sed -i "s|# server_tokens off;|server_tokens off;|" /etc/nginx/nginx.conf
    if pgrep systemd-journal; then
      systemctl restart nginx
    else
      service nginx restart
    fi
    if ! [ -x "$(command -v ufw)" ]; then
      ufw allow 80/tcp
      ufw allow 443/tcp
    fi
  fi
}

# Secure Nginx
secure-nginx

# Secure wireguard server
function secure-wireguard() {
  if [ ! -f "/etc/wireguard/wg0.conf" ]; then
    if ! [ -x "$(command -v ufw)" ]; then
      ufw allow 51820/udp
    fi
  fi
}

# Secure wireguard
secure-wireguard

function secure-apache() {
  if [ ! -f "/etc/apache2/apache2.conf" ]; then
    if ! [ -x "$(command -v ufw)" ]; then
      ufw allow 80/tcp
      ufw allow 443/tcp
    fi
  fi
}

# Secure Apache
secure-apache

function secure-dns() {
  lsof -i :53 >&2
  if [ $? -eq 1 ]; then
    if ! [ -x "$(command -v ufw)" ]; then
      ufw allow 53/tcp
      ufw allow 53/udp
    fi
  fi
}

# TODO: Check if the port 53 is being used and if it is, use UFW and open TCP and UDP.
secure-dns
