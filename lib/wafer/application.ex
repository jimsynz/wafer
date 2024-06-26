defmodule Wafer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @doc false
  def start(_type, _args) do
    children = [
      {Registry, [keys: :duplicate, name: Wafer.InterruptRegistry]},
      Wafer.Driver.Circuits.GPIO.Dispatcher
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Wafer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
