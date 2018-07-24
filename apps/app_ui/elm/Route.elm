module Route exposing (Route(..), fromLocation, href, modifyUrl)

import Data.User as User exposing (Username)
import Html exposing (Attribute)
import Html.Attributes as Attr
import Navigation exposing (Location)
import UrlParser as Url exposing ((</>), (<?>), Parser, QueryParser, int, oneOf, parseHash, parsePath, s, string, stringParam, top)


-- ROUTING --


type Route
    = Main
    | Link String
    | Login
    | Logout
    | AdministrationSecurity

route : Parser (Route -> a) a
route =
    oneOf
        [ Url.map Main top
        , Url.map Link (s "link" </> string)
        , Url.map Login (s "login")
        , Url.map Logout (s "logout")
        , Url.map AdministrationSecurity (s "administration" </> s "security")
        ]

-- INTERNAL --


routeToString : Route -> String
routeToString page =
    let
        pieces =
            case page of
                Main ->
                    [ "" ]

                Link path ->
                    [ "link", path ]

                Login ->
                    [ "login" ]

                Logout ->
                    [ "logout" ]

                AdministrationSecurity ->
                    [ "administration", "security" ]

    in
    "#" ++ String.join "/" pieces



-- PUBLIC HELPERS --


href : Route -> Attribute msg
href route =
    Attr.href (routeToString route)


modifyUrl : Route -> Cmd msg
modifyUrl =
    routeToString >> Navigation.modifyUrl


fromLocation : Location -> Maybe Route
fromLocation location =
    let
        x =
            Debug.log "location" location
    in
    if String.isEmpty location.hash then
        Just Main
    else
        Debug.log "parsed hash" <| parseHash route location
