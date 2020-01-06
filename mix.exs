defmodule Wafer.MixProject do
  use Mix.Project
  @moduledoc false

  @description """
  Wafer is an Elixir library to make writing drivers for i2c and SPI connected
  peripherals and interacting with GPIO pins easier.
  """
  @version "0.1.0"

  def project do
    [
      app: :wafer,
      version: @version,
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      package: package(),
      description: @description,
      deps: deps(),
      consolidate_protocols: Mix.env() != :test
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Wafer.Application, []}
    ]
  end

  def package do
    [
      maintainers: ["James Harton <james@automat.nz>"],
      licenses: ["Hippocratic"],
      links: %{
        "Source" => "https://gitlab.com/jimsy/wafer"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: [:dev, :test]},
      {:earmark, ">= 0.0.0", only: [:dev, :test]},
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
