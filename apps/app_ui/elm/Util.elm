module Util
    exposing
        ( (=>)
        , Time
        , appendErrors
        , boolToDisplayString
        , convertStringToTimestamp
        , dFormat
        , dateFormat
        , dateFormatString
        , dateInMilli
        , dateInSeconds
        , dateTimeFormat
        , dateTimeFormatString
        , daysToSeconds
        , delay
        , dtmFormat
        , fuzzySearch
        , initDtm
        , justValues
        , millsecondsToSeconds
        , minutesToDays
        , nl2br
        , onChange
        , onClickStopPropagation
        , pair
        , replace
        , secondsToMillseconds
        , send
        , stringToIdAttr
        , viewIf
        , webDataToMaybe
        )

import Date exposing (..)
import Date.Extra.Config.Config_en_us exposing (config)
import Date.Extra.Create exposing (dateFromFields)
import Date.Extra.Format as Format exposing (format, formatUtc, isoFormat, isoMsecOffsetFormat)
import Html exposing (Attribute, Html)
import Html.Events exposing (defaultOptions, on, onWithOptions)
import Json.Decode as Decode
import Process
import Regex
import RemoteData
import String.Extra as String
import Task
import Time


(=>) : a -> b -> ( a, b )
(=>) =
    (,)


{-| infixl 0 means the (=>) operator has the same precedence as (<|) and (|>),
meaning you can use it at the end of a pipeline and have the precedence work out.
-}
infixl 0 =>


{-| Useful when building up a Cmd via a pipeline, and then pairing it with
a model at the end.

    session.user
        |> User.Request.foo
        |> Task.attempt Foo
        |> pair { model | something = blah }

-}
pair : a -> b -> ( a, b )
pair first second =
    first => second


viewIf : Bool -> Html msg -> Html msg
viewIf condition content =
    if condition then
        content
    else
        Html.text ""


onClickStopPropagation : msg -> Attribute msg
onClickStopPropagation msg =
    onWithOptions "click"
        { defaultOptions | stopPropagation = True }
        (Decode.succeed msg)


appendErrors : { model | errors : List error } -> List error -> { model | errors : List error }
appendErrors model errors =
    { model | errors = model.errors ++ errors }


type alias Time =
    Float


delay : Time -> msg -> Cmd msg
delay time msg =
    Process.sleep time
        |> Task.andThen (always <| Task.succeed msg)
        |> Task.perform identity


convertStringToTimestamp dateString =
    case Date.fromString dateString of
        Ok dt ->
            Date.toTime dt / 1000

        Err error ->
            let
                x =
                    Debug.log "Error occurred converting date to time"
            in
            0


dateTimeFormat dateTimeString =
    Result.withDefault "n/a" <|
        Result.map
            (format config config.format.dateTime)
            (Date.fromString dateTimeString)


dtmFormat dtm =
    Result.withDefault "n/a" <|
        Result.map
            (format config config.format.dateTime)
            dtm


dateFormat dateTimeString =
    Result.withDefault "n/a" <|
        Result.map
            (format config config.format.date)
            (Date.fromString dateTimeString)


dFormat dtm =
    Result.withDefault "n/a" <|
        Result.map
            (format config config.format.date)
            dtm


initDtm =
    dateFromFields 2020 Jan 1 0 0 0 0


send : msg -> Cmd msg
send msg =
    Task.succeed msg
        |> Task.perform identity


millsecondsToSeconds =
    (*) 0.001


secondsToMillseconds =
    (*) 1000


daysToSeconds =
    (*) 86400


minutesToDays =
    (/) 14400


dateInMilli : Date -> Float
dateInMilli date =
    Date.toTime date
        |> Time.inMilliseconds


dateInSeconds : Date -> Int
dateInSeconds date =
    let
        x =
            Debug.log "" { date = date, time = Date.toTime date }
    in
    Date.toTime date
        |> Time.inSeconds
        |> floor


replace : String -> String -> String -> String
replace from to str =
    String.split from str
        |> String.join to


stringToIdAttr s =
    s
        |> replace " " "_"
        |> String.toLower


justValues : List (Maybe a) -> List a
justValues =
    List.filterMap identity


fuzzySearch a b =
    Regex.contains (Regex.regex (a |> fuzzyPattern)) (b |> String.toLower)


fuzzyPattern q =
    q
        |> String.toLower
        |> String.trim
        |> String.words
        |> String.join "(.{0,})"



-- EVENTS


onChange : (String -> msg) -> Attribute msg
onChange handler =
    on "change" <| Decode.map handler <| Decode.at [ "target", "value" ] Decode.string


dateFormatString =
    "%m/%d/%Y"


dateTimeFormatString =
    "%m/%d/%Y %H:%i:%s"


boolToDisplayString : Bool -> String
boolToDisplayString boolean =
    case boolean of
        True ->
            "Yes"

        False ->
            "No"


nl2br =
    String.replace "\n" "<br/>"


webDataToMaybe : RemoteData.WebData x -> Maybe x
webDataToMaybe webData =
    case webData of
        RemoteData.Success something ->
            Just something

        _ ->
            Nothing
