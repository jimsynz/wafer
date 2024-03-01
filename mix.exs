defmodule Wafer.MixProject do
  use Mix.Project
  @moduledoc false

  @description """
  Wafer is an Elixir library to make writing drivers for i2c and SPI connected
  peripherals and interacting with GPIO pins easier.
  """

  @version "1.0.3"

  def project do
    [
      app: :wafer,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      package: package(),
      description: @description,
      deps: deps(),
      consolidate_protocols: Mix.env() != :test,
      source_url: "https://harton.dev/james/wafer",
      homepage_url: "https://harton.dev/james/wafer",
      docs: [
        source_url_pattern: "https://harton.dev/james/wafer/src/branch/main/%{path}#L%{line}",
        extras: ["README.md"]
      ]
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
        "Source" => "https://harton.dev/james/wafer",
        "Gitlab Mirror" => "https://gitlab.com/jimsy/wafer"
      },
      source_url: "https://harton.dev/james/wafer"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    devtest = [only: ~w[dev test]a, runtime: false]

    [
      {:circuits_gpio, "~> 2.0", optional: true},
      if System.get_env("CI_I2C_1_X") == "true" do
        {:circuits_i2c, "~> 2.0", optional: true}
      else
        {:circuits_i2c, "~> 2.0 or ~> 1.0", optional: true}
      end,
      {:circuits_spi, "~> 2.0 or ~> 1.3", optional: true},
      {:elixir_ale, "~> 1.2", optional: true},

      # Dev/test
      {:credo, "~> 1.6", devtest},
      {:dialyxir, "~> 1.4", devtest},
      {:doctor, "~> 0.21", devtest},
      {:earmark, "~> 1.4", devtest},
      {:ex_check, "~> 0.16", devtest},
      {:ex_doc, ">= 0.0.0", devtest},
      {:git_ops, "~> 2.4", devtest},
      {:mimic, "~> 1.5", only: :test},
      {:mix_audit, "~> 2.1", devtest}
    ]
  end
end
