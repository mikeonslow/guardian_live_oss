module Data.Security.ApplicationPermissions exposing (..)

import Dict exposing (Dict)
import Exts.Json.Encode as ExEncode
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, optional, required)
import Json.Encode as Encode exposing (Value)


type alias AppPermissionSets =
    { --id : Float
      --, appName : String
          permissionSets : PermissionSets
    }


type alias PermissionSets =
    Dict String (List Permission)


type alias Permission =
    String



--  { id : String
--, lable : String
-- }
-- SERIALIZATION --


appPermissionSetsDecoder : Decoder AppPermissionSets
appPermissionSetsDecoder =
    decode AppPermissionSets
        -- |> required "id" Decode.float
        -- |> required "appName" Decode.string
        |> required "permissionSets" permissionSetDecoder


permissionSetDecoder : Decoder PermissionSets
permissionSetDecoder =
    Decode.dict permissionListDecoder


permissionListDecoder : Decoder (List Permission)
permissionListDecoder =
    Decode.list permissionDecoder


permissionDecoder : Decoder Permission
permissionDecoder =
    Decode.string


appPermissionSetsEncoder : AppPermissionSets -> Encode.Value
appPermissionSetsEncoder set =
    Encode.object
        [ -- ( "id", Encode.float set.id )
          -- , ( "appName", Encode.string set.appName )
          -- ,
              ( "permissionSets", encodePermissionSets set.permissionSets )
        ]


encodePermissionSets : Dict String (List Permission) -> Value
encodePermissionSets dict =
    dict
        -- Dict String (List String)
        |> Dict.map (always encodeListOfStrings)
        -- Dict String Value
        |> Dict.toList
        -- List (String, Value)
        |> Encode.object


encodeListOfStrings : List String -> Value
encodeListOfStrings listOfStrings =
    listOfStrings
        |> List.map Encode.string
        |> Encode.list



-- TODO need to supply label from Dict of some sort, serverside?
