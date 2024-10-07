#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# Disable prompts for apt-get.
export DEBIAN_FRONTEND="noninteractive"

# System info.
PLATFORM="$(uname --hardware-platform || true)"
DISTRIB_CODENAME="$(lsb_release --codename --short || true)"
DISTRIB_ID="$(lsb_release --id --short | tr '[:upper:]' '[:lower:]' || true)"

# Secure generator comands
GENERATE_SECURE_SECRET_CMD="openssl rand --hex 16"
GENERATE_K256_PRIVATE_KEY_CMD="openssl ecparam --name secp256k1 --genkey --noout --outform DER | tail --bytes=+8 | head --bytes=32 | xxd --plain --cols 32"

# The Docker compose file.
COMPOSE_URL="https://raw.githubusercontent.com/bluesky-social/pds/main/compose.yaml"

# The pdsadmin script.
PDSADMIN_URL="https://raw.githubusercontent.com/bluesky-social/pds/main/pdsadmin.sh"

# System dependencies.
REQUIRED_SYSTEM_PACKAGES="
  ca-certificates
  curl
  gnupg
  jq
  lsb-release
  openssl
  sqlite3
  xxd
"
# Docker packages.
REQUIRED_DOCKER_PACKAGES="
  containerd.io
  docker-ce
  docker-ce-cli
  docker-compose-plugin
"

PUBLIC_IP=""
METADATA_URLS=()
METADATA_URLS+=("http://169.254.169.254/v1/interfaces/0/ipv4/address") # Vultr
METADATA_URLS+=("http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address") # DigitalOcean
METADATA_URLS+=("http://169.254.169.254/2021-03-23/meta-data/public-ipv4") # AWS
METADATA_URLS+=("http://169.254.169.254/hetzner/v1/metadata/public-ipv4") # Hetzner

PDS_DATADIR="${1:-/pds}"
PDS_HOSTNAME="${2:-}"
PDS_ADMIN_EMAIL="${3:-}"
PDS_DID_PLC_URL="https://plc.directory"
PDS_BSKY_APP_VIEW_URL="https://api.bsky.app"
PDS_BSKY_APP_VIEW_DID="did:web:api.bsky.app"
PDS_REPORT_SERVICE_URL="https://mod.bsky.app"
PDS_REPORT_SERVICE_DID="did:plc:ar7c4by46qjdydhdevvrndac"
PDS_CRAWLERS="https://bsky.network"

function usage {
  local error="${1}"
  cat <<USAGE >&2
ERROR: ${error}
Usage:
sudo bash $0

Please try again.
USAGE
  exit 1
}

function main {
  # Check that user is root.
  if [[ "${EUID}" -ne 0 ]]; then
    usage "This script must be run as root. (e.g. sudo $0)"
  fi

  # Check for a supported architecture.
  # If the platform is unknown (not uncommon) then we assume x86_64
  if [[ "${PLATFORM}" == "unknown" ]]; then
    PLATFORM="x86_64"
  fi
  if [[ "${PLATFORM}" != "x86_64" ]] && [[ "${PLATFORM}" != "aarch64" ]] && [[ "${PLATFORM}" != "arm64" ]]; then
    usage "Sorry, only x86_64 and aarch64/arm64 are supported. Exiting..."
  fi

  # Check for a supported distribution.
  SUPPORTED_OS="false"
  if [[ "${DISTRIB_ID}" == "ubuntu" ]]; then
    if [[ "${DISTRIB_CODENAME}" == "focal" ]]; then
      SUPPORTED_OS="true"
      echo "* Detected supported distribution Ubuntu 20.04 LTS"
    elif [[ "${DISTRIB_CODENAME}" == "jammy" ]]; then
      SUPPORTED_OS="true"
      echo "* Detected supported distribution Ubuntu 22.04 LTS"
    elif [[ "${DISTRIB_CODENAME}" == "mantic" ]]; then
      SUPPORTED_OS="true"
      echo "* Detected supported distribution Ubuntu 23.10 LTS"
    fi
  elif [[ "${DISTRIB_ID}" == "debian" ]]; then
    if [[ "${DISTRIB_CODENAME}" == "bullseye" ]]; then
      SUPPORTED_OS="true"
      echo "* Detected supported distribution Debian 11"
    elif [[ "${DISTRIB_CODENAME}" == "bookworm" ]]; then
      SUPPORTED_OS="true"
      echo "* Detected supported distribution Debian 12"
    fi
  fi

  if [[ "${SUPPORTED_OS}" != "true" ]]; then
    echo "Sorry, only Ubuntu 20.04, 22.04, Debian 11 and Debian 12 are supported by this installer. Exiting..."
    exit 1
  fi

  # Enforce that the data directory is /pds since we're assuming it for now.
  # Later we can make this actually configurable.
  if [[ "${PDS_DATADIR}" != "/pds" ]]; then
    usage "The data directory must be /pds. Exiting..."
  fi

  # Check if PDS is already installed.
  if [[ -e "${PDS_DATADIR}/pds.sqlite" ]]; then
    echo
    echo "ERROR: pds is already configured in ${PDS_DATADIR}"
    echo
    echo "To do a clean re-install:"
    echo "------------------------------------"
    echo "1. Stop the service"
    echo
    echo "  sudo systemctl stop pds"
    echo
    echo "2. Delete the data directory"
    echo
    echo "  sudo rm -rf ${PDS_DATADIR}"
    echo
    echo "3. Re-run this installation script"
      echo
    echo "  sudo bash ${0}"
    echo
    echo "For assistance, check https://github.com/bluesky-social/pds"
    exit 1
  fi

  #
  # Attempt to determine server's public IP.
  #

  # First try using the hostname command, which usually works.
  if [[ -z "${PUBLIC_IP}" ]]; then
    PUBLIC_IP=$(hostname --all-ip-addresses | awk '{ print $1 }')
  fi

  # Prevent any private IP address from being used, since it won't work.
  if [[ "${PUBLIC_IP}" =~ ^(127\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.|192\.168\.) ]]; then
    PUBLIC_IP=""
  fi

  # Check the various metadata URLs.
  if [[ -z "${PUBLIC_IP}" ]]; then
    for METADATA_URL in "${METADATA_URLS[@]}"; do
      METADATA_IP="$(timeout 2 curl --silent --show-error "${METADATA_URL}" | head --lines=1 || true)"
      if [[ "${METADATA_IP}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        PUBLIC_IP="${METADATA_IP}"
        break
      fi
    done
  fi

  if [[ -z "${PUBLIC_IP}" ]]; then
    PUBLIC_IP="Server's IP"
  fi

  #
  # Prompt user for required variables.
  #
  if [[ -z "${PDS_HOSTNAME}" ]]; then
    cat <<INSTALLER_MESSAGE
---------------------------------------
     Add DNS Record for Public IP
---------------------------------------

  From your DNS provider's control panel, create the required
  DNS record with the value of your server's public IP address.

  + Any DNS name that can be resolved on the public internet will work.
  + Replace example.com below with any valid domain name you control.
  + A TTL of 600 seconds (10 minutes) is recommended.

  Example DNS record:

    NAME                TYPE   VALUE
    ----                ----   -----
    example.com         A      ${PUBLIC_IP:-Server public IP}
    *.example.com       A      ${PUBLIC_IP:-Server public IP}

  **IMPORTANT**
  It's recommended to wait 3-5 minutes after creating a new DNS record
  before attempting to use it. This will allow time for the DNS record
  to be fully updated.

INSTALLER_MESSAGE

    if [[ -z "${PDS_HOSTNAME}" ]]; then
      read -p "Enter your public DNS address (e.g. example.com): " PDS_HOSTNAME
    fi
  fi

  if [[ -z "${PDS_HOSTNAME}" ]]; then
    usage "No public DNS address specified"
  fi

  if [[ "${PDS_HOSTNAME}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    usage "Invalid public DNS address (must not be an IP address)"
  fi

  # Admin email
  if [[ -z "${PDS_ADMIN_EMAIL}" ]]; then
    read -p "Enter an admin email address (e.g. you@example.com): " PDS_ADMIN_EMAIL
  fi
  if [[ -z "${PDS_ADMIN_EMAIL}" ]]; then
    usage "No admin email specified"
  fi

  if [[ -z "${PDS_ADMIN_EMAIL}" ]]; then
    read -p "Enter an admin email address (e.g. you@example.com): " PDS_ADMIN_EMAIL
  fi
  if [[ -z "${PDS_ADMIN_EMAIL}" ]]; then
    usage "No admin email specified"
  fi

  #
  # Install system packages.
  #
  if lsof -v >/dev/null 2>&1; then
    while true; do
      apt_process_count="$(lsof -n -t /var/cache/apt/archives/lock /var/lib/apt/lists/lock /var/lib/dpkg/lock | wc --lines || true)"
      if (( apt_process_count == 0 )); then
        break
      fi
      echo "* Waiting for other apt process to complete..."
      sleep 2
    done
  fi

  apt-get update
  apt-get install --yes ${REQUIRED_SYSTEM_PACKAGES}

  #
  # Install Docker
  #
  if ! docker version >/dev/null 2>&1; then
    echo "* Installing Docker"
    mkdir --parents /etc/apt/keyrings

    # Remove the existing file, if it exists,
    # so there's no prompt on a second run.
    rm --force /etc/apt/keyrings/docker.gpg
    curl --fail --silent --show-error --location "https://download.docker.com/linux/${DISTRIB_ID}/gpg" | \
      gpg --dearmor --output /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRIB_ID} ${DISTRIB_CODENAME} stable" >/etc/apt/sources.list.d/docker.list

    apt-get update
    apt-get install --yes ${REQUIRED_DOCKER_PACKAGES}
  fi

  #
  # Configure the Docker daemon so that logs don't fill up the disk.
  #
  if ! [[ -e /etc/docker/daemon.json ]]; then
    echo "* Configuring Docker daemon"
    cat <<'DOCKERD_CONFIG' >/etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "500m",
    "max-file": "4"
  }
}
DOCKERD_CONFIG
    systemctl restart docker
  else
    echo "* Docker daemon already configured! Ensure log rotation is enabled."
  fi

  #
  # Create data directory.
  #
  if ! [[ -d "${PDS_DATADIR}" ]]; then
    echo "* Creating data directory ${PDS_DATADIR}"
    mkdir --parents "${PDS_DATADIR}"
  fi
  chmod 700 "${PDS_DATADIR}"

  #
  # Configure Caddy
  #
  if ! [[ -d "${PDS_DATADIR}/caddy/data" ]]; then
    echo "* Creating Caddy data directory"
    mkdir --parents "${PDS_DATADIR}/caddy/data"
  fi
  if ! [[ -d "${PDS_DATADIR}/caddy/etc/caddy" ]]; then
    echo "* Creating Caddy config directory"
    mkdir --parents "${PDS_DATADIR}/caddy/etc/caddy"
  fi

  echo "* Creating Caddy config file"
  cat <<CADDYFILE >"${PDS_DATADIR}/caddy/etc/caddy/Caddyfile"
{
	email ${PDS_ADMIN_EMAIL}
	on_demand_tls {
		ask http://localhost:3000/tls-check
	}
}

*.${PDS_HOSTNAME}, ${PDS_HOSTNAME} {
	tls {
		on_demand
	}
	reverse_proxy http://localhost:3000
}
CADDYFILE

  #
  # Create the PDS env config
  #
  # Created here so that we can use it later in multiple places.
  PDS_ADMIN_PASSWORD=$(eval "${GENERATE_SECURE_SECRET_CMD}")
  cat <<PDS_CONFIG >"${PDS_DATADIR}/pds.env"
PDS_HOSTNAME=${PDS_HOSTNAME}
PDS_JWT_SECRET=$(eval "${GENERATE_SECURE_SECRET_CMD}")
PDS_ADMIN_PASSWORD=${PDS_ADMIN_PASSWORD}
PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=$(eval "${GENERATE_K256_PRIVATE_KEY_CMD}")
PDS_DATA_DIRECTORY=${PDS_DATADIR}
PDS_BLOBSTORE_DISK_LOCATION=${PDS_DATADIR}/blocks
PDS_BLOB_UPLOAD_LIMIT=52428800
PDS_DID_PLC_URL=${PDS_DID_PLC_URL}
PDS_BSKY_APP_VIEW_URL=${PDS_BSKY_APP_VIEW_URL}
PDS_BSKY_APP_VIEW_DID=${PDS_BSKY_APP_VIEW_DID}
PDS_REPORT_SERVICE_URL=${PDS_REPORT_SERVICE_URL}
PDS_REPORT_SERVICE_DID=${PDS_REPORT_SERVICE_DID}
PDS_CRAWLERS=${PDS_CRAWLERS}
LOG_ENABLED=true
PDS_CONFIG

  #
  # Download and install pds launcher.
  #
  echo "* Downloading PDS compose file"
  curl \
    --silent \
    --show-error \
    --fail \
    --output "${PDS_DATADIR}/compose.yaml" \
    "${COMPOSE_URL}"

  # Replace the /pds paths with the ${PDS_DATADIR} path.
  sed --in-place "s|/pds|${PDS_DATADIR}|g" "${PDS_DATADIR}/compose.yaml"

  #
  # Create the systemd service.
  #
  echo "* Starting the pds systemd service"
  cat <<SYSTEMD_UNIT_FILE >/etc/systemd/system/pds.service
[Unit]
Description=Bluesky PDS Service
Documentation=https://github.com/bluesky-social/pds
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${PDS_DATADIR}
ExecStart=/usr/bin/docker compose --file ${PDS_DATADIR}/compose.yaml up --detach
ExecStop=/usr/bin/docker compose --file ${PDS_DATADIR}/compose.yaml down

[Install]
WantedBy=default.target
SYSTEMD_UNIT_FILE

  systemctl daemon-reload
  systemctl enable pds
  systemctl restart pds

  # Enable firewall access if ufw is in use.
  if ufw status >/dev/null 2>&1; then
    if ! ufw status | grep --quiet '^80[/ ]'; then
      echo "* Enabling access on TCP port 80 using ufw"
      ufw allow 80/tcp >/dev/null
    fi
    if ! ufw status | grep --quiet '^443[/ ]'; then
      echo "* Enabling access on TCP port 443 using ufw"
      ufw allow 443/tcp >/dev/null
    fi
  fi

  #
  # Download and install pdadmin.
  #
  echo "* Downloading pdsadmin"
  curl \
    --silent \
    --show-error \
    --fail \
    --output "/usr/local/bin/pdsadmin" \
    "${PDSADMIN_URL}"
  chmod +x /usr/local/bin/pdsadmin

  cat <<INSTALLER_MESSAGE
========================================================================
PDS installation successful!
------------------------------------------------------------------------

Check service status      : sudo systemctl status pds
Watch service logs        : sudo docker logs -f pds
Backup service data       : ${PDS_DATADIR}
PDS Admin command         : pdsadmin

Required Firewall Ports
------------------------------------------------------------------------
Service                Direction  Port   Protocol  Source
-------                ---------  ----   --------  ----------------------
HTTP TLS verification  Inbound    80     TCP       Any
HTTP Control Panel     Inbound    443    TCP       Any

Required DNS entries
------------------------------------------------------------------------
Name                         Type       Value
-------                      ---------  ---------------
${PDS_HOSTNAME}              A          ${PUBLIC_IP}
*.${PDS_HOSTNAME}            A          ${PUBLIC_IP}

Detected public IP of this server: ${PUBLIC_IP}

To see pdsadmin commands, run "pdsadmin help"

========================================================================
INSTALLER_MESSAGE

  CREATE_ACCOUNT_PROMPT=""
  read -p "Create a PDS user account? (y/N): " CREATE_ACCOUNT_PROMPT

  if [[ "${CREATE_ACCOUNT_PROMPT}" =~ ^[Yy] ]]; then
    pdsadmin account create
  fi

}

# Run main function.
main
