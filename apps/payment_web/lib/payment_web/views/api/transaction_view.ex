defmodule PaymentWeb.Api.TransactionView do
  use PaymentWeb, :view
  alias PaymentWeb.Api.TransactionView

  def render("index.json", %{transactions: transactions}) do
    %{data: render_many(transactions, TransactionView, "transaction.json")}
  end

  def render("show.json", %{transaction: transaction}) do
    %{data: render_one(transaction, TransactionView, "transaction.json")}
  end

  def render("transaction.json", %{transaction: transaction}) do
    %{
      _key: transaction._key,
      invoice_id: transaction.invoice_id,
      pg_code: transaction.pg_code,
      authority: transaction.authority,
      pg_url: transaction.pg_url,
      description: transaction.description,
      payable: transaction.payable,
      status: transaction.status,
      tracking_id: transaction.tracking_id,
      inserted_at: transaction.inserted_at,
      updated_at: transaction.updated_at,
      expire_at: transaction.expire_at,
      pg: render_one(transaction.pg, TransactionView, "transaction_pg.json")
    }
  end

  def render("transaction_pg.json", %{transaction: transaction_pg}) do
    %{
      code: transaction_pg.code,
      name: transaction_pg.name,
      status: transaction_pg.status
    }
  end
end
