module Namespace
    exposing
        ( Namespace
        , Auth
        , id
        , name
        , owner
        , coOwners
        , created
        , decoder
        , fetch
        , list
        , listCoOwner
        , addCoOwner
        , deleteCoOwner
        , token
        , endpoint
        , certificate
        , certificateB64
        , auth
        , config
        )

{-| A namespace's profile - potentially your own!

Contrast with Cred, which is the currently signed-in namespace.

-}

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import ID exposing (ID)
import Email exposing (Email)
import Api.Endpoint as Endpoint
import Api.Namespace
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


coOwners : Namespace -> List User
coOwners (Namespace info) =
    info.coOwners


created : Namespace -> String
created (Namespace info) =
    info.createdAt



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
        |> Api.get (Api.Namespace.get ident)


list : Http.Request (List Namespace)
list =
    Decode.list decoder
        |> Api.get (Api.Namespace.list)


listCoOwner : Http.Request (List Namespace)
listCoOwner =
    Decode.list decoder
        |> Api.get (Api.Namespace.listCoOwner)


addCoOwner : ID -> User -> Http.Request Namespace
addCoOwner ident user =
    let
        body =
            User.encode user |> Http.jsonBody
    in
        Api.post (Api.Namespace.coOwner ident) body decoder


deleteCoOwner : ID -> User -> Http.Request Namespace
deleteCoOwner ident user =
    let
        body =
            User.encode user |> Http.jsonBody
    in
        Api.delete (Api.Namespace.coOwner ident) body decoder


token : ID -> Http.Request String
token ident =
    Decode.field "token" Decode.string
        |> Api.get (Api.Namespace.token ident)


certificate : ID -> Http.Request String
certificate ident =
    Decode.field "certificate" Decode.string
        |> Api.get (Api.Namespace.certificate ident)


certificateB64 : ID -> Http.Request String
certificateB64 ident =
    Decode.field "certificate_b64" Decode.string
        |> Api.get (Api.Namespace.certificateB64 ident)


endpoint : ID -> Http.Request String
endpoint ident =
    Decode.field "endpoint" Decode.string
        |> Api.get (Api.Namespace.endpoint ident)


config : ID -> Http.Request String
config ident =
    Decode.field "config" Decode.string
        |> Api.get (Api.Namespace.config ident)


type alias Auth =
    { certificate : String
    , certificateB64 : String
    , endpoint : String
    , token : String
    }


auth : ID -> Http.Request Auth
auth ident =
    Decode.map4 Auth
        (Decode.field "certificate" Decode.string)
        (Decode.field "certificate_b64" Decode.string)
        (Decode.field "endpoint" Decode.string)
        (Decode.field "token" Decode.string)
        |> Api.get (Api.Namespace.auth ident)
