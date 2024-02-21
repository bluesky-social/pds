#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

PDS_ENV_FILE="/pds/pds.env"
source "${PDS_ENV_FILE}"

curl_cmd() {
  curl --fail --silent --show-error "$@"
}

curl_cmd_post() {
  curl --fail --silent --show-error --request POST --header "Content-Type: application/json" "$@"
}

curl_cmd_post_nofail() {
  curl --silent --show-error --request POST --header "Content-Type: application/json" "$@"
}

SUBCOMMAND="${1:-}"

if [[ "${SUBCOMMAND}" == "list" ]]; then
  DIDS=$(curl_cmd \
    "https://${PDS_HOSTNAME}/xrpc/com.atproto.sync.listRepos?limit=100" | jq -r '.repos[].did'
  )
  OUTPUT='[{"handle":"Handle","email":"Email","did":"DID"}'
  for did in $DIDS; do
    ITEM=$(curl_cmd \
      --user "admin:${PDS_ADMIN_PASSWORD}" \
      "https://${PDS_HOSTNAME}/xrpc/com.atproto.admin.getAccountInfo?did=$did"
    )
    OUTPUT="${OUTPUT},${ITEM}"
  done
  OUTPUT="${OUTPUT}]"
  echo $OUTPUT | jq --raw-output '.[] | [.handle, .email, .did] | @tsv' | column -t
elif [[ "${SUBCOMMAND}" == "create" ]]; then
  EMAIL="${2:-}"
  HANDLE="${3:-}"

  if [[ "${EMAIL}" == "" || "${HANDLE}" == "" ]]; then
    echo "ERROR: missing EMAIL and/or HANDLE parameters." >/dev/stderr
    echo "Usage: $0 ${SUBCOMMAND} <EMAIL> <HANDLE>" >/dev/stderr
    exit 1
  fi

  PASSWORD=$(openssl rand -base64 30 | tr -d "=+/" | cut -c1-24)
  INVITE_CODE=$(curl_cmd_post \
    --user "admin:${PDS_ADMIN_PASSWORD}" \
    --data '{"useCount": 1}' \
    https://${PDS_HOSTNAME}/xrpc/com.atproto.server.createInviteCode | jq --raw-output '.code'
  )
  RESULT=$(curl_cmd_post_nofail \
    --data "{\"email\":\"${EMAIL}\", \"handle\":\"${HANDLE}\", \"password\":\"${PASSWORD}\", \"inviteCode\":\"${INVITE_CODE}\"}" \
    https://${PDS_HOSTNAME}/xrpc/com.atproto.server.createAccount
  )

  DID=$(echo $RESULT | jq --raw-output '.did')
  if [[ "${DID}" != did:* ]]; then
    ERR=$(echo $RESULT | jq --raw-output '.message')
    echo "ERROR: ${ERR}" >/dev/stderr
    echo "Usage: $0 ${SUBCOMMAND} <EMAIL> <HANDLE>" >/dev/stderr
    exit 1
  fi

  echo "Account created for ${HANDLE}.\nYour password is below, which we'll only show you once.\n"
  echo "DID:      ${DID}"
  echo "Password: ${PASSWORD}"
elif [[ "${SUBCOMMAND}" == "delete" ]]; then
  DID="${2:-}"

  if [[ "${DID}" == "" ]]; then
    echo "ERROR: missing DID parameter." >/dev/stderr
    echo "Usage: $0 ${SUBCOMMAND} <DID>" >/dev/stderr
    exit 1
  fi

  if [[ "${DID}" != did:* ]]; then
    echo "ERROR: DID parameter must start with \"did:\"." >/dev/stderr
    echo "Usage: $0 ${SUBCOMMAND} <DID>" >/dev/stderr
    exit 1
  fi

  echo "This action is permanent."
  read -r -p "Are you sure you'd like to delete ${DID}? [y/N] " response
  if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    exit 0
  fi

    curl_cmd_post \
    --user "admin:${PDS_ADMIN_PASSWORD}" \
    --data "{\"did\": \"${DID}\"}" \
    https://${PDS_HOSTNAME}/xrpc/com.atproto.admin.deleteAccount >/dev/null

  echo "${DID} deleted"
elif [[ "${SUBCOMMAND}" == "takedown" ]]; then
  DID="${2:-}"
  TAKEDOWN_REF="$(date +%s)"

  if [[ "${DID}" == "" ]]; then
    echo "ERROR: missing DID parameter." >/dev/stderr
    echo "Usage: $0 ${SUBCOMMAND} <DID>" >/dev/stderr
    exit 1
  fi

  if [[ "${DID}" != did:* ]]; then
    echo "ERROR: DID parameter must start with \"did:\"." >/dev/stderr
    echo "Usage: $0 ${SUBCOMMAND} <DID>" >/dev/stderr
    exit 1
  fi

  PAYLOAD=$(cat <<EOF
    {
      "subject": {
        "\$type": "com.atproto.admin.defs#repoRef",
        "did": "${DID}"
      },
      "takedown": {
        "applied": true,
        "ref": "${TAKEDOWN_REF}"
      }
    }
EOF
)

  curl_cmd_post \
  --user "admin:${PDS_ADMIN_PASSWORD}" \
  --data "${PAYLOAD}" \
  https://${PDS_HOSTNAME}/xrpc/com.atproto.admin.updateSubjectStatus >/dev/null

  echo "${DID} taken down"
elif [[ "${SUBCOMMAND}" == "untakedown" ]]; then
  DID="${2:-}"

  if [[ "${DID}" == "" ]]; then
    echo "ERROR: missing DID parameter." >/dev/stderr
    echo "Usage: $0 ${SUBCOMMAND} <DID>" >/dev/stderr
    exit 1
  fi

  if [[ "${DID}" != did:* ]]; then
    echo "ERROR: DID parameter must start with \"did:\"." >/dev/stderr
    echo "Usage: $0 ${SUBCOMMAND} <DID>" >/dev/stderr
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

  curl_cmd_post \
  --user "admin:${PDS_ADMIN_PASSWORD}" \
  --data "${PAYLOAD}" \
  https://${PDS_HOSTNAME}/xrpc/com.atproto.admin.updateSubjectStatus >/dev/null

  echo "${DID} untaken down"
else
  echo "Unknown subcommand "$0 ${SUBCOMMAND}"." >/dev/stderr
  exit 1
fi
