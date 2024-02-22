# Account Migration 

### ⚠️ Warning ⚠️ ️
Account migration is a potentially destructive operation. Part of the operation involves signing away your old PDS's ability to make updates to your DID. If something goes wrong, you could be permanently locked out of your account, and Bluesky will not be able to help you recover it. 

Therefore, we do not recommend migrating your primary account yet. And we specifically recommend _against_ migrating your main account if you do not understand how PLC operations work.

As well, the Bluesky PDS is not currently accepting incoming migrations (it will in the future). Therefore this is currently a one-way street. If you migrate off of `bsky.social`, _you will not be able to return_. However, you will be able to migrate between other PDSs.

...

![Diagram of account migration flow](https://github.com/bluesky-social/pds/blob/main/asserts/account-migration.png)

Account Migration occurs in 4 main steps:
- Creating an account on the new PDS
- Migrating data from the old PDS to the new PDS
- Updating identity to point to the new PDS
- Finalizing the migration


### Creating an Account

In order to create an account, you first need to prove to the new PDS that you're in control of the DID that you're attempting to register as.

To do so, you need a JWT signed with the signing key associated with your DID. You can obtain this through calling `com.atproto.server.getServiceAuth` from your old PDS. If you're old PDS is not willing to provide the authentication token, you will need to update your DID document to point to a signing key that you possess in order to mint an authentication token yourself.

With this JWT set as a Bearer token, you can then create an account on the new PDS by calling `com.atproto.server.createAccount`. You'll need to fulfill any challenges that the new PDS requires - such as an invite code. 

After creating an account, you'll have a signing key on the new PDS and an empty repository. You're account will be in a "deactivated" state such that it is not usable yet.

### Migrating data

Now that you have an account on the new PDS, you can start migrating data into it. After creating your account, you will have received an access token for the new PDS and it will be required for all incoming data.

First, you can grab your entire repository in the from of a [CAR file](https://ipld.io/specs/transport/car/carv1/) by calling `com.atproto.sync.getRepo`. You can then upload those exact bytes to your new PDS through `com.atproto.repo.importRepo`. The new PDS will parse the CAR file, index all blocks and records, and sign a new commit for the repository.

Next, you'll need to upload all relevant blobs. These can be discovered by calling `com.atproto.sync.listBlobs` on your old PDS. For each blob, you'll need to download the contents through `com.atproto.sync.getBlob` and upload them to your new PDS through `com.atproto.repo.uploadBlob`.

Finally, you'll need to migrate private state. Currently the only private state held on your PDS is your preferences. You can migrate this by calling `app.bsky.actor.getPreferences` on your old PDS, and submitting the results to `app.bsky.actor.putPreferences` on your new PDS.

At any point during this process, you can check the status of your new account by calling `com.atproto.server.checkAccountStatus` which will inform you of your repo state, how many records are indexed, how many private state values are stored, how many blobs it is expecting (based on parsing records), and how many blobs have been uploaded. 

### Updating identity

After your data has been migrated to your new PDS, you'll need to update your DID to point to the correct credentials - handle, pds endpoint, signing key, and (if using a did:plc) the new PDS's rotation key.

You can fetch your new PDS's recommendations for these by calling `com.atproto.identity.getRecommendedDidCredentials`. If you're interested in adding a personally held key to your rotation keys, this is a good time to do so.

If using a did:plc (as most accounts are), you can then request a signed PLC operation from your old PDS by passing the credentials through to `com.atproto.identity.signPlcOperation`. However, since this is a sensitive and possibly destructive operation, you'll need to fulfill an email challenge. To do so, simply call `com.atproto.identity.requestPlcOperationSignature` and send the provided token along with your request for a signed operation.

The operation you receive has the capability to update your PLC identity. Of course, you may submit it yourself to `https://plc.directory`. However, we strongly encourage you to submit it through your new PDS at `com.atproto.identity.submitPlcOperation`. Your new PDS will check the operation to ensure that it does not get your account into a bad state. We also encourage you to check the operation yourself.

If you are using a did:web or if your old PDS is not cooperating, you will need to take care of updating your DID yourself, either by updating the `.well-known` endpoint for your did:web or by signing a PLC operation with a rotation key that you possess.

### Finalizing the migration

After your identity is updated, you're nearly ready to go!

We recommend doing a final check of `com.atproto.server.checkAccountStatus` to ensure that everything looks in order.

After doing so, call `com.atproto.server.activateAccount` on your new PDS. It will ensure that your DID is set up correctly, activate your account, and send out events on its firehose noting that you updated your identity and published a new commit.

As a clean up step, you can deactivate or delete your account on your old PDS by calling `com.atproto.server.deleteAccount` or `com.atproto.server.deactivateAccount`. If doing the latter, you may provide an optional `deleteAfter` param that suggests to the server that it should hold onto your deactivated account until at least that date.

### After migration

After migrating, you should be good to start using the app as normal! You'll need to log out and log back in through your new PDS so that the client is talking to the correct service. It's possible that some services (such as feed generators) will have a stale DID cache and may not be able to accurately verify your auth tokens immediately. However, we've found that most services handle this gracefully, and those that don't should sort themselves out pretty quickly.