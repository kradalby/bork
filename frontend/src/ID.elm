module ID exposing (ID, decoder, encode, toString, urlParser)

import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Url.Parser exposing (Parser)


-- TYPES


type ID
    = ID String



-- CREATE


urlParser : Parser (ID -> a) a
urlParser =
    Url.Parser.custom "ID" (\str -> Just (ID str))


decoder : Decoder ID
decoder =
    Decode.map ID Decode.string


encode : ID -> Value
encode (ID str) =
    Encode.string str



-- TRANSFORM


toString : ID -> String
toString (ID str) =
    str
