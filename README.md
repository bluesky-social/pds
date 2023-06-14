# PDS

Welcome to the repository for the official Bluesky PDS (Personal Data Server). This repository includes container images and documentation designed to assist technical people with self-hosting a Bluesky PDS.

## FAQ

### What is Bluesky?

Bluesky is a social media application built on AT Protocol.

Please visit the [Bluesky website](https://bsky.app/) for more information.

### What is AT Protocol?

The Authenticated Transfer Protocol, aka atproto, is a protocol for large-scale distributed social applications.

Please visit the [AT Protocol docs](https://atproto.com/guides/overview) for additional information.

### Where is the code?

* [Canonical TypeScript code](https://github.com/bluesky-social/atproto)
* [Experimental Go code](https://github.com/bluesky-social/indigo)

## Self-hosting a PDS

Self-hosting a Bluesky PDS means running your own Personal Data Server that is capable of federating with the wider Bluesky social network.

### Launch your server

Launch a server on any cloud provider, [Digital Ocean](https://digitalocean.com/) and [Vultr](https://vultr.com/) are two popular choices.

**Server Requirements**
* Public IPv4 address
* Public DNS name
* Public internet access permitted on port 80/tcp and 443/tcp

**Server Recommendations**
|                  |                  |
| ---------------- | ---------------- |
| Operating System | Ubuntu 22.04 LTS |
| Memory (RAM)     | 2+ GB            |
| CPU Cores        | 2+               |
| Storage          | 40+ GB SSD       |
 

### Install your server

Install your Ubuntu 22.04 server, and then ensure that you can ssh to it.

**NOTE:** It is a good security practice to restrict inbound ssh access (port 22/tcp) to your own computer's public IP address. You can check your current public IP address using [ifconfig.me](https://ifconfig.me/).

### Open your firewall

One of the most common sources of misconfiguration is not opening firewall ports correctly. Please be sure to double check this step.

It may be helpful to use a remote [port scanning](https://dnschecker.org/port-scanner.php) service to verify that access is permitted. Once your server is fully configured, this service should display the ports as open.

#### Open ports on your cloud provider's firewall

In your cloud provider's console, the following ports should be open to access from the public internet.

* 80/tcp (Used only for TLS certification verification)
* 443/tcp (Used for all application requests)

#### Open ports on your Linux firewall

If your server is running a Linux firewall managed with `ufw`, you will also need to open these same ports on the server itself.

```bash
$ sudo ufw allow 80/tcp
$ sudo ufw allow 443/tcp
```

### Install Docker

To install Docker CE (Community Edition) on Ubuntu 22.04, use the the following instructions. For other operating systems you may reference the [official Docker install guides](https://docs.docker.com/engine/install/).

**NOTE:** All of the following commands should be run on your server via ssh.

#### Uninstall old versions

```bash
sudo apt-get remove docker docker-engine docker.io containerd runc
```

#### Set up the repository

```bash
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg
```

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

```bash
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

#### Install Docker Engine

```bash
sudo apt-get update
```

```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

#### Verify Docker Engine installation

```bash
sudo docker run hello-world
```

### Set up the PDS directory

```bash
# Create the directory where all PDS data will be stored.
sudo mkdir /data

# Create the required caddy webserver directories.
sudo mkdir --parents /data/caddy/{etc,data}
```

### Start the PDS containers

#### Download the Docker compose file

Download the `sqlite-compose.yaml` to run your PDS with a local SQLite database.

```bash
curl https://raw.githubusercontent.com/bluesky-social/pds/main/sqlite-compose.yaml >compose.yaml
```

Or, download the `postgres-compose.yaml` to run your PDS with a remote PostgreSQL database.

```bash
curl https://raw.githubusercontent.com/bluesky-social/pds/main/postgres-compose.yaml >compose.yaml
```

#### Edit your compose.yaml file

You will need to customize various settings configured through the PDS environment variables.

| Environment Variable  | Value                                         |
| --------------------- | --------------------------------------------- |
| PDS_HOSTNAME          | example.com                                   |
| PDS_DB_POSTGRES_URL   | postgresql://user:password@host:port/database |
| PDS_JWT_SECRET        | jwt-secret                                    |
| PDS_ADMIN_PASSWORD    | admin-pass                                    |
| ...                   | ...                                           |

You _should_ provide values to the following variables:
- `PDS_HOSTNAME`
- `PDS_DB_POSTGRES_URL` or `PDS_DB_SQLITE_LOCATION` depending on which database you intend to use
- `PDS_JWT_SECRET`
- `PDS_ADMIN_PASSWORD`
- `LOG_ENBALED` - defaults to `true` and outputs structured logs to stdout

You _should not_ update the following value unless you also update the mounted volumes for your docker image:
- `PDS_BLOBSTORE_DISK_LOCATION`

You will need to provide key material to the following variables. We've included a utility to generate keys for you with openssl
Once these are set, you _should not_ adjust them - as you will break any repositories that you are currently hosting.
- `PDS_REPO_SIGNING_KEY_K256_PRIVATE_KEY_HEX`
- `PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX`
 
You _should not_ adjust the following variables if you intend to federate with the Bluesky federation sandbox:
- `PDS_DID_PLC_URL="plc.bsky-sandbox.dev"`
- `PDS_BSKY_APP_VIEW_ENDPOINT="api.bsky-sandbox.dev"`
- `PDS_BSKY_APP_VIEW_DID="did:web:api.bsky-sandbox.dev"`
- `PDS_CRAWLERS="bgs.bsky-sandbox.dev"`

There are additional environment variables that can be tweaked depending on how you're running your service. For instance, storing blobs in AWS S3, keys in AWS KMS, or setting up an email service.

Feel free to explore these [Here](https://github.com/bluesky-social/atproto/blob/simplify-pds/packages/pds/src/config/env.ts). However, we will not be providing support for more advanced configurations.

#### Run docker compose

Run `docker compose up` to start the three required containers.

```bash
docker compose up --wait --detach
```

You should see output similar to this:

```
[+] Running 3/3
 ✔ Container watchtower  Healthy  1.1s 
 ✔ Container pds         Healthy  1.1s 
 ✔ Container caddy       Healthy  1.0s
```

### Verify your PDS is online

You can check if your server is online and healthy by requesting the healthcheck endpoint.

```bash
curl https://example.com/xrpc/_health
{"version":"v1.2.3"}
```

### Connecting to your server

You can use the Bluesky app to connect to your server to create an account.

1. Download the Bluesky app
1. Enter the URL of your PDS (e.g. `https://example.com/`)
1. Create an account
