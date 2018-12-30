module Session exposing (Session, changes, fromUser, navKey, user, id)

import Api
import Browser.Navigation as Nav
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (custom, required)
import Json.Encode as Encode exposing (Value)
import Time
import User exposing (User)
import ID exposing (ID)


-- TYPES


type Session
    = LoggedIn Nav.Key User
    | Guest Nav.Key



-- INFO


user : Session -> Maybe User
user session =
    case session of
        LoggedIn _ val ->
            Just val

        Guest _ ->
            Nothing


id : Session -> Maybe ID
id session =
    case session of
        LoggedIn _ val ->
            Just (User.id val)

        Guest _ ->
            Nothing


navKey : Session -> Nav.Key
navKey session =
    case session of
        LoggedIn key _ ->
            key

        Guest key ->
            key



-- CHANGES


changes : (Session -> msg) -> Nav.Key -> Sub msg
changes toMsg key =
    -- Api.userChanges (\maybeUser -> toMsg (fromUser key maybeUser)) User.decoder
    Sub.none


fromUser : Nav.Key -> Maybe User -> Session
fromUser key maybeUser =
    -- It's stored in localStorage as a JSON String;
    -- first decode the Value as a String, then
    -- decode that String as JSON.
    case maybeUser of
        Just userVal ->
            LoggedIn key userVal

        Nothing ->
            Guest key
