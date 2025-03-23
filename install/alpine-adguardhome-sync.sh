#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Mips
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.docker.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apk add newt
$STD apk add curl
$STD apk add openssh
# $STD apk add tzdata
$STD apk add nano
$STD apk add mc

$STD apk add go
msg_ok "Installed Dependencies"

get_latest_release() {
  curl -sL https://api.github.com/repos/bakito/adguardhome-sync/releases/latest | grep '"tag_name":' | cut -d'"' -f4
}
LATEST_VERSION=$(get_latest_release)

msg_info "Installing Adguardhome-Sync $LATEST_VERSION"
$STD go install github.com/bakito/adguardhome-sync@latest
msg_ok "Installed Adguardhome-Sync $LATEST_VERSION"

motd_ssh
customize
