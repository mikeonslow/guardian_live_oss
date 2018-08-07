use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :app_ui, AppUi.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :info

# Configure your database
#TODO: Remove repo configs from all ui config files
config :auth, Auth.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "Clarity32@",
  database: "test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  timeout: 20_000,
  pool_size: 10
