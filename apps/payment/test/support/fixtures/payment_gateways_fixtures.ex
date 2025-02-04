defmodule Payment.PaymentGatewaysFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Payment.PaymentGateways` context.
  """

  @doc """
  Generate a payment_gateway.
  """
  def payment_gateway_fixture(attrs \\ %{}) do
    {:ok, payment_gateway} =
      attrs
      |> Enum.into(%{

      })
      |> Payment.PaymentGateways.create_payment_gateway()

    payment_gateway
  end
end
