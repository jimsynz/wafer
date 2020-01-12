defprotocol Wafer.Release do
  alias Wafer.Conn

  @moduledoc """
  A protocol for releasing connections.  The opposite of `Conn`'s `acquire/1`.

  ## Deriving

  If you're implementing your own `Conn` type that simply delegates to one of
  the lower level drivers that you can derive this protocol automatically:

  ```elixir
  defstruct MyConn do
    @derive Wafer.Release
    defstruct [:conn]
  end
  ```

  If your type uses a key other than `conn` for the inner connection you can specify it while deriving:

  ```elixir
  defstruct MyConn do
    @derive {Wafer.Release, key: :pin_conn}
    defstruct [:pin_conn]
  end
  ```
  """

  @doc """
  Release all resources associated with the connection.  Usually in preparation
  for shutdown.
  """
  @spec release(Conn.t()) :: :ok
  def release(conn)
end

defimpl Wafer.Release, for: Any do
  defmacro __deriving__(module, struct, options) do
    key = Keyword.get(options, :key, :conn)

    unless Map.has_key?(struct, key) do
      raise(
        "Unable to derive `Wafer.Release` for `#{module}`: key `#{inspect(key)}` not present in struct."
      )
    end

    quote do
      defimpl Wafer.Release, for: unquote(module) do
        def release(%{unquote(key) => inner_conn}), do: Wafer.Release.release(inner_conn)
      end
    end
  end

  def release(unknown), do: {:error, "`Wafer.Release` not implemented for #{inspect(unknown)}"}
end
