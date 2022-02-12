defmodule Sensei.MixProject do
  use Mix.Project

  def project do
    [
      app: :sensei,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Sensei, []},
      extra_applications: [:logger],
      start_phases: start_phases(Mix.env())
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nadia, "~> 0.7.0"},
      {:mongodb_driver, "~> 0.7"},
      {:tz, "~> 0.20.0"},
      {:libgraph, "~> 0.13"},
      {:ok, "~> 2.3"},
      {:ecoji_ex, github: "KoteSolutions/ecoji-ex"},
      {:struct_simplifier, github: "Ecialo/struct_simplifier", branch: "decoder_proto"}
    ]
  end

  def elixirc_paths(:test), do: ["lib", "test/helpers"]
  def elixirc_paths(_), do: ["lib"]

  def start_phases(:dev), do: [prepare_dev: []]
  def start_phases(_), do: [ensure_indexes: []]
end
