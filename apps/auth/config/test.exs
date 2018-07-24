use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :auth, Auth.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :info

# Configure your database
config :auth, Auth.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "123",
  database: "app",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  timeout: 20_000,
  pool_size: 10
