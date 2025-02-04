defmodule PaymentWeb.Plugs.RoleAuth do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, profile: true) do
    ensure_login_profile(conn, [])
  end

  def call(conn, _opt) do
    ensure_login_user(conn, [])
  end

  def ensure_login_super_admin(conn, _) do
    case Guardian.Plug.current_resource(conn) do
      %{_key: key, rol: 0} ->
        conn
        |> assign(:profile_id, key)
        |> assign(:role, 0)
      _ ->
        conn
        |> put_status(:not_found)
        |> Phoenix.Controller.text("not_found")
        |> halt()

    end
  end

  def ensure_login_content_maker(conn, _) do
    case Guardian.Plug.current_resource(conn) do
      %{_key: key, rol: 2} ->
        conn
        |> assign(:profile_id, key)
        |> assign(:role, 2)
      _ ->
        conn
        |> put_status(:not_found)
        |> Phoenix.Controller.text("not_found")
        |> halt()

    end
  end

  def ensure_login_admin(conn, _) do
    case Guardian.Plug.current_resource(conn) do
      %{_key: key, rol: 1} ->
        conn
        |> assign(:profile_id, key)
        |> assign(:role, 1)
      _ ->
        conn
        |> put_status(:not_found)
        |> Phoenix.Controller.text("not_found")
        |> halt()

    end
  end

  def ensure_login_user(conn, _) do
    case Guardian.Plug.current_resource(conn) do
      %{_key: key} ->
        conn
        |> assign(:user_id, key)
      _ ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.text("unauthorized")
        |> halt()
    end
  end

  def ensure_login_profile(conn, _) do
    case Guardian.Plug.current_resource(conn) do
      %{_key: key} ->
        conn
        |> assign(:client_id, key)
      _ ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.text("unauthorized")
        |> halt()
    end
  end

  def check_login_profile(conn, _) do
    case Guardian.Plug.current_resource(conn) do
      %{_key: key} ->
        conn
        |> assign(:profile_id, key)
      _ ->
        conn
    end
  end
end
