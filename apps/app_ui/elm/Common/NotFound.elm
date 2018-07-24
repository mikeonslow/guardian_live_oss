module Common.NotFound exposing (root)

import Bootstrap.Card as Card
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Text as Text
import Html exposing (..)
import Html.Attributes exposing (..)


root model =
    Grid.containerFluid
        [ class "loginContainer" ]
        [ Grid.row []
            [ Grid.col [ Col.xs4 ]
                []
            , Grid.col [ Col.xs4 ]
                [ viewNotFoundCard model ]
            , Grid.col [ Col.xs4 ]
                []
            ]
        ]


viewNotFoundCard model =
    Card.config [ Card.attrs [ style [ ( "width", "23rem" ) ] ] ]
        |> Card.header [ class "text-center" ]
            [ img [ src "images/if_lock_60740.png", class "img-fluid" ] []
            ]
        |> Card.block []
            [ Card.titleH4 [] [ text "Page Not Found" ]
            , Card.text []
                [ text "The page you are looking for was not found" ]
            ]
        |> Card.view
