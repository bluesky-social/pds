# Bluesky Developer Sandbox Guide

Welcome to the atproto federation developer sandbox!

This is a completely separate network from our production services that allows us to test out the federation architecture and wire protocol.

The federation sandbox environment is an area set up for exploration and testing of the technical components of the AT Protocol distributed social network. It is intended for developers and self-hosters to test out data availability in a federated environment.

To maintain a positive and productive developer experience, we've established this Code of Conduct that outlines our expectations and guidelines. This sandbox environment is initially meant to test the technical components of federation.

Given that this is a testing environment, we will be defederating from any instances that do not abide by these guidelines, or that cause unnecessary trouble, and will not be providing specific justifications for these decisions.

<!-- markdown-toc -i SANDBOX.md -->

<!-- toc -->

- [Guidelines that must be followed](#guidelines-that-must-be-followed)
  * [Post responsibly](#post-responsibly)
  * [Keep the emphasis on testing](#keep-the-emphasis-on-testing)
  * [Do limit account creation](#do-limit-account-creation)
  * [Don’t expect persistence or uptime](#dont-expect-persistence-or-uptime)
  * [Don't advertise your service as being "Bluesky"](#dont-advertise-your-service-as-being-bluesky)
  * [Do not mirror sandbox did:plcs to production](#do-not-mirror-sandbox-didplcs-to-production)
  * [Status and Wipes](#status-and-wipes)
    + [🐉 Beware of dragons!](#%F0%9F%90%89-beware-of-dragons)
    + [Routine wipes](#routine-wipes)
- [Getting started](#getting-started)
  * [Auto-updates](#auto-updates)
  * [Odds & Ends & Warnings & Reminders](#odds--ends--warnings--reminders)
- [Learn more about atproto federation](#learn-more-about-atproto-federation)
  * [Network Services](#network-services)
    + [PLC](#plc)
    + [BGS](#bgs)
    + [Bluesky App View](#bluesky-app-view)
- [The PDS](#the-pds)

<!-- tocstop -->

# Guidelines that must be followed

Using the sandbox environment means you agree to adhere to our Guidelines. Please read the following carefully:

## Post responsibly

The sandbox environment is intended to test infrastructure, but user content may be created as part of this testing process. Content generation can be automated or manual.

Do not post content that requires active moderation or violates the [Bluesky Community Guidelines](https://bsky.social/about/support/community-guidelines).

## Keep the emphasis on testing

We’re striving to maintain a sandbox environment that fosters learning and technical growth. We will defederate with instances that recruit users without making it clear that this is a test environment.

## Do limit account creation

We don't want any one server using a majority of the resources in the  sandbox. To keep things balanced, to start, we’re only federating with Personal Data Servers (PDS) with up to 1000 accounts. However, we may change this if needed.

## Don’t expect persistence or uptime

We will routinely be wiping the data on our infrastructure. This is intended to reset the network state and to test sync protocols. Accounts and content should not be mirrored or migrated between the sandbox and real-world environments.

## Don't advertise your service as being "Bluesky"

This is a developer sandbox and is meant for technical users. Do not promote your service as being a way for non-technical users to use Bluesky.

## Do not mirror sandbox did:plcs to production


## Status and Wipes

### 🐉 Beware of dragons!

This hasn’t been production tested yet. It seems to work pretty well, but who knows what’s lurking under the surface — that's what this sandbox is for! Have patience with us as we prep for federation.

On that note, please give us feedback either in [Issues](https://github.com/bluesky-social/atproto/issues) (actual bugs) or [Discussions](https://github.com/bluesky-social/atproto/discussions) (higher-level questions/discussions) on the [atproto repo](https://github.com/bluesky-social/atproto).

### Routine wipes

As part of the sandbox, we will be doing routine wipes of all network data.

We expect to perform wipes on a weekly or bi-weekly basis, though we reserve the right to do a wipe at any point.

When we wipe data, we will be wiping it on all services (BGS, App View, PLC). We will also mark any existing DIDs as “invalid” & will refuse to index those accounts in the next epoch of the network to discourage users from attempting to “rollover” their accounts across wipes.

# Getting started

For complete instructions on getting your PDS set up, check out the [README](./README.md).

To access your account, you’ll log in with the client of your choice in the exact same way that you log into production Bluesky, for instance the [Bluesky web client](https://app.bsky-sandbox.dev/). When you do so, please provide the url of *your PDS* as the service that you wish to log in to.

## Auto-updates

We’ve included Watchtower in the PDS distribution. Every day at midnight PST, this will check our GitHub container registry to see if there is a new version of the PDS container & update it on your service.

This will allow us to rapidly iterate on protocol changes, as we’ll be able to push them out to the network on a daily basis.

When we do routine network wipes, we will be pushing out a database migration to participating PDS that wipes content and accounts.

You are within your rights to disable Watchtower auto-updates, but we strongly encourage their use and will not be providing support if you decide not to run the most up-to-date PDS distribution.

## Odds & Ends & Warnings & Reminders

🧪 Experiment & have fun! 

🤖 Run [feed generators](https://github.com/bluesky-social/feed-generator). They should work the exact same way as production - be sure to adjust your env to listen to Sandbox BGS!

🌈 Feel free to run your own AppView or BGS - although it’s a bit more involved & we’ll be providing limited support for this.

✏️ Because the atproto network is a distributed system, your PDS can no longer definitively read-after-write. Updates are generally processed pretty quickly, however this discrepancy may show in certain circumstances, such as updating a profile or replying to a thread. We're working on utilities to make this easier to handle.

⏱️ As a specific case of the above, because we use on-demand TLS with Caddy, your profile may not load at first - please be patient & it should load within 5-10s after account creation. Again, we'll be working to smooth over this.

👤 Your PDS will provide your handle by default. Custom domain handles should work exactly the same in sandbox as they do on production Bluesky. Although you will not be able to re-use your handle from production Bluesky as you can only have one DID set per handle.

⚠️ If you follow the self-hosted PDS setup instructions, you’ll have private key material in your env file - be careful about sharing that!

📣 This is a sandbox version of a **public broadcast protocol** - please do not share sensitive information.

🤝 Help each other out! Respond to issues & discussions, chat in the community-run [Discord](https://discord.gg/3srmDsHSZJ), etc.

# Learn more about atproto federation

Check out the [high-level view of federation](https://bsky.social/about/blog/5-5-2023-federation-architecture).

Dive deeper with the [atproto docs](https://atproto.com/docs).

## Network Services

We are running three services: PLC, BGS, Bluesky "App View"

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

The PDS (Personal Data Server) is where users host their social data such as posts, profiles, likes, and follows. The goal of the sandbox is to federate many PDS together, so we hope you’ll run your own.

We’re not actually running a Bluesky PDS in sandbox. You might see Bluesky team members' accounts in the sandbox environment, but those are self-hosted too.

The PDS that you’ll be running is much of the same code that is running on the Bluesky production PDS. Notably, all of the in-pds-appview code has been torn out. You can see the actual PDS code that you’re running on the [atproto/simplify-pds](https://github.com/bluesky-social/atproto/pull/1198) branch.
