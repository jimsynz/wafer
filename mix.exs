defmodule Wafer.MixProject do
  use Mix.Project
  @moduledoc false

  def project do
    [
      app: :wafer,
      version: "0.1.0",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Wafer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mimic, "~> 1.1", only: :test},
      {:credo, "~> 1.1", only: [:dev, :test], runtime: false},
      {:elixir_ale, "~> 1.2", optional: true},
      {:circuits_i2c, "~> 0.3", optional: true},
      {:circuits_gpio, "~> 0.4", optional: true},
      {:circuits_spi, "~> 0.1", optional: true}
    ]
  end

  # Load fake versions of the Circuits and ElixirALE modules unless explicitly
  # told not to.
  defp elixirc_paths(:test) do
    if System.get_env("FAKE_DRIVERS") == "false",
      do: elixirc_paths(nil),
      else: ["test/support" | elixirc_paths(nil)]
  end

  defp elixirc_paths(_), do: ["lib"]
end
