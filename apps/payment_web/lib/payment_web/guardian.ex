defmodule PaymentWeb.Guardian do
  use Guardian, otp_app: :payment_web

  def subject_for_token(user, _claims) do
    sub = to_string(user._key)
    {:ok, sub}
  end

  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  def resource_from_claims(%{"sub"=> sub, "phn"=> phn, "rol"=> rol}) do
    {:ok, %{_key: sub, phn: phn, rol: rol}}
  rescue
    Ecto.NoResultsError -> {:error, :resource_not_found}
  end

  # def resource_from_claims(%{"sub"=> sub, "phn"=> phn}) do
  #   {:ok, %{_key: sub, phn: phn}}
  # rescue
  #   Ecto.NoResultsError -> {:error, :resource_not_found}
  # end

  def resource_from_claims(%{"sub" => sub}) do
    {:ok, %{_key: sub}}
  rescue
    Ecto.NoResultsError -> {:error, :resource_not_found}
  end

  def resource_from_claims(_claims) do
    {:error, :resource_id_not_found}
  end
end
