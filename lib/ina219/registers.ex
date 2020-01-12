defmodule INA219.Registers do
  use Wafer.Registers

  @moduledoc """
  The INA219 uses a bank of registers for holding configuration settings,
  measurement results, maximum/minimum limits, and status information.

  ## Registers

  ### Configuration register

  All-register reset, settings for bus voltage range, PGA Gain, ADC
  resolution/averaging.  Read write.

  ### Shunt Voltage register

  Shunt voltage measurement data. Read only.

  ### Bus Voltage register

  Bus voltage measurement data. Read-only,

  ### Power register

  Power measurement data. Read only.

  ### Current register

  Contains the value of the current flowing through the shunt resistor.  Read only.

  ### Calibration register

  Sets full-scale range and LSB of current and power measurements. Overall
  system calibration.  Read write.
  """

  defregister(:configuration, 0, :rw, 2)
  defregister(:shunt_voltage, 1, :ro, 2)
  defregister(:bus_voltage, 2, :ro, 2)
  defregister(:power, 3, :ro, 2)
  defregister(:current, 4, :ro, 2)
  defregister(:calibration, 5, :rw, 2)
end
