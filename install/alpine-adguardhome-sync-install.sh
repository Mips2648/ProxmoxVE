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

install_adguardhomesync() {
  mkdir -p /opt/adguardhome-sync
  cd /opt/adguardhome-sync
  temp_file=$(mktemp)
  wget -q https://github.com/bakito/adguardhome-sync/releases/download/v${LATEST_VERSION}/adguardhome-sync_${LATEST_VERSION}_linux_amd64.tar.gz -O $temp_file
  tar -xzf ${temp_file} -C /opt/adguardhome-sync/ --overwrite
  echo "${LATEST_VERSION}" >"/opt/adguardhome-sync/version.txt"
  rm -f $temp_file
}

config_adguardhomesync() {
  DEFAULT_PORT=80
  echo
  while true; do
    read -r -p "Enter IP of the origin instance: " ORIGIN_IP
    if [[ $ORIGIN_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && ping -c 1 -W 1 "$ORIGIN_IP" >/dev/null 2>&1; then
      break
    else
      echo "Invalid IP address. Please try again."
    fi
  done

  while true; do
    read -r -p "Enter port of the origin instance (Default: ${DEFAULT_PORT}): " ORIGIN_PORT
    ORIGIN_PORT=${ORIGIN_PORT:-$DEFAULT_PORT}
    if [[ $ORIGIN_PORT =~ ^[0-9]+$ ]] && [ "$ORIGIN_PORT" -ge 1 ] && [ "$ORIGIN_PORT" -le 65535 ]; then
      break
    else
      echo "Invalid port. Please enter a number between 1 and 65535."
    fi
  done

  while true; do
    read -r -p "Enter username of the origin instance: " ORIGIN_USER
    if [[ -n "$ORIGIN_USER" && "$ORIGIN_USER" != *" "* ]]; then
      break
    else
      echo "Invalid username. It must not be empty or contain spaces. Please try again."
    fi
  done

  while true; do
    read -s -r -p "Enter password of the origin instance: " ORIGIN_PASS
    echo
    if [[ -n "$ORIGIN_PASS" && "$ORIGIN_PASS" != *" "* ]]; then
      break
    else
      echo "Invalid password. It must not be empty or contain spaces. Please try again."
    fi
  done

  while true; do
    read -r -p "Enter IP of the replica instance: " REPLICA_IP
    if [[ $REPLICA_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && ping -c 1 -W 1 "$REPLICA_IP" >/dev/null 2>&1; then
      break
    else
      echo "Invalid IP address. Please enter a valid and reachable IP."
    fi
  done

  while true; do
    read -r -p "Enter port of the replica instance (Default: ${DEFAULT_PORT}): " REPLICA_PORT
    REPLICA_PORT=${REPLICA_PORT:-$DEFAULT_PORT}
    if [[ $REPLICA_PORT =~ ^[0-9]+$ ]] && [ "$REPLICA_PORT" -ge 1 ] && [ "$REPLICA_PORT" -le 65535 ]; then
      break
    else
      echo "Invalid port. Please enter a number between 1 and 65535."
    fi
  done

  while true; do
    read -r -p "Enter username of the replica instance (default: ${ORIGIN_USER}): " REPLICA_USER
    REPLICA_USER=${REPLICA_USER:-$ORIGIN_USER}
    if [[ -n "$REPLICA_USER" && "$REPLICA_USER" != *" "* ]]; then
      break
    else
      echo "Invalid username. It must not be empty or contain spaces. Please try again."
    fi
  done

  while true; do
    read -s -r -p "Enter password of the replica instance (default: same as origin): " REPLICA_PASS
    echo
    REPLICA_PASS=${REPLICA_PASS:-$ORIGIN_PASS}
    if [[ -n "$REPLICA_PASS" && "$REPLICA_PASS" != *" "* ]]; then
      break
    else
      echo "Invalid password. It must not be empty or contain spaces. Please try again."
    fi
  done

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
}

setup_service() {
  cat <<EOF >/etc/init.d/adguardhome-sync
#!/sbin/openrc-run
name="adguardhome-sync"
description="adguardhome-sync"
command="/opt/adguardhome-sync/adguardhome-sync"
command_background=true
pidfile="/run/adguardhome-sync.pid"
command_args="--config /opt/adguardhome-sync/adguardhome-sync.yaml run"
EOF
  chmod +x /etc/init.d/adguardhome-sync
  rc-update add adguardhome-sync default
  rc-service adguardhome-sync start
}

msg_info "Installing Adguardhome-Sync ${LATEST_VERSION}"
install_adguardhomesync
msg_ok "Installed Adguardhome-Sync ${LATEST_VERSION}"

msg_info "Creating Configuration"
config_adguardhomesync
msg_ok "Configuration created. If you want to change it or if you made a mistake, edit /opt/adguardhome-sync/adguardhome-sync.yaml and restart service"

msg_info "Creating Service"
setup_service
msg_ok "Service created. To control it use 'rc-service adguardhome-sync {start|stop|restart|status}'"

motd_ssh
customize

msg_info "Cleaning up"
$STD apk cache clean
msg_ok "Cleaned"
