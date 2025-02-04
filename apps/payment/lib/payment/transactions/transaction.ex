defmodule Payment.Transactions.Transaction.PG do
  use Arango.Ecto.Type.Custom,
  maptypes: %{
    _key:     :string,
    id:       :string,
    name:     :string,
    code:     :integer,
    status:   {:parameterized, Ecto.Enum, Ecto.Enum.init(values: [active: 1, deactive: 0])}
  }
end

defmodule Payment.Transactions.Transaction.Metadata do
  use Arango.Ecto.Type.Custom,
  maptypes: %{
    pg_response: :map
  }
end

defmodule Payment.Transactions.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:_key, :string, [autogenerate: false]}
  @timestamps_opts [type: :utc_datetime]

  schema "transactions" do
    field :invoice_id,         :string
    field :pg_code,            :integer
    field :description,        :string
    field :status,             Ecto.Enum, values: [failed: -1, paying: 0, paid: 1]
    field :payable,            :string
    field :authority,          :string
    field :expire_at,          :integer
    field :card_hash,          :string
    field :card_pan,           :string
    field :tracking_id,        :integer
    field :vretry_count,       :integer, default: 0
    field :pg_url,             :string
    field :last_vretry_time,   :integer, default: nil
    field :metadata,           Payment.Transactions.Transaction.Metadata
    timestamps()

    # virtual fields
    field :db_msg,           :string
    field :pg,               Payment.Transactions.Transaction.PG
  end

  @doc false
  def init_changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:invoice_id, :pg_code])
    |> validate_required([:invoice_id, :pg_code])
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
