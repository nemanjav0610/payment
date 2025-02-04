defmodule PaymentWeb.Guardian.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :payment_web,
    error_handler: PaymentWeb.Guardian.ErrorHandler,
    module: PaymentWeb.Guardian

  # If there is a session token, restrict it to an access token and validate it
  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  # If there is an authorization header, restrict it to an access token and validate it
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  # Load the user if either of the verifications worked
  plug Guardian.Plug.LoadResource
  plug Guardian.Plug.EnsureAuthenticated
end
