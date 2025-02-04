defmodule Payment.InvoicesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Payment.Invoices` context.
  """

  @doc """
  Generate a invoice.
  """
  def invoice_fixture(attrs \\ %{}) do
    {:ok, invoice} =
      attrs
      |> Enum.into(%{

      })
      |> Payment.Invoices.create_invoice()

    invoice
  end
end
