# Dockerized PDS

This project is a fork of the [official PDS implementation](https://github.com/bluesky-social/pds). This fork aims to make the deployment and management of a PDS more amenable to the standard Docker approach.

# Installation

1. Tweak the example `docker-compose.yaml` and `pds.env` to your liking. 
2. Run `docker compose -f docker-compose.yaml up -d`.

# Administration

The bash scripts used for administration are available *in the the path inside docker container*, meaning you can administer the PDS with commands like

```bash
$ docker exec -it pds pds-create-invite-code
pds-example-com-12345-abcde
```

```bash
$ docker exec -it pds pds-account create alice@example.com alice.pds.example.com

Account created successfully!
-----------------------------
Handle   : alice.pds.example.com
DID      : did:plc:1234567890
Password : supersecret
-----------------------------
Save this password, it will not be displayed again.
```

```bash
$ docker exec -it pds pds-account list      
Handle  Email  DID
```

```bash
$ docker exec -it pds pds-account list                                          
Handle                 Email              DID
alice.pds.example.com  alice@example.com  did:plc:1234567890
```