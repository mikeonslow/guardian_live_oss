defmodule Auth.AppRoles do
  alias Auth.{Repo, Role}

  def store_all(%{"updated" => save_roles, "deleted" => deleted_roles}, user_id) do
    _dlt_rslt =
      deleted_roles
      |> Enum.map(fn %{"id" => id} -> id end)
      |> delete_all()

    _sv_rslt =
      save_roles
      |> Enum.map(fn %{"id" => id, "name" => name, "permissions" => perms} ->
        %{nid: id, vname: name, clperms: perms}
        |> save_or_create(user_id)
      end)
      |> translate_response
  end

  defp save_or_create(%{nid: 0} = map, user_id) do
    Role.new_changeset(map)
    |> create_if_valid(user_id)
  end

  defp save_or_create(map, user_id) do
    map
    |> call_update(user_id)
  end

  def call_update(%{nid: id} = role, user_id) do
    Role
    |> Repo.get(id)
    |> Role.changeset(role)
    |> update_if_valid(user_id)
  end

  def get(id) do
    Role
    |> Repo.get(id)
    |> to_map
  end

  def delete_all(role_ids) do
    ## "New deleted role"
    role_ids
    |> Enum.reject(fn id -> id == 0 end)
    |> Enum.map(fn id ->
      Role
      |> Repo.get(id)
      |> Repo.delete!()
    end)
  end

  def get_all do
    Role
    |> Repo.all()
    |> translate_response
  end

  ###########################################################
  #
  #   Private functions
  #
  ###########################################################

  defp translate_response(roles) do
    for p <- roles, do: p |> to_map
  end

  defp to_map(ps) do
    %{
      id: ps.nid,
      name: ps.vname,
      permissions: ps.clperms
    }
  end

  ## ---- TODO move to macro or module?
  defp create_if_valid(changeset, user_id) do
    changeset.valid?
    |> create(changeset, user_id)
  end

  defp create(false, errors, _user_id), do: errors

  defp create(true, changeset, user_id) do
    changeset
    |> Repo.insert!(user_id: user_id)
  end

  defp update_if_valid(changeset, user_id) do
    changeset.valid?
    |> update(changeset, user_id)
  end

  defp update(false, errors, _user_id), do: errors

  defp update(true, changeset, user_id) do
    changeset
    |> Repo.update!(user_id: user_id)
  end
end
