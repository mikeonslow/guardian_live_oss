module Types exposing (..)

import Bootstrap.Navbar as Navbar
import Data.Alert as Alert
import Data.LocalStorageChange as StorageChange
import Data.User as User exposing (User, Username)
import Date exposing (Date)
import Json.Decode as Decode exposing (Value)
import Page.Administration.Security as AdministrationSecurity
import Page.Demo.Form as DemoForm
import Page.Link as Link
import Page.Login as Login
import Page.Main as Main
import Page.PermissionError as PermissionError
import Route exposing (Route)
import Window


type Msg
    = SetRoute (Maybe Route)
    | InitUserData User
    | Unauthorized
    | LinkMsg Link.Msg
    | LoginMsg Login.Msg
    | MainMsg Main.Msg
    | AdministrationSecurityMsg AdministrationSecurity.Msg
    | DemoFormMsg DemoForm.Msg
    | SetSocketConnect Bool
    | SocketClosedAbnormally
    | NavbarMsg Navbar.State
    | GetCurrentDateTime Date
    | ToDatePicker
    | WindowEvent
    | WindowSize Window.Size
    | ShowAlert Int Alert.AlertType
    | HideAlert Int
    | QueueAlert Alert.AlertType
    | LocalStorageChanged (Result String StorageChange.Change)
    | ChannelJoinError Value
    | NoOp


type alias Config =
    { userData : Value
    , currentTimestamp : Float
    }
