module Common.Layout.Header exposing (pageHeader)

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Exts.Html exposing (nbsp)
import Html exposing (h5, text)
import String
import String.Extra as Sx


pageHeader model =
    let
        headerText =
            model.routePath
                |> Sx.replace "#" ""
                |> String.split "/"
                |> List.map Sx.toSentenceCase
                |> String.join " / "
    in
    [ Grid.row []
        [ Grid.col [ Col.xs12 ] [ text nbsp ] ]
    , Grid.row []
        [ Grid.col [ Col.xs12 ] [ h5 [] [ text headerText ] ] ]
    , Grid.row []
        [ Grid.col [ Col.xs12 ] [ text nbsp ] ]
    ]
