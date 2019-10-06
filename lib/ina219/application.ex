defmodule INA219.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: INA219.Registry}
    ]

    devices =
      :ina219
      |> Application.get_env(:devices, [])
      |> Enum.map(fn config ->
        %{
          id: {INA219.Device, Map.fetch!(config, :bus), Map.fetch!(config, :address)},
          start: {INA219.Device, :start_link, [config]}
        }
      end)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: INA219.Supervisor]
    Supervisor.start_link(children ++ devices, opts)
  end
end
