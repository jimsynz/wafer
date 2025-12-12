defmodule Wafer.Driver.Circuits.GPIO do
  defstruct ~w[direction pin ref]a
  @behaviour Wafer.Conn
  alias Wafer.Driver.Circuits.GPIO.Wrapper
  alias Wafer.GPIO
  import Wafer.Guards

  @moduledoc """
  A connection to a native GPIO pin via Circuits' GPIO driver.

  Implements the `Wafer.Conn` behaviour as well as the `Wafer.GPIO` protocol.
  """

  @type t :: %__MODULE__{ref: reference, pin: non_neg_integer, direction: GPIO.pin_direction()}

  @type options :: [option]
  @type option :: {:pin, non_neg_integer} | {:direction, GPIO.pin_direction()}

  @doc """
  Acquire a connection to a native GPIO pin via Circuit's GPIO driver.

  ## Options

    - `:pin` (required) the integer number of the pin to connect to.  Hardware dependent.
    - `:direction` (optional) either `:in` or `:out`.  Defaults to `:out`.
  """
  @spec acquire(options) :: {:ok, t} | {:error, reason :: any}
  def acquire(opts) when is_list(opts) do
    with {:ok, pin} when is_pin_number(pin) <- Keyword.fetch(opts, :pin),
         direction when is_pin_direction(direction) <- Keyword.get(opts, :direction, :out),
         pin_dir <- String.to_atom(Enum.join([direction, "put"], "")),
         {:ok, ref} <- Wrapper.open(pin, pin_dir, Keyword.drop(opts, ~w[pin direction]a)) do
      {:ok, %__MODULE__{ref: ref, pin: pin, direction: direction}}
    else
      :error -> {:error, "Circuits.GPIO requires a `pin` option."}
      {:error, reason} -> {:error, reason}
    end
  end
end

defimpl Wafer.Release, for: Wafer.Driver.Circuits.GPIO do
  alias Wafer.Driver.Circuits.GPIO.Wrapper
  alias Wafer.Driver.Circuits.GPIO

  @doc """
  Release all resources related to this GPIO pin connection.

  Note that other connections may still be using the pin.
  """
  @spec release(GPIO.t()) :: :ok | {:error, reason :: any}
  def release(%GPIO{ref: ref} = _conn), do: Wrapper.close(ref)
end

defimpl Wafer.GPIO, for: Wafer.Driver.Circuits.GPIO do
  alias Wafer.Driver.Circuits.GPIO.Dispatcher
  alias Wafer.Driver.Circuits.GPIO.Wrapper
  import Wafer.Guards

  def read(%{ref: ref}) do
    case Wrapper.read(ref) do
      value when is_pin_value(value) -> {:ok, value}
    end
  rescue
    error -> {:error, error}
  end

  def write(%{ref: ref} = conn, value) when is_pin_value(value) do
    with :ok <- Wrapper.write(ref, value), do: {:ok, conn}
  end

  def direction(%{direction: :in} = conn, :in), do: {:ok, conn}
  def direction(%{direction: :out} = conn, :out), do: {:ok, conn}

  def direction(%{ref: ref} = conn, direction) when is_pin_direction(direction) do
    with pin_dir <- translate_pin_direction(direction),
         :ok <- Wrapper.set_direction(ref, pin_dir),
         do: {:ok, %{conn | direction: direction}}
  end

  def enable_interrupt(conn, pin_condition, metadata \\ nil)
      when is_pin_condition(pin_condition) do
    Dispatcher.enable(conn, pin_condition, metadata)
  end

  def disable_interrupt(conn, pin_condition) when is_pin_condition(pin_condition) do
    Dispatcher.disable(conn, pin_condition)
  end

  def pull_mode(%{ref: ref} = conn, mode) when is_pin_pull_mode(mode) do
    with :ok <- Wrapper.set_pull_mode(ref, mode), do: {:ok, conn}
  end

  defp translate_pin_direction(:in), do: :input
  defp translate_pin_direction(:out), do: :output
end

defimpl Wafer.DeviceID, for: Wafer.Driver.Circuits.GPIO do
  def id(%{pin: pin}), do: {Wafer.Driver.Circuits.GPIO, pin}
end
