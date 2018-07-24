module Views.LoaderTop exposing (view)

import Bootstrap.Form as Form
import Bootstrap.Progress as Progress
import Data.Loader as Loader
import Html
import Html.Attributes exposing (class)


initialProps =
    [ Progress.height 6
    , Progress.value 100
    ]


view page =
    let
        loader =
            case page.globalState.loaderStatus of
                Nothing ->
                    Html.text ""

                Just state ->
                    Html.div [ class "loader-top" ]
                        [ Progress.progress
                            (initialProps
                                |> addRole state
                                |> addAnimationType state
                            )
                        ]
    in
    loader


addRole state props =
    let
        display =
            case state of
                Loader.Info ->
                    [ Progress.info ]

                Loader.Warning ->
                    [ Progress.warning ]

                Loader.Success ->
                    [ Progress.success ]

                Loader.Error ->
                    [ Progress.danger ]
    in
    List.concat [ display, props ]


addAnimationType state props =
    let
        display =
            case state of
                Loader.Error ->
                    []

                _ ->
                    [ Progress.animated, Progress.striped ]
    in
    List.concat [ display, props ]
