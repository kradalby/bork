module Page.Misc exposing (..)

import Session exposing (Session)
import ID exposing (ID)


isOwner : Session -> ID -> Bool
isOwner session id =
    case (Session.id session) of
        Nothing ->
            False

        Just loggedInId ->
            loggedInId == id
