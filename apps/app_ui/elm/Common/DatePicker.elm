module DateTime exposing (onDateChange, root)

import Date exposing (Date)
import Html exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode exposing (..)
import Native.DateTimePicker


root : List (Attribute msg) -> Date -> Html msg
root attributes defaultDate =
    Native.DateTime.root attributes defaultDate


onDateChange : (Date -> msg) -> Attribute msg
onDateChange tagger =
    on "datechange"
        (Decode.map (Date.fromTime >> tagger)
            ("detail" := float)
        )
