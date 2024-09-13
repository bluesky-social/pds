# Account Migration 

### ⚠️ Warning ⚠️ ️
Account migration is a potentially destructive operation. Part of the operation involves signing away your old PDS's ability to make updates to your DID. If something goes wrong, you could be permanently locked out of your account, and Bluesky will not be able to help you recover it. 

Therefore, we do not recommend migrating your primary account yet. And we specifically recommend _against_ migrating your main account if you do not understand how PLC operations work.

Also, the Bluesky PDS is not currently accepting incoming migrations (it will in the future). Therefore this is currently a one-way street. If you migrate off of `bsky.social`, _you will not be able to return_. However, you will be able to migrate between other PDSs.

![Diagram of account migration flow](https://raw.githubusercontent.com/bluesky-social/pds/main/assets/account-migration.png)

Account Migration occurs in 4 main steps:
- Creating an account on the new PDS
- Migrating data from the old PDS to the new PDS
- Updating identity to point to the new PDS
- Finalizing the migration


### Creating an Account

In order to create an account, you first need to prove to the new PDS that you're in control of the DID that you're attempting to register as.

To do so, you need a JWT signed with the signing key associated with your DID. You can obtain this through calling `com.atproto.server.getServiceAuth` from your old PDS. If your old PDS is not willing to provide the authentication token, you will need to update your DID document to point to a signing key that you possess in order to mint an authentication token yourself.

With this JWT set as a Bearer token, you can then create an account on the new PDS by calling `com.atproto.server.createAccount`. You'll need to fulfill any challenges that the new PDS requires - such as an invite code. 

After creating an account, you'll have a signing key on the new PDS and an empty repository. Your account will be in a "deactivated" state such that it is not usable yet.

### Migrating data

Now that you have an account on the new PDS, you can start migrating data into it. After creating your account, you will have received an access token for the new PDS and it will be required for all incoming data.

First, you can grab your entire repository in the form of a [CAR file](https://ipld.io/specs/transport/car/carv1/) by calling `com.atproto.sync.getRepo`. You can then upload those exact bytes to your new PDS through `com.atproto.repo.importRepo`. The new PDS will parse the CAR file, index all blocks and records, and sign a new commit for the repository.

Next, you'll need to upload all relevant blobs. These can be discovered by calling `com.atproto.sync.listBlobs` on your old PDS. For each blob, you'll need to download the contents through `com.atproto.sync.getBlob` and upload them to your new PDS through `com.atproto.repo.uploadBlob`. 

Finally, you'll need to migrate private state. Currently the only private state held on your PDS is your preferences. You can migrate this by calling `app.bsky.actor.getPreferences` on your old PDS, and submitting the results to `app.bsky.actor.putPreferences` on your new PDS.

At any point during this process, you can check the status of your new account by calling `com.atproto.server.checkAccountStatus` which will inform you of your repo state, how many records are indexed, how many private state values are stored, how many blobs it is expecting (based on parsing records), and how many blobs have been uploaded. If you find you are missing blobs and are not sure which, you may use `com.atproto.repo.listMissingBlobs` on your new PDS to find them.

### Updating identity

After your data has been migrated to your new PDS, you'll need to update your DID to point to the correct credentials - handle, pds endpoint, signing key, and (if using a did:plc) the new PDS's rotation key.

You can fetch your new PDS's recommendations for these by calling `com.atproto.identity.getRecommendedDidCredentials`. If using a did:plc, we recommend taking this chance to generate a new rotation key and adding it to the list of recommended rotation keys that comes from your new PDS.

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


## Example Code

The below Typescript code gives an example of how this account migration flow may function. Please note that it is for documentation purposes only and can not be run exactly as is as there is an out-of-band step where you need to get a confirmation token from your email.

It also does not handle some of the more advanced steps such as verifying a full import, looking for missing blobs, adding your own recovery key, or validating the PLC operation itself.

```ts
import AtpAgent from '@atproto/api'
import { Secp256k1Keypair } from '@atproto/crypto'
import * as ui8 from 'uint8arrays'

const OLD_PDS_URL = 'https://bsky.social'
const NEW_PDS_URL = 'https://example.com'
const CURRENT_HANDLE = 'to-migrate.bsky.social'
const CURRENT_PASSWORD = 'password'
const NEW_HANDLE = 'migrated.example.com'
const NEW_ACCOUNT_EMAIL = 'migrated@example.com'
const NEW_ACCOUNT_PASSWORD = 'password'
const NEW_PDS_INVITE_CODE = 'example-com-12345-abcde'

const migrateAccount = async () => {
  const oldAgent = new AtpAgent({ service: OLD_PDS_URL })
  const newAgent = new AtpAgent({ service: NEW_PDS_URL })

  await oldAgent.login({
    identifier: CURRENT_HANDLE,
    password: CURRENT_PASSWORD,
  })

  const accountDid = oldAgent.session?.did
  if (!accountDid) {
    throw new Error('Could not get DID for old account')
  }

  // Create account
  // ------------------

  const describeRes = await newAgent.api.com.atproto.server.describeServer()
  const newServerDid = describeRes.data.did

  const serviceJwtRes = await oldAgent.com.atproto.server.getServiceAuth({
    aud: newServerDid,
    lxm: 'com.atproto.server.createAccount',
  })
  const serviceJwt = serviceJwtRes.data.token

  await newAgent.api.com.atproto.server.createAccount(
    {
      handle: NEW_HANDLE,
      email: NEW_ACCOUNT_EMAIL,
      password: NEW_ACCOUNT_PASSWORD,
      did: accountDid,
      inviteCode: NEW_PDS_INVITE_CODE,
    },
    {
      headers: { authorization: `Bearer ${serviceJwt}` },
      encoding: 'application/json',
    },
  )
  await newAgent.login({
    identifier: NEW_HANDLE,
    password: NEW_ACCOUNT_PASSWORD,
  })

  // Migrate Data
  // ------------------

  const repoRes = await oldAgent.com.atproto.sync.getRepo({ did: accountDid })
  await newAgent.com.atproto.repo.importRepo(repoRes.data, {
    encoding: 'application/vnd.ipld.car',
  })

  let blobCursor: string | undefined = undefined
  do {
    const listedBlobs = await oldAgent.com.atproto.sync.listBlobs({
      did: accountDid,
      cursor: blobCursor,
    })
    for (const cid of listedBlobs.data.cids) {
      const blobRes = await oldAgent.com.atproto.sync.getBlob({
        did: accountDid,
        cid,
      })
      await newAgent.com.atproto.repo.uploadBlob(blobRes.data, {
        encoding: blobRes.headers['content-type'],
      })
    }
    blobCursor = listedBlobs.data.cursor
  } while (blobCursor)

  const prefs = await oldAgent.api.app.bsky.actor.getPreferences()
  await newAgent.api.app.bsky.actor.putPreferences(prefs.data)

  // Migrate Identity
  // ------------------

  const recoveryKey = await Secp256k1Keypair.create({ exportable: true })
  const privateKeyBytes = await recoveryKey.export()
  const privateKey = ui8.toString(privateKeyBytes, 'hex')

  await oldAgent.com.atproto.identity.requestPlcOperationSignature()

  const getDidCredentials =
    await newAgent.com.atproto.identity.getRecommendedDidCredentials()
  const rotationKeys = getDidCredentials.data.rotationKeys ?? []
  if (!rotationKeys) {
    throw new Error('No rotation key provided')
  }
  const credentials = {
    ...getDidCredentials.data,
    rotationKeys: [recoveryKey.did(), ...rotationKeys],
  }

  // @NOTE, this token will need to come from the email from the previous step
  const TOKEN = ''

  const plcOp = await oldAgent.com.atproto.identity.signPlcOperation({
    token: TOKEN,
    ...credentials,
  })

  console.log(
    `❗ Your private recovery key is: ${privateKey}. Please store this in a secure location! ❗`,
  )

  await newAgent.com.atproto.identity.submitPlcOperation({
    operation: plcOp.data.operation,
  })

  // Finalize Migration
  // ------------------

  await newAgent.com.atproto.server.activateAccount()
  await oldAgent.com.atproto.server.deactivateAccount({})
}

```
