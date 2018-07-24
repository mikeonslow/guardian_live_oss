module Common.Url exposing (parseQuery)

import Dict exposing (Dict)
import Util


parseQuery =
    String.split "&"
        >> List.map (String.split "=")
        >> List.map
            (\pair ->
                case pair of
                    k :: [ v ] ->
                        Just ( k, v )

                    _ ->
                        Nothing
            )
        >> Util.justValues
        >> Dict.fromList
