defmodule App.Mixfile do
  use Mix.Project

  def project do
    [
      apps_path: "./apps",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      version: "0.0.1",
      deps: deps(),
      dialyzer: [
        plt_add_deps: :transitive,
        flags: [:unmatched_returns, :error_handling, :race_conditions, :no_opaque],
        paths: [
          "_build/dev/lib/app_ui/ebin",
          "_build/dev/lib/auth/ebin"
        ]
      ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps folder
  defp deps do
    [
      {:dialyxir, "~> 0.5.1", only: [:dev], runtime: false},
      {:distillery, "~> 1.4", runtime: false},
      {:credo, "~> 0.5", only: [:local, :dev, :test]},
      {:dogma, "~> 0.1", only: [:local, :dev]}
    ]
  end
end
