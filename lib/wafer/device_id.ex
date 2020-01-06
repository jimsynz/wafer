defprotocol Wafer.DeviceID do
  alias Wafer.Conn

  @moduledoc """
  Allows devices to generate a unique identifier.

  Mainly used for `InterruptRegistry` but you might find it useful too.  Can be
  derived in the same manner as all other `Wafer` protocols.
  """

  @doc """
  Generate a unique identifier for `conn`.
  """
  @spec id(Conn.t()) :: any
  def id(conn)
end

defimpl Wafer.DeviceID, for: Any do
  defmacro __deriving__(module, struct, options) do
    key = Keyword.get(options, :key, :conn)

    unless Map.has_key?(struct, key) do
      raise(
        "Unable to derive `Wafer.DeviceID` for `#{module}`: key `#{inspect(key)}` not present in struct."
      )
    end

    quote do
      defimpl Wafer.DeviceID, for: unquote(module) do
        def id(%{unquote(key) => inner_conn}), do: Wafer.DeviceID.id(inner_conn)
      end
    end
  end

  def id(unknown), do: raise("`Wafer.DeviceID` not implemented for `#{inspect(unknown)}")
end
