defmodule PaymentWeb.Router do
  use PaymentWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PaymentWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :authenticate_api do
    plug :accepts, ["json"]
    plug PaymentWeb.Guardian.Pipeline
    plug PaymentWeb.Plugs.RoleAuth, profile: true
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PaymentWeb do
    pipe_through :browser

    scope "/pg" do
      get "/zarinpal/callback", TransactionController, :validate_zarinpal_transaction
    end
  end

  scope "/api", PaymentWeb.Api, as: :api do
    pipe_through :api

    scope "/invoices" do
      # GET
      get "/get_invoice", InvoiceController, :show

      # POST
      post "/create", InvoiceController, :create
    end

    scope "/transactions" do
      # GET
      get "/get_transaction", TransactionController, :show
      get "/verify_zarinpal_transaction", TransactionController, :validate_zarinpal_transaction

      # POST
      post "/create", TransactionController, :create
    end

    scope "/pgs" do
      # GET
      get "/", PaymentGatewayController, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", PaymentWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PaymentWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
