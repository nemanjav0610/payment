defmodule Payment.PaymentGateways.Zarinpal do
  # =======================================================================================================================================
  # ============================================================= Sand Funcs ==============================================================
  # =======================================================================================================================================

  def sand_get_authority_code_from_pg(%{pg: %{code: 1}} = data) do
    url = "https://sandbox.zarinpal.com/pg/rest/WebGate/PaymentRequest.json"
    body = Jason.encode!(%{
      merchant_id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      description: data.description,
      callback_url: "http://localhost:4000/pg/zarinpal/callback",
      amount: String.to_integer(data.payable)
    })

    resp = HTTPoison.post(url, body, [{"Content-Type", "application/json"}], [])

    case sand_val_zarinpal_response(resp) do
      {:ok, body} ->
        case body do
          %{Status: 100} ->
            {:ok, %{authority: body[:Authority], expire_in: :timer.minutes(16)}}
          _ ->
            {:error, :fucked_up}
        end

      error ->
        error
    end
  end

  def sand_get_authority_code_from_pg(_data) do
    {:error, :metho_not_allowed}
  end

  def sand_verify_zarinpal_authority(data) do
    url = "https://sand.zarinpal.com/pg/rest/WebGate/PaymentVerification.json"
    body = Jason.encode!(%{
      MerchantID: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      Authority: data.authority,
      Amount: String.to_integer(data.payable)
    })

    resp = HTTPoison.post(url, body, [{"Content-Type", "application/json"}], [])

    sand_val_zarinpal_response(resp)
  end

  def sand_val_zarinpal_response(response) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        sand_proc_zarinpal_resp(body)
      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        sand_proc_zarinpal_resp(body)
      {:error, %HTTPoison.Error{id: nil, reason: :timeout}} ->
        {:error, :poison, :bad_gateway}
      {:error, %HTTPoison.Error{reason: _reason}} ->
        {:error, :poison, :bad_gateway}
      _error ->
        {:error, :poison, :bad_gateway}
    end
  end

  def sand_proc_zarinpal_resp(body) do
    case body do
      %{Status: 101} -> {:ok, body}
      %{Status: 100} -> {:ok, body}
      _ -> {:error, :pg, body}
    end
  end

  # =======================================================================================================================================
  # ============================================================= Main Func ===============================================================
  # =======================================================================================================================================

  def zarinpal_payment_page_url(authority) do
    "https://www.zarinpal.com/pg/StartPay/#{authority}"
  end

  def get_authority_code_from_zarinpal(data) do
    url = "https://api.zarinpal.com/pg/v4/payment/request.json"
    body = Jason.encode!(%{
      merchant_id: Application.get_env(:payment, :zarinpal_merchant_id),
      currency: "IRR",
      description: data.description,
      callback_url: Application.get_env(:payment, :zarinpal_callback_base_url) <> "/pg/zarinpal/callback",
      amount: String.to_integer(data.payable)
    })

    resp = HTTPoison.post(url, body, [{"Content-Type", "application/json"}], [])
    val_zarinpal_response(resp)
  end

  def verify_zarinpal_authority(data) do
    url = "https://api.zarinpal.com/pg/v4/payment/verify.json"
    body = Jason.encode!(%{
      merchant_id: Application.get_env(:payment, :zarinpal_merchant_id),
      authority: data.authority,
      amount: String.to_integer(data.payable)
    })

    resp = HTTPoison.post(url, body, [{"Content-Type", "application/json"}], [])
    val_zarinpal_response(resp)
  end

  def val_zarinpal_response(response) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        proc_zarinpal_resp(Jason.decode!(body, keys: :atoms))
      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        proc_zarinpal_resp(Jason.decode!(body, keys: :atoms))
      {:error, %HTTPoison.Error{id: nil, reason: :timeout}} ->
        {:error, :poison, :bad_gateway}
      {:error, %HTTPoison.Error{reason: _reason}} ->
        {:error, :poison, :bad_gateway}
      _error ->
        {:error, :poison, :bad_gateway}
    end
  end

  def proc_zarinpal_resp(body) do
    case body do
      %{data: %{code: 100} = _data, errors: []} -> {:ok, body}
      %{data: %{code: 101} = _data, errors: []} -> {:ok, body}
      _ -> {:error, :pg, body}
    end
  end
end
