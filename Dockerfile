# This is just Example Dockerfile for Next.js with Prisma
# You can change it to your needs
FROM node:16 AS builder
LABEL builder=true
COPY ./src /workdir/src
WORKDIR /workdir/src
RUN npm install -g npm@9.3.1 &&\
     npm install --global yarn --force &&\
      npm install -g prisma && prisma generate
RUN yarn install
RUN yarn build

FROM node:16 AS server
LABEL builder=false
WORKDIR /build
RUN npm install -g npm@9.3.1 && npm install -g prisma
COPY --from=builder /workdir/src/package*.json /build
COPY --from=builder /workdir/src/next.config.js /build
COPY --from=builder /workdir/src/.next /build/.next
COPY --from=builder /workdir/src/public /build/public
COPY --from=builder /workdir/src/node_modules /build/node_modules
ENV NODE_ENV=production
EXPOSE 3000
CMD ["node_modules/.bin/next", "start"]
