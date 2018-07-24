# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config


# Configures the endpoint
config :app_ui, AppUi.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "QQ9/b1MU7qTFyVS4coSvG1hwn1J/Z6zgs2J8RZudvVziNLfeeLh8k40FDOfwMfwU",
  render_errors: [view: App.ErrorView, accepts: ~w(html json)],
  pubsub: [name: AppUi.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :auth, Auth.Guardian,
  issuer: "app_ui",
  secret_key: {Auth.SecretKey, :fetch, []},
#"L0YuKt8Vqe1a8l5OjIOBECEfyi3Hyw0DbVuk2oDkwvFYO22Q4eoVcHKHZUqGKfo+",
#"dch9AaUvjXogIVDNaHRTXCzTD4GbTt2jYtZLxPLtz20Wyt+OxdIcJsx7I99d4Noc",
  ttl: { 1, :days },
  verify_issuer: true,
  permissions:  { Auth, :permissions,[], 250 },
  # { Auth, :for_config, []}
  permissions_provided_by: { Auth, :for_config, [[:app]], 2500 },
  permissions_persisted_by: { Auth, :store_permissions, [:app] }

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
