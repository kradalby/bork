module Api.Error exposing (..)

import Json.Decode as Decode exposing (Decoder)


type alias Error =
    { error : String
    , trace : String
    , code : Int
    }


decoder : Decoder Error
decoder =
    Decode.map3 Error
        (Decode.field "error" Decode.string)
        (Decode.field "trace" Decode.string)
        (Decode.field "code" Decode.int)
