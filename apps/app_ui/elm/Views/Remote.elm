module Views.Remote exposing (Config, SimpleConfig, TableConfig, custom, simple, table)

import Bootstrap.Table as Table exposing (TBody, THead, TableOption)
import Common.Icons as Icon
import FontAwesome.Web as FA
import Html exposing (Html)
import Html.Attributes exposing (attribute, class)
import RemoteData exposing (RemoteData(..))


type alias SimpleConfig e msg =
    { error : String
    , loading : String
    , remote : RemoteData e (Html msg)
    }


type alias TableConfig e msg =
    { error : String
    , loading : String
    , options : List (TableOption msg)
    , thead : THead msg
    , tbody : RemoteData e (TBody msg)
    }


type alias Config msg =
    { initial : Html msg
    , loading : Html msg
    , remote : RemoteData (Html msg) (Html msg)
    }


simple : SimpleConfig e msg -> Html msg
simple { error, loading, remote } =
    custom
        { initial = Html.text ""
        , loading =
            Html.span [ class "remote-state" ]
                [ Html.i
                    [ attribute "aria-hidden" "true"
                    , class "fa fa-spinner fa-pulse"
                    ]
                    []
                , Html.text loading
                ]
        , remote = RemoteData.mapError (\_ -> Html.span [ class "remote-state" ] [ Icon.basicIcon FA.exclamation_triangle False, Html.text error ]) remote
        }


table : TableConfig e msg -> Html msg
table { error, loading, options, thead, tbody } =
    custom
        { initial = emptyTable options thead
        , loading =
            [ Html.i
                [ attribute "aria-hidden" "true"
                , class "fa fa-spinner fa-pulse"
                ]
                []
            , Html.text loading
            ]
                |> tableBodyState options thead
        , remote =
            RemoteData.map (\body -> Table.table { options = options, thead = thead, tbody = body }) tbody
                |> RemoteData.mapError
                    (\_ ->
                        [ Icon.basicIcon FA.exclamation_triangle False, Html.text error ]
                            |> tableBodyState options thead
                    )
        }


custom : Config msg -> Html msg
custom { initial, loading, remote } =
    case remote of
        NotAsked ->
            initial

        Loading ->
            loading

        Success view ->
            view

        Failure view ->
            view



-- Helpers


emptyTable : List (TableOption msg) -> THead msg -> Html msg
emptyTable options thead =
    Table.table { options = options, thead = thead, tbody = Table.tbody [] [] }


tableBodyState : List (TableOption msg) -> THead msg -> List (Html msg) -> Html msg
tableBodyState options thead body =
    Html.div []
        [ emptyTable options thead
        , Html.div [ class "table-body-state" ] body
        ]
