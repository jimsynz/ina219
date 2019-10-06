defmodule INA219.Registers do
  alias ElixirALE.I2C
  use Bitwise
  require Logger

  @moduledoc """
  Handle reading and writing directly from each device's registers.
  """

  @doc """
  Read the device's configuration register.
  """
  def configuration(pid), do: read_register(pid, 0)

  @doc """
  Write `bytes` to the device's configuration register.
  """
  def configuration(pid, bytes), do: write_register(pid, 0, bytes)

  @doc """
  Read the shunt voltage register.
  """
  def shunt_voltage(pid), do: read_register(pid, 1)

  @doc """
  Read the bus voltage register.
  """
  def bus_voltage(pid), do: read_register(pid, 2)

  @doc """
  Read the power register.
  """
  def power(pid), do: read_register(pid, 3)

  @doc """
  Read the current register.
  """
  def current(pid), do: read_register(pid, 4)

  @doc """
  Read the calibration register.
  """
  def calibration(pid), do: read_register(pid, 5)

  @doc """
  Write `bytes` to the device's calibration register.
  """
  def calibration(pid, bytes), do: write_register(pid, 5, bytes)

  defp read_register(pid, register) do
    with :ok <- I2C.write(pid, <<register>>),
         <<value::integer-size(16)>> <- I2C.read(pid, 2),
         do: value
  end

  defp write_register(pid, register, bytes) do
    msb = bytes >>> 8
    lsb = bytes &&& 0xFF
    I2C.write(pid, <<register, msb, lsb>>)
  end
end
