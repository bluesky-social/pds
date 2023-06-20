# PDS

Welcome to the repository for the official Bluesky PDS (Personal Data Server). This repository includes container images and documentation designed to assist technical people with self-hosting a Bluesky PDS.

## Table of Contents

* [FAQ](#faq)
  * [What is Bluesky?](#what-is-bluesky)
  * [What is AT Protocol?](#what-is-at-protocol)
  * [Where is the code?](#where-is-the-code)
  * [What is the current status of federation?](#what-is-the-current-status-of-federation)
  * [What should I know about running a PDS in the developer sandbox?](#what-should-i-know-about-running-a-pds-in-the-developer-sandbox)
* [Self\-hosting PDS](#self-hosting-pds)
  * [Preparation for self\-hosting PDS](#preparation-for-self-hosting-pds)
  * [Open your cloud firewall for HTTP and HTTPS](#open-your-cloud-firewall-for-http-and-https)
  * [Configure DNS for your domain](#configure-dns-for-your-domain)
  * [Check that DNS is working as expected](#check-that-dns-is-working-as-expected)
  * [Automatic install on Ubuntu 20\.04/22\.04 or Debian 11/12](#automatic-install-on-ubuntu-20042204-or-debian-1112)
  * [Installing manually on Ubuntu 22\.04](#installing-manually-on-ubuntu-2204)
* [PDS environment variables](#pds-environment-variables)


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

### What is the current status of federation?

We do not currently support PDS federation on the production network but it is now possible to federate in the developer sandbox.

### What should I know about running a PDS in the developer sandbox?

Read the [SANDBOX.md](https://github.com/bluesky-social/pds/blob/main/SANDBOX.md) for an overview of the sandbox network.

## Self-hosting PDS

Self-hosting a Bluesky PDS means running your own Personal Data Server that is capable of federating with the wider Bluesky social network.

### Preparation for self-hosting PDS

Launch a server on any cloud provider, [Digital Ocean](https://digitalocean.com/) and [Vultr](https://vultr.com/) are two popular choices.

Ensure that you can ssh to your server and have root access.

**Server Requirements**
* Public IPv4 address
* Public DNS name
* Public inbound internet access permitted on port 80/tcp and 443/tcp

**Server Recommendations**
|                  |              |
| ---------------- | ------------ |
| Operating System | Ubuntu 22.04 |
| Memory (RAM)     | 2+ GB        |
| CPU Cores        | 2+           |
| Storage          | 40+ GB SSD   |
| Architectures    | amd64, arm64 |
 
**Note:** It is a good security practice to restrict inbound ssh access (port 22/tcp) to your own computer's public IP address. You can check your current public IP address using [ifconfig.me](https://ifconfig.me/).

### Open your cloud firewall for HTTP and HTTPS

One of the most common sources of misconfiguration is not opening firewall ports correctly. Please be sure to double check this step.

In your cloud provider's console, the following ports should be open to inbound access from the public internet.

* 80/tcp (Used only for TLS certification verification)
* 443/tcp (Used for all application requests)

**Note:** there is no need to set up TLS or redirect requests from port 80 to 443 because the Caddy web server, included in the Docker compose file, will handle this for you.

### Configure DNS for your domain

From your DNS provider's control panel, set up a domain with records pointing to your server.

| Name            | Type | Value         | TTL |
| --------------- | ---- | ------------- | --- |
| `example.com`   | `A`  | `12.34.56.78` | 600 |
| `*.example.com` | `A`  | `12.34.56.78` | 600 |

**Note:**
* Replace `example.com` with your domain name.
* Replace `12.34.56.78` with your server's IP address.
* Some providers may use the `@` symbol to represent the root of your domain.
* The wildcard record is required when allowing users to create new accounts on your PDS.
* The TTL can be anything but 600 (10 minutes) is reasonable

### Check that DNS is working as expected

Use a service like [DNS Checker](https://dnschecker.org/) to verify that you can resolve domain names.

Examples to check (record type `A`):
* `example.com`
* `random.example.com`
* `test123.example.com`

These should all return your server's public IP.

### Automatic install on Ubuntu 20.04/22.04 or Debian 11/12

On your server via ssh, run the installer script:

```bash
wget https://raw.githubusercontent.com/bluesky-social/pds/main/installer.sh
```

```bash
sudo bash installer.sh
```

### Installing manually on Ubuntu 22.04

#### Open ports on your Linux firewall

If your server is running a Linux firewall managed with `ufw`, you will need to open these ports:

```bash
$ sudo ufw allow 80/tcp
$ sudo ufw allow 443/tcp
```

#### Install Docker

On your server, install Docker CE (Community Edition), using the the following instructions. For other operating systems you may reference the [official Docker install guides](https://docs.docker.com/engine/install/).

**Note:** All of the following commands should be run on your server via ssh.

##### Uninstall old versions

```bash
sudo apt-get remove docker docker-engine docker.io containerd runc
```

##### Set up the repository

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

##### Install Docker Engine

```bash
sudo apt-get update
```

```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

##### Verify Docker Engine installation

```bash
sudo docker run hello-world
```

#### Set up the PDS directory

```bash
sudo mkdir /pds
sudo mkdir --parents /pds/caddy/data
sudo mkdir --parents /pds/caddy/etc/caddy
```

#### Create the Caddyfile

Be sure to replace `example.com` with your own domain.

```bash
cat <<CADDYFILE | sudo tee /pds/caddy/etc/caddy/Caddyfile
{
  email you@example.com
}

*.example.com, example.com {
  tls {
    on_demand
  }
  reverse_proxy http://localhost:3000
}
CADDYFILE
```

#### Create the PDS env configuration file

You should fill in the first 5 values, but leave the rest untouched unless you have good reason to change it. 

See the PDS environment variables section at the end of this README for explanations of each value

Your PDS will need two secp256k1 private keys provided as hex strings. You can securely generate these keys using `openssl` with the following command:

**Note:**
* Replace `example.com` with your domain name.

```bash
PDS_HOSTNAME="example.com"
PDS_JWT_SECRET="$(openssl rand --hex 16)"
PDS_ADMIN_PASSWORD="$(openssl rand --hex 16)"
PDS_REPO_SIGNING_KEY_K256_PRIVATE_KEY_HEX="$(openssl ecparam --name secp256k1 --genkey --noout --outform DER | tail --bytes=+8 | head --bytes=32 | xxd --plain --cols 32)"
PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX="$(openssl ecparam --name secp256k1 --genkey --noout --outform DER | tail --bytes=+8 | head --bytes=32 | xxd --plain --cols 32)"

cat <<PDS_CONFIG | sudo tee /pds/pds.env
PDS_HOSTNAME=${PDS_HOSTNAME}
PDS_JWT_SECRET=${PDS_JWT_SECRET}
PDS_ADMIN_PASSWORD=${PDS_ADMIN_PASSWORD}
PDS_REPO_SIGNING_KEY_K256_PRIVATE_KEY_HEX=${PDS_REPO_SIGNING_KEY_K256_PRIVATE_KEY_HEX}
PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=${PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX}
PDS_DB_SQLITE_LOCATION=/pds/pds.sqlite
PDS_BLOBSTORE_DISK_LOCATION=/pds/blocks
PDS_DID_PLC_URL=https://plc.bsky-sandbox.dev
PDS_BSKY_APP_VIEW_ENDPOINT=https://api.bsky-sandbox.dev
PDS_BSKY_APP_VIEW_DID=did:web:api.bsky-sandbox.dev
PDS_CRAWLERS=https://bgs.bsky-sandbox.dev
PDS_CONFIG
```

#### Start the PDS containers

##### Download the Docker compose file

Download the `compose.yaml` to run your PDS, which includes the following containers:

* `pds` Node PDS server running on http://localhost:3000
* `caddy` HTTP reverse proxy handling TLS and proxying requests to the PDS server
* `watchtower` Daemon responsible for auto-updating containers to keep the server secure and federating

```bash
curl https://raw.githubusercontent.com/bluesky-social/pds/main/compose.yaml | sudo tee /pds/compose.yaml
```

##### Create the systemd service

```bash
  cat <<SYSTEMD_UNIT_FILE >/etc/systemd/system/pds.service
[Unit]
Description=Bluesky PDS Service
Documentation=https://github.com/bluesky-social/pds
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/pds
ExecStart=/usr/bin/docker compose --file /pds/compose.yaml up --detach
ExecStop=/usr/bin/docker compose --file /pds/compose.yaml down

[Install]
WantedBy=default.target
SYSTEMD_UNIT_FILE
```

##### Start the service

```bash
sudo systemctl daemon-reload
```

```bash
sudo systemctl start pds
```

**Ensure that containers are running**

There should be a caddy, pds, and watchtower container running.

```bash
sudo systemctl status pds
```

```bash
sudo docker ps
```

#### Verify your PDS is online

You can check if your server is online and healthy by requesting the healthcheck endpoint.

```bash
curl https://example.com/xrpc/_health
{"version":"0.2.2-beta.2"}
```

#### Generate an invite code

By default, your PDS will require an invite code to create an account. 

You can generate a new invite code with the following command:

```bash
curl -X POST https://<PDS_HOSTNAME>/xrpc/com.atproto.server.createInviteCode \
  -u "admin:<PDS_ADMIN_PASSWORD>" \
  -H "Content-Type: application/json" \
  -d '{"useCount": 1}'
```

## Connecting to your server

You can use the Bluesky app to connect to your server to create an account.

1. Download the Bluesky app
1. Enter the URL of your PDS (e.g. `https://example.com/`)
1. Create an account using the generated invite code
1. Create a post

_Note: because we use on-the-fly TLS certs, it may take 10-30s for your handle to be accessible. If you aren't seeing your first post/profile, wait 30s and try to make another post._

Checkout [SANDBOX.md](./SANDBOX.md) for an overview of participating in the sandbox network.

## Manually updating your PDS

If you use use Docker `compose.yaml` file in this repo, your PDS will automatically update nightly. To manually update to the latest version use the following commands.

**Pull the latest PDS container image:**
```bash
sudo docker pull ghcr.io/bluesky-social/pds:latest
```

**Restart PDS with the new container image:**
```bash
sudo systemctl restart pds
```

## PDS environment variables

You will need to customize various settings configured through the PDS environment variables. See the below table to find the variables you'll need to set.

| Environment Variable                      | Value                        | Should update? | Notes                                                                       |
| ----------------------------------------- | ---------------------------- | -------------- | --------------------------------------------------------------------------- |
| PDS_HOSTNAME                              | example.com                  | ✅              | Public domain you intend to deploy your service at                          |
| PDS_JWT_SECRET                            | jwt-secret                   | ✅              | Use a secure high-entropy string that is 32 characters in length            |
| PDS_ADMIN_PASSWORD                        | admin-pass                   | ✅              | Use a secure high-entropy string that is 32 characters in length            |
| PDS_REPO_SIGNING_KEY_K256_PRIVATE_KEY_HEX | 3ee68...                     | ✅              | See above Generate Keys section - once set, do not change                   |
| PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX | e049f...                     | ✅              | See above Generate Keys section - once set, do not change                   |
| PDS_DB_SQLITE_LOCATION                    | /pds/pds.sqlite              | ❌              | Or use `PDS_DB_POSTGRES_URL` depending on which database you intend to use  |
| PDS_BLOBSTORE_DISK_LOCATION               | /pds/blocks                  | ❌              | Only update if you update the mounted volume for your docker image as well  |
| PDS_DID_PLC_URL                           | https://plc.bsky-sandbox.dev | ❌              | Do not adjust if you intend to federate with the Bluesky federation sandbox |
| PDS_BSKY_APP_VIEW_URL                     | https://api.bsky-sandbox.dev | ❌              | Do not adjust if you intend to federate with the Bluesky federation sandbox |
| PDS_BSKY_APP_VIEW_DID                     | did:web:api.bsky-sandbox.dev | ❌              | Do not adjust if you intend to federate with the Bluesky federation sandbox |
| PDS_CRAWLERS                              | https://bgs.bsky-sandbox.dev | ❌              | Do not adjust if you intend to federate with the Bluesky federation sandbox |

There are additional environment variables that can be tweaked depending on how you're running your service. For instance, storing blobs in AWS S3, keys in AWS KMS, or setting up an email service.

Feel free to explore those [Here](https://github.com/bluesky-social/atproto/blob/simplify-pds/packages/pds/src/config/env.ts). However, we will not be providing support for more advanced configurations.
