use Mix.Config

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Configure your database
config :auth, Auth.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "123",
  database: "app",
  hostname: "localhost",
  pool_size: 2,
  timeout: 20_000
