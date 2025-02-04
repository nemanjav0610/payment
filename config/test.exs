import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :arango, Arango.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "arango_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :payment_web, PaymentWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ThNsyuUPVqP/nkVmQ+nZ8dWYPrxG+2zQi9essHPqngr6LpUhHP6k7votQWTI5dQz",
  server: false

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :payment, Payment.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "payment_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
