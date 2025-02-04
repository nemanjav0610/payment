defmodule Payment.PaymentGateways.PaymentGateway do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "payment_gateways" do
    field :_key,     :string, primary_key: true
    field :name,     :string
    field :code,     :integer
    field :status,   Ecto.Enum, values: [active: 1, deactive: 0]
  end
end
