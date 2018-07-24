module Views.Tags exposing (Config, Msg(..), State, Tag, currentTags, init, update, view)

import Autocomplete
import Bootstrap.Form.Input as Input
import Common.Icons as Icon
import Common.Input exposing (onBackspaceEvent)
import Exts.List as ListExtra
import FontAwesome.Web as FA
import Html exposing (Html)
import Html.Attributes exposing (class, classList, style)
import Html.Events exposing (onClick, onFocus)
import Json.Decode
import Process
import Regex
import Task
import Time
import Util exposing ((=>))


type alias Tag a =
    { a
        | id : Float
        , label : String
        , default : Bool
    }


type alias Config =
    { itemsToShow : Int
    , uniqueId : String
    }


type alias State =
    { autoState : Autocomplete.State
    , showMenu : Bool
    , query : Query
    , tokenized : List Float
    , isFocused : Bool
    }


type Msg
    = TagSelected Bool String
    | TagRemoved Float
    | UpdateAutocomplete Autocomplete.Msg
    | InputChanged String
    | ResetMenu
    | WrapTag Bool
    | Focused Bool
    | PreviewTag String
    | Backspaced
    | ShowMenu Bool


type Query
    = UserInput String
    | PreviewInput String
    | None


init : List (Tag a) -> State
init tags =
    let
        defaultTokenized =
            List.map .id tags
    in
    { autoState = Autocomplete.empty
    , showMenu = False
    , query = None
    , tokenized = defaultTokenized
    , isFocused = False
    }


currentTags : State -> List Float
currentTags { tokenized } =
    tokenized


update : Msg -> Config -> List (Tag a) -> State -> ( State, Cmd Msg )
update msg config tags state =
    case msg of
        WrapTag toTop ->
            let
                filteredTags =
                    matchingTags state.query (unusedTags state.tokenized tags)

                howManyToShow =
                    config.itemsToShow

                autoState =
                    state.autoState

                newAutoState =
                    if toTop then
                        Autocomplete.resetToLastItem
                            updateConfig
                            filteredTags
                            howManyToShow
                            autoState
                    else
                        Autocomplete.resetToFirstItem
                            updateConfig
                            filteredTags
                            howManyToShow
                            autoState
            in
            if state.isFocused then
                { state | autoState = newAutoState }
                    => Cmd.none
            else
                state => Cmd.none

        ResetMenu ->
            { state | autoState = Autocomplete.reset updateConfig state.autoState }
                => Cmd.none

        TagSelected reset tagId ->
            let
                floatId =
                    String.toFloat tagId

                tokenized =
                    case floatId of
                        Result.Ok id ->
                            state.tokenized ++ [ id ]

                        Result.Err _ ->
                            state.tokenized
            in
            { state | tokenized = tokenized, query = None }
                => Cmd.none

        PreviewTag tagId ->
            case String.toFloat tagId of
                Result.Ok id ->
                    let
                        previewText =
                            ListExtra.firstMatch (\tag -> tag.id == id) tags
                                |> Maybe.map .label
                                |> Maybe.withDefault ""
                    in
                    { state | query = PreviewInput previewText }
                        => Cmd.none

                Result.Err _ ->
                    state => Cmd.none

        TagRemoved tagId ->
            { state | tokenized = List.filter (\id -> id /= tagId) state.tokenized }
                => Cmd.none

        UpdateAutocomplete autoMsg ->
            if state.isFocused then
                let
                    ( autoState, nextAutoMsg ) =
                        Autocomplete.update
                            updateConfig
                            autoMsg
                            config.itemsToShow
                            state.autoState
                            (matchingTags state.query (unusedTags state.tokenized tags))

                    newState =
                        { state | autoState = autoState }
                in
                case nextAutoMsg of
                    Nothing ->
                        newState => Cmd.none

                    Just updateMsg ->
                        update updateMsg config tags newState
            else
                state => Cmd.none

        InputChanged value ->
            let
                query =
                    case state.query of
                        UserInput _ ->
                            UserInput value

                        None ->
                            UserInput value

                        PreviewInput preview ->
                            if preview == value then
                                PreviewInput value
                            else
                                UserInput value

                autocompleteResults =
                    matchingTags query tags
            in
            { state | query = query, showMenu = shouldShowMenu query state.tokenized tags }
                => Cmd.none

        Focused focused ->
            let
                showMenu =
                    if focused then
                        shouldShowMenu state.query state.tokenized tags
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
            { state | isFocused = True }
                => cmd

        Backspaced ->
            let
                mostRecentTag =
                    List.reverse state.tokenized
                        |> List.head

                emptyInput =
                    case state.query of
                        None ->
                            True

                        UserInput text ->
                            String.isEmpty text

                        PreviewInput text ->
                            String.isEmpty text
            in
            if emptyInput then
                case mostRecentTag of
                    Nothing ->
                        state => Cmd.none

                    Just recentId ->
                        removeTag recentId state
                            => Cmd.none
            else
                state => Cmd.none

        ShowMenu show ->
            let
                query =
                    if not show then
                        None
                    else
                        state.query
            in
            { state | showMenu = show, query = query }
                => Cmd.none


removeTag : Float -> State -> State
removeTag tagId state =
    { state | tokenized = List.filter (\id -> id /= tagId) state.tokenized }


shouldShowMenu : Query -> List Float -> List (Tag a) -> Bool
shouldShowMenu query tokens tags =
    matchingTags query (unusedTags tokens tags)
        |> List.isEmpty
        |> not



-- View


view : Config -> List (Tag a) -> State -> Html Msg
view config tags state =
    let
        filteredTags =
            matchingTags state.query (unusedTags state.tokenized tags)

        autocompleteMenu =
            Html.map UpdateAutocomplete
                (Autocomplete.view viewConfig config.itemsToShow state.autoState filteredTags)

        textValue =
            case state.query of
                UserInput text ->
                    text

                None ->
                    ""

                PreviewInput text ->
                    text

        inputField =
            inputView config.uniqueId textValue

        tagViews =
            List.filterMap (\id -> ListExtra.firstMatch (\tag -> tag.id == id) tags) state.tokenized
                |> List.map tagView

        children =
            List.concat
                [ tagViews
                , [ inputField ]
                ]
    in
    Html.div []
        [ Html.div [ class "tags-input" ] children
        , Util.viewIf state.showMenu autocompleteMenu
        ]


tagView : Tag a -> Html Msg
tagView { id, label } =
    Html.span [ class "tag label label-info" ]
        [ Html.text label
        , Html.i [ onClick (TagRemoved id) ] [ Icon.actionIcon FA.times True Nothing ]
        ]


inputView : String -> String -> Html Msg
inputView uniqueId text =
    Html.span [ class "token-input" ]
        [ Input.text
            [ Input.small
            , Input.onInput InputChanged
            , Input.value text
            , Input.attrs
                [ onFocus (Focused True)
                , onBackspaceEvent Backspaced
                , Html.Events.onWithOptions "blur" { stopPropagation = False, preventDefault = True } (Json.Decode.succeed (Focused False))
                ]
            , Input.id uniqueId
            ]
        ]



-- Autocomplete


unusedTags : List Float -> List (Tag a) -> List (Tag a)
unusedTags tokens tags =
    List.filter (not << (\tag -> List.member tag.id tokens)) tags


matchingTags : Query -> List (Tag a) -> List (Tag a)
matchingTags query availableTags =
    let
        filterText =
            case query of
                UserInput text ->
                    text

                None ->
                    ""

                PreviewInput _ ->
                    ""

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
                (\tag ->
                    tag.label /= "" && Regex.contains (Regex.regex queryPattern) (String.toLower tag.label)
                )
                availableTags
    in
    if String.isEmpty lowerQuery then
        availableTags
    else
        filteredList


updateConfig : Autocomplete.UpdateConfig Msg (Tag a)
updateConfig =
    Autocomplete.updateConfig
        { toId = \tag -> toString tag.id
        , onKeyDown =
            \code maybeId ->
                if code == 13 || code == 40 then
                    Maybe.map (TagSelected False) maybeId
                else if code == 13 then
                    Maybe.map (TagSelected True) maybeId
                else
                    Just ResetMenu
        , onTooLow = Just <| WrapTag False
        , onTooHigh = Just <| WrapTag True
        , onMouseEnter = \id -> Just <| PreviewTag id
        , onMouseLeave = \_ -> Nothing
        , onMouseClick = \id -> Just <| TagSelected True id
        , separateSelections = False
        }


viewConfig : Autocomplete.ViewConfig (Tag a)
viewConfig =
    let
        customizedLi keySelected mouseSelected item =
            { attributes = [ classList [ ( "autocomplete-item", True ), ( "bg-info text-white", keySelected || mouseSelected ) ] ]
            , children = [ Html.text item.label ]
            }
    in
    Autocomplete.viewConfig
        { toId = \item -> toString item.id
        , ul = [ class "autocomplete-list" ]
        , li = customizedLi
        }
