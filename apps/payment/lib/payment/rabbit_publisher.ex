defmodule Payment.RabbitPublisher do
  use GenServer
  use AMQP

  @exchange "payment.direct"

  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def init(opts) do
    {:ok, conn} = AMQP.Connection.open(opts)
    {:ok, chan} = AMQP.Channel.open(conn)

    # Setup exchange
    setup_exchange(chan)
    Logger.info("#{__MODULE__} Connect to rabbitmq sucessfully")
    {:ok, chan}

  rescue
    _ ->
      Logger.error("#{__MODULE__} Can't connect to rabbit")
      {:stop, :unauthorized}
  end

  def send_msg(params) do
    case GenServer.call(__MODULE__, {:send_msg, params}) do
      {:sent} ->
        {:ok, :sent}
      {status} ->
        {:error, status}
    end

  rescue
    _ ->
      Logger.error("#{__MODULE__} Can't send msg to rabbit")
      {:error, :bad_msg}
  end

  def handle_call({:send_msg, {route, msg}}, _from, chan) do
    case prepare_msg(msg) do
      {:ok, encoded_msg} ->
        AMQP.Basic.publish(chan, @exchange, route, encoded_msg, persistent: true)
        {:reply, {:sent}, chan}
      _ ->
        {:reply, {:bad_msg}, chan}
    end

  rescue
    e ->
      IO.inspect e
      Logger.error("#{__MODULE__} Can't send msg to rabbit")
      {:error, :bad_topic}
  end

  def handle_call(_msg, _from, chan) do
    {:reply, {:unknown_msg}, chan}
  end

  # tools

  defp prepare_msg(msg), do: Jason.encode(msg)
  defp setup_exchange(chan), do: AMQP.Exchange.declare(chan, @exchange, :direct)
end
