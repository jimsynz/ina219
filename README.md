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

In your `config.exs` add the following:

```elixir
config :ina219,
  devices: [
    %{
      bus: "i2c-1",
      address: 0x41,
      commands: [:calibrate_32V_2A!],
      current_divisor: 10,
      power_divisor: 2
    }
  ]
```

You must set the `bus` and `address` values according to your system.

## Calibration

Calibrating these wee chips is a bit of a pain in the donkey, but is easily
achieved by following the equation in the data sheet.  Once you have the
calibration and divisor values you wish to use you can configure the device
manually (see the hexdocs for `INA219.Commands` for more information).  For
example:

```elixir
%{
  bus: "i2c-1",
  address: 0x41,
  commands: [
    calibrate: 8192,
    bus_voltage_range: 32,
    shunt_voltage_pga: 8,
    bus_adc_resolution_and_averaging: {1, 12},
    shunt_adc_resolution_and_averaging: {1, 12},
    mode: :shunt_and_bus_voltage_continuous
  ],
  current_divisor: 10,
  power_divisor: 2
}
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ina219` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ina219, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ina219](https://hexdocs.pm/ina219).

