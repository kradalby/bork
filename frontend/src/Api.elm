port module Api exposing (addServerError, application, decodeErrors, delete, get, logout, post, put, traceDecoder)

{-| This module is responsible for communicating to the Conduit API.

It exposes an opaque Endpoint type which is guaranteed to point to the correct URL.

-}

import Api.Endpoint as Endpoint exposing (Endpoint)
import Browser
import Browser.Navigation as Nav
import Http exposing (Body, Expect)
import Json.Decode as Decode exposing (Decoder, Value, decodeString, field, string)
import Json.Decode.Pipeline as Pipeline exposing (optional, required)
import Json.Encode as Encode
import Url exposing (Url)
import Username exposing (Username)



-- APPLICATION
-- application :
--     Decoder (Cred -> viewer)
--     ->
--         { init : Maybe viewer -> Url -> Nav.Key -> ( model, Cmd msg )
--         , onUrlChange : Url -> msg
--         , onUrlRequest : Browser.UrlRequest -> msg
--         , subscriptions : model -> Sub msg
--         , update : msg -> model -> ( model, Cmd msg )
--         , view : model -> Browser.Document msg
--         }
--     -> Program Value model msg
-- application viewerDecoder config =
--     let
--         init flags url navKey =
--             let
--                 maybeViewer =
--                     Decode.decodeValue Decode.string flags
--                         |> Result.andThen (Decode.decodeString (storageDecoder viewerDecoder))
--                         |> Result.toMaybe
--             in
--                 config.init maybeViewer url navKey
--     in
--         Browser.application
--             { init = init
--             , onUrlChange = config.onUrlChange
--             , onUrlRequest = config.onUrlRequest
--             , subscriptions = config.subscriptions
--             , update = config.update
--             , view = config.view
--             }


application :
    { init : Url -> Nav.Key -> ( model, Cmd msg )
    , onUrlChange : Url -> msg
    , onUrlRequest : Browser.UrlRequest -> msg
    , subscriptions : model -> Sub msg
    , update : msg -> model -> ( model, Cmd msg )
    , view : model -> Browser.Document msg
    }
    -> Program Value model msg
application config =
    let
        init flags url navKey =
            config.init url navKey
    in
    Browser.application
        { init = init
        , onUrlChange = config.onUrlChange
        , onUrlRequest = config.onUrlRequest
        , subscriptions = config.subscriptions
        , update = config.update
        , view = config.view
        }



-- HTTP


get : Endpoint -> Decoder a -> Http.Request a
get url decoder =
    Endpoint.request
        { method = "GET"
        , url = url
        , expect = Http.expectJson (traceDecoder "get " decoder)
        , headers = []
        , body = Http.emptyBody
        , timeout = Nothing
        , withCredentials = False
        }


put : Endpoint -> Body -> Decoder a -> Http.Request a
put url body decoder =
    Endpoint.request
        { method = "PUT"
        , url = url
        , expect = Http.expectJson decoder
        , headers = []
        , body = body
        , timeout = Nothing
        , withCredentials = False
        }


post : Endpoint -> Body -> Decoder a -> Http.Request a
post url body decoder =
    Endpoint.request
        { method = "POST"
        , url = url
        , expect = Http.expectJson decoder
        , headers =
            []
        , body = body
        , timeout = Nothing
        , withCredentials = False
        }


delete : Endpoint -> Body -> Decoder a -> Http.Request a
delete url body decoder =
    Endpoint.request
        { method = "DELETE"
        , url = url
        , expect = Http.expectJson decoder
        , headers = []
        , body = body
        , timeout = Nothing
        , withCredentials = False
        }


logout : Http.Body -> Http.Request String
logout body =
    delete Endpoint.auth body (Decode.succeed "")



-- register : Http.Body -> Decoder (Cred -> a) -> Http.Request a
-- register body decoder =
--     post Endpoint.users Nothing body (Decode.field "user" (decoderFromCred decoder))
-- settings : Cred -> Http.Body -> Decoder (Cred -> a) -> Http.Request a
-- settings cred body decoder =
--     put Endpoint.user cred body (Decode.field "user" (decoderFromCred decoder))
-- ERRORS


addServerError : List String -> List String
addServerError list =
    "Server error" :: list


{-| Many API endpoints include an "errors" field in their BadStatus responses.
-}
decodeErrors : Http.Error -> List String
decodeErrors error =
    case error of
        Http.BadStatus response ->
            response.body
                |> decodeString (field "errors" errorsDecoder)
                |> Result.withDefault [ "Server error" ]

        err ->
            [ "Server error" ]


errorsDecoder : Decoder (List String)
errorsDecoder =
    Decode.keyValuePairs (Decode.list Decode.string)
        |> Decode.map (List.concatMap fromPair)


fromPair : ( String, List String ) -> List String
fromPair ( field, errors ) =
    List.map (\error -> field ++ " " ++ error) errors


traceDecoder : String -> Decode.Decoder msg -> Decode.Decoder msg
traceDecoder message decoder =
    Decode.value
        |> Decode.andThen
            (\value ->
                case Decode.decodeValue decoder value of
                    Ok decoded ->
                        -- Decode.succeed <| Debug.log ("Success: " ++ message) <| decoded
                        Decode.succeed decoded

                    Err err ->
                        -- Decode.fail <| Debug.log ("Fail: " ++ message) <| Debug.toString err
                        Decode.fail "fail"
            )
