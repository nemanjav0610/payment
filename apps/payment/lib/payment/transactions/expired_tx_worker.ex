defmodule Payment.Transactions.ExpiredTxWorker do
  use GenServer

  alias Payment.PaymentGateways.Zarinpal
  alias Payment.Transactions

  import Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def init (opts) do
    scheduler()
    {:ok, opts}
  end

  def handle_info({:check_expired_transaction}, state) do
    case Transactions.get_expired_transaction() do
      {:ok, :empty} ->
        scheduler()
        {:noreply, state}

      {:ok, data} ->
        poison_task = Task.async(fn -> verifying_tx(data) end)
        case Task.await(poison_task, 10_000) do
          {:ok, body} ->
            Transactions.verify_transactions(data, body)

          {:error, :pg, %{data: [], errors: %{code: -51}} = body} ->
            Transactions.expired_transaction_was_failed(data, body)

          {:error, :pg, %{data: [], errors: %{code: code}}} ->
            Logger.error("#{__MODULE__}, Expired Transaction[#{data._key}] has error, code -> #{code}")

          {:error, :poison, status} ->
            Logger.error("#{__MODULE__}, Expired Transaction[#{data._key}] has error, status -> #{status}")
        end

        scheduler()
        {:noreply, state}

      {:error, status} ->
        scheduler()
        Logger.error("#{__MODULE__}, get_expired_transaction has error, status -> #{status}")
        {:noreply, state}
    end

  rescue
    e ->
      IO.inspect(e)
      Logger.error("#{__MODULE__} has error, status -> task was timeout")
      {:noreply, state}
  end

  defp scheduler() do
    Process.send_after(self(), {:check_expired_transaction}, 1000)
  end

  defp verifying_tx(data) do
    try do
      Zarinpal.verify_zarinpal_authority(data)
    catch
      _, _ -> {:error, :poison, :task_poison_terminated}
    end
  end
end
