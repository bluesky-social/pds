#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

PDS_ENV_FILE="/pds/pds.env"
source "${PDS_ENV_FILE}"

DID="${1:-}"

if [[ "${DID}" == "" ]]; then
  echo "ERROR: missing DID parameter." >/dev/stderr
  echo "Usage: $0 <DID>" >/dev/stderr
  exit 1
fi

if [[ "${DID}" != did:* ]]; then
  echo "ERROR: DID parameter must start with \"did:\"." >/dev/stderr
  echo "Usage: $0 <DID>" >/dev/stderr
  exit 1
fi

PAYLOAD=$(cat <<EOF
{
  "subject": {
    "\$type": "com.atproto.admin.defs#repoRef",
    "did": "${DID}"
  },
  "takedown": {
    "applied": false
  }
}
EOF
)

curl \
  --fail \
  --silent \
  --show-error \
  --request POST \
  --user "admin:${PDS_ADMIN_PASSWORD}" \
  --header "Content-Type: application/json" \
  --data "${PAYLOAD}" \
  https://${PDS_HOSTNAME}/xrpc/com.atproto.admin.updateSubjectStatus >/dev/null

echo "${DID} untaken down"
