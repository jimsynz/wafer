defmodule Wafer.Driver.CircuitsGPIO do
  defstruct ~w[direction pin ref]a
  @behaviour Wafer.Conn
  alias Circuits.GPIO, as: Driver
  alias Wafer.GPIO

  @moduledoc """
  A connection to a native GPIO pin via Circuit's GPIO driver.
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
    with {:ok, pin} <- Keyword.get(opts, :pin),
         {:ok, direction} <- Keyword.get(opts, :direction, :out),
         {:ok, ref} <- Driver.open(pin, direction, Keyword.drop(opts, ~w[pin direction]a)) do
      %__MODULE__{ref: ref, pin: pin, direction: direction}
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
  def release(%{ref: ref}), do: Driver.close(ref)
end

defimpl Wafer.GPIOProto, for: Wafer.Driver.CircuitsGPIO do
  alias Wafer.Driver.CircuitsGPIODispatcher
  alias Circuits.GPIO, as: Driver

  def read(%{ref: ref}) do
    case(Driver.read(ref)) do
      value when value in [0, 1] -> {:ok, value}
      {:error, reason} -> {:error, reason}
    end
  end

  def write(%{ref: ref} = conn, value) when value in [0, 1] do
    case(Driver.write(ref, value)) do
      :ok -> {:ok, conn}
      {:error, reason} -> {:error, reason}
    end
  end

  def direction(%{direction: :in} = conn, :in), do: {:ok, conn}
  def direction(%{direction: :out} = conn, :out), do: {:ok, conn}

  def direction(%{ref: ref} = conn, direction) when direction in [:in, :out] do
    case(Driver.set_direction(ref, direction)) do
      :ok -> %{conn | direction: direction}
      {:error, reason} -> {:error, reason}
    end
  end

  def enable_interrupt(conn, pin_trigger), do: CircuitsGPIODispatcher.enable(conn, pin_trigger)
  def disable_interrupt(conn, pin_trigger), do: CircuitsGPIODispatcher.disable(conn, pin_trigger)

  def pull_mode(%{ref: ref} = conn, mode) when mode in [:not_set, :none, :pull_up, :pull_down] do
    case Driver.set_pull_mode(ref, mode) do
      :ok -> {:error, conn}
      {:error, reason} -> {:error, reason}
    end
  end
end
