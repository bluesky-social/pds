#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# This script is used to display help information for the pdsadmin command.
cat <<HELP
pdsadmin help
--
update
  Update to the latest PDS version.
    e.g. pdsadmin update

account
  list
    List accounts
    e.g. pdsadmin account list
  create <EMAIL> <HANDLE>
    Create a new account
    e.g. pdsadmin account create alice@example.com alice.example.com
  delete <DID>
    Delete an account specified by DID.
    e.g. pdsadmin account delete did:plc:xyz123abc456
  takedown <DID>
    Takedown an account specified by DID.
    e.g. pdsadmin account takedown did:plc:xyz123abc456
  untakedown <DID>
    Remove a takedown an account specified by DID.
    e.g. pdsadmin account untakedown did:plc:xyz123abc456
  password-reset <DID>
    Reset a password for an account specified by DID.
    e.g. pdsadmin account reset-password did:plc:xyz123abc456

request-crawl [<RELAY HOST>]
    Request a crawl from a relay host.
    e.g. pdsadmin request-crawl bsky.network

create-invite-code
  Create a new invite code.
    e.g. pdsadmin create-invite-code

help
    Display this help information.

HELP
