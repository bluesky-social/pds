#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# Backwards compatibility wrapper for the old create-invite-code command.
# Delegates to 'pdsadmin invite create'.

PDSADMIN_BASE_URL="https://raw.githubusercontent.com/bluesky-social/pds/main/pdsadmin"

SCRIPT_URL="${PDSADMIN_BASE_URL}/invite.sh"
SCRIPT_FILE="$(mktemp /tmp/pdsadmin.invite.XXXXXX)"

curl --fail --silent --show-error --location --output "${SCRIPT_FILE}" "${SCRIPT_URL}"
chmod +x "${SCRIPT_FILE}"

if "${SCRIPT_FILE}" create "$@"; then
  rm -f "${SCRIPT_FILE}"
fi
