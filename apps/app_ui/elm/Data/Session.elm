module Data.Session exposing (Session)

import Bootstrap.Navbar as Navbar
import Data.AuthToken exposing (AuthToken)
import Data.User as User exposing (User)


type alias Session =
    { user : Maybe User
    , navbarState : Navbar.State
    }
