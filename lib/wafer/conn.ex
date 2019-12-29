defmodule Wafer.Conn do
  @moduledoc """
  Defines a protocol and behaviour for connecting to a peripheral.
  """

  @type option :: {atom, any}

  @doc """
  Acquire a connection to a peripheral using the provided driver.
  """
  @callback acquire(opts :: [option]) :: t :: {:error, reason :: any}

  @doc """
  Release all resources associated with this connection.
  """
  @callback release(module) :: :ok | {:error, reason :: any}
end
