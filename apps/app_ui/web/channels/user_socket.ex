defmodule AppUi.UserSocket do
  use Phoenix.Socket

  require Logger

  ## Channels
  channel "authorized:*", AppUi.AuthorizedChannel
  channel "login:*", AppUi.LoginChannel
  channel "admin:*", AppUi.AdminChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.


  @doc """
  Connect for initial login
  """
  def connect(%{"username" => sUID,
                "password" => password_clear } , socket) do
    # Verify login - find user in the DB
    Auth.authenticate_employee(sUID, password_clear) |> process_auth_resp(sUID , socket)
    # TODO have users/permissions stored in K/V store
  end

  @doc """
  Connect with existing JWT token
  """
  def connect(%{"jwt" => token}, socket) do
    case Guardian.Phoenix.Socket.authenticate(socket, Auth.Guardian, token) do
      {:ok, authed_socket} ->
        can_login? = authed_socket
        |> Guardian.Phoenix.Socket.current_claims
        |> Auth.Guardian.decode_permissions_from_claims
        |> Auth.Guardian.any_permissions?(%{"default" => ["login"]})
        case can_login? do
          true ->
            # Allow to continue
            user = Guardian.Phoenix.Socket.current_resource(authed_socket)
            Logger.info "Current Resource for this JWT #{inspect user}"
            {:ok, authed_socket
#            |> assign(:guardian_token, token)        # TODO Review: if UI needs 
            |> assign(:user_id, user.id)           # TODO Review: if UI needs 
            |> assign(:user, user )# TODO Review: if UI needs 
            }
          false ->
            Logger.info "token #{inspect token} contains no :login permission"
            {:ok, socket
            |> assign(:user_id, 0)
            |> assign(:login_error, "no :login permission")
            }
        end
      {:error, reason} ->
        Logger.info "Error Guardian.Phoenix.Socket.authenticate -> reason: #{inspect reason}"
        {:ok, socket
        |> assign(:user_id, 0)
        |> assign(:login_error, reason)
        }
	  end
  end

  @doc """
  No other from of conect is available
  """
  def connect(_params, _socket) do
    :error
  end

  defp process_auth_resp(%{ permissions: nil } = _user, sUID, socket) do
    Logger.info "Can't authenticate user! #{inspect sUID} -> no permissions!"
    {:ok, socket
    |> assign(:user_id, 0)
    |> assign(:login_error, sUID)}
  end

  defp process_auth_resp(%{ id: _id, username: _name } = user, _sUID, socket) do
    Logger.info "Found user:  #{inspect user}"
    {:ok, jwt, claims} = # TODO Maybe log _full_claims for audit?
      Auth.Guardian.encode_and_sign(user ,%{}, permissions: user.permissions )
    {:ok, socket |> Guardian.Phoenix.Socket.assign_rtc(user, jwt, claims)
    |> assign(:guardian_token, jwt)
    |> assign(:user_id, user.id)
    |> assign(:user, user )
    }
  end

  defp process_auth_resp({:error, :user_not_found}, sUID, socket) do
    Logger.info "Can't authenticate user! #{inspect sUID} - user not found"
    {:ok, socket
    |> assign(:user_id, 0)
    |> assign(:login_error, sUID)}
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Cbs.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  # def id(socket), do: "users_socket:#{socket.assigns.user_id}" #
  # login uses anonimous socket? TODO verify it's safe: WATCH OUT FOR DOD ATTACK
  # def id(_socket), do: nil

  def id(socket), do:  "user_socket:#{socket.assigns.user_id}"

  # use code bellow to logout user
  # Cbs.Endpoint.broadcast( "user_socket:#{socket.assigns.user_id}", "disconnect", %{})

end
