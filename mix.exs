defmodule PaymentBackend.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: System.get_env("VERSION"),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      default_release: :payment_backend,
      releases: [
        payment_backend: [
          applications: [
            arango: :permanent,
            payment: :permanent,
            payment_web: :permanent
          ],
          cookie: "vMV6I4eBqhNuhh2nDLrRs3Cs34bginC9D3uhx1I7BOI51BfsagVxPFCxRfTC1YL"
        ]
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    []
  end
end
