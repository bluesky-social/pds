FROM node:20.19-alpine3.22 as build

RUN corepack enable

# Build goat binary
ENV CGO_ENABLED=0
ENV GODEBUG="netdns=go"
WORKDIR /tmp
RUN apk add --no-cache git go
RUN git clone https://github.com/bluesky-social/goat.git && cd goat && git checkout v0.1.2 && go build -o /tmp/goat-build .

# Move files into the image and install
WORKDIR /app
COPY ./service ./
RUN corepack prepare --activate
RUN pnpm install --production --frozen-lockfile > /dev/null

# Uses assets from build stage to reduce build size
FROM node:20.19-alpine3.22

RUN apk add --update dumb-init

# Avoid zombie processes, handle signal forwarding
ENTRYPOINT ["dumb-init", "--"]

WORKDIR /app
COPY --from=build /app /app
COPY --from=build /tmp/goat-build /usr/local/bin/goat

EXPOSE 3000
ENV PDS_PORT=3000
ENV NODE_ENV=production
# potential perf issues w/ io_uring on this version of node
ENV UV_USE_IO_URING=0

CMD ["node", "--enable-source-maps", "index.js"]

LABEL org.opencontainers.image.source=https://github.com/bluesky-social/pds
LABEL org.opencontainers.image.description="AT Protocol PDS"
LABEL org.opencontainers.image.licenses=MIT
