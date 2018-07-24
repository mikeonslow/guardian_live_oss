defmodule MixDocker.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mix_docker,
      version: "0.5.0",
      elixir: "~> 1.5",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),

      description: description(),
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  defp description do
    "Add docker related steps"
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:distillery, "~> 1.2"},
      {:ex_doc, "~> 0.10", only: :dev}
    ]
  end
end
