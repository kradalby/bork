module User
    exposing
        ( User
        , id
        , username
        , name
        , email
        , isAdmin
        , decoder
        , encode
        , session
        , get
        , list
        )

{-| A user's profile - potentially your own!

Contrast with Cred, which is the currently signed-in user.

-}

import Http
import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import ID exposing (ID)
import Email exposing (Email)
import Username exposing (Username)
import Api.Endpoint as Endpoint
import Api
import Api.User


-- TYPES


type User
    = User Internals


type alias Internals =
    { id : ID
    , createdAt : String
    , updatedAt : String
    , username : Username
    , firstName : String
    , lastName : String
    , email : Email
    , isAdmin : Bool
    , isActive : Bool
    , provider : String
    , providerId : String
    }



-- INFO


id : User -> ID
id (User info) =
    info.id


username : User -> Username
username (User info) =
    info.username


name : User -> String
name (User info) =
    info.firstName ++ " " ++ info.lastName


email : User -> Email
email (User info) =
    info.email


isAdmin : User -> Bool
isAdmin (User info) =
    info.isAdmin



-- SERIALIZATION


decoder : Decoder User
decoder =
    Decode.succeed Internals
        |> required "id" ID.decoder
        |> required "created_at" Decode.string
        |> required "updated_at" Decode.string
        |> required "username" Username.decoder
        |> required "first_name" Decode.string
        |> required "last_name" Decode.string
        |> required "email" Email.decoder
        |> required "is_admin" Decode.bool
        |> required "is_active" Decode.bool
        |> required "provider" Decode.string
        |> required "provider_id" Decode.string
        |> Decode.map User


encode : User -> Value
encode (User info) =
    Encode.object
        [ ( "id", ID.encode info.id )
        , ( "username", Username.encode info.username )
        , ( "first_name", Encode.string info.firstName )
        , ( "last_name", Encode.string info.lastName )
        , ( "email", Email.encode info.email )
        , ( "is_admin", Encode.bool info.isAdmin )
        , ( "is_active", Encode.bool info.isActive )
        ]



-- SESSION


session : Http.Request User
session =
    Api.get Endpoint.session decoder



-- FETCH


get : ID -> Http.Request User
get ident =
    decoder
        |> Api.get (Api.User.get ident)


list : Http.Request (List User)
list =
    Decode.list decoder
        |> Api.get (Api.User.list)
