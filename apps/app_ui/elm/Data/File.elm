module Data.File
    exposing
        ( Base64
        , Error(..)
        , File
        , MimeType(..)
        , mimeTypeDecoder
        , mimeTypeValue
        , selectedFileDecoder
        )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline exposing (decode, required)


type alias File =
    { name : String
    , size : Float
    , mimeType : MimeType
    , data : Base64
    }


type alias Base64 =
    String


type MimeType
    = Text String
    | Image String
    | Audio String
    | Video String
    | Application String


type Error
    = FileTooLarge
    | InvalidType
    | Error


mimeTypeValue : MimeType -> String
mimeTypeValue mime =
    case mime of
        Text value ->
            value

        Image value ->
            value

        Audio value ->
            value

        Video value ->
            value

        Application value ->
            value



-- Serialization


selectedFileDecoder : Decoder (Result Error File)
selectedFileDecoder =
    Decode.oneOf
        [ Decode.map Result.Ok fileDecoder
        , Decode.map Result.Err errorDecoder
        ]


errorDecoder : Decoder Error
errorDecoder =
    Decode.int
        |> Decode.map
            (\code ->
                case code of
                    (-1) ->
                        FileTooLarge

                    (-2) ->
                        InvalidType

                    _ ->
                        Error
            )


fileDecoder : Decoder File
fileDecoder =
    decode File
        |> required "name" Decode.string
        |> required "size" Decode.float
        |> required "type" mimeTypeDecoder
        |> required "data" Decode.string


mimeTypeDecoder : Decoder MimeType
mimeTypeDecoder =
    let
        mime input =
            if String.startsWith "text" input then
                Decode.succeed (Text input)
            else if String.startsWith "image" input then
                Decode.succeed (Image input)
            else if String.startsWith "audio" input then
                Decode.succeed (Audio input)
            else if String.startsWith "video" input then
                Decode.succeed (Video input)
            else if String.startsWith "application" input then
                Decode.succeed (Application input)            
            else
                Decode.fail ("could not parse mime type of " ++ input)
    in
    Decode.string
        |> Decode.andThen mime
