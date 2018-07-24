module Data.Response exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, optional, required)


type alias Data =
    { status : Int
    , message : String
    }


decoder : Decoder Data
decoder =
    decode Data
        |> required "status" Decode.int
        |> required "message" Decode.string
