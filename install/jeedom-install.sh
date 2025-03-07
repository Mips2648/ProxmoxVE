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
update_os

# Installing Dependencies with the 3 core dependencies (curl;sudo;mc)
msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc
msg_ok "Installed Dependencies"

# Setup App
msg_info "Downloading ${APPLICATION} installation"
wget -q https://raw.githubusercontent.com/jeedom/core/master/install/install.sh
chmod +x install.sh
msg_ok "Downloaded installation script"

msg_info "Upgrade OS"
$STD ./install.sh -s 1
msg_ok "Upgraded OS"

msg_info "Install Jeedom main dependencies"
$STD ./install.sh -s 2
msg_ok "Installed Jeedom main dependencies"

msg_info "Install Database"
$STD ./install.sh -s 3
msg_ok "Database installed"

msg_info "Install Apache"
$STD ./install.sh -s 4
msg_ok "Apache installed"

msg_info "Install PHP"
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

msg_info "Configure Jeedom"
$STD ./install.sh -s 9
msg_ok "Jeedom configured"

msg_info "Install Jeedom"
$STD ./install.sh -s 10
msg_ok "Jeedom installed"

msg_info "Post installation"
$STD ./install.sh -s 11
msg_ok "Post installation done"

msg_info "Check installation"
$STD ./install.sh -s 12
msg_ok "Installation checked, everything seems successfuly installed"

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
