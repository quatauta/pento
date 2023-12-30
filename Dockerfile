# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=alpine
# https://www.alpinelinux.org/releases/
ARG ELIXIR_VERSION="1.16.0"
ARG ERLANG_VERSION="26.2.1"
ARG ALPINE_VERSION="3.18.4"

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION}"
ARG RUNNER_IMAGE="alpine:${ALPINE_VERSION}"

ARG BUILDER_PACKAGES="build-base git"
ARG RUNNER_PACKAGES="libgcc libstdc++ ncurses-terminfo-base libncursesw ca-certificates openssl tini"

FROM ${BUILDER_IMAGE} as builder

# install build dependencies
ARG BUILDER_PACKAGES
RUN --mount=type=cache,sharing=locked,target=/etc/apk/cache \
    apk update && apk upgrade && apk add ${BUILDER_PACKAGES}

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN --mount=type=cache,sharing=locked,target=/root/.mix \
    --mount=type=cache,sharing=locked,target=/app/deps \
    --mount=type=cache,sharing=locked,target=/app/_build \
    mix local.hex --if-missing --force && mix local.rebar --if-missing --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN --mount=type=cache,sharing=locked,target=/root/.mix \
    --mount=type=cache,sharing=locked,target=/app/deps \
    --mount=type=cache,sharing=locked,target=/app/_build \
    mix deps.get --only $MIX_ENV && mix deps.clean --unused

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
RUN mkdir -p config
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN --mount=type=cache,sharing=locked,target=/root/.mix \
    --mount=type=cache,sharing=locked,target=/app/_build \
    --mount=type=cache,sharing=locked,target=/app/deps \
    mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

RUN --mount=type=cache,sharing=locked,target=/root/.mix \
    --mount=type=cache,sharing=locked,target=/app/_build \
    --mount=type=cache,sharing=locked,target=/app/deps \
    mix assets.deploy && mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN --mount=type=cache,sharing=locked,target=/root/.mix \
    --mount=type=cache,sharing=locked,target=/app/_build \
    --mount=type=cache,sharing=locked,target=/app/deps \
    mix release && cp -a /app/_build/${MIX_ENV}/rel/pento /app/rel_pento/
RUN mkdir -p /app/_build/${MIX_ENV}/rel/ && \
    mv /app/rel_pento/ /app/_build/${MIX_ENV}/rel/pento && \
    find /app/_build/${MIX_ENV}/rel/pento -name "*.plt" -exec rm {} +

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

ARG RUNNER_PACKAGES
RUN --mount=type=cache,sharing=locked,target=/etc/apk/cache \
    apk update && apk upgrade && apk add ${RUNNER_PACKAGES}

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/pento ./

USER nobody

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/app/bin/server"]
