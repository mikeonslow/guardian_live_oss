module Common.Page exposing (..)

import Bootstrap.Accordion as Accordion
import Bootstrap.Navbar as Navbar
import Dict exposing (..)


type alias Page =
    { ui : Ui
    }


type alias Ui =
    { navbarStates : Dict String UiAccordion
    , accordionStates : Dict String UiAccordion
    }


type alias UiNavbar =
    { navbarState : Navbar.State }


type alias UiAccordion =
    { accordionState : Accordion.State }


initialState =
    { ui =
        { navbarStates = Dict.fromList []
        , accordionStates = Dict.fromList []
        }
    }


type PageMsg
    = Save
    | Cancel
    | AccordionMsg Accordion.State
