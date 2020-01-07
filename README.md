# INA219

A library for interacting with the
[Texas Instruments INA219](http://www.ti.com/product/INA219)
high side current and power monitoring chip via I2C  using
[Elixir ALE](https://github.com/fhunleth/elixir_ale).

I'm using the [Adafruit INA219 breakout](https://www.adafruit.com/product/904)
for prototyping, so am using their calibrations straight from their Arduino
library, but you can do the maths and calibrate it yourself if you're using a
different shunt resistor value.

## Usage

This library uses the [Wafer](https://gitlab.com/jimsy/wafer) project to connect
to the I2C device - this allows you to bring your own driver.

Example using [Elixir Circuits](https://hex.pm/packages/circuits_i2c)

    iex> {:ok, conn} = Wafer.Driver.CircuitsI2C.acquire(bus: "i2c-1", address: 0x41)
    ...> {:ok, conn} = INA219.acquire(conn: conn, current_divisor: 10, power_divisor: 2)
    ...> :ok = INA219.calibrate_32V_2A(conn)
    ...> INA219.bus_voltage(conn)
    {:ok, 12.0}

## Calibration

Calibrating these wee chips is a bit of a pain in the donkey, but is easily
achieved by following the equation in the data sheet.  Once you have the
calibration and divisor values you wish to use you can configure the device
manually.  For example:

    iex> {:ok, conn} = Wafer.Driver.CircuitsI2C.acquire(bus: "i2c-1", address: 0x41)
    ...> {:ok, conn} = INA219.acquire(conn: conn, current_divisor: 10, power_divisor: 2)
    ...> INA219.calibrate(conn, 4096)
    ...> INA219.bus_voltage_range(conn, 32)
    ...> INA219.shunt_voltage_pga(conn, 8)
    ...> INA219.bus_adc_resolution_and_averaging(conn, {1, 12})
    ...> INA219.shunt_adc_resolution_and_averaging(conn, {1, 12})
    ...> INA219.mode(conn, :shunt_and_bus_voltage_continuous)

The `current_divisor` and `power_divisor` values are stored in the connection
struct because there's no way to store them in the device's registers.  You can
alter them as required.

## Installation

The `ina219` package is [available on hex](https://hex.pm/packages/ina219) so it
can be installed by adding `ina219` to your list of dependencies in `mix.exs`.
You'll also need to install an appropriate connection driver.

```elixir
def deps do
  [
    {:ina219, "~> 0.1.0"}
  ]
end
```


Documentation for the latest release is always available on
[HexDocs](https://hexdocs.pm/ina219/) and for the master branch
[here](https://jimsy.gitlab.io/ina219).

