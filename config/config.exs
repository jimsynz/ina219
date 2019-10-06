import Config

config :ina219,
  devices: [
    %{
      bus: "i2c-1",
      address: 0x41,
      commands: [:calibrate_32V_1A!],
      current_divisor: 10,
      power_divisor: 2
    }
  ]
