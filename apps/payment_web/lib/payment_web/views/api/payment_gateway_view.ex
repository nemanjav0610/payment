defmodule PaymentWeb.Api.PaymentGatewayView do
  use PaymentWeb, :view
  alias PaymentWeb.Api.PaymentGatewayView

  def render("index.json", %{payment_gateways: payment_gateways}) do
    %{data: render_many(payment_gateways, PaymentGatewayView, "payment_gateway.json")}
  end

  def render("show.json", %{payment_gateway: payment_gateway}) do
    %{data: render_one(payment_gateway, PaymentGatewayView, "payment_gateway.json")}
  end

  def render("payment_gateway.json", %{payment_gateway: payment_gateway}) do
    %{
      _key: payment_gateway._key,
      code: payment_gateway.code,
      name: payment_gateway.name,
      status: payment_gateway.status
    }
  end
end
