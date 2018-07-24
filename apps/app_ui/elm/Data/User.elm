module Data.User exposing (..)

import Data.AuthToken as AuthToken exposing (AuthToken)
import Data.UserPhoto as UserPhoto exposing (UserPhoto)
import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)
import Json.Encode as Encode exposing (Value)
import Json.Encode.Extra as EncodeExtra
import UrlParser
import Util exposing ((=>))


type alias User =
    { id : Float
    , email : String
    , guardian_token : AuthToken
    , username : Username
    }



-- SERIALIZATION --


decoder : Decoder User
decoder =
    decode User
        |> required "id" Decode.float
        |> required "email" Decode.string
        |> required "guardian_token" AuthToken.decoder
        |> required "username" usernameDecoder


encode : User -> Value
encode user =
    Encode.object
        [ "id" => Encode.float user.id
        , "email" => Encode.string user.email
        , "guardian_token" => AuthToken.encode user.guardian_token
        , "username" => encodeUsername user.username
        ]



-- Username


type Username
    = Username String


usernameToString : Username -> String
usernameToString (Username username) =
    username


usernameParser : UrlParser.Parser (Username -> a) a
usernameParser =
    UrlParser.custom "USERNAME" (Ok << Username)


usernameDecoder : Decoder Username
usernameDecoder =
    Decode.map Username Decode.string


encodeUsername : Username -> Value
encodeUsername (Username username) =
    Encode.string username


usernameToHtml : Username -> Html msg
usernameToHtml (Username username) =
    Html.text username



-- FullName


type FullName
    = FullName String


fullNameToString : FullName -> String
fullNameToString (FullName fullname) =
    fullname


fullNameDecoder : Decoder FullName
fullNameDecoder =
    Decode.map FullName Decode.string


encodeFullName : FullName -> Value
encodeFullName (FullName fullName) =
    Encode.string fullName


fullNameToHtml : FullName -> Html msg
fullNameToHtml (FullName fullName) =
    Html.text fullName


getUsername user =
    case user of
        Nothing ->
            ""

        Just user ->
            usernameToString user.username
