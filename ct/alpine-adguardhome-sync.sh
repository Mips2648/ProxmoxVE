#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/Mips2648/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Mips
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bakito/adguardhome-sync

APP="Alpine-Adguardhome-Sync"
var_tags="Adguardhome;alpine"
var_cpu="1"
var_ram="256"
var_disk="0.5"
var_os="alpine"
var_version="3.21"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    if ! apk -e info newt >/dev/null 2>&1; then
        apk add -q newt
    fi
    while true; do
        CHOICE=$(
            whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --menu "Select option" 11 58 1 \
                "1" "Check for Adguardhome-Sync Updates" 3>&2 2>&1 1>&3
        )
        exit_status=$?
        if [ $exit_status == 1 ]; then
            clear
            exit-script
        fi
        header_info
        case $CHOICE in
        1)
            apk update && apk upgrade
            exit
            ;;
        esac
    done
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
