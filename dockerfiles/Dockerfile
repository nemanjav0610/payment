FROM elixir:1.13.1-alpine as builder

WORKDIR /app

# Install Hex + Rebar
RUN mix do local.hex --force, local.rebar --force
RUN set -eux
RUN apk add git

# Set envs
ENV MIX_ENV=prod

# First Copy
COPY mix.exs /app/
COPY mix.* /app/
COPY apps/arango/mix.exs /app/apps/arango/
COPY apps/payment/mix.exs /app/apps/payment/
COPY apps/payment_web/mix.exs /app/apps/payment_web/

RUN mix do deps.get --only prod

COPY config/ /app/config/
RUN MIX_ENV=prod mix do deps.compile

# Install assets packages
# WORKDIR /app/apps/payment_web
# COPY apps/payment_web/assets/package*.json /app/apps/payment_web/assets/
# RUN MIX_ENV=prod mix compile
# && cd assets && yarn install --production=true

FROM elixir:1.13.1-alpine as rel

RUN MIX_ENV=prod mix do local.hex --force, local.rebar --force

WORKDIR /app
RUN chown nobody /app
RUN apk add git

# USER nobody

ENV MIX_ENV=prod
ARG VERSION

COPY --from=builder --chown=nobody:root /app/ /app/

# Final copy
COPY apps/arango/ /app/apps/arango/
COPY apps/payment/ /app/apps/payment/
COPY apps/payment_web/ /app/apps/payment_web/

RUN MIX_ENV=prod mix compile && mix release

# Start server
WORKDIR /app/_build/prod/rel/payment_backend/bin
CMD ["./payment_backend", "start"]

FROM elixir:1.13.1-alpine

RUN set -eux \
    & apk add \
        --no-cache \
        bash 

WORKDIR /app
RUN chown nobody /app
COPY --from=rel --chown=nobody:root /app/_build/prod/rel/payment_backend /app/

CMD ["./bin/payment_backend", "start"]
