module Common.PhoneHelper exposing (..)

import Char
import Exts.Html exposing (nbsp)
import Html exposing (..)
import Html.Attributes exposing (..)


prettyFormat number =
    number
        |> String.filter Char.isDigit
        |> (\s ->
                case String.toList s of
                    [ a, b, c, d, e, f, g, h, i, j ] ->
                        String.fromList [ '(', a, b, c, ')', ' ', d, e, f, '-', g, h, i, j ]

                    [ '1', b, c, d, e, f, g, h, i, j, k ] ->
                        String.fromList [ '1', ' ', '(', b, c, d, ')', ' ', e, f, g, '-', h, i, j, k ]

                    _ ->
                        s
           )


callerNumberIcon =
    i [ class "fa fa-phone fa-3" ] []


callerNumberDetails number =
    if not <| String.isEmpty <| prettyFormat number then
        [ callerNumberIcon, text <| " " ++ prettyFormat number ]
    else
        []


callerCIDIcon =
    Html.i [ class "fa fa-user-circle fa-2" ] []


callerCIDDetails name =
    if not <| String.isEmpty name then
        [ text nbsp, callerCIDIcon, text <| " " ++ name ]
    else
        []



--callerDetails =
--    List.concat [ callerNumberDetails, callerCIDDetails ]
