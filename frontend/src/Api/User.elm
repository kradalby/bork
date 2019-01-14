module Api.User exposing (..)

import Api.Endpoint exposing (Endpoint, url)
import ID exposing (ID)


-- USER ENDPOINTS


list : Endpoint
list =
    url [ "users" ] []


get : ID -> Endpoint
get id =
    url [ "users", ID.toString id ] []


coowned : ID -> Endpoint
coowned id =
    url [ "users", ID.toString id, "coowned" ] []
