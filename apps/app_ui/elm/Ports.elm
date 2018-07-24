port module Ports exposing (..)

import Json.Encode exposing (Value, object, string)


type alias GuardianToken =
    { guardian_token : String }


type alias CacheData =
    { username : String
    , cacheEnabled : Bool
    }


port setSecurityToken : String -> Cmd msg


port getSecurityToken : String -> Cmd msg


port sendSecurityToken : (GuardianToken -> msg) -> Sub msg


port clearSecurityToken : String -> Cmd msg


port setUsernameCache : String -> Cmd msg


port getUsernameCache : String -> Cmd msg


port sendUsernameCache : (CacheData -> msg) -> Sub msg


port clearUsernameCache : String -> Cmd msg


port setUserCache : Value -> Cmd msg


port clearUserCache : String -> Cmd msg


port sendWindowCommand : Value -> Cmd msg


port receiveWindowCommand : (Value -> msg) -> Sub msg


port localStorageChanged : (Value -> msg) -> Sub msg


port sendToLocalStorage : Value -> Cmd msg


port selectedFile : (Value -> msg) -> Sub msg


port watchFileSelections : String -> Cmd msg
