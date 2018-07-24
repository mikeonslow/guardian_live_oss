module Expect.Extra exposing (..)

import Expect exposing (Expectation)
import UpdateResult exposing (UpdateResult)


expectNoSideEffects : externalMsg -> UpdateResult model (Cmd msg) externalMsg -> Expectation
expectNoSideEffects expectedExternalMsg ( ( _, msg ), externalMsg ) =
    Expect.equal ( Cmd.none, expectedExternalMsg ) ( msg, externalMsg )


expectModel : model -> UpdateResult model command externalMsg -> Expectation
expectModel expected ( ( model, _ ), _ ) =
    Expect.equal expected model


expectCommand : command -> UpdateResult model command externalMsg -> Expectation
expectCommand expected ( ( _, command ), _ ) =
    Expect.equal expected command


expectExternalMsg : externalMsg -> UpdateResult model command externalMsg -> Expectation
expectExternalMsg expected ( ( _, _ ), externalMsg ) =
    Expect.equal expected externalMsg


expectModelWithCommand : model -> command -> UpdateResult model command externalMsg -> Expectation
expectModelWithCommand expectedModel expectedCommand updateResults =
    Tuple.first updateResults
        |> Expect.equal ( expectedModel, expectedCommand )
