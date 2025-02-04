defmodule Payment.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Payment.Repo,
      {Payment.RabbitPublisher, Application.get_env(:payment, :rabbitmq_opts)},
      Payment.Invoices.ExpiredInvoiceWorker,
      Payment.Transactions.ExpiredTxWorker,
      {Payment.Transactions.VerifiedTxConsumer, [rabbitmq_opts: Application.get_env(:payment, :rabbitmq_opts)]},
      # Start the PubSub system
      {Phoenix.PubSub, name: Payment.PubSub}
      # Start a worker by calling: Payment.Worker.start_link(arg)
      # {Payment.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Payment.Supervisor)
  end
end
