module Data.Link exposing (..)

import Dict exposing (Dict)


type alias Data =
    { action : String, params : Dict String String }


type Action
    = OpenSupportTicket Float
    | Unknown


toAction : Data -> Action
toAction { action, params } =
    case ( action, params ) of
        ( "viewSupportTicket", params ) ->
            Dict.get "id" params
                |> Result.fromMaybe "No parameter `id` found in `params`"
                |> Result.andThen String.toFloat
                |> Result.map (\id -> OpenSupportTicket id)
                |> Result.withDefault Unknown

        ( unhandled, _ ) ->
            Debug.log ("Data.Link.toAction | Cannot resolve action `" ++ unhandled ++ "`, returning default action") Unknown


default =
    { action = ""
    , params = Dict.empty
    }
