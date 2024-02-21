#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

PDS_DATADIR="/pds"
COMPOSE_FILE="${PDS_DATADIR}/compose.yaml"
COMPOSE_URL="https://raw.githubusercontent.com/bluesky-social/pds/main/compose.yaml"

# TODO: allow the user to specify a version to update to.
TARGET_VERSION="${1:-}"

COMPOSE_TEMP_FILE="${COMPOSE_FILE}.tmp"

echo "* Downloading PDS compose file"
curl \
  --silent \
  --show-error \
  --fail \
  --output "${COMPOSE_TEMP_FILE}" \
  "${COMPOSE_URL}"

if cmp --quiet "${COMPOSE_FILE}" "${COMPOSE_TEMP_FILE}"; then
  echo "PDS is already up to date"
  rm --force "${COMPOSE_TEMP_FILE}"
  exit 0
fi

echo "* Updating PDS"
mv "${COMPOSE_TEMP_FILE}" "${COMPOSE_FILE}"

echo "* Restarting PDS"
systemctl restart pds

cat <<MESSAGE
PDS has been updated
---------------------
Check systemd logs: journalctl --unit pds
Check container logs: docker logs pds

MESSAGE
