module Namespace
    exposing
        ( Namespace
        , Auth
        , id
        , name
        , owner
        , coOwners
        , coowned
        , created
        , decoder
        , get
        , list
        , create
        , delete
        , addCoOwner
        , deleteCoOwner
        , availableUsers
        , token
        , endpoint
        , certificate
        , certificateB64
        , auth
        , config
        , prefix
        , validate
        )

{-| A namespace's profile - potentially your own!

Contrast with Cred, which is the currently signed-in namespace.

-}

import Http
import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import ID exposing (ID)
import Email exposing (Email)
import Api.Endpoint as Endpoint
import Api.Namespace
import Api.User
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


get : ID -> Http.Request Namespace
get ident =
    decoder
        |> Api.get (Api.Namespace.show ident)


list : Http.Request (List Namespace)
list =
    Decode.list decoder
        |> Api.get (Api.Namespace.list)


create : String -> Http.Request Namespace
create namespace =
    let
        body =
            Encode.object [ ( "name", Encode.string namespace ) ] |> Http.jsonBody
    in
        Api.post Api.Namespace.create body decoder


delete : ID -> Http.Request Namespace
delete ident =
    decoder
        |> Api.delete (Api.Namespace.show ident) Http.emptyBody


coowned : ID -> Http.Request (List Namespace)
coowned ident =
    Decode.list decoder
        |> Api.get (Api.User.coowned ident)


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


availableUsers : ID -> Http.Request (List User)
availableUsers ident =
    Decode.list User.decoder
        |> Api.get (Api.Namespace.availableUsers ident)


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


prefix : Http.Request String
prefix =
    Decode.field "prefix" Decode.string
        |> Api.get Api.Namespace.prefix


validate : String -> Http.Request (List String)
validate namespace =
    let
        body =
            Encode.object [ ( "name", Encode.string namespace ) ] |> Http.jsonBody

        resultDecoder =
            Decode.field "errors" (Decode.list Decode.string)
    in
        Api.post Api.Namespace.validate body resultDecoder


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
