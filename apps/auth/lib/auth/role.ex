defmodule Auth.Role do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:nid, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :nid}

  schema "roles" do
    field(:vname, :string)
    field(:clperms, :map)
  end

  @required_fields ~w(vname clperms)a

  @read_on_cast [:vname, :clperms]

  @doc """
  Creates a changeset based on the `model` and `params`.
  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(role, params \\ %{}) do
    role
    |> cast(params, @read_on_cast)
    |> validate_required(@required_fields)
    |> validate_length(:vname, min: 1, max: 50)
  end

  def new_changeset(params) when is_map(params) do
    %__MODULE__{}
    |> cast(params, @read_on_cast)
    |> validate_required(@required_fields)
    |> validate_length(:vname, min: 1, max: 50)
  end
end
