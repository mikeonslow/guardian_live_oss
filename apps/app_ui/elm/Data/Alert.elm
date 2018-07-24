module Data.Alert exposing (..)


type AlertType
    = Basic String
    | Info String
    | Warning String
    | Success String
    | Error String
    | Danger String


type alias Alert =
    { id : Int
    , alertType : AlertType
    }
