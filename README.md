# PDS

Welcome to the repository for the official Bluesky PDS (Personal Data Server). This repository includes container images and documentation designed to assist technical people with hosting a Bluesky PDS.

Head over to the [ATProto Touchers Discord](https://discord.atprotocol.dev/) to chat with other folks hosting instances and get important updates about the PDS distribution!

## Table of Contents

<!-- markdown-toc -i README.md -->

<!-- toc -->

- [PDS](#pds)
  - [Table of Contents](#table-of-contents)
  - [FAQ](#faq)
    - [What is Bluesky?](#what-is-bluesky)
    - [What is AT Protocol?](#what-is-at-protocol)
    - [Where is the code?](#where-is-the-code)
    - [What is the current status of federation?](#what-is-the-current-status-of-federation)
  - [Self-hosting a PDS](#self-hosting-a-pds)
    - [Deploying a PDS onto a VPS](#deploying-a-pds-onto-a-vps)
    - [Open your cloud firewall for HTTP and HTTPS](#open-your-cloud-firewall-for-http-and-https)
    - [Configure DNS for your domain](#configure-dns-for-your-domain)
    - [Check that DNS is working as expected](#check-that-dns-is-working-as-expected)
    - [Installing on Ubuntu 20.04/22.04/24.04 and Debian 11/12/13](#installing-on-ubuntu-200422042404-and-debian-111213)
    - [Verifying that your PDS is online and accessible](#verifying-that-your-pds-is-online-and-accessible)
    - [Creating an account using pdsadmin](#creating-an-account-using-pdsadmin)
    - [Creating an account using an invite code](#creating-an-account-using-an-invite-code)
    - [Using the Bluesky app with your PDS](#using-the-bluesky-app-with-your-pds)
    - [Setting up SMTP](#setting-up-smtp)
      - [Common SMTP issues](#common-smtp-issues)
    - [Logging](#logging)
    - [Updating your PDS](#updating-your-pds)
    - [goat CLI](#goat-cli)
    - [Environment Variables](#environment-variables)
  - [License](#license)

<!-- tocstop -->

## FAQ

### What is Bluesky?

Bluesky is a social media application built on AT Protocol.

Please visit the [Bluesky website](https://bsky.social/) for more information.

### What is AT Protocol?

The Authenticated Transfer Protocol, aka atproto, is a protocol for large-scale distributed social applications.

Please visit the [AT Protocol docs](https://atproto.com/guides/overview) for additional information.

### Where is the code?

* [TypeScript code](https://github.com/bluesky-social/atproto/tree/main/packages/pds)
* [Go code](https://github.com/bluesky-social/indigo)

### What is the current status of federation?

The AT Protocol network is open to federation!

✅ Federated domain handles (e.g. `@nytimes.com`)

✅ Federated feed generators (custom algorithms)

✅ Federated relays (event firehose)

✅ Federated app views (API service)

✅ Federated data (PDS hosting)

✅ Federated moderation (labeling)

## Self-hosting a PDS

Self-hosting a Bluesky PDS means running your own Personal Data Server that is capable of federating with the wider Bluesky social network.

### Deploying a PDS onto a VPS

This README provides instructions for deploying a PDS using our install script onto a Virtual Private Server. [Digital Ocean](https://digitalocean.com/) and [Vultr](https://vultr.com/) are two popular choices for VPS hosting.

Ensure that you can ssh to your server and have root access.

**Server Requirements**
* Public IPv4 address
* Public DNS name
* Public inbound internet access permitted on port 80/tcp and 443/tcp

**Server Recommendations**
|                  |              |
| ---------------- | ------------ |
| Operating System | Ubuntu 24.04 |
| Memory (RAM)     | 1 GB         |
| CPU Cores        | 1            |
| Storage          | 20 GB SSD    |
| Architectures    | amd64, arm64 |
| Number of users  | 1-20         |

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

### Installing on Ubuntu 20.04/22.04/24.04 and Debian 11/12/13

Note that this script assumes a relatively "fresh" VPS that is not also concurrently hosting a web server or anything else on port 80/443. If you intend to run a PDS alongside an existing webserver on the same VPS, you will not want to use this install script.

On your server, download the install script using `curl`:

```bash
curl https://raw.githubusercontent.com/bluesky-social/pds/main/installer.sh > installer.sh
```

And then run the installer using `bash`. You will need `sudo` permissions to continue:

```bash
sudo bash installer.sh
```

The install script is interactive and will prompt for input during the install process. You will need to provide your public DNS address, an admin email address (which does not need to be from the same domain), and be prompted to create a PDS user account with its own email address and handle. If you plan to reuse an existing AT handle, you can skip user account creation, though if it is your first time deploying a PDS you may want to create an account using your domain like `account.your-domain.net` for testing purposes.

Upon completion of a successful installation, you'll receive output similar to the following:

```
========================================================================
PDS installation successful!
------------------------------------------------------------------------

Check service status      : sudo systemctl status pds
Watch service logs        : sudo docker logs -f pds
Backup service data       : /pds
PDS Admin command         : pdsadmin

Required Firewall Ports
------------------------------------------------------------------------
Service                Direction  Port   Protocol  Source
-------                ---------  ----   --------  ----------------------
HTTP TLS verification  Inbound    80     TCP       Any
HTTP Control Panel     Inbound    443    TCP       Any

Required DNS entries
------------------------------------------------------------------------
Name                         Type       Value
-------                      ---------  ---------------
your-domain.net              A          your-ip-address
*.your-domain.net            A          your-ip-address

Detected public IP of this server: your-ip-address

To see pdsadmin commands, run "pdsadmin help"

========================================================================
```

And, following account creation:

```
Account created successfully!
-----------------------------
Handle   : handle.your-domain.net
DID      : did:plc:your-did
Password : your-password
-----------------------------
Save this password, it will not be displayed again.
```

### Verifying that your PDS is online and accessible

> [!TIP]
> The most common problems with getting PDS content consumed in the live network usually result from users trying to port the provided Caddy configuration to Nginx, Apache, or other reverse proxies. Getting TLS certificates, WebSockets, and virtual server names provisioned can be challenging. We are not currently providing tech support for other configurations.

After installation, your PDS should be live and accessible on the web. You can check if your server is online and healthy by making a request to `https://your-domain.net/xrpc/_health` (the healthcheck endpoint). You should see a JSON response with a version, like:

Visit `https://your-domain.net/xrpc/_health` in your browser. You should see a JSON response with a version, like:

```
{"version":"0.2.2-beta.2"}
```

You'll also need to check that WebSockets are working, for the rest of the network to pick up content from your PDS. You can test by installing a tool like `wsdump` and running a command like:

```bash
wsdump "wss://example.com/xrpc/com.atproto.sync.subscribeRepos?cursor=0"
```

Note that there will be no events output on the WebSocket until they are created in the PDS, so the above command may continue to run with no output immediately post-installation.

### Creating an account using pdsadmin

You'll now have access to some additional command line tools on this server. Use `pdsadmin` to create an account if you haven't already:

```bash
sudo pdsadmin account create
```

### Creating an account using an invite code

If needed, use `pdsadmin` to create an invite code:

```bash
sudo pdsadmin create-invite-code
```

When creating an account using the app, enter this invite code.

### Using the Bluesky app with your PDS

You can use the Bluesky app to connect to your PDS.

1. Get the Bluesky app
    * [Bluesky for Web](https://bsky.app/)
    * [Bluesky for iPhone](https://apps.apple.com/us/app/bluesky-social/id6444370199)
    * [Bluesky for Android](https://play.google.com/store/apps/details?id=xyz.blueskyweb.app)
1. Enter the URL of your PDS (e.g. `https://example.com/`)

_Note: because the subdomain TLS certificate is created on-demand, it may take 10-30s for your handle to be accessible. If you aren't seeing your first post/profile, wait 30s and try to make another post._

### Setting up SMTP

To be able to verify users' email addresses and send other emails, you need to set up an SMTP server.

As an alternative to running your own SMTP server, you can use an email service. [Resend](https://resend.com/) and [SendGrid](https://sendgrid.com/) are two popular choices.

Create an account and API key on an email service, ensure your server allows access on the required ports, and then you can add these configuration variables to `/pds/pds.env` on your server (example with Resend):

```
PDS_EMAIL_SMTP_URL=smtps://resend:<your api key here>@smtp.resend.com:465/
PDS_EMAIL_FROM_ADDRESS=admin@your.domain
```

If you prefer to use a standard SMTP server (a local one or from your email provider), put your account's username and password in the URL:

```
PDS_EMAIL_SMTP_URL=smtps://username:password@smtp.example.com/
```

Alternatively, if you're running a local sendmail-compatible mail service like Postfix or Exim on the same host, you can configure the PDS to use the sendmail transport by using such URL:

```
PDS_EMAIL_SMTP_URL=smtp:///?sendmail=true
```

_Note: Your PDS will need to be restarted with those variables. This varies depending on your setup. If you followed this installation guide, run `systemctl restart pds`. You might need to restart the server or recreate the container, depending on what you are using._

#### Common SMTP issues

If you find that your test messages using cURL or other sources go out correctly, but you are not receiving emails from your PDS, you may need to URL encode your username and password on `/pds/pds.env` and restart the PDS service.

If the username and/or password contain special characters, the special characters will need to be [percent encoded](https://en.wikipedia.org/wiki/Percent-encoding).  For some email services, the username will contain an extra `@` symbol that will also need to be percent encoded. For example, the URL `user&name@oci:p@ssword@smtphost:465` after percent encoding for the username and password fields would become `user%26name%40oci:p%40ssword@smtphost:465`.

If you are migrating an account, Bluesky's UI will ask you to confirm your email address. The confirmation code email is meant to come from your PDS. If you are encountering issues with SMTP and want to confirm the address before solving it, you can find the confirmation code on the `email_token` table on `accounts.sqlite`.

### Logging

By default, logs from the PDS are printed to `stdout` and end up in Docker's log. You can browse them by running:

```
[sudo] docker logs pds
```

Note: these logs are not persisted, so they will be lost after server reboot.

Alternatively, you can configure the logs to be printed to a file by setting `LOG_DESTINATION`:

```
LOG_DESTINATION=/pds/pds.log
```

You can also change the minimum level of logs to be printed (default: `info`):

```
LOG_LEVEL=debug
```

### Updating your PDS

It is recommended that you keep your PDS up to date with new versions. You can use the `pdsadmin` tool to update your PDS.

```bash
sudo pdsadmin update
```

### goat CLI

The PDS image includes [goat](https://github.com/bluesky-social/goat), our command line tool for performing admin functions. `goat` is more portable than the `pdsadmin` scripts and can be used locally or within the container installed by this script.

### Environment Variables

| Environment Variable                        | Default                            |
| ------------------------------------------- | ---------------------------------- |
| `PDS_HOSTNAME`                              | None                               |
| `PDS_JWT_SECRET`                            | None                               |
| `PDS_ADMIN_PASSWORD`                        | None                               |
| `PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX` | None                               |
| `PDS_DATA_DIRECTORY`                        | `/pds`                             |
| `PDS_BLOBSTORE_DISK_LOCATION`               | `/pds/blocks`                      |
| `PDS_BLOB_UPLOAD_LIMIT`                     | `104857600` (100MB)                |
| `PDS_DID_PLC_URL`                           | `https://plc.directory`            |
| `PDS_BSKY_APP_VIEW_URL`                     | `https://api.bsky.app`             |
| `PDS_BSKY_APP_VIEW_DID`                     | `did:web:api.bsky.app`             |
| `PDS_REPORT_SERVICE_URL`                    | `https://mod.bsky.app`             |
| `PDS_REPORT_SERVICE_DID`                    | `did:plc:ar7c4by46qjdydhdevvrndac` |
| `PDS_CRAWLERS`                              | `https://bsky.network`             |
| `LOG_ENABLED`                               | `true`                             |
| `PDS_EMAIL_SMTP_URL`                        | None                               |
| `PDS_EMAIL_FROM_ADDRESS`                    | None                               |


## License

This project is dual-licensed under MIT and Apache 2.0 terms:

- MIT license ([LICENSE-MIT.txt](https://github.com/bluesky-social/pds/blob/main/LICENSE-MIT.txt) or http://opensource.org/licenses/MIT)
- Apache License, Version 2.0, ([LICENSE-APACHE.txt](https://github.com/bluesky-social/pds/blob/main/LICENSE-APACHE.txt) or http://www.apache.org/licenses/LICENSE-2.0)

Downstream projects and end users may choose either license individually, or both together, at their discretion. The motivation for this dual-licensing is the additional software patent assurance provided by Apache 2.0.
