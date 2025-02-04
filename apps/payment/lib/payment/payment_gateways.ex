defmodule Payment.PaymentGateways do
  @moduledoc """
  The PaymentGateways context.
  """

  import Ecto.Query, warn: false
  import Logger

  alias Payment.Repo
  alias Payment.PaymentGateways.PaymentGateway

  @doc """
  Returns the list of payment_gateways.

  ## Examples

      iex> list_payment_gateways()
      [%PaymentGateway{}, ...]

  """
  def list_payment_gateways() do
    aql = """
      FOR pg IN payment_gateways
      FILTER pg.status == 1
      RETURN pg
    """
    Repo.all(PaymentGateway, aql)

  rescue
    e ->
      IO.inspect e
      db_transaction_error("list_payment_gateways/0")
      {:error, :service_unavailable}
  end

  defp db_transaction_error(func_name), do: Logger.error("Function[#{func_name}] DB transaction has error")
end
