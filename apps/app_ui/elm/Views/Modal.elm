module Views.Modal exposing (buttonClose, view)

import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Exts.Html exposing (nbsp)
import FontAwesome.Web as FA
import Html exposing (Html, br, i, text)
import Html.Attributes exposing (class, style, target)
import Html.Events as Events


{- TODO keep config out of state (Data combines state with config) -}


type alias Config msg =
    { title : String
    , tagger : Modal.State -> msg
    }


buttonClose clickHandler =
    Button.button
        [ Button.secondary
        , Button.small
        , Button.attrs [ Events.onClick clickHandler ]
        ]
        [ FA.times_circle, text nbsp, Html.text "Close" ]


view config =
    Modal.config config.tagger
        |> Modal.large
        |> Modal.h3 [] [ text config.title ]
        |> Modal.body [ class "list-modal" ]
            []
        |> Modal.footer []
            [ Button.button
                [ Button.secondary
                , Button.small
                , Button.onClick <| config.tagger Modal.hiddenState
                ]
                [ FA.times_circle, text " Close" ]
            ]
        |> Modal.view config.modal
