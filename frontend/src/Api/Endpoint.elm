module Api.Endpoint
    exposing
        ( Endpoint
        , request
        , url
        , auth
        , session
        )

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
        , headers =
            [ Http.header
                "Content-Type"
                "application/json"
            ]
                ++ config.headers
        , method = config.method
        , timeout = config.timeout
        , url = unwrap config.url
        , withCredentials = config.withCredentials
        }



-- TYPES


{-| Get a URL to the

This is not publicly exposed, because we want to make sure the only way to get one of these URLs is from this module.

-}
type Endpoint
    = Endpoint String


unwrap : Endpoint -> String
unwrap (Endpoint str) =
    str


url : List String -> List QueryParameter -> Endpoint
url paths queryParams =
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
