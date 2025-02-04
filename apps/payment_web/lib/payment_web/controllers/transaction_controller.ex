defmodule PaymentWeb.TransactionController do
  use PaymentWeb, :controller

  alias Payment.Transactions
  alias Payment.Transactions.Transaction

  def validate_zarinpal_transaction(conn, %{"Authority" => authority, "Status"=> "OK"}) do
    with {:ok, transaction} <- Transactions.validate_zarinpal_transaction(authority) do
      conn
      |> put_flash(:info, "Transaction paid successfully.")
      |> render("index.html")

    else
      _ ->
        conn
        |> put_flash(:error, "Transaction payment failed.")
        |> render("index.html")
    end
  end

  def validate_zarinpal_transaction(conn, %{"Authority" => _authority} = _params) do
    conn
    |> put_flash(:error, "Transaction payment failed.")
    |> render("index.html")
  end
end
