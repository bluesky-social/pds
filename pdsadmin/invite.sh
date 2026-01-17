#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

echo "NOTE: pdsadmin is not actively maintained. Consider using goat: https://github.com/bluesky-social/goat" >/dev/stderr

PDS_ENV_FILE=${PDS_ENV_FILE:-"/pds/pds.env"}
source "${PDS_ENV_FILE}"

# curl a URL and fail if the request fails.
function curl_cmd_get {
  curl --fail --silent --show-error "$@"
}

# curl a URL and fail if the request fails.
function curl_cmd_post {
  curl --fail --silent --show-error --request POST --header "Content-Type: application/json" "$@"
}

# The subcommand to run.
SUBCOMMAND="${1:-}"

#
# invite list [filter]
#
if [[ "${SUBCOMMAND}" == "list" ]]; then
  FILTER="${2:-}"

  CODES_JSON="$(curl_cmd_get \
    --user "admin:${PDS_ADMIN_PASSWORD}" \
    "https://${PDS_HOSTNAME}/xrpc/com.atproto.admin.getInviteCodes"
  )"

  if [[ "${FILTER}" == "used" ]]; then
    # Show codes that have been used
    JQ_FILTER='.codes[] | select(.uses != []) | [.code, (.uses | length | tostring), (if .disabled then "disabled" else "active" end)] | @tsv'
  elif [[ "${FILTER}" == "disabled" ]]; then
    # Show disabled codes
    JQ_FILTER='.codes[] | select(.disabled == true) | [.code, (.uses | length | tostring), "disabled"] | @tsv'
  elif [[ "${FILTER}" == "free" ]]; then
    # Show codes that are not used and not disabled
    JQ_FILTER='.codes[] | select(.uses == [] and .disabled == false) | [.code, "0", "active"] | @tsv'
  elif [[ -z "${FILTER}" ]]; then
    # No filter provided: show all codes
    JQ_FILTER='.codes[] | [.code, (.uses | length | tostring), (if .disabled then "disabled" else "active" end)] | @tsv'
  else
    echo "Unknown filter: ${FILTER}" >/dev/stderr
    echo "Valid filters: used, disabled, free" >/dev/stderr
    exit 1
  fi

  RESULTS="$(echo "${CODES_JSON}" | jq --raw-output "${JQ_FILTER}")"
  if [[ -z "${RESULTS}" ]]; then
    if [[ -n "${FILTER}" ]]; then
      echo "No invite codes found matching filter: ${FILTER}"
    else
      echo "No invite codes found."
    fi
  else
    echo -e "Code\tUses\tStatus"
    echo "${RESULTS}" | column --table
  fi

#
# invite create [use_count]
#
elif [[ "${SUBCOMMAND}" == "create" ]]; then
  USE_COUNT="${2:-1}"

  # Validate that USE_COUNT is a positive integer to avoid invalid JSON payloads.
  if ! [[ "${USE_COUNT}" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: USE_COUNT must be a positive integer (got: '${USE_COUNT}')." >/dev/stderr
    echo "Usage: pdsadmin invite create [count]" >/dev/stderr
    exit 1
  fi

  CODE="$(curl_cmd_post \
    --user "admin:${PDS_ADMIN_PASSWORD}" \
    --data "{\"useCount\": ${USE_COUNT}}" \
    "https://${PDS_HOSTNAME}/xrpc/com.atproto.server.createInviteCode" | jq --raw-output '.code'
  )"

  echo "${CODE}"

else
  echo "Unknown subcommand: ${SUBCOMMAND}" >/dev/stderr
  echo "Usage: pdsadmin invite <command>" >/dev/stderr
  echo "" >/dev/stderr
  echo "Commands:" >/dev/stderr
  echo "  list [filter]    List invite codes (filter: used, disabled, free)" >/dev/stderr
  echo "  create [count]   Create a new invite code (default: 1 use)" >/dev/stderr
  exit 1
fi
