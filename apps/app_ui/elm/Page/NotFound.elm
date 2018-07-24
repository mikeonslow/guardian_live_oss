module Page.NotFound exposing (view)

import Bootstrap.Card as Card
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Text as Text
import Data.Session as Session exposing (Session)
import Html exposing (..)
import Html.Attributes exposing (..)
import Views.Assets as Assets


-- VIEW --


view : Session -> Html msg
view model =
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
