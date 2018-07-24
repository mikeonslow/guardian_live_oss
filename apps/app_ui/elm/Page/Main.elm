module Page.Main exposing (ExternalMsg(..), Model, Msg(..), initialModel, update, view)

import Bootstrap.Card as Card
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Text as Text
import Data.Session as Session exposing (Session)
import Html exposing (..)
import Html.Attributes exposing (..)
import Util exposing ((=>))
import Views.Assets as Assets


-- MODEL --


type alias Model =
    { errors : List Error }


type alias Error =
    ( String, String )


type Msg
    = NoOption


type ExternalMsg
    = NoOp


initialModel : Model
initialModel =
    { errors = [] }


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        NoOption ->
            model => Cmd.none => NoOp



-- VIEW --


view : Session -> Html msg
view model =
    Grid.containerFluid
        [ class "mainContainer" ]
        [ Grid.row []
            [ Grid.col [ Col.xs12 ]
                []
            ]
        ]
