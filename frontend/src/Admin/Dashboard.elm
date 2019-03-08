module Admin.Dashboard exposing
    ( Dashboard
    , decoder
    , get
    , namespacesCount
    , namespacesNew
    , usersCount
    , usersNew
    )

{-| A namespace's profile - potentially your own!

Contrast with Cred, which is the currently signed-in namespace.

-}

import Api
import Api.Admin
import Api.Endpoint as Endpoint
import Api.User
import Email exposing (Email)
import Http
import ID exposing (ID)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode exposing (Value)
import Namespace exposing (Namespace)
import User exposing (User)



-- TYPES


type Dashboard
    = Dashboard Internals


type alias Internals =
    { usersCount : Int
    , usersNew : List User
    , namespacesCount : Int
    , namespacesNew : List Namespace
    }



-- INFO


usersCount : Dashboard -> Int
usersCount (Dashboard info) =
    info.usersCount


usersNew : Dashboard -> List User
usersNew (Dashboard info) =
    info.usersNew


namespacesCount : Dashboard -> Int
namespacesCount (Dashboard info) =
    info.namespacesCount


namespacesNew : Dashboard -> List Namespace
namespacesNew (Dashboard info) =
    info.namespacesNew



-- SERIALIZATION


decoder : Decoder Dashboard
decoder =
    Decode.succeed Internals
        |> required "users_count" Decode.int
        |> required "users_new" (Decode.list User.decoder)
        |> required "namespaces_count" Decode.int
        |> required "namespaces_new" (Decode.list Namespace.decoder)
        |> Decode.map Dashboard



-- FETCH


get : Http.Request Dashboard
get =
    decoder
        |> Api.get Api.Admin.dashboard
