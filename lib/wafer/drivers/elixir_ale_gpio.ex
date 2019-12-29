defmodule Wafer.Driver.ElixirAleGPIO do
  defstruct ~w[direction pid pin]a
  @behaviour Wafer.Conn
  alias ElixirALE.GPIO, as: Driver
  alias Wafer.GPIO

  @moduledoc """
  A connection to a native GPIO pin via ElixirALE's GPIO driver.
  """

  @type t :: %__MODULE__{pid: pid}

  @type options :: [option]
  @type option :: {:pin, non_neg_integer} | {:direction, GPIO.pin_direction()}

  @doc """
  Acquire a connection to the specified GPIO pin using the ElixirALE GPIO driver.

  ## Options

    - `:pin` (required) - the integer pin number.  Hardware dependent.
    - `:direction` - either `:in` or `:out`.  Defaults to `:out`.
  """
  @spec acquire(options) :: {:ok, t} | {:error, reason :: any}
  def acquire(opts) when is_list(opts) do
    with {:ok, pin} <- Keyword.get(opts, :pin),
         {:ok, direction} <- Keyword.get(opts, :direction, :out),
         {:ok, pid} <- Driver.start_link(pin, direction, Keyword.drop(opts, ~w[pin direction]a)) do
      %__MODULE__{pid: pid}
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
  def release(%{pid: pid}), do: Driver.release(pid)
end

defimpl Wafer.GPIOProto, for: Wafer.Driver.ElixirAleGPIO do
  alias ElixirALE.GPIO, as: Driver
  alias Wafer.Driver.ElixirAleGPIODispatcher

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

  def direction(_conn, _direction),
    do:
      {:error,
       "ElixirALE doesn't support direction changing. Restart the connection process with the new direction instead."}

  def enable_interrupt(conn, pin_trigger),
    do: ElixirAleGPIODispatcher.enable(conn, pin_trigger)

  def disable_interrupt(conn, pin_trigger),
    do: ElixirAleGPIODispatcher.disable(conn, pin_trigger)

  def pull_mode(_conn, _pull_mode), do: {:error, :not_supported}
end
