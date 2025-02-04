defmodule Payment.TransactionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Payment.Transactions` context.
  """

  @doc """
  Generate a transaction.
  """
  def transaction_fixture(attrs \\ %{}) do
    {:ok, transaction} =
      attrs
      |> Enum.into(%{

      })
      |> Payment.Transactions.create_transaction()

    transaction
  end
end
