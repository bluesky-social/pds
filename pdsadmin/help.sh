#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# This script is used to display help information for the pdsadmin command.
cat <<HELP
pdsadmin help
--
NOTE: These scripts are not actively maintained. For a more robust solution,
consider using goat: https://github.com/bluesky-social/goat
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
    Remove a takedown from an account specified by DID.
    e.g. pdsadmin account untakedown did:plc:xyz123abc456
  reset-password <DID>
    Reset a password for an account specified by DID.
    e.g. pdsadmin account reset-password did:plc:xyz123abc456

request-crawl [<RELAY HOST>]
    Request a crawl from a relay host.
    e.g. pdsadmin request-crawl bsky.network

invite
  list [FILTER]
    List invite codes. Filter: used, disabled, free
    e.g. pdsadmin invite list
    e.g. pdsadmin invite list free
  create [COUNT]
    Create a new invite code with optional use count (default: 1)
    e.g. pdsadmin invite create
    e.g. pdsadmin invite create 5

create-invite-code [COUNT]
    Create a new invite code (deprecated, use 'pdsadmin invite create' instead)
    e.g. pdsadmin create-invite-code
    e.g. pdsadmin create-invite-code 5

help
    Display this help information.

HELP
