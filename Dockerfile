FROM node:18-alpine as build

# Move files into the image and install
WORKDIR /app
COPY ./service ./
RUN yarn install --production --frozen-lockfile > /dev/null

# Uses assets from build stage to reduce build size
FROM node:18-alpine

RUN apk add --update dumb-init

# Avoid zombie processes, handle signal forwarding
ENTRYPOINT ["dumb-init", "--"]

WORKDIR /app
COPY --from=build /app /app

EXPOSE 3000
ENV PDS_PORT=3000
ENV NODE_ENV=production

CMD ["node", "--enable-source-maps", "index.js"]

LABEL org.opencontainers.image.source=https://github.com/bluesky-social/pds
LABEL org.opencontainers.image.description="ATP Personal Data Server (PDS)"
LABEL org.opencontainers.image.licenses=MIT
