module UpdateResult exposing (..)


type alias UpdateResult model command externalMsg =
    ( ( model, command ), externalMsg )
