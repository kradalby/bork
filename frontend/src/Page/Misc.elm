module Page.Misc exposing (httpErrorToUserError, isOwner)

import Api
import Api.Error
import Http exposing (..)
import ID exposing (ID)
import Json.Decode as Decode
import Session exposing (Session)


isOwner : Session -> ID -> Bool
isOwner session id =
    case Session.id session of
        Nothing ->
            False

        Just loggedInId ->
            loggedInId == id


httpErrorToUserError : Http.Error -> String
httpErrorToUserError error =
    case error of
        BadUrl url ->
            "BadUrl " ++ url

        Timeout ->
            "Timeout"

        NetworkError ->
            "NetworkError"

        BadStatus response ->
            let
                decodedError =
                    Result.withDefault "Could not decode error."
                        (Result.map .error <|
                            Decode.decodeString
                                (Api.traceDecoder "error" Api.Error.decoder)
                                response.body
                        )
            in
            decodedError

        BadPayload message response ->
            "BadPayload: " ++ message
