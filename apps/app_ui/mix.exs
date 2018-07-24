defmodule AppUi.Mixfile do
  use Mix.Project

  def project do
    [app: :app_ui,
     version: "0.0.1",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.6",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {AppUi, []},
     applications: [ :phoenix, :phoenix_html, :cowboy, :logger, :gettext, :auth]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.3"},
     {:phoenix_html, "~> 2.3"},
     {:phoenix_live_reload, "~> 1.0", only: [:dev, :local]},
     {:gettext, "~> 0.9"},
     {:cowboy, "~> 1.0"},
     {:ex_machina, "~> 2.0", only: [:test, :local]},
     {:auth, in_umbrella: true}
   ]
  end
end
