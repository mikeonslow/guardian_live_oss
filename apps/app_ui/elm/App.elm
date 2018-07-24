module App exposing (main)

import Autocomplete
import Bootstrap.Accordion as Accordion
import Bootstrap.Modal as Modal
import Bootstrap.Navbar as Navbar
import Common.Connection as Connection
import Common.LocalDebug as LocalDebug
import Data.Alert as Alert exposing (Alert)
import Data.AuthToken as AuthToken exposing (AuthToken)
import Data.File
import Data.Loader as Loader
import Data.LocalStorageChange as StorageChange
import Data.Session as Session exposing (Session)
import Data.User as User exposing (User, Username)
import Data.UserPhoto as UserPhoto exposing (UserPhoto)
import Date exposing (Date)
import DatePicker exposing (DateEvent(..), defaultSettings)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes
import Html.Events
import Http
import Json.Decode as Decode exposing (Value)
import Json.Encode as JE
import Navigation exposing (Location)
import Page.Administration.Security as AdministrationSecurity
import Page.Demo.Form as DemoForm
import Page.Errored as Errored exposing (PageLoadError)
import Page.Link as LinkPage
import Page.Login as Login
import Page.Main as Main
import Page.NotFound as NotFound
import Page.PermissionError as PermissionError exposing (..)
import Phoenix
import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Socket as Socket exposing (Socket)
import Ports
import Process
import Random
import Request.LocalStorage
import Request.Window
import Route exposing (Route)
import Task
import Time exposing (Time)
import Time.Date as TimeDate exposing (date)
import Types exposing (Config, Msg(..))
import Util exposing ((=>))
import Views.Alert
import Views.Autocomplete
import Views.LoaderTop as LoaderTop
import Views.Modal as PageModal
import Views.NavigationTop as NavigationTop
import Views.Page as Page exposing (ActivePage)
import Window


type Page
    = Main Main.Model
    | Link LinkPage.Model
    | Login Login.Model
    | AdministrationSecurity AdministrationSecurity.Model
    | Errored PageLoadError
    | PermissionError PermissionErrorModel
    | Blank
    | NotFound


type PageState
    = Loaded Page
    | TransitioningFrom Page



-- MODEL --


type alias Model =
    { session : Session
    , pageState : PageState
    , globalState : GlobalState
    }


type alias GlobalState =
    { connected : Bool
    , loaderStatus : Maybe Loader.Role
    , currentDatetime : Maybe Date
    , alert : Maybe Alert
    , debugLevel : LocalDebug.Level
    , windowSize : Window.Size
    , lastRoute : Maybe Route
    }


init : Config -> Location -> ( Model, Cmd Msg )
init { userData, currentTimestamp } location =
    let
        user =
            decodeUserFromJson userData

        (AuthToken.AuthToken authToken) =
            getAuthToken { session = { user = user } }

        hasToken =
            if String.length authToken > 0 then
                True
            else
                False

        ( navbarState, navbarCmd ) =
            Navbar.initialState NavbarMsg

        ( routeState, routeCmd ) =
            setRoute (Route.fromLocation location)
                { pageState = Loaded initialPage
                , session = { user = user, navbarState = navbarState }
                , globalState =
                    { connected = hasToken
                    , loaderStatus = Nothing
                    , currentDatetime = Just (Date.fromTime currentTimestamp)
                    , alert = Nothing
                    , debugLevel = LocalDebug.Production
                    , windowSize = { height = 1920, width = 1080 }
                    , lastRoute = Nothing
                    }
                }

        cmds =
            if hasToken then
                windowSize :: navbarCmd :: [ routeCmd, Task.perform GetCurrentDateTime Date.now ]
            else
                windowSize :: navbarCmd :: [ Navigation.newUrl "#login", Task.perform GetCurrentDateTime Date.now ]
    in
        ( routeState, Cmd.batch cmds )


initialPage : Page
initialPage =
    Main Main.initialModel


windowSize : Cmd Msg
windowSize =
    Task.perform WindowSize Window.size


decodeUserFromJson : Value -> Maybe User
decodeUserFromJson json =
    json
        |> Decode.decodeValue Decode.string
        |> Result.toMaybe
        |> Maybe.andThen (Decode.decodeString User.decoder >> Result.toMaybe)


decodeTokenFromJson : Value -> Maybe AuthToken
decodeTokenFromJson json =
    json
        |> Decode.decodeValue Decode.string
        |> Result.toMaybe
        |> Maybe.andThen (Decode.decodeString AuthToken.decoder >> Result.toMaybe)


pageWithoutNavbar : PageInputs -> Html Msg
pageWithoutNavbar page =
    div [ Html.Attributes.class "page-frame" ]
        [ loader page
        , page.content
        ]


screenPopsPage : PageInputs -> Html Msg
screenPopsPage page =
    div [ Html.Attributes.class "page-frame gray-background", Html.Attributes.style [ ( "height", "100vh" ) ] ]
        [ loader page
        , page.content
        ]


navbarPage : PageInputs -> Html Msg
navbarPage page =
    div [ Html.Attributes.class "page-frame" ]
        [ loader page
        , navbar page.session
        , page.content
        ]


navbar : Session -> Html Msg
navbar session =
    NavigationTop.view session


loader : PageInputs -> Html Msg
loader page =
    LoaderTop.view page



-- VIEW --


view : Model -> Html Msg
view model =
    case model.pageState of
        Loaded page ->
            viewPage model.globalState model.session False page

        TransitioningFrom page ->
            viewPage model.globalState model.session True page


viewPage : GlobalState -> Session -> Bool -> Page -> Html Msg
viewPage globalState session isLoading page =
    let
        frame =
            Page.frame isLoading session session.user

        content =
            case page of
                NotFound ->
                    NotFound.view session
                        |> frame Page.Other

                Main subModel ->
                    Main.view session
                        |> frame Page.Other
                        |> Html.map MainMsg

                Link subModel ->
                    LinkPage.view subModel
                        |> frame Page.Other
                        |> Html.map LinkMsg

                Blank ->
                    Html.text ""
                        |> frame Page.Other

                Errored subModel ->
                    Errored.view session subModel
                        |> frame Page.Other

                PermissionError subModel ->
                    PermissionError.view session subModel
                        |> frame Page.Other

                Login subModel ->
                    Login.view subModel
                        |> frame Page.Other
                        |> Html.map LoginMsg

                AdministrationSecurity subModel ->
                    AdministrationSecurity.view subModel
                        |> frame Page.Other
                        |> Html.map AdministrationSecurityMsg

        pageInputs =
            PageInputs globalState session content

        pageWithWrapper =
            case ( session.user, page ) of
                ( Just user, Login _ ) ->
                    pageWithoutNavbar pageInputs

                ( Just user, _ ) ->
                    navbarPage pageInputs

                ( Nothing, _ ) ->
                    pageWithoutNavbar pageInputs

        pageWithAlertWrapper =
            case globalState.alert of
                Nothing ->
                    pageWithWrapper

                Just alertType ->
                    div []
                        [ pageWithWrapper
                        , div
                            [ Html.Attributes.class "toast-container" ]
                            [ Views.Alert.view alertType ]
                        ]
    in
        pageWithAlertWrapper


type alias PageInputs =
    { globalState : GlobalState
    , session : Session
    , content : Html Msg
    }



-- Phoenix


initPhxLogin : Model -> Socket Msg
initPhxLogin model =
    let
        loginData =
            case model.pageState of
                Loaded (Login data) ->
                    data

                _ ->
                    Login.initialModel

        guardianToken =
            getGuardianToken model

        auth =
            if String.length guardianToken > 0 then
                [ ( "jwt", guardianToken ) ]
            else
                [ ( "username", loginData.username )
                , ( "password", Http.encodeUri loginData.password )
                ]
    in
        Socket.init Connection.socketUrl
            |> Socket.withDebug
            |> Socket.withParams
                (List.concat [ auth ])
            |> Socket.onAbnormalClose SocketClosedAbnormally


channels username =
    Channel.init ("login:" ++ username)
        |> Channel.withPayload (JE.object [ ( "username", JE.string username ) ])
        |> Channel.on "user:guardian_token" receiveLoginMsg
        |> Channel.on "login:unauthorized" receiveUnauthorizedMsg



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        username =
            User.getUsername model.session.user

        token =
            getGuardianToken model

        -- TODO refactor to type
        auth =
            { username = username
            , token = token
            }

        channelAuth =
            ChannelAuth (User.getUsername model.session.user) (getGuardianToken model)
    in
        Sub.batch
            (List.concat
                [ pageSubscriptions auth (getPage model.pageState)
                , phoenixSubscriptions model
                , portSubscriptions
                , navbarSubscriptions model
                , [ Window.resizes WindowSize ]
                , [ Sub.map LocalStorageChanged localStorageChangeSub ]
                ]
            )


localStorageChangeSub : Sub (Result String StorageChange.Change)
localStorageChangeSub =
    Ports.localStorageChanged (Decode.decodeValue StorageChange.decoder)


getPage : PageState -> Page
getPage pageState =
    case pageState of
        Loaded page ->
            page

        TransitioningFrom page ->
            page


type alias ChannelAuth =
    { username : String
    , token : String
    }


pageSubscriptions : ChannelAuth -> Page -> List (Sub Msg)
pageSubscriptions auth page =
    let
        subs =
            case page of
                Main _ ->
                    Sub.none

                Link _ ->
                    Sub.none

                AdministrationSecurity _ ->
                    Sub.none

                Blank ->
                    Sub.none

                Errored _ ->
                    Sub.none

                PermissionError _ ->
                    Sub.none

                NotFound ->
                    Sub.none

                Login _ ->
                    Sub.none
    in
        [ subs ]


phoenixSubscriptions model =
    let
        username =
            User.getUsername model.session.user

        token =
            getGuardianToken model

        -- TODO refactor to type
        auth =
            { username = username
            , token = token
            }

        channelList =
            let
                pageChannels =
                    (case model.pageState of
                        Loaded (AdministrationSecurity rest) ->
                            [ AdministrationSecurity.channels auth
                                { onAppPermissionsSet = receiveAppPermissionSets
                                , onAppRoles = receiveAppRoles
                                }
                            ]

                        _ ->
                            let
                                x =
                                    Debug.log "UNHANDLED CHANNELS FOR PAGE: " model.pageState
                            in
                                []
                    )
                        |> List.map
                            (\channel ->
                                channel
                                    |> Channel.onJoinError ChannelJoinError
                            )
            in
                if String.length username > 0 && String.length token > 0 then
                    List.concat
                        [ [ channels username ]
                        , List.concat [ pageChannels ]
                        ]
                else
                    [ channels username ]
    in
        if model.globalState.connected then
            [ Phoenix.connect
                (initPhxLogin model)
                channelList
            ]
        else
            []


portSubscriptions =
    [ Ports.sendUsernameCache receiveUsernameCache
    , Ports.sendSecurityToken receiveToken
    ]


navbarSubscriptions model =
    [ Navbar.subscriptions model.session.navbarState NavbarMsg ]



-- INBOUND RECEIVERS


receiveLoginMsg subMsg =
    LoginMsg
        (Login.ReceiveLoginMessage
            subMsg
        )


receiveLogoutMsg subMsg =
    LoginMsg
        (Login.ReceiveLoginMessage
            subMsg
        )


receiveUnauthorizedMsg subMsg =
    LoginMsg
        (Login.ReceiveUnauthorizedMessage
            subMsg
        )


receiveUsernameCache cacheData =
    LoginMsg
        (Login.GetCachedUsername
            cacheData
        )


receiveToken guardian_token =
    LoginMsg
        (Login.GetSecurityToken
            guardian_token
        )


receiveAppRoles appRoles =
    AdministrationSecurityMsg
        (AdministrationSecurity.ReceiveAppRoles appRoles)


receiveAppPermissionSets appPermissionsSet =
    AdministrationSecurityMsg
        (AdministrationSecurity.ReceiveAppPermissionSets appPermissionsSet)


receiveAppPermissionSetsAccordion accordionState =
    AdministrationSecurityMsg
        (AdministrationSecurity.AccordionMsg accordionState)



-- UPDATE --


setRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
setRoute maybeRoute currentModel =
    let
        transition toMsg task =
            { currentModel | pageState = TransitioningFrom (getPage currentModel.pageState) }
                => Task.attempt toMsg task

        errored =
            pageErrored currentModel

        currentValidRoute =
            getRoute currentModel

        currentGlobalState =
            currentModel.globalState

        updatedGlobalState =
            { currentGlobalState
                | lastRoute = Just currentValidRoute
            }

        model =
            { currentModel | globalState = updatedGlobalState }
    in
        case maybeRoute of
            Nothing ->
                { model | pageState = Loaded NotFound } => Cmd.none

            Just Route.Main ->
                { model | pageState = Loaded (Main Main.initialModel) }
                    => Cmd.none

            Just (Route.Link path) ->
                let
                    user =
                        model.session.user

                    ( newPage, newCmd ) =
                        LinkPage.init user path
                in
                    { model | pageState = Loaded (Link newPage) } => Cmd.map LinkMsg newCmd

            Just Route.AdministrationSecurity ->
                let
                    ( newPage, newCmd ) =
                        AdministrationSecurity.init model.session.user
                in
                    { model | pageState = Loaded (AdministrationSecurity newPage) }
                        => Cmd.map AdministrationSecurityMsg newCmd

            Just Route.Login ->
                let
                    newModel =
                        model
                            |> setConnectionStatus False
                            |> clearUser
                in
                    { newModel | pageState = Loaded (Login Login.initialModel) }
                        => Cmd.batch
                            [ Ports.getUsernameCache ""
                            , Ports.clearSecurityToken ""
                            , Ports.clearUserCache ""
                            ]

            Just Route.Logout ->
                let
                    session =
                        model.session

                    newModel =
                        model
                in
                    { model | session = { session | user = Nothing } }
                        => Cmd.batch
                            [ Route.modifyUrl Route.Login
                            ]


getRoute : Model -> Route
getRoute model =
    case model.pageState of
        Loaded (Main md) ->
            Route.Main

        Loaded (Login md) ->
            Route.Login

        Loaded (AdministrationSecurity md) ->
            Route.AdministrationSecurity

        _ ->
            Route.Main


pageErrored : Model -> ActivePage -> String -> ( Model, Cmd msg )
pageErrored model activePage errorMessage =
    let
        error =
            Errored.pageLoadError activePage errorMessage
    in
        { model | pageState = Loaded (Errored error) } => Cmd.none


permissionErrored : Model -> ( Model, Cmd msg )
permissionErrored model =
    let
        currentRoute =
            Maybe.withDefault Route.Main
                model.globalState.lastRoute

        error =
            PermissionError.permissionError currentRoute
    in
        { model | pageState = Loaded (PermissionError error) } => Cmd.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetCurrentDateTime dateTime ->
            let
                currentGlobalState =
                    model.globalState

                updatedGlobalState =
                    { currentGlobalState | currentDatetime = Just dateTime }
            in
                { model | globalState = updatedGlobalState } => Cmd.none

        NavbarMsg state ->
            updateNavbar state model

        WindowSize size ->
            let
                currentGlobalState =
                    model.globalState

                updatedGlobalState =
                    { currentGlobalState | windowSize = size }
            in
                { model | globalState = updatedGlobalState } => Cmd.none

        SocketClosedAbnormally ->
            model => Cmd.none

        ShowAlert id alertType ->
            let
                time =
                    10 * Time.second

                alertDissmissCmd =
                    Process.sleep time
                        |> Task.perform (\_ -> HideAlert id)
            in
                { model | globalState = updateAlert model.globalState (Just <| Alert id alertType) }
                    => alertDissmissCmd

        HideAlert id ->
            let
                alert =
                    Maybe.andThen
                        (\alert ->
                            if id == alert.id then
                                Nothing
                            else
                                Just alert
                        )
                        model.globalState.alert
            in
                { model | globalState = updateAlert model.globalState alert }
                    => Cmd.none

        QueueAlert alertType ->
            let
                showAlert =
                    Random.generate (\newId -> ShowAlert newId alertType) (Random.int Random.minInt Random.maxInt)

                postDelayed =
                    Process.sleep (0.5 * Time.second)
                        |> Task.perform (\_ -> QueueAlert alertType)

                ( newModel, alertCommands ) =
                    case model.globalState.alert of
                        Nothing ->
                            model => showAlert

                        Just { id } ->
                            update (HideAlert id) model
                                |> Tuple.first
                                => postDelayed
            in
                newModel => alertCommands

        LoginMsg (Login.ReceiveUnauthorizedMessage _) ->
            case model.pageState of
                Loaded ((Login loginModel) as page) ->
                    updatePage page msg model

                _ ->
                    model => Navigation.modifyUrl "#logout"

        LocalStorageChanged (Ok change) ->
            model => Cmd.none

        LocalStorageChanged (Err error) ->
            model => Cmd.none

        ChannelJoinError val ->
            permissionErrored model

        _ ->
            updatePage (getPage model.pageState) msg model


updateAlert : GlobalState -> Maybe Alert -> GlobalState
updateAlert state alert =
    { state | alert = alert }


updateNavbar state model =
    let
        session =
            model.session

        newSession =
            { session | navbarState = state }

        newModel =
            { model | session = newSession }
    in
        newModel => Cmd.none


updatePage : Page -> Msg -> Model -> ( Model, Cmd Msg )
updatePage page msg model =
    let
        session =
            model.session

        toPage toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd ) =
                    subUpdate subMsg subModel
            in
                ( { model | pageState = Loaded (toModel newModel) }, Cmd.map toMsg newCmd )

        errored =
            pageErrored model
    in
        case ( msg, page ) of
            ( SetRoute route, _ ) ->
                setRoute route model

            ( LinkMsg subMsg, Link subModel ) ->
                let
                    ( ( pageModel, cmd ), msgFromPage ) =
                        LinkPage.update subMsg subModel

                    ( newModel, newCmds ) =
                        model => Cmd.none
                in
                    { model | pageState = Loaded (Link pageModel) }
                        => Cmd.batch
                            [ Cmd.map LinkMsg cmd, newCmds ]

            ( LoginMsg subMsg, Login subModel ) ->
                let
                    ( ( pageModel, cmd ), msgFromPage ) =
                        Login.update subMsg subModel

                    newModel =
                        case msgFromPage of
                            Login.NoOp ->
                                model

                            Login.SetSocketConnect enabled ->
                                let
                                    globalState =
                                        model.globalState
                                in
                                    { model
                                        | globalState =
                                            { globalState
                                                | connected = enabled
                                                , loaderStatus = Just Loader.Info
                                                , currentDatetime = model.globalState.currentDatetime
                                                , alert = model.globalState.alert
                                                , debugLevel = model.globalState.debugLevel
                                                , windowSize = model.globalState.windowSize
                                            }
                                    }

                            Login.Unauthorized ->
                                let
                                    globalState =
                                        model.globalState
                                in
                                    { model
                                        | globalState =
                                            { globalState
                                                | connected = False
                                                , loaderStatus = Just Loader.Error
                                                , currentDatetime = model.globalState.currentDatetime
                                                , alert = model.globalState.alert
                                                , debugLevel = model.globalState.debugLevel
                                                , windowSize = model.globalState.windowSize
                                            }
                                    }

                            Login.InitUserData userData ->
                                let
                                    session =
                                        model.session

                                    globalState =
                                        model.globalState

                                    newSession =
                                        { session | user = Just userData }

                                    newGlobalState =
                                        { globalState | loaderStatus = Nothing }
                                in
                                    model
                                        |> (\m -> { m | session = newSession })
                                        |> (\m -> { m | globalState = newGlobalState })
                in
                    { newModel | pageState = Loaded (Login pageModel) }
                        => Cmd.batch
                            [ Cmd.map LoginMsg cmd ]

            ( AdministrationSecurityMsg subMsg, AdministrationSecurity subModel ) ->
                let
                    ( ( pageModel, cmd ), msgFromPage ) =
                        AdministrationSecurity.update subMsg subModel
                in
                    { model | pageState = Loaded (AdministrationSecurity pageModel) }
                        => Cmd.batch
                            [ Cmd.map AdministrationSecurityMsg cmd ]

            ( _, NotFound ) ->
                -- Disregard incoming messages when we're on the
                -- NotFound page.
                model => Cmd.none

            ( state, _ ) ->
                -- Disregard incoming messages that arrived for the wrong page
                model => Cmd.none



-- HELPERS


getGuardianToken model =
    case model.session.user of
        Nothing ->
            ""

        Just user ->
            AuthToken.authTokenToString user.guardian_token


getAuthToken model =
    case model.session.user of
        Nothing ->
            AuthToken.AuthToken ""

        Just user ->
            user.guardian_token


setConnectionStatus enabled model =
    let
        globalState =
            model.globalState

        newModel =
            { model | globalState = { globalState | connected = enabled } }
    in
        newModel


clearUser model =
    let
        session =
            model.session

        newModel =
            { model | session = { session | user = Nothing } }
    in
        newModel



-- MAIN --


main : Program Config Model Msg
main =
    Navigation.programWithFlags (Route.fromLocation >> SetRoute)
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
