defprotocol Wafer.GPIO do
  alias Wafer.Conn

  @moduledoc """
  A `GPIO` is a physical pin which can be read from and written to.

  Some hardware supports interrupts, some has internal pull up/down resistors.
  Wafer supports all of these, however not all drivers do.

  ## Deriving

  If you're implementing your own `Conn` type that simply delegates to one of
  the lower level drivers then you can derive this protocol automatically:

  ```elixir
  defstruct MyPin do
    @derive Wafer.GPIO
    defstruct [:conn]
  end
  ```

  If your type uses a key other than `conn` for the inner connection you can
  specify it while deriving:

  ```elixir
  defstruct MyPin do
    @derive {Wafer.GPIO, key: :gpio_conn}
    defstruct [:gpio_conn]
  end
  ```
  """

  @type pin_direction :: :in | :out
  @type pin_condition :: :none | :rising | :falling | :both
  @type pin_value :: 0 | 1
  @type pull_mode :: :not_set | :none | :pull_up | :pull_down

  @type interrupt_options :: [interrupt_option]
  @type interrupt_option :: {:suppress_glitches, boolean} | {:receiver, pid}

  @doc """
  Read the current pin value.
  """
  @spec read(Conn.t()) :: {:ok, pin_value, Conn.t()} | {:error, reason :: any}
  def read(conn)

  @doc """
  Set the pin value.
  """
  @spec write(Conn.t(), pin_value) :: {:ok, Conn.t()} | {:error, reason :: any}
  def write(conn, pin_value)

  @doc """
  Set the pin direction.
  """
  @spec direction(Conn.t(), pin_direction) :: {:ok, Conn.t()} | {:error, reason :: any}
  def direction(conn, pin_direction)

  @doc """
  Enable an interrupt for this connection and trigger.

  Interrupts will be sent to the calling process as messages in the form of
  `{:interrupt, Conn.t(), pin_condition}`.

  ## Implementors note

  `Wafer` starts it's own `Registry` named `Wafer.InterruptRegistry` which you
  can use to publish your interrupts to using the above format.  The registry
  key is set as follows: `{PublishingModule, pin, pin_condition}`.  You can see
  examples in the `CircuitsGPIODispatcher` and `ElixirALEGPIODispatcher`
  modules.
  """
  @spec enable_interrupt(Conn.t(), pin_condition) :: {:ok, Conn.t()} | {:error, reason :: any}
  def enable_interrupt(conn, pin_condition)

  @doc """
  Disables interrupts for this connection and trigger.
  """
  @spec disable_interrupt(Conn.t(), pin_condition) :: {:ok, Conn.t()} | {:error, reason :: any}
  def disable_interrupt(conn, pin_condition)

  @doc """
  Set the pull mode for this pin.

  If the hardware contains software-switchable pull-up and/or pull-down
  resistors you can configure them this way.  If they are not supported then
  this function will return `{:error, :not_supported}`.
  """
  @spec pull_mode(Conn.t(), pull_mode) :: {:ok, Conn.t()} | {:error, reason :: any}
  def pull_mode(conn, pull_mode)
end

defimpl Wafer.GPIO, for: Any do
  defmacro __deriving__(module, struct, options) do
    key = Keyword.get(options, :key, :conn)

    unless Map.has_key?(struct, key) do
      raise(
        "Unable to derive `Wafer.GPIO` for `#{module}`: key `#{inspect(key)}` not present in struct."
      )
    end

    quote do
      defimpl Wafer.GPIO, for: unquote(module) do
        import Wafer.Guards
        alias Wafer.GPIO

        def read(%{unquote(key) => inner_conn} = conn) do
          with {:ok, pin_value, inner_conn} <- GPIO.read(inner_conn),
               do: {:ok, pin_value, Map.put(conn, unquote(key), inner_conn)}
        end

        def write(%{unquote(key) => inner_conn} = conn, pin_value) when is_pin_value(pin_value) do
          with {:ok, inner_conn} <- GPIO.write(inner_conn, pin_value),
               do: {:ok, Map.put(conn, unquote(key), inner_conn)}
        end

        def direction(%{unquote(key) => inner_conn} = conn, pin_direction)
            when is_pin_direction(pin_direction) do
          with {:ok, inner_conn} <- GPIO.direction(inner_conn, pin_direction),
               do: {:ok, Map.put(conn, unquote(key), inner_conn)}
        end

        def enable_interrupt(%{unquote(key) => inner_conn} = conn, pin_condition)
            when is_pin_condition(pin_condition) do
          with {:ok, inner_conn} <- GPIO.enable_interrupt(inner_conn, pin_condition),
               do: {:ok, Map.put(conn, unquote(key), inner_conn)}
        end

        def disable_interrupt(%{unquote(key) => inner_conn} = conn, pin_condition)
            when is_pin_condition(pin_condition) do
          with {:ok, inner_conn} <- GPIO.disable_interrupt(inner_conn, pin_condition),
               do: {:ok, Map.put(conn, unquote(key), inner_conn)}
        end

        def pull_mode(%{unquote(key) => inner_conn} = conn, pull_mode)
            when is_pin_pull_mode(pull_mode) do
          with {:ok, inner_conn} <- GPIO.pull_mode(inner_conn, pull_mode),
               do: {:ok, Map.put(conn, unquote(key), inner_conn)}
        end
      end
    end
  end

  def read(unknown), do: {:error, "`Wafer.GPIO` not implemented for `#{inspect(unknown)}"}

  def write(unknown, _pin_value),
    do: {:error, "`Wafer.GPIO` not implemented for `#{inspect(unknown)}"}

  def direction(unknown, _pin_direction),
    do: {:error, "`Wafer.GPIO` not implemented for `#{inspect(unknown)}"}

  def enable_interrupt(unknown, _pin_condition),
    do: {:error, "`Wafer.GPIO` not implemented for `#{inspect(unknown)}`"}

  def disable_interrupt(unknown, _pin_condition),
    do: {:error, "`Wafer.GPIO` not implemented for `#{inspect(unknown)}`"}

  def pull_mode(unknown, _pull_mode),
    do: {:error, "`Wafer.GPIO` not implemented for `#{inspect(unknown)}`"}
end
