module Data.Security.ApplicationRoles exposing (..)

import Data.Security.ApplicationPermissions as ApplicationPermissions exposing (Permission, PermissionSets, permissionSetDecoder)
import Dict exposing (Dict)
import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, optional, required)
import Json.Encode as Encode exposing (Value)
import Json.Encode.Extra as EncodeExtra
import UrlParser
import Util exposing ((=>))


type alias ApplicationRole =
    { id : Float
    , name : String
    , permissions : PermissionSets

    -- sparsed bits of Application Permissions set permissions
    }


newWithName : String -> ApplicationRole
newWithName withName =
    { id = 0.0
    , name = withName
    , permissions = Dict.empty
    }



-- SERIALIZATION --


appRoleEncoder : ApplicationRole -> Encode.Value
appRoleEncoder role =
    Encode.object
        [ ( "id", Encode.float role.id )
        , ( "name", Encode.string role.name )
        , ( "permissions", ApplicationPermissions.encodePermissionSets role.permissions )
        ]


decoder =
    Decode.at [ "app_roles" ] aplicationRolesDecoder


aplicationRolesDecoder : Decoder (List ApplicationRole)
aplicationRolesDecoder =
    Decode.list aplicationRoleDecoder


aplicationRoleDecoder : Decoder ApplicationRole
aplicationRoleDecoder =
    decode ApplicationRole
        |> required "id" Decode.float
        |> required "name" Decode.string
        |> required "permissions" ApplicationPermissions.permissionSetDecoder
