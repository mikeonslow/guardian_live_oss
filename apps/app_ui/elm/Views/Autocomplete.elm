module Views.Autocomplete
    exposing
        ( Item
        , KeyboardEvents
        , Msg(InputChanged, ItemSelected, RefreshMenu, ResetMenu, SetText, UpdateAutocomplete)
        , State
        , ViewConfig
        , init
        , simpleMenuViewConfig
        , simpleUpdate
        , simpleUpdateConfig
        , simpleView
        , splitView
        , subscription
        , text
        , updateWithConfig
        , viewWithConfig
        )

{-| A wrapper for elm-autocomplete.
Provides standard update and view configurations and applies subscription events to only the focused element.


# State

@docs State, init, text


# Update

@docs Msg, Item, simpleUpdate, updateWithConfig, simpleUpdateConfig, subscription


# View

@docs ViewConfig, simpleMenuViewConfig, simpleView, viewWithConfig, splitView

-}

import Autocomplete
import Bootstrap.Form.Input as Input
import Control as Debounce
import Control.Debounce
import Exts.List as ListExtra
import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Events
import Json.Decode
import Process
import Regex
import Task
import Time
import Util exposing ((=>))


-- State


{-| Opaque type that holds the state for an autocomplete menu.
-}
type State
    = State AutoState


type alias AutoState =
    { autoState : Autocomplete.State
    , showMenu : Bool
    , query : Query
    , isFocused : Bool
    , howManyToShow : Int
    , debounce : Debounce.State Msg
    }


{-| Get the current text value of the autocomplete
-}
text : State -> String
text (State state) =
    case state.query of
        None ->
            ""

        UserInput text ->
            text

        PreviewInput text previewText ->
            previewText


{-| Initialize state with the max amount of items to show in an autocomplete menu and the initial query.

    init 10 ""

-}
init : Int -> String -> State
init howManyToShow query =
    State
        { autoState = Autocomplete.empty
        , showMenu = False
        , query = UserInput query
        , isFocused = False
        , howManyToShow = howManyToShow
        , debounce = Debounce.initialState
        }


type Query
    = UserInput String
    | PreviewInput String String
    | None



-- Update


{-| Opaque type that defines update operations
-}
type Msg
    = UpdateAutocomplete Autocomplete.Msg
    | SetText String
    | InputChanged String
    | ResetMenu
    | Wrap Bool
    | Focused Bool
    | PreviewItem String
    | ShowMenu Bool
    | ItemSelected String
    | Deb (Debounce.Control Msg)
    | RefreshMenu


{-| Item to show in an autocomplete menu.
It is an extensible record so any record that contains the same fields can be used.
-}
type alias Item a =
    { a
        | id : Float
        , label : String
    }


simpleUpdateConfig : Autocomplete.UpdateConfig Msg (Item a)
simpleUpdateConfig =
    Autocomplete.updateConfig
        { toId = \item -> toString item.id
        , onKeyDown =
            \code maybeId ->
                if code == 38 || code == 40 then
                    Maybe.map PreviewItem maybeId
                else if code == 13 then
                    Maybe.map ItemSelected maybeId
                else
                    Just ResetMenu
        , onTooLow = Just <| Wrap False
        , onTooHigh = Just <| Wrap True
        , onMouseEnter = \id -> Just <| PreviewItem id
        , onMouseLeave = \_ -> Nothing
        , onMouseClick = \id -> Just <| ItemSelected id
        , separateSelections = False
        }


{-| An update method using a standard defined update configuration
-}
simpleUpdate : Msg -> List (Item a) -> State -> ( State, Cmd Msg )
simpleUpdate msg items state =
    updateWithConfig msg simpleUpdateConfig items state


{-| An update method using a specified update configuration
-}
updateWithConfig : Msg -> Autocomplete.UpdateConfig Msg (Item a) -> List (Item a) -> State -> ( State, Cmd Msg )
updateWithConfig msg config items (State state) =
    case msg of
        Wrap toTop ->
            let
                filteredItems =
                    matchingItems state.query items

                howManyToShow =
                    state.howManyToShow

                autoState =
                    state.autoState

                newAutoState =
                    if toTop then
                        Autocomplete.resetToLastItem
                            config
                            filteredItems
                            howManyToShow
                            autoState
                    else
                        Autocomplete.resetToFirstItem
                            config
                            filteredItems
                            howManyToShow
                            autoState

                text =
                    if toTop then
                        List.reverse filteredItems
                            |> List.head
                            |> Maybe.map .label
                            |> Maybe.withDefault ""
                    else
                        List.head filteredItems
                            |> Maybe.map .label
                            |> Maybe.withDefault ""

                query =
                    case state.query of
                        None ->
                            PreviewInput "" text

                        UserInput previous ->
                            PreviewInput previous text

                        PreviewInput previous _ ->
                            PreviewInput previous text
            in
            State { state | autoState = newAutoState, query = query }
                => Cmd.none
                |> updateIfFocused state

        ResetMenu ->
            State { state | autoState = Autocomplete.reset config state.autoState }
                => Cmd.none
                |> updateIfFocused state

        ItemSelected itemId ->
            case getLabelById itemId items of
                Result.Ok text ->
                    State { state | query = UserInput text }
                        => Cmd.none
                        |> updateIfFocused state

                Result.Err e ->
                    Debug.log e (State state => Cmd.none)

        PreviewItem itemId ->
            case getLabelById itemId items of
                Result.Ok text ->
                    let
                        query =
                            case state.query of
                                None ->
                                    PreviewInput "" text

                                UserInput previous ->
                                    PreviewInput previous text

                                PreviewInput previous _ ->
                                    PreviewInput previous text
                    in
                    State { state | query = query }
                        => Cmd.none
                        |> updateIfFocused state

                Result.Err e ->
                    Debug.log e (State state => Cmd.none)

        UpdateAutocomplete autoMsg ->
            if state.isFocused then
                let
                    ( autoState, nextAutoMsg ) =
                        Autocomplete.update
                            config
                            autoMsg
                            state.howManyToShow
                            state.autoState
                            (matchingItems state.query items)

                    newState =
                        State { state | autoState = autoState }
                in
                case nextAutoMsg of
                    Nothing ->
                        newState
                            => Cmd.none

                    Just updateMsg ->
                        newState
                            => Task.perform (\_ -> updateMsg) (Task.succeed ())
            else
                State state => Cmd.none

        SetText value ->
            State { state | query = UserInput value }
                => Cmd.none

        InputChanged value ->
            let
                query =
                    case state.query of
                        UserInput _ ->
                            UserInput value

                        None ->
                            UserInput value

                        PreviewInput text previewText ->
                            if previewText == value then
                                PreviewInput text previewText
                            else
                                UserInput value

                autocompleteResults =
                    matchingItems query items
            in
            State { state | query = query, showMenu = shouldShowMenu query items, isFocused = True }
                => Cmd.none

        Focused focused ->
            let
                showMenu =
                    if focused then
                        shouldShowMenu state.query items
                    else
                        False

                delay =
                    if focused then
                        0
                    else
                        0.3 * Time.second

                cmd =
                    Process.sleep delay
                        |> Task.perform (\_ -> ShowMenu showMenu)
            in
            State state
                => cmd

        ShowMenu show ->
            let
                query =
                    case state.query of
                        PreviewInput text previewText ->
                            UserInput text

                        _ ->
                            state.query
            in
            State { state | showMenu = show, query = query, isFocused = show }
                => Cmd.none

        Deb debMsg ->
            Debounce.update (\s -> State { state | debounce = s }) state.debounce debMsg

        RefreshMenu ->
            State { state | showMenu = state.isFocused && shouldShowMenu state.query items }
                => Cmd.none


updateIfFocused : AutoState -> ( State, Cmd msg ) -> ( State, Cmd msg )
updateIfFocused originalState newState =
    if originalState.isFocused then
        newState
    else
        State originalState
            => Cmd.none


getLabelById : String -> List (Item a) -> Result String String
getLabelById id items =
    String.toFloat id
        |> Result.andThen
            (\id ->
                ListExtra.firstMatch (\item -> item.id == id) items
                    |> Result.fromMaybe "couldn't find selected item"
                    |> Result.map .label
            )


shouldShowMenu : Query -> List (Item a) -> Bool
shouldShowMenu query items =
    matchingItems query items
        |> List.isEmpty
        |> not


matchingItems : Query -> List (Item a) -> List (Item a)
matchingItems query availableItems =
    let
        filterText =
            case query of
                UserInput text ->
                    text

                None ->
                    ""

                PreviewInput text _ ->
                    text

        lowerQuery =
            String.trim (String.toLower filterText)

        queryPattern =
            let
                parts =
                    String.words lowerQuery

                joined =
                    String.join "(.{0,})" parts
            in
            joined ++ "(.{0,})"

        filteredList =
            List.filter
                (\item ->
                    item.label
                        /= ""
                        && (item.label /= String.trim filterText)
                        && Regex.contains (Regex.regex queryPattern) (String.toLower item.label)
                )
                availableItems
    in
    if String.isEmpty lowerQuery then
        List.filter (\item -> not (String.isEmpty item.label)) availableItems
    else
        filteredList



-- View


{-| Configuration for a view. Requires an elm-autocomplete view config
-}
type alias ViewConfig a msg =
    { menuConfig : Autocomplete.ViewConfig (Item a)
    , options : List (Input.Option msg)
    , tagger : Msg -> msg
    }


{-| Render an autocomplete state with a standard view configuration
-}
simpleView : (Msg -> msg) -> List (Item a) -> State -> Html msg
simpleView tagger items state =
    let
        config =
            { menuConfig = simpleMenuViewConfig
            , options = [ Input.small ]
            , tagger = tagger
            }
    in
    viewWithConfig config items state


{-| Render an autocomplete state with a specified view configuration
-}
viewWithConfig : ViewConfig a msg -> List (Item a) -> State -> Html msg
viewWithConfig config items state =
    case splitView config items state of
        ( inputField, Nothing ) ->
            Html.div [] [ inputField ]

        ( inputField, Just menu ) ->
            Html.div [] [ inputField, menu ]


{-| Render an autocomplete state with the menu and input field separate for different combinations.

    ( inputView, autocompleteMenu ) =
        splitView config items state

-}
splitView : ViewConfig a msg -> List (Item a) -> State -> ( Html msg, Maybe (Html msg) )
splitView config items (State state) =
    let
        textValue =
            case state.query of
                UserInput text ->
                    text

                None ->
                    ""

                PreviewInput _ previewText ->
                    previewText

        inputField =
            inputView config.tagger config.options textValue
    in
    if not state.showMenu then
        ( inputField, Nothing )
    else
        let
            filteredItems =
                matchingItems state.query items

            autocompleteMenu =
                Html.div [ Attrs.class "autocomplete-menu" ]
                    [ Html.map (config.tagger << UpdateAutocomplete)
                        (Autocomplete.view config.menuConfig state.howManyToShow state.autoState filteredItems)
                    ]
        in
        ( inputField, Just autocompleteMenu )


inputView : (Msg -> msg) -> List (Input.Option msg) -> String -> Html msg
inputView tagger options text =
    Input.text <|
        List.concat
            [ options
            , [ Input.onInput (tagger << InputChanged)
              , Input.value text
              , Input.attrs
                    [ Html.Events.onFocus (tagger <| debounce 0.3 <| Focused True)
                    , Html.Events.onWithOptions "blur" { stopPropagation = True, preventDefault = True } (Json.Decode.succeed (tagger <| debounce 0.3 <| Focused False))
                    ]
              ]
            ]


debounce : Time.Time -> Msg -> Msg
debounce seconds =
    Control.Debounce.trailing Deb (seconds * Time.second)


{-| Simple menu view config that renders a text view of each item's label
-}
simpleMenuViewConfig : Autocomplete.ViewConfig (Item a)
simpleMenuViewConfig =
    Autocomplete.viewConfig
        { toId = \item -> toString item.id
        , ul = [ Attrs.class "autocomplete-list" ]
        , li =
            \keySelected mouseSelected item ->
                { attributes =
                    [ Attrs.classList
                        [ ( "autocomplete-item", True )
                        , ( "bg-info text-white", keySelected || mouseSelected )
                        ]
                    ]
                , children = [ Html.text item.label ]
                }
        }



-- Subscription


type alias KeyboardEvents =
    Autocomplete.Msg


{-| Subscribe to keyboard events. Provide a function to delegate the Msg update.
-}
subscription : (Msg -> msg) -> Sub msg
subscription tagger =
    Sub.map (tagger << UpdateAutocomplete) Autocomplete.subscription
