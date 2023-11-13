defmodule Wafer.MixProject do
  use Mix.Project
  @moduledoc false

  @description """
  Wafer is an Elixir library to make writing drivers for i2c and SPI connected
  peripherals and interacting with GPIO pins easier.
  """

  @version "1.0.2"

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
      maintainers: ["James Harton <james@harton.nz>"],
      licenses: ["HL3-FULL"],
      links: %{
        "Source" => "https://gitlab.com/jimsy/wafer"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:circuits_gpio, "~> 1.0", optional: true},
      if System.get_env("CI_I2C_1_X") == "true" do
        {:circuits_i2c, "~> 1.0", optional: true}
      else
        {:circuits_i2c, "~> 2.0 or ~> 1.0", optional: true}
      end,
      {:circuits_spi, "~> 2.0", optional: true},
      {:credo, "~> 1.6", only: ~w[dev test]a, runtime: false},
      {:earmark, "~> 1.4", only: ~w[dev test]a},
      {:elixir_ale, "~> 1.2", optional: true},
      {:ex_doc, ">= 0.28.1", only: ~w[dev test]a},
      {:git_ops, "~> 2.4", only: ~w[dev test]a, runtime: false},
      {:mimic, "~> 1.5", only: :test}
    ]
  end
end
