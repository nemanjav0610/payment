defmodule Payment.Transactions.VerifiedTxConsumer do
  use Broadway

  require Logger
  alias Broadway.Message
  alias Payment.Transactions
  alias Payment.RabbitPublisher

  def start_link(opts) do
    rabbitmq_opts = Keyword.get(opts, :rabbitmq_opts) |> URI.parse()
    [username, password] = String.split(rabbitmq_opts.userinfo, ":")

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {BroadwayRabbitMQ.Producer,
          queue: "verified_txs",
          declare: [
            durable: true
          ],
          bindings: [
            {"payment.direct", [routing_key: "verified_tx"]}
          ],
          on_failure: :reject_and_requeue,
          connection: [
            username: username,
            password: password,
            host: rabbitmq_opts.host,
            port: rabbitmq_opts.port
          ],
          qos: [
            prefetch_count: 1,
          ]
        },
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 5
        ]
      ]
    )
  end

  def handle_message(_, %Message{data: encoded_data} = message, _) do
    data = Jason.decode!(encoded_data, keys: :atoms)
    client_rmq_routing_key = Application.get_env(:payment, :client_rmq_routing_key)

    case Transactions.verify_transactions(data.transaction, data.pg_response) do
      {:ok, invoice} ->
        RabbitPublisher.send_msg({client_rmq_routing_key, invoice})
        message

      {:error, status} ->
        Logger.error("#{__MODULE__}, Msg processing failed, reason -> #{status}")
        Message.failed(message, status)
    end

  rescue
    e ->
      IO.inspect(e)
      Logger.error("#{__MODULE__}, Msg processing failed, reason -> unhandled_error")
      Message.failed(message, :unhandled_error)
  end
end
