defmodule Wafer.Driver.CircuitsSPI do
  defstruct ~w[bus ref]a
  @behaviour Wafer.Conn
  alias Circuits.SPI, as: Driver

  @moduledoc """
  A connection to a chip via Circuits's SPI driver.

  Implements the `Wafer.Conn` behaviour as well as the `Wafer.SPI` protocol.
  """

  @type t :: %__MODULE__{bus: binary, ref: reference}

  @type options :: [option | driver_option]
  @type option :: {:bus_name, binary}
  # These options are passed unchanged to the underlying driver.
  @type driver_option ::
          {:mode, 0..3}
          | {:bits_per_word, 0..16}
          | {:speed_hz, pos_integer}
          | {:delay_us, non_neg_integer}

  @doc """
  Acquire a connection to a peripheral using the Circuits' SPI driver on the
  specified bus and address.
  """
  @spec acquire(options) :: {:ok, t} | {:error, reason :: any}
  def acquire(opts) when is_list(opts) do
    with {:ok, bus} when is_binary(bus) <- Keyword.fetch(opts, :bus_name),
         {:ok, ref} when is_reference(ref) <- Driver.open(bus, Keyword.delete(opts, :bus_name)) do
      {:ok, %__MODULE__{bus: bus, ref: ref}}
    else
      :error -> {:error, "Circuits.SPI requires a `bus_name` option"}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Close the SPI bus connection.
  """
  @spec release(t) :: :ok | {:error, reason :: any}
  def release(%__MODULE__{ref: ref} = _conn) when is_reference(ref), do: Driver.close(ref)
end

defimpl Wafer.SPI, for: Wafer.Driver.CircuitsSPI do
  alias Circuits.SPI, as: Driver

  def transfer(%{ref: ref} = conn, data) when is_reference(ref) and is_binary(data) do
    case Driver.transfer(ref, data) do
      {:ok, data} -> {:ok, data, conn}
      {:error, reason} -> {:error, reason}
    end
  end
end
