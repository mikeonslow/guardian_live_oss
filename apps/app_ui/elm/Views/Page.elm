module Views.Page exposing (ActivePage(..), bodyId, frame)

{-| The frame around a typical page - that is, the header and footer.
-}

-- FONT AWESOME
-- EXTS

import Bootstrap.Grid as Grid
import Data.Session as Session exposing (Session)
import Data.User as User exposing (User, Username)
import FontAwesome.Web as FA
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Route exposing (Route)
import Types exposing (..)


type ActivePage
    = Other
    | Main
    | Login


frame : Bool -> Session -> Maybe User -> ActivePage -> Html msg -> Html msg
frame isLoading session user page content =
    div []
        [ Grid.containerFluid
            []
            [ content ]
        , Grid.containerFluid
            []
            [ text "" ]
        ]


viewHeader : ActivePage -> Maybe User -> Bool -> Html msg
viewHeader page user isLoading =
    nav [ class "navbar navbar-light" ]
        []


viewFooter =
    div [] [ text "Footer" ]


{-| This id comes from index.html.

The Feed uses it to scroll to the top of the page (by ID) when switching pages
in the pagination sense.

-}
bodyId : String
bodyId =
    "page-body"
