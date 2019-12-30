defprotocol Wafer.GPIO do
  alias Wafer.Conn

  @moduledoc """
  A `GPIO` is a physical pin which can be read from and written to.
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
