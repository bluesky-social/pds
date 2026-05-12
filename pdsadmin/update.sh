#!/usr/bin/env bash
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

sed --in-place "s|/pds|${PDS_DATADIR}|g" "${COMPOSE_TEMP_FILE}"

if ! cmp --quiet "${COMPOSE_FILE}" "${COMPOSE_TEMP_FILE}"; then
  echo "* Updating PDS compose file"
  mv "${COMPOSE_TEMP_FILE}" "${COMPOSE_FILE}"
else
  rm --force "${COMPOSE_TEMP_FILE}"
fi

echo "* Pulling latest PDS image"
docker compose --project-directory "${PDS_DATADIR}" pull

echo "* Restarting PDS"
systemctl restart pds

cat <<MESSAGE
PDS has been updated
---------------------
Check systemd logs: journalctl --unit pds
Check container logs: docker logs pds

MESSAGE
