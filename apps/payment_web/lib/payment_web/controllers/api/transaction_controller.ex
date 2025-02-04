defmodule PaymentWeb.Api.TransactionController do
  use PaymentWeb, :controller

  alias Payment.Transactions

  action_fallback PaymentWeb.FallbackController

  def create(conn, %{"transaction" => transaction_params}) do
    with {:ok, transaction} <- Transactions.create_transaction(transaction_params) do
      case transaction do
        %{db_msg: "created"} ->
          conn
          |> put_status(:created)
          |> render("show.json", transaction: transaction)

        %{db_msg: "accepted"} ->
          conn
          |> put_status(:accepted)
          |> render("show.json", transaction: transaction)
      end
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, transaction} <- Transactions.get_transaction(id) do
      conn
      |> put_status(:ok)
      |> render("show.json", transaction: transaction)
    end
  end

  def validate_zarinpal_transaction(conn, %{"authority" => authority, "status"=> "OK"}) do
    with {:ok, :paid} <- Transactions.validate_zarinpal_transaction(authority) do
      conn |> json(%{success: true})

    else
      _e ->
        conn |> json(%{success: false})
    end
  end

  def validate_zarinpal_transaction(conn, _params) do
    conn |> json(%{success: false})
  end
end
