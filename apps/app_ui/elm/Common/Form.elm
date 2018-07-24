module Common.Form exposing (ColumnLayout(..), Context, Data, LayoutType(..), ValidStatus(..), emptyContext, getFieldValue, getFormFieldData, update, updateFields, validateAll, view)

import Autocomplete
import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.Card as Card
import Bootstrap.Form as Form
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Form.Select as Select
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Common.Form.Button as Button
import Common.Form.Field as Field
import Common.Icons as Icon
import Common.Role exposing (Role(..))
import Exts.Html exposing (nbsp)
import Exts.List exposing (chunk)
import FontAwesome.Web as FA
import Html exposing (Html, div, i, span, text)
import Html.Attributes exposing (autocomplete, class, maxlength, readonly, selected, size, style, value)
import Html.Events exposing (onClick, onInput, onWithOptions)
import Html.Keyed as Keyed
import Json.Decode as Decode exposing (Decoder)
import Set exposing (Set)
import Util exposing ((=>), justValues, onChange)


type ValidStatus
    = Initial
    | Valid
    | NotValid


type LayoutType
    = Standard
    | Inline


type ColumnLayout
    = OneColumn
    | TwoColumn
    | ThreeColumn


type alias Data msg id =
    { validation : ValidationStatus
    , fields : List (List (Field.Data msg id))
    , buttons : List (Button.Data msg)
    , layoutType : LayoutType
    , columnLayout : ColumnLayout
    , onSubmit : msg
    }


type alias ValidationStatus =
    { isValid : ValidStatus
    , message : Maybe String
    , role : Maybe Role
    }


type alias Context msg id =
    { autocompleteMenus : List ( id, Html msg )
    }


emptyContext : Context msg id
emptyContext =
    { autocompleteMenus = [] }


view context form =
    let
        { isValid, message, role } =
            form.validation

        messageWrapper msg =
            nbsp ++ " " ++ msg

        alert =
            case ( isValid, message, role ) of
                ( _, Just msg, Nothing ) ->
                    alertType Info
                        [ alertIcon Info
                        , text nbsp
                        , text <| messageWrapper msg
                        ]

                ( _, Just msg, Just role_ ) ->
                    alertType role_
                        [ alertIcon role_
                        , text nbsp
                        , text <| messageWrapper msg
                        ]

                ( _, _, _ ) ->
                    text ""

        formInner =
            buildFields context form
    in
    div [] [ alert, formInner ]


buildFields context form =
    let
        formOuter =
            case form.layoutType of
                Standard ->
                    Form.form

                Inline ->
                    Form.formInline

        fieldCount =
            List.length form.fields

        columns =
            case form.columnLayout of
                OneColumn ->
                    [ form.fields ]

                TwoColumn ->
                    chunk ((fieldCount |> toFloat) / 2 |> round) form.fields

                ThreeColumn ->
                    chunk ((fieldCount |> toFloat) / 3 |> round) form.fields
    in
    div []
        (List.concat
            [ formOuter [] (List.map (buildRow context) form.fields) |> List.singleton
            , [ Grid.row []
                    [ Grid.col [] (List.map buildButton form.buttons) ]
              ]
            ]
        )


getViewMenu context field =
    Exts.List.firstMatch (\( id, _ ) -> id == field.id) context.autocompleteMenus
        |> Maybe.map Tuple.second
        |> Maybe.withDefault (Html.text "")


buildButton options =
    let
        classes =
            "ml-sm-2 my-2 pull-right"

        attrs =
            case options.onClick of
                Nothing ->
                    [ class classes ]

                Just onClickAction ->
                    [ class classes, onClick onClickAction ]
    in
    Button.button
        [ options.typeStyle
        , Button.small
        , Button.attrs attrs
        ]
        [ text options.label, text nbsp, Icon.basicIcon options.icon False ]


buildRow context fields =
    Grid.row []
        (List.map
            (buildColumn context)
            fields
        )


buildColumn context field =
    let
        colAttrs =
            case field.columnSizes of
                Nothing ->
                    []

                Just sizes ->
                    [ Col.attrs [ class sizes ] ]
    in
    Grid.col colAttrs
        [ span
            []
            [ buildField context field ]
        ]


buildField context field =
    case field.fieldType of
        Field.Text ->
            buildTextField field

        Field.ViewOnly ->
            buildViewOnlyField field

        Field.SelectList ->
            buildSelectField field

        Field.Quantity ->
            buildQuantityField field

        Field.Autocomplete ->
            buildAutocompleteField (getViewMenu context field) field

        Field.Link ->
            buildLinkField field

        Field.ControlGroup selection buttonTitles ->
            buildControlGroupField field selection buttonTitles

        _ ->
            buildTextField field


buildTextField field =
    let
        ( groupConfig, inputRoleConfig ) =
            case field.validation.role of
                Nothing ->
                    [] => []

                Just role ->
                    buildGroupConfig role => buildInputRole role

        validationText currentList =
            case ( field.validation.isValid, field.validation.message ) of
                ( _, Nothing ) ->
                    currentList

                ( Field.Initial, _ ) ->
                    currentList

                ( _, Just msg ) ->
                    List.concat [ currentList, [ Form.validationText [] [ text msg ] ] ]

        labelElement currentList =
            case field.label of
                Nothing ->
                    currentList

                Just value ->
                    List.concat [ currentList, [ Form.label [] [ text value ] ] ]

        onUpdateHandler currentList =
            case ( field.onUpdate, field.fieldType ) of
                ( Nothing, _ ) ->
                    currentList

                ( Just handler, fieldType ) ->
                    Input.attrs [ onInput handler ] :: currentList

        buildStyle currentList =
            case field.max of
                Nothing ->
                    currentList

                Just max ->
                    currentList

        --                    style
        --                        [ ( "min-width", "80px" )
        --                        , ( "width", max |> toFieldWidth )
        --                        ]
        --                        :: currentList
        maxAttr currentList =
            case ( field.max, field.dataType ) of
                ( Nothing, Field.IPv4Address ) ->
                    List.concat
                        [ currentList
                        , [ Input.attrs
                                [ maxlength 15
                                , style
                                    [ ( "width", 15 |> toFieldWidth ) ]
                                ]
                          ]
                        ]

                ( Nothing, Field.DateOnly ) ->
                    List.concat
                        [ currentList
                        , [ Input.attrs
                                [ maxlength 10
                                , style
                                    [ ( "width", 7 |> toFieldWidth ) ]
                                ]
                          ]
                        ]

                ( Nothing, Field.Mac ) ->
                    List.concat
                        [ currentList
                        , [ Input.attrs
                                [ maxlength 17
                                , style
                                    [ ( "width", 10 |> toFieldWidth ) ]
                                ]
                          ]
                        ]

                ( Just max, _ ) ->
                    List.concat
                        [ currentList
                        , [ Input.attrs
                                ([ maxlength max ] |> buildStyle)
                          ]
                        ]

                ( Nothing, _ ) ->
                    currentList

        inputType =
            case field.dataType of
                Field.Password ->
                    Input.password

                _ ->
                    Input.text

        fieldElement currentList =
            List.concat
                [ currentList
                , [ Keyed.node "div"
                        []
                        [ ( toString field.keyedId
                          , inputType
                                (List.concat
                                    [ inputRoleConfig
                                    , []
                                        |> onUpdateHandler
                                        |> maxAttr
                                    , [ Input.small, Input.defaultValue field.value ]
                                    ]
                                )
                          )
                        ]
                  ]
                ]
    in
    Form.group groupConfig
        ([]
            |> labelElement
            |> fieldElement
            |> validationText
        )


buildViewOnlyField field =
    let
        labelElement currentList =
            case field.label of
                Nothing ->
                    currentList

                Just value ->
                    List.concat [ currentList, [ Form.label [] [ text value ] ] ]

        buildStyle currentList =
            case field.max of
                Nothing ->
                    currentList

                Just max ->
                    currentList

        maxAttr currentList =
            case ( field.max, field.dataType ) of
                ( Nothing, Field.IPv4Address ) ->
                    List.concat
                        [ currentList
                        , [ Input.attrs
                                [ maxlength 15
                                , style
                                    [ ( "width", 15 |> toFieldWidth ) ]
                                ]
                          ]
                        ]

                ( Nothing, Field.DateOnly ) ->
                    List.concat
                        [ currentList
                        , [ Input.attrs
                                [ maxlength 10
                                , style
                                    [ ( "width", 7 |> toFieldWidth ) ]
                                ]
                          ]
                        ]

                ( Nothing, Field.Mac ) ->
                    List.concat
                        [ currentList
                        , [ Input.attrs
                                [ maxlength 17
                                , style
                                    [ ( "width", 10 |> toFieldWidth ) ]
                                ]
                          ]
                        ]

                ( Just max, _ ) ->
                    List.concat
                        [ currentList
                        , [ Input.attrs
                                ([ maxlength max ] |> buildStyle)
                          ]
                        ]

                ( Nothing, _ ) ->
                    currentList

        inputAttrs =
            Util.justValues [ Just <| readonly True ]

        fieldElement currentList =
            List.concat
                [ currentList
                , [ Keyed.node "div"
                        []
                        [ ( toString field.keyedId
                          , Input.text
                                (List.concat
                                    [ [ Input.attrs inputAttrs ]
                                        |> maxAttr
                                    , [ Input.small, Input.defaultValue field.value ]
                                    ]
                                )
                          )
                        ]
                  ]
                ]
    in
    Form.group []
        ([]
            |> labelElement
            |> fieldElement
        )


buildSelectField field =
    let
        ( groupConfig, selectRoleConfig ) =
            case field.validation.role of
                Nothing ->
                    [] => []

                Just role ->
                    buildGroupConfig role => buildSelectRole role

        validationText currentList =
            case ( field.validation.isValid, field.validation.message ) of
                ( _, Nothing ) ->
                    currentList

                ( Field.Initial, _ ) ->
                    currentList

                ( _, Just msg ) ->
                    List.concat [ currentList, [ Form.validationText [] [ text msg ] ] ]

        labelElement currentList =
            case field.label of
                Nothing ->
                    currentList

                Just value ->
                    List.concat [ currentList, [ Form.label [] [ text value ] ] ]

        onUpdateHandler currentList =
            case field.onUpdate of
                Nothing ->
                    currentList

                Just handler ->
                    Select.attrs [ onChange handler ] :: currentList

        buildStyle currentList =
            case field.max of
                Nothing ->
                    currentList

                Just max ->
                    currentList

        --                    style
        --                        [ ( "min-width", "80px" )
        --                        , ( "width", max |> toFieldWidth )
        --                        ]
        --                        :: currentList
        maxAttr currentList =
            case ( field.max, field.dataType ) of
                ( Nothing, Field.IPv4Address ) ->
                    List.concat
                        [ currentList
                        , [ Select.attrs
                                [ maxlength 15
                                , style
                                    [ ( "width", 15 |> toFieldWidth ) ]
                                ]
                          ]
                        ]

                ( Nothing, Field.DateOnly ) ->
                    List.concat
                        [ currentList
                        , [ Select.attrs
                                [ maxlength 10
                                , style
                                    [ ( "width", 7 |> toFieldWidth ) ]
                                ]
                          ]
                        ]

                ( Nothing, Field.Mac ) ->
                    List.concat
                        [ currentList
                        , [ Select.attrs
                                [ maxlength 17
                                , style
                                    [ ( "width", 10 |> toFieldWidth ) ]
                                ]
                          ]
                        ]

                ( Just max, _ ) ->
                    List.concat
                        [ currentList
                        , [ Select.attrs
                                ([ maxlength max ]
                                    |> buildStyle
                                )
                          ]
                        ]

                ( Nothing, _ ) ->
                    currentList

        fieldOptions =
            case field.options of
                Nothing ->
                    []

                Just options ->
                    options |> List.sortBy .label

        fieldOptionsWithDefault =
            { id = Field.defaultSelectId, label = "Select an Option", default = True } :: fieldOptions

        fieldLoader =
            if field.optionsLoading then
                span [ class "select-loader" ] [ i [ class "fa fa-circle-o-notch fa-spin fa-1x fa-fw" ] [] ]
            else
                text ""

        attrs =
            [ value field.value ]

        fieldElement currentList =
            List.concat
                [ currentList
                , [ Select.select
                        (List.concat
                            [ selectRoleConfig
                            , [ Select.attrs attrs ]
                                |> onUpdateHandler
                                |> maxAttr
                            , [ Select.small ]
                            ]
                        )
                        (List.map
                            (\option ->
                                Select.item [ value option.id, selected (option.id == field.value) ] [ text option.label ]
                            )
                            fieldOptionsWithDefault
                        )
                  , fieldLoader
                  ]
                ]
    in
    Form.group groupConfig
        ([]
            |> labelElement
            |> fieldElement
            |> validationText
        )


buildQuantityField : Field.Data msg id -> Html msg
buildQuantityField field =
    let
        labelElement =
            Maybe.map textLabel field.label

        numericOnlyInputHandler handler =
            Input.onInput (\input -> handler <| validateNumericString boundedUpdate field.value (toString minValue) input)

        onInputHandler =
            Maybe.map numericOnlyInputHandler field.onUpdate

        boundedValue =
            validateNumericString boundedUpdate stringMinValue stringMinValue field.value

        minValue =
            Maybe.withDefault 0 field.min

        stringMinValue =
            toString minValue

        maxValue =
            Maybe.withDefault 100 field.max

        options =
            justValues [ Just (Input.value boundedValue), onInputHandler ]

        boundedUpdate =
            clamp minValue maxValue

        decrement =
            updateIntTextValue (\value -> value - 1) boundedValue

        increment =
            updateIntTextValue (\value -> value + 1) boundedValue

        clickHandler =
            Maybe.map2 (\inputHandler value -> Button.onClick <| inputHandler value) field.onUpdate

        decrementClickHandler =
            clickHandler decrement

        incrementClickHandler =
            clickHandler increment

        inputGroup =
            InputGroup.config
                (InputGroup.text options)
                |> InputGroup.small
                |> InputGroup.predecessors
                    [ InputGroup.button (justValues [ decrementClickHandler ]) [ text "-" ] ]
                |> InputGroup.successors
                    [ InputGroup.button (justValues [ incrementClickHandler ]) [ text "+" ] ]
                |> InputGroup.view

        children =
            justValues [ labelElement, Just inputGroup ]
    in
    Form.group [] children


buildAutocompleteField menuView field =
    let
        groupConfig =
            Maybe.map buildGroupConfig field.validation.role
                |> Maybe.withDefault []

        inputRoleConfig =
            Maybe.map buildInputRole field.validation.role
                |> Maybe.withDefault []

        validationText =
            case ( field.validation.isValid, field.validation.message ) of
                ( _, Nothing ) ->
                    Nothing

                ( Field.Initial, _ ) ->
                    Nothing

                ( _, Just msg ) ->
                    Just <| Form.validationText [] [ text msg ]

        labelElement =
            Maybe.map (\value -> Form.label [] [ text value ]) field.label

        onUpdateHandler =
            Maybe.map onInput field.onUpdate

        maxAttr =
            case ( field.max, field.dataType ) of
                ( Nothing, Field.IPv4Address ) ->
                    Just <|
                        [ maxlength 15
                        , style
                            [ ( "width", toFieldWidth 15 ) ]
                        ]

                ( Nothing, Field.DateOnly ) ->
                    Just <|
                        [ maxlength 10
                        , style
                            [ ( "width", toFieldWidth 7 ) ]
                        ]

                ( Nothing, Field.Mac ) ->
                    Just <|
                        [ maxlength 17
                        , style
                            [ ( "width", toFieldWidth 10 ) ]
                        ]

                ( Just max, _ ) ->
                    Just [ maxlength max ]

                ( Nothing, _ ) ->
                    Nothing

        fieldElement =
            Input.text <|
                [ Input.attrs fieldAttrs
                , Input.small
                , Input.value field.value
                ]
                    ++ inputRoleConfig

        fieldAttrs =
            Util.justValues
                [ onUpdateHandler
                , Just <| autocomplete False
                ]
                ++ Maybe.withDefault [] maxAttr

        children =
            Util.justValues [ labelElement, Just fieldElement, Just menuView ]
    in
    Form.group groupConfig children


buildLinkField field =
    let
        groupConfig =
            Maybe.map buildGroupConfig field.validation.role
                |> Maybe.withDefault []

        labelElement =
            Maybe.map (\value -> Form.label [] [ text value ]) field.label

        onClickHandler =
            Maybe.map (\handler -> Button.onClick (handler field.value)) field.onUpdate

        linkValue =
            Button.button
                (Util.justValues [ Just Button.roleLink, onClickHandler ])
                [ text field.value ]

        children =
            Util.justValues [ labelElement, Just linkValue ]
    in
    Form.group groupConfig children


buildControlGroupField field selection buttonTitles =
    let
        groupConfig =
            Maybe.map buildGroupConfig field.validation.role
                |> Maybe.withDefault []

        labelElement =
            Maybe.map (\value -> Form.label [ style [ ( "margin-right", "0.5em" ) ] ] [ text value ]) field.label

        titles =
            Set.toList buttonTitles

        controlGroup =
            case selection of
                Field.Single ->
                    ButtonGroup.radioButtonGroup [ ButtonGroup.small ] <|
                        List.map
                            (\title ->
                                ButtonGroup.radioButton (title == field.value)
                                    (Util.justValues
                                        [ Just Button.primary
                                        , Maybe.map (\handler -> Button.onClick (handler title)) field.onUpdate
                                        ]
                                    )
                                    [ text title ]
                            )
                            titles

                Field.Multiple ->
                    ButtonGroup.checkboxButtonGroup [ ButtonGroup.small ] <|
                        List.map
                            (\title ->
                                let
                                    checked =
                                        String.contains title field.value

                                    delim =
                                        ","

                                    newValue =
                                        if checked then
                                            if String.contains delim field.value then
                                                String.split delim field.value
                                                    |> List.filter (\text -> text /= title)
                                                    |> String.join delim
                                            else
                                                ""
                                        else if String.contains delim field.value then
                                            String.split delim field.value
                                                |> (::) title
                                                |> String.join delim
                                        else if not <| String.isEmpty field.value then
                                            String.join delim [ field.value, title ]
                                        else
                                            title
                                in
                                ButtonGroup.checkboxButton checked
                                    (Util.justValues
                                        [ Just Button.primary
                                        , Maybe.map (\handler -> Button.onClick (handler newValue)) field.onUpdate
                                        ]
                                    )
                                    [ text title ]
                            )
                            titles

        children =
            Util.justValues [ labelElement, Just controlGroup ]
    in
    Form.group groupConfig children


validateNumericString : (Int -> Int) -> String -> String -> String -> String
validateNumericString validator default empty value =
    if String.isEmpty value then
        empty
    else
        String.toInt value
            |> Result.map validator
            |> Result.map toString
            |> Result.withDefault default


updateIntTextValue : (Int -> Int) -> String -> Maybe String
updateIntTextValue update value =
    String.toInt value
        |> Result.toMaybe
        |> Maybe.map update
        |> Maybe.map toString


textLabel : String -> Html msg
textLabel label =
    Form.label [] [ text label ]


buildGroupConfig role =
    case role of
        Success ->
            [ Form.groupSuccess ]

        Warning ->
            [ Form.groupWarning ]

        Danger ->
            [ Form.groupDanger ]

        _ ->
            []


buildInputRole role =
    case role of
        Success ->
            [ Input.success ]

        Warning ->
            [ Input.warning ]

        Danger ->
            [ Input.danger ]

        _ ->
            []


buildSelectRole role =
    case role of
        Success ->
            []

        Warning ->
            []

        Danger ->
            []

        _ ->
            []


update form fields =
    { form | fields = fields }


updateFields form fields =
    { form | fields = fields }


alertType role =
    case role of
        Success ->
            Alert.success

        Warning ->
            Alert.warning

        Danger ->
            Alert.danger

        _ ->
            Alert.info


alertIcon role =
    case role of
        Success ->
            FA.check

        Warning ->
            FA.exclamation_triangle

        Danger ->
            FA.exclamation_triangle

        _ ->
            FA.info_circle


fieldDefaults =
    { padding = 5, width = 14, validIconWidth = 20 }


toFieldWidth size =
    ((size * fieldDefaults.width) + fieldDefaults.padding + fieldDefaults.validIconWidth |> toString) ++ "px"


buildWidthStyles : Maybe ( Float, Field.DistanceUnit ) -> List ( String, String ) -> List ( String, String )
buildWidthStyles options =
    case options of
        Nothing ->
            identity

        Just option ->
            identity


validateAll form =
    let
        formValidation =
            form.validation

        validatedFields =
            List.map (List.map Field.validate) form.fields

        formIsValid =
            validatedFields
                |> List.concat
                |> List.filter (\field -> field.validation.isValid == Field.NotValid)
                |> List.length
                |> (\count -> count == 0)
                |> (\isValid ->
                        if isValid then
                            Valid
                        else
                            NotValid
                   )

        --        errorCount =
        --            List.filter (\field -> not field.validation.isValid) fieldList
        --                |> List.length
        ( validationMessage, validationRole ) =
            case formIsValid of
                NotValid ->
                    Just defaultInvalidMessage => Just Danger

                _ ->
                    formValidation.message => formValidation.role

        newForm =
            { form
                | fields = validatedFields
                , validation = { formValidation | isValid = formIsValid, message = validationMessage, role = validationRole }
            }
    in
    newForm


getFormFieldData form ids =
    let
        fieldList =
            List.map
                (\f ->
                    let
                        field =
                            f |> Field.validate
                    in
                    { id = field.id
                    , value = field.value
                    , isValid = field.validation.isValid
                    }
                )
                (List.concat form.fields)
    in
    fieldList


getFieldValue id form =
    List.filter (\field -> field.id == id) form
        |> List.head
        |> Maybe.map .value
        |> Maybe.withDefault ""


defaultInvalidMessage : String
defaultInvalidMessage =
    "There are problems with this form. Please resolve them and click \"Save\""
