defmodule Payment.Invoices.ExpiredInvoiceWorker do
  use GenServer

  alias Payment.Invoices
  import Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def init (opts) do
    scheduler()
    {:ok, opts}
  end

  def handle_info({:check_expired_invoice}, state) do
    case Invoices.expire_invoices() do
      {:ok, num} ->
        :ok
      {:error, status} ->
        Logger.error("#{__MODULE__}, check_expired_invoice has error, status -> #{status}")
    end

    scheduler()
    {:noreply, state}

  rescue
    e ->
      IO.inspect(e)
      Logger.error("#{__MODULE__} has error, status -> unhandled_error")
      {:noreply, state}
  end

  defp scheduler() do
    Process.send_after(self(), {:check_expired_invoice}, 1000)
  end
end
