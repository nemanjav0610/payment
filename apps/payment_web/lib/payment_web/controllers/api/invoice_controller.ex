defmodule PaymentWeb.Api.InvoiceController do
  use PaymentWeb, :controller

  alias Payment.Invoices

  action_fallback PaymentWeb.FallbackController

  def create(conn, %{"invoice" => invoice_params}) do
    with {:ok, invoice} <- Invoices.create_invoice(invoice_params) do
      conn
      |> put_status(:created)
      |> render("show_with_pgs.json", invoice: invoice)
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, invoice} <- Invoices.get_invoice(id) do
      conn
      |> put_status(:ok)
      |> render("show.json", invoice: invoice)
    end
  end
end
