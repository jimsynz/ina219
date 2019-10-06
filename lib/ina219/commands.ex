defmodule INA219.Commands do
  use Bitwise
  require Logger
  alias INA219.Registers

  @moduledoc """
  This module allows execution of all I2C commands to and from the INA219.

  It's pretty handy that the INA219 only has two-byte registers, which makes
  life a lot simpler for me.
  """

  @doc """
  Power-on-reset the device,
  """
  def reset!(pid) do
    conf = Registers.configuration(pid)
    conf = conf ||| 0x8000
    Registers.configuration(pid, conf)
  end

  @doc """
  This is a convenient helper function to set the configuration to the right values
  for 32V input voltage range and 2A current range at the cost of accuracy.
  This only works for devices with a 0.1Ω shunt resistor (ie Adafruit's breakout).

  Make sure that you configure your device with a `current_divisor` of `10` and a
  `power_divisor` of `2`.
  """
  def calibrate_32V_2A!(pid) do
    with :ok <- calibrate(pid, 4096),
         :ok <- bus_voltage_range(pid, 32),
         :ok <- shunt_voltage_pga(pid, 8),
         :ok <- bus_adc_resolution_and_averaging(pid, {1, 12}),
         :ok <- shunt_adc_resolution_and_averaging(pid, {1, 12}),
         :ok <- mode(pid, :shunt_and_bus_voltage_continuous) do
      :ok
    end
  end

  @doc """
  This is a convenient helper function to set the configuration to the right values
  for 32V input voltage range and 1A current range at the cost of accuracy.
  This only works for devices with a 0.1Ω shunt resistor (ie Adafruit's breakout).

  Make sure that you configure your device with a `current_divisor` of `25` and a
  `power_divisor` of `1`.
  """
  def calibrate_32V_1A!(pid) do
    with :ok <- calibrate(pid, 10240),
         :ok <- bus_voltage_range(pid, 32),
         :ok <- shunt_voltage_pga(pid, 8),
         :ok <- bus_adc_resolution_and_averaging(pid, {1, 12}),
         :ok <- shunt_adc_resolution_and_averaging(pid, {1, 12}),
         :ok <- mode(pid, :shunt_and_bus_voltage_continuous) do
      :ok
    end
  end

  @doc """
  This is a convenient helper function to set the configuration to the right values
  for 16V input and 400mA current range at the highest resolution (0.1mA).
  This only works for devices with a 0.1Ω shunt resistor (ie Adafruit's breakout).

  Make sure that you configure your device with a `current_divisor` of `20` and a
  `power_divisor` of `1`.
  """
  def calibrate_16V_400mA!(pid) do
    with :ok <- calibrate(pid, 8192),
         :ok <- bus_voltage_range(pid, 16),
         :ok <- shunt_voltage_pga(pid, 1),
         :ok <- bus_adc_resolution_and_averaging(pid, {1, 12}),
         :ok <- shunt_adc_resolution_and_averaging(pid, {1, 12}),
         :ok <- mode(pid, :shunt_and_bus_voltage_continuous) do
      :ok
    end
  end

  @doc """
  Retrieve the configured bus voltage range.
  """
  def bus_voltage_range(pid) do
    conf = Registers.configuration(pid)
    conf = conf >>> 13 &&& 1
    elem({16, 32}, conf)
  end

  @doc """
  Set the configured bus voltage range to either 16 or 32V.
  """
  def bus_voltage_range(pid, 16) do
    conf = Registers.configuration(pid)
    # ~~~(1 <<< 13)
    conf = conf &&& -0x2001
    Registers.configuration(pid, conf)
  end

  def bus_voltage_range(pid, 32) do
    conf = Registers.configuration(pid)
    # (1 <<< 13)
    conf = conf ||| 0x2000
    Registers.configuration(pid, conf)
  end

  @doc """
  Retrieve the configured shunt voltage PGA.

  Returns the `gain` value.

  Valid values are:
    `1` - gain  1, range  +40mV.
    `2` - gain +2, range  +80mV.
    `4` - gain +4, range +160mV.
    `8` - gain +8, range +320mV.
  """
  def shunt_voltage_pga(pid) do
    conf = Registers.configuration(pid)
    elem({1, 2, 4, 8}, conf >>> 11 &&& 3)
  end

  @doc """
  Set the configured shunt voltage PGA to a configured value.

  Valid values are:
    `1` - gain  1, range  +40mV.
    `2` - gain +2, range  +80mV.
    `4` - gain +4, range +160mV.
    `8` - gain +8, range +320mV.
  """

  def shunt_voltage_pga(pid, 1), do: set_shunt_voltage_pga(pid, 0)
  def shunt_voltage_pga(pid, 2), do: set_shunt_voltage_pga(pid, 1)
  def shunt_voltage_pga(pid, 4), do: set_shunt_voltage_pga(pid, 2)
  def shunt_voltage_pga(pid, 8), do: set_shunt_voltage_pga(pid, 3)

  defp set_shunt_voltage_pga(pid, value) do
    conf = Registers.configuration(pid)
    head = conf >>> 13
    tail = conf &&& 2047
    conf = (head <<< 13) + (value <<< 11) + tail
    Registers.configuration(pid, conf)
  end

  @doc """
  Retrieve the bus ADC resolution and averaging.

  Returns the number of samples and the resolution as a two element tuple.
  eg `{1, 9}` refers to 9-bit ADC resolution and 1-sample averaging.
  """
  def bus_adc_resolution_and_averaging(pid) do
    conf = Registers.configuration(pid)

    case conf >>> 7 &&& 15 do
      0 -> {1, 9}
      1 -> {1, 10}
      2 -> {1, 11}
      3 -> {1, 12}
      4 -> {1, 9}
      5 -> {1, 10}
      6 -> {1, 11}
      7 -> {1, 12}
      8 -> {1, 12}
      9 -> {2, 12}
      10 -> {4, 12}
      11 -> {8, 12}
      12 -> {16, 12}
      13 -> {32, 12}
      14 -> {64, 12}
      15 -> {128, 12}
    end
  end

  @doc """
  Set the bus ADC resolution and averaging.

  Expects a tuple of the form `{samples, bits}`. Be aware that changing this value affects
  the amount of time it takes to compute values. Refer to the datasheet for more information.

  Valid values are:

  * `{  1,  9}` - 1 sample averaging and 9 bit ADC resolution.
  * `{  1, 10}` - 1 sample averaging and 10 bit ADC resolution.
  * `{  1, 11}` - 1 sample averaging and 11 bit ADC resolution.
  * `{  1, 12}` - 1 sample averaging and 12 bit ADC resolution.
  * `{  2, 12}` - 2 sample averaging and 12 bit ADC resolution.
  * `{  4, 12}` - 4 sample averaging and 12 bit ADC resolution.
  * `{  8, 12}` - 8 sample averaging and 12 bit ADC resolution.
  * `{ 16, 12}` - 16 sample averaging and 12 bit ADC resolution.
  * `{ 32, 12}` - 32 sample averaging and 12 bit ADC resolition.
  * `{ 64, 12}` - 64 sample averaging and 12 bit ADC resolution.
  * `{128, 12}` - 128 sample averaging and 12 bit ADB resolution.
  """
  def bus_adc_resolution_and_averaging(pid, {1, 9}),
    do: set_bus_adc_resolution_and_averaging(pid, 0)

  def bus_adc_resolution_and_averaging(pid, {1, 10}),
    do: set_bus_adc_resolution_and_averaging(pid, 1)

  def bus_adc_resolution_and_averaging(pid, {1, 11}),
    do: set_bus_adc_resolution_and_averaging(pid, 2)

  def bus_adc_resolution_and_averaging(pid, {1, 12}),
    do: set_bus_adc_resolution_and_averaging(pid, 3)

  def bus_adc_resolution_and_averaging(pid, {2, 12}),
    do: set_bus_adc_resolution_and_averaging(pid, 9)

  def bus_adc_resolution_and_averaging(pid, {4, 12}),
    do: set_bus_adc_resolution_and_averaging(pid, 10)

  def bus_adc_resolution_and_averaging(pid, {8, 12}),
    do: set_bus_adc_resolution_and_averaging(pid, 11)

  def bus_adc_resolution_and_averaging(pid, {16, 12}),
    do: set_bus_adc_resolution_and_averaging(pid, 12)

  def bus_adc_resolution_and_averaging(pid, {32, 12}),
    do: set_bus_adc_resolution_and_averaging(pid, 13)

  def bus_adc_resolution_and_averaging(pid, {64, 12}),
    do: set_bus_adc_resolution_and_averaging(pid, 14)

  def bus_adc_resolution_and_averaging(pid, {128, 12}),
    do: set_bus_adc_resolution_and_averaging(pid, 15)

  defp set_bus_adc_resolution_and_averaging(pid, i) do
    conf = Registers.configuration(pid)
    head = conf >>> 11
    tail = conf &&& 127
    Registers.configuration(pid, (head <<< 11) + (i <<< 7) + tail)
  end

  @doc """
  Retrieve the shunt ADC resolution.

  Returns the number of samples and the resolution as a two element tuple.
  eg `{1, 9}` refers to 9-bit ADC resolution and 1-sample averaging.
  """
  def shunt_adc_resolution_and_averaging(pid) do
    conf = Registers.configuration(pid)

    case conf >>> 3 &&& 15 do
      0 -> {1, 9}
      1 -> {1, 10}
      2 -> {1, 11}
      3 -> {1, 12}
      4 -> {1, 9}
      5 -> {1, 10}
      6 -> {1, 11}
      7 -> {1, 12}
      8 -> {1, 12}
      9 -> {2, 12}
      10 -> {4, 12}
      11 -> {8, 12}
      12 -> {16, 12}
      13 -> {32, 12}
      14 -> {64, 12}
      15 -> {128, 12}
    end
  end

  @doc """
  Set the shunt ADC resolution and averaging.

  Expects a tuple of the form `{samples, bits}`. Be aware that changing this value affects
  the amount of time it takes to compute values. Refer to the datasheet for more information.

  Valid values are:

  * `{  1,  9}` - 1 sample averaging and 9 bit ADC resolution.
  * `{  1, 10}` - 1 sample averaging and 10 bit ADC resolution.
  * `{  1, 11}` - 1 sample averaging and 11 bit ADC resolution.
  * `{  1, 12}` - 1 sample averaging and 12 bit ADC resolution.
  * `{  2, 12}` - 2 sample averaging and 12 bit ADC resolution.
  * `{  4, 12}` - 4 sample averaging and 12 bit ADC resolution.
  * `{  8, 12}` - 8 sample averaging and 12 bit ADC resolution.
  * `{ 16, 12}` - 16 sample averaging and 12 bit ADC resolution.
  * `{ 32, 12}` - 32 sample averaging and 12 bit ADC resolition.
  * `{ 64, 12}` - 64 sample averaging and 12 bit ADC resolution.
  * `{128, 12}` - 128 sample averaging and 12 bit ADB resolution.
  """
  def shunt_adc_resolution_and_averaging(pid, {1, 9}),
    do: set_shunt_adc_resolution_and_averaging(pid, 0)

  def shunt_adc_resolution_and_averaging(pid, {1, 10}),
    do: set_shunt_adc_resolution_and_averaging(pid, 1)

  def shunt_adc_resolution_and_averaging(pid, {1, 11}),
    do: set_shunt_adc_resolution_and_averaging(pid, 2)

  def shunt_adc_resolution_and_averaging(pid, {1, 12}),
    do: set_shunt_adc_resolution_and_averaging(pid, 3)

  def shunt_adc_resolution_and_averaging(pid, {2, 12}),
    do: set_shunt_adc_resolution_and_averaging(pid, 9)

  def shunt_adc_resolution_and_averaging(pid, {4, 12}),
    do: set_shunt_adc_resolution_and_averaging(pid, 10)

  def shunt_adc_resolution_and_averaging(pid, {8, 12}),
    do: set_shunt_adc_resolution_and_averaging(pid, 11)

  def shunt_adc_resolution_and_averaging(pid, {16, 12}),
    do: set_shunt_adc_resolution_and_averaging(pid, 12)

  def shunt_adc_resolution_and_averaging(pid, {32, 12}),
    do: set_shunt_adc_resolution_and_averaging(pid, 13)

  def shunt_adc_resolution_and_averaging(pid, {64, 12}),
    do: set_shunt_adc_resolution_and_averaging(pid, 14)

  def shunt_adc_resolution_and_averaging(pid, {128, 12}),
    do: set_shunt_adc_resolution_and_averaging(pid, 15)

  defp set_shunt_adc_resolution_and_averaging(pid, i) do
    conf = Registers.configuration(pid)
    head = conf >>> 7
    tail = conf &&& 7
    Registers.configuration(pid, (head <<< 7) + (i <<< 3) + tail)
  end

  @doc """
  Retrieve the current operating mode of the device.
  """
  def mode(pid) do
    conf = Registers.configuration(pid)

    case conf &&& 7 do
      0 -> :power_down
      1 -> :shunt_voltage_triggered
      2 -> :bus_voltage_triggered
      3 -> :adc_off
      4 -> :shunt_voltage_continuous
      5 -> :bus_voltage_continuous
      6 -> :shunt_and_bus_voltage_continuous
    end
  end

  @doc """
  Set the current operating mode for the device.

  Valid values are:
      :power_down
      :shunt_voltage_triggered
      :bus_voltage_triggered
      :adc_off
      :shunt_voltage_continuous
      :bus_voltage_continuous
      :shunt_and_bus_voltage_continuous
  """
  def mode(pid, :power_down), do: set_mode(pid, 0)
  def mode(pid, :shunt_voltage_triggered), do: set_mode(pid, 1)
  def mode(pid, :bus_voltage_triggered), do: set_mode(pid, 2)
  def mode(pid, :adc_off), do: set_mode(pid, 3)
  def mode(pid, :shunt_voltage_continuous), do: set_mode(pid, 4)
  def mode(pid, :bus_voltage_continuous), do: set_mode(pid, 5)
  def mode(pid, :shunt_and_bus_voltage_continuous), do: set_mode(pid, 6)

  defp set_mode(pid, i) do
    conf = Registers.configuration(pid)
    head = conf >>> 3
    Registers.configuration(pid, (head <<< 3) + i)
  end

  @doc """
  Are new samples ready since the last time you read them?
  Calling this function will clear the value until next time new samples are ready.
  """
  def conversion_ready?(pid) do
    r = Registers.bus_voltage(pid)

    case r >>> 1 &&& 1 do
      0 -> false
      1 -> true
    end
  end

  @doc """
  Returns `true` when power or current calculations are out of range.
  This indicates that current and power data may be meaningless.
  """
  def math_overflow?(pid) do
    r = Registers.bus_voltage(pid)

    case r &&& 1 do
      0 -> false
      1 -> true
    end
  end

  @doc """
  Returns the bus voltage in mV.
  """
  def bus_voltage(pid), do: (Registers.bus_voltage(pid) >>> 3) * 4 * 0.001

  @doc """
  Returns the shunt voltage in mV.
  """
  def shunt_voltage(pid), do: Registers.shunt_voltage(pid) * 0.01

  @doc """
  Returns the current in mA.
  """
  def current(pid, divisor), do: Registers.current(pid) / divisor

  @doc """
  Returns the power in mW
  """
  def power(pid, divisor), do: Registers.power(pid) / divisor

  @doc """
  Set the calibration value.
  """
  def calibrate(pid, value), do: Registers.calibration(pid, value)
end
