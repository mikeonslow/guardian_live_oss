module Page.Link exposing (ExternalMsg(..), Model, Msg(..), init, update, view)

import Common.Connection as Connection
import Common.Url as Url
import Data.Link as Link
import Data.Session as Session exposing (Session)
import Data.User as User exposing (User)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import UrlParser as Url exposing ((</>), (<?>), Parser, QueryParser, int, oneOf, parseHash, parsePath, s, string, stringParam, top)
import Util exposing ((=>))
import Views.Assets as Assets


-- MODEL --


type alias Model =
    { errors : List Error }


type alias Error =
    ( String, String )


type Msg
    = Dispatch Link.Action
    | NoOption


type ExternalMsg
    = OpenSupportTicketView Float
    | NoOp


init : Maybe User -> String -> ( Model, Cmd Msg )
init user options =
    let
        action =
            Link.toAction (parseOptions options)

        x =
            Debug.log "Page.Link.init options" { options = options, action = action }

        cmds =
            case action of
                Link.OpenSupportTicket id ->
                    Util.send <| Dispatch action

                _ ->
                    Cmd.none
    in
    initialModel user options => cmds


initialModel : Maybe User -> String -> Model
initialModel user options =
    { errors = [] }


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        Dispatch action ->
            case action of
                Link.OpenSupportTicket ticketId ->
                    model => Cmd.none => OpenSupportTicketView ticketId

                _ ->
                    model => Cmd.none => NoOp

        NoOption ->
            model => Cmd.none => NoOp



-- VIEW --


view : Model -> Html Msg
view model =
    text ""



-- HELPERS --


parseOptions options =
    options
        |> String.split "?"
        |> (\opts ->
                case opts of
                    action :: [ query ] ->
                        { action = action, params = Url.parseQuery query }

                    _ ->
                        Link.default
           )
        |> Debug.log "parsedOptions"
