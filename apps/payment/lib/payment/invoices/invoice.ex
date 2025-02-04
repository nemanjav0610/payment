defmodule Payment.Invoices.Invoice.PGs do
  use Arango.Ecto.Type.Custom,
  maptypes: %{
    _key:     :string,
    id:       :string,
    name:     :string,
    code:     :integer,
    status:   {:parameterized, Ecto.Enum, Ecto.Enum.init(values: [active: 1, deactive: 0])}
  }
end

defmodule Payment.Invoices.Invoice do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:_key, :string, [autogenerate: false]}
  @timestamps_opts [type: :utc_datetime]

  schema "invoices" do
    field :description,       :string
    field :status,            Ecto.Enum, values: [expired: -2, failed: -1, init: 0, paid: 1, locked: 2]
    field :callback,          :map
    field :payable,           :string
    field :current_tx_id,     :string
    field :expire_at,         :integer

    timestamps()

    # virtual fields
    field :db_msg,            :string
    field :pgs,               {:array, Payment.Invoices.Invoice.PGs}
  end

  @doc false
  def create_changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [:description, :callback, :payable])
    |> validate_required([:description, :callback, :payable])
    |> validate_format(:payable, ~r/^[1-9][0-9]{3,10}$/)
    |> put_enum_defaults([status: :init])
  end

  # ========================================================== Private Funcs ==================================================================

  defp put_enum_defaults(%{valid?: false} = changeset, _defaults) do
    changeset
  end

  defp put_enum_defaults(changeset, defaults \\ []) do
    Enum.reduce(defaults, changeset, fn {key, val}, chngst ->
      case Map.has_key?(chngst.changes, key) do
        false ->
          chngst |> put_change(key, val)
        true ->
          chngst
      end
    end)
  end
end
