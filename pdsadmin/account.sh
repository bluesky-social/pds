#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

PDS_ENV_FILE="pds.env"
# PDS_ENV_FILE="/pds/pds.env"
source "${PDS_ENV_FILE}"

SUBCOMMAND="${1:-}"

if [[ "${SUBCOMMAND}" == "list" ]]; then
  echo "TODO"
elif [[ "${SUBCOMMAND}" == "create" ]]; then
  echo "TODO"
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
  if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
  then
      exit 0
  fi

  curl \
    --fail \
    --silent \
    --show-error \
    --request POST \
    --user "admin:${PDS_ADMIN_PASSWORD}" \
    --header "Content-Type: application/json" \
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

  curl \
    --fail \
    --silent \
    --show-error \
    --request POST \
    --user "admin:${PDS_ADMIN_PASSWORD}" \
    --header "Content-Type: application/json" \
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
else
  echo "Unknown subcommand "$0 ${SUBCOMMAND}"." >/dev/stderr
  exit 1
fi
