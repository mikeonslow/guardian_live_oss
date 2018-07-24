defmodule AppUi.AuthorizedChannelTest do
  use AppUi.ChannelCase
  alias AppUi.UserSocket
  alias AppUi.AuthorizedChannel

  import AppUi.Factory

  setup do

    user = insert(:user) |> Repo.preload(:role) |> Auth.translate_user

    this_user_perms = %{ default: [:login],
                                    auth_test: [:p1, :p3] }
    # issue relativelly long lived token that has minimal permissions
    # the login channel will be responsible for issuing tokens
    # that will have shorter time to live with higher level permissions
    {:ok, jwt, _full_claims} =
      Auth.Guardian.encode_and_sign(user, %{}, permissions: this_user_perms)
    #
    {:ok, socket} = connect(UserSocket,
      %{"jwt" => jwt })

    require Logger
    Logger.info "socket.assigns  =>  #{inspect socket.assigns}"

    {:ok, _reply, socket} = subscribe_and_join(socket,
      AuthorizedChannel,
      "authorized:" <> Integer.to_string(user.id),
      %{})
    {:ok, socket: socket, user: user, jwt: jwt}
  end

  test "pong replies with status ok", %{socket: socket} do
    ref = push socket, "pong", %{"hello" => "there"}
    assert_reply ref, :ok, %{message: "pong"}
  end

  test "p3 replies with status ok cause p3 is granted", %{socket: socket} do
    ref = push socket, :p3, %{"hello" => "there"}
    assert_reply ref, :ok, %{message: :p3}
  end

  test "ping shutdowns socket because p2 permission is not granted", %{socket: socket} do
    Process.monitor(socket.channel_pid)
    _ref = push socket, "ping", %{"hello" => "there"}
    assert_push "unauthorized:permissions", %{
      "error" => 403,
      "message" => "No permission to perform ping"
    }
    assert_receive {:DOWN, _, _,_, :shutdown}
    # TODO assert socket is closed
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from! socket, "broadcast", %{"some" => "data"}
    assert_push "broadcast", %{"some" => "data"}
  end

  test "unauthenticated users cannot join", %{socket: socket} do
    assert {:error, %{error: :not_all_permissions}} =
      socket
      |>  subscribe_and_join(AuthorizedChannel,"authorized:lobby", %{})
  end
end
