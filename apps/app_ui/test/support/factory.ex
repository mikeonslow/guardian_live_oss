defmodule AppUi.Factory do
  use ExMachina.Ecto, repo: Auth.Repo

  alias Auth.User
  alias Auth.Role

  @clperms  %{ "default" => ["login", "token", "logout", "refresh", "exchange"]
               # ,
	#      orders_quotes: ["Browse", "Update", "Delete"],
	#      orders_customerOrders: ["Browse"],
	#      orders_quotes_generate: ["All"],
	#      myProfile: ["All"],
	#             support: ["None"]
  }

  def role_factory do
    %Role{
      vname: "borodark-test",
      clperms: @clperms
    }
  end

  def user_factory do
    sPasswd = Comeonin.Bcrypt.hashpwsalt("Password123")
    %User{
      sUID: sequence("borodark-test"),
      sEmail: sequence(:email, &"email-#{&1}@example.com"),
      password: "Password123",
      password_shadow:  sPasswd
    }
  end

end
