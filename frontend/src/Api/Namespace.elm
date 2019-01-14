module Api.Namespace exposing (..)

import Api.Endpoint exposing (Endpoint, url)
import ID exposing (ID)


-- NAMESPACE ENDPOINTS


list : Endpoint
list =
    url [ "namespaces" ] []


get : ID -> Endpoint
get id =
    url [ "namespaces", ID.toString id ] []


create : Endpoint
create =
    list


coOwner : ID -> Endpoint
coOwner id =
    url [ "namespaces", ID.toString id, "coowners" ] []


availableUsers : ID -> Endpoint
availableUsers id =
    url [ "namespaces", ID.toString id, "available_users" ] []


endpoint : ID -> Endpoint
endpoint id =
    url [ "namespaces", ID.toString id, "endpoint" ] []


token : ID -> Endpoint
token id =
    url [ "namespaces", ID.toString id, "token" ] []


certificate : ID -> Endpoint
certificate id =
    url [ "namespaces", ID.toString id, "certificate" ] []


certificateB64 : ID -> Endpoint
certificateB64 id =
    url [ "namespaces", ID.toString id, "certificateb64" ] []


auth : ID -> Endpoint
auth id =
    url [ "namespaces", ID.toString id, "auth" ] []


config : ID -> Endpoint
config id =
    url [ "namespaces", ID.toString id, "config" ] []


prefix : Endpoint
prefix =
    url [ "namespaces", "prefix" ] []
