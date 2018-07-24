module Page.Login exposing (ExternalMsg(..), Model, Msg(..), initialModel, update, view)

import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Form as Form
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Input as Input
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Text as Text
import Common.Input exposing (onEnter)
import Data.AuthToken as AuthToken exposing (AuthToken)
import Data.User as User exposing (User, Username)
import Data.UserPhoto as UserPhoto exposing (UserPhoto)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput, targetValue)
import Json.Decode as Decode exposing (Value)
import Json.Decode.Pipeline as JDP exposing (decode, hardcoded, optional)
import Json.Encode as JE
import Navigation exposing (Location)
import Ports
import RemoteData exposing (..)
import Util exposing ((=>))


-- MODEL --


type alias Model =
    { errors : List Error
    , username : String
    , cacheUsername : Bool
    , password : String
    , pin : String
    , guardian_token : String
    }


type alias Error =
    ( String, String )



-- UPDATE


type FormInput
    = Username
    | CacheUsername
    | Password
    | Pin


type Msg
    = UpdateFormData FormInput String
    | ToggleCacheUsername
    | GetCachedUsername Ports.CacheData
    | GetSecurityToken Ports.GuardianToken
    | ReceiveLoginMessage Value
    | ReceiveUnauthorizedMessage Value
    | ReceiveLogoutMessage Value
    | JoinLogin


type ExternalMsg
    = NoOp
    | SetSocketConnect Bool
    | InitUserData User
    | Unauthorized


initialModel : Model
initialModel =
    { errors = []
    , username = ""
    , cacheUsername = False
    , password = ""
    , pin = ""
    , guardian_token = ""
    }


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        JoinLogin ->
            let
                cmds =
                    if model.cacheUsername == True then
                        Ports.setUsernameCache model.username
                    else
                        Cmd.none
            in
            model => cmds => SetSocketConnect True

        ReceiveLoginMessage raw ->
            case Decode.decodeValue User.decoder raw of
                Ok loginMessage ->
                    let
                        token =
                            AuthToken.authTokenToString loginMessage.guardian_token

                        newModel =
                            { model | guardian_token = token, password = "" }
                    in
                    newModel
                        => Cmd.batch
                            [ Ports.setSecurityToken token
                            , Ports.setUserCache
                                (User.encode loginMessage)
                            , Navigation.newUrl "#"
                            ]
                        => InitUserData loginMessage

                Err error ->
                    let
                        x =
                            Debug.log "Login.ReceiveLoginMessage Error" raw
                    in
                    model => Cmd.none => NoOp

        ReceiveUnauthorizedMessage raw ->
            case Decode.decodeValue User.decoder raw of
                Ok unauthorizedMessage ->
                    { model | errors = [ ( "Login Failed", "Username or password was incorrect" ) ] }
                        => Cmd.none
                        => NoOp

                Err error ->
                    let
                        x =
                            Debug.log "Login.ReceiveUnauthorizedMessage Error" raw
                    in
                    model => Cmd.none => Unauthorized

        ReceiveLogoutMessage raw ->
            model => Cmd.none => NoOp

        UpdateFormData field value ->
            let
                newModel =
                    updateField field value model
            in
            newModel => Cmd.none => NoOp

        ToggleCacheUsername ->
            let
                newModel =
                    updateField CacheUsername "" model

                cmds =
                    if newModel.cacheUsername then
                        Cmd.none
                    else
                        Ports.clearUsernameCache ""
            in
            newModel => cmds => NoOp

        GetCachedUsername cacheData ->
            { model | username = cacheData.username, cacheUsername = cacheData.cacheEnabled }
                => Cmd.none
                => NoOp

        GetSecurityToken data ->
            let
                ( newModel, cmds ) =
                    if String.length data.guardian_token > 0 then
                        ( { model
                            | guardian_token = data.guardian_token
                          }
                        , Navigation.newUrl "#"
                        )
                    else
                        ( model, Cmd.none )
            in
            newModel => Cmd.none => NoOp


updateField :
    FormInput
    -> String
    -> Model
    -> Model
updateField field value form =
    case field of
        Username ->
            { form | username = value }

        CacheUsername ->
            { form | cacheUsername = not form.cacheUsername }

        Password ->
            { form | password = value }

        Pin ->
            { form | pin = value }


decodeGuardianToken : Decode.Decoder Ports.GuardianToken
decodeGuardianToken =
    decode Ports.GuardianToken
        |> JDP.required "guardian_token" Decode.string



-- VIEW


view model =
    Grid.containerFluid
        [ class "loginContainer" ]
        [ Grid.row []
            [ Grid.col [ Col.xs4 ]
                []
            , Grid.col [ Col.xs4 ]
                [ viewCard False model ]
            , Grid.col [ Col.xs4 ]
                []
            ]
        , Grid.row []
            [ Grid.col [ Col.xs2 ]
                [ text "" ]
            ]
        ]


viewCard showLoader model =
    Card.config [ Card.attrs [ style [ ( "width", "23rem" ) ] ] ]
        |> Card.header [ class "text-center" ]
            [ img [ src "images/if_lock_60740.png", class "img-fluid" ] []
            ]
        |> viewCardMiddle showLoader model
        |> viewCardBottom showLoader model
        |> Card.view


viewCardMiddle showLoader model =
    let
        rememberUsernameChecked =
            if model.cacheUsername then
                checked True
            else
                checked False

        loginText =
            if showLoader then
                "Logging in..."
            else
                "Login"

        headerBlock =
            [ Card.titleH4 [] [ text loginText ] ]

        formBlock =
            if showLoader then
                []
            else
                [ Card.text []
                    [ viewCardForm model ]
                ]

        formBlock2 =
            if showLoader then
                [ Card.custom <|
                    viewCardLoading
                ]
            else
                [ Card.custom <|
                    Checkbox.checkbox
                        [ Checkbox.attrs
                            [ onClick ToggleCacheUsername, rememberUsernameChecked ]
                        ]
                        "Remember Username?"
                ]
    in
    Card.block []
        (List.concat
            [ headerBlock, formBlock, formBlock2 ]
        )


viewCardLoading =
    div [ style [ ( "text-align", "center" ) ] ]
        [ i [ class "fa fa-spinner fa-pulse fa-3x fa-fw" ]
            []
        , span [ class "sr-only" ]
            [ text "Loading..." ]
        ]


viewCardBottom showLoader model =
    let
        loginDisabled =
            if
                String.length model.username
                    == 0
                    || String.length model.password
                    == 0
            then
                True
            else
                False

        buttonBlock =
            if showLoader then
                []
            else
                [ Card.custom <|
                    Button.button [ Button.primary, Button.attrs [ onClick JoinLogin, disabled loginDisabled ] ] [ text "Login" ]
                ]
    in
    Card.block [ Card.blockAlign Text.alignXsRight ]
        buttonBlock


viewCardForm : Model -> Html Msg
viewCardForm formData =
    Form.form []
        [ Form.group []
            [ Form.label [] [ text "Username" ]
            , Input.text [ Input.attrs [ onInput (UpdateFormData Username), value formData.username ] ]
            ]
        , Form.group []
            [ Form.label [] [ text "Password" ]
            , Input.password [ Input.attrs [ onInput (UpdateFormData Password), value formData.password ], onEnter JoinLogin ]
            ]
        ]



-- HELPERS


getAuthToken model =
    case model.session.user of
        Nothing ->
            AuthToken.AuthToken ""

        Just user ->
            user.guardian_token
