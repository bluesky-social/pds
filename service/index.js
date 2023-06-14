"use strict";
const {
  PDS,
  Database,
  envToCfg,
  envToSecrets,
  readEnv,
} = require("@atproto/pds");

const main = async () => {
  const env = readEnv();
  const cfg = envToCfg(env);
  const secrets = envToSecrets(env);
  const pds = await PDS.create(cfg, secrets);
  if (cfg.db.dialect === "pg") {
    // Migrate using credentialed user
    const migrateDb = Database.postgres({
      url: cfg.db.migrationUrl,
      schema: cfg.db.schema,
    });
    await migrateDb.migrateToLatestOrThrow();
    await migrateDb.close();
  } else {
    await pds.ctx.db.migrateToLatestOrThrow();
  }
  await pds.start();
  // Graceful shutdown (see also https://aws.amazon.com/blogs/containers/graceful-shutdowns-with-ecs/)
  process.on("SIGTERM", async () => {
    await pds.destroy();
  });
};

main();
