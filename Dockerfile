FROM alpine:3.13.1 as base_stage

LABEL maintainer="beardedeagle <randy@heroictek.com>"

# Important! Update this no-op ENV variable when this Dockerfile
# is updated with the current date. It will force refresh of all
# of the base images.
ENV REFRESHED_AT=2021-02-02 \
  MIX_HOME=/usr/local/lib/elixir/.mix \
  TERM=xterm \
  LANG=C.UTF-8

RUN set -xe \
  && apk --no-cache update \
  && apk --no-cache upgrade \
  && apk add --no-cache \
    bash \
    git \
    libstdc++ \
    openssl \
    zlib \
  && rm -rf /root/.cache \
  && rm -rf /var/cache/apk/* \
  && rm -rf /tmp/*

FROM base_stage as deps_stage

RUN set -xe \
  && apk add --no-cache --virtual .build-deps rsync

FROM beardedeagle/alpine-elixir-builder:1.11.3 as elixir_stage

FROM beardedeagle/alpine-node-builder:15.8.0 as node_stage

FROM deps_stage as stage

COPY --from=elixir_stage /usr/local /opt/elixir
COPY --from=node_stage /usr/local /opt/node

RUN set -xe \
  && rsync -a /opt/elixir/ /usr/local \
  && rsync -a /opt/node/ /usr/local \
  && apk del .build-deps \
  && rm -rf /root/.cache \
  && rm -rf /var/cache/apk/* \
  && rm -rf /tmp/*

FROM base_stage

RUN npm i -g meta \
    && alias deps.get="meta exec 'mix deps.get' --include-only=apps/control_financiero" \
    && alias deps.update="meta exec 'mix deps.update' --include-only=apps/control_financiero" \
    && alias run="meta exec 'sh run.sh' --include-only=apps/control_financiero"

COPY --from=stage /usr/local /usr/local

