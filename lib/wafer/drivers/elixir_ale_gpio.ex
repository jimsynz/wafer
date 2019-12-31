defmodule Wafer.Driver.ElixirALEGPIO do
  defstruct ~w[direction pid pin]a
  @behaviour Wafer.Conn
  alias ElixirALE.GPIO, as: Driver
  alias Wafer.GPIO

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
    with pin when is_integer(pin) and pin >= 0 <- Keyword.get(opts, :pin),
         direction when direction in [:in, :out] <- Keyword.get(opts, :direction, :out),
         {:ok, pid} <- Driver.start_link(pin, direction, Keyword.drop(opts, ~w[pin direction]a)) do
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
  def release(%__MODULE__{pid: pid} = _conn), do: Driver.release(pid)
end

defimpl Wafer.GPIO, for: Wafer.Driver.ElixirALEGPIO do
  alias ElixirALE.GPIO, as: Driver
  alias Wafer.Driver.ElixirALEGPIODispatcher

  def read(%{pid: pid} = _conn) do
    case Driver.read(pid) do
      value when value in [0, 1] -> {:ok, value}
      {:error, reason} -> {:error, reason}
    end
  end

  def write(%{pid: pid} = conn, value) when value in [0, 1] do
    case Driver.write(pid, value) do
      :ok -> {:ok, conn}
      {:error, reason} -> {:error, reason}
    end
  end

  def direction(_conn, _direction), do: {:error, :not_supported}

  def enable_interrupt(conn, pin_condition),
    do: ElixirALEGPIODispatcher.enable(conn, pin_condition)

  def disable_interrupt(conn, pin_condition),
    do: ElixirALEGPIODispatcher.disable(conn, pin_condition)

  def pull_mode(_conn, _pull_mode), do: {:error, :not_supported}
end
