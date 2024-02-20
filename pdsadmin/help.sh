#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# This script is used to display help information for the pdsadmin command.
cat <<HELP
pdsadmin help
--
update <VERSION>
  Update to the specific PDS version.
    e.g. pdsadmin update 0.1.1

account
  list
    List accounts
    e.g. pdsadmin account list
  create <EMAIL> <HANDLE> <DOB>
    Create a new account
    e.g. pdsadmin account create alice@example.com alice.example.com 08/04/2004
  delete <DID>
    Delete an account specified by DID.
    e.g. pdsadmin account takedown did:plc:xyz123abc456
  takedown <DID>
    Takedown an account specified by DID.
    e.g. pdsadmin account takedown did:plc:xyz123abc456
  untakedown <DID>
    Remove a takedown an account specified by DID.
    e.g. pdsadmin account takedown did:plc:xyz123abc456

request-crawl <RELAY HOST>
    Request a crawl from a relay host.
    e.g. pdsadmin request-crawl bsky.network

create-invite-code
  Create a new invite code.
    e.g. pdsadmin create-invite-code

help
    Display this help information.

HELP
