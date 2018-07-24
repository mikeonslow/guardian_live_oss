defmodule Auth.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Auth.Repo.start_link()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      # supervisor(Auth.Repo, []),
      # Start the endpoint when the application starts
      ## TODO Rework login GenServer to async
      # supervisor(Auth.Login, [])
      # Starts a worker by calling: Auth.Worker.start_link(arg1, arg2, arg3)
      worker(Auth, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Auth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
