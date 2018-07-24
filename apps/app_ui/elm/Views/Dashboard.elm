module Views.Dashboard
    exposing
        ( Col
        , Data
        , Msg
        , Row
        , Widget
        , closeDetail
        , col
        , init
        , modalTagger
        , openDetail
        , row
        , update
        , view
        )

{-| Module for a dashboard view, that shows widgets in a grid and handles the modal states.


# Data

@docs Data, init


# Update

@docs Msg, update, openDetail, closeDetail, modalTagger


# Rendering

@docs Row, row, Col, col, Widget, view

-}

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col
import Bootstrap.Grid.Row
import Bootstrap.Modal as Modal
import Dict exposing (Dict)
import Exts.Html exposing (nbsp)
import Html exposing (Html)


-- Data


{-| Opaque type representing the state of the dashboard.
-}
type Data
    = Data State


type alias State =
    { modals : Dict String Modal.State
    }


{-| Initialize dashboard data.
-}
init : Data
init =
    Data { modals = Dict.empty }



-- Update


{-| Opaque type for updating dashboard data.
-}
type Msg id
    = ModalMsg id Modal.State


{-| Update data based on a message.
-}
update : Msg id -> Data -> Data
update msg (Data data) =
    case msg of
        ModalMsg id modalState ->
            let
                closedDialogs =
                    Dict.map (\_ _ -> Modal.hiddenState) data.modals
            in
            Data
                { data
                    | modals = Dict.insert (toKey id) modalState closedDialogs
                }


{-| open a widget model to expand into detail view.
-}
openDetail : id -> Msg id
openDetail id =
    ModalMsg id Modal.visibleState


{-| Close a detailed view of a widget.
-}
closeDetail : id -> Msg id
closeDetail id =
    ModalMsg id Modal.hiddenState


{-| Used for converting a modal state to a Msg.
-}
modalTagger : id -> (Modal.State -> Msg id)
modalTagger id =
    ModalMsg id


toKey : id -> String
toKey =
    toString



-- View


{-| Represents a widget in the dashboard.
-}
type alias Widget identifier msg =
    { id : identifier
    , content : Html msg
    , modal : Modal.Config msg
    }


{-| Opaque type that represents a row of widget columns.
-}
type Row id msg
    = Row (List (Bootstrap.Grid.Row.Option msg)) (List (Col id msg))


{-| Opaque type that represents a column for a widget.
-}
type Col id msg
    = Column (List (Bootstrap.Grid.Col.Option msg)) (Widget id msg)


{-| Create a row of columns.

    row [] [ col [ Col.xs3 ] myWidget ]

-}
row : List (Bootstrap.Grid.Row.Option msg) -> List (Col id msg) -> Row id msg
row options columns =
    Row options columns


{-| Create a column for rendering a widget.

    col [ Col.xs12 ] myWidget

-}
col : List (Bootstrap.Grid.Col.Option msg) -> Widget id msg -> Col id msg
col options widget =
    Column options widget


{-| Render a grid of widgets.

    view []
        [ row [] [ col [ Col.xs3 ] myWidget ] ]
        data

-}
view : List (Html.Attribute msg) -> List (Row id msg) -> Data -> Html msg
view attrs widgets data =
    let
        rows =
            List.map (renderRow data) widgets

        children =
            [ emptyRow ] ++ rows ++ [ emptyRow ]
    in
    Grid.containerFluid attrs children


emptyRow : Html msg
emptyRow =
    Grid.row []
        [ Grid.col [ Bootstrap.Grid.Col.xs12 ]
            [ Html.text nbsp ]
        ]


renderRow : Data -> Row id msg -> Html msg
renderRow data (Row attrs cols) =
    Grid.row attrs (List.map (renderCol data) cols)


renderCol : Data -> Col id msg -> Grid.Column msg
renderCol (Data data) (Column attrs widget) =
    let
        modalState =
            Dict.get (toKey widget.id) data.modals
                |> Maybe.withDefault Modal.hiddenState
    in
    Grid.col attrs
        [ Html.div []
            [ widget.content
            , Modal.view modalState widget.modal
            ]
        ]
