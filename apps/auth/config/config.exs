# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :auth, ecto_repos: [Auth.Repo]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: []

config(:exometer_core, report: [reporters: [{:exometer_report_tty, []}]])

config(
  :elixometer,
  reporter: :exometer_report_tty,
  env: Mix.env(),
  metric_prefix: "app_ui"
)

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
