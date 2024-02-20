#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

PDS_ENV_FILE="/pds/pds.env"

if [[ -f "${PDS_ENV_FILE}" ]]; then
  source "${PDS_ENV_FILE}"
fi

curl --silent \
  --show-error \
  --request POST \
  --user "admin:${PDS_ADMIN_PASSWORD}" \
  --header "Content-Type: application/json" \
  --data '{"useCount": 1}' \
  https://${PDS_HOSTNAME}/xrpc/com.atproto.server.createInviteCode | jq --raw-output '.code'
