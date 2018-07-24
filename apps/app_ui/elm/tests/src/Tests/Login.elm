module Tests.Login exposing (..)

import Data.AuthToken as Auth
import Data.User as User exposing (User)
import Expect
import Expect.Extra exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Navigation
import Page.Login as Login
import Ports
import Stub
import Test exposing (..)
import Tests.Extra exposing (testNoSideEffects)
import UpdateResult exposing (UpdateResult)


joinLoginTests : Test
joinLoginTests =
    let
        msg =
            Login.JoinLogin

        model =
            Login.initialModel
    in
    describe "join login tests"
        [ test "do not remember username" <|
            \_ ->
                let
                    noCacheUsername =
                        { model | cacheUsername = False }
                in
                run msg noCacheUsername
                    |> expectModel noCacheUsername
        , test "remember username" <|
            \_ ->
                let
                    cacheUsername =
                        { model | cacheUsername = True }
                in
                run msg cacheUsername
                    |> expectModelWithCommand cacheUsername (Ports.setUsernameCache cacheUsername.username)
        , test "connect to socket" <|
            \_ ->
                run msg model
                    |> expectExternalMsg (Login.SetSocketConnect True)
        ]


receiveLoginMessage : Test
receiveLoginMessage =
    let
        model =
            Login.initialModel

        user =
            Stub.user

        success =
            Login.ReceiveLoginMessage (User.encode user)

        error =
            Login.ReceiveLoginMessage Encode.null

        token =
            Auth.authTokenToString user.guardian_token
    in
    describe "receiving login message response"
        [ describe "successful decoding"
            [ test "updates token and resets password" <|
                \_ ->
                    let
                        expected =
                            { model | guardian_token = token, password = "" }
                    in
                    run success model
                        |> expectModel expected
            , test "save user data" <|
                \_ ->
                    let
                        expected =
                            Cmd.batch
                                [ Ports.setSecurityToken token
                                , Ports.setUserCache (User.encode user)
                                , Navigation.newUrl "#"
                                ]
                    in
                    run success model
                        |> expectCommand expected
            , test "initialize user data" <|
                \_ ->
                    run success model
                        |> expectExternalMsg (Login.InitUserData user)
            ]
        , describe "decoding failure" <|
            [ testSetErrorsWithNoSideEffects (run error model) ]
        ]


receiveUnauthorizedMessage : Test
receiveUnauthorizedMessage =
    let
        model =
            Login.initialModel

        user =
            Stub.user

        error =
            Login.ReceiveUnauthorizedMessage Encode.null

        success =
            Login.ReceiveUnauthorizedMessage (User.encode user)
    in
    describe "receive unauthorizedMessage response"
        [ describe "sucessful decoding"
            [ testHasErrors (run success model)
            , testNoSideEffects Login.NoOp (run success model)
            ]
        , describe "decoding failure"
            [ testHasErrors (run error model)
            , test "requests unauthorized external command" <|
                \_ ->
                    run error model
                        |> expectExternalMsg Login.Unauthorized
            ]
        ]


receiveLogoutMessage : Test
receiveLogoutMessage =
    let
        model =
            Login.initialModel

        success =
            Login.ReceiveLoginMessage (Encode.bool True)

        error =
            Login.ReceiveLogoutMessage Encode.null
    in
    describe "receive logout message response"
        [ describe "successful decoding"
            [ testNoSideEffects Login.NoOp (run success model)
            ]
        , describe "decoding failure"
            [ testHasErrors (run error model) ]
        ]


toggleCacheUsername : Test
toggleCacheUsername =
    let
        model =
            Login.initialModel

        cacheUsername =
            { model | cacheUsername = True }

        noCacheUsername =
            { model | cacheUsername = False }

        msg =
            Login.ToggleCacheUsername
    in
    describe "toggle cache username"
        [ test "updates form data to enable caching username" <|
            \_ ->
                run msg noCacheUsername
                    |> expectModel cacheUsername
        , test "updates form data to disable caching username" <|
            \_ ->
                run msg cacheUsername
                    |> expectModel noCacheUsername
        , test "no side effects if caching username" <|
            \_ ->
                run msg noCacheUsername
                    |> expectNoSideEffects Login.NoOp
        , test "clear cached user name if not caching username" <|
            \_ ->
                run msg cacheUsername
                    |> expectCommand (Ports.clearUsernameCache "")
        ]


getCachedUsername : Test
getCachedUsername =
    let
        cachedData =
            Ports.CacheData "username" True

        model =
            Login.initialModel

        msg =
            Login.GetCachedUsername cachedData
    in
    describe "retreive cached username"
        [ test "update model with cached data" <|
            \_ ->
                let
                    expected =
                        { model | username = "username", cacheUsername = True }
                in
                run msg model
                    |> expectModel expected
        , testNoSideEffects Login.NoOp (run msg model)
        ]


getSecurityToken : Test
getSecurityToken =
    let
        model =
            Login.initialModel

        validToken =
            Ports.GuardianToken "token"

        invalidToken =
            Ports.GuardianToken ""

        msg =
            Login.GetSecurityToken
    in
    describe "get token"
        [ test "update model with successsful token" <|
            \_ ->
                let
                    expected =
                        { model | guardian_token = "token" }
                in
                run (msg validToken) model
                    |> expectModel expected
        , test "do not update model if there is invalid token" <|
            \_ ->
                run (msg invalidToken) model
                    |> expectModel model
        , testNoSideEffects Login.NoOp (run (msg validToken) model)
        , testNoSideEffects Login.NoOp (run (msg invalidToken) model)
        ]



-- Helpers


run : Login.Msg -> Login.Model -> LoginUpdateResult
run msg model =
    Login.update msg model


type alias LoginUpdateResult =
    UpdateResult Login.Model (Cmd Login.Msg) Login.ExternalMsg


testSetErrorsWithNoSideEffects : LoginUpdateResult -> Test
testSetErrorsWithNoSideEffects updateResults =
    concat
        [ testHasErrors updateResults
        , testNoSideEffects Login.NoOp updateResults
        ]


testHasErrors : LoginUpdateResult -> Test
testHasErrors ( ( model, _ ), _ ) =
    test "add error to model" <|
        \_ ->
            Expect.false "has errors" (List.isEmpty model.errors)
