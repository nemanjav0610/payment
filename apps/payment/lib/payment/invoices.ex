defmodule Payment.Invoices do
  @moduledoc """
  The Invoices context.
  """

  import Logger
  import Ecto.Query, warn: false

  alias Payment.Repo
  alias Payment.Invoices.Invoice

  @doc """
  Gets a single invoice.

  Raises `Ecto.NoResultsError` if the Invoice does not exist.

  ## Examples

      iex> get_invoice!(123)
      %Invoice{}

      iex> get_invoice!(456)
      ** (Ecto.NoResultsError)

  """
  def get_invoice(id) do
    aql =
    """
      FOR inv IN invoices
      FILTER inv._key == "#{id}"
      RETURN inv
    """

    case Repo.one(Invoice, aql) do
      nil -> {:error, :not_found}
      data -> {:ok, data}
    end

  rescue
    e ->
      IO.inspect e
      db_transaction_error("get_invoice/1")
      {:error, :service_unavailable}
  end

  @doc """
  Creates a invoice.

  ## Examples

      iex> create_invoice(%{field: value})
      {:ok, %Invoice{}}

      iex> create_invoice(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @invoice_expires_in :timer.hours(24)

  def create_invoice(attrs \\ %{}) do
    case %Invoice{} |> Invoice.create_changeset(attrs) |> Repo.prepare_changeset_for_insert do
      {:ok, document, _} ->
        aql =
          """
            LET pgs = (
              FOR pg IN payment_gateways
              FILTER pg.status == 1
              RETURN KEEP(pg, "_key", "name", "status", "code")
            )

            INSERT MERGE(
                #{Jason.encode!(document)},
                {expire_at: DATE_TIMESTAMP("#{document.inserted_at}") + #{@invoice_expires_in}}) IN invoices RETURN MERGE(NEW, {pgs: pgs})
          """

          {:ok, Repo.one(Invoice, aql)}

      other ->
        other
    end

  rescue
    e ->
      IO.inspect e
      db_transaction_error("create_invoice/1")
      {:error, :service_unavailable}
  end

  @doc """
  Expire invoices.

  ## Examples

      iex> expire_invoices()
      {:ok, 0}

      iex> expire_invoices()
      {:ok, 5}

  """
  def expire_invoices() do
    aql = """
      LET now_time = DATE_NOW()

      FOR inv IN invoices
      FILTER inv.expire_at < now_time
      FILTER inv.status == 0
      UPDATE inv WITH {
        status: -2,
        updated_at: DATE_ISO8601(now_time)
      }IN invoices RETURN KEEP(NEW, "_key")
    """

    case Repo.query(Invoice, aql) do
      nil -> {:ok, 0}
      data -> {:ok, length(data)}
    end

  rescue
    e ->
      IO.inspect e
      db_transaction_error("expire_invoices/0")
      {:error, :service_unavailable}
  end

  # =======================================================================================================================================
  # ======================================================= Private Functions =============================================================
  # =======================================================================================================================================

  defp db_transaction_error(func_name), do: Logger.error("Function[#{func_name}] DB transaction has error")
end
