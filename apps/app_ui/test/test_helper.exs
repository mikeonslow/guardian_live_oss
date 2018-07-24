{:ok, _} = Application.ensure_all_started(:ex_machina)
{:ok, _} = Application.ensure_all_started :exometer_core
ExUnit.start
#:ok = Ecto.Adapters.SQL.Sandbox.checkout(Auth.Repo)
#Ecto.Adapters.SQL.Sandbox.mode(Auth.Repo, {:shared, self()})
