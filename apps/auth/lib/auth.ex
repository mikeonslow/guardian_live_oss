defmodule Auth do
  use GenServer
  use Elixometer

  @moduledoc ~S"""
  Authentication system for the platform.
  """
  import Ecto.Query

  require Logger

  alias Auth.{Repo, User, Role, AppPermissions, AppRoles}

  @timed key: "permissions.cached"
  def permissions do
    GenServer.call(__MODULE__, :permissions)
  end

  def roles do
    GenServer.call(__MODULE__, :roles)
  end

  def save_permissions(app_perms, user_id) do
    # TODO invalidate all tokens, change signing salt, etc
    # 1 push to state - update will happened
    GenServer.call(__MODULE__, {:new_permissions, app_perms, user_id})
    # 2 return from state
    GenServer.call(__MODULE__, :permissions)
  end

  def get_user(user_id) when is_integer(user_id) do
    user_id |> load_user
  end

  def get_user(user_id) when is_bitstring(user_id) do
    user_id |> load_user
  end

  def get_user(_user_id), do: raise("Invalid user_id type")

  defp load_user(user_id) do
    Repo.get(User, user_id)
    # lets preload the role so role will ne empty or have value
    |> Repo.preload(:role)
    # sPasswd DOES NOT LEAVE THE PERIMETTER!!!
    |> translate_user
  end

  # TODO make GenServer call here from cache
  def authenticate_employee(username, password_clear) do
    try do
      user =
        from(u in User, where: [sUID: ^username])
        # TODO use PK for cipher ?
        |> Repo.one!()

      rc =
        case Comeonin.Bcrypt.checkpw(password_clear, user.password_shadow) do
          false ->
            Logger.info("Password does not match for #{inspect(username)}")
            {:error, :user_not_found}

          true ->
            user =
              user
              |> Repo.preload(:role)

            perms = permissions()

            role =
              user.role
              |> drop_missing_sets_from_role(perms)
              |> drop_missing_bits_from_role(perms)

            # sPasswd DOES NOT LEAVE THE PERIMETTER!!!
            %{user | role: role}
            |> translate_user
        end

      Logger.info(" -------------------> user found: #{inspect(rc)}")
      rc
    rescue
      error in Ecto.NoResultsError ->
        Logger.info(" -------------------> user Not found: #{inspect(error)}")
        {:error, :user_not_found}
    end
  end

  def for_config([]), do: %{}

  def for_config([app | other_apps]) do
    app
    |> for_config
    |> Map.merge(other_apps |> for_config)
  end

  def for_config(app) when app |> is_atom do
    (app |> to_string |> get_app_perm_set).c_permission_sets
  end

  def store_permissions(app_permissions_map, app_name) do
    #    Logger.info "Perms !!!! ---->>> #{inspect app_permissions_map}"
    app_ps =
      app_name
      |> to_string
      |> get_app_perm_set
      |> AppPermissions.changeset(%{c_permission_sets: app_permissions_map})
      |> Repo.update!()

    app_ps.c_permission_sets
  end

  def get_app_perm_set(app_name) do
    AppPermissions
    |> apply_filter(app_name)
    # really just one
    |> Repo.one!()
  end

  ###########################################################
  #
  #  Callbacks
  #
  ###########################################################

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    # TODO one second?
    Process.send_after(self(), :load_permissions, 1)
    {:ok, %{}}
  end

  def handle_call({:new_permissions, app_perms, user_id}, _from, _state) do
    # TODO what if there is no permissions?
    Logger.info(":new_permissions  is #{inspect(app_perms)}")
    Process.send_after(self(), :save_permissions, 1)
    Process.send_after(self(), {:patch_roles, user_id}, 1)
    {:reply, app_perms, %{permissions: app_perms}}
  end

  def handle_call(:permissions, _from, state) do
    # TODO what if there is no permissions?
    {:reply, state[:permissions], state}
  end

  def handle_info(:load_permissions, _state) do
    mfa = Application.fetch_env!(:auth, Auth.Guardian)[:permissions_provided_by]

    perms =
      case mfa do
        {m, f, a, timeout} -> {m, f, a} |> permission_fetch(timeout)
        {m, f, a} -> {m, f, a} |> permission_fetch
        permissions_map -> permissions_map
      end

    Logger.debug("perms:handle_info  =>  #{inspect(perms)}")
    {:noreply, %{permissions: perms}}
  end

  def handle_info(:save_permissions, state) do
    mfa = Application.fetch_env!(:auth, Auth.Guardian)[:permissions_persisted_by]

    stored_app_perms =
      case mfa do
        {m, f, app_name} ->
          apply(m, f, [state[:permissions] | app_name])

        _ ->
          raise ":permissions_persisted_by parameter is missing from config! Please specify {M,f,a} to store permission"
      end

    Logger.info("---> saved permissions are #{inspect(stored_app_perms)}")
    {:noreply, %{permissions: stored_app_perms}}
  end

  def handle_info({:patch_roles, user_id}, state) do
    app_perms = state[:permissions]

    roles =
      Role
      |> Repo.all()
      |> drop_missing_sets(app_perms)
      |> drop_missing_bits(app_perms)
      |> Enum.map(fn r ->
        %{nid: r.nid, vname: r.vname, clperms: r.clperms}
        |> AppRoles.call_update(user_id)
      end)

    Logger.info("Patched Roles: ------------------->  #{inspect(roles)}")
    {:noreply, state}
  end

  def drop_missing_sets(roles, app_perms) do
    roles_sans_dropped_sets =
      roles
      |> Enum.map(fn role ->
        role
        |> drop_missing_sets_from_role(app_perms)
      end)

    roles_sans_dropped_sets
  end

  def drop_missing_sets_from_role(nil, _app_perms), do: nil

  def drop_missing_sets_from_role(role, app_perms) do
    %{
      role
      | clperms:
          role.clperms
          # only keys that are left in app_perms
          |> Map.take(
            role.clperms
            |> Map.keys()
            |> MapSet.new()
            |> MapSet.intersection(app_perms |> Map.keys() |> MapSet.new())
          )
    }
  end

  def drop_missing_bits(roles, app_perms) do
    roles_with_cleaned_up_bits =
      roles
      |> Enum.map(fn r ->
        r
        |> drop_missing_bits_from_role(app_perms)
      end)

    # role.clperms |> Enum.map(fn {set, perms} -> {set, perms |> MapSet.new |> MapSet.intersection(p |> Map.get(set) |> MapSet.new) |> MapSet.to_list } end) |> Map.new end)
    roles_with_cleaned_up_bits
  end

  def drop_missing_bits_from_role(nil, _app_perms), do: nil

  def drop_missing_bits_from_role(role, app_perms) do
    %{
      role
      | clperms:
          role.clperms
          |> Enum.map(fn {set, perms} ->
            {set,
             perms
             |> MapSet.new()
             |> MapSet.intersection(app_perms |> Map.get(set) |> MapSet.new())
             |> MapSet.to_list()}
          end)
          |> Map.new()
    }
  end

  def handle_cast(_req, state) do
    {:noreply, state}
  end

  @translate %{
    role: :permissions,
    iUID: :id,
    sEmail: :email,
    sUID: :username,
    sName: :fullName
  }

  def translate_user(%User{} = user) do
    user
    |> translate_fields(@translate)
    |> user_permissions
    |> Map.take(Map.values(@translate))
  end

  ###########################################################
  #
  #  Private functions
  #
  ###########################################################

  defp user_permissions(%{permissions: nil} = user) do
    user
  end

  defp user_permissions(%{permissions: non_empty_role} = user) do
    # map of permissions
    %{user | permissions: non_empty_role.clperms}
  end

  @doc """
  Pass the struture and map of  %{from_key: :to_key} or  %{from_key: {:to_key, convesion_fun/1 }}
  The from_key: in the struct will be relaced
  with to_key: and converted convertion_fun if supplied
  """
  def translate_fields(struct, db_2_ui) do
    Enum.reduce(db_2_ui, struct, &reduce_fn/2)
  end

  defp reduce_fn({db, {ui, convert_fun}}, struct) do
    struct
    |> Map.put(ui, convert_fun.(Map.get(struct, db)))
    |> Map.delete(db)
  end

  defp reduce_fn({db, ui}, struct) do
    struct
    |> Map.put(ui, Map.get(struct, db))
    |> Map.delete(db)
  end

  defp permission_fetch({m, f, args}, timeout) when timeout |> is_integer do
    Logger.debug(
      "Async call => { #{inspect(m)}, #{inspect(f)}, #{inspect(args)}, #{inspect(timeout)}"
    )

    x = Task.async(fn -> apply(m, f, args) |> handle_permission_fetch end)
    perms = Task.await(x, timeout)
    perms
  end

  defp permission_fetch({m, f, args}) do
    Logger.debug("Sync call => { #{inspect(m)}, #{inspect(f)}, #{inspect(args)} }")
    apply(m, f, args) |> handle_permission_fetch
  end

  defp handle_permission_fetch({:error, reason}) do
    {:stop, :error, "App permissions source is down! Auth can not continue :: #{inspect(reason)}"}
  end

  defp handle_permission_fetch(perms), do: perms

  defp apply_filter(query, app_name) do
    query
    |> where([p], p.vapp_name == ^app_name)
  end
end
