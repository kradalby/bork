module Api.Endpoint exposing (Endpoint, request, user, users, auth, session, namespace, namespaces, namespaceToken, namespaceCertificate, namespaceCertificateB64, namespaceAuth)

import ID as ID exposing (ID)
import Http
import Url.Builder exposing (QueryParameter)
import Username exposing (Username)


{-| Http.request, except it takes an Endpoint instead of a Url.
-}
request :
    { body : Http.Body
    , expect : Http.Expect a
    , headers : List Http.Header
    , method : String
    , timeout : Maybe Float
    , url : Endpoint
    , withCredentials : Bool
    }
    -> Http.Request a
request config =
    Http.request
        { body = config.body
        , expect = config.expect
        , headers = config.headers
        , method = config.method
        , timeout = config.timeout
        , url = unwrap config.url
        , withCredentials = config.withCredentials
        }



-- TYPES


{-| Get a URL to the Conduit API.

This is not publicly exposed, because we want to make sure the only way to get one of these URLs is from this module.

-}
type Endpoint
    = Endpoint String


unwrap : Endpoint -> String
unwrap (Endpoint str) =
    str


url : List String -> List QueryParameter -> Endpoint
url paths queryParams =
    -- NOTE: Url.Builder takes care of percent-encoding special URL characters.
    -- See https://package.elm-lang.org/packages/elm/url/latest/Url#percentEncode
    -- Url.Builder.crossOrigin "https://conduit.productionready.io"
    Url.Builder.absolute
        ([ "api", "v1" ] ++ paths)
        queryParams
        |> Endpoint



-- USER ENDPOINTS


auth : Endpoint
auth =
    Url.Builder.absolute
        [ "auth" ]
        []
        |> Endpoint


session : Endpoint
session =
    Url.Builder.absolute
        [ "auth", "session" ]
        []
        |> Endpoint


users : Endpoint
users =
    url [ "users" ] []


user : ID -> Endpoint
user id =
    url [ "users", ID.toString id ] []



-- NAMESPACE ENDPOINTS


namespaces : Endpoint
namespaces =
    url [ "namespaces" ] []


namespace : ID -> Endpoint
namespace id =
    url [ "namespaces", ID.toString id ] []


namespaceToken : ID -> Endpoint
namespaceToken id =
    url [ "namespaces", ID.toString id, "token" ] []


namespaceCertificate : ID -> Endpoint
namespaceCertificate id =
    url [ "namespaces", ID.toString id, "certificate" ] []


namespaceCertificateB64 : ID -> Endpoint
namespaceCertificateB64 id =
    url [ "namespaces", ID.toString id, "certificateb64" ] []


namespaceAuth : ID -> Endpoint
namespaceAuth id =
    url [ "namespaces", ID.toString id, "auth" ] []
