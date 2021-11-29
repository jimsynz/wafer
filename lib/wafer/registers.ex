# credo:disable-for-this-file
defmodule Wafer.Registers do
  @moduledoc """
  This module provides helpful macros for specifying the registers used to
  communicate with your device.

  This can be a massive time saver, and means you can basically just copy them
  straight out of the datasheet.

  See the documentation for `defregister/4` for more information.
  """
  alias Wafer.Chip
  alias Wafer.Conn

  @type register_name :: atom
  @type access_mode :: :ro | :rw | :wo
  @type bytes :: non_neg_integer

  defmacro __using__(_opts) do
    quote do
      import Wafer.Registers
    end
  end

  @doc ~S"""
  Define functions for interacting with a device register.

  ## Parameters
    - `name` - name of the register.
    - `register_address` - the address of the register.
    - `mode` the access mode of the register.
    - `bytes` the number of bytes in the register.

  ## Examples

  ### Read-only registers

  Define a read-only register named `status` at address `0x03` which is a single
  byte wide:

      iex> defregister(:status, 0x03, :ro, 1)

  This will define the following function along with documentation and
  typespecs:

  ```elixir
  def read_status(conn), do: Chip.read_register(conn, 0x03, 1)
  ```

  ### Write-only registers

  Define a write-only register named `int_en` at address `0x02` which is 2 bytes
  wide:

      iex> defregister(:int_en, 0x02, :wo, 2)

  This will define the following functions along with documentation and
  typespecs:

  ```elixir
  def write_int_en(conn, data)
      when is_binary(data) and byte_size(data) == 2,
      do: Chip.write_register(conn, 0x2, data)

  def write_int_en(_conn, data),
      do: {:error, "Argument error: #{inspect(data)}"}
  ```

  ### Read-write registers.

  Define a read-write register named `config` at address `0x01`.

      iex> defregister(:config, 0x01, :rw, 1)

  In addition to defining `read_config/1` and `write_config/2` as per the
  examples above it will also generate the following functions along with
  documentation and typespecs:

  ```elixir
  def swap_config(conn, data)
      when is_binary(data) and byte_size(data) == 1,
      do: Chip.swap_register(conn, 0x01, data)

  def swap_config(_conn, data),
      do: {:error, "Argument error: #{inspect(data)}"}

  def update_config(conn, callback)
      when is_function(callback, 1) do
        with {:ok, data} <- Chip.read_register(conn, 0x01, 1),
             new_data when is_binary(new_data) and byte_size(new_data) == 1 <- callback.(data),
             {:ok, conn} <- Chip.write_regsiter(conn, 0x01, new_data),
             do: {:ok, conn}
      end

  def update_config(_conn, _callback),
      do: {:error, "Argument error: callback should be an arity 1 function"}
  ```

  """
  @spec defregister(atom, non_neg_integer, :ro | :rw | :wo, non_neg_integer) :: Macro.t()
  defmacro defregister(name, register_address, :ro, bytes)
           when is_atom(name) and is_integer(register_address) and register_address >= 0 and
                  is_integer(bytes) and bytes >= 0 do
    empty_bytes = 1..bytes |> Enum.map(fn _ -> 0 end) |> Enum.join(", ")

    quote do
      @doc """
      Read the contents of the `#{unquote(name)}` register.

      ## Example

          iex> read_#{unquote(name)}(conn)
          {:ok, <<#{unquote(empty_bytes)}>>}
      """
      @spec unquote(:"read_#{name}")(Conn.t()) :: {:ok, binary} | {:error, reason :: any}
      def unquote(:"read_#{name}")(conn),
        do: Chip.read_register(conn, unquote(register_address), unquote(bytes))
    end
  end

  defmacro defregister(name, register_address, :wo, bytes)
           when is_atom(name) and is_integer(register_address) and register_address >= 0 and
                  is_integer(bytes) and bytes >= 0 do
    empty_bytes = 1..bytes |> Enum.map(fn _ -> 0 end) |> Enum.join(", ")

    quote do
      @doc """
      Write new contents to the `#{unquote(name)}` register.

      ## Example

          iex> write_#{unquote(name)}(conn, <<#{unquote(empty_bytes)}>>)
          {:ok, _conn}
      """
      @spec unquote(:"write_#{name}")(Conn.t(), data :: binary) ::
              {:ok, Conn.t()} | {:error, reason :: any}
      def unquote(:"write_#{name}")(conn, data)
          when is_binary(data) and byte_size(data) == unquote(bytes),
          do: Chip.write_register(conn, unquote(register_address), data)

      def unquote(:"write_#{name}")(_conn, data), do: {:error, "Argument error: #{inspect(data)}"}
    end
  end

  defmacro defregister(name, register_address, :rw, bytes)
           when is_atom(name) and is_integer(register_address) and register_address >= 0 and
                  is_integer(bytes) and bytes >= 0 do
    empty_bytes = 1..bytes |> Enum.map(fn _ -> 0 end) |> Enum.join(", ")
    bits = bytes * 8

    quote do
      @doc """
      Read the contents of the `#{unquote(name)}` register.

      ## Example

          iex> read_#{unquote(name)}(conn)
          {:ok, <<#{unquote(empty_bytes)}>>}
      """
      @spec unquote(:"read_#{name}")(Conn.t()) :: {:ok, binary} | {:error, reason :: any}
      def unquote(:"read_#{name}")(conn),
        do: Chip.read_register(conn, unquote(register_address), unquote(bytes))

      @doc """
      Write new contents to the `#{unquote(name)}` register.

      ## Example

          iex> write_#{unquote(name)}(conn, <<#{unquote(empty_bytes)}>>)
          {:ok, _conn}
      """
      @spec unquote(:"write_#{name}")(Conn.t(), data :: binary) ::
              {:ok, Conn.t()} | {:error, reason :: any}
      def unquote(:"write_#{name}")(conn, data)
          when is_binary(data) and byte_size(data) == unquote(bytes),
          do: Chip.write_register(conn, unquote(register_address), data)

      def unquote(:"write_#{name}")(_conn, data), do: {:error, "Argument error: #{inspect(data)}"}

      @doc """
      Swap the contents of the `#{unquote(name)}` register.

      Reads the contents of the register, then replaces it, returning the
      previous contents.  Some drivers may implement this atomically.

      ## Example

          iex> swap_#{unquote(name)}(conn, <<#{unquote(empty_bytes)}>>)
          {:ok, <<#{unquote(empty_bytes)}>>, _conn}
      """
      @spec unquote(:"swap_#{name}")(Conn.t(), data :: binary) ::
              {:ok, Conn.t()} | {:error, reason :: any}
      def unquote(:"swap_#{name}")(conn, data)
          when is_binary(data) and byte_size(data) == unquote(bytes),
          do: Chip.swap_register(conn, unquote(register_address), data)

      def unquote(:"swap_#{name}")(_conn, data), do: {:error, "Argument error: #{inspect(data)}"}

      @doc """
      Update the contents of the `#{unquote(name)}` register using a
      transformation function.

      ## Example

          iex> transform = fn <<data::size(#{unquote(bits)})>> -> <<(data * 2)::size(#{unquote(bits)})>> end
          ...> update_#{unquote(name)}(conn, transform)
          {:ok, _conn}
      """
      @spec unquote(:"update_#{name}")(
              Conn.t(),
              (<<_::_*unquote(bits)>> -> <<_::_*unquote(bits)>>)
            ) :: {:ok, Conn.t()} | {:error, reason :: any}
      def unquote(:"update_#{name}")(conn, callback) when is_function(callback, 1) do
        with {:ok, old_data} <-
               Chip.read_register(conn, unquote(register_address), unquote(bytes)),
             new_data when is_binary(new_data) and byte_size(new_data) == unquote(bytes) <-
               callback.(old_data),
             {:ok, conn} <- Chip.write_register(conn, unquote(register_address), new_data),
             do: {:ok, conn}
      end

      def unquote(:"update_#{name}")(_conn, _callback),
        do: {:error, "Argument error: callback should be an arity 1 function"}
    end
  end

  @doc """
  Define functions for interacting with a device register with common defaults.

  ## Examples

  When specified with an access mode, assumes a 1 byte register:

      iex> defregister(:status, 0x03, :ro)

  When specified with a byte size, assumes a `:rw` register:

      iex> defregister(:config, 0x02, 2)

  """
  @spec defregister(atom, non_neg_integer, :ro | :rw | :wo | non_neg_integer) :: Macro.t()
  defmacro defregister(name, register_address, mode) when mode in ~w[ro rw wo]a do
    quote do
      defregister(unquote(name), unquote(register_address), unquote(mode), 1)
    end
  end

  defmacro defregister(name, register_address, bytes) when is_integer(bytes) and bytes >= 0 do
    quote do
      defregister(unquote(name), unquote(register_address), :rw, unquote(bytes))
    end
  end
end
