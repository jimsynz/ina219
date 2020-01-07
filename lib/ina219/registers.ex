defmodule INA219.Registers do
  use Wafer.Registers

  @moduledoc """
  The INA219 uses a bank of registers for holding configuration settings,
  measurement results, maximum/minimum limits, and status information.
  """

  @doc """
  All-register reset, settings for bus voltage range, PGA Gain, ADC
  resolution/averaging.
  """
  defregister(:configuration, 0, :rw, 2)

  @doc """
  Shunt voltage measurement data.
  """
  defregister(:shunt_voltage, 1, :ro, 2)

  @doc """
  Bus voltage measurement data.
  """
  defregister(:bus_voltage, 2, :ro, 2)

  @doc """
  Power measurement data.
  """
  defregister(:power, 3, :ro, 2)

  @doc """
  Contains the value of the current flowing through the shunt resistor.
  """
  defregister(:current, 4, :ro, 2)

  @doc """
  Sets full-scale range and LSB of current and power measurements. Overall
  system calibration.
  """
  defregister(:calibration, 5, :rw, 2)
end
