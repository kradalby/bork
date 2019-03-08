module Api.Error exposing (Error, decoder)

import Json.Decode as Decode exposing (Decoder)


type alias Error =
    { error : String
    , code : Int
    , trace : Maybe String
    }


decoder : Decoder Error
decoder =
    Decode.map3 Error
        (Decode.field "error" Decode.string)
        (Decode.field "code" Decode.int)
        (Decode.maybe (Decode.field "trace" Decode.string))
