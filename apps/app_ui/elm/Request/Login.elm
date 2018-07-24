module Request.Login exposing (..)

import Data.User as User exposing (User)
import Json.Encode as Encode
import Ports


storeSession : User -> Cmd msg
storeSession user =
    User.encode user
        |> Encode.encode 0
        |> Just
        |> Ports.sendUsernameCache
