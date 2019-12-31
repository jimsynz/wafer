# credo:disable-for-this-file
defmodule Wafer.Registers do
  @moduledoc """
  This module provides helpful macros for specifying the registers used to
  communicate with your device.

  This can be a massive time saver, and means you can basically just copy them
  straight out of the datasheet.
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

  @doc """
  Define a registers.

  ## Parameters
    - `name` - name of the register.
    - `register_address` - the address of the register.
    - `mode` the access mode of the register.
    - `bytes` the number of bytes in the register.

  ## Examples

      iex> defregister(:status, 0x03, :ro, 1)

      iex> defregister(:config, 0x01, :rw, 2)

      iex> defregister(:int_en, 0x02, :wo, 1)

  """
  defmacro defregister(name, register_address, :ro, bytes)
           when is_atom(name) and is_integer(register_address) and register_address >= 0 and
                  is_integer(bytes) and bytes >= 0 do
    quote do
      @spec unquote(:"read_#{name}")(Conn.t()) :: {:ok, binary} | {:error, reason :: any}
      def unquote(:"read_#{name}")(conn),
        do: Chip.read_register(conn, unquote(register_address), unquote(bytes))
    end
  end

  defmacro defregister(name, register_address, :wo, bytes)
           when is_atom(name) and is_integer(register_address) and register_address >= 0 and
                  is_integer(bytes) and bytes >= 0 do
    quote do
      @spec unquote(:"write_#{name}")(Conn.t(), data :: binary) :: :ok | {:error, reason :: any}
      def unquote(:"write_#{name}")(conn, data)
          when is_binary(data) and byte_size(data) == unquote(bytes),
          do: Chip.write_register(conn, unquote(register_address), data)

      def unquote(:"write_#{name}")(_conn, data), do: {:error, "Argument error: #{inspect(data)}"}
    end
  end

  defmacro defregister(name, register_address, :rw, bytes)
           when is_atom(name) and is_integer(register_address) and register_address >= 0 and
                  is_integer(bytes) and bytes >= 0 do
    quote do
      @spec unquote(:"read_#{name}")(Conn.t()) :: {:ok, binary} | {:error, reason :: any}
      def unquote(:"read_#{name}")(conn),
        do: Chip.read_register(conn, unquote(register_address), unquote(bytes))

      @spec unquote(:"write_#{name}")(Conn.t(), data :: binary) :: :ok | {:error, reason :: any}
      def unquote(:"write_#{name}")(conn, data)
          when is_binary(data) and byte_size(data) == unquote(bytes),
          do: Chip.write_register(conn, unquote(register_address), data)

      def unquote(:"write_#{name}")(_conn, data), do: {:error, "Argument error: #{inspect(data)}"}

      @spec unquote(:"swap_#{name}")(Conn.t(), data :: binary) ::
              :ok | {:error, reason :: any}
      def unquote(:"swap_#{name}")(conn, data)
          when is_binary(data) and byte_size(data) == unquote(bytes),
          do: Chip.swap_register(conn, unquote(register_address), data)

      @spec unquote(:"update_#{name}")(
              Conn.t(),
              (<<_::_*unquote(bytes * 8)>> -> <<_::_*unquote(bytes * 8)>>)
            ) :: :ok | {:error, reason :: any}
      def unquote(:"update_#{name}")(conn, callback) when is_function(callback, 1) do
        with {:ok, old_data} <-
               Chip.read_register(conn, unquote(register_address), unquote(bytes)),
             new_data when is_binary(new_data) and byte_size(new_data) == unquote(bytes) <-
               callback.(old_data),
             :ok <- Chip.write_register(conn, unquote(register_address), new_data),
             do: :ok
      end

      def unquote(:"update_#{name}")(_conn, callback),
        do: {:error, "Argument error: callback should be an arity 1 function"}
    end
  end

  @doc """
  Define a register with common defaults:

  ## Examples

  When specified with an access mode, assumes a 1 byte register:

      iex> defregister(:status, 0x03, :ro)

  When specified with a byte size, assumes a `:rw` register:

      iex> defregister(:config, 0x02, 2)

  """
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
