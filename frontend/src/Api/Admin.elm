module Api.Admin exposing (dashboard)

import Api.Endpoint exposing (Endpoint, url)
import ID exposing (ID)



-- NAMESPACE ENDPOINTS


dashboard : Endpoint
dashboard =
    url [ "admin", "dashboard" ] []
