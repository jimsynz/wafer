defprotocol Wafer.GPIOProto do
  alias Wafer.{Conn, GPIO}

  @moduledoc """
  A `GPIO` is a physical pin which can be read from and written to.  This is the
  protocol used to interract with the pin.  Used via `Wafer.GPIO`.
  """

  @doc """
  Read the current pin value.
  """
  @spec read(Conn.t()) :: {:ok, GPIO.pin_value()} | {:error, reason :: any}
  def read(conn)

  @doc """
  Set the pin value.
  """
  @spec write(Conn.t(), GPIO.pin_value()) :: {:ok, Conn.t()} | {:error, reason :: any}
  def write(conn, pin_value)

  @doc """
  Set the pin direction.
  """
  @spec direction(Conn.t(), GPIO.pin_direction()) :: {:ok, Conn.t()} | {:error, reason :: any}
  def direction(conn, pin_direction)

  @doc """
  Enable an interrupt for this pin.

  Interrupts will be sent to the calling process as messages in the form of
  `{:interrupt, Conn.t(), GPIO.pin_value()}`.

  ## Implementors note

  `Wafer` starts it's own `Registry` named `Wafer.InterruptRegistry` which
  you should publish your interrupts to using the above format.  The registry
  key is set as follows: `{Conn.t(), pin_trigger}`.
  """
  @spec enable_interrupt(Conn.t(), GPIO.pin_trigger()) ::
          {:ok, Conn.t()} | {:error, reason :: any}
  def enable_interrupt(conn, pin_trigger)

  @doc """
  Set the pull-mode for this pin.

  ## Implementors note

  If your GPIO device does not contain any internal resistors for pull up or
  pull down operation then simply return `{:error, :not_supported}` from this
  call.
  """
  @spec pull_mode(Conn.t(), GPIO.pull_mode()) :: {:ok, Conn.t()} | {:error, reason :: any}
  def pull_mode(conn, pull_mode)
end
