module Page.Misc exposing (..)

import Session exposing (Session)
import ID exposing (ID)
import Http exposing (..)


isOwner : Session -> ID -> Bool
isOwner session id =
    case (Session.id session) of
        Nothing ->
            False

        Just loggedInId ->
            loggedInId == id


httpErrorToUserError : Http.Error -> String
httpErrorToUserError error =
    case error of
        BadUrl url ->
            ""

        Timeout ->
            ""

        NetworkError ->
            ""

        BadStatus code ->
            ""

        BadPayload a b ->
            ""
