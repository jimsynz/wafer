defmodule Wafer.GPIO do
  alias Wafer.{Conn, GPIOProto, InterruptRegistry}

  @moduledoc """
  A `GPIO` is a physical pin which can be read from and written to.
  """

  @type pin_direction :: :in | :out
  @type pin_trigger :: :none | :rising | :falling | :both
  @type pin_value :: 0 | 1
  @type pull_mode :: :not_set | :none | :pull_up | :pull_down

  @type interrupt_options :: [interrupt_option]
  @type interrupt_option :: {:suppress_glitches, boolean} | {:receiver, pid}

  @doc """
  Read the current pin value.
  """
  @spec read(Conn.t()) :: {:ok, pin_value, Conn.t()} | {:error, reason :: any}
  defdelegate read(conn), to: GPIOProto

  @doc """
  Set the pin value.
  """
  @spec write(Conn.t(), pin_value) :: {:ok, Conn.t()} | {:error, reason :: any}
  defdelegate write(conn, pin_value), to: GPIOProto

  @doc """
  Set the pin direction.
  """
  @spec direction(Conn.t(), pin_direction) :: {:ok, Conn.t()} | {:error, reason :: any}
  defdelegate direction(conn, pin_direction), to: GPIOProto

  @doc """
  Enable an interrupt for this pin.

  Interrupts will be sent to the calling process as messages in the form of
  `{:interrupt, Conn.t(), pin_value}`.

  ## Implementors note

  `Wafer` starts it's own `Registry` named `Wafer.InterruptRegistry` which
  you should publish your interrupts to using the above format.  The registry
  key is set as follows: `{Conn.t(), pin_trigger}`.
  """
  @spec enable_interrupt(Conn.t(), pin_trigger) :: {:ok, Conn.t()} | {:error, reason :: any}
  def enable_interrupt(conn, pin_trigger) do
    with {:ok, _pid} <- Registry.register(InterruptRegistry, {conn, pin_trigger}, nil),
         {:ok, conn} <- GPIOProto.enable_interrupt(conn, pin_trigger),
         do: {:ok, conn}
  end

  @doc """
  Set the pull mode for this pin.

  If the hardware contains software-switchable pull-up and/or pull-down
  resistors you can configure them this way.  If they are not supported then
  this function will return `{:error, :not_supported}`.
  """
  @spec pull_mode(Conn.t(), pull_mode) :: {:ok, Conn.t()} | {:error, reason :: any}
  defdelegate pull_mode(conn, pull_mode), to: GPIOProto
end
