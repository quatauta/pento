# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=alpine
# https://www.alpinelinux.org/releases/
ARG ELIXIR_VERSION="1.16.1"
ARG ERLANG_VERSION="26.2.2"
ARG ALPINE_VERSION="3.19.1"

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION}"
ARG RUNNER_IMAGE="alpine:${ALPINE_VERSION}"

ARG BUILDER_PACKAGES="build-base git"
ARG RUNNER_PACKAGES="libgcc libstdc++ ncurses-terminfo-base libncursesw ca-certificates openssl tini"

FROM ${BUILDER_IMAGE} as builder

# Install build dependencies
ARG BUILDER_PACKAGES
RUN --mount=type=cache,sharing=locked,target=/etc/apk/cache \
    apk update && apk upgrade && apk add ${BUILDER_PACKAGES}

# Prepare build dir
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --if-missing --force && mix local.rebar --if-missing --force

# Set build ENV
ENV MIX_ENV="prod"

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV && mix deps.clean --unused

# Copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
# Download and install esbuild & tailwindcss to _build/
# (versions are defined in config.exs).
RUN mkdir -p config
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix do deps.compile, esbuild.install, tailwind.install

# Deploy assets
COPY priv priv
COPY assets assets
RUN mix assets.deploy

# 
COPY lib lib
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

# Create mix release and remove *.plt (Dy
COPY rel rel
RUN mix release && find /app/_build/${MIX_ENV}/rel/pento -name "*.plt" -exec rm {} +

# Start a new build stage so that the final image will only contain
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

# Set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/pento ./

USER nobody

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/app/bin/server"]
