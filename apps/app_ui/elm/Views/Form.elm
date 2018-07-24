module Views.Form
    exposing
        ( AutocompleteConfig
        , AutocompleteItem
        , ButtonConfig
        , Col
        , Data
        , DataType(..)
        , DataTypeOptions
        , Field
        , FieldOption
        , FormValidation(..)
        , Row
        , SelectItem
        , SimpleMsg
            ( HackResetTextForElm18
            , SetChecked
            , SetFormValidation
            , SetMutliSelected
            , SetOptions
            , SetQuantity
            , SetRadioSelection
            , SetSelectListSelection
            , SetSingleSelection
            , SetText
            )
        , SimpleSelectItem
        , ViewConfig
        , autocomplete
        , autocompleteForOptions
        , button
        , buttonType
        , checkbox
        , col
        , custom
        , customSelectList
        , customView
        , getChecked
        , getMultiSelected
        , getQuantity
        , getSelected
        , getText
        , helpText
        , init
        , inputText
        , invalidMessage
        , isValidForm
        , label
        , link
        , maxlength
        , multiButtonSelection
        , oneColumn
        , quantityPicker
        , radio
        , required
        , rightAligned
        , row
        , selectList
        , singleButtonSelection
        , textarea
        , toSimpleSelectItem
        , twoColumn
        , update
        , updateAutocomplete
        , updateWithKeyboardMsg
        , validMessage
        , validateForm
        , validateFormWithOptions
        , view
        , warningMessage
        )

{-| This module is a light abstraction over building forms with bootstrap. Adds common functionality and type safety to render forms.


# Data

@docs Data, init, getChecked, getText, getSelected, getMultiSelected, getQuantity


# Validation

@docs isValidForm, validateForm, validateFormWithOptions


# Updating

@docs SimpleMsg, update, AutoMsg, updateAutocomplete, AutocompleteItem, updateWithKeyboardMsg


# Fields

@docs DataType, DataTypeOptions, Field, inputText, textarea, checkbox, button, selectList, customSelectList, radio, quantityPicker, link, singleButtonSelection, multiButtonSelection, autocomplete, autocompleteForOptions, custom, SelectItem, SimpleSelectItem, toSimpleSelectItem


# Field Options

@docs FieldOption, label, required, invalidMessage, validMessage, warningMessage, helpText


# Layout

@docs Row, Col, row, col, oneColumn, twoColumn


# View

@docs view, customView, ViewConfig, AutocompleteConfig, ButtonConfig, buttonType

-}

import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Form
import Bootstrap.Form.Checkbox
import Bootstrap.Form.Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Form.Radio
import Bootstrap.Form.Select
import Bootstrap.Form.Textarea
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col
import Bootstrap.Grid.Row
import Common.BoundedNumber as Bounded exposing (BoundedNumber)
import Common.Icons as Icon
import Common.Validation as Validation
import Dict exposing (Dict)
import Exts.Html exposing (nbsp)
import Exts.Maybe
import FontAwesome.Web as FA
import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Keyed as Keyed
import List.Extra
import RemoteData exposing (RemoteData)
import Set exposing (Set)
import Util exposing ((=>))
import Validation exposing (ValidationResult(..))
import Views.Autocomplete
import Views.Remote


-- Data


type FormValidation
    = Valid
    | Invalid


type alias Key =
    String


{-| Opaque type that holds the values of all the fields in the form.
-}
type Data id
    = Data (Maybe FormValidation) (Fields id)


type alias Fields id =
    { inputTexts : Dict Key StringField
    , checkboxes : Dict Key CheckboxField
    , textareas : Dict Key StringField
    , selectLists : Dict Key SelectionField
    , radios : Dict Key SelectionField
    , quantityPickers : Dict Key (SimpleField (BoundedNumber Int))
    , links : Dict Key LinkField
    , singleButtonSelections : Dict Key SelectionField
    , multiButtonSelections : Dict Key MultiButtonSelectionField
    , buttons : Dict Key (ButtonField id)
    , autocompletes : Dict Key (AutocompleteField id)
    , customs : Dict Key id
    }


{-| Initialize with data to represent all the fields that will be in the form.
Note that order does not matter. Views define the layout and UI of the form data,
which means we can do things like share form initializations and render them differently.

    init
        [ checkbox id [ label "Good Api?" ] True
        , button id [] "Finish"
        ]

-}
init : List (Field id) -> Data id
init fields =
    Data Nothing (initFields fields)


{-| Attempt to see if a field is checked
-}
getChecked : id -> Data id -> Maybe Bool
getChecked id (Data _ fields) =
    getValue id fields.checkboxes


{-| Attempt to get a text value
-}
getText : id -> Data id -> Maybe (ValidationResult String)
getText id (Data _ fields) =
    Exts.Maybe.oneOf
        [ getValue id fields.inputTexts
        , getValue id fields.textareas
        , getValue id fields.autocompletes
        ]


{-| Attempt to get the selected value
-}
getSelected : id -> Data id -> Maybe (ValidationResult Float)
getSelected id (Data _ fields) =
    Exts.Maybe.oneOf
        [ getValue id fields.selectLists
        , getValue id fields.radios
        , getValue id fields.singleButtonSelections
        ]


{-| Attempt to get all the selected values of a multiselected item
-}
getMultiSelected : id -> Data id -> Maybe (ValidationResult (Set Float))
getMultiSelected id (Data _ fields) =
    getValue id fields.multiButtonSelections


{-| Attempt to get the quanity value
-}
getQuantity : id -> Data id -> Maybe Int
getQuantity id (Data _ fields) =
    getValue id fields.quantityPickers
        |> Maybe.map Bounded.value


getValue : id -> Dict Key { a | value : value } -> Maybe value
getValue id dict =
    Dict.get (toKey id) dict
        |> Maybe.map .value


initFields : List (Field id) -> Fields id
initFields =
    List.foldl insertField
        { inputTexts = Dict.empty
        , checkboxes = Dict.empty
        , textareas = Dict.empty
        , selectLists = Dict.empty
        , radios = Dict.empty
        , quantityPickers = Dict.empty
        , links = Dict.empty
        , singleButtonSelections = Dict.empty
        , multiButtonSelections = Dict.empty
        , buttons = Dict.empty
        , autocompletes = Dict.empty
        , customs = Dict.empty
        }


insertField : Field id -> Fields id -> Fields id
insertField field fields =
    let
        insert id =
            Dict.insert (toKey id)
    in
    case field of
        InputText id inputField ->
            { fields | inputTexts = insert id inputField fields.inputTexts }

        Checkbox id checkboxField ->
            { fields | checkboxes = insert id checkboxField fields.checkboxes }

        Textarea id textareaField ->
            { fields | textareas = insert id textareaField fields.textareas }

        SelectList id selectListField ->
            { fields | selectLists = insert id selectListField fields.selectLists }

        Radio id radioField ->
            { fields | radios = insert id radioField fields.radios }

        QuantityPicker id quantityPickerField ->
            { fields | quantityPickers = insert id quantityPickerField fields.quantityPickers }

        Link id linkField ->
            { fields | links = insert id linkField fields.links }

        SingleButtonSelection id singleButtonSelectionField ->
            { fields | singleButtonSelections = insert id singleButtonSelectionField fields.singleButtonSelections }

        MultiButtonSelection id multiButtonSelectionField ->
            { fields | multiButtonSelections = insert id multiButtonSelectionField fields.multiButtonSelections }

        Button id buttonField ->
            { fields | buttons = insert id buttonField fields.buttons }

        Autocomplete id autocompleteField ->
            { fields | autocompletes = insert id autocompleteField fields.autocompletes }

        Custom id ->
            { fields | customs = insert id id fields.customs }


{-| Check if any of the fields have an Invalid status or Initial status but is required
-}
isValidForm : Data id -> Bool
isValidForm (Data _ fields) =
    let
        validations dict =
            Dict.map (\_ { value, options } -> ( value, options.required )) dict
                |> Dict.values
                |> List.map
                    (\( value, required ) ->
                        case value of
                            Validation.Valid _ ->
                                True

                            Validation.Invalid _ _ ->
                                False

                            Initial ->
                                not required
                    )
    in
    List.concat
        [ validations fields.inputTexts
        , validations fields.textareas
        , validations fields.selectLists
        , validations fields.radios
        , validations fields.singleButtonSelections
        , validations fields.multiButtonSelections
        , validations fields.autocompletes
        ]
        |> List.all (\valid -> valid == True)


{-| Validate all fields in a form to show a form validation message.
Causes initial values to be validated even if the user did not act upon them.
-}
validateForm : Data id -> Data id
validateForm ((Data _ fields) as data) =
    let
        validateField requireValidator errorMessage default key field =
            case field.value of
                Validation.Valid _ ->
                    field

                Validation.Invalid _ _ ->
                    field

                Validation.Initial ->
                    { field
                        | value =
                            validateRequired requireValidator field.options default
                                |> Validation.mapMessage (\_ -> errorMessage)
                    }

        stringValidator key field =
            validateField
                (Validation.validate Validation.required)
                (dataTypeError field.dataType)
                ""
                key
                field

        multiButtonSelectionsValidator =
            validateField
                (\value -> Validation.validate (Validation.nonEmptySet value) "")
                Validation.selectAnOptionError
                Set.empty

        selectListValidator =
            validateField
                (\value ->
                    Validation.validate Validation.notDefaultOption (toString value)
                        |> Validation.andThen validateIsFloat
                )
                Validation.selectAnOptionError
                defaultSelectionId

        selectionValidator =
            validateField
                (\value ->
                    Validation.validate Validation.required (toString value)
                        |> Validation.andThen validateIsFloat
                )
                Validation.selectAnOptionError
                defaultSelectionId

        validatedFields =
            { fields
                | inputTexts = Dict.map stringValidator fields.inputTexts
                , textareas = Dict.map stringValidator fields.textareas
                , selectLists = Dict.map selectListValidator fields.selectLists
                , radios = Dict.map selectionValidator fields.radios
                , singleButtonSelections = Dict.map selectionValidator fields.singleButtonSelections
                , multiButtonSelections = Dict.map multiButtonSelectionsValidator fields.multiButtonSelections
                , autocompletes = Dict.map stringValidator fields.autocompletes
            }

        formValidation =
            if isValidForm (Data Nothing validatedFields) then
                Just Valid
            else
                Just Invalid
    in
    Data formValidation validatedFields


{-| Validate all fields in a form to show a form validation message. Options are given for autocomplete fields
to be one of the options provided for that id key.
-}
validateFormWithOptions : Dict String (List AutocompleteItem) -> Data id -> Data id
validateFormWithOptions options data =
    let
        (Data _ validatedFields) =
            validateForm data

        updatedFields =
            Dict.foldl
                (\id options acc ->
                    { acc
                        | autocompletes = Dict.update id (Maybe.map (updateAutocompleteFieldValueWithOptions options)) acc.autocompletes
                    }
                )
                validatedFields
                options

        newValidation =
            if isValidForm (Data Nothing updatedFields) then
                Just Valid
            else
                Just Invalid
    in
    Data newValidation updatedFields


getField : id -> Data id -> Maybe (Field id)
getField id (Data _ fields) =
    let
        get id =
            Dict.get (toKey id)

        map tag =
            Maybe.map (tag id)
    in
    Exts.Maybe.oneOf
        [ get id fields.inputTexts |> map InputText
        , get id fields.checkboxes |> map Checkbox
        , get id fields.textareas |> map Textarea
        , get id fields.selectLists |> map SelectList
        , get id fields.radios |> map Radio
        , get id fields.quantityPickers |> map QuantityPicker
        , get id fields.links |> map Link
        , get id fields.singleButtonSelections |> map SingleButtonSelection
        , get id fields.multiButtonSelections |> map MultiButtonSelection
        , get id fields.buttons |> map Button
        , get id fields.customs |> Maybe.map (\_ -> Custom id)
        , get id fields.autocompletes |> map Autocomplete
        ]


{-| Messages that can update values in the form.
-}
type SimpleMsg id
    = OnTextChange id String
    | SetQuantity id String
    | IncrementQuantity id
    | DecrementQuantity id
    | SetChecked id Bool
    | SetSelectListSelection id Float
    | SetRadioSelection id Float
    | SetSingleSelection id Float
    | SetMutliSelected id (Set Float)
    | SetText id String
    | SetOptions id (RemoteData String (List SimpleSelectItem))
    | SetFormValidation (Maybe FormValidation)
    | HackResetTextForElm18 id


{-| Update the data in a form
-}
update : SimpleMsg id -> Data id -> Data id
update msg ((Data _ fields) as data) =
    case msg of
        SetText id text ->
            Data Nothing
                { fields
                    | inputTexts = updateDict id (updateStringField text >> incrementKeyedId) fields.inputTexts
                    , textareas = updateDict id (updateStringField text >> incrementKeyedId) fields.textareas
                    , autocompletes = updateDict id (updateAutocompleteFieldValue text) fields.autocompletes
                }

        OnTextChange id text ->
            Data Nothing
                { fields
                    | inputTexts = updateDict id (updateStringField text) fields.inputTexts
                    , textareas = updateDict id (updateStringField text) fields.textareas
                }

        SetQuantity id quantity ->
            let
                validator { value } =
                    Validation.required quantity
                        |> Result.andThen (Validation.quantity Nothing Nothing)
                        |> Result.map (\newValue -> Bounded.set newValue value)
                        |> Result.withDefault value
            in
            Data Nothing
                { fields
                    | quantityPickers = updateValueById id validator fields.quantityPickers
                }

        IncrementQuantity id ->
            Data Nothing
                { fields
                    | quantityPickers = updateValueById id (\{ value } -> Bounded.inc value) fields.quantityPickers
                }

        DecrementQuantity id ->
            Data Nothing
                { fields
                    | quantityPickers = updateValueById id (\{ value } -> Bounded.dec value) fields.quantityPickers
                }

        SetChecked id checked ->
            Data Nothing
                { fields
                    | checkboxes = updateValueById id (\_ -> checked) fields.checkboxes
                }

        SetSingleSelection id selected ->
            let
                validator { options } =
                    Validation.valid selected
                        |> Validation.map toString
                        |> Validation.andThen (validateRequired (Validation.validate Validation.required) options)
                        |> Validation.andThen validateIsFloat
            in
            Data Nothing
                { fields
                    | singleButtonSelections = updateValueById id validator fields.singleButtonSelections
                }

        SetMutliSelected id selected ->
            let
                validator { options } =
                    Validation.valid selected
                        |> Validation.andThen (validateRequired (\value -> Validation.validate (Validation.nonEmptySet value) "") options)
            in
            Data Nothing
                { fields
                    | multiButtonSelections = updateValueById id validator fields.multiButtonSelections
                }

        SetRadioSelection id selected ->
            let
                validator { options } =
                    Validation.valid selected
                        |> Validation.map toString
                        |> Validation.andThen (validateRequired (Validation.validate Validation.required) options)
                        |> Validation.andThen validateIsFloat
            in
            Data Nothing
                { fields
                    | radios = updateValueById id validator fields.radios
                }

        SetSelectListSelection id selected ->
            let
                initialValue =
                    if selected == defaultSelectionId then
                        Validation.Initial
                    else
                        Validation.valid selected

                validator { options } =
                    initialValue
                        |> Validation.map toString
                        |> Validation.andThen (validateRequired (Validation.validate Validation.notDefaultOption) options)
                        |> Validation.andThen validateIsFloat
            in
            Data Nothing
                { fields
                    | selectLists = updateValueById id validator fields.selectLists
                }

        SetFormValidation validation ->
            Data validation fields

        HackResetTextForElm18 id ->
            let
                validator a =
                    { a | value = Validation.Initial }
            in
            Data Nothing
                { fields
                    | inputTexts = updateDict id (validator >> incrementKeyedId) fields.inputTexts
                    , textareas = updateDict id (validator >> incrementKeyedId) fields.textareas
                }

        SetOptions id options ->
            let
                singleValueValidator oldValue newOptions =
                    case oldValue of
                        Validation.Valid v ->
                            if List.member v (List.map .id newOptions) then
                                oldValue
                            else
                                Validation.Initial

                        _ ->
                            Validation.Initial

                multiValueValidator oldValue newOptions =
                    case oldValue of
                        Validation.Valid v ->
                            let
                                optionIds =
                                    List.map .id newOptions
                                        |> Set.fromList
                            in
                            if Set.isEmpty (Set.diff optionIds v) then
                                oldValue
                            else
                                Validation.Initial

                        _ ->
                            Validation.Initial
            in
            Data Nothing
                { fields
                    | selectLists = updateDict id (updateSelectOptionsField singleValueValidator options) fields.selectLists
                    , radios = updateDict id (updateSelectOptionsField singleValueValidator options) fields.radios
                    , singleButtonSelections = updateDict id (updateSelectOptionsField singleValueValidator options) fields.singleButtonSelections
                    , multiButtonSelections = updateDict id (updateSelectOptionsField multiValueValidator options) fields.multiButtonSelections
                }


{-| Update an autocomplete field in the form.

    updateAutocomplete autoMsg id items formData

-}
updateAutocomplete : Views.Autocomplete.Msg -> id -> List AutocompleteItem -> Data id -> ( Data id, Cmd Views.Autocomplete.Msg )
updateAutocomplete msg id items ((Data formStatus fields) as data) =
    let
        ( autocompletes, cmd ) =
            Dict.get (toKey id) fields.autocompletes
                |> Maybe.map
                    (\field ->
                        let
                            ( autoState, autoCmd ) =
                                Views.Autocomplete.simpleUpdate msg items field.autoState

                            updatedAutoField =
                                updateAutocompleteFieldState autoState field

                            isValidated =
                                case formStatus of
                                    Nothing ->
                                        False

                                    Just _ ->
                                        True

                            validatedAutoField =
                                if field.optionRequired && isValidated then
                                    updateAutocompleteFieldValueWithOptions items updatedAutoField
                                else
                                    updatedAutoField
                        in
                        Dict.insert (toKey id) validatedAutoField fields.autocompletes
                            => autoCmd
                    )
                |> Maybe.withDefault ( fields.autocompletes, Cmd.none )
    in
    Data formStatus
        { fields | autocompletes = autocompletes }
        => cmd


{-| Update all autocomplete fields in this form. Useful when applying keyboard events.

    updateWithKeyboardMsg autoMsg configs formData

-}
updateWithKeyboardMsg : Views.Autocomplete.KeyboardEvents -> Dict String (AutocompleteConfig msg) -> Data id -> ( Data id, Cmd msg )
updateWithKeyboardMsg msg configs (Data _ fields) =
    Dict.foldl
        (\id field ( accDict, accCmds ) ->
            let
                fieldItems =
                    Dict.get id configs
                        |> Maybe.map .items
                        |> Maybe.withDefault []

                fieldCmd msg =
                    Dict.get id configs
                        |> Maybe.map (\{ updateTagger } -> Cmd.map updateTagger msg)
                        |> Maybe.withDefault Cmd.none

                ( newAutoState, autoCmd ) =
                    Views.Autocomplete.simpleUpdate (Views.Autocomplete.UpdateAutocomplete msg) fieldItems field.autoState
                        |> Tuple.mapSecond fieldCmd

                updatedAutoField =
                    updateAutocompleteFieldState newAutoState field
            in
            Dict.insert id updatedAutoField accDict
                => (autoCmd :: accCmds)
        )
        ( Dict.empty, [] )
        fields.autocompletes
        |> Tuple.mapFirst (\autocompletes -> Data Nothing { fields | autocompletes = autocompletes })
        |> Tuple.mapSecond Cmd.batch


updateAutocompleteFieldState : Views.Autocomplete.State -> AutocompleteField id -> AutocompleteField id
updateAutocompleteFieldState state field =
    { field
        | autoState = state
        , value = validateString field.dataType field.options (Views.Autocomplete.text state)
    }


updateAutocompleteFieldValue : String -> AutocompleteField id -> AutocompleteField id
updateAutocompleteFieldValue newValue field =
    { field
        | autoState =
            Views.Autocomplete.simpleUpdate (Views.Autocomplete.SetText newValue) [] field.autoState
                |> Tuple.first
        , value =
            validateString field.dataType field.options newValue
                |> Validation.andThen (validateRequired (Validation.validate Validation.required) field.options)
                |> Validation.mapMessage (\_ -> dataTypeError field.dataType)
    }


updateAutocompleteFieldValueWithOptions : List AutocompleteItem -> AutocompleteField id -> AutocompleteField id
updateAutocompleteFieldValueWithOptions options field =
    { field
        | value =
            field.value
                |> Validation.andThen (Validation.validate (Validation.oneOf options))
    }


type alias HasValue a v =
    { a | value : v, options : FieldConfig }


updateValueById : id -> (HasValue a v -> v) -> Dict String (HasValue a v) -> Dict String (HasValue a v)
updateValueById id f dict =
    updateDict id (updateValue f) dict


updateDict : id -> (v -> v) -> Dict String v -> Dict String v
updateDict id f =
    Dict.update (toKey id) (Maybe.map f)


updateValue : (HasValue a v -> v) -> HasValue a v -> HasValue a v
updateValue f item =
    { item | value = f item }


updateStringField : String -> StringField -> StringField
updateStringField newValue field =
    { field
        | value =
            validateString field.dataType field.options newValue
                |> Validation.andThen (validateRequired (Validation.validate Validation.required) field.options)
                |> Validation.mapMessage (\_ -> dataTypeError field.dataType)
    }


type alias HasSelectOptions a v =
    { a
        | selectOptions : RemoteData String (List SimpleSelectItem)
        , value : v
    }


updateSelectOptionsField : (v -> List SimpleSelectItem -> v) -> RemoteData String (List SimpleSelectItem) -> HasSelectOptions a v -> HasSelectOptions a v
updateSelectOptionsField valueUpdater options field =
    { field
        | selectOptions = options
        , value =
            RemoteData.map (valueUpdater field.value) options
                |> RemoteData.withDefault field.value
    }


validateString : DataType -> { a | required : Bool } -> String -> ValidationResult String
validateString dataType { required } value =
    if not required && String.isEmpty value then
        Validation.Valid value
    else
        Validation.validate (dataTypePattern dataType) value


validateRequired : (v -> ValidationResult v) -> { a | required : Bool } -> v -> ValidationResult v
validateRequired requireValidator { required } value =
    if required then
        requireValidator value
    else
        Validation.valid value


incrementKeyedId : Keyed a -> Keyed a
incrementKeyedId keyed =
    { keyed | keyedId = keyed.keyedId + 1 }


validateIsFloat : String -> ValidationResult Float
validateIsFloat =
    Validation.validate String.toFloat



-- Fields


defaultSelectionLabel : String
defaultSelectionLabel =
    "Select an Option"


defaultSelectionId : Float
defaultSelectionId =
    0


type alias Keyed a =
    { a | keyedId : Int }


toKey : id -> Key
toKey id =
    toString id


{-| Extensible Record that has the select item attributes
-}
type alias SelectItem a =
    { a
        | id : Float
        , label : String
    }


{-| Select item with just the necessary data
-}
type alias SimpleSelectItem =
    { id : Float
    , label : String
    }


{-| Create a SimpleSelectItem out of a record that has an id and a label
-}
toSimpleSelectItem : SelectItem a -> SimpleSelectItem
toSimpleSelectItem { id, label } =
    { id = id, label = label }


simpleSelectionData : RemoteData e (List (SelectItem a)) -> RemoteData e (List SimpleSelectItem)
simpleSelectionData =
    RemoteData.map (List.map toSimpleSelectItem)


type alias StringField =
    { keyedId : Int
    , dataType : DataType
    , value : ValidationResult String
    , options : FieldConfig
    }


type alias AutocompleteField id =
    { dataType : DataType
    , value : ValidationResult String
    , autoState : Views.Autocomplete.State
    , options : FieldConfig
    , id : id
    , optionRequired : Bool
    }


type alias SimpleField value =
    { value : value
    , options : FieldConfig
    }


type alias SelectionField =
    { value : ValidationResult Float
    , selectOptions : RemoteData String (List SimpleSelectItem)
    , options : FieldConfig
    , order : Bool
    , selectOption : Bool
    }


type alias MultiButtonSelectionField =
    { value : ValidationResult (Set Float)
    , selectOptions : RemoteData String (List SimpleSelectItem)
    , options : FieldConfig
    }


type alias CheckboxField =
    { value : Bool
    , title : String
    , options : FieldConfig
    }


type alias LinkField =
    { value : String
    , title : String
    , options : FieldConfig
    }


type alias ButtonField id =
    { title : String
    , buttonId : id
    , options : FieldConfig
    }


dataTypePattern : DataType -> String -> Result String String
dataTypePattern dataType value =
    case dataType of
        StringBasic { minChars, maxChars } ->
            Validation.basicString minChars maxChars value

        StringExtended { minChars, maxChars } ->
            Validation.extendedString minChars maxChars value

        IPv4Address ->
            Validation.ipv4Address value

        Number { minChars, maxChars } ->
            Validation.quantity minChars maxChars value
                |> Result.map toString

        Phone { minChars, maxChars } ->
            Validation.phone minChars maxChars value

        Decimal { minChars, maxChars } ->
            Validation.decimal minChars maxChars value
                |> Result.map toString

        DateOnly ->
            Validation.date value

        Mac ->
            Validation.mac value

        ZipCode ->
            Validation.zipCode value

        Email { minChars, maxChars } ->
            Validation.email minChars maxChars value

        Password ->
            Validation.password value

        Any { minChars, maxChars } ->
            Validation.any minChars maxChars value


dataTypeError : DataType -> String
dataTypeError dataType =
    case dataType of
        StringBasic { minChars, maxChars } ->
            Validation.basicStringError minChars maxChars

        StringExtended { minChars, maxChars } ->
            Validation.extendedStringError minChars maxChars

        IPv4Address ->
            Validation.ipv4Error

        Number { minChars, maxChars } ->
            Validation.quantityError minChars maxChars

        Phone { minChars, maxChars } ->
            Validation.phoneError minChars maxChars

        Decimal { minChars, maxChars } ->
            Validation.decimalError

        DateOnly ->
            Validation.dateError

        Mac ->
            Validation.macError

        ZipCode ->
            Validation.zipCodeError

        Email _ ->
            Validation.emailError

        Password ->
            Validation.passwordError

        Any { minChars, maxChars } ->
            Validation.anyStringError minChars maxChars


{-| Create a field type to represent an input text field.

    inputText MyId (StringBasic { minChars = Just 0, maxChars = Just 15 }) [ label "label" ] ""

-}
inputText : id -> DataType -> List FieldOption -> String -> Field id
inputText id dataType options value =
    let
        validatedValue =
            if String.isEmpty value then
                Validation.Initial
            else
                Validation.validate (dataTypePattern dataType) value

        validation =
            case validatedValue of
                Validation.Invalid _ _ ->
                    Validation.Initial

                Validation.Valid v ->
                    Validation.Valid v

                Validation.Initial ->
                    Validation.Initial
    in
    InputText id
        { keyedId = 0
        , value = validation
        , dataType = dataType
        , options = collectOptions options
        }


{-| Create a field type to represent a checkbox field.

    checkbox MyId [] True "Check me"

-}
checkbox : id -> List FieldOption -> Bool -> String -> Field id
checkbox id options value title =
    Checkbox id
        { value = value
        , title = title
        , options = collectOptions options
        }


{-| Create a field type to represent a text area field.

    textarea MyId (StringExtended { minChars = Just 1, maxChars = Just 20 }) [] "Initial text"

-}
textarea : id -> DataType -> List FieldOption -> String -> Field id
textarea id dataType options value =
    let
        validatedValue =
            if String.isEmpty value then
                Validation.Initial
            else
                Validation.validate (dataTypePattern dataType) value

        validation =
            case validatedValue of
                Validation.Invalid _ _ ->
                    Validation.Initial

                Validation.Valid v ->
                    Validation.Valid v

                Validation.Initial ->
                    Validation.Initial
    in
    Textarea id
        { keyedId = 0
        , value = validation
        , dataType = dataType
        , options = collectOptions options
        }


{-| Create a field type to represent a select list field.
Providing Nothing will use the default select a value selection.

    selectList MyId (RemoteData.succeed [ { id = 1, label = "One" }, { id = 2, label = "Two" } ]) [] Nothing

-}
selectList : id -> RemoteData String (List (SelectItem a)) -> List FieldOption -> Maybe Float -> Field id
selectList id selections options value =
    let
        validation =
            Maybe.map Validation.valid value
                |> Maybe.withDefault Validation.Initial
    in
    SelectList id
        { value = validation
        , selectOptions = simpleSelectionData selections
        , options = collectOptions options
        , order = True
        , selectOption = True
        }


{-| Create a field type to represent a select list field, with options for auto ordering and adding a select option.

    selectList MyId (RemoteData.succeed [ { id = 0, label = "Select one! }, { id = 1, label = "One" }, { id = 2, label = "Two" } ]) False False [] (Just 0)

-}
customSelectList : id -> RemoteData String (List (SelectItem a)) -> Bool -> Bool -> List FieldOption -> Maybe Float -> Field id
customSelectList id selections order selectOption options value =
    let
        validation =
            Maybe.map Validation.valid value
                |> Maybe.withDefault Validation.Initial
    in
    SelectList id
        { value = validation
        , selectOptions = simpleSelectionData selections
        , options = collectOptions options
        , order = order
        , selectOption = selectOption
        }


{-| Create a field type to represent a group of radio buttons.

    radio MyId (RemoteData.succeed [ { id = 1, label = "One" }, { id = 2, label = "Two" } ]) [] (Just 1)

-}
radio : id -> RemoteData String (List (SelectItem a)) -> List FieldOption -> Maybe Float -> Field id
radio id selections options value =
    let
        validation =
            Maybe.map Validation.valid value
                |> Maybe.withDefault Validation.Initial
    in
    Radio id
        { value = validation
        , selectOptions = simpleSelectionData selections
        , options = collectOptions options
        , order = False
        , selectOption = False
        }


{-| Create a field type to represent a bounded quantity picker.
The value is a bounded number for limiting the actual quantity amount.

    quantityPicker MyId [] (BoundedNumber.init 0 max)

-}
quantityPicker : id -> List FieldOption -> BoundedNumber Int -> Field id
quantityPicker id options value =
    QuantityPicker id
        { value = value
        , options = collectOptions options
        }


{-| Create a field type to represent a link field.

    link MyId [] "My Link" "hrefUrl"

-}
link : id -> List FieldOption -> String -> String -> Field id
link id options title value =
    Link id
        { value = value
        , title = title
        , options = collectOptions options
        }


{-| Create a field type to represent a group of buttons that allow for only one selection.
Providing Nothing will use the default select a value seleciton.

    singleButtonSelection MyId (RemoteData.succeed [ { id = 1, label = "One" }, { id = 2, label = "Two" } ]) [] Nothing

-}
singleButtonSelection : id -> RemoteData String (List (SelectItem a)) -> List FieldOption -> Maybe Float -> Field id
singleButtonSelection id selections options value =
    let
        optionRecord =
            collectOptions options

        validation =
            Maybe.map toString value
                |> Maybe.map (Validation.validate Validation.required)
                |> Maybe.map (Validation.andThen validateIsFloat)
                |> Maybe.withDefault Validation.Initial
    in
    SingleButtonSelection id
        { value = validation
        , selectOptions = simpleSelectionData selections
        , options = optionRecord
        , order = False
        , selectOption = False
        }


{-| Create a field type to represent a group of buttons that allow for multiple selections.
Providing Nothing will use the default select a value seleciton.

    multiButtonSelection MyId (RemoteData.succeed [ { id = 1, label = "One" }, { id = 2, label = "Two" } ]) [] Nothing

-}
multiButtonSelection : id -> RemoteData String (List (SelectItem a)) -> List FieldOption -> Maybe (Set Float) -> Field id
multiButtonSelection id selections options value =
    let
        validation =
            Maybe.map (\selected -> Validation.validate (Validation.nonEmptySet selected) "") value
                |> Maybe.withDefault Validation.Initial
    in
    MultiButtonSelection id
        { value = validation
        , selectOptions = simpleSelectionData selections
        , options = collectOptions options
        }


{-| Create a field that has text input and autocomplete suggestions.

    autocomplete MyId StringExtended [] (Autocomplete.init 5 "initial text")

-}
autocomplete : id -> DataType -> List FieldOption -> Views.Autocomplete.State -> Field id
autocomplete id dataType options autoState =
    Autocomplete id (autocompleteData False id dataType options autoState)


{-| Create a field that has text input and autocomplete suggestions, but also requires an option to be an item from the list.

    autocomplete MyId StringExtended [] (Autocomplete.init 5 "initial text")

-}
autocompleteForOptions : id -> DataType -> List FieldOption -> Views.Autocomplete.State -> Field id
autocompleteForOptions id dataType options autoState =
    Autocomplete id (autocompleteData True id dataType options autoState)


autocompleteData : Bool -> id -> DataType -> List FieldOption -> Views.Autocomplete.State -> AutocompleteField id
autocompleteData optionRequired id dataType options autoState =
    let
        initialText =
            Views.Autocomplete.text autoState

        validatedValue =
            Validation.validate (dataTypePattern dataType) initialText

        validation =
            case validatedValue of
                Validation.Invalid _ _ ->
                    Validation.Initial

                Validation.Valid v ->
                    Validation.Valid v

                Validation.Initial ->
                    Validation.Initial
    in
    { value = validation
    , dataType = dataType
    , autoState = autoState
    , options = collectOptions options
    , id = id
    , optionRequired = optionRequired
    }


{-| Create a field type to represent a button.

    button MyId [] "Submit"

-}
button : id -> List FieldOption -> String -> Field id
button id options title =
    Button id
        { buttonId = id
        , title = title
        , options = collectOptions options
        }


{-| Create a custom field to be rendered with a custom renderer.
-}
custom : id -> Field id
custom id =
    Custom id


{-| Opaque type that has data to represent a form field
-}
type Field id
    = InputText id StringField
    | Checkbox id CheckboxField
    | Textarea id StringField
    | SelectList id SelectionField
    | Radio id SelectionField
    | QuantityPicker id (SimpleField (BoundedNumber Int))
    | Link id LinkField
    | SingleButtonSelection id SelectionField
    | MultiButtonSelection id MultiButtonSelectionField
    | Button id (ButtonField id)
    | Autocomplete id (AutocompleteField id)
    | Custom id



-- Field Options


{-| Opaque type that represents an option for a field
-}
type FieldOption
    = Label String
    | Required Bool
    | ValidMessage (Maybe String)
    | InvalidMessage (Maybe String)
    | WarningMessage (Maybe String)
    | HelpText String
    | MaxLength (Maybe Int)


{-| Field option to add a label to the field
-}
label : String -> FieldOption
label text =
    Label text


{-| Field option to state if this field requires the user to act upon on it. Defaults to False
-}
required : Bool -> FieldOption
required isRequired =
    Required isRequired


{-| Field option to specify the invalid text if the field is an invalid state. Defaults to standard invalidation texts.
-}
invalidMessage : Maybe String -> FieldOption
invalidMessage text =
    InvalidMessage text


{-| Field option to specify the valid text if the field is a valid state. Defaults to no valid text.
-}
validMessage : Maybe String -> FieldOption
validMessage text =
    ValidMessage text


{-| Field option specify if there should be text in the warning state. Defaults to no warning text.
-}
warningMessage : Maybe String -> FieldOption
warningMessage text =
    WarningMessage text


{-| Field option for adding help text to a field.
-}
helpText : String -> FieldOption
helpText text =
    HelpText text


{-| Field options for maxlength, currently only implemented for quantityPicker and inputText
-}
maxlength : Int -> FieldOption
maxlength int =
    MaxLength (Just int)


type alias FieldConfig =
    { label : Maybe String
    , required : Bool
    , invalidMessage : Maybe String
    , validMessage : Maybe String
    , warningMessage : Maybe String
    , helpText : Maybe String
    , maxlength : Maybe Int
    }


{-| Options for a DataType
-}
type alias DataTypeOptions a =
    { minChars : Maybe a
    , maxChars : Maybe a
    }


{-| Data types that are used for validating text input
-}
type DataType
    = StringBasic (DataTypeOptions Int)
    | StringExtended (DataTypeOptions Int)
    | IPv4Address
    | Number (DataTypeOptions Int)
    | Phone (DataTypeOptions Int)
    | Decimal (DataTypeOptions Float)
    | DateOnly
    | Mac
    | ZipCode
    | Email (DataTypeOptions Int)
    | Password
    | Any (DataTypeOptions Int)


{-| Represents an autocomplete drop down item.
-}
type alias AutocompleteItem =
    { id : Float
    , label : String
    }


defaultConfig : FieldConfig
defaultConfig =
    { label = Nothing
    , required = False
    , invalidMessage = Nothing
    , validMessage = Nothing
    , warningMessage = Nothing
    , helpText = Nothing
    , maxlength = Nothing
    }


collectOptions : List FieldOption -> FieldConfig
collectOptions =
    List.foldl
        (\option config ->
            case option of
                Label label ->
                    { config | label = Just label }

                Required required ->
                    { config | required = required }

                HelpText value ->
                    { config | helpText = Just value }

                WarningMessage message ->
                    { config | warningMessage = message }

                ValidMessage message ->
                    { config | validMessage = message }

                InvalidMessage message ->
                    { config | invalidMessage = message }

                MaxLength value ->
                    { config | maxlength = value }
        )
        defaultConfig



-- Layout


{-| Opaque type that represents a row of form columns.
-}
type Row id msg
    = Row (List (Bootstrap.Grid.Row.Option msg)) (List (Col id msg))


{-| Opaque type that represents a column of Form Fields
-}
type Col id msg
    = Column (List (Bootstrap.Grid.Col.Option msg)) (List id)


{-| Create a row of columns.

    row [] [ col [] [ Field1Id, Field2Id ]

-}
row : List (Bootstrap.Grid.Row.Option msg) -> List (Col id msg) -> Row id msg
row options columns =
    Row options columns


{-| Create a column for rendering form fields with the given id.

    col [ Col.xs12 ] [ Field1Id ]

-}
col : List (Bootstrap.Grid.Col.Option msg) -> List id -> Col id msg
col options fieldIds =
    Column options fieldIds


{-| Layout all fields in a single vertical column.

    view config
        (oneColumn [ Field1Id, Field2Id ])
        formData

-}
oneColumn : List id -> List (Row id msg)
oneColumn fieldIds =
    List.map (\fieldId -> row [] [ col [] [ fieldId ] ]) fieldIds


{-| Layout all fields in a single vertical column.

    view config
        (twoColumn
            [ Field1Id, Field2Id ]
            [ Field3Id ]
        )
        formData

-}
twoColumn : List id -> List id -> List (Row id msg)
twoColumn firstColumns secondColumns =
    []



-- View


{-| View a form by providing a configuration and layout scheme for fields.

    view config
        [ row [] [ col [] [ Field1Id, Field2Id ] ]
        , row [] [ col [] [ Field3Id ] ]
        ]
        formData

-}
view : ViewConfig id msg -> List (Row id msg) -> Data id -> Html msg
view config rows data =
    let
        customRenderer =
            \_ -> Html.text ""
    in
    customView config customRenderer rows data


{-| View a form by providing a configuration, a layout scheme, and a renderer for if customer views are used.

    view config
        (\id -> renderCustomElement id )
        [ row [] [ col [] [ Field1Id, Field2Id ] ]
        , row [] [ col [] [ Field3Id ] ]
        ]
        formData

-}
customView : ViewConfig id msg -> (id -> Html msg) -> List (Row id msg) -> Data id -> Html msg
customView config customRenderer rows ((Data validForm fields) as data) =
    let
        messageWrapper message =
            Maybe.map (\msg -> nbsp ++ " " ++ msg) message
                |> Maybe.withDefault ""

        alert valid =
            case valid of
                Valid ->
                    Alert.success
                        [ FA.check
                        , Html.text nbsp
                        , Html.text <| messageWrapper config.validFormBanner
                        ]

                Invalid ->
                    Alert.danger
                        [ FA.exclamation_triangle
                        , Html.text nbsp
                        , Html.text <| messageWrapper config.invalidFormBanner
                        ]

        formValidationBanner =
            Maybe.map alert validForm
                |> Maybe.withDefault (Html.text "")
    in
    Grid.containerFluid [ Attrs.style [ ( "padding", "0px" ) ] ]
        [ formValidationBanner
        , Bootstrap.Form.form config.attrs (List.map (renderRow config customRenderer data) rows)
        ]


{-| Configuration for a view. Message for updates, button clicks, and ids that should be rendered as non editable.
-}
type alias ViewConfig id msg =
    { updateTagger : SimpleMsg id -> msg
    , buttonConfig : id -> Maybe (ButtonConfig msg)
    , readOnlyFields : List id
    , autocompleteConfig : id -> Maybe (AutocompleteConfig msg)
    , validFormBanner : Maybe String
    , invalidFormBanner : Maybe String
    , attrs : List (Html.Attribute msg)
    }


{-| Configuration for a button to render
-}
type alias ButtonConfig msg =
    { tagger : msg
    , icon : Maybe (Html msg)
    , primary : Bool
    , attrs : List (Html.Attribute msg)
    }


{-| Make the element start at the ride side of the column instead of the left
-}
rightAligned : Html.Attribute msg
rightAligned =
    Attrs.class "ml-sm-2 my-2 pull-right"


{-| Sets the button type as button. Helpful for removing default onSubmit action
-}
buttonType : Html.Attribute msg
buttonType =
    Attrs.type_ "button"


{-| Configuration for an autocomplete view. Used for providing the right message and drop down items for a given view.
-}
type alias AutocompleteConfig msg =
    { updateTagger : Views.Autocomplete.Msg -> msg
    , items : List AutocompleteItem
    }



-- Rendering


renderRow : ViewConfig id msg -> (id -> Html msg) -> Data id -> Row id msg -> Html msg
renderRow config customRenderer data (Row rowOptions columns) =
    Bootstrap.Form.row rowOptions (List.map (renderCol config customRenderer data) columns)


renderCol : ViewConfig id msg -> (id -> Html msg) -> Data id -> Col id msg -> Bootstrap.Form.Col msg
renderCol config customRenderer data (Column colOptions fieldIds) =
    Bootstrap.Form.col colOptions (List.map (renderField config customRenderer data) fieldIds)


renderField : ViewConfig id msg -> (id -> Html msg) -> Data id -> id -> Html msg
renderField config customRenderer data fieldId =
    let
        fieldById =
            getField fieldId data

        readOnly =
            List.member fieldId config.readOnlyFields

        updater =
            config.updateTagger
    in
    case fieldById of
        Nothing ->
            Html.text ""

        Just field ->
            case field of
                InputText id fieldData ->
                    renderInputField id readOnly updater fieldData
                        |> renderLabels fieldData.value fieldData.options
                        |> toValidatedGroup (validationValue readOnly fieldData.value)

                Checkbox id fieldData ->
                    renderCheckbox id readOnly updater fieldData
                        |> renderLabels Validation.Initial fieldData.options
                        |> toGroup

                Textarea id fieldData ->
                    renderTextarea id readOnly updater fieldData
                        |> renderLabels fieldData.value fieldData.options
                        |> toValidatedGroup (validationValue readOnly fieldData.value)

                Radio id fieldData ->
                    renderRadio id readOnly updater fieldData
                        |> renderLabels fieldData.value fieldData.options
                        |> toValidatedGroup (validationValue readOnly fieldData.value)

                SelectList id fieldData ->
                    renderSelectList id readOnly updater fieldData
                        |> renderLabels fieldData.value fieldData.options
                        |> toValidatedGroup (validationValue readOnly fieldData.value)

                QuantityPicker id fieldData ->
                    renderQuantityPicker id readOnly updater fieldData
                        |> renderLabels Validation.Initial fieldData.options
                        |> toGroup

                Link id fieldData ->
                    renderLink id readOnly fieldData
                        |> renderLabels Validation.Initial fieldData.options
                        |> toGroup

                SingleButtonSelection id fieldData ->
                    renderSingleButtonSelectionField id readOnly updater fieldData
                        |> renderLabels fieldData.value fieldData.options
                        |> toValidatedGroup (validationValue readOnly fieldData.value)

                MultiButtonSelection id fieldData ->
                    renderMultiButtonSelectionField id readOnly updater fieldData
                        |> renderLabels fieldData.value fieldData.options
                        |> toValidatedGroup (validationValue readOnly fieldData.value)

                Button id fieldData ->
                    case config.buttonConfig id of
                        Nothing ->
                            Html.text ""

                        Just buttonConfig ->
                            let
                                button =
                                    renderButton id readOnly buttonConfig fieldData
                            in
                            case fieldData.options.label of
                                Nothing ->
                                    button

                                Just _ ->
                                    button
                                        |> renderLabels Validation.Initial fieldData.options
                                        |> toGroup

                Autocomplete id fieldData ->
                    case config.autocompleteConfig id of
                        Nothing ->
                            Html.text ""

                        Just autoConfig ->
                            renderAutocompleteField id readOnly autoConfig fieldData
                                |> renderLabels fieldData.value fieldData.options
                                |> toValidatedGroup (validationValue readOnly fieldData.value)

                Custom id ->
                    customRenderer id


renderInputField : id -> Bool -> (SimpleMsg id -> msg) -> StringField -> Html msg
renderInputField id readOnly tagger data =
    let
        value =
            Validation.toString identity data.value

        inputType =
            case data.dataType of
                Password ->
                    Bootstrap.Form.Input.password

                _ ->
                    Bootstrap.Form.Input.text
    in
    inputType
        [ Bootstrap.Form.Input.attrs (constructAttrs readOnly data.options)
        , Bootstrap.Form.Input.small
        , Bootstrap.Form.Input.defaultValue value
        , Bootstrap.Form.Input.onInput (tagger << OnTextChange id)
        ]
        |> keyedDiv data.keyedId


renderTextarea : id -> Bool -> (SimpleMsg id -> msg) -> StringField -> Html msg
renderTextarea id readOnly tagger data =
    Bootstrap.Form.Textarea.textarea
        [ Bootstrap.Form.Textarea.attrs [ Attrs.readonly readOnly ]
        , Bootstrap.Form.Textarea.defaultValue (Validation.toString identity data.value)
        , Bootstrap.Form.Textarea.onInput (tagger << OnTextChange id)
        ]
        |> keyedDiv data.keyedId


renderCheckbox : id -> Bool -> (SimpleMsg id -> msg) -> CheckboxField -> Html msg
renderCheckbox id readOnly tagger data =
    Bootstrap.Form.Checkbox.checkbox
        [ Bootstrap.Form.Checkbox.checked data.value
        , Bootstrap.Form.Checkbox.disabled readOnly
        , Bootstrap.Form.Checkbox.onCheck (tagger << SetChecked id)
        ]
        data.title


renderRadio : id -> Bool -> (SimpleMsg id -> msg) -> SelectionField -> Html msg
renderRadio id readOnly tagger data =
    Views.Remote.simple
        { error = "Error loading options"
        , loading = "loading.."
        , remote =
            RemoteData.map
                (\options ->
                    List.map
                        (\option ->
                            Bootstrap.Form.Radio.create
                                [ Bootstrap.Form.Radio.onClick (tagger <| SetRadioSelection id option.id)
                                , Bootstrap.Form.Radio.checked <| Validation.valid option.id == data.value
                                , Bootstrap.Form.Radio.inline
                                ]
                                option.label
                        )
                        options
                )
                data.selectOptions
                |> RemoteData.map (Bootstrap.Form.Radio.radioList "")
                |> RemoteData.map (Html.div [])
        }


renderSelectList : id -> Bool -> (SimpleMsg id -> msg) -> SelectionField -> Html msg
renderSelectList id readOnly tagger data =
    let
        default =
            { id = defaultSelectionId, label = defaultSelectionLabel }

        appendDuplicateNumbers =
            List.indexedMap
                (\i item ->
                    if i > 1 then
                        { item | label = item.label ++ "(" ++ toString i ++ ")" }
                    else
                        item
                )

        sortById =
            List.sortBy .id

        providedOptions =
            RemoteData.withDefault [] data.selectOptions

        handleDuplicates options =
            List.Extra.groupWhile (\a b -> a.label == b.label) options
                |> List.map (sortById >> appendDuplicateNumbers)
                |> List.concat

        filterDefaultLabel options =
            List.filter (\option -> option.label /= defaultSelectionLabel) options

        options =
            if data.order && data.selectOption then
                providedOptions
                    |> filterDefaultLabel
                    |> handleDuplicates
                    |> List.sortBy .label
                    |> (::) default
            else if data.order then
                providedOptions
                    |> handleDuplicates
                    |> List.sortBy .label
            else if data.selectOption then
                providedOptions
                    |> filterDefaultLabel
                    |> handleDuplicates
                    |> (::) default
            else
                handleDuplicates providedOptions

        value =
            case data.value of
                Validation.Valid v ->
                    v

                Validation.Invalid _ last ->
                    String.toFloat last
                        |> Result.withDefault default.id

                Validation.Initial ->
                    if data.selectOption then
                        default.id
                    else
                        List.head providedOptions
                            |> Maybe.map .id
                            |> Maybe.withDefault 0

        selectedTitle =
            List.filter (\option -> option.id /= defaultSelectionId) options
                |> List.Extra.find (\option -> option.id == value)
                |> Maybe.map .label
                |> Maybe.withDefault ""

        selectList =
            Bootstrap.Form.Select.select
                [ Bootstrap.Form.Select.small
                , Bootstrap.Form.Select.onChange (tagger << SetSelectListSelection id << Result.withDefault defaultSelectionId << String.toFloat)
                , Bootstrap.Form.Select.attrs [ Attrs.value (toString value) ]
                ]
                (List.map
                    (\option ->
                        Bootstrap.Form.Select.item
                            [ Attrs.value (toString option.id)
                            , Attrs.selected (option.id == value)
                            ]
                            [ Html.text option.label ]
                    )
                    options
                )
    in
    if readOnly then
        Bootstrap.Form.Input.text
            [ Bootstrap.Form.Input.attrs [ Attrs.readonly True ]
            , Bootstrap.Form.Input.small
            , Bootstrap.Form.Input.value selectedTitle
            ]
    else
        Views.Remote.simple
            { error = "Error loading options"
            , loading = "loading.."
            , remote = RemoteData.map (\_ -> selectList) data.selectOptions
            }


renderLink : id -> Bool -> LinkField -> Html msg
renderLink id readOnly data =
    Html.a [ Attrs.disabled readOnly, Attrs.href data.value ] [ Html.text data.title ]


renderButton : id -> Bool -> ButtonConfig msg -> ButtonField id -> Html msg
renderButton id readOnly { tagger, icon, primary, attrs } data =
    let
        children =
            case icon of
                Just i ->
                    [ Html.text data.title, Html.text nbsp, Icon.basicIcon i False ]

                Nothing ->
                    [ Html.text data.title ]

        primaryAttr =
            if primary then
                Just Button.primary
            else
                Just Button.secondary

        attributes =
            Util.justValues
                [ Just Button.small
                , Just Button.secondary
                , Just <| Button.disabled readOnly
                , Just <| Button.onClick tagger
                , Just <| Button.attrs attrs
                , primaryAttr
                ]
    in
    Button.button
        attributes
        children


renderQuantityPicker : id -> Bool -> (SimpleMsg id -> msg) -> SimpleField (BoundedNumber Int) -> Html msg
renderQuantityPicker id readOnly tagger data =
    let
        value =
            Bounded.value data.value
                |> toString

        decrement =
            InputGroup.button [ Button.secondary, Button.onClick (tagger <| DecrementQuantity id) ] [ Html.text "-" ]

        increment =
            InputGroup.button [ Button.secondary, Button.onClick (tagger <| IncrementQuantity id) ] [ Html.text "+" ]

        textField =
            InputGroup.text
                [ Bootstrap.Form.Input.attrs (constructAttrs readOnly data.options)
                , Bootstrap.Form.Input.small
                , Bootstrap.Form.Input.value value
                , Bootstrap.Form.Input.onInput (tagger << SetQuantity id)
                ]
    in
    InputGroup.config textField
        |> InputGroup.small
        |> InputGroup.predecessors [ decrement ]
        |> InputGroup.successors [ increment ]
        |> InputGroup.view


constructAttrs : Bool -> FieldConfig -> List (Html.Attribute msg)
constructAttrs readonly config =
    case config.maxlength of
        Just number ->
            [ Attrs.readonly readonly, Attrs.maxlength number ]

        Nothing ->
            [ Attrs.readonly readonly ]


renderSingleButtonSelectionField : id -> Bool -> (SimpleMsg id -> msg) -> SelectionField -> Html msg
renderSingleButtonSelectionField id readOnly tagger data =
    let
        value =
            Validation.withDefault 0 data.value

        buttonGroup options =
            List.map
                (\option ->
                    ButtonGroup.radioButton (value == option.id)
                        [ Button.primary
                        , Button.onClick (tagger <| SetSingleSelection id option.id)
                        ]
                        [ Html.text option.label ]
                )
                options
                |> ButtonGroup.radioButtonGroup [ ButtonGroup.small ]
    in
    Views.Remote.simple
        { error = "Error loading options"
        , loading = "loading.."
        , remote = RemoteData.map buttonGroup data.selectOptions
        }


renderMultiButtonSelectionField : id -> Bool -> (SimpleMsg id -> msg) -> MultiButtonSelectionField -> Html msg
renderMultiButtonSelectionField id readOnly tagger data =
    let
        value =
            Validation.withDefault Set.empty data.value

        buttonGroup options =
            List.map
                (\option ->
                    let
                        selected =
                            Set.member option.id value

                        updatedSet =
                            if selected then
                                Set.remove option.id value
                            else
                                Set.insert option.id value
                    in
                    ButtonGroup.checkboxButton (Set.member option.id value)
                        [ Button.primary
                        , Button.onClick (tagger <| SetMutliSelected id updatedSet)
                        ]
                        [ Html.text option.label ]
                )
                options
                |> ButtonGroup.checkboxButtonGroup [ ButtonGroup.small ]
    in
    Views.Remote.simple
        { error = "Error loading options"
        , loading = "loading.."
        , remote = RemoteData.map buttonGroup data.selectOptions
        }


renderAutocompleteField : id -> Bool -> AutocompleteConfig msg -> AutocompleteField id -> Html msg
renderAutocompleteField id readOnly config data =
    Views.Autocomplete.viewWithConfig
        { menuConfig = Views.Autocomplete.simpleMenuViewConfig
        , options = [ Bootstrap.Form.Input.small, Bootstrap.Form.Input.disabled readOnly ]
        , tagger = config.updateTagger
        }
        config.items
        data.autoState


keyedDiv : Int -> Html msg -> Html msg
keyedDiv keyedId element =
    Keyed.node "div"
        []
        [ ( toString keyedId, element ) ]


renderLabels :
    ValidationResult v
    ->
        { a
            | label : Maybe String
            , helpText : Maybe String
            , validMessage : Maybe String
            , invalidMessage : Maybe String
        }
    -> Html msg
    -> List (Html msg)
renderLabels validation { label, helpText, validMessage, invalidMessage } element =
    let
        labelElement =
            Maybe.map textLabel label

        helpTextElement =
            Maybe.map helpLabel helpText

        validationText =
            case validation of
                Validation.Valid _ ->
                    validMessage

                Validation.Invalid e _ ->
                    Maybe.withDefault e invalidMessage
                        |> Just

                Validation.Initial ->
                    Nothing

        validationElement =
            Maybe.map validationLabel validationText

        children =
            Util.justValues [ labelElement, Just element, validationElement, helpTextElement ]
    in
    children


validationValue : Bool -> ValidationResult a -> ValidationResult a
validationValue readOnly value =
    if readOnly then
        Validation.Initial
    else
        value


toValidatedGroup : ValidationResult a -> List (Html msg) -> Html msg
toValidatedGroup validation =
    let
        validationGroup =
            case validation of
                Validation.Invalid _ _ ->
                    [ Bootstrap.Form.groupDanger ]

                Validation.Valid _ ->
                    [ Bootstrap.Form.groupSuccess ]

                Validation.Initial ->
                    []
    in
    Bootstrap.Form.group validationGroup


toGroup : List (Html msg) -> Html msg
toGroup =
    Bootstrap.Form.group []


textLabel : String -> Html msg
textLabel label =
    Bootstrap.Form.label [] [ Html.text label ]


helpLabel : String -> Html msg
helpLabel label =
    Bootstrap.Form.help [] [ Html.text label ]


validationLabel : String -> Html msg
validationLabel label =
    Bootstrap.Form.validationText [] [ Html.text label ]
