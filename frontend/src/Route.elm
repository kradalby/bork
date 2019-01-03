module Route exposing (Route(..), fromUrl, href, replaceUrl)

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, string)
import ID exposing (ID)


-- ROUTING


type Route
    = Home
    | Root
      -- | Settings
    | Namespace ID
    | NamespaceNew
    | NamespaceList
    | User ID



-- | UserList


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Home Parser.top

        -- , Parser.map Settings (s "settings")
        , Parser.map NamespaceNew (s "namespaces" </> s "new")
        , Parser.map Namespace (s "namespaces" </> ID.urlParser)
        , Parser.map NamespaceList (s "namespaces")
        , Parser.map User (s "users" </> ID.urlParser)

        -- , Parser.map UserList (s "users")
        ]



-- PUBLIC HELPERS


href : Route -> Attribute msg
href targetRoute =
    Attr.href (routeToString targetRoute)


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (routeToString route)


fromUrl : Url -> Maybe Route
fromUrl url =
    -- The RealWorld spec treats the fragment like a path.
    -- This makes it *literally* the path, so we can proceed
    -- with parsing as if it had been a normal path all along.
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }
        |> Parser.parse parser



-- INTERNAL


routeToString : Route -> String
routeToString page =
    let
        pieces =
            case page of
                Home ->
                    []

                Root ->
                    []

                --   Settings ->
                --       [ "settings" ]
                Namespace id ->
                    [ "namespaces", ID.toString id ]

                NamespaceNew ->
                    [ "namespaces", "new" ]

                NamespaceList ->
                    [ "namespaces" ]

                User id ->
                    [ "users", ID.toString id ]

        --                UserList ->
        --                    [ "users" ]
    in
        "#/" ++ String.join "/" pieces
