defmodule INA219.MixProject do
  use Mix.Project

  @version "2.0.0"

  def project do
    [
      app: :ina219,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      description:
        "Provides a driver for INA219-based voltage and current sensors connected via I2C",
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def package do
    [
      maintainers: ["James Harton <james@harton.nz>"],
      licenses: ["HL3-FULL"],
      links: %{
        "Source" => "https://gitlab.com/jimsy/ina219"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:circuits_i2c, "~> 2.0", optional: true},
      {:credo, "~> 1.6", only: ~w[dev test]a, runtime: false},
      {:earmark, "~> 1.4", only: ~w[dev test]a},
      {:elixir_ale, "~> 1.2", optional: true},
      {:ex_doc, "~> 0.30", only: ~w[dev test]a},
      {:git_ops, "~> 2.4", only: ~w[dev test]a, runtime: false},
      {:mimic, "~> 1.5", only: :test},
      {:wafer, "~> 1.0"}
    ]
  end
end
