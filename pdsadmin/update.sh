#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

PDS_DATADIR="/pds"
COMPOSE_FILE="${PDS_DATADIR}/compose.yaml"
DOCKER_COMPOSE_URL="https://raw.githubusercontent.com/bluesky-social/pds/main/docker_compose.yaml"
PODMAN_COMPOSE_URL="https://raw.githubusercontent.com/bluesky-social/pds/main/podman_compose.yaml"
CONTAINER_ENGINE="docker"

# TODO: allow the user to specify a version to update to.
TARGET_VERSION="${1:-}"

COMPOSE_TEMP_FILE="${COMPOSE_FILE}.tmp"

echo "* Downloading PDS compose file"
if [[ $(grep -w "ID_LIKE" /etc/os-release) =~ "fedora" ]] || [[ $(grep -w "ID" /etc/os-release) == "fedora" ]]; then
  curl \
    --silent \
    --show-error \
    --fail \
    --output "${COMPOSE_TEMP_FILE}" \
    "${PODMAN_COMPOSE_URL}"
elif [[ $(grep -w "ID_LIKE" /etc/os-release) =~ "debian" ]] || [[ $(grep -w "ID" /etc/os-release) == "debian" ]]; then
  curl \
    --silent \
    --show-error \
    --fail \
    --output "${COMPOSE_TEMP_FILE}" \
    "${DOCKER_COMPOSE_URL}"
fi

sed --in-place "s|/pds|${PDS_DATADIR}|g" "${PDS_DATADIR}/compose.yaml"

if cmp --quiet "${COMPOSE_FILE}" "${COMPOSE_TEMP_FILE}"; then
  echo "PDS is already up to date"
  rm --force "${COMPOSE_TEMP_FILE}"
  exit 0
fi

echo "* Updating PDS"
mv "${COMPOSE_TEMP_FILE}" "${COMPOSE_FILE}"

echo "* Restarting PDS"
systemctl restart pds.service

if [[ $(grep -w "ID_LIKE" /etc/os-release) =~ "fedora" ]] || [[ $(grep -w "ID" /etc/os-release) == "fedora" ]]; then
  CONTAINER_ENGINE="podman"
fi

cat <<MESSAGE
PDS has been updated
---------------------
Check systemd logs: journalctl --unit pds
Check container logs: ${CONTAINER_ENGINE} logs pds

MESSAGE
