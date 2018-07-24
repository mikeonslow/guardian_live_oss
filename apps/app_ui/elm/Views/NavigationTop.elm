module Views.NavigationTop exposing (view)

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Modal as Modal
import Bootstrap.Navbar as Navbar
import Data.Session as Session exposing (Session)
import Data.User as User exposing (User, Username)
import Data.UserPhoto as UserPhoto exposing (UserPhoto)
import Exts.Html exposing (nbsp)
import FontAwesome.Web as FA
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput, targetValue)
import Route exposing (Route)
import Types exposing (Msg(..))


type alias Item =
    { id : String
    , label : String
    , link : String
    , icon : Html Msg
    , enabled : Bool
    , children : SubItem
    , clickAction : Maybe Msg
    }


type SubItem
    = SubItem (List Item)



--items : Session ->


items session =
    [ { id = "administration"
      , label = "Administration"
      , link = "administration"
      , icon = FA.bars
      , enabled = False
      , children =
            SubItem
                [ { id = "security"
                  , label = "Security"
                  , link = "administration/security"
                  , icon = FA.lock
                  , enabled = True
                  , children = SubItem []
                  , clickAction = Nothing
                  }
                ]
      , clickAction = Nothing
      }
    , { id = "myProfile"
      , label = "My Profile"
      , link = "myProfile"
      , icon = FA.user
      , enabled = False
      , children =
            SubItem []
      , clickAction = Nothing
      }
    , { id = "logout"
      , label = "Logout"
      , link = "logout"
      , icon = FA.key
      , enabled = True
      , children =
            SubItem []
      , clickAction = Nothing
      }
    ]


subItemToList : SubItem -> List Item
subItemToList (SubItem list) =
    list


getChildren : Item -> List Item
getChildren =
    .children >> subItemToList


view : Session -> Html Msg
view session =
    let
        navItems =
            items session

        filteredItems =
            navItems |> List.filter .enabled
    in
    Navbar.config NavbarMsg
        |> Navbar.withAnimation
        |> Navbar.primary
        |> Navbar.brand [ href "#" ]
            [ img [ src "images/if_lock_60740.png" ] []
            , text "My Awesomely Secured Application "
            ]
        |> Navbar.items
            (drawNavigationItems filteredItems True)
        |> Navbar.view session.navbarState


drawNavigationItems itemList top =
    let
        nodes =
            itemList
                |> List.map
                    (\item ->
                        case getChildren item of
                            [] ->
                                navbarItem item

                            children ->
                                navbarDropdownList item
                    )
    in
    nodes


navbarItem config =
    let
        buttonAttrs =
            case config.clickAction of
                Just clickAction ->
                    [ onClick clickAction ]

                Nothing ->
                    [ onClick NoOp, href ("#" ++ config.link) ]

        buttonElement =
            Navbar.itemLink buttonAttrs [ config.icon, text config.label ]
    in
    buttonElement


navbarDropdownList config =
    Navbar.dropdown
        { id = config.id
        , toggle = Navbar.dropdownToggle [] [ config.icon, text config.label ]
        , items =
            List.map navbarDropdownItem (getChildren config)
        }


navbarDropdownItem config =
    let
        buttonAttrs =
            case config.clickAction of
                Just clickAction ->
                    [ onClick clickAction ]

                Nothing ->
                    [ onClick NoOp, href ("#" ++ config.link) ]

        buttonElement =
            Navbar.dropdownItem buttonAttrs [ config.icon, text config.label ]
    in
    buttonElement
