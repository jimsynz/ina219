defmodule INA219.Device do
  use GenServer
  alias ElixirALE.{I2C}
  alias INA219.{Commands, Device}
  require Logger

  @moduledoc """
  An individual INA219 device.

  Each device needs it's configuration specified in your application's
  configuration.

  Example configuration:

      config :ina219,
        devices: [
          %{
              bus: "i2c-1",
              address: 0x41,
              name: :sensor0,
              commands: [:calibrate_32V_1A!],
              current_divisor: 10,
              power_divisor: 2
          }
        ]

  Note that `bus` and `address` are required.  All other parameters are
  optional.  If no `name` is provided then a tuple of the bus name and address
  will be used, for example the device above would be named `{"i2c-1", 0x41}`.
  """

  @type device_name :: any

  @doc """
  Retrieve the current divisor from the process configuration.
  """
  @spec current_divisor(pid | device_name) :: number | {:error, reason :: any}
  def current_divisor(pid) when is_pid(pid), do: GenServer.call(pid, :current_divisor)

  def current_divisor(device_name),
    do: GenServer.call({:via, Registry, {INA219.Registry, device_name}}, :current_divisor)

  @doc """
  Set the current divisor in the process configuration.
  """
  @spec current_divisor(pid | device_name, divisor :: number) :: :ok | {:error, reason :: any}
  def current_divisor(pid, divisor) when is_pid(pid),
    do: GenServer.call(pid, {:current_divisor, divisor})

  def current_divisor(device_name, divisor),
    do:
      GenServer.call(
        {:via, Registry, {INA219.Registry, device_name}},
        {:current_divisor, divisor}
      )

  @doc """
  Retrieve the power divisor from the process configuration.
  """
  @spec power_divisor(pid | device_name) :: number | {:error, reason :: any}
  def power_divisor(pid) when is_pid(pid), do: GenServer.call(pid, :power_divisor)

  def power_divisor(device_name),
    do: GenServer.call({:via, Registry, {INA219.Registry, device_name}}, :power_divisor)

  @doc """
  Set the power divisor in the process configuration.
  """
  @spec power_divisor(pid | device_name, divisor :: number) :: :ok | {:error, reason :: any}
  def power_divisor(pid, divisor), do: GenServer.call(pid, {:power_divisor, divisor})

  def power_divisor(device_name, divisor),
    do:
      GenServer.call({:via, Registry, {INA219.Registry, device_name}}, {:power_divisor, divisor})

  @doc """
  Are new samples ready since the last time you read them?
  Calling this function will clear the value until next time new samples are ready.
  """
  @spec conversion_ready?(pid | device_name) :: boolean
  def conversion_ready?(pid) when is_pid(pid), do: GenServer.call(pid, :conversion_ready?)

  def conversion_ready?(device_name),
    do: GenServer.call({:via, Registry, {INA219.Registry, device_name}}, :conversion_ready?)

  @doc """
  Returns `true` when power or current calculations are out of range.
  This indicates that current and power data may be meaningless.
  """
  @spec math_overflow?(pid | device_name) :: boolean
  def math_overflow?(pid) when is_pid(pid), do: GenServer.call(pid, :math_overflow?)

  def math_overflow?(device_name),
    do: GenServer.call({:via, Registry, {INA219.Registry, device_name}}, :math_overflow?)

  @doc """
  Returns the bus voltage in mV.
  """
  @spec bus_voltage(pid | device_name) :: number | {:error, reason :: any}
  def bus_voltage(pid) when is_pid(pid), do: GenServer.call(pid, :bus_voltage)

  def bus_voltage(device_name),
    do: GenServer.call({:via, Registry, {INA219.Registry, device_name}}, :bus_voltage)

  @doc """
  Returns the shunt voltage in mV.
  """
  @spec shunt_voltage(pid | device_name) :: number | {:error, reason :: any}
  def shunt_voltage(pid) when is_pid(pid), do: GenServer.call(pid, :shunt_voltage)

  def shunt_voltage(device_name),
    do: GenServer.call({:via, Registry, {INA219.Registry, device_name}}, :shunt_voltage)

  @doc """
  Returns the current in mA.
  """
  @spec current(pid | device_name) :: number | {:error, reason :: any}
  def current(pid) when is_pid(pid), do: GenServer.call(pid, :current)

  def current(device_name),
    do: GenServer.call({:via, Registry, {INA219.Registry, device_name}}, :current)

  @doc """
  Returns the power in mW
  """
  @spec power(pid | device_name) :: number | {:error, reason :: any}
  def power(pid) when is_pid(pid), do: GenServer.call(pid, :power)

  def power(device_name),
    do: GenServer.call({:via, Registry, {INA219.Registry, device_name}}, :power)

  @doc """
  Executes the passed function with the `pid` of the I2C connection as it's argument.
  Use this if you want to manually run functions from `Commands` or `Registers`.
  """
  @spec execute(pid | device_name, (pid -> any)) :: any
  def execute(pid, fun) when is_pid(pid) and is_function(fun, 1),
    do: GenServer.call(pid, {:execute, fun})

  def execute(device_name, fun) when is_function(fun, 1),
    do: GenServer.call({:via, Registry, {INA219.Registry, device_name}}, {:execute, fun})

  @doc false
  def start_link(config), do: GenServer.start_link(Device, config)

  @impl true
  def init(%{bus: bus, address: address} = config) do
    name =
      config
      |> Map.get(:name, {bus, address})

    {:ok, _} = Registry.register(INA219.Registry, name, self())
    Process.flag(:trap_exit, true)

    Logger.info("Connecting to INA219 sensor #{inspect(name)}")

    {:ok, i2c} = I2C.start_link(bus, address)

    current_divisor = Map.get(config, :current_divisor, 1)
    power_divisor = Map.get(config, :power_divisor, 1)
    commands = Map.get(config, :commands, [])

    with :ok <- Commands.reset!(i2c),
         :ok <- apply_commands(i2c, commands) do
      state = %{
        bus: bus,
        address: address,
        current_divisor: current_divisor,
        power_divisor: power_divisor,
        i2c: i2c,
        name: name,
        commands: commands
      }

      {:ok, state}
    else
      {:error, message} -> {:stop, message}
    end
  end

  @impl true
  def terminate(_reason, %{i2c: i2c, name: name}) do
    Logger.info("Disconnecting from INA219 device #{inspect(name)}")
    I2C.release(i2c)
  end

  @impl true
  def handle_call({:execute, fun}, _from, %{i2c: i2c} = state) do
    result = fun.(i2c)
    {:reply, result, state}
  end

  def handle_call(:current_divisor, _from, %{current_divisor: divisor} = state) do
    {:reply, divisor, state}
  end

  def handle_call({:current_divisor, divisor}, _from, state) do
    {:reply, :ok, %{state | current_divisor: divisor}}
  end

  def handle_call(:power_divisor, _from, %{power_divisor: divisor} = state) do
    {:reply, divisor, state}
  end

  def handle_call({:power_divisor, divisor}, _from, state) do
    {:reply, :ok, %{state | power_divisor: divisor}}
  end

  def handle_call(:conversion_ready?, _from, %{i2c: pid} = state) do
    {:reply, Commands.conversion_ready?(pid), state}
  end

  def handle_call(:math_overflow?, _from, %{i2c: pid} = state) do
    {:reply, Commands.math_overflow?(pid), state}
  end

  def handle_call(:bus_voltage, _from, %{i2c: pid} = state) do
    {:reply, Commands.bus_voltage(pid), state}
  end

  def handle_call(:shunt_voltage, _from, %{i2c: pid} = state) do
    {:reply, Commands.shunt_voltage(pid), state}
  end

  def handle_call(:current, _from, %{i2c: pid, current_divisor: divisor} = state) do
    {:reply, Commands.current(pid, divisor), state}
  end

  def handle_call(:power, _from, %{i2c: pid, power_divisor: divisor} = state) do
    {:reply, Commands.power(pid, divisor), state}
  end

  defp apply_commands(pid, commands) do
    Enum.reduce(commands, :ok, fn
      _, {:error, _} = error ->
        error

      command, :ok when is_atom(command) ->
        apply(Commands, command, [pid])

      {command, args}, :ok when is_atom(command) and is_list(args) ->
        apply(Commands, command, [pid | args])

      {command, arg}, :ok when is_atom(command) ->
        apply(Commands, command, [pid, arg])
    end)
  end
end
