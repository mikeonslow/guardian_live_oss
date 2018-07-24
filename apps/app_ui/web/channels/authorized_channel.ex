defmodule AppUi.AuthorizedChannel do

  use AppUi.Web, :channel

  require Logger

  @channel_name "authorized:"

  #TODO must not permissions to be verbs of handle_in("...")?
  @channel_permissions %{ "default" => [ "login" ]}

  use Auth.Channel

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("pong", _payload, socket) do
    socket
    |> Guardian.Phoenix.Socket.current_claims()
    |> Auth.Guardian.decode_permissions_from_claims()
    |> Auth.Guardian.any_permissions?(%{auth_test: [:p1]})
    |> allowed(socket, "pong")
  end

  def handle_in(:p3, _payload, socket) do
    socket
    |> Guardian.Phoenix.Socket.current_claims()
    |> Auth.Guardian.decode_permissions_from_claims()
    |> Auth.Guardian.any_permissions?(%{auth_test: [:p3]})
    |> allowed(socket, :p3)
  end

  def handle_in("ping", _payload, socket) do
    socket
    |> Guardian.Phoenix.Socket.current_claims()
    |> Auth.Guardian.decode_permissions_from_claims()
    |> Auth.Guardian.any_permissions?(%{auth_test: [:p2]})
    |> allowed(socket, "ping")
  end


  def allowed(true, socket, what) do
    Logger.info "#{inspect what} WAS ALLOWED ...."
    {:reply, {:ok, %{message: what}}, socket}
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
