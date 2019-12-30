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
      {:elixir_ale, "~> 1.2", only: :dev, optional: true},
      {:circuits_i2c, "~> 0.3", only: :dev, optional: true},
      {:circuits_gpio, "~> 0.4", only: :dev, optional: true},
      {:circuits_spi, "~> 0.1", only: :dev, optional: true}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support" | elixirc_paths(nil)]
  defp elixirc_paths(_), do: ["lib"]
end
