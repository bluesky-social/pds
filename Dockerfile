FROM node:20.11-alpine3.18 as build

RUN corepack enable

# Move files into the image and install
WORKDIR /app
COPY ./service ./
RUN corepack prepare --activate
RUN pnpm install --production --frozen-lockfile > /dev/null

# Uses assets from build stage to reduce build size
FROM node:20.11-alpine3.18

RUN apk add --update dumb-init \
    bash openssl jq ca-certificates curl gnupg jq \
    lsb-release openssl

RUN mkdir /tmp-scripts /config /pds
COPY ./scripts /tmp-scripts/
RUN chmod +x /tmp-scripts/*; \
    mv /tmp-scripts/* /bin/; \
    rmdir /tmp-scripts

# Avoid zombie processes, handle signal forwarding
ENTRYPOINT ["dumb-init", "--"]

WORKDIR /app
COPY --from=build /app /app

EXPOSE 3000
ENV PDS_ENV_FILE=/config/pds.env
ENV PDS_PORT=3000
ENV NODE_ENV=production
# potential perf issues w/ io_uring on this version of node
ENV UV_USE_IO_URING=0

CMD ["node", "--enable-source-maps", "index.js"]

LABEL org.opencontainers.image.source=https://github.com/samanthavbarron/pds
LABEL org.opencontainers.image.description="AT Protocol PDS"
LABEL org.opencontainers.image.licenses=MIT
