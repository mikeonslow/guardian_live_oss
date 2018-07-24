module Page.Administration.Security exposing (ExternalMsg(..), Model, Msg(..), channels, init, update, view)

import Bootstrap.Accordion as Accordion exposing (..)
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Tab as Tab
import Bootstrap.Table as Table
import Bootstrap.Text as Text
import Common.Connection as Connection
import Common.Icons as Icon
import Control as Debouncer
import Control.Debounce
import Data.Security.ApplicationPermissions as ApplicationPermissions exposing (AppPermissionSets, Permission, PermissionSets, appPermissionSetsDecoder, appPermissionSetsEncoder)
import Data.Security.ApplicationRoles as ApplicationRoles exposing (ApplicationRole, aplicationRolesDecoder, appRoleEncoder, newWithName)
import Data.User as User exposing (..)
import Dict exposing (Dict)
import Exts.Html exposing (nbsp)
import FontAwesome.Web as FA
import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Events exposing (on, onCheck, onClick, onInput, targetValue)
import Json.Decode as Decode exposing (Value)
import Json.Encode as JE
import List
import Maybe.Extra as Maybe
import Phoenix.Channel as Channel exposing (Channel)
import RemoteData exposing (RemoteData)
import Time
import Util exposing ((=>))
import Views.Remote as Remote


-- MODEL --


type alias Model =
    { errors : List Error
    , saveAppPermsEnabled : Bool
    , saveAppRolesEnabled : Bool
    , deletedRoles : List ApplicationRole
    , appRoles : RemoteData Error (List ApplicationRole)
    , appPermissionSets : RemoteData Error AppPermissionSets
    , tabState : Tab.State
    , user : Maybe User
    , searchRoleName : RoleName
    , searchSetName : SetName
    , searchBitNames : Dict SetName (Maybe BitName)
    , searchRoleSetName : Dict RoleName (Maybe SetName)
    , accordionState : Accordion.State
    , debounce : Debouncer.State Msg
    }


type alias Error =
    ( String, String )


type Msg
    = DropSetFromRole RoleName SetName
    | AddBit RoleName SetName BitName
    | RemoveBit RoleName SetName BitName
    | SearchRoleSet RoleName SetName
    | AddSetToRole SetName RoleName
    | DeleteRole RoleName
    | SaveRoles
    | RemoveAppPermSet SetName
    | AddAppPermSet SetName
    | AddRole RoleName
    | SaveAppPermSets
    | RemoveAppPermBit String Permission
    | AccordionMsg Accordion.State
    | ReceiveAppRoles Value
    | ReceiveAppPermissionSets Value
    | Debounce (Debouncer.Control Msg)
    | TabMsg Tab.State
    | SearchRoleName RoleName
    | SearchSetName SetName
    | SearchBitName SetName BitName
    | AddSetBit SetName
    | NoOption


type alias RoleName =
    String


type alias SetName =
    String


type alias BitName =
    String


type ExternalMsg
    = NoOp


init : Maybe User -> ( Model, Cmd Msg )
init user =
    let
        model =
            initialModel user

        endpoint =
            "admin:" ++ User.getUsername model.user

        events =
            [ eventAppPermissionSets model
            , eventAppRoles model
            ]
    in
    model
        => Cmd.batch (Connection.push endpoint events)


initialModel : Maybe User -> Model
initialModel user =
    { errors = []
    , saveAppPermsEnabled = False
    , saveAppRolesEnabled = False
    , deletedRoles = []
    , appRoles = RemoteData.Loading
    , appPermissionSets = RemoteData.Loading
    , tabState = Tab.initialState
    , user = user
    , searchRoleName = ""
    , searchSetName = ""
    , searchBitNames = Dict.empty
    , searchRoleSetName = Dict.empty
    , accordionState = Accordion.initialState
    , debounce = Debouncer.initialState
    }


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        Debounce debMsg ->
            Debouncer.update (\state -> { model | debounce = state }) model.debounce debMsg
                => NoOp

        SearchRoleSet roleName setName ->
            let
                newModel =
                    case ( model.appRoles, String.trim setName |> String.isEmpty ) of
                        ( RemoteData.Success appRoles, False ) ->
                            { model | searchRoleSetName = Dict.insert roleName (Just (String.trim setName)) model.searchRoleSetName }

                        _ ->
                            { model | searchRoleSetName = Dict.insert roleName Nothing model.searchRoleSetName }
            in
            newModel => Cmd.none => NoOp

        AddSetToRole setName roleName ->
            let
                newModel =
                    case ( model.appRoles, String.trim setName |> String.isEmpty ) of
                        ( RemoteData.Success appRoles, False ) ->
                            { model
                                | saveAppRolesEnabled = True
                                , appRoles = RemoteData.succeed (addSetToRole appRoles roleName setName)
                            }

                        _ ->
                            model
            in
            newModel => Cmd.none => NoOp

        AddBit roleName setName bitName ->
            let
                newModel =
                    case ( model.appRoles, String.trim bitName |> String.isEmpty ) of
                        ( RemoteData.Success appRoles, False ) ->
                            { model
                                | saveAppRolesEnabled = True
                                , appRoles = RemoteData.succeed (flip appRoles roleName setName bitName True)
                            }

                        _ ->
                            model
            in
            newModel => Cmd.none => NoOp

        RemoveBit roleName setName bitName ->
            let
                newModel =
                    case model.appRoles of
                        RemoteData.Success appRoles ->
                            { model
                                | saveAppRolesEnabled = True
                                , appRoles = RemoteData.succeed (flip appRoles roleName setName bitName False)
                            }

                        _ ->
                            model
            in
            newModel => Cmd.none => NoOp

        DropSetFromRole roleName setName ->
            let
                newModel =
                    case model.appRoles of
                        RemoteData.Success appRoles ->
                            let
                                -- ( selectedAppRoles, otherRoles ) =
                                --  List.partition (\role -> role.name == roleName) appRoles
                                updatedRoles =
                                    List.map
                                        (\role ->
                                            case role.name == roleName of
                                                True ->
                                                    removeSetFromRole setName role

                                                False ->
                                                    role
                                        )
                                        appRoles
                            in
                            { model | saveAppRolesEnabled = True, appRoles = RemoteData.succeed updatedRoles }

                        _ ->
                            model
            in
            newModel => Cmd.none => NoOp

        DeleteRole roleName ->
            let
                newModel =
                    case model.appRoles of
                        RemoteData.Success appRoles ->
                            let
                                ( deletedAppRoles, keptRoles ) =
                                    List.partition (\role -> role.name == roleName) appRoles
                            in
                            { model | saveAppRolesEnabled = True, appRoles = RemoteData.succeed keptRoles, deletedRoles = deletedAppRoles ++ model.deletedRoles }

                        _ ->
                            model
            in
            newModel => Cmd.none => NoOp

        SaveRoles ->
            case model.appRoles of
                RemoteData.Success appRoles ->
                    let
                        cmds =
                            Connection.push
                                ("admin:" ++ User.getUsername model.user)
                                [ { name = "save_app_roles"
                                  , payload =
                                        Just
                                            (JE.object
                                                [ ( "updated"
                                                  , JE.list
                                                        (List.map (\role -> appRoleEncoder role) appRoles)
                                                  )
                                                , ( "deleted"
                                                  , JE.list
                                                        (List.map (\role -> appRoleEncoder role) model.deletedRoles)
                                                  )
                                                ]
                                            )
                                  , onOk = Just (\response -> ReceiveAppRoles response)
                                  , onError = Nothing
                                  }
                                ]
                    in
                    { model | deletedRoles = [], saveAppRolesEnabled = False, appRoles = RemoteData.Loading } => Cmd.batch cmds => NoOp

                _ ->
                    model => Cmd.none => NoOp

        SaveAppPermSets ->
            case model.appPermissionSets of
                RemoteData.Success appPermSets ->
                    let
                        cmds =
                            Connection.push
                                ("admin:" ++ User.getUsername model.user)
                                [ { name = "save_app_perm_sets"
                                  , payload =
                                        Just (appPermissionSetsEncoder appPermSets)
                                  , onOk = Just (\response -> ReceiveAppPermissionSets response)
                                  , onError = Nothing
                                  }
                                ]
                    in
                    { model | saveAppPermsEnabled = False, appPermissionSets = RemoteData.Loading } => Cmd.batch cmds => NoOp

                _ ->
                    model => Cmd.none => NoOp

        RemoveAppPermSet setName ->
            let
                newModel =
                    case model.appPermissionSets of
                        RemoteData.Success appPermSets ->
                            let
                                updatedAppPermSet =
                                    RemoteData.succeed { appPermSets | permissionSets = Dict.remove setName appPermSets.permissionSets }
                            in
                            { model | saveAppPermsEnabled = True, appPermissionSets = updatedAppPermSet }

                        _ ->
                            model
            in
            newModel => Cmd.none => NoOp

        RemoveAppPermBit setName bitName ->
            let
                newModel =
                    case model.appPermissionSets of
                        RemoteData.Success appPermSets ->
                            let
                                newBits =
                                    Maybe.unwrap [] (\bits -> List.filter (\aBit -> aBit /= bitName) bits) (Dict.get setName appPermSets.permissionSets)

                                updatedAppPermSet =
                                    RemoteData.succeed { appPermSets | permissionSets = Dict.insert setName newBits appPermSets.permissionSets }
                            in
                            { model | saveAppPermsEnabled = True, appPermissionSets = updatedAppPermSet }

                        _ ->
                            model
            in
            newModel
                => Cmd.none
                => NoOp

        AccordionMsg state ->
            { model | accordionState = state }
                => Cmd.none
                => NoOp

        SearchSetName value ->
            { model | searchSetName = String.trim value }
                => Cmd.none
                => NoOp

        SearchBitName setName value ->
            case String.trim value |> String.isEmpty of
                False ->
                    { model | searchBitNames = Dict.insert setName (Just (String.trim value)) model.searchBitNames }
                        => Cmd.none
                        => NoOp

                True ->
                    model
                        => Cmd.none
                        => NoOp

        AddAppPermSet setName ->
            let
                newModel =
                    case ( model.appPermissionSets, String.trim setName |> String.isEmpty ) of
                        ( RemoteData.Success appPermSets, False ) ->
                            let
                                updatedAppPermSet =
                                    RemoteData.succeed { appPermSets | permissionSets = Dict.insert (String.trim setName) [] appPermSets.permissionSets }
                            in
                            { model | saveAppPermsEnabled = True, appPermissionSets = updatedAppPermSet }

                        _ ->
                            model
            in
            newModel
                => Cmd.none
                => NoOp

        AddRole roleName ->
            let
                newModel =
                    case ( model.appRoles, String.trim roleName |> String.isEmpty ) of
                        ( RemoteData.Success appRoles, False ) ->
                            -- have roles, new name is not empty
                            let
                                roleNam =
                                    String.trim roleName

                                updatedAppRoles =
                                    case List.filter (\role -> role.name == roleNam) appRoles of
                                        [] ->
                                            appRoles ++ [ ApplicationRoles.newWithName roleNam ]

                                        _ ->
                                            appRoles
                            in
                            { model | saveAppRolesEnabled = True, appRoles = RemoteData.succeed updatedAppRoles }

                        ( _, _ ) ->
                            -- Don't care!!!
                            model
            in
            newModel
                => Cmd.none
                => NoOp

        AddSetBit setName ->
            let
                newModel =
                    case ( model.appPermissionSets, String.trim setName |> String.isEmpty ) of
                        ( RemoteData.Success appPermSets, False ) ->
                            let
                                setNam =
                                    String.trim setName

                                -- DO NOT Remove bit if it's already in the list
                                bits =
                                    Dict.get setNam appPermSets.permissionSets

                                bitName =
                                    Dict.get setNam model.searchBitNames

                                newBits =
                                    case ( bits, bitName ) of
                                        ( Just theBits, Just newBit ) ->
                                            case newBit of
                                                Just newBitValue ->
                                                    -- append only if not member
                                                    case List.member newBitValue theBits of
                                                        True ->
                                                            theBits

                                                        False ->
                                                            List.append theBits [ newBitValue ]

                                                Nothing ->
                                                    theBits

                                        ( _, _ ) ->
                                            -- We doomed! -- Kidding - could be fresh set
                                            []

                                -- add bit Again, at the tail - order of bits matters to Guardian!!!
                                updatedAppPermSet =
                                    RemoteData.succeed { appPermSets | permissionSets = Dict.insert setNam newBits appPermSets.permissionSets }
                        --        cleanSearchBitNames = Dict.remove setName model.searchBitNames
                            in
                            { model | saveAppPermsEnabled = True, appPermissionSets = updatedAppPermSet }

                        _ ->
                            model
            in
            newModel
                => Cmd.none
                => NoOp

        SearchRoleName value ->
            { model | searchRoleName = String.trim value }
                => Cmd.none
                => NoOp

        ReceiveAppPermissionSets raw ->
            case Decode.decodeValue ApplicationPermissions.appPermissionSetsDecoder raw of
                Ok appPermissionSet ->
                    let
                        newSearchBitNames =
                            Dict.keys appPermissionSet.permissionSets
                                --> List ["set name1", ...]
                                |> List.map (\setName -> ( setName, Nothing ))
                                --> [("set", Maybe ..), ..]
                                |> Dict.fromList
                    in
                    { model | appPermissionSets = RemoteData.succeed appPermissionSet, saveAppPermsEnabled = False, searchBitNames = newSearchBitNames }
                        => Cmd.none
                        => NoOp

                Err error ->
                    { model | appPermissionSets = RemoteData.Failure ( error, error ), saveAppPermsEnabled = False, searchBitNames = Dict.empty }
                        => Cmd.none
                        => NoOp

        ReceiveAppRoles raw ->
            case Decode.decodeValue ApplicationRoles.decoder raw of
                Ok appRoles ->
                    { model | appRoles = RemoteData.succeed appRoles }
                        => Cmd.none
                        => NoOp

                Err error ->
                    { model | appRoles = RemoteData.Failure ( error, error ) }
                        => Cmd.none
                        => NoOp

        TabMsg state ->
            { model | tabState = state } => Cmd.none => NoOp

        NoOption ->
            model => Cmd.none => NoOp



-- VIEW --


view : Model -> Html Msg
view model =
    Grid.containerFluid
        [ class "mainContainer" ]
        [ Grid.row []
            [ Grid.col [ Col.xs12 ]
                [ text nbsp ]
            ]
        , Grid.row []
            [ Grid.col [ Col.xs12 ] [ h5 [] [ text "Administration / Security" ] ] ]
        , Grid.row []
            [ Grid.col [ Col.xs12 ] [ text nbsp ] ]
        , Grid.row []
            [ Grid.col [ Col.xs12 ]
                [ Tab.config TabMsg
                    |> Tab.items
                        [ Tab.item
                            { id = "appRoles"
                            , link = Tab.link [] [ text "Application Roles" ]
                            , pane =
                                Tab.pane [ class "mt-3" ]
                                    [ Grid.containerFluid
                                        []
                                        [ Grid.row []
                                            [ Grid.col [ Col.xs12 ]
                                                [ Input.text
                                                    [ Input.small
                                                    , Input.attrs
                                                        [ Attr.map (Control.Debounce.trailing Debounce (1 * Time.second)) <| onInput SearchRoleName
                                                        , class "ml-sm-2 my-2"
                                                        , style [ ( "width", "40%" ), ( "float", "left" ) ]
                                                        , placeholder "Role Name"
                                                        ]
                                                    ]
                                                , Button.linkButton
                                                    [ Button.small
                                                    , Button.primary
                                                    , Button.attrs
                                                        [ style [ ( "float", "left" ) ]
                                                        , class "ml-sm-2 my-2"
                                                        , onClick <| AddRole model.searchRoleName
                                                        ]
                                                    ]
                                                    [ text "Add Role"
                                                    , Icon.basicIcon FA.plus False
                                                    ]
                                                , Button.linkButton
                                                    [ Button.small
                                                    , Button.primary
                                                    , Button.disabled (not model.saveAppRolesEnabled)
                                                    , Button.attrs
                                                        [ class "ml-sm-2 my-2"
                                                        , style [ ( "float", "right" ) ]
                                                        , onClick <| SaveRoles
                                                        ]
                                                    ]
                                                    [ text "Save Roles"
                                                    , Icon.basicIcon FA.check False
                                                    ]
                                                ]
                                            ]
                                        , Grid.row
                                            []
                                            [ Grid.col []
                                                [ Accordion.config
                                                    AccordionMsg
                                                    |> Accordion.withAnimation
                                                    |> Accordion.cards
                                                        (showRoles model.searchRoleName
                                                            model.appRoles
                                                            model.appPermissionSets
                                                            model.searchRoleSetName
                                                        )
                                                    |> Accordion.view model.accordionState
                                                ]
                                            ]
                                        ]
                                    ]
                            }
                        , Tab.item
                            { id = "appPerms"
                            , link = Tab.link [] [ text "Application Permission Sets" ]
                            , pane =
                                Tab.pane [ class "mt-3" ]
                                    [ Grid.containerFluid
                                        []
                                        [ Grid.row
                                            []
                                            [ Grid.col [ Col.xs12 ]
                                                [ Input.text
                                                    [ Input.small
                                                    , Input.attrs
                                                        [ Attr.map (Control.Debounce.trailing Debounce (1 * Time.second)) <| onInput SearchSetName
                                                        , class "ml-sm-2 my-2"
                                                        , style [ ( "float", "left" ), ( "width", "40%" ) ]
                                                        , placeholder "Permission Set Name"
                                                        ]
                                                    ]
                                                , Button.linkButton
                                                    [ Button.small
                                                    , Button.primary

                                                    -- TODO implement add new AppPermSet -> Add Card on top enable "Set Name"
                                                    , Button.attrs
                                                        [ class "ml-sm-2 my-2"
                                                        , style [ ( "float", "left" ) ]
                                                        , onClick <| AddAppPermSet model.searchSetName
                                                        ]
                                                    ]
                                                    [ text "Add Permission Set"
                                                    , Icon.basicIcon FA.plus False
                                                    ]
                                                , Button.linkButton
                                                    [ Button.small
                                                    , Button.primary
                                                    , Button.disabled (not model.saveAppPermsEnabled)
                                                    , Button.attrs
                                                        [ class "ml-sm-2 my-2"
                                                        , style [ ( "float", "right" ) ]
                                                        , onClick <| SaveAppPermSets
                                                        ]
                                                    ]
                                                    [ text "Save App Permission Sets"
                                                    , Icon.basicIcon FA.check False
                                                    ]
                                                ]
                                            ]
                                        , Grid.row
                                            []
                                            [ Grid.col []
                                                [ Accordion.config
                                                    AccordionMsg
                                                    |> Accordion.withAnimation
                                                    |> Accordion.cards
                                                        (appPermSetsCards model.searchSetName model.searchBitNames model.appPermissionSets)
                                                    |> Accordion.view model.accordionState
                                                ]
                                            ]
                                        ]
                                    ]
                            }
                        ]
                    |> Tab.view model.tabState
                ]
            ]
        ]



-- VIEW HELPERS


setBit : ApplicationRole -> SetName -> BitName -> Bool -> ApplicationRole
setBit role setName bitName bitValue =
    { role
        | permissions =
            Dict.fromList
                (List.map
                    (\( aSetName, bits ) ->
                        case aSetName == setName of
                            True ->
                                ( aSetName
                                , case bitValue of
                                    True ->
                                        bitName :: bits

                                    False ->
                                        List.filter (\aBitName -> aBitName /= bitName) bits
                                )

                            False ->
                                ( aSetName, bits )
                    )
                    (Dict.toList role.permissions)
                )
    }


flip : List ApplicationRole -> RoleName -> SetName -> BitName -> Bool -> List ApplicationRole
flip appRoles roleName setName bitName bitValue =
    List.map
        (\role ->
            case role.name == roleName of
                True ->
                    setBit role setName bitName bitValue

                False ->
                    role
        )
        appRoles


removeSetFromRole : SetName -> ApplicationRole -> ApplicationRole
removeSetFromRole setName appRole =
    { appRole | permissions = Dict.remove setName appRole.permissions }


addSetToRole : List ApplicationRole -> RoleName -> SetName -> List ApplicationRole
addSetToRole appRoles roleName setName =
    List.map
        (\role ->
            case role.name == roleName of
                True ->
                    { role
                        | permissions = Dict.insert setName [] role.permissions
                    }

                False ->
                    role
        )
        appRoles


selectAppPermSet : String -> RemoteData Error AppPermissionSets -> Maybe ( String, List Permission )
selectAppPermSet selectedSet appPermissionSets =
    case appPermissionSets of
        RemoteData.Success appPermSets ->
            case Dict.filter (\key value -> String.toUpper key == selectedSet) appPermSets.permissionSets |> Dict.toList |> List.head of
                Just permSet ->
                    Just permSet

                Nothing ->
                    Nothing

        _ ->
            Nothing


showRoles : String -> RemoteData Error (List ApplicationRole) -> RemoteData Error AppPermissionSets -> Dict RoleName (Maybe SetName) -> List (Accordion.Card Msg)
showRoles roleFilter appRoles appPermissionSets searchRoleSetName =
    let
        filter =
            List.filter
                (\role ->
                    String.isEmpty roleFilter
                        || String.contains (String.toUpper roleFilter) (String.toUpper role.name)
                )
    in
    case appRoles of
        RemoteData.NotAsked ->
            errorCard roleFilter "Initialising Roles"

        RemoteData.Loading ->
            errorCard roleFilter "Loading Roles ..."

        RemoteData.Failure err ->
            errorCard roleFilter (toString err)

        RemoteData.Success roles ->
            case appPermissionSets of
                RemoteData.NotAsked ->
                    errorCard roleFilter "Initialising Permission Sets"

                RemoteData.Loading ->
                    errorCard roleFilter "Loading Permission Sets ..."

                RemoteData.Failure err ->
                    errorCard roleFilter ("Error Loading Permission Sets: " ++ toString err)

                RemoteData.Success appPermSets ->
                    case roles |> filter of
                        [] ->
                            errorCard roleFilter "No Matching Roles Found "

                        filteredRoles ->
                            rolesAccordion filteredRoles appPermSets searchRoleSetName



-- CHANNELS --


channels auth handlers =
    Channel.init ("admin:" ++ auth.username)
        |> Channel.withPayload
            (JE.object
                [ ( "username", JE.string auth.username )
                , ( "guardian_token", JE.string auth.token )
                ]
            )
        |> Channel.on "app_permission_sets" handlers.onAppPermissionsSet
        |> Channel.on "app_roles" handlers.onAppRoles



-- EVENTS


eventAppPermissionSets model =
    { name = "app_permission_sets"
    , payload =
        Just
            (JE.object
                [ ( "app_name", JE.string "app_ui" ) ]
             -- TODO do not hardcode
            )
    , onOk = Just (\response -> ReceiveAppPermissionSets response)
    , onError = Nothing
    }


eventAppRoles model =
    { name = "app_roles"
    , payload =
        Just
            (JE.object
                [ ( "app_name", JE.string "app_ui" ) ]
             -- TODO do not hardcode
            )
    , onOk = Just (\response -> ReceiveAppRoles response)
    , onError = Nothing
    }


rolesAccordion : List ApplicationRole -> AppPermissionSets -> Dict RoleName (Maybe SetName) -> List (Accordion.Card Msg)
rolesAccordion roles appPermSets searchRoleSetName =
    (\aRole ->
        if List.isEmpty roles then
            errorCard "Application Roles" "No Roles defined for this Application "
        else
            List.map (roleCard appPermSets.permissionSets searchRoleSetName) aRole
    )
        roles


roleCard : Dict String (List Permission) -> Dict RoleName (Maybe SetName) -> ApplicationRole -> Accordion.Card Msg
roleCard appPermSets searchRoleSetName role =
    let
        -- intersect AppRole Permissions and app Permissions
        legitSets =
            Dict.intersect role.permissions appPermSets

        -- role perm sets has to contain only PermissionSets available in AppPermSets
        -- extra =
           --  Dict.diff role.permissions appPermSets

        --y = case Dict.isEmpty extra of
          --  False ->
                -- TODO Deal with extra sets !!!
            --    Debug.log "Error: Permission Set is Unknown to Application" extra
            --True ->
              --  NoOp
        fullPermissionBitSets =
            Dict.intersect appPermSets legitSets
    in
    --
    Accordion.card
        { id = role.name
        , options = [ Card.outlineSuccess, Card.align Text.alignXsLeft ]
        , header =
            Accordion.header []
                (Accordion.toggle [] [ text nbsp, text role.name ])
                |> Accordion.appendHeader
                    [ span
                        [ onClick <| DeleteRole role.name
                        , Attr.style [ ( "float", "right" ) ]
                        ]
                        [ FA.remove ]
                    , span []
                        [-- TODO print brief role description, have `comments` attribute for Role
                        ]
                    ]
                |> Accordion.prependHeader
                    [ span [] [ FA.diamond, text nbsp ] ]
        , blocks =
            [ Accordion.block [ Card.blockAlign Text.alignXsLeft ]
                [ Card.blockQuote []
                    [ InputGroup.config
                        (InputGroup.text
                            [ Input.id "roleSetName"
                            , Input.attrs
                                [ placeholder "Enter Permission  Set Name"
                                , Attr.map
                                    (Control.Debounce.trailing Debounce (1 * Time.second))
                                  <|
                                    onInput (SearchRoleSet role.name)
                                ]
                            ]
                        )
                        |> InputGroup.small
                        |> InputGroup.attrs
                            [ style [ ( "width", "30%" ), ( "float", "left" ) ]
                            , class "ml-sm-3 my-3"
                            ]
                        |> InputGroup.view
                    ]
                ]
            , Accordion.listGroup
                (List.map
                    (\aMatch ->
                        ListGroup.li
                            [ ListGroup.success
                            , ListGroup.attrs
                                [ class "ml-sm-3 my-3"
                                , style [ ( "float", "left" ) ]
                                ]
                            ]
                            [ text aMatch
                            , Button.linkButton
                                [ Button.primary
                                , Button.attrs
                                    [ style [ ( "width", "10%" ), ( "float", "right" ) ]
                                    , class "ml-sm-3 my-3"
                                    , onClick <| AddSetToRole aMatch role.name
                                    ]
                                ]
                                [ text "Add" ]
                            ]
                    )
                    (permSetMatches role appPermSets searchRoleSetName)
                )
            , Accordion.block [ Card.blockAlign Text.alignXsLeft ]
                [ Card.blockQuote []
                    [ rolePermSetsView role.name fullPermissionBitSets legitSets ]
                ]
            ]
        }



-- TODO show list of permission sets that matches the roleSetName


permSetMatches : ApplicationRole -> PermissionSets -> Dict RoleName (Maybe SetName) -> List SetName
permSetMatches role appPermSets searchRoleSetName =
    case Dict.get role.name searchRoleSetName of
        Just maybeSearchRoleSetName ->
            case ( maybeSearchRoleSetName, String.isEmpty (Maybe.withDefault "" maybeSearchRoleSetName) ) of
                ( Just setSearchName, False ) ->
                    Dict.filter (\setName perms -> String.contains (String.toUpper setSearchName) (String.toUpper setName))
                        (Dict.filter
                            (\setName perms ->
                                not (Dict.member setName role.permissions)
                            )
                            appPermSets
                        )
                        |> Dict.keys

                _ ->
                    []

        _ ->
            []


rolePermSetsView : RoleName -> Dict String (List Permission) -> Dict String (List Permission) -> Html Msg
rolePermSetsView roleName fullPermBits rolePermSets =
    let
        -- List (key, [bits1,bit2,...])
        rolePermsList =
            Dict.toList rolePermSets
    in
    Remote.table
        { error = "Failure to load Role Permissions"
        , loading = "loading..."
        , options = [ Table.small, Table.bordered, Table.responsive, Table.striped ]
        , thead = rolePermSetTableHeader
        , tbody =
            RemoteData.map
                (\setBits ->
                    if List.isEmpty setBits then
                        emptyPermSetsTable
                    else
                        List.map
                            (permSetTableRaw roleName fullPermBits)
                            setBits
                            |> Table.tbody []
                )
                (RemoteData.succeed rolePermsList)
        }


appPermSetsCards : SetName -> Dict SetName (Maybe BitName) -> RemoteData Error AppPermissionSets -> List (Accordion.Card Msg)
appPermSetsCards setSearchName searchBitNames appPermSets =
    case appPermSets of
        RemoteData.NotAsked ->
            errorCard setSearchName "Initialising ..."

        RemoteData.Loading ->
            errorCard setSearchName "Loading ..."

        RemoteData.Failure err ->
            errorCard setSearchName (toString err)

        RemoteData.Success appPermSets ->
            Dict.filter
                (\setName perms ->
                    String.isEmpty setSearchName
                        || String.contains (String.toUpper setSearchName) (String.toUpper setName)
                )
                appPermSets.permissionSets
                |> appPermSetsData searchBitNames


errorCard : String -> String -> List (Accordion.Card msg)
errorCard setName reason =
    [ Accordion.card
        { id = "notFound"
        , options = []
        , header =
            Accordion.header [] <| Accordion.toggle [] [ setName ++ " Not available: " ++ reason |> text ]
        , blocks =
            []
        }
    ]


appPermSetsData : Dict SetName (Maybe BitName) -> Dict String (List Permission) -> List (Accordion.Card Msg)
appPermSetsData searchBitNames fullPermBits =
    List.map2
        (\( key, searchBitName ) ( key, allSetBits ) ->
            appPermissionBitsCard searchBitName key allSetBits
        )
        (searchBitNames |> Dict.toList)
        (fullPermBits |> Dict.toList)


appPermissionBitsRemoveView : String -> List Permission -> Html Msg
appPermissionBitsRemoveView setName setBits =
    Grid.containerFluid
        []
        [ Grid.row []
            (List.map
                (\bitName ->
                    Grid.col
                        []
                        [ span [ onClick <| RemoveAppPermBit setName bitName ] [ text bitName, text nbsp, text nbsp, FA.remove ] ]
                )
                setBits
            )
        ]


appPermissionBitsView : String -> List Permission -> Html msg -> Html msg
appPermissionBitsView setName setBits faIcon =
    Grid.containerFluid
        []
        [ Grid.row []
            (List.map
                (\bitName ->
                    Grid.col
                        []
                        [ text bitName, text nbsp, text nbsp, faIcon ]
                )
                setBits
            )
        ]


appPermissionBitsCard : Maybe BitName -> SetName -> List Permission -> Accordion.Card Msg
appPermissionBitsCard searchBitName setName setBits =
    Accordion.card
        { id = setName
        , options = [ Card.outlineSuccess, Card.align Text.alignXsLeft ]
        , header =
            Accordion.header []
                (Accordion.toggle [] [ text nbsp, text setName ])
                |> Accordion.appendHeader
                    [ span
                        [ onClick <| RemoveAppPermSet setName
                        , Attr.style [ ( "float", "right" ) ]
                        ]
                        [ FA.remove ]
                    , span [] [ text nbsp, appPermissionBitsView setName setBits FA.check ]
                    ]
                |> Accordion.prependHeader
                    [ span [] [ FA.shield, text nbsp ] ]
        , blocks =
            [ Accordion.block [ Card.blockAlign Text.alignXsLeft ]
                -- Edit form goes here?
                -- [ Card.text [] [ appPermissionBitsView setName setBits ]
                [ Card.text [] [ appPermissionBitsRemoveView setName setBits ] -- click will remove
                , Card.blockQuote []
                    [ Grid.containerFluid
                        []
                        [ Grid.row []
                            [ Grid.col [ Col.xs12 ]
                                [ Input.text
                                    [ Input.id "bitName"
                                    , Input.attrs
                                        [ placeholder "Enter Bit Name"
                                        , Attr.map (Control.Debounce.trailing Debounce (1 * Time.second)) <| onInput (SearchBitName setName)
                                        , class "ml-sm-2 my-2"
                                        , style [ ( "width", "40%" ), ( "float", "left" ) ]

                                        -- TODO make it searchable list with suggestions
                                        ]
                                    ]
                                , Button.linkButton
                                    [ Button.primary
                                    , Button.attrs
                                        [ style [ ( "width", "10%" ), ( "float", "left" ) ]
                                        , class "ml-sm-2 my-2"
                                        , onClick <| AddSetBit setName
                                        ]
                                    ]
                                    [ text "Add"
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        }


emptyPermSetsTable : Table.TBody msg
emptyPermSetsTable =
    Table.tbody []
        [ Table.tr []
            [ Table.td ([ class "no-result text-center", colspan 4 ] |> List.map Table.cellAttr)
                [ Icon.basicIcon FA.info_circle False
                , Html.text nbsp
                , Html.text "Set has No Permissions ..."
                ]
            ]
        ]



-- rolesTableRow : Dict String (List Permission) -> ApplicationRole -> Table.Row msg


emptyBitsTable : String -> Maybe (List Permission) -> Table.Row msg
emptyBitsTable setName fullBitsOfTheSet =
    Table.tr []
        [ Table.td [] [ Html.text setName ]
        , case fullBitsOfTheSet of
            Nothing ->
                Table.td [] [ Html.text "No bits set For this one ..." ]

            Just bits ->
                Table.td [] [ Html.text (toString bits) ]
        ]



-- TODO refactor to have Dict String (List roleBits, List fullBits) ?


permSetTableRaw : RoleName -> Dict String (List Permission) -> ( String, List Permission ) -> Table.Row Msg
permSetTableRaw roleName appPermissionSets roleSet =
    let
        ( roleSetName, roleBits ) =
            roleSet

        fullSetBits =
            Dict.get roleSetName appPermissionSets
    in
    case fullSetBits of
        Nothing ->
            Table.tr []
                [ Table.td [] [ Html.text roleSetName ]
                , Table.td [] [ Html.text "Invalid Set name In Role: Application Permission Set not Found ..." ]
                ]

        Just allSetBits ->
            Table.tr []
                [ Table.td []
                    [ Html.text roleSetName
                    ]
                , Table.td []
                    [ permissionBitsView roleName roleSetName allSetBits roleBits
                    , span
                        [ onClick <| DropSetFromRole roleName roleSetName
                        , Attr.style [ ( "float", "right" ) ]
                        ]
                        [ FA.remove ]
                    ]
                ]


permissionBitsView : RoleName -> SetName -> List Permission -> List Permission -> Html Msg
permissionBitsView roleName roleSetName setBits roleBits =
    let
        columnList =
            permissionBitsMap setBits roleBits

        drawBitCurried =
            drawBit roleName roleSetName
    in
    Grid.containerFluid
        []
        [ Grid.row []
            (List.map
                (\( bitName, enabled ) -> Grid.col [] (drawBitCurried enabled bitName))
                columnList
            )
        ]



-- drawBit : (Bool -> msg ) -> Bool -> Bool -> String -> Html msg
-- TODO implement change/save


drawBit : RoleName -> SetName -> Bool -> String -> List (Html Msg)
drawBit roleName setName checked bitName =
    case checked of
        True ->
            [ span
                [ onClick <| RemoveBit roleName setName bitName
                ]
                [ text bitName, text nbsp, FA.check_square_o ]
            ]

        False ->
            [ span
                [ onClick <| AddBit roleName setName bitName
                ]
                [ text bitName, text nbsp, FA.square_o ]
            ]


permissionBitsMap : List Permission -> List Permission -> List ( Permission, Bool )
permissionBitsMap setBits roleBits =
    List.map (\aSetBit -> ( aSetBit, List.member aSetBit roleBits )) setBits


rolePermSetTableHeader : Table.THead msg
rolePermSetTableHeader =
    Table.simpleThead
        [ Table.th [] [ Html.text "System Page/Permission Set Name" ]
        , Table.th [] [ Html.text "Permissions" ]
        ]


emptyPermSetTable : Table.TBody msg
emptyPermSetTable =
    Table.tbody []
        [ Table.tr []
            [ Table.td ([ class "no-result text-center", colspan 4 ] |> List.map Table.cellAttr)
                [ Icon.basicIcon FA.info_circle False
                , Html.text nbsp
                , Html.text "No Permissions in this Role. Use Add button ..."
                ]
            ]
        ]
