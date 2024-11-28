FROM node:20.11-alpine3.19 as build

RUN npm install -g pnpm

# Move files into the image and install
WORKDIR /app
COPY ./service ./

# Install libvips (using vips-dev to get the pkg-config files) so we can have
# sharp use it instead of its built-in version.
RUN apk add --update vips-dev

# Packages required to build the C++ files that sharp will build to use the
# system libvips.
RUN apk add --update make gcc binutils g++

RUN pnpm install --production --frozen-lockfile > /dev/null

# Uses assets from build stage to reduce build size
FROM node:20.11-alpine3.19

RUN apk add --update dumb-init

# Avoid zombie processes, handle signal forwarding
ENTRYPOINT ["dumb-init", "--"]

WORKDIR /app
COPY --from=build /app /app

# Copy the libraries so libvips and the other dependecies needed by the sharp
# C++ files are available in the image.
COPY --from=build /usr/lib /usr/lib
COPY --from=build /lib /lib

EXPOSE 3000
ENV PDS_PORT=3000
ENV NODE_ENV=production
# potential perf issues w/ io_uring on this version of node
ENV UV_USE_IO_URING=0

CMD ["node", "--enable-source-maps", "index.js"]

LABEL org.opencontainers.image.source=https://github.com/bluesky-social/pds
LABEL org.opencontainers.image.description="AT Protocol PDS"
LABEL org.opencontainers.image.licenses=MIT
