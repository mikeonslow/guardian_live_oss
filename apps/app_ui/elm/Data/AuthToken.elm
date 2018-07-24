module Data.AuthToken exposing (AuthToken(..), authTokenToString, decoder, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


type AuthToken
    = AuthToken String


encode : AuthToken -> Value
encode (AuthToken token) =
    Encode.string token


decoder : Decoder AuthToken
decoder =
    Decode.string
        |> Decode.map AuthToken


authTokenToString : AuthToken -> String
authTokenToString (AuthToken token) =
    token
