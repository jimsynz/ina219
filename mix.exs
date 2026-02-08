defmodule INA219.MixProject do
  use Mix.Project

  @version "2.0.1"

  def project do
    [
      app: :ina219,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      description:
        "Provides a driver for INA219-based voltage and current sensors connected via I2C",
      deps: deps(),
      package: package(),
      docs: [
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"]
      ]
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
        "Source" => "https://harton.dev/james/ina219",
        "GitHub" => "https://github.com/jimsynz/ina219",
        "Changelog" => "https://docs.harton.nz/james/ina219/changelog.html",
        "Sponsor" => "https://github.com/sponsors/jimsynz"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:circuits_i2c, "~> 2.0", optional: true},
      {:credo, "~> 1.6", only: ~w[dev test]a, runtime: false},
      {:dialyxir, "~> 1.4", only: ~w[dev test]a, runtime: false},
      {:doctor, "~> 0.22", only: ~w[dev test]a, runtime: false},
      {:elixir_ale, "~> 1.2", optional: true},
      {:ex_check, "~> 0.16", only: ~w[dev test]a, runtime: false},
      {:ex_doc, "~> 0.40", only: ~w[dev test]a, runtime: false},
      {:git_ops, "~> 2.4", only: ~w[dev test]a, runtime: false},
      {:mimic, "~> 2.0", only: :test},
      {:wafer, "~> 1.0"}
    ]
  end
end
