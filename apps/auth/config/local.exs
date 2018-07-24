use Mix.Config

# Configure your database
config :auth, Auth.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "123",
  database: "app",
  hostname: "localhost",
  pool_size: 2
