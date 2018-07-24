module Page.PermissionError exposing (PermissionErrorModel, permissionError, view)

{-| Renders this page on permission error or channel join error
-}

import Bootstrap.Alert as Alert
import Data.Session as Session exposing (Session)
import Exts.Html exposing (nbsp)
import FontAwesome.Web as FA
import Html exposing (Html, a, div, h1, i, img, main_, p, text)
import Html.Attributes exposing (alt, class, href, id, style, tabindex)
import Route as Route exposing (..)


-- MODEL --


type PermissionErrorModel
    = PermissionError Model


type alias Model =
    { routeToPrevious : Route
    }


permissionError : Route -> PermissionErrorModel
permissionError route =
    PermissionError { routeToPrevious = route }



-- VIEW --


view : Session -> PermissionErrorModel -> Html msg
view session (PermissionError model) =
    let
        msg =
            nbsp ++ " " ++ "You do not have access to this feature in the system"

        alert =
            Alert.danger
                [ p []
                    [ FA.exclamation_triangle
                    , text <| msg
                    ]
                , Alert.link [ Route.href model.routeToPrevious ]
                    [ i [ class "fa fa-arrow-left", style [ ( "padding-right", "10px" ) ] ] []
                    , text "Back to Previous Page"
                    ]
                ]
    in
    main_ [ id "content", class "container", tabindex -1 ]
        [ div []
            [ Alert.h4 [] [ text "Access Error" ]
            , alert
            ]
        ]
