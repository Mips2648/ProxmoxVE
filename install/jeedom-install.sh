#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Mips
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://jeedom.com/

# Import Functions und Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check

# update_os # don't call this one because it is a bad idea to remove /usr/lib/python3.*/EXTERNALLY-MANAGED in this context
msg_info "Upgrade OS"
$STD apt-get update
$STD apt-get -o Dpkg::Options::="--force-confold" -y dist-upgrade
msg_ok "OS upgraded"

# Installing Dependencies with the 3 core dependencies (curl;sudo;mc)
msg_info "Installing dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  lsb-release \
  grep
msg_ok "Dependencies installed"

# OS Check
msg_info "Checking OS version"
if ! lsb_release -d | grep -q "Debian GNU/Linux"; then
  msg_error "Wrong OS detected. Jeedom only supports Debian"
  exit 1
fi
msg_ok "OS check done"

# Setup App
msg_info "Downloading Jeedom installation script"
wget -q https://raw.githubusercontent.com/jeedom/core/master/install/install.sh
chmod +x install.sh
msg_ok "Installation script downloaded"

msg_info "Install Jeedom main dependencies"
$STD ./install.sh -s 2
msg_ok "Installed Jeedom main dependencies"

msg_info "Install Database"
$STD ./install.sh -s 3
msg_ok "Database installed"

msg_info "Install Apache"
$STD ./install.sh -s 4
msg_ok "Apache installed"

msg_info "Install PHP and dependencies"
$STD ./install.sh -s 5
msg_ok "PHP installed"

msg_info "Download Jeedom core"
$STD ./install.sh -s 6
msg_ok "Download done"

msg_info "Database customisation"
$STD ./install.sh -s 7
msg_ok "Database customisation done"

msg_info "Jeedom customisation"
$STD ./install.sh -s 8
msg_ok "Jeedom customisation done"

msg_info "Configuring Jeedom"
$STD ./install.sh -s 9
msg_ok "Jeedom configured"

msg_info "Installing Jeedom"
$STD ./install.sh -s 10
msg_ok "Jeedom installed"

msg_info "Post installation"
$STD ./install.sh -s 11
msg_ok "Post installation done"

msg_info "Check installation"
$STD ./install.sh -s 12
msg_ok "Installation checked, everything is successfuly installed. A reboot is recommended."

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
