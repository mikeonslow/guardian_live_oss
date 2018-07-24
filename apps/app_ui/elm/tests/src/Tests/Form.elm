module Tests.Form exposing (..)

import Common.Form as Form
import Common.Form.Field as Field
import Expect exposing (..)
import Stub
import Test exposing (Test, describe, test)
import Tests.Extra exposing (it)


emptyContext : Test
emptyContext =
    let
        expected =
            { autocompleteMenus = [] }
    in
    it "returns Context with empty items" <|
        equal expected Form.emptyContext


getFieldValue : Test
getFieldValue =
    let
        fieldId =
            0

        expected =
            "1"

        field =
            Stub.textField fieldId expected

        result =
            Form.getFieldValue fieldId [ field ]
    in
    describe "getting a value from a field"
        [ describe "field exists"
            [ it "returns the expected value" <|
                equal expected result
            ]
        , describe
            "field does not exist"
            [ it "returns empty string" <|
                -- We should return a Maybe instead
                equal "" (Form.getFieldValue -1 [ field ])
            ]
        ]


getFormFieldData : Test
getFormFieldData =
    let
        field1Id =
            0

        field2Id =
            1

        field1 =
            Stub.textField field1Id "0"

        field2 =
            Stub.textField field2Id "1"

        form =
            Stub.form () [ [ field1 ], [ field2 ] ]

        result =
            Form.getFormFieldData form [ field1Id, field2Id ]

        expected =
            [ { id = field1Id
              , value = "0"
              , isValid = Field.Valid
              }
            , { id = field2Id
              , value = "1"
              , isValid = Field.Valid
              }
            ]
    in
    describe "getting all data from a form via ids"
        [ describe "ids match"
            [ it "should return the fields" <|
                equalLists expected result
            ]
        , describe "no matching ids"
            [ it "should return empty list" <|
                equal [] (Form.getFormFieldData form [ -1, -2 ])
            ]
        ]


validateAll : Test
validateAll =
    let
        field1Id =
            0

        field2Id =
            1

        field1 =
            Stub.textField field1Id "one"

        field2 =
            Stub.textField field2Id "two"

        form =
            Stub.form () [ [ field1 ], [ field2 ] ]

        invalidField1 =
            Stub.textField field1Id "!"

        invalidForm =
            { form | fields = [ [ invalidField1, field2 ] ] }

        expectedInvalidField1 =
            { invalidField1 | validation = Stub.invalidFieldValidationState }

        expectedInvalidForm =
            { form | fields = [ [ expectedInvalidField1, field2 ] ], validation = Stub.invalidFormValidationState }
    in
    describe "valide all fields in a form"
        [ it "should remain the same if validation does not change" <|
            equal form (Form.validateAll form)
        , it "should update if validation does change" <|
            equal expectedInvalidForm (Form.validateAll invalidForm)
        ]
