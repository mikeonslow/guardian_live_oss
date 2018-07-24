module Request.LocalStorage
    exposing
        ( removeItem
        , saveItem
        )

import Json.Encode as Encode exposing (Value)
import Ports
import Util exposing ((=>))


saveItem : String -> String -> Cmd msg
saveItem key value =
    let
        item =
            Encode.object
                [ encodeKey key
                , "value" => Encode.string value
                , "action" => Encode.string "set"
                ]
    in
    Ports.sendToLocalStorage item


removeItem : String -> Cmd msg
removeItem key =
    let
        item =
            Encode.object
                [ encodeKey key
                , "action" => Encode.string "remove"
                ]
    in
    Ports.sendToLocalStorage item


encodeKey : String -> ( String, Value )
encodeKey key =
    ( "key", Encode.string key )
