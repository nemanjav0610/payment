defmodule StreamsWeb.Guardian.GeneralPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :payment_web,
    error_handler: StreamsWeb.Guardian.ErrorHandler,
    module: StreamsWeb.Guardian

  # If there is an authorization header, restrict it to an access token and validate it
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.LoadResource, allow_blank: true
end
