module Views.Table exposing (empty)

import Bootstrap.Popover as Popover
import Bootstrap.Table as Table
import Common.Icons as Icon
import Exts.Html exposing (nbsp)
import FontAwesome.Web as FA
import Html exposing (text)
import Html.Attributes exposing (class, colspan)


empty : { columns : Int } -> List ( String, Table.Row msg )
empty { columns } =
    [ ( "empty"
      , Table.tr []
            [ Table.td [ Table.cellAttr <| class "no-result text-center", Table.cellAttr <| colspan columns ]
                [ Icon.basicIcon FA.info_circle False
                , text nbsp
                , text "No results found with current filters"
                ]
            ]
      )
    ]
