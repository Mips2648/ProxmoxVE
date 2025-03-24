#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/Mips2648/ProxmoxVE/refs/heads/alpine-adguardhome-sync/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Mips
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bakito/adguardhome-sync

APP="Alpine-Adguardhome-Sync"
var_tags="Adguardhome;alpine"
var_cpu="1"
var_ram="256"
var_disk="0.2"
var_os="alpine"
var_version="3.21"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_adguardhomesync() {
    RELEASE=$1
    mkdir -p /opt/adguardhome-sync
    cd /opt/adguardhome-sync
    temp_file=$(mktemp)
    wget -q https://github.com/bakito/adguardhome-sync/releases/download/v${RELEASE}/adguardhome-sync_${RELEASE}_linux_amd64.tar.gz -O $temp_file
    tar -xzf ${temp_file} -C /opt/adguardhome-sync/ --overwrite
    echo "${RELEASE}" >"/opt/adguardhome-sync/version.txt"
    rm -f "$temp_file"
}

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    RELEASE=$(curl -s https://api.github.com/repos/bakito/adguardhome-sync/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ "${RELEASE}" != "$(cat /opt/adguardhome-sync/version.txt)" ]] || [[ ! -f /opt/adguardhome-sync/version.txt ]]; then
        # Stopping Services
        msg_info "Stopping Adguardhome-Sync"
        rc-service adguardhome-sync stop
        msg_ok "Stopped Adguardhome-Sync"

        # Execute Update
        msg_info "Updating Adguardhome-Sync to v${RELEASE}"
        update_adguardhomesync "$RELEASE"
        msg_ok "Updated Adguardhome-Sync to v${RELEASE}"

        # Starting Services
        msg_info "Starting Adguardhome-Sync"
        rc-service adguardhome-sync start
        msg_ok "Started Adguardhome-Sync"

        msg_ok "Update to v${RELEASE} Successful"
    else
        msg_ok "No update required. Adguardhome-Sync is already at v${RELEASE}"
    fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
