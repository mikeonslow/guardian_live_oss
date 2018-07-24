module Data.LocalStorageChange exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)


type alias Change =
    { key : Maybe String
    , newValue : Maybe String
    , oldValue : Maybe String
    , url : String
    }



-- SERIALIZATION --


decoder : Decoder Change
decoder =
    decode Change
        |> required "key" nullableString
        |> required "newValue" nullableString
        |> required "oldValue" nullableString
        |> required "url" Decode.string


nullableString : Decoder (Maybe String)
nullableString =
    Decode.nullable Decode.string
