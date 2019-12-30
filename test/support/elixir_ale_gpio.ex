defmodule ElixirALE.GPIO do
  @moduledoc false

  def set_int(pid, condition) when is_pid(pid) and condition in [:rising, :falling, :both],
    do: :ok

  def start_link(pin, direction, _opts \\ [])
      when is_integer(pin) and pin >= 0 and direction in [:in, :out],
      do: {:ok, self()}

  def release(pid) when is_pid(pid), do: :ok

  def read(pid) when is_pid(pid), do: 0
  def write(pid, value) when is_pid(pid) and value in [0, 1], do: :ok
end
