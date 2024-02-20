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
  pds.app.get("/check-handle", checkHandleRoute);
  // Graceful shutdown (see also https://aws.amazon.com/blogs/containers/graceful-shutdowns-with-ecs/)
  process.on("SIGTERM", async () => {
    httpLogger.info("pds is stopping");
    await pds.destroy();
    httpLogger.info("pds is stopped");
  });
};

async function checkHandleRoute(
  /** @type {import('express').Request} */ req,
  /** @type {import('express').Response} */ res,
  /** @type {import('express').NextFunction} */ next
) {
  try {
    const { domain } = req.query;
    if (!domain || typeof domain !== "string") {
      return res.status(400).json({
        error: "InvalidRequest",
        message: "bad or missing domain query param",
      });
    }
    const isHostedHandle = pds.ctx.cfg.availableUserDomains.find((avail) =>
      domain.endsWith(avail)
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
    return res.json({ did: account.did, handle: account.handle });
  } catch {
    return res.status(500).json({
      error: "InternalServerError",
      message: "Internal Server Error",
    });
  }
}

main();
