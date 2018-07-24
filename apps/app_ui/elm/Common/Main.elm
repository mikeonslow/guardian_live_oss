module Common.Main exposing (root)

import Bootstrap.Card as Card
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Text as Text
import Html exposing (..)
import Html.Attributes exposing (..)


root model =
    Grid.containerFluid
        []
        [ Grid.row []
            [ Grid.col [ Col.xs12 ] []
            ]
        ]
