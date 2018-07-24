module Request.Window
    exposing
        ( Option
        , Size(..)
        , close
        , dependent
        , open
        , openNewWindow
        , resizable
        , showLocationBar
        )

import Json.Encode as Encode exposing (Value)
import Ports
import Util exposing ((=>))


type Option
    = Option String


type Size
    = Percent Float
    | Pixel Float


resizable : Option
resizable =
    Option "resizable=true"


dependent : Option
dependent =
    Option "dependent=true"


showLocationBar : Bool -> Option
showLocationBar show =
    Option ("location=" ++ String.toLower (toString show))


openNewWindow : String -> Size -> Size -> List Option -> Cmd msg
openNewWindow url =
    open url "_blank"


open : String -> String -> Size -> Size -> List Option -> Cmd msg
open url windowName width height options =
    let
        windowOptions =
            collectOptions options

        parameters =
            Encode.object
                [ "url" => Encode.string url
                , "name" => Encode.string windowName
                , "action" => Encode.string "open"
                , "options" => Encode.string windowOptions
                , "width" => sizeEncoder width
                , "height" => sizeEncoder height
                ]
    in
    Ports.sendWindowCommand parameters


sizeEncoder : Size -> Value
sizeEncoder size =
    case size of
        Pixel px ->
            Encode.object
                [ "type" => Encode.int 0
                , "value" => Encode.float px
                ]

        Percent percent ->
            Encode.object
                [ "type" => Encode.int 1
                , "value" => Encode.float percent
                ]


close : String -> Cmd msg
close url =
    let
        parameter =
            Encode.object
                [ "url" => Encode.string url
                , "action" => Encode.string "close"
                ]
    in
    Ports.sendWindowCommand parameter


collectOptions : List Option -> String
collectOptions options =
    let
        x =
            Debug.log "collectOptions"
                (List.map optionValue options
                    |> String.join ","
                )
    in
    List.map optionValue options
        |> String.join ","


optionValue : Option -> String
optionValue (Option option) =
    option


positionWithDefault x d =
    if x >= 0 then
        toString x
    else
        toString d
