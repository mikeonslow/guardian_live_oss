defmodule AppUi.AdminChannel do

  use AppUi.Web, :channel

  alias Auth
  alias Auth.AppRoles

  require Logger

  @channel_name "admin:"
  #TODO must not permissions to be verbs of handle_in("...")?
  @channel_permissions %{ "admin" => [
                            "app_permission_sets",
                            "app_roles",
                            "save_app_perm_sets",
                            "save_app_roles" ] }

  use Auth.Channel

  def handle_in("app_permission_sets", %{ "app_name" => _app_name}, socket) do
    # TODO use app_name?
    socket
    |> Guardian.Phoenix.Socket.current_claims()
    |> Auth.Guardian.decode_permissions_from_claims()
    |> Auth.Guardian.any_permissions?(%{"admin" => ["app_permission_sets"]})
    |> allowed(socket, "app_permission_sets")
  end

  def handle_in("app_roles", %{ "app_name" => _app_name}, socket) do
    broadcast! socket, "app_roles", %{ app_roles: AppRoles.get_all}
    {:noreply, socket}
  end

  def handle_in("save_app_perm_sets", %{ "permissionSets" => permission_sets }, socket) do
    socket
    |> Guardian.Phoenix.Socket.current_claims()
    |> Auth.Guardian.decode_permissions_from_claims()
    |> Auth.Guardian.any_permissions?(%{"admin" => ["save_app_perm_sets"]})
    |> allowed(socket, "save_app_perm_sets",permission_sets)
  end

  def handle_in("save_app_roles", roles , socket) do
    user_id = user_id(socket)
    newRoles = roles |> AppRoles.store_all(user_id)
    {:reply, {:ok, %{app_roles: newRoles} }, socket }
  end

  def allowed(true, socket, "save_app_perm_sets",permission_sets) do
    Logger.info "save_app_perm_sets WAS ALLOWED ...."
    user_id = user_id(socket)
    app_perms = permission_sets |> Auth.save_permissions(user_id)
    # app_roles has to be cleaned up off of deleted permissions sets 
    broadcast! socket, "app_roles", %{ app_roles: AppRoles.get_all}
    {:reply, {:ok, %{ permissionSets: app_perms  } }, socket }
  end

  def allowed(true, socket, "app_permission_sets") do
    Logger.info "app_permission_sets WAS ALLOWED ...."
    broadcast! socket, "app_permission_sets", %{ "permissionSets" => Auth.permissions}
    {:noreply, socket}
  end

  def allowed(false, socket, what) do
    push socket, "unauthorized:permissions", %{
      "error" => 403,
      "message" => "No permission to perform " <> what
    }
    Logger.info "terminating #{inspect socket}"
    {:stop, :shutdown , socket}
  end

end
