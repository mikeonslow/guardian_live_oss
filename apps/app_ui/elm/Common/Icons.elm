module Common.Icons
    exposing
        ( ActionIcon
        , actionIcon
        , actionIconProps
        , actionIconWithClickPopover
        , actionIconWithHoverPopover
        , basicIcon
        , basicIconWithClickPopover
        , basicIconWithHoverPopover
        , customFAIcon
        , iconContainer
        )

import Bootstrap.Popover as Popover
import Color exposing (..)
import FontAwesome.Web as Icon
import Html exposing (Html, a, span)
import Html.Attributes exposing (class, classList)


type alias ActionIcon =
    { color : Color
    , disabledColor : Color
    , size : Int
    }


actionIconProps =
    { color = Color.black
    , disabledColor = Color.gray
    , size = 14
    }


actionIcon icon isEnabled container =
    let
        iconElem =
            case container of
                Nothing ->
                    [ basicIcon icon isEnabled ] |> iconContainer isEnabled

                Just outerElem ->
                    [ outerElem [ basicIcon icon isEnabled ] ] |> iconContainer isEnabled
    in
    iconElem


basicIcon icon isEnabled =
    icon


customFAIcon : String -> Html msg
customFAIcon className =
    -- build icon from Font Awesome icon class name, omit the "fa fa-" part
    Html.i [ Html.Attributes.class ("fa fa-" ++ className) ] []


basicIconWithHoverPopover : Html.Html msg -> Bool -> (Popover.State -> msg) -> Popover.State -> Popover.Config msg
basicIconWithHoverPopover icon isEnabled msg state =
    basicIconWithPopover icon isEnabled (Popover.onHover state msg)


basicIconWithClickPopover : Html.Html msg -> Bool -> (Popover.State -> msg) -> Popover.State -> Popover.Config msg
basicIconWithClickPopover icon isEnabled msg state =
    basicIconWithPopover icon isEnabled (Popover.onClick state msg)


basicIconWithPopover : Html.Html msg -> Bool -> List (Html.Attribute msg) -> Popover.Config msg
basicIconWithPopover icon isEnabled event =
    Popover.config <|
        span
            (iconContainerClasses isEnabled :: event)
            [ icon ]


actionIconWithHoverPopover :
    Html msg
    -> Bool
    -> Maybe (List (Html msg) -> Html msg)
    -> (Popover.State -> msg)
    -> Popover.State
    -> Popover.Config msg
actionIconWithHoverPopover icon isEnabled container msg state =
    actionIconWithPopover icon isEnabled container (Popover.onHover state msg)


actionIconWithClickPopover :
    Html msg
    -> Bool
    -> Maybe (List (Html msg) -> Html msg)
    -> (Popover.State -> msg)
    -> Popover.State
    -> Popover.Config msg
actionIconWithClickPopover icon isEnabled container msg state =
    actionIconWithPopover icon isEnabled container (Popover.onClick state msg)


actionIconWithPopover :
    Html msg
    -> Bool
    -> Maybe (List (Html msg) -> Html msg)
    -> List (Html.Attribute msg)
    -> Popover.Config msg
actionIconWithPopover icon isEnabled container event =
    let
        containerAttrs =
            span
                (iconContainerClasses isEnabled :: event)

        iconElem =
            case container of
                Nothing ->
                    containerAttrs [ basicIcon icon isEnabled ]

                Just outerElem ->
                    containerAttrs [ outerElem [ basicIcon icon isEnabled ] ]
    in
    Popover.config iconElem


iconContainer isEnabled =
    span
        [ iconContainerClasses isEnabled ]


iconContainerClasses isEnabled =
    classList
        [ ( "icon-action", True )
        , ( "disabled", not isEnabled )
        ]
