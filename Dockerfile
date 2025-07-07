FROM node:20.11-alpine3.18 as build

RUN corepack enable

# Move files into the image and install
WORKDIR /app
COPY ./service ./
RUN corepack prepare --activate
RUN pnpm install --production --frozen-lockfile > /dev/null

# Uses assets from build stage to reduce build size
FROM node:20.11-alpine3.18

RUN apk add --update dumb-init

# Avoid zombie processes, handle signal forwarding
ENTRYPOINT ["dumb-init", "--"]

WORKDIR /app
COPY --from=build /app /app

EXPOSE 3000
ENV PDS_PORT=3000
ENV NODE_ENV=production
# potential perf issues w/ io_uring on this version of node
ENV UV_USE_IO_URING=0

CMD ["node", "--enable-source-maps", "index.js"]

LABEL org.opencontainers.image.source=https://github.com/gander-social/pds
LABEL org.opencontainers.image.description="AT Protocol PDS"
LABEL org.opencontainers.image.licenses=MIT
