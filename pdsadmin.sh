#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

PDSADMIN_BASE_URL="https://raw.githubusercontent.com/bluesky-social/pds/main/pdsadmin"

# Command to run.
COMMAND="${1:-help}"
SCRIPT_FILE="/pds/${COMMAND}.sh"
shift || true

# Ensure the user is root, since it's required for most commands.
if [[ "${EUID}" -ne 0 ]]; then
  echo "ERROR: This script must be run as root"
  exit 1
fi

# Download the script, if it exists.
SCRIPT_URL="${PDSADMIN_BASE_URL}/${COMMAND}.sh"
UPDATE_FILE="$(mktemp /tmp/pdsadmin.${COMMAND}.XXXXXX)"

if ! curl --fail --silent --show-error --location --output "${UPDATE_FILE}" "${SCRIPT_URL}"; then
  echo "ERROR: ${COMMAND} not found"
  exit 2
fi
chmod +x "${UPDATE_FILE}"

# Install the command on first use, else if modified ask permission to update it
if [[ ! -f "${SCRIPT_FILE}" ]]; then
  mv --force "${UPDATE_FILE}" "${SCRIPT_FILE}"
elif ! cmp --quiet "${SCRIPT_FILE}" "${UPDATE_FILE}"; then
  read -p "Update command \"${COMMAND}\" [yes]? " choice
  case $choice in
    ""|[Yy]* ) # Default allow
      mv --force "${UPDATE_FILE}" "${SCRIPT_FILE}" 
    ;;
    * )
      rm --force "${UPDATE_FILE}"
    ;;
    esac
fi

"${SCRIPT_FILE}" "$@"
