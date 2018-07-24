defmodule AppUi.LoginChannel do

  use AppUi.Web, :channel

  require Logger

  ## This channel will be used to return JWT to the JS client. JWT is generated during
  ## Socket Connection and is in socket.assignes: socket.assigns[:token]
  ## socket |> assign(:hardware_id, hardware_id) |> assign(:guardian_token, jwt) }
  ##
  def join("login:" <> _user_id,  %{"username" => _username} , socket) do
    # if error is in assigned push error message
    login_error = socket.assigns[:login_error]
    guardian_token = socket.assigns[:guardian_default_token]
    Logger.info" > jwt #{inspect guardian_token}"
    decide(socket,login_error,guardian_token)
  end

  @spec terminate(msg :: map, Phoenix.Socket.t) :: {:shutdown, :left | :closed} | term
  def terminate(reason, socket) do
    Logger.debug" > leave #{inspect reason}  #{inspect socket}"
    :ok
  end

  def handle_info({:reply_with_token,  %{guardian_token: guardian_token, user: user}}, socket) do
    Logger.info ":reply_with_token - received .... sending user: #{inspect user}"
    push socket, "user:guardian_token", user |> Map.put(:guardian_token, guardian_token)
    {:noreply, socket }
  end

  def handle_info({:logout, errors }, socket) do
    # TODO revoke token?
    push socket, "login:unauthorized", %{
      "error" => 403,
      "message" => "Unauthorized"
    }
    Logger.debug "terminating #{inspect socket}"
    {:stop, {:shutdown, {:logout, errors}}, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  # TODO handle refresh token here?
  def handle_in("ping", _payload, socket) do
    {:reply, {:ok, %{message: "pong"}}, socket}
  end

  def handle_in("logout",
    %{"guardain_token" => jwt} , socket) do
    # TODO make it simpler! just revoke?
    case Auth.Guardian.decode_and_verify(jwt) do
      { :ok, claims } ->
        #Logger.debug "logging out claims #{inspect claims}"
        %{"sub" => "User:"<> user_id } = claims
        #Logger.debug "before  disconnect broadcast" 
        _rslt = AppUi.Endpoint.broadcast("user_socket:#{user_id}", "disconnect", %{})
      { :error, reason } ->
        Logger.debug "Error in JWT Verification: #{inspect reason}"
    end
    {:stop, {:shutdown, {:logout, jwt}}, socket}
  end

  defp decide(socket, nil, guardian_token) do
    user = socket.assigns[:user]
    #    Logger.debug " user from assigns:  #{inspect user}"
    # Logger.debug " guardian_token:  #{inspect guardian_token}"
    # invoke handle info bellow passing jwt and 
    send(self(), {:reply_with_token, %{guardian_token: guardian_token, user: user}})
    {:ok, socket}
  end

  defp decide(socket, login_error, nil) do
    send(self(), {:logout, login_error})
    {:ok, socket}
  end

end
