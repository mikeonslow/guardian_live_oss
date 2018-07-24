module Common.Form.Field exposing (..)

import Autocomplete
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Common.Role exposing (Role(..))
import Common.Validation as Validation
import Exts.List as ListExtra
import Html exposing (Html)
import Regex exposing (HowMany(..), find)
import Set exposing (Set)
import Util exposing ((=>))


type DataTypes
    = StringBasic
    | StringExtended
    | IPv4Address
    | Number
    | Phone
    | Decimal
    | DateOnly
    | Mac
    | ZipCode
    | Email
    | Password


type FieldTypes
    = Text
    | TextArea
    | ViewOnly
    | Checkbox
    | SelectList
    | Radio
    | Quantity
    | Autocomplete
    | Link
    | ControlGroup Selection (Set String)


type Selection
    = Single
    | Multiple


type ValidStatus
    = Initial
    | Valid
    | NotValid


type DistanceUnit
    = Rem
    | Px
    | Em


type alias Data msg id =
    { dataType : DataTypes
    , id : id
    , fieldType : FieldTypes
    , label : Maybe String
    , value : String
    , min : Maybe Int
    , max : Maybe Int
    , size : Maybe Int
    , width : Maybe String
    , validation : ValidationStatus
    , onUpdate : Maybe (String -> msg)
    , options : Maybe (List (SelectOption String))
    , optionsLoading : Bool
    , columnSizes : Maybe String
    , required : Bool
    , readOnly : Bool
    , disabled : Bool
    , keyedId : Int
    , invalidMessage : Maybe String
    }


type alias ValidationStatus =
    { isValid : ValidStatus
    , message : Maybe String
    , role : Maybe Role
    }


type alias SelectOption a =
    { id : a
    , label : String
    , default : Bool
    }


type Msg
    = SetValue
    | SetDisplayAndValue
    | SetOptions (List (SelectOption String))
    | GetValues
    | SetLoadingStatus


defaultSelectId : String
defaultSelectId =
    "-1"


viewOnly : Data msg id -> Data msg id
viewOnly field =
    let
        value =
            case field.fieldType of
                SelectList ->
                    valueFromSelected field

                _ ->
                    field.value
    in
    { field | fieldType = ViewOnly, value = value }


selectDefaultOption : { a | fieldType : FieldTypes, value : String } -> { a | fieldType : FieldTypes, value : String }
selectDefaultOption field =
    case field.fieldType of
        SelectList ->
            { field | value = defaultSelectId }

        _ ->
            field


valueFromSelected : Data msg id -> String
valueFromSelected field =
    Maybe.andThen (ListExtra.firstMatch (\{ id } -> id == field.value)) field.options
        |> Maybe.map .label
        |> Maybe.withDefault field.value


validate field =
    let
        { isValid, message, role } =
            field.validation

        fieldMinMax =
            field |> parseMinMax

        ( fieldMin, fieldMax ) =
            fieldMinMax

        intMin =
            String.toInt fieldMin
                |> Result.toMaybe

        intMax =
            String.toInt fieldMax
                |> Result.toMaybe

        validatedResult =
            case field.dataType of
                StringBasic ->
                    Validation.basicString intMin intMax field.value

                StringExtended ->
                    Validation.extendedString intMin intMax field.value

                IPv4Address ->
                    Validation.ipv4Address field.value

                Number ->
                    Validation.quantity intMin intMax field.value
                        |> Result.map toString

                Phone ->
                    Validation.phone intMin intMax field.value

                Decimal ->
                    Validation.decimal
                        (Result.toMaybe (String.toFloat fieldMin))
                        (Result.toMaybe (String.toFloat fieldMax))
                        field.value
                        |> Result.map toString

                DateOnly ->
                    Validation.date field.value

                Mac ->
                    Validation.mac field.value

                ZipCode ->
                    Validation.zipCode field.value

                Email ->
                    Validation.email intMin intMax field.value

                Password ->
                    Validation.password field.value

        validatedResultWithCustomError =
            validatedResult
                |> Result.mapError
                    (\e ->
                        Maybe.withDefault e field.invalidMessage
                    )

        isDefaultSelection =
            field.value == defaultSelectId

        validationStatus =
            if String.isEmpty field.value && not field.required then
                Valid
            else
                case validatedResultWithCustomError of
                    Result.Ok _ ->
                        Valid

                    Result.Err _ ->
                        NotValid

        updatedIsValid =
            case field.fieldType of
                SelectList ->
                    case ( isDefaultSelection, field.required ) of
                        ( True, True ) ->
                            NotValid

                        ( True, False ) ->
                            Initial

                        _ ->
                            validationStatus

                _ ->
                    validationStatus

        invalidMessage =
            case validatedResult of
                Result.Ok _ ->
                    ""

                Result.Err e ->
                    e

        ( updatedRole, updatedMessage ) =
            case updatedIsValid of
                Initial ->
                    ( Nothing, Nothing )

                Valid ->
                    ( Just Success, Nothing )

                NotValid ->
                    ( Just Danger, Just invalidMessage )
    in
    { field
        | validation =
            { isValid = updatedIsValid
            , message = updatedMessage
            , role = updatedRole
            }
    }


update msg fields field value =
    let
        fn =
            case msg of
                SetLoadingStatus ->
                    identity

                SetOptions options ->
                    updateOptions field options

                SetDisplayAndValue ->
                    updateValue field value True

                _ ->
                    updateValue field value False
    in
    List.map fn fields


updateOptions field options =
    \fs ->
        List.map
            (\f ->
                if field == f.id then
                    f |> (\f -> { f | options = Just options })
                else
                    f
            )
            fs


updateValue field value forceValue =
    \fs ->
        List.map
            (\f ->
                let
                    keyedId =
                        if forceValue then
                            f.keyedId + 1
                        else
                            f.keyedId
                in
                if field == f.id then
                    f
                        |> (\f -> { f | value = value, keyedId = keyedId })
                        |> validate
                else
                    f
            )
            fs


parseMinMax field =
    let
        fieldMin =
            case field.min of
                Nothing ->
                    "0"

                Just min ->
                    min |> toString

        fieldMax =
            case field.max of
                Nothing ->
                    ""

                Just max ->
                    max |> toString
    in
    ( fieldMin, fieldMax )
