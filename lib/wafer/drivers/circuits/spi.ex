defmodule Wafer.Driver.Circuits.SPI do
  defstruct ~w[bus ref]a
  @behaviour Wafer.Conn
  alias Wafer.Driver.Circuits.SPI.Wrapper

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
         {:ok, ref} when is_reference(ref) <- Wrapper.open(bus, Keyword.delete(opts, :bus_name)) do
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
  def release(%__MODULE__{ref: ref} = _conn) when is_reference(ref), do: Wrapper.close(ref)
end

defimpl Wafer.SPI, for: Wafer.Driver.Circuits.SPI do
  alias Wafer.Driver.Circuits.SPI.Wrapper

  def transfer(%{ref: ref} = conn, data) when is_reference(ref) and is_binary(data) do
    case Wrapper.transfer(ref, data) do
      {:ok, read_data} when is_binary(read_data) and byte_size(data) == byte_size(read_data) ->
        {:ok, read_data, conn}

      {:error, reason} ->
        {:error, reason}

      other ->
        {:error, "Invalid response from driver: #{inspect(other)}"}
    end
  end
end

defimpl Wafer.DeviceID, for: Wafer.Driver.Circuits.SPI do
  def id(%{bus: bus}), do: {Wafer.Driver.Circuits.SPI, bus}
end
