module Page.Demo.Form exposing (ExternalMsg(..), Model, Msg(..), initialCmds, initialModel, update, view)

import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Text as Text
import Common.Form as Form
import Common.Form.Field as Field
import Common.Role exposing (Role(..))
import Data.Session as Session exposing (Session)
import Exts.Html exposing (nbsp)
import FontAwesome.Web as FA
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Util exposing ((=>))
import Views.Assets as Assets


-- MODEL --


type alias Model =
    { errors : List Error
    , form : Form.Data Msg FieldId
    }


type alias Error =
    ( String, String )


type Msg
    = UpdateField FieldId String
    | NoOption


type ExternalMsg
    = NoOp


type FieldId
    = TestField1
    | TestField2
    | TestField3
    | TestField4
    | TestField5
    | TestField6
    | TestField7
    | TestField8


initialModel : Model
initialModel =
    { errors = []
    , form =
        { layoutType = Form.Standard
        , columnLayout = Form.ThreeColumn
        , validation =
            { isValid = Form.Initial
            , message =
                Just defaultMessage
            , role = Just Info
            }
        , onSubmit = NoOption
        , fields =
            [--            [ { id = TestField1
             --              , dataType = Field.StringBasic
             --              , fieldType = Field.Text
             --              , label = Just "Test Field 1 (StringBasic 2 - 3)"
             --              , value = ""
             --              , min = Just 2
             --              , max = Just 3
             --              , size = Nothing
             --              , onUpdate = Just (updateField TestField1)
             --              , validation =
             --                    { isValid = Field.Initial
             --                    , message = Nothing
             --                    , role = Nothing
             --                    }
             --              }
             --            , { id = TestField2
             --              , dataType = Field.StringBasic
             --              , fieldType = Field.Text
             --              , label = Just "Test Field 2 (StringBasic)"
             --              , value = ""
             --              , min = Nothing
             --              , max = Just 25
             --              , size = Nothing
             --              , onUpdate = Just (updateField TestField2)
             --              , validation =
             --                    { isValid = Field.Initial
             --                    , message = Nothing
             --                    , role = Nothing
             --                    }
             --              }
             --            , { id = TestField3
             --              , dataType = Field.StringExtended
             --              , fieldType = Field.Text
             --              , label = Just "Test Field 3 (StringExtended)"
             --              , value = ""
             --              , min = Nothing
             --              , max = Just 25
             --              , size = Nothing
             --              , onUpdate = Just (updateField TestField3)
             --              , validation =
             --                    { isValid = Field.Initial
             --                    , message = Nothing
             --                    , role = Nothing
             --                    }
             --              }
             --            , { id = TestField4
             --              , dataType = Field.IPv4Address
             --              , fieldType = Field.Text
             --              , label = Just "Test Field 4 (IPv4Address)"
             --              , value = ""
             --              , min = Nothing
             --              , max = Nothing
             --              , size = Nothing
             --              , onUpdate = Just (updateField TestField4)
             --              , validation =
             --                    { isValid = Field.Initial
             --                    , message = Nothing
             --                    , role = Nothing
             --                    }
             --              }
             --            , { id = TestField5
             --              , dataType = Field.Number
             --              , fieldType = Field.Text
             --              , label = Just "Test Field 5 (Number 3 - 15)"
             --              , value = ""
             --              , min = Just 3
             --              , max = Just 15
             --              , size = Nothing
             --              , onUpdate = Just (updateField TestField5)
             --              , validation =
             --                    { isValid = Field.Initial
             --                    , message = Nothing
             --                    , role = Nothing
             --                    }
             --              }
             --            , { id = TestField6
             --              , dataType = Field.Decimal
             --              , fieldType = Field.Text
             --              , label = Just "Test Field 6 (Decimal 3 - 5)"
             --              , value = ""
             --              , min = Just 3
             --              , max = Just 5
             --              , size = Nothing
             --              , onUpdate = Just (updateField TestField6)
             --              , validation =
             --                    { isValid = Field.Initial
             --                    , message = Nothing
             --                    , role = Nothing
             --                    }
             --              }
             --            , { id = TestField7
             --              , dataType = Field.DateOnly
             --              , fieldType = Field.Text
             --              , label = Just "Test Field 7 (DateOnly)"
             --              , value = ""
             --              , min = Nothing
             --              , max = Nothing
             --              , size = Nothing
             --              , onUpdate = Just (updateField TestField7)
             --              , validation =
             --                    { isValid = Field.Initial
             --                    , message = Nothing
             --                    , role = Nothing
             --                    }
             --              }
             --            , { id = TestField8
             --              , dataType = Field.Mac
             --              , fieldType = Field.Text
             --              , label = Just "Test Field 8 (Mac)"
             --              , value = ""
             --              , min = Nothing
             --              , max = Nothing
             --              , size = Nothing
             --              , onUpdate = Just (updateField TestField8)
             --              , validation =
             --                    { isValid = Field.Initial
             --                    , message = Nothing
             --                    , role = Nothing
             --                    }
             --              }
            ]
        , buttons =
            [ { label = "Save"
              , icon = FA.check
              , typeStyle = Button.primary
              , onClick = Nothing
              }
            ]
        }
    }


initialCmds : List (Cmd msg)
initialCmds =
    []


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        UpdateField field value ->
            let
                form =
                    model.form

                fields =
                    model.form.fields

                updatedFields =
                    Field.update Field.SetValue fields field value

                updatedForm =
                    Form.update form updatedFields
            in
            { model | form = updatedForm }
                => Cmd.none
                => NoOp

        NoOption ->
            model => Cmd.none => NoOp



-- VIEW --


view : Model -> Html Msg
view model =
    let
        form =
            model.form
    in
    Grid.containerFluid
        [ class "mainContainer" ]
        [ Grid.row []
            [ Grid.col [ Col.xs12 ]
                [ text nbsp ]
            ]
        , Grid.row []
            [ Grid.col [ Col.xs12 ]
                [ text "Orders / Quotes / Form" ]
            ]
        , Grid.row []
            [ Grid.col [ Col.xs12 ]
                [ text nbsp ]
            ]
        , Grid.row []
            [ Grid.col [ Col.xs12 ]
                [ Form.view Form.emptyContext form ]
            ]
        ]


defaultMessage =
    "A helpful message to display if necessary. "
        ++ "This can provide the user insight on how to fill out the form or alert them of an overall"
        ++ "error with the form contents."


updateField field value =
    UpdateField field value
