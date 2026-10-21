# NOTE there is an additional build stage below that should match
FROM node:24.22-alpine3.23 AS build

RUN corepack enable

# Build goat binary
ENV CGO_ENABLED=0
ENV GODEBUG="netdns=go"
WORKDIR /tmp
RUN apk add --no-cache git go
RUN git clone https://github.com/bluesky-social/goat.git && cd goat && git checkout v0.2.2 && go build -o /tmp/goat-build .

# Move files into the image and install
WORKDIR /app
COPY ./service ./
RUN corepack prepare --activate
RUN pnpm install --production --frozen-lockfile > /dev/null

# Resolve through the PDS so this works with pnpm's isolated dependencies. Copy
# the standalone preload to a stable path and fail the build if it is missing.
RUN node -e "\
  const { copyFileSync } = require('node:fs'); \
  const { createRequire } = require('node:module'); \
  const pdsRequire = createRequire(require.resolve('@atproto/pds/package.json')); \
  copyFileSync(pdsRequire.resolve('@atproto-labs/fetch-node/emudhra-preload'), '/app/emudhra-preload.mjs'); \
"

# Uses assets from build stage to reduce build size
FROM node:24.22-alpine3.23

RUN apk add --update dumb-init

# Pick up CA bundle updates without waiting for an upstream node image rebuild
RUN apk upgrade --no-cache ca-certificates-bundle

# Avoid zombie processes, handle signal forwarding
COPY --chmod=755 ./docker-entrypoint.sh /usr/local/bin/pds-entrypoint
ENTRYPOINT ["dumb-init", "--", "pds-entrypoint"]

WORKDIR /app
COPY --from=build /app /app
COPY --from=build /tmp/goat-build /usr/local/bin/goat

EXPOSE 3000
ENV PDS_PORT=3000
ENV NODE_ENV=production
# potential perf issues w/ io_uring on this version of node
ENV UV_USE_IO_URING=0

CMD ["node", "--enable-source-maps", "index.ts"]

LABEL org.opencontainers.image.source=https://github.com/bluesky-social/pds
LABEL org.opencontainers.image.description="AT Protocol PDS"
LABEL org.opencontainers.image.licenses=MIT

# Indicates that the bundled @atproto/pds exposes "./telemetry", so operators who
# want metrics can load the OTel SDK with
# NODE_OPTIONS=--import=@atproto/pds/telemetry in pds.env (see monitoring/).
LABEL social.bsky.pds.telemetry="otel"
