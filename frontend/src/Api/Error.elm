module Api.Error exposing (Error, decoder)

import Json.Decode as Decode exposing (Decoder)


type alias Error =
    { error : String
    , trace : Maybe String
    , code : Int
    }


decoder : Decoder Error
decoder =
    Decode.map3 Error
        (Decode.field "error" Decode.string)
        (Decode.field "trace" (Decode.nullable Decode.string))
        (Decode.field "code" Decode.int)
