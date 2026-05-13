"use strict";
const {
  PDS,
  envToCfg,
  envToSecrets,
  readEnv,
  httpLogger,
} = require("@atproto/pds");
const pkg = require("@atproto/pds/package.json");

const main = async () => {
  const env = readEnv();
  env.version ||= pkg.version;
  const cfg = envToCfg(env);
  const secrets = envToSecrets(env);
  const pds = await PDS.create(cfg, secrets);
  await pds.start();
  httpLogger.info("pds has started");
  
  pds.app.get("/tls-check", (req, res) => {
    checkHandleRoute(pds, req, res);
  });

  pds.app.get("/.well-known/webfinger", async (req, res) => {
    try {
      const resource = req.query.resource;
      if (!resource || typeof resource !== "string") {
        return res.status(400).json({ error: "missing resource parameter" });
      }

      const issuerUrl = process.env.PDS_OIDC_ISSUER_URL;
      if (!issuerUrl) {
        return res.status(404).json({ error: "webfinger not configured" });
      }

      // Parse acct: URI to extract the AT Proto handle.
      // Supports two formats:
      //   acct:alice.bsky.social@pds.example.com — handle is "alice.bsky.social"
      //   acct:alice.com — handle is "alice.com" (bare domain handle)
      const match = resource.match(/^acct:(.+)$/);
      if (!match) {
        return res.status(400).json({ error: "invalid resource format, expected acct: URI" });
      }

      const acct = match[1];
      const handle = acct.includes("@") ? acct.split("@")[0] : acct;

      const account = await pds.ctx.accountManager.getAccount(handle);
      if (!account) {
        return res.status(404).json({ error: "account not found" });
      }

      res.setHeader("Content-Type", "application/jrd+json");
      res.json({
        subject: resource,
        links: [{
          rel: "http://openid.net/specs/connect/1.0/issuer",
          href: issuerUrl
        }]
      });
    } catch (err) {
      httpLogger.error({ err }, "webfinger lookup failed");
      return res.status(500).json({ error: "internal server error" });
    }
  });

  // Graceful shutdown (see also https://aws.amazon.com/blogs/containers/graceful-shutdowns-with-ecs/)
  process.on("SIGTERM", async () => {
    httpLogger.info("pds is stopping");
    await pds.destroy();
    httpLogger.info("pds is stopped");
  });
};

async function checkHandleRoute(
  /** @type {PDS} */ pds,
  /** @type {import('express').Request} */ req,
  /** @type {import('express').Response} */ res
) {
  try {
    const { domain } = req.query;
    if (!domain || typeof domain !== "string") {
      return res.status(400).json({
        error: "InvalidRequest",
        message: "bad or missing domain query param",
      });
    }
    if (domain === pds.ctx.cfg.service.hostname) {
      return res.json({ success: true });
    }
    const isHostedHandle = pds.ctx.cfg.identity.serviceHandleDomains.find(
      (avail) => domain.endsWith(avail)
    );
    if (!isHostedHandle) {
      return res.status(400).json({
        error: "InvalidRequest",
        message: "handles are not provided on this domain",
      });
    }
    const account = await pds.ctx.accountManager.getAccount(domain);
    if (!account) {
      return res.status(404).json({
        error: "NotFound",
        message: "handle not found for this domain",
      });
    }
    return res.json({ success: true });
  } catch (err) {
    httpLogger.error({ err }, "check handle failed");
    return res.status(500).json({
      error: "InternalServerError",
      message: "Internal Server Error",
    });
  }
}

main();
