defmodule PaymentWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use PaymentWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(PaymentWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :bad_request}) do
    conn
    |> put_status(:bad_request)
    |> put_view(PaymentWeb.ErrorView)
    |> render(:"400")
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(PaymentWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :method_not_allowed}) do
    conn
    |> put_status(:method_not_allowed)
    |> put_view(PaymentWeb.ErrorView)
    |> render(:"405")
  end

  def call(conn, {:error, :timeout}) do
    conn
    |> put_status(:request_timeout)
    |> put_view(PaymentWeb.ErrorView)
    |> render(:"408")
  end

  def call(conn, {:error, :not_acceptable}) do
    conn
    |> put_status(:not_acceptable)
    |> put_view(PaymentWeb.ErrorView)
    |> render(:"406")
  end

  def call(conn, {:error, :conflict}) do
    conn
    |> put_status(:conflict)
    |> put_view(PaymentWeb.ErrorView)
    |> render(:"409")
  end

  #5XX
  def call(conn, {:error, :service_unavailable}) do
    conn
    |> put_status(:service_unavailable)
    |> put_view(PaymentWeb.ErrorView)
    |> render(:"503")
  end
end
