defmodule Payment.Repo do
  use Arango.Repo,
    otp_app: :payment,
    collections: ["invoices", "transactions", "payment_gateways", "transactions_history"]
end
