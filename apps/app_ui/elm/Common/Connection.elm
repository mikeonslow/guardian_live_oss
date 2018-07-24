module Common.Connection exposing (push, socketUrl)

import Json.Encode as JE
import Phoenix
import Phoenix.Push as Push


socketUrl =
    "ws://localhost:4000/socket/websocket?vsn=1.0.0"


push roomAndTopic events =
    List.map (pushEvent roomAndTopic) events


pushEvent roomAndTopic event =
    let
        pushPayload =
            case event.payload of
                Nothing ->
                    identity

                Just payload ->
                    Push.withPayload payload

        okayHandler =
            case event.onOk of
                Nothing ->
                    identity

                Just handler ->
                    Push.onOk handler

        errorHandler =
            case event.onOk of
                Nothing ->
                    identity

                Just handler ->
                    Push.onError handler
    in
    Phoenix.push socketUrl
        (Push.init roomAndTopic event.name
            |> pushPayload
            |> okayHandler
            |> errorHandler
        )



{--
{"status" => status_id,
			 "accountManager" => account_manager_id,
			 "franchisor" => franchisor,
			 "create_date_start" => start_dtm,
			 "create_date_end" => end_dtm,
			 "customerName" => customer_id }
--}
