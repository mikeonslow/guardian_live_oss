module Views.Alert exposing (view)

import Data.Alert as Alert exposing (Alert)
import Html exposing (Html, div, i)
import Html.Attributes exposing (attribute, class)
import Types exposing (Msg(..))


view : Alert -> Html msg
view alert =
    let
        checkIconClass =
            "check"

        infoCircleIconClass =
            "info-circle"

        exclamationIconClass =
            "exclamation-triangle"

        ( iconClass, toastRoleClass, text ) =
            case alert.alertType of
                Alert.Basic text ->
                    ( Nothing, "info", text )

                Alert.Success text ->
                    ( Just checkIconClass, "success", text )

                Alert.Info text ->
                    ( Just infoCircleIconClass, "info", text )

                Alert.Warning text ->
                    ( Just exclamationIconClass, "warning", text )

                Alert.Danger text ->
                    ( Just exclamationIconClass, "danger", text )

                Alert.Error text ->
                    ( Just exclamationIconClass, "danger", text )

        icon =
            case iconClass of
                Nothing ->
                    Html.text ""

                Just iconClass ->
                    i
                        [ attribute "aria-hidden" "true"
                        , class ("fa fa-" ++ iconClass)
                        ]
                        []
    in
    div [ class (defaultToastClasses ++ toastRoleClass) ]
        [ icon
        , Html.text text
        ]


defaultToastClasses =
    "toast display-and-fade "
