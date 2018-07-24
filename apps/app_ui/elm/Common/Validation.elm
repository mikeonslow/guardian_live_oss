module Common.Validation
    exposing
        ( any
        , anyStringError
        , basicString
        , basicStringError
        , date
        , dateError
        , decimal
        , decimalError
        , email
        , emailError
        , extendedString
        , extendedStringError
        , ipv4Address
        , ipv4Error
        , mac
        , macError
        , nonEmptySet
        , notDefaultOption
        , oneOf
        , oneOfError
        , password
        , passwordError
        , phone
        , phoneError
        , quantity
        , quantityError
        , required
        , requiredError
        , selectAnOptionError
        , withBackup
        , zipCode
        , zipCodeError
        )

import Common.Validation.Integer exposing (max32BitInt)
import Common.Validation.Pattern as Pattern
import Regex exposing (Regex)
import Set exposing (Set)
import Validation exposing (ValidationResult)


-- Patterns


basicString : Maybe Int -> Maybe Int -> String -> Result String String
basicString min max text =
    let
        bounds =
            patternBounds min max

        errorMessage =
            basicStringError min max
    in
    validatePattern errorMessage (Pattern.stringBasic bounds) text


extendedString : Maybe Int -> Maybe Int -> String -> Result String String
extendedString min max text =
    let
        bounds =
            patternBounds min max

        errorMessage =
            extendedStringError min max
    in
    validatePattern errorMessage (Pattern.stringExtended bounds) text


any : Maybe Int -> Maybe Int -> String -> Result String String
any min max text =
    let
        bounds =
            patternBounds min max

        errorMessage =
            anyStringError min max
    in
    validatePattern errorMessage (Pattern.any bounds) text


ipv4Address : String -> Result String String
ipv4Address =
    validatePattern ipv4Error Pattern.ipv4Address


quantity : Maybe Int -> Maybe Int -> String -> Result String Int
quantity min max text =
    let
        bounds =
            patternBounds min max

        errorMessage =
            quantityError min max
    in
    validatePattern errorMessage (Pattern.number bounds) text
        |> Result.andThen String.toInt


phone : Maybe Int -> Maybe Int -> String -> Result String String
phone min max text =
    let
        bounds =
            patternBounds min max

        errorMessage =
            phoneError min max
    in
    validatePattern errorMessage (Pattern.phone bounds) text


decimal : Maybe Float -> Maybe Float -> String -> Result String Float
decimal min max text =
    let
        bounds =
            patternBounds min max
    in
    validatePattern decimalError (Pattern.decimal bounds) text
        |> Result.andThen String.toFloat


date : String -> Result String String
date =
    validatePattern dateError Pattern.date


mac : String -> Result String String
mac =
    validatePattern macError Pattern.mac


zipCode : String -> Result String String
zipCode =
    validatePattern zipCodeError Pattern.zipCode


email : Maybe Int -> Maybe Int -> String -> Result String String
email min max text =
    let
        bounds =
            patternBounds min max
    in
    validatePattern emailError (Pattern.email bounds) text


password : String -> Result String String
password =
    validatePattern passwordError
        Pattern.password


notDefaultOption : String -> Result String String
notDefaultOption value =
    if value /= toString defaultSelectOptionId then
        Ok value
    else
        Err selectAnOptionError


oneOf : List { a | label : String } -> String -> Result String String
oneOf options value =
    if List.any (\{ label } -> label == value) options then
        Ok value
    else
        Err oneOfError


required : String -> Result String String
required value =
    if String.isEmpty value then
        Err requiredError
    else
        Ok value


nonEmptySet : Set a -> (String -> Result String (Set a))
nonEmptySet value =
    if Set.isEmpty value then
        \_ -> Err selectAnOptionError
    else
        \_ -> Ok value


defaultSelectOptionId : Float
defaultSelectOptionId =
    0


withBackup : a -> ValidationResult a -> ValidationResult a
withBackup backup value =
    case value of
        Validation.Invalid _ _ ->
            Validation.Valid backup

        _ ->
            value



-- Default error messages


basicStringError : Maybe Int -> Maybe Int -> String
basicStringError min max =
    let
        ( stringMin, stringMax ) =
            patternBounds min max
    in
    case ( min, max ) of
        ( Just x, Just y ) ->
            "Must be alphanumeric and between "
                ++ toString x
                ++ " and "
                ++ toString y
                ++ " characters"

        ( Just x, Nothing ) ->
            "Must be alphanumeric and have at least " ++ toString x ++ " characters"

        ( Nothing, Just y ) ->
            "Must be alphanumeric  and have at most " ++ toString y ++ " characters"

        ( Nothing, Nothing ) ->
            "Must be alphanumeric "


extendedStringError : Maybe Int -> Maybe Int -> String
extendedStringError min max =
    let
        ( stringMin, stringMax ) =
            patternBounds min max
    in
    case ( min, max ) of
        ( Just x, Just y ) ->
            "Must be alphanumeric and between "
                ++ toString x
                ++ " and "
                ++ toString y
                ++ " characters"

        ( Just x, Nothing ) ->
            "Must be alphanumeric and have at least " ++ toString x ++ " characters"

        ( Nothing, Just y ) ->
            "Must be alphanumeric  and have at most " ++ toString y ++ " characters"

        ( Nothing, Nothing ) ->
            "Must be alphanumeric "


anyStringError : Maybe Int -> Maybe Int -> String
anyStringError min max =
    let
        ( stringMin, stringMax ) =
            patternBounds min max
    in
    case ( min, max ) of
        ( Just x, Just y ) ->
            "Must be between "
                ++ toString x
                ++ " and "
                ++ toString y
                ++ " characters"

        ( Just x, Nothing ) ->
            "Must be at least " ++ toString x ++ " characters"

        ( Nothing, Just y ) ->
            "Must be at most " ++ toString y ++ " characters"

        ( Nothing, Nothing ) ->
            ""


ipv4Error : String
ipv4Error =
    "Must contain a valid IPv4 address"


quantityError : Maybe Int -> Maybe Int -> String
quantityError min max =
    case ( min, max ) of
        ( Just x, Just y ) ->
            "Must contain only numbers and be between "
                ++ toString x
                ++ " and "
                ++ toString y
                ++ " characters"

        ( Just x, Nothing ) ->
            "Must contain only numbers and have at least " ++ toString x ++ " characters"

        ( Nothing, Just y ) ->
            "Must contain only numbers and have at most " ++ toString y ++ " characters"

        ( Nothing, Nothing ) ->
            "Must contain only numbers"


phoneError : Maybe Int -> Maybe Int -> String
phoneError min max =
    let
        ( stringMin, stringMax ) =
            patternBounds min max
    in
    "Must contain only numbers and be between "
        ++ stringMin
        ++ " and "
        ++ stringMax
        ++ " characters"


decimalError : String
decimalError =
    "Field must contain a valid decimal value"


dateError : String
dateError =
    "Field must contain a valid date format (ex: 06/21/1978)"


macError : String
macError =
    "Field must contain a valid mac address"


zipCodeError : String
zipCodeError =
    "Field must contain a valid zip code"


requiredError : String
requiredError =
    "Value required"


emailError : String
emailError =
    "Field must contain a valid email address"


selectAnOptionError : String
selectAnOptionError =
    "Please select an option"


passwordError : String
passwordError =
    "Password must contain at least 8 characters, one lowercase letter, one uppercase letter, and a number"


oneOfError : String
oneOfError =
    "Please select an item from the list"



-- Helpers


patternBounds : Maybe a -> Maybe a -> ( String, String )
patternBounds min max =
    ( Maybe.map toString min
        |> Maybe.withDefault "0"
    , Maybe.map toString max
        |> Maybe.withDefault (toString max32BitInt)
    )


validatePattern : String -> String -> String -> Result String String
validatePattern errorMessage pattern value =
    Regex.regex pattern
        |> matchPattern value
        |> Result.mapError (\_ -> errorMessage)


matchPattern : String -> Regex -> Result String String
matchPattern value regex =
    let
        matchCharacters =
            Regex.find (Regex.AtMost 1) regex value
    in
    if List.isEmpty matchCharacters then
        Err "Pattern doesn't match"
    else
        Ok value
