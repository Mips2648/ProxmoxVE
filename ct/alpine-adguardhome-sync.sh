#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/Mips2648/ProxmoxVE/refs/heads/alpine-adguardhome-sync/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Mips
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bakito/adguardhome-sync

APP="Alpine-Adguardhome-Sync"
var_tags="Adguardhome-sync;alpine"
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

update_adguardhomesync() {
    clear
    RELEASE=$(curl -s https://api.github.com/repos/bakito/adguardhome-sync/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ "${RELEASE}" != "$(cat /opt/adguardhome-sync/version.txt)" ]] || [[ ! -f /opt/adguardhome-sync/version.txt ]]; then
        # Stopping Services
        rc-service adguardhome-sync stop

        # Execute Update
        $STD echo " * Updating Adguardhome-Sync to v${RELEASE}..."
        temp_file=$(mktemp)
        wget -q https://github.com/bakito/adguardhome-sync/releases/download/v${RELEASE}/adguardhome-sync_${RELEASE}_linux_amd64.tar.gz -O $temp_file
        tar -xzf ${temp_file} -C /opt/adguardhome-sync/ --overwrite
        echo "${RELEASE}" >"/opt/adguardhome-sync/version.txt"
        rm -f "$temp_file"
        msg_ok "Updated Adguardhome-Sync to v${RELEASE}"

        # Starting Services
        rc-service adguardhome-sync start

        msg_ok "Update to v${RELEASE} Successful"
    else
        msg_ok "No update required. Adguardhome-Sync is already at v${RELEASE}"
    fi
}

config_adguardhomesync() {
    DEFAULT_PORT=80
    clear
    while true; do
        ORIGIN_IP=$(whiptail --title "Origin Instance" --inputbox "Enter IP of the origin instance:" 10 60 3>&1 1>&2 2>&3)
        exit_status=$?
        if [ $exit_status -ne 0 ]; then
            echo "Operation canceled."
            exit 1
        fi
        if [[ $ORIGIN_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            break
        else
            whiptail --title "Invalid Input" --msgbox "Invalid IP address. Please try again." 10 60
        fi

    done
    while true; do
        ORIGIN_PORT=$(whiptail --title "Origin Instance" --inputbox "Enter port of the origin instance (Default: ${DEFAULT_PORT}):" 10 60 "${DEFAULT_PORT}" 3>&1 1>&2 2>&3)
        exit_status=$?
        if [ $exit_status -ne 0 ]; then
            echo "Operation canceled."
            exit 1
        fi
        if [[ $ORIGIN_PORT =~ ^[0-9]+$ ]] && [ "$ORIGIN_PORT" -ge 1 ] && [ "$ORIGIN_PORT" -le 65535 ]; then
            break
        else
            whiptail --title "Invalid Input" --msgbox "Invalid port. Please enter a number between 1 and 65535." 10 60
        fi

    done
    ORIGIN_USER=$(whiptail --title "Origin Instance" --inputbox "Enter username of the origin instance:" 10 60 3>&1 1>&2 2>&3)
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        echo "Operation canceled."
        exit 1
    fi
    ORIGIN_PASS=$(whiptail --title "Origin Instance" --passwordbox "Enter password of the origin instance:" 10 60 3>&1 1>&2 2>&3)
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        echo "Operation canceled."
        exit 1
    fi

    while true; do
        REPLICA_IP=$(whiptail --title "Replica Instance" --inputbox "Enter IP of the replica instance:" 10 60 3>&1 1>&2 2>&3)
        exit_status=$?
        if [ $exit_status -ne 0 ]; then
            echo "Operation canceled."
            exit 1
        fi
        if [[ $REPLICA_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            break
        else
            whiptail --title "Invalid Input" --msgbox "Invalid IP address. Please try again." 10 60
        fi
    done

    while true; do
        REPLICA_PORT=$(whiptail --title "Replica Instance" --inputbox "Enter port of the replica instance (Default: ${DEFAULT_PORT}):" 10 60 "${DEFAULT_PORT}" 3>&1 1>&2 2>&3)
        exit_status=$?
        if [ $exit_status -ne 0 ]; then
            echo "Operation canceled."
            exit 1
        fi
        if [[ $REPLICA_PORT =~ ^[0-9]+$ ]] && [ "$REPLICA_PORT" -ge 1 ] && [ "$REPLICA_PORT" -le 65535 ]; then
            break
        else
            whiptail --title "Invalid Input" --msgbox "Invalid port. Please enter a number between 1 and 65535." 10 60
        fi
    done

    REPLICA_USER=$(whiptail --title "Replica Instance" --inputbox "Enter username of the replica instance (default: ${ORIGIN_USER}):" 10 60 "${ORIGIN_USER}" 3>&1 1>&2 2>&3)
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        echo "Operation canceled."
        exit 1
    fi

    REPLICA_PASS=$(whiptail --title "Replica Instance" --passwordbox "Enter password of the replica instance (default: same as origin):" 10 60 "${ORIGIN_PASS}" 3>&1 1>&2 2>&3)
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        echo "Operation canceled."
        exit 1
    fi

    whiptail --title "Summary" --msgbox "Origin Instance:\nIP: ${ORIGIN_IP}\nPort: ${ORIGIN_PORT}\nUsername: ${ORIGIN_USER}\n\nReplica Instance:\nIP: ${REPLICA_IP}\nPort: ${REPLICA_PORT}\nUsername: ${REPLICA_USER}" 15 60

    whiptail --title "Confirmation" --yesno "Is this configuration correct?\nDo you want to continue?" 10 60
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        echo "Operation canceled by the user."
        exit 1
    fi

    cat <<EOF >/opt/adguardhome-sync/adguardhome-sync.yaml
# cron expression to run in daemon mode. (default; "" = runs only once)
cron: "*/5 * * * *"

# runs the synchronisation on startup
runOnStart: true

# If enabled, the synchronisation task will not fail on single errors, but will log the errors and continue
continueOnError: true

origin:
  # url of the origin instance
  url: http://${ORIGIN_IP}:${ORIGIN_PORT}
  # apiPath: define an api path if other than "/control"
  # insecureSkipVerify: true # disable tls check
  username: ${ORIGIN_USER}
  password: ${ORIGIN_PASS}
  # cookie: Origin-Cookie-Name=CCCOOOKKKIIIEEE

# replicas instances
replicas:
  # url of the replica instance
  - url: http://${REPLICA_IP}:${REPLICA_PORT}
    username: ${REPLICA_USER}
    password: ${REPLICA_PASS}

# Configure the sync API server, disabled if api port is 0
api:
  # Port, default 8080
  port: 80
  # if username and password are defined, basic auth is applied to the sync API
  # username: username
  # password: password
  # enable api dark mode
  darkMode: false

  # enable metrics on path '/metrics' (api port must be != 0)
  # metrics:
  # enabled: true
  # scrapeInterval: 30s
  # queryLogLimit: 10000

  # enable tls for the api server
  # tls:
  #   # the directory of the provided tls certs
  #   certDir: /path/to/certs
  #   # the name of the cert file (default: tls.crt)
  #   certName: foo.crt
  #   # the name of the key file (default: tls.key)
  #   keyName: bar.key

# Configure sync features; by default all features are enabled.
features:
  generalSettings: true
  queryLogConfig: true
  statsConfig: true
  clientSettings: true
  services: true
  filters: true
  dhcp:
    serverConfig: true
    staticLeases: true
  dns:
    serverConfig: true
    accessLists: true
    rewrites: true
EOF

    rc-service adguardhome-sync restart
    msg_ok "Configuration created. If you want to change it or if you made a mistake, edit /opt/adguardhome-sync/adguardhome-sync.yaml and restart service ('rc-service adguardhome-sync {start|stop|restart|status}')"
}

function update_script() {

    if [ ! -d /opt/adguardhome-sync ]; then
        msg_error "No ${APP} Installation Found!"
        exit 1
    fi

    while true; do
        CHOICE=$(
            whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --menu "Select option" 11 58 2 \
                "1" "Update Adguardhome-Sync" \
                "2" "Reset configuration" 3>&2 2>&1 1>&3
        )
        exit_status=$?
        if [ $exit_status == 1 ]; then
            clear
            exit-script
        fi
        case $CHOICE in
        1)
            update_adguardhomesync
            break
            ;;
        2)
            config_adguardhomesync
            break
            ;;
        esac
    done

    exit 0
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
