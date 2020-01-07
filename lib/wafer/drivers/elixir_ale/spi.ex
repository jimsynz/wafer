defmodule Wafer.Driver.ElixirALE.SPI do
  defstruct ~w[bus pid]a
  @behaviour Wafer.Conn
  alias Wafer.Driver.ElixirALE.SPI.Wrapper

  @moduledoc """
  A connection to a chip via ElixirALE's SPI driver.

  Implements the `Wafer.Conn` behaviour as well as the `Wafer.SPI` protocol.
  """

  @type t :: %__MODULE__{bus: binary, pid: pid}

  @type options :: [option | driver_option]
  @type option :: {:bus_name, binary}
  # These options are passed unchanged to the underlying driver.
  @type driver_option ::
          {:mode, 0..3}
          | {:bits_per_word, 0..16}
          | {:speed_hz, pos_integer}
          | {:delay_us, non_neg_integer}

  @doc """
  Acquire a connection to a peripheral using the ElixirALE' SPI driver on the
  specified bus and address.
  """
  @spec acquire(options) :: {:ok, t} | {:error, reason :: any}
  def acquire(opts) when is_list(opts) do
    with {:ok, bus} when is_binary(bus) <- Keyword.fetch(opts, :bus_name),
         {:ok, pid} when is_pid(pid) <-
           Wrapper.start_link(bus, Keyword.delete(opts, :bus_name), []) do
      {:ok, %__MODULE__{bus: bus, pid: pid}}
    else
      :error -> {:error, "ElixirALE.SPI requires a `bus_name` option"}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Close the SPI bus connection.
  """
  @spec release(t) :: :ok | {:error, reason :: any}
  def release(%__MODULE__{pid: pid} = _conn) when is_pid(pid), do: Wrapper.release(pid)
end

defimpl Wafer.SPI, for: Wafer.Driver.ElixirALE.SPI do
  alias Wafer.Driver.ElixirALE.SPI.Wrapper

  def transfer(%{pid: pid} = conn, data) when is_pid(pid) and is_binary(data) do
    case Wrapper.transfer(pid, data) do
      read_data when is_binary(read_data) and byte_size(read_data) == byte_size(data) ->
        {:ok, read_data, conn}

      {:error, reason} ->
        {:error, reason}

      other ->
        {:error, "Invalid response from driver: #{inspect(other)}"}
    end
  end
end

defimpl Wafer.DeviceID, for: Wafer.Driver.ElixirALE.SPI do
  def id(%{bus: bus}), do: {Wafer.Driver.ElixirALE.SPI, bus}
end
