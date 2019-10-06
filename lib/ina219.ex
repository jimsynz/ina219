defmodule INA219 do
  @moduledoc """
  INA219 Driver for Elixir using ElixirALE.

  ## Usage

  In your `config.exs` add the following:

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

  You must set the `bus` and `address` values according to your system.

  ## Calibration

  Calibrating these wee chips is a bit of a pain in the donkey, but is easily
  achieved by following the equation in the data sheet.  Once you have the
  calibration and divisor values you wish to use you can configure the device
  manually (see the hexdocs for `INA219.Commands` for more information).  For
  example:

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

  """

  @doc """
  Connect to an INA219 device.
  """
  def connect(config),
    do:
      Supervisor.start_child(INA219.Supervisor, %{
        id: {INA219.Device, Map.fetch!(config, :bus), Map.fetch!(config, :address)},
        start: {INA219.Device, :start_link, [config]}
      })

  @doc """
        Disconnect an INA219 device.
  """
  def disconnect(device_name),
    do: Process.exit({:via, Registry, {INA219.Registry, device_name}}, :normal)
end
