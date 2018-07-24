module Common.Layout.Accordion
    exposing
        ( Block
        , Card
        , Config
        , Data
        , Header
        , Id
        , Msg(..)
        , Toggle
        , block
        , card
        , cards
        , config
        , header
        , init
        , toggle
        , update
        , view
        )

import Dict exposing (Dict)
import Html exposing (Attribute, Html)
import Html.Attributes as Attrs
import Html.Events
import Json.Decode
import Set exposing (Set)
import Util


-- State


type Data
    = Data State


type alias State =
    { cards : Dict Id CardData
    }


init : List Id -> Data
init openCardIds =
    let
        cards =
            List.map (\id -> ( id, CardData True )) openCardIds
                |> Dict.fromList
    in
    Data { cards = cards }


type alias CardData =
    { open : Bool
    }


type alias Id =
    String


type Msg
    = ToggleOpen Id
    | Open (Set Id)
    | Close (Set Id)



-- Update


update : Msg -> Data -> Data
update msg (Data state) =
    case msg of
        ToggleOpen id ->
            Data { state | cards = updateOrDefault id (\i -> { i | open = not i.open }) state.cards }

        Open ids ->
            updateCards (updateOpen True) ids state

        Close ids ->
            updateCards (updateOpen False) ids state


updateOrDefault : Id -> (CardData -> CardData) -> Dict Id CardData -> Dict Id CardData
updateOrDefault id updater =
    Dict.update id
        (\value ->
            case value of
                Nothing ->
                    { open = False }
                        |> updater
                        |> Just

                Just v ->
                    Just <| updater v
        )


updateOpen : Bool -> { a | open : Bool } -> { a | open : Bool }
updateOpen open item =
    { item | open = open }


updateCards : (CardData -> CardData) -> Set Id -> State -> Data
updateCards updater ids state =
    Data { state | cards = Set.foldl (\id acc -> updateOrDefault id updater acc) state.cards ids }



-- View


type Config msg
    = Config
        { toMsg : Msg -> msg
        , cards : List (Card msg)
        }


type Card msg
    = Card
        { id : Id
        , header : Header msg
        , blocks : List (Block msg)
        }


config : (Msg -> msg) -> Config msg
config toMsg =
    Config
        { toMsg = toMsg
        , cards = []
        }


view : Data -> Config msg -> Html msg
view (Data state) ((Config { cards }) as config) =
    Html.div [ Attrs.class "accordion" ] (List.map (renderCard state config) cards)


renderCard : State -> Config msg -> Card msg -> Html msg
renderCard state config ((Card { id, blocks }) as card) =
    let
        collapsedAttrs =
            [ Attrs.class "collapsed", Attrs.style [ ( "height", "0px" ), ( "overflow", "hidden" ) ] ]

        isCollapsed =
            Dict.get id state.cards
                |> Maybe.map
                    (\card ->
                        if card.open then
                            []
                        else
                            collapsedAttrs
                    )
                |> Maybe.withDefault collapsedAttrs
    in
    Html.div
        [ Attrs.class "card" ]
        [ renderHeader config card
        , Html.div ([ Attrs.id id ] ++ isCollapsed) (List.map renderBlock blocks)
        ]


cards : List (Card msg) -> Config msg -> Config msg
cards cards (Config config) =
    Config { config | cards = cards }


card :
    { id : String
    , blocks : List (Block msg)
    , header : Header msg
    }
    -> Card msg
card { id, header, blocks } =
    Card
        { id = id
        , header = header
        , blocks = blocks
        }



-- Header


type Header msg
    = Header
        { attributes : List (Attribute msg)
        , toggle : Toggle msg
        }


type Toggle msg
    = Toggle
        { attributes : List (Attribute msg)
        , children : List (Html msg)
        }


toggle : List (Attribute msg) -> List (Html msg) -> Toggle msg
toggle attrs children =
    Toggle { attributes = attrs, children = children }


header : List (Attribute msg) -> Toggle msg -> Header msg
header attrs toggle =
    Header
        { attributes = attrs
        , toggle = toggle
        }


renderHeader : Config msg -> Card msg -> Html msg
renderHeader ((Config { toMsg }) as config) ((Card { id, header }) as card) =
    let
        (Header { attributes, toggle }) =
            header

        combinedAttributes =
            [ Attrs.class "card-header"
            , Html.Events.onClick (toMsg (ToggleOpen id))
            ]
                ++ attributes
    in
    Html.div
        combinedAttributes
        [ renderToggle config card ]


renderToggle : Config msg -> Card msg -> Html msg
renderToggle (Config { toMsg }) (Card { id, header }) =
    let
        (Header { toggle }) =
            header

        (Toggle { attributes, children }) =
            toggle

        clickHandler =
            Html.Events.onWithOptions
                "click"
                { stopPropagation = True
                , preventDefault = True
                }
                (Json.Decode.succeed <| toMsg (ToggleOpen id))

        combinedAttributes =
            [ Attrs.href ("#" ++ id), clickHandler ] ++ attributes
    in
    Html.a combinedAttributes children



-- Blocks


type Block msg
    = Block
        { attributes : List (Attribute msg)
        , children : List (Html msg)
        }


block : List (Attribute msg) -> List (Html msg) -> Block msg
block attrs children =
    Block { attributes = attrs, children = children }


renderBlock : Block msg -> Html msg
renderBlock (Block { attributes, children }) =
    let
        combinedAttributes =
            [ Attrs.class "card-block"
            ]
                ++ attributes
    in
    Html.div combinedAttributes children
