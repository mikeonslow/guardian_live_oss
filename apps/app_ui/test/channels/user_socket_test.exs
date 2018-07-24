defmodule AppUi.UserSocketTest do
  use AppUi.ChannelCase

  alias AppUi.UserSocket

  import AppUi.Factory

  alias Auth
  alias Auth.Repo

  setup do

    role = insert(:role)

    user1 = insert(:user) |> Repo.preload(:role)
    user_sans_role = user1 |> Auth.translate_user

    user2 = insert(:user, role: role)
    user_with_role = user2 |> Auth.translate_user

    { :ok, no_login_jwt, _full_claims_user1 } =
      Auth.Guardian.encode_and_sign(user_sans_role ,%{}, permissions: %{} )
    # TODO later issue relativelly long lived token that has minimal permissions
    # the login channel will be responsible for issuing tokens
    # that will have shorter time to live with higher level permissions
    {:ok, token, _full_claims2} = Auth.Guardian.encode_and_sign( user_with_role, %{}, permissions: role.clperms)
#    require Logger
    #    Logger.info "setup user  =>  #{inspect full_claims2} #{inspect user2}"
#    Logger.info "setup jwt  =>  #{inspect token}"
    # supply to tests 
    {:ok, user_sans_role: { user1.sUID, user1.password },
     user: user_with_role,
     username: user2.sUID,
     password: user2.password,
     jwt: token,
     no_login_jwt: no_login_jwt }
  end

  test "Socket login routine test", %{user: user, username: username, password: password, jwt: jwt } do
    require Logger
    #
    {:ok, socket } = connect(UserSocket,
      %{"username" => username,
        "password" => password})
    Logger.info "socket.assigns #{inspect socket.assigns}"
    s_user = socket.assigns[:user]
    Logger.info "s_user  =>  #{inspect s_user}"
    { :ok, claims } = Auth.Guardian.decode_and_verify(jwt)
    %{"sub" => "User:"<> userId } = claims
    #assert
    pfc = Auth.Guardian.decode_permissions_from_claims(claims)
     # Permissions.from_claims(claims, :default )
    Logger.info "PFC =  #{inspect pfc}"
    assert Auth.Guardian.decode_permissions_from_claims(claims)
    |> Auth.Guardian.any_permissions?( %{default: ["login"]})
    assert String.to_integer(userId) == user.id
  end

  test "Socket login failed without role", %{user_sans_role: {username, password}} do
    {:ok, socket } = connect(UserSocket,
      %{"username" => username,
        "password" => password})
    require Logger
    Logger.info "socket.assigns #{inspect socket.assigns}"
    assert socket.assigns[:login_error] |> String.match?(~r/borodark-./)
    assert socket.assigns[:user_id] == 0
  end

  test "Can NOT connect to socket - " do
    assert :error == connect(UserSocket,
      %{"user" => "borodark",
	      "passw" => "secret"})
  end


  test "Can connect to socket using jwt ", %{user: user, jwt: jwt} do
    {:ok, socket} = connect(UserSocket,
      %{"jwt" => jwt})

    assert socket.assigns[:user_id] == user.id
    assert socket.assigns[:guardian_default_token] == jwt
  end

  test "Can't connect to socket with username, password that were not setup" do
    {:ok, socket } = connect(UserSocket,
      %{"username" => "borodark", "password" => "secret"})
    assert socket.assigns == %{login_error: "borodark", user_id: 0}
  end

  test "Can not connect with valid JWT without login permissions", %{ no_login_jwt: jwt} do
    {:ok, socket } = connect(UserSocket,
      %{"jwt" => jwt})
    assert socket.assigns[:login_error] != nil 
    assert socket.assigns[:user_id] == 0
  end

  test "Can connect with valid JWT ", %{user: user, jwt: jwt} do
    {:ok, socket} = connect(UserSocket, %{"jwt" => jwt})
    assert socket.assigns[:user_id] == user.id
    assert socket.assigns[:guardian_default_token] == jwt
  end

  test "Can not connect to socket with some dumn jwt" do
    {:ok, socket } = connect(UserSocket,
      %{"jwt" => "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJVc2VyOjE1NSIsImV4cCI6MTQ5MTg0NTg4MCwiaWF0IjoxNDkxNzU5NDgwLCJpc3MiOiJjYnMiLCJqdGkiOiI2MmJmZjZjMC1lZDRjLTRkOGQtYjk2Ni1kNjU3YWY5OTQxZDkiLCJwZW0iOnt9LCJzdWIiOiJVc2VyOjE1NSIsInR5cCI6ImFjY2VzcyJ9.Kd-bCE6xxz7FsNvdYsUR6urVKyOOUlY_hqPuMjzjE-baykvTrmZPb6NhTTARy8RUBx4GuVHoGgjYuQVNqTHCwg"}
    )
    assert socket.assigns[:login_error] == :invalid_token
    assert socket.assigns[:user_id] == 0
  end

end
