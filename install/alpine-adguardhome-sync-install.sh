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
msg_ok "Installed Dependencies"

get_latest_release() {
  curl -s https://api.github.com/repos/bakito/adguardhome-sync/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }'
}
LATEST_VERSION=$(get_latest_release)

msg_info "Installing Adguardhome-Sync ${LATEST_VERSION}"
mkdir -p /opt/adguardhome-sync
cd /opt/adguardhome-sync
wget -q https://github.com/bakito/adguardhome-sync/releases/download/v${LATEST_VERSION}/adguardhome-sync_${LATEST_VERSION}_linux_amd64.tar.gz
tar -xzf adguardhome-sync_${LATEST_VERSION}_linux_amd64.tar.gz -C /opt/adguardhome-sync/ --overwrite
echo "${LATEST_VERSION}" >"/opt/adguardhome-sync_version.txt"
msg_ok "Installed Adguardhome-Sync ${LATEST_VERSION}"

msg_info "Creating Configuration"
DEFAULT_PORT=3000

read -r -p "Enter IP of the origin instance: " ORIGN_IP
read -r -p "Enter port of the origin instance (Default: ${DEFAULT_PORT}): " ORIGIN_PORT
read -r -p "Enter username of the origin instance: " ORIGIN_USER
read -r -p "Enter password of the origin instance: " ORIGIN_PASS

read -r -p "Enter IP of the replica instance: " REPLICA_IP
read -r -p "Enter port of the replica instance (Default: ${DEFAULT_PORT}): " REPLICA_PORT
read -r -p "Enter username of the replica instance: " REPLICA_USER
read -r -p "Enter password of the replica instance: " REPLICA_PASS

cat <<EOF >/opt/adguardhome-sync/adguardhome-sync.yaml
# cron expression to run in daemon mode. (default; "" = runs only once)
cron: "*/5 * * * *"

# runs the synchronisation on startup
runOnStart: true

# If enabled, the synchronisation task will not fail on single errors, but will log the errors and continue
continueOnError: true

origin:
  # url of the origin instance
  url: https://${ORIGN_IP}:${ORIGIN_PORT}
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
  port: 8080
  # if username and password are defined, basic auth is applied to the sync API
  # username: username
  # password: password
  # enable api dark mode
  darkMode: true

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
msg_ok "Default configuration created. If you want to change it, edit /opt/adguardhome-sync/adguardhome-sync.yaml"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/adguardhome-sync.service
[Unit]
Description=adguardhome-sync Service
After=network.target

[Service]
ExecStart = /opt/adguardhome-sync/adguardhome-sync --config /opt/adguardhome-sync/adguardhome-sync.yaml run
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now adguardhome-sync.service
msg_ok "Created Service"

motd_ssh
customize
