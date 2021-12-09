defmodule Wafer.MixProject do
  use Mix.Project
  @moduledoc false

  @description """
  Wafer is an Elixir library to make writing drivers for i2c and SPI connected
  peripherals and interacting with GPIO pins easier.
  """

  @version "0.3.1"

  def project do
    [
      app: :wafer,
      version: @version,
      elixir: "~> 1.9",
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
      {:circuits_gpio, "~> 1.0", optional: true},
      {:circuits_i2c, "~> 1.0", optional: true},
      {:circuits_spi, "~> 1.0", optional: true},
      {:credo, "~> 1.6", only: ~w[dev test]a, runtime: false},
      {:earmark, ">= 1.4.19", only: ~w[dev test]a},
      {:elixir_ale, "~> 1.2", optional: true},
      {:ex_doc, ">= 0.0.0", only: ~w[dev test]a},
      {:git_ops, "~> 2.4", only: ~w[dev test]a, runtime: false},
      {:mimic, "~> 1.1", only: :test}
    ]
  end
end
