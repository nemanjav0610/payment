defmodule PaymentWeb.Api.PaymentGatewayController do
  use PaymentWeb, :controller

  alias Payment.PaymentGateways
  alias Payment.PaymentGateways.PaymentGateway

  action_fallback PaymentWeb.FallbackController

  def index(conn, _params) do
    payment_gateways = PaymentGateways.list_payment_gateways()
    render(conn, "index.json", payment_gateways: payment_gateways)
  end
end
