defmodule AppUi.LoginChannelTest do
  use AppUi.ChannelCase #,async: true
  alias AppUi.UserSocket
  alias AppUi.LoginChannel
  import AppUi.Factory
  require Logger

  setup do

    role = insert(:role)
    user = insert(:user, role: role)
#    Logger.info "Dump role: #{inspect role} ---------> #{inspect user}"
    {:ok, socket} = connect(UserSocket,
      %{"username" => user.sUID,
	      "password" => "Password123"}
    )
    {:ok, _reply, socket} = subscribe_and_join(
      socket,
      LoginChannel,
      "login:"<> Integer.to_string(user.iUID),
      %{"username" => user.sUID}
    )

    ## to make sure we receive the :after_join with jwt token
    jwt = socket.assigns[:guardian_default_token]
    Logger.info "Dump jwt: #{inspect jwt} ---------> #{inspect user}"
    assert_push "user:guardian_token", %{guardian_token: jwt}
    {:ok, socket: socket, user: user, jwt: jwt }
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push socket, "ping", %{"hello" => "there"}
    assert_reply ref, :ok, %{message: "pong"}
  end

  test "logout ", %{socket: socket, jwt: jwt} do
    #Process.unlink(socket.channel_pid)
    push socket, "logout", %{
        "guardain_token" => jwt
    }
    #assert_received(:exit)
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from! socket, "broadcast", %{"some" => "data"}
    assert_push "broadcast", %{"some" => "data"}
  end

end
