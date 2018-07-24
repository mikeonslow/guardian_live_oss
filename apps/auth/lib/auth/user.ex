defmodule Auth.User do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:iUID, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :iUID}

  schema "employees" do
    # ??TODO unique_constraint(:sUID)
    field(:sUID, :string)
    field(:sName, :string)
    field(:password, :string, virtual: true)
    field(:password_shadow, :string)
    field(:sEmail, :string)
    belongs_to(:role, Auth.Role, foreign_key: :nroleid, references: :nid)
  end

  @required_fields ~w(sUID sName sEmail)a

  @read_on_cast [:password, :sEmail, :sName, :sUID]

  # @optional_fields ~w()a

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @read_on_cast)
    |> validate_required(@required_fields)
    |> validate_length(:sEmail, min: 3, max: 50)
  end

  def registration_changeset(model, params) do
    model
    |> changeset(params)
    |> cast(params, [:password])
    |> validate_length(:password, min: 4)
    |> encrypt_password()
  end

  defp encrypt_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(
          changeset,
          :password_shadow,
          Comeonin.Bcrypt.hashpwsalt(pass)
        )

      _ ->
        changeset
    end
  end
end
