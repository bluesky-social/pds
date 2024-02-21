#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

PDS_ENV_FILE="/pds/pds.env"
source "${PDS_ENV_FILE}"

RELAY_HOSTS="${1:-}"
if [[ "${RELAY_HOSTS}" == "" ]]; then
  RELAY_HOSTS="${PDS_CRAWLERS}"
fi

if [[ "${RELAY_HOSTS}" == "" ]]; then
  echo "ERROR: missing RELAY HOST parameter." >/dev/stderr
  echo "Usage: $0 <RELAY HOST>[,<RELAY HOST>,...]" >/dev/stderr
  exit 1
fi

for host in ${RELAY_HOSTS//,/ }; do
  echo "Requesting crawl from ${host}"
  curl \
    --fail \
    --silent \
    --show-error \
    --request POST \
    --user "admin:${PDS_ADMIN_PASSWORD}" \
    --header "Content-Type: application/json" \
    --data "{\"hostname\": \"${PDS_HOSTNAME}\"}" \
    https://${host}/xrpc/com.atproto.sync.requestCrawl >/dev/null
done

echo "done"
