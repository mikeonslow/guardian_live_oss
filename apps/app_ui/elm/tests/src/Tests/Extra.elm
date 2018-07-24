module Tests.Extra exposing (..)

import Expect
import Expect.Extra exposing (..)
import Test exposing (Test, test)
import UpdateResult exposing (UpdateResult)


testNoSideEffects : externalMsg -> UpdateResult model (Cmd msg) externalMsg -> Test
testNoSideEffects expectedExternalMsg updateResults =
    test "no side effects" <|
        \_ ->
            expectNoSideEffects expectedExternalMsg updateResults


it : String -> Expect.Expectation -> Test
it message expectation =
    test message (\() -> expectation)
