defmodule PaymentWeb.Api.InvoiceView do
  use PaymentWeb, :view
  alias PaymentWeb.Api.{InvoiceView, PaymentGatewayView, TransactionView}

  def render("index.json", %{invoices: invoices}) do
    %{data: render_many(invoices, InvoiceView, "invoice.json")}
  end

  def render("show_with_pgs.json", %{invoice: invoice}) do
    %{
      data: %{
        invoice: render_one(invoice, InvoiceView, "invoice.json"),
        pgs: render_many(invoice.pgs, InvoiceView, "invoice_with_pgs.json")
      }
    }
  end

  def render("show.json", %{invoice: invoice}) do
    %{data: render_one(invoice, InvoiceView, "invoice.json")}
  end

  def render("invoice.json", %{invoice: invoice}) do
    %{
      _key: invoice._key,
      description: invoice.description,
      status: invoice.status,
      callback: invoice.callback,
      current_tx_id: invoice.current_tx_id,
      payable: invoice.payable,
      inserted_at: invoice.inserted_at,
      updated_at: invoice.updated_at,
      expire_at: invoice.expire_at
    }
  end

  def render("invoice_with_pgs.json", %{invoice: invoice_pg}) do
    %{
      code: invoice_pg.code,
      name: invoice_pg.name,
      status: invoice_pg.status
    }
  end
end
