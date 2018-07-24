module Common.LocalDebug exposing (Level(..), log)


type Level
    = Development
    | Staging
    | Production


log globalDebugLevel debugLevel label payload =
    let
        execDebug =
            printDebugLog label payload
    in
    case ( globalDebugLevel, debugLevel ) of
        ( Development, Development ) ->
            let
                x =
                    execDebug
            in
            True

        ( _, Development ) ->
            False

        ( Staging, Staging ) ->
            let
                x =
                    execDebug
            in
            True

        ( _, Staging ) ->
            False

        ( _, Production ) ->
            let
                x =
                    execDebug
            in
            True


printDebugLog =
    Debug.log
