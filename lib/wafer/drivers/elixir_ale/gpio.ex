defmodule Wafer.Driver.ElixirALE.GPIO do
  defstruct ~w[direction pid pin]a
  @behaviour Wafer.Conn
  alias Wafer.Driver.ElixirALE.GPIO.Wrapper
  alias Wafer.GPIO
  import Wafer.Guards

  @moduledoc """
  A connection to a native GPIO pin via ElixirALE's GPIO driver.

  Implements the `Wafer.Conn` behaviour as well as the `Wafer.GPIO` protocol.
  """

  @type t :: %__MODULE__{pid: pid}

  @type options :: [option]
  @type option :: {:pin, non_neg_integer} | {:direction, GPIO.pin_direction()} | {:force, boolean}

  @doc """
  Acquire a connection to the specified GPIO pin using the ElixirALE GPIO driver.

  ## Options

    - `:pin` (required) - the integer pin number.  Hardware dependent.
    - `:direction` - either `:in` or `:out`.  Defaults to `:out`.
  """
  @spec acquire(options) :: {:ok, t} | {:error, reason :: any}
  def acquire(opts) when is_list(opts) do
    with {:ok, pin} when is_pin_number(pin) <- Keyword.fetch(opts, :pin),
         direction when direction in [:in, :out] <- Keyword.get(opts, :direction, :out),
         {:ok, pid} <- Wrapper.start_link(pin, direction, Keyword.drop(opts, ~w[pin direction]a)) do
      {:ok, %__MODULE__{pid: pid, pin: pin, direction: direction}}
    else
      :error -> {:error, "ElixirALE.GPIO requires a `pin` option."}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Release all resources related to this GPIO pin connection.

  Note that other connections may still be using the pin.
  """
  @spec release(t) :: :ok | {:error, reason :: any}
  def release(%__MODULE__{pid: pid} = _conn), do: Wrapper.release(pid)
end

defimpl Wafer.GPIO, for: Wafer.Driver.ElixirALE.GPIO do
  alias Wafer.Driver.ElixirALE.GPIO.Wrapper
  alias Wafer.Driver.ElixirALE.GPIO.Dispatcher

  def read(%{pid: pid} = _conn) do
    case Wrapper.read(pid) do
      value when value in [0, 1] -> {:ok, value}
      {:error, reason} -> {:error, reason}
    end
  end

  def write(%{pid: pid} = conn, value) when value in [0, 1] do
    case Wrapper.write(pid, value) do
      :ok -> {:ok, conn}
      {:error, reason} -> {:error, reason}
    end
  end

  def direction(_conn, _direction), do: {:error, :not_supported}

  def enable_interrupt(conn, pin_condition, metadata \\ nil),
    do: Dispatcher.enable(conn, pin_condition, metadata)

  def disable_interrupt(conn, pin_condition),
    do: Dispatcher.disable(conn, pin_condition)

  def pull_mode(_conn, _pull_mode), do: {:error, :not_supported}
end

defimpl Wafer.DeviceID, for: Wafer.Driver.ElixirALE.GPIO do
  def id(%{pin: pin}), do: {Wafer.Driver.ElixirALE.GPIO, pin}
end
