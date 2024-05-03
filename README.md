# PDS

Welcome to the repository for the official Bluesky PDS (Personal Data Server). This repository includes container images and documentation designed to assist technical people with hosting a Bluesky PDS.

Head over to the [AT Protocol PDS Admins Discord](https://discord.gg/E4Urw3xS) to chat with other folks hosting instances and get important updates about the PDS distribution!

## Table of Contents

<!-- markdown-toc -i README.md -->

<!-- toc -->

- [FAQ](#faq)
  * [What is Bluesky?](#what-is-bluesky)
  * [What is AT Protocol?](#what-is-at-protocol)
  * [Where is the code?](#where-is-the-code)
  * [What is the current status of federation?](#what-is-the-current-status-of-federation)
  * [What should I know about running a PDS in the developer sandbox?](#what-should-i-know-about-running-a-pds-in-the-developer-sandbox)
- [Self-hosting PDS](#self-hosting-pds)
  * [Preparation for self-hosting PDS](#preparation-for-self-hosting-pds)
  * [Open your cloud firewall for HTTP and HTTPS](#open-your-cloud-firewall-for-http-and-https)
  * [Configure DNS for your domain](#configure-dns-for-your-domain)
  * [Check that DNS is working as expected](#check-that-dns-is-working-as-expected)
  * [Installer on Ubuntu 20.04/22.04 and Debian 11/12](#installer-on-ubuntu-20042204-and-debian-1112)
  * [Verifying that your PDS is online and accessible](#verifying-that-your-pds-is-online-and-accessible)
  * [Creating an account using pdsadmin](#creating-an-account-using-pdsadmin)
  * [Creating an account using an invite code](#creating-an-account-using-an-invite-code)
  * [Using the Bluesky app with your PDS](#using-the-bluesky-app-with-your-pds)
  * [Updating your PDS](#updating-your-pds)

<!-- tocstop -->

## FAQ

### What is Bluesky?

Bluesky is a social media application built on AT Protocol.

Please visit the [Bluesky website](https://bsky.social/) for more information.

### What is AT Protocol?

The Authenticated Transfer Protocol, aka atproto, is a protocol for large-scale distributed social applications.

Please visit the [AT Protocol docs](https://atproto.com/guides/overview) for additional information.

### Where is the code?

* [TypeScript code](https://github.com/bluesky-social/atproto)
* [Go code](https://github.com/bluesky-social/indigo)

### What is the current status of federation?

As of Spring 2024, the AT Protocol network is open to federation!

✅ Federated domain handles (e.g. `@nytimes.com`)

✅ Federated feed generators (custom algorithms)

✅ Federated relays (event firehose)

✅ Federated app views (API service)

✅ Federated data (PDS hosting)

✅ Federated moderation (labeling)

### What should I know about running a PDS in the developer sandbox?

Developers may now run self-hosted PDS hosts on the production network!

Though it is still recommended to run experiments in the developer sandbox network.

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

### Installer on Ubuntu 20.04/22.04 and Debian 11/12

On your server via ssh, download the installer script using wget:

```bash
wget https://raw.githubusercontent.com/bluesky-social/pds/main/installer.sh
```

or download it using curl:

```bash
curl https://raw.githubusercontent.com/bluesky-social/pds/main/installer.sh >installer.sh
```

And then run the installer using bash:

```bash
sudo bash installer.sh
```

### Verifying that your PDS is online and accessible

> [!TIP]
> The most common problems with getting PDS content consumed in the live network are when folks substitute the provided Caddy configuration for nginx, apache, or similar reverse proxies. Getting TLS certificates, WebSockets, and virtual server names all correct can be tricky. We are not currently providing tech support for other configurations.

You can check if your server is online and healthy by requesting the healthcheck endpoint.

You can visit `https://example.com/xrpc/_health` in your browser. You should see a JSON response with a version, like:

```
{"version":"0.2.2-beta.2"}
```

You'll also need to check that WebSockets are working, for the rest of the network to pick up content from your PDS. You can test by installing a tool like `wsdump` and running a command like:

```bash
wsdump "wss://example.com/xrpc/com.atproto.sync.subscribeRepos?cursor=0"
```

Note that there will be no events output on the WebSocket until they are created in the PDS, so the above command may continue to run with no output if things are configured successfully.

### Creating an account using pdsadmin

Using ssh on your server, use `pdsadmin` to create an account if you haven't already.

```bash
sudo pdsadmin account create
```

### Creating an account using an invite code

Using ssh on your server, use `pdsadmin` to create an invite code.

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

### Updating your PDS

It is recommended that you keep your PDS up to date with new versions, otherwise things may break. You can use the `pdsadmin` tool to update your PDS.

```bash
sudo pdsadmin update
```

## License

This project is dual-licensed under MIT and Apache 2.0 terms:

- MIT license ([LICENSE-MIT.txt](https://github.com/bluesky-social/pds/blob/main/LICENSE-MIT.txt) or http://opensource.org/licenses/MIT)
- Apache License, Version 2.0, ([LICENSE-APACHE.txt](https://github.com/bluesky-social/pds/blob/main/LICENSE-APACHE.txt) or http://www.apache.org/licenses/LICENSE-2.0)

Downstream projects and end users may choose either license individually, or both together, at their discretion. The motivation for this dual-licensing is the additional software patent assurance provided by Apache 2.0.
