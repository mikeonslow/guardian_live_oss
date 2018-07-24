module Common.Form.Button exposing (Data)

import Bootstrap.Button as Button
import Html exposing (Html)


type alias Data msg =
    { label : String
    , icon : Html msg
    , typeStyle : Button.Option msg
    , onClick : Maybe msg
    }
