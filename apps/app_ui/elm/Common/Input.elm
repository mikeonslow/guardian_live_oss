module Common.Input exposing (..)

import Bootstrap.Form.Input
import Html exposing (Attribute)
import Html.Events exposing (on)
import Json.Decode as Decoder


onEnterEvent : msg -> Attribute msg
onEnterEvent action =
    on "keyup" <|
        Decoder.andThen
            (\keyCode ->
                if keyCode == 13 then
                    Decoder.succeed action
                else
                    Decoder.fail (toString keyCode)
            )
            Html.Events.keyCode


onEnter : msg -> Bootstrap.Form.Input.Option msg
onEnter action =
    Bootstrap.Form.Input.attrs [ onEnterEvent action ]


onBackspaceEvent : msg -> Attribute msg
onBackspaceEvent action =
    on "keydown" <|
        Decoder.andThen
            (\keyCode ->
                if keyCode == 8 then
                    Decoder.succeed action
                else
                    Decoder.fail (toString keyCode)
            )
            Html.Events.keyCode


onBackspace : msg -> Bootstrap.Form.Input.Option msg
onBackspace action =
    Bootstrap.Form.Input.attrs [ onBackspaceEvent action ]
