module Common.Validation.Pattern exposing (..)


stringBasic ( min, max ) =
    "^[a-zA-Z0-9\\ ]{" ++ min ++ "," ++ max ++ "}$"


stringExtended ( min, max ) =
    "(^[a-zA-Z0-9\\/\\&\\#\\ \\'\\.\\+\\-\\?\\$\\(\\)\\<\\>\\@\\,\\!\\\"]{" ++ min ++ "," ++ max ++ "}$)"


ipv4Address =
    "^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$"


number ( min, max ) =
    "(^[0-9]{" ++ min ++ "," ++ max ++ "}$)"


phone ( min, max ) =
    "(^[0-9]{" ++ min ++ "," ++ max ++ "}$)"


decimal ( min, max ) =
    "(^[0-9\\.\\-]{" ++ min ++ "," ++ max ++ "}$)"


date =
    "(([0-9]{2})([\\/]{1})([0-9]{2})([\\/]{1})([0-9]{2,4}))"


zipCode =
    "(^\\d{5}(-\\d{4})?$)|(^[ABCEGHJKLMNPRSTVXY]{1}\\d{1}[A-Z]{1} *\\d{1}[A-Z]{1}\\d{1}$)"


mac =
    "(^(([A-Fa-f0-9]{2}[:]?){5}[A-Fa-f0-9]{2}[,]?)+$)"


email ( min, max ) =
    "^(?=.{" ++ min ++ "," ++ max ++ "}$)[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}"


password =
    "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[a-zA-Z\\d]{8,}$"


any ( min, max ) =
    "^[\\S\\s]{" ++ min ++ "," ++ max ++ "}$"
