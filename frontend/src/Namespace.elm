module Namespace exposing (Namespace, id, name, owner, decoder, fetch, list)

{-| A namespace's profile - potentially your own!

Contrast with Cred, which is the currently signed-in namespace.

-}

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import ID exposing (ID)
import Email exposing (Email)
import Api.Endpoint as Endpoint
import Api
import User exposing (User)


-- TYPES


type Namespace
    = Namespace Internals


type alias Internals =
    { id : ID
    , createdAt : String
    , updatedAt : String
    , owner : User
    , ownerId : ID
    , coOwners : List User
    , name : String
    }



-- INFO


id : Namespace -> ID
id (Namespace info) =
    info.id


name : Namespace -> String
name (Namespace info) =
    info.name


owner : Namespace -> User
owner (Namespace info) =
    info.owner



-- SERIALIZATION


decoder : Decoder Namespace
decoder =
    Decode.succeed Internals
        |> required "id" ID.decoder
        |> required "created_at" Decode.string
        |> required "updated_at" Decode.string
        |> required "owner" User.decoder
        |> required "owner_id" ID.decoder
        |> required "co_owners" (Decode.list User.decoder)
        |> required "name" Decode.string
        |> Decode.map Namespace



-- FETCH


fetch : ID -> Http.Request Namespace
fetch ident =
    decoder
        |> Api.get (Endpoint.namespace ident)


list : Http.Request (List Namespace)
list =
    Decode.list decoder
        |> Api.get (Endpoint.namespaces)
