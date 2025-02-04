import Config

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base = System.get_env("SECRET_KEY_BASE") || raise "environment variable SECRET_KEY_BASE is missing"

  config :cors_plug,
    origin: String.split(System.get_env("CLIENTS_DOMAIN") || "", ","),
    max_age: 86400,
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH"]

  config :payment_web, PaymentWeb.Endpoint,
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    check_origin: String.split(System.get_env("CLIENTS_DOMAIN") || "", ","),
    server: true,
    secret_key_base: secret_key_base

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  #     config :payment_web, PaymentWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :payment_web, PaymentWeb.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

  config :payment,
    rabbitmq_opts: System.get_env("RABBITMQ_OPTS") ||
      raise("environment variable RABBITMQ_OPTS is missing"),
    client_rmq_routing_key: System.get_env("CLIENT_RMQ_ROUTING_KEY") ||
      raise("environment variable CLIENT_RMQ_ROUTING_KEY is missing"),
    zarinpal_merchant_id: System.get_env("ZARINPAL_MERCHANT_ID") ||
      raise("environment variable ZARINPAL_MERCHANT_ID is missing"),
    zarinpal_callback_base_url: System.get_env("ZARINPAL_CALLBACK_BASE_URL") ||
      raise("environment variable ZARINPAL_CALLBACK_BASE_URL is missing")

  db_name =       System.get_env("DATABASE_NAME") || raise "environment variable DATABASE_NAME is missing"
  db_username =   System.get_env("DATABASE_USERNAME") || raise "environment variable DATABASE_USERNAME is missing"
  db_password =   System.get_env("DATABASE_PASSWORD") || raise "environment variable DATABASE_PASSWORD is missing"
  db_endpoints =  String.split(System.get_env("DATABASE_ENDPOINTS") || "", ",") || raise "environment variable DATABASE_ENDPOINTS is missing"
  db_pool_size =  String.to_integer(System.get_env("POOL_SIZE") || "10")

  config :payment, Payment.Repo,
    username: db_username,
    password: db_password,
    database: db_name,
    endpoints: db_endpoints,
    show_sensitive_data_on_connection_error: true,
    pool_size: db_pool_size
end
