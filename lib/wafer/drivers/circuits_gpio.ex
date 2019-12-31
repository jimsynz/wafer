defmodule Wafer.Driver.CircuitsGPIO do
  defstruct ~w[direction pin ref]a
  @behaviour Wafer.Conn
  alias Circuits.GPIO, as: Driver
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
    with pin when is_pin_number(pin) <- Keyword.get(opts, :pin),
         direction when is_pin_direction(direction) <- Keyword.get(opts, :direction, :out),
         pin_dir <- String.to_atom(Enum.join([direction, "put"], "")),
         {:ok, ref} <- Driver.open(pin, pin_dir, Keyword.drop(opts, ~w[pin direction]a)) do
      {:ok, %__MODULE__{ref: ref, pin: pin, direction: direction}}
    else
      :error -> {:error, "Circuits.GPIO requires a `pin` option."}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Release all resources related to this GPIO pin connection.

  Note that other connections may still be using the pin.
  """
  @spec release(t) :: :ok | {:error, reason :: any}
  def release(%__MODULE__{ref: ref} = _conn) when is_reference(ref), do: Driver.close(ref)
end

defimpl Wafer.GPIO, for: Wafer.Driver.CircuitsGPIO do
  alias Wafer.Driver.CircuitsGPIODispatcher
  alias Circuits.GPIO, as: Driver
  import Wafer.Guards

  def read(%{ref: ref}) when is_reference(ref) do
    case(Driver.read(ref)) do
      value when is_pin_value(value) -> {:ok, value}
      {:error, reason} -> {:error, reason}
    end
  end

  def write(%{ref: ref} = conn, value) when is_reference(ref) and is_pin_value(value) do
    case(Driver.write(ref, value)) do
      :ok -> {:ok, conn}
      {:error, reason} -> {:error, reason}
    end
  end

  def direction(%{direction: :in} = conn, :in), do: {:ok, conn}
  def direction(%{direction: :out} = conn, :out), do: {:ok, conn}

  def direction(%{ref: ref} = conn, direction)
      when is_reference(ref) and is_pin_direction(direction) do
    pin_dir = String.to_atom(Enum.join([direction, "put"], ""))

    case(Driver.set_direction(ref, pin_dir)) do
      :ok -> {:ok, %{conn | direction: direction}}
      {:error, reason} -> {:error, reason}
    end
  end

  def enable_interrupt(conn, pin_condition) when is_pin_condition(pin_condition),
    do: CircuitsGPIODispatcher.enable(conn, pin_condition)

  def disable_interrupt(conn, pin_condition) when is_pin_condition(pin_condition),
    do: CircuitsGPIODispatcher.disable(conn, pin_condition)

  def pull_mode(%{ref: ref} = conn, mode) when is_reference(ref) and is_pin_pull_mode(mode) do
    case Driver.set_pull_mode(ref, mode) do
      :ok -> {:ok, conn}
      {:error, reason} -> {:error, reason}
    end
  end
end
