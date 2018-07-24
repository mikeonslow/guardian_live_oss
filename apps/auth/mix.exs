defmodule Auth.Mixfile do
  use Mix.Project

  def project do
    [
      app: :auth,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [plt_add_deps: :apps_direct]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger], mod: {Auth.Application, []}, applications: [:ecto, :mariaex]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:my_app, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:exometer_core, "~> 1.4"},
      {:elixometer, github: "pinterest/elixometer"},
      {:setup, "1.8.4", override: true, manager: :rebar},
      {:lager, "3.6.2", override: true},
      {:comeonin, "~> 3.0"},
      {:guardian,
       github: "borodark/guardian", branch: "feature/live_permissions", override: true},
      {:mariaex, "~> 0.8"},
      {:ecto, "~> 2.2"}
    ]
  end
end
