defmodule INA219 do
  @derive [Wafer.Chip, Wafer.DeviceID]
  defstruct ~w[conn current_divisor power_divisor]a
  @behaviour Wafer.Conn
  alias Wafer.Conn
  import INA219.Registers

  @moduledoc """
  INA219 Driver using Wafer.
  """

  @type t :: %INA219{conn: Conn.t(), current_divisor: number, power_divisor: number}
  @type acquire_options :: [acquire_option]
  @type acquire_option ::
          {:conn, Conn.t()} | {:current_divisor, number} | {:power_divisor, number}
  @type sample_averaging :: 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128
  @type sample_resolution :: 9 | 10 | 12
  @type operating_mode ::
          :power_down
          | :shunt_voltage_triggered
          | :bus_voltage_triggered
          | :adc_off
          | :shunt_voltage_continuous
          | :bus_voltage_continuous
          | :shunt_and_bus_voltage_continuous
  @type shunt_voltage_pga :: 1 | 2 | 4 | 8
  @type millivolts :: float
  @type volts :: float
  @type milliamps :: float
  @type milliwatts :: float

  @doc """
  Acquire a connection to the INA219 device using the passed in I2C connection.

  ## Options:
  - `conn` an I2C connection, probably from `ElixirALE.I2C` or `Circuits.I2C`.
  - `current_divisor` see `INA219.Commands` for more information.
  - `power_divisor` see `INA219.Commands` for more information.
  """
  @spec acquire(acquire_options) :: {:ok, t} | {:error, reason :: any}
  @impl Wafer.Conn
  def acquire(options) do
    with {:ok, conn} <- Keyword.fetch(options, :conn),
         {:ok, current_divisor} <- Keyword.fetch(options, :current_divisor),
         {:ok, power_divisor} <- Keyword.fetch(options, :power_divisor) do
      {:ok, %INA219{conn: conn, current_divisor: current_divisor, power_divisor: power_divisor}}
    else
      :error ->
        {:error,
         "`INA219.acquire/1` requires the `conn`, `current_divisor` and `power_divisor` options."}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Release the connection to the device.
  """
  @spec release(t) :: :ok
  @impl Wafer.Conn
  def release(%INA219{conn: %{__struct__: mod} = inner} = _conn),
    do: apply(mod, :release, [inner])

  @doc """
  Power-on-reset the device,
  """
  @spec reset(t) :: :ok | {:error, reason :: any}
  def reset(conn) do
    update_configuration(conn, fn <<_::size(1), conf::size(15)>> ->
      <<1::size(1), conf::size(15)>>
    end)
  end

  @doc """
  This is a convenient helper function to set the configuration to the right values
  for 32V input voltage range and 2A current range at the cost of accuracy.
  This only works for devices with a 0.1Ω shunt resistor (ie Adafruit's breakout).

  Make sure that you configure your device with a `current_divisor` of `10` and a
  `power_divisor` of `2`.
  """
  @spec calibrate_32V_2A(t) :: :ok | {:error, reason :: any}
  # credo:disable-for-next-line
  def calibrate_32V_2A(conn) do
    with :ok <- calibrate(conn, 4096),
         :ok <- bus_voltage_range(conn, 32),
         :ok <- shunt_voltage_pga(conn, 8),
         :ok <- bus_adc_resolution_and_averaging(conn, {1, 12}),
         :ok <- shunt_adc_resolution_and_averaging(conn, {1, 12}),
         :ok <- mode(conn, :shunt_and_bus_voltage_continuous) do
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
  @spec calibrate_32V_1A(t) :: :ok | {:error, reason :: any}
  # credo:disable-for-next-line
  def calibrate_32V_1A(conn) do
    with :ok <- calibrate(conn, 10_240),
         :ok <- bus_voltage_range(conn, 32),
         :ok <- shunt_voltage_pga(conn, 8),
         :ok <- bus_adc_resolution_and_averaging(conn, {1, 12}),
         :ok <- shunt_adc_resolution_and_averaging(conn, {1, 12}),
         :ok <- mode(conn, :shunt_and_bus_voltage_continuous) do
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
  @spec calibrate_16V_400mA(t) :: :ok | {:error, reason :: any}
  # credo:disable-for-next-line
  def calibrate_16V_400mA(conn) do
    with :ok <- calibrate(conn, 8192),
         :ok <- bus_voltage_range(conn, 16),
         :ok <- shunt_voltage_pga(conn, 1),
         :ok <- bus_adc_resolution_and_averaging(conn, {1, 12}),
         :ok <- shunt_adc_resolution_and_averaging(conn, {1, 12}),
         :ok <- mode(conn, :shunt_and_bus_voltage_continuous) do
      :ok
    end
  end

  @doc """
  Retrieve the configured bus voltage range.
  """
  @spec bus_voltage_range(t) :: {:ok, 16 | 32} | {:error, reason :: any}
  def bus_voltage_range(conn) do
    with {:ok, <<_::size(2), brng::size(1), _::size(13)>>} <-
           read_configuration(conn) do
      {:ok, elem({16, 32}, brng)}
    end
  end

  @doc """
  Set the configured bus voltage range to either 16 or 32V.
  """
  @spec bus_voltage_range(t, 16 | 32) :: :ok | {:error, reason :: any}
  def bus_voltage_range(conn, 16) do
    update_configuration(conn, fn <<head::size(2), _::size(1), tail::size(13)>> ->
      <<head::size(2), 0::size(1), tail::size(13)>>
    end)
  end

  def bus_voltage_range(conn, 32) do
    update_configuration(conn, fn <<head::size(2), _::size(1), tail::size(13)>> ->
      <<head::size(2), 1::size(1), tail::size(13)>>
    end)
  end

  @doc """
  Retrieve the configured shunt voltage PGA.

  Returns the `gain` value.

  Valid values are:
    - `1` - gain  1, range  +40mV.
    - `2` - gain +2, range  +80mV.
    - `4` - gain +4, range +160mV.
    - `8` - gain +8, range +320mV.
  """
  @spec shunt_voltage_pga(t) :: {:ok, shunt_voltage_pga} | {:error, reason :: any}
  def shunt_voltage_pga(conn) do
    with {:ok, <<_::size(3), pga::size(2), _::size(11)>>} <- read_configuration(conn) do
      {:ok, elem({1, 2, 4, 8}, pga)}
    end
  end

  @doc """
  Set the configured shunt voltage PGA to a configured value.

  Valid values are:
    - `1` - gain  1, range  +40mV.
    - `2` - gain +2, range  +80mV.
    - `4` - gain +4, range +160mV.
    - `8` - gain +8, range +320mV.
  """
  @spec shunt_voltage_pga(t, shunt_voltage_pga) :: :ok | {:error, reason :: any}
  def shunt_voltage_pga(conn, 1), do: set_shunt_voltage_pga(conn, 0)
  def shunt_voltage_pga(conn, 2), do: set_shunt_voltage_pga(conn, 1)
  def shunt_voltage_pga(conn, 4), do: set_shunt_voltage_pga(conn, 2)
  def shunt_voltage_pga(conn, 8), do: set_shunt_voltage_pga(conn, 3)

  defp set_shunt_voltage_pga(conn, value) when value in 0..3 do
    update_configuration(conn, fn <<head::size(3), _::size(2), tail::size(11)>> ->
      <<head::size(3), value::size(2), tail::size(11)>>
    end)
  end

  @doc """
  Retrieve the bus ADC resolution and averaging.

  Returns the number of samples and the resolution as a two element tuple.
  eg `{1, 9}` refers to 9-bit ADC resolution and 1-sample averaging.
  """
  @spec bus_adc_resolution_and_averaging(t) ::
          {:ok, {sample_averaging, sample_resolution}} | {:error, reason :: any}
  def bus_adc_resolution_and_averaging(conn) do
    with {:ok, <<_::size(5), res::size(4), _::size(7)>>} <- read_configuration(conn) do
      {:ok, get_bus_adc_res_avg(res)}
    end
  end

  defp get_bus_adc_res_avg(0), do: {1, 9}
  defp get_bus_adc_res_avg(1), do: {1, 10}
  defp get_bus_adc_res_avg(2), do: {1, 11}
  defp get_bus_adc_res_avg(3), do: {1, 12}
  defp get_bus_adc_res_avg(4), do: {1, 9}
  defp get_bus_adc_res_avg(5), do: {1, 10}
  defp get_bus_adc_res_avg(6), do: {1, 11}
  defp get_bus_adc_res_avg(7), do: {1, 12}
  defp get_bus_adc_res_avg(8), do: {1, 12}
  defp get_bus_adc_res_avg(9), do: {2, 12}
  defp get_bus_adc_res_avg(10), do: {4, 12}
  defp get_bus_adc_res_avg(11), do: {8, 12}
  defp get_bus_adc_res_avg(12), do: {16, 12}
  defp get_bus_adc_res_avg(13), do: {32, 12}
  defp get_bus_adc_res_avg(14), do: {64, 12}
  defp get_bus_adc_res_avg(15), do: {128, 12}

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
  @spec bus_adc_resolution_and_averaging(
          t,
          {sample_averaging, sample_resolution}
        ) :: :ok | {:error, reason :: any}
  def bus_adc_resolution_and_averaging(conn, {1, 9}),
    do: set_bus_adc_resolution_and_averaging(conn, 0)

  def bus_adc_resolution_and_averaging(conn, {1, 10}),
    do: set_bus_adc_resolution_and_averaging(conn, 1)

  def bus_adc_resolution_and_averaging(conn, {1, 11}),
    do: set_bus_adc_resolution_and_averaging(conn, 2)

  def bus_adc_resolution_and_averaging(conn, {1, 12}),
    do: set_bus_adc_resolution_and_averaging(conn, 3)

  def bus_adc_resolution_and_averaging(conn, {2, 12}),
    do: set_bus_adc_resolution_and_averaging(conn, 9)

  def bus_adc_resolution_and_averaging(conn, {4, 12}),
    do: set_bus_adc_resolution_and_averaging(conn, 10)

  def bus_adc_resolution_and_averaging(conn, {8, 12}),
    do: set_bus_adc_resolution_and_averaging(conn, 11)

  def bus_adc_resolution_and_averaging(conn, {16, 12}),
    do: set_bus_adc_resolution_and_averaging(conn, 12)

  def bus_adc_resolution_and_averaging(conn, {32, 12}),
    do: set_bus_adc_resolution_and_averaging(conn, 13)

  def bus_adc_resolution_and_averaging(conn, {64, 12}),
    do: set_bus_adc_resolution_and_averaging(conn, 14)

  def bus_adc_resolution_and_averaging(conn, {128, 12}),
    do: set_bus_adc_resolution_and_averaging(conn, 15)

  defp set_bus_adc_resolution_and_averaging(conn, i) do
    update_configuration(conn, fn <<head::size(5), _::size(4), tail::size(7)>> ->
      <<head::size(5), i::size(4), tail::size(7)>>
    end)
  end

  @doc """
  Retrieve the shunt ADC resolution.

  Returns the number of samples and the resolution as a two element tuple.
  eg `{1, 9}` refers to 9-bit ADC resolution and 1-sample averaging.
  """
  @spec shunt_adc_resolution_and_averaging(t) ::
          {:ok, {sample_averaging, sample_resolution}} | {:error, reason :: any}
  def shunt_adc_resolution_and_averaging(conn) do
    with {:ok, <<_::size(9), res::size(4), _::size(3)>>} <- read_configuration(conn) do
      {:ok, get_shunt_adc_res_avg(res)}
    end
  end

  defp get_shunt_adc_res_avg(0), do: {1, 9}
  defp get_shunt_adc_res_avg(1), do: {1, 10}
  defp get_shunt_adc_res_avg(2), do: {1, 11}
  defp get_shunt_adc_res_avg(3), do: {1, 12}
  defp get_shunt_adc_res_avg(4), do: {1, 9}
  defp get_shunt_adc_res_avg(5), do: {1, 10}
  defp get_shunt_adc_res_avg(6), do: {1, 11}
  defp get_shunt_adc_res_avg(7), do: {1, 12}
  defp get_shunt_adc_res_avg(8), do: {1, 12}
  defp get_shunt_adc_res_avg(9), do: {2, 12}
  defp get_shunt_adc_res_avg(10), do: {4, 12}
  defp get_shunt_adc_res_avg(11), do: {8, 12}
  defp get_shunt_adc_res_avg(12), do: {16, 12}
  defp get_shunt_adc_res_avg(13), do: {32, 12}
  defp get_shunt_adc_res_avg(14), do: {64, 12}
  defp get_shunt_adc_res_avg(15), do: {128, 12}

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
  def shunt_adc_resolution_and_averaging(conn, {1, 9}),
    do: set_shunt_adc_resolution_and_averaging(conn, 0)

  def shunt_adc_resolution_and_averaging(conn, {1, 10}),
    do: set_shunt_adc_resolution_and_averaging(conn, 1)

  def shunt_adc_resolution_and_averaging(conn, {1, 11}),
    do: set_shunt_adc_resolution_and_averaging(conn, 2)

  def shunt_adc_resolution_and_averaging(conn, {1, 12}),
    do: set_shunt_adc_resolution_and_averaging(conn, 3)

  def shunt_adc_resolution_and_averaging(conn, {2, 12}),
    do: set_shunt_adc_resolution_and_averaging(conn, 9)

  def shunt_adc_resolution_and_averaging(conn, {4, 12}),
    do: set_shunt_adc_resolution_and_averaging(conn, 10)

  def shunt_adc_resolution_and_averaging(conn, {8, 12}),
    do: set_shunt_adc_resolution_and_averaging(conn, 11)

  def shunt_adc_resolution_and_averaging(conn, {16, 12}),
    do: set_shunt_adc_resolution_and_averaging(conn, 12)

  def shunt_adc_resolution_and_averaging(conn, {32, 12}),
    do: set_shunt_adc_resolution_and_averaging(conn, 13)

  def shunt_adc_resolution_and_averaging(conn, {64, 12}),
    do: set_shunt_adc_resolution_and_averaging(conn, 14)

  def shunt_adc_resolution_and_averaging(conn, {128, 12}),
    do: set_shunt_adc_resolution_and_averaging(conn, 15)

  defp set_shunt_adc_resolution_and_averaging(conn, i) do
    update_configuration(conn, fn <<head::size(9), _::size(4), tail::size(3)>> ->
      <<head::size(9), i::size(4), tail::size(3)>>
    end)
  end

  @doc """
  Retrieve the current operating mode of the device.
  """
  @spec mode(t) :: {:ok, operating_mode} | {:error, reason :: any}
  def mode(conn) do
    with {:ok, <<_::size(13), mode::size(3)>>} <- read_configuration(conn) do
      {:ok, get_mode(mode)}
    end
  end

  defp get_mode(0), do: :power_down
  defp get_mode(1), do: :shunt_voltage_triggered
  defp get_mode(2), do: :bus_voltage_triggered
  defp get_mode(3), do: :shunt_and_bus_voltage_triggered
  defp get_mode(4), do: :adc_off
  defp get_mode(5), do: :shunt_voltage_continuous
  defp get_mode(6), do: :bus_voltage_continuous
  defp get_mode(7), do: :shunt_and_bus_voltage_continuous

  @doc """
  Set the current operating mode for the device.

  Valid values are:
  - `:power_down`
  - `:shunt_voltage_triggered`
  - `:bus_voltage_triggered`
  - `:adc_off`
  - `:shunt_voltage_continuous`
  - `:bus_voltage_continuous`
  - `:shunt_and_bus_voltage_continuous`
  """
  @spec mode(t, operating_mode) :: :ok | {:error, reason :: any}
  def mode(conn, :power_down), do: set_mode(conn, 0)
  def mode(conn, :shunt_voltage_triggered), do: set_mode(conn, 1)
  def mode(conn, :bus_voltage_triggered), do: set_mode(conn, 2)
  def mode(conn, :shunt_and_bus_voltage_triggered), do: set_mode(conn, 3)
  def mode(conn, :adc_off), do: set_mode(conn, 4)
  def mode(conn, :shunt_voltage_continuous), do: set_mode(conn, 5)
  def mode(conn, :bus_voltage_continuous), do: set_mode(conn, 6)
  def mode(conn, :shunt_and_bus_voltage_continuous), do: set_mode(conn, 7)

  defp set_mode(conn, i) do
    update_configuration(conn, fn <<head::size(13), _::size(3)>> ->
      <<head::size(13), i::size(3)>>
    end)
  end

  @doc """
  Are new samples ready since the last time you read them?
  Calling this function will clear the value until next time new samples are ready.
  """
  @spec conversion_ready?(t) :: boolean
  def conversion_ready?(conn) do
    case read_bus_voltage(conn) do
      {:ok, <<_::size(14), 1::size(1), _::size(1)>>} -> true
      _ -> false
    end
  end

  @doc """
  Returns `true` when power or current calculations are out of range.
  This indicates that current and power data may be meaningless.
  """
  @spec math_overflow?(t) :: boolean
  def math_overflow?(conn) do
    case read_bus_voltage(conn) do
      {:ok, <<_::size(15), 1::size(1)>>} -> true
      _ -> false
    end
  end

  @doc """
  Returns the bus voltage in V.
  """
  @spec bus_voltage(t) :: {:ok, volts} | {:error, reason :: any}
  def bus_voltage(conn) do
    with {:ok, <<voltage::13, _::size(3)>>} <- read_bus_voltage(conn) do
      {:ok, voltage * 0.004}
    end
  end

  @doc """
  Returns the shunt voltage in mV.
  """
  @spec shunt_voltage(t) :: {:ok, millivolts} | {:error, reason :: any}
  def shunt_voltage(conn) do
    with {:ok, pga} <- shunt_voltage_pga(conn),
         {:ok, data} <- read_shunt_voltage(conn) do
      calculate_shunt_voltage(pga, data)
    end
  end

  defp calculate_shunt_voltage(1, <<1::size(1), _::size(3), data::size(12)>>),
    do: {:ok, 0 - (0x1000 - data) / 100.0}

  defp calculate_shunt_voltage(1, <<0::size(1), _::size(3), data::size(12)>>),
    do: {:ok, data / 100.0}

  defp calculate_shunt_voltage(2, <<1::size(1), _::size(2), data::size(13)>>),
    do: {:ok, 0 - (0x2000 - data) / 100.0}

  defp calculate_shunt_voltage(2, <<0::size(1), _::size(2), data::size(13)>>),
    do: {:ok, data / 100.0}

  defp calculate_shunt_voltage(4, <<1::size(1), _::size(1), data::size(14)>>),
    do: {:ok, 0 - (0x4000 - data) / 100.0}

  defp calculate_shunt_voltage(4, <<0::size(1), _::size(1), data::size(14)>>),
    do: {:ok, data / 100.0}

  defp calculate_shunt_voltage(8, <<1::size(1), data::size(15)>>),
    do: {:ok, 0 - (0x8000 - data) / 100.0}

  defp calculate_shunt_voltage(8, <<0::size(1), data::size(15)>>), do: {:ok, data / 100.0}

  defp calculate_shunt_voltage(_, _), do: {:error, "Invalid shunt voltage value"}

  @doc """
  Returns the current in mA.
  """
  @spec current(t) :: {:ok, milliamps} | {:error, reason :: any}
  def current(%{current_divisor: divisor} = conn) when is_float(divisor) do
    with {:ok, <<data::size(16)>>} <- read_current(conn) do
      {:ok, data / divisor}
    end
  end

  def current(%{current_divisor: divisor} = conn) when is_integer(divisor) do
    with {:ok, <<data::size(16)>>} <- read_current(conn) do
      {:ok, data / (divisor * 1.0)}
    end
  end

  @doc """
  Returns the power in mW
  """
  @spec power(t) :: {:ok, milliwatts} | {:error, reason :: any}
  def power(%{power_divisor: divisor} = conn) when is_float(divisor) do
    with {:ok, <<data::size(16)>>} <- read_power(conn) do
      {:ok, data / divisor}
    end
  end

  def power(%{power_divisor: divisor} = conn) when is_integer(divisor) do
    with {:ok, <<data::size(16)>>} <- read_power(conn) do
      {:ok, data / (divisor * 1.0)}
    end
  end

  @doc """
  Get the calibration value.
  """
  @spec calibrate(t) :: {:ok, non_neg_integer} | {:error, reason :: any}
  def calibrate(conn) do
    with {:ok, <<data::size(16)>>} <- read_calibration(conn) do
      {:ok, data}
    end
  end

  @doc """
  Set the calibration value.
  """
  @spec calibrate(t, non_neg_integer) :: :ok | {:error, reason :: any}
  def calibrate(conn, data) when is_integer(data) and data >= 0 and data <= 0xFFFF do
    write_calibration(conn, <<data::size(16)>>)
  end
end
