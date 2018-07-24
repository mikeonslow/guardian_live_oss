module Views.Popover exposing (..)

import Html exposing (a, div, h2, span, text)
import Html.Attributes exposing (class, href)


view hoverTarget content =
    span [ class "popover__wrapper" ]
        [ a [ href "#" ]
            [ span [ class "popover__title" ]
                hoverTarget
            ]
        , div [ class "push popover__content" ]
            content
        ]
