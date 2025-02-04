defmodule Payment.Transactions do
  @moduledoc """
  The Transactions context.
  """

  import Logger
  import Ecto.Query, warn: false

  alias Payment.Repo
  alias Payment.Transactions.Transaction
  alias Payment.Invoices.Invoice
  alias Payment.RabbitPublisher
  alias Payment.PaymentGateways.Zarinpal

  @doc """
  Gets a single transaction.

  Raises `Ecto.NoResultsError` if the Transaction does not exist.

  ## Examples

      iex> get_transaction!(123)
      %Transaction{}

      iex> get_transaction!(456)
      ** (Ecto.NoResultsError)

  """
  def get_transaction(id) do
    aql =
    """
      FOR tran IN transactions
      FILTER tran._key == "#{id}"
      LET pagay = (
        FOR pg IN payment_gateways
        FILTER pg.code == tran.pg_code
        FILTER pg.status == 1
        RETURN KEEP(pg, "_key", "name", "status", "code")
      )
      RETURN MERGE(tran, {pg: pagay[0]})
    """
    case Repo.one(Transaction, aql) do
      nil -> {:error, :not_found}
      data -> {:ok, data}
    end

  rescue
    e ->
      IO.inspect e
      db_transaction_error("get_transaction/1")
      {:error, :service_unavailable}
  end

  @doc """
  Creates a transaction.

  ## Examples

      iex> create_transaction(%{field: value})
      {:ok, %Transaction{}}

      iex> create_transaction(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_transaction(attrs \\ %{}) do
    case %Transaction{} |> Transaction.init_changeset(attrs) |> Repo.prepare_changeset_for_insert do
      {:ok, document, _} ->
        aql_invoice = """
          LET invoice = (
            FOR inv IN invoices
            FILTER inv._key == "#{document.invoice_id}"
            RETURN inv
          )

          LET pagay = (
            FOR pg IN payment_gateways
            FILTER pg.code == #{document.pg_code}
            FILTER pg.status == 1
            RETURN KEEP(pg, "_key", "name", "status", "code")
          )

          LET resp = (
            invoice != [] ? (
              invoice[0].status == 0 AND pagay != [] ? (
                MERGE(invoice[0], {db_msg: "ok", pg: pagay[0]})
              ) : invoice[0].status == 2 ? (
                MERGE(invoice[0], {db_msg: "accepted"})
              ) : (
                {db_msg: "method_not_allowed"}
              )
            ) : (
            {db_msg: "not_found"}
            )
          )

          RETURN resp
        """
        case Repo.one(aql_invoice) do
          %{db_msg: "ok"} = invoice ->
            case Zarinpal.get_authority_code_from_zarinpal(invoice) do
              {:ok, body} ->
                aql_transaction = """
                  LET now_time = DATE_NOW()

                  LET invoice = (
                    FOR inv IN invoices
                    FILTER inv._key == "#{invoice._key}"
                    RETURN inv
                  )

                  LET insert_transactoion = (
                    (invoice[0].status == 0) AND ((now_time + #{tx_expirtion_time(document.pg_code)}) < (invoice[0].expire_at - 60000))? (
                      [
                        {
                          invoice_id: invoice[0]._key,
                          description: invoice[0].description,
                          payable: invoice[0].payable,
                          authority: "#{body.data.authority}",
                          pg_url: "#{Zarinpal.zarinpal_payment_page_url(body.data.authority)}",
                          status: 0,
                          vretry_count: 0,
                          last_vretry_time: null,
                          pg_code: #{document.pg_code},
                          inserted_at: DATE_ISO8601(now_time),
                          updated_at: DATE_ISO8601(now_time),
                          expire_at: now_time + #{tx_expirtion_time(document.pg_code)}
                        }
                      ]
                    ) : (
                      []
                    )
                  )

                  LET new_transaction = (
                    FOR in_tran IN insert_transactoion
                    INSERT in_tran IN transactions RETURN NEW
                  )

                  LET new_transaction_log = (
                      FOR in_tran_h IN new_transaction
                      INSERT {
                        transaction_id: in_tran_h._key,
                        type: 0,
                        data: {
                          new: in_tran_h,
                          old: {}
                        },
                        inserted_at: DATE_ISO8601(now_time),
                        updated_at: DATE_ISO8601(now_time)
                      } IN transactions_history RETURN KEEP(NEW, "_key")
                  )

                  LET update_invoice = (
                    invoice[0].status == 0 AND new_transaction != [] ? (
                      [{
                        _key: invoice[0]._key,
                        status: 2,
                        current_tx_id: new_transaction[0]._key,
                        updated_at: DATE_ISO8601(now_time)
                      }]
                    ) : (
                      []
                    )
                  )

                  LET updated_invoice = (
                    FOR up_inv IN update_invoice
                    UPDATE up_inv IN invoices RETURN KEEP(NEW, "_key")
                  )

                  LET pagay = (
                    FOR pg IN payment_gateways
                    FILTER pg.code == new_transaction[0].pg_code
                    RETURN KEEP(pg, "_key", "name", "status", "code")
                  )

                  LET resp = (
                    invoice != [] ? (
                      update_invoice != [] AND new_transaction != [] AND new_transaction_log != []? (
                        MERGE(new_transaction[0], {db_msg: "created", pg: pagay[0]})
                      ) : (
                        {db_msg: "method_not_allowed"}
                      )
                    ) : (
                    {db_msg: "not_found"}
                    )
                  )

                  RETURN resp
                """

                case Repo.one(Transaction, aql_transaction) do
                  %Transaction{db_msg: "created"} = transaction ->  {:ok, transaction}
                  %Transaction{db_msg: db_msg} -> {:error, String.to_atom(db_msg)}
                end

              {:error, _, _} ->
                {:error, :bad_gateway}
            end

          %{db_msg: "accepted"} = invoice ->
              aql_transaction1 = """
               FOR tran IN transactions
               FILTER tran._key == "#{invoice.current_tx_id}"
               FILTER tran.status == 0
               LET pagay = (
                FOR pg IN payment_gateways
                FILTER pg.code == tran.pg_code
                RETURN KEEP(pg, "_key", "name", "status", "code")
               )
               RETURN MERGE(tran, {db_msg: "accepted", pg: pagay[0]})
              """

              case Repo.one(Transaction, aql_transaction1) do
                nil -> {:error, :not_acceptable}
                transaction -> {:ok, transaction}
              end

          %{db_msg: db_msg} ->
            {:error, String.to_atom(db_msg)}
        end

      other ->
        other
    end

  rescue
    e ->
      IO.inspect e
      db_transaction_error("create_transaction/1")
      {:error, :service_unavailable}
  end

  def validate_zarinpal_transaction(authority) do
    aql = """
      FOR tran IN transactions
      FILTER tran.authority == "#{authority}"
      RETURN tran
    """

    case Repo.one(aql) do
      nil -> {:error, :not_found}
      data ->
        case Zarinpal.verify_zarinpal_authority(data) do
          {:ok, body} ->
            RabbitPublisher.send_msg({"verified_tx", %{transaction: data, pg_response: body}})
            {:ok, :paid}
          {:error, :pg, _body} -> {:error, :bad_request}
          {:error, :poison, status} -> {:error, status}
        end
    end

  rescue
    e ->
      IO.inspect e
      db_transaction_error("validate_zarinpal_transaction/1")
      {:error, :service_unavailable}
  end

  def verify_transactions(data, pg_response) do
    aql = """
      LET now_time = DATE_NOW()

      LET tx = (
        FOR tran IN transactions
        FILTER tran._key == "#{data._key}"
        FILTER tran.invoice_id == "#{data.invoice_id}"
        FILTER tran.payable == "#{data.payable}"
        RETURN tran
      )

      LET invoice = (
        FOR inv IN invoices
        FILTER inv._key == "#{data.invoice_id}"
        FILTER inv.current_tx_id == "#{data._key}"
        RETURN inv
      )

      LET tx_update = (
        (tx != [] AND tx[0].status == 0) AND (invoice != [] AND invoice[0].status == 2) ? (
          [{
            _key: "#{data._key}",
            status: 1,
            card_hash: "#{pg_response.data.card_hash}",
            card_pan: "#{pg_response.data.card_pan}",
            tracking_id: #{pg_response.data.ref_id},
            metadata: {
              pg_response: #{Jason.encode!(pg_response)}
            },
            updated_at: DATE_ISO8601(now_time)
          }]
        ) : (
          []
        )
      )

      LET inv_update = (
        (tx != [] AND tx[0].status == 0) AND (invoice != [] AND invoice[0].status == 2) ? (
          [{
            _key: "#{data.invoice_id}",
            status: 1,
            updated_at: DATE_ISO8601(now_time)
          }]
        ) : (
          []
        )
      )

      LET updated_tx = (
        FOR up_tx IN tx_update
        UPDATE up_tx IN transactions RETURN NEW
      )

      LET new_transaction_log = (
        FOR up_tran_h IN updated_tx
        INSERT {
          transaction_id: up_tran_h._key,
          type: 1,
          data: {
            new: up_tran_h,
            old: tx[0]
          },
          inserted_at: DATE_ISO8601(now_time),
          updated_at: DATE_ISO8601(now_time)
        } IN transactions_history RETURN KEEP(NEW, "_key")
      )

      LET updated_inv = (
        FOR up_inv IN inv_update
        UPDATE up_inv IN invoices RETURN NEW
      )

      LET resp = (
        updated_tx != [] AND updated_inv != [] AND new_transaction_log != [] ? (
          MERGE(updated_tx[0], {db_msg: "inv_tx_updated"})
        ) : tx[0].status == 1 AND invoice[0].status == 1 ? (
          {db_msg: "inv_tx_updated"}
        ) : (
          {db_msg: "unknown_error"}
        )
      )
      RETURN resp

    """

    case Repo.one(Transaction, aql) do
      %Transaction{db_msg: "inv_tx_updated"} ->
        {:ok, :done}
        inv_aql = """
          FOR inv IN invoices
          FILTER inv._key == "#{data.invoice_id}"
          FILTER inv.status == 1
          RETURN inv
        """

        case Repo.one(inv_aql) do
          nil -> {:error, :not_found}
          data -> {:ok, data}
        end

      %Transaction{db_msg: db_msg} -> {:error, String.to_atom(db_msg)}
    end

  rescue
    e ->
      IO.inspect e
      db_transaction_error("verify_transactions/1")
      {:error, :service_unavailable}
  end

  def get_expired_transaction() do
    aql = """
      LET now_time = DATE_NOW()

      LET tx = (
        FOR tran IN transactions
        FILTER tran.expire_at < now_time
        FILTER tran.status == 0
        FILTER (tran.vretry_count < 5) OR ((tran.vretry_count >= 5 AND tran.vretry_count < 10) AND ((now_time - tran.last_vretry_time) > 1800000))
        SORT tran.vretry_count ASC
        LIMIT 1
        RETURN tran
      )

      LET update_tx = (
        tx != [] ? (
          [{
            _key: tx[0]._key,
            vretry_count: tx[0].vretry_count + 1,
            last_vretry_time: now_time,
            updated_at: DATE_ISO8601(now_time)
          }]
        ) : (
          []
        )
      )

      LET updated_tx = (
        FOR up_tx IN update_tx
        UPDATE up_tx IN transactions RETURN NEW
      )

      LET new_transaction_log = (
        FOR up_tran_h IN updated_tx
        INSERT {
          transaction_id: up_tran_h._key,
          type: 2,
          data: {
            new: up_tran_h,
            old: tx[0]
          },
          inserted_at: DATE_ISO8601(now_time),
          updated_at: DATE_ISO8601(now_time)
        } IN transactions_history RETURN KEEP(NEW, "_key")
      )

      LET resp = (
        tx != [] ? (
          updated_tx != [] ? (
            MERGE(updated_tx[0], {db_msg: "updated"})
          ) : (
            {db_msg: "unknown"}
          )
        ) : (
          {db_msg: "empty"}
        )
      )

      RETURN resp
    """

    case Repo.one(Transaction, aql) do
      nil -> {:ok, :empty}
      %Transaction{db_msg: "empty"} = transaction -> {:ok, :empty}
      %Transaction{db_msg: "updated"} = transaction -> {:ok, transaction}
      %Transaction{db_msg: db_msg} -> {:error, String.to_atom(db_msg)}
    end

  rescue
    e ->
      IO.inspect e
      db_transaction_error("get_expired_transaction/1")
      {:error, :service_unavailable}
  end

  def expired_transaction_was_failed(data, pg_response) do
    aql = """

      LET now_time = DATE_NOW()

      LET tx = (
        FOR tran IN transactions
        FILTER tran._key == "#{data._key}"
        FILTER tran.invoice_id == "#{data.invoice_id}"
        FILTER tran.payable == "#{data.payable}"
        FILTER tran.status == 0
        RETURN tran
      )

      LET invoice = (
        FOR inv IN invoices
        FILTER inv._key == "#{data.invoice_id}"
        FILTER inv.current_tx_id == "#{data._key}"
        FILTER inv.status == 2
        RETURN inv
      )

      LET tx_update = (
        tx != [] AND invoice != [] ? (
          [{
            _key: "#{data._key}",
            status: -1,
            metadata: {
              pg_response: #{Jason.encode!(pg_response)}
            },
            updated_at: DATE_ISO8601(now_time)
          }]
        ) : (
          []
        )
      )

      LET inv_update = (
        tx != [] AND invoice != [] ? (
          [{
            _key: "#{data.invoice_id}",
            status: 0,
            current_tx_id: null,
            updated_at: DATE_ISO8601(now_time)
          }]
        ) : (
          []
        )
      )

      LET updated_tx = (
        FOR up_tx IN tx_update
        UPDATE up_tx IN transactions RETURN NEW
      )

      LET updated_inv = (
        FOR up_inv IN inv_update
        UPDATE up_inv IN invoices RETURN NEW
      )

      LET new_transaction_log = (
        FOR up_tran_h IN updated_tx
        INSERT {
          transaction_id: up_tran_h._key,
          type: -1,
          data: {
            new: up_tran_h,
            old: tx[0]
          },
          inserted_at: DATE_ISO8601(now_time),
          updated_at: DATE_ISO8601(now_time)
        } IN transactions_history RETURN KEEP(NEW, "_key")
      )

      LET resp = (
        updated_tx != [] AND updated_inv != [] AND new_transaction_log != [] ? (
            MERGE(updated_tx[0], {db_msg: "inv_tx_updated"})
        ) : (
            {db_msg: "unknown_error"}
        )
      )

      RETURN resp
    """

    Repo.one(Transaction, aql)

  rescue
    e ->
      IO.inspect e
      db_transaction_error("expired_transaction_was_failed/1")
      {:error, :service_unavailable}
  end

  @doc """
  Deletes a transaction.

  ## Examples

      iex> delete_transaction(transaction)
      {:ok, %Transaction{}}

      iex> delete_transaction(transaction)
      {:error, %Ecto.Changeset{}}

  """
  def delete_transaction(%Transaction{} = transaction) do
    Repo.delete(transaction)
  end

  # =======================================================================================================================================
  # ======================================================= Private Functions =============================================================
  # =======================================================================================================================================

  defp tx_expirtion_time(pg_code) do
    cond do
      1 -> :timer.minutes(20)
      true -> :timer.minutes(20)
    end
  end

  defp db_transaction_error(func_name), do: Logger.error("Function[#{func_name}] DB transaction has error")
end
