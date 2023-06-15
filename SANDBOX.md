# Sandbox Guide

Welcome to the atproto federation sandbox!

This is a completely separate network from our production services that allows us to test out the federation architecture and wire protocol.

**🐉 Beware of dragons!**

This hasn’t been production tested yet. It seems to work pretty well, but who knows what’s lurking under the surface. Have patience with us as we prep for federation.

On that note, please give us feedback either in [Issues](https://github.com/bluesky-social/atproto/issues) (actual bugs) or [Discussions](https://github.com/bluesky-social/atproto/discussions) (higher-level questions/discussions) on the [atproto repo](https://github.com/bluesky-social/atproto).

### Sandbox Rules

Please checkout the [Sandbox Rules](LINK_ME) before we get started. The gist is: this network is meant to test the technical underpinnings of federation. If you turn up technical problems for us, then you’re doing a great job. If you cause problems for us otherwise, we will defederate from you and will not give an explanation. 

Do not:

- post content that requires active moderation or violates the [Bluesky Community Guidelines](https://blueskyweb.xyz/support/community-guidelines)
- advertise your service as being “Bluesky” or “production atproto network” - this is a sandbox and is meant for technical users
- create a service with more than 1000 accounts on it
- mirror sandbox did:plcs to production

### Routine wipes

As part of the sandbox, we will be doing routine wipes of all network data.

We expect to perform wipes on a weekly or bi-weekly basis, though we reserve the right to do a wipe at any point.

When we wipe data, we will be wiping it on all services (BGS, App View, PLC). We will also mark any existing DIDs as “invalid” & will refuse to index those accounts in the next epoch of the network to discourage users from attempting to “rollover” their accounts across wipes.

# The Sandbox Network

This is a parallel network to production Bluesky where we can test out the federation architecture and wire protocol.

You can check out a high-level view of federation [here](https://blueskyweb.xyz/blog/5-5-2023-federation-architecture).

You can dive deeper into atproto [here](https://atproto.com/docs).

## Network Services

We are running three services: PLC, BGS, Bluesky App View

### PLC

**Hostname:** `plc.bsky-sandbox.dev`

**Code:** https://github.com/bluesky-social/did-method-plc

PLC is the default DID provider for the network. DIDs are the root of your identity in the network. Sandbox PLC functions exactly the same as production PLC, but it is run as a separate service with a separate dataset. The DID resolution client in the self-hosted PDS package is set up to talk the correct PLC service.

### BGS

**Hostname:** `bgs.bsky-sandbox.dev`

**Code:** https://github.com/bluesky-social/indigo/tree/main/bgs

BGS (Big Graph Service) is the firehose for the entire network. It collates data from PDSs & rebroadcasts them out on one giant websocket.

BGS has to find out about your server somehow, so when we do any sort of write, we ping BGS with `com.atproto.sync.requestCrawl` to notify it of new data. This is done automatically in the self-hosted PDS package.

If you’re familiar with the Bluesky production firehose, you can subscribe to the BGS firehose in the exact same manner, the interface & data should be identical

### Bluesky App View

**Hostname:** `api.bsky-sandbox.dev`

**Code:** https://github.com/bluesky-social/atproto/tree/main/packages/bsky

The Bluesky App View aggregates data from across the network to service the Bluesky microblogging application.  It consumes the firehose from the BGS, processing it into serviceable views of the network such as feeds, post threads, and user profiles. It functions as a fairly traditional web service.

When you request a Bluesky-related view from your PDS (`getProfile` for instance), your PDS will actually proxy the request up to App View.

Feel free to experiment with running your own App View if you like!

# The PDS

The PDS (personal data server) is where users host their social data such as posts, profiles, likes, and follows. The goal of the sandbox is to federate many PDS together, so we hope you’ll run your own.

We’re not actually running a Bluesky PDS in sandbox. All of the team’s sandbox accounts are self-hosted.

The PDS that you’ll be running is much of the same code that is running on the Bluesky production PDS. Notably, all of the in-pds-appview code has been torn out. You can see the actual PDS code that you’re running on the [atproto/simplify-pds](https://github.com/bluesky-social/atproto/pull/1198) branch.

### Getting started

For complete instructions on getting your PDS set up, check out the [README](https://github.com/bluesky-social/pds/blob/main/README.md).

To access your account, you’ll log in with the client of your choice in the exact same way that you log into production Bluesky, for instance the [Bluesky web client](https://bsky.app/). When you do so, please provide the url of *your PDS* as the service that you wish to log in to.

Invites on your PDS are required by default - to generate your first invite code, please run:

```bash
# PDS_HOSTNAME & PDS_ADMIN_PASSWORD both come from your pds.env file

curl -X POST https://<PDS_HOSTNAME>/xrpc/com.atproto.server.createInviteCode \
  -u "admin:<PDS_ADMIN_PASSWORD>" \
  -H "Content-Type: application/json" \
  -d '{"useCount": 1}'
```

### Auto-updates

We’ve included Watchtower in the PDS distribution. Every day at midnight PST, this will check our GitHub container registry to see if there is a new version of the PDS container & update it on your service.

This will allow us to rapidly iterate on protocol changes, as we’ll be able to push them out to the network on a daily basis.

When we do routine network wipes, we will be pushing out a database migration to participating PDS that wipes content and accounts.

You are within your rights to disable Watchtower auto-updates, but we strongly encourage their use and will not be providing support if you decide not to run the most up-to-date PDS distribution.

## Odds & Ends & Warnings & Reminders

🧪 Experiment & have fun! 

🤖 Run [feed generators](https://github.com/bluesky-social/feed-generator). They should work the exact same way as production - be sure to adjust your env to listen to Sandbox BGS!

🌈 Feel free to run your own AppView or BGS - although it’s a bit more involved & we’ll be providing limited support for this.

👤 Your PDS will provide your handle by default. Custom domain handles should work exactly the same in sandbox as they do on production Bluesky. Although you will not be able to re-use your handle from production Bluesky as you can only have one DID set per handle.

⚠️ If you follow the self-hosted PDS setup instructions, you’ll have private key material in your env file - be careful about sharing that!

📣 This is a sandbox version of a **public broadcast protocol** - please do not share sensitive information.

🤝 Help each other out! Respond to issues & discussions, chat in Matrix/Discord, etc.