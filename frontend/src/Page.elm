module Page exposing (Page(..), view, viewErrors)

import Api
import Browser exposing (Document)
import Html exposing (Html, a, button, div, footer, header, i, img, li, main_, nav, p, span, text, ul)
import Html.Attributes exposing (class, classList, href, style)
import Html.Events exposing (onClick)
import Route exposing (Route)
import Session exposing (Session)
import ID exposing (ID)
import User exposing (User)
import Username
import Alert


{-| Determines which navbar link (if any) will be rendered as active.

Note that we don't enumerate every page here, because the navbar doesn't
have links for every page. Anything that's not part of the navbar falls
under Other.

-}
type Page
    = Other
    | Home
      --  | Settings
    | User ID
      --  | UserList
    | Namespace ID
    | NamespaceList
    | NamespaceNew


{-| Take a page's Html and frames it with a header and footer.

The caller provides the current user, so we can display in either
"signed in" (rendering username) or "signed out" mode.

isLoading is for determining whether we should show a loading spinner
in the header. (This comes up during slow page transitions.)

-}
view : Maybe User -> Page -> { title : String, content : Html msg } -> Document msg
view maybeUser page { title, content } =
    { title = title ++ " - bork"
    , body = viewHeader page maybeUser :: (viewMain content) :: [ viewFooter ]
    }


viewHeader : Page -> Maybe User -> Html msg
viewHeader page maybeUser =
    header []
        [ nav [ class "navbar navbar-expand-md navbar-dark fixed-top bg-dark" ]
            [ div [ class "container pl-0" ]
                [ a [ class "navbar-brand", Route.href Route.Home ]
                    [ text "bork" ]
                , ul [ class "nav navbar-nav pull-xs-right" ] <|
                    -- navbarLink page Route.Home [ text "Home" ]
                    -- ::
                    viewMenu page maybeUser
                ]
            ]
        ]


viewMenu : Page -> Maybe User -> List (Html msg)
viewMenu page maybeUser =
    let
        linkTo =
            navbarLink page
    in
        case maybeUser of
            Just user ->
                let
                    id =
                        User.id user

                    username =
                        User.username user
                in
                    [ linkTo Route.NamespaceNew [ text "New" ]
                    , linkTo Route.NamespaceList [ text "Namespaces" ]

                    --                   , linkTo Route.UserList [ text "Users " ]
                    --                   , linkTo Route.Settings [ text "Settings" ]
                    , linkTo
                        (Route.User id)
                        [ Username.toHtml username
                        ]

                    -- , linkTo Route.Logout [ text "Sign out" ]
                    ]

            Nothing ->
                [ li [ classList [ ( "nav-item", True ), ( "active", True ) ] ]
                    [ a [ class "nav-link", href "/auth/openid-connect" ] [ text "Sign in" ] ]
                ]


viewMain : Html msg -> Html msg
viewMain content =
    main_ [ class "container" ] [ content ]


viewFooter : Html msg
viewFooter =
    footer [ class "footer" ]
        [ div [ class "container" ]
            [ span [ class "attribution" ]
                [ a [ href "https://elm-lang.org" ] [ text "elm" ]
                , text ", "
                , a [ href "https://golang.org" ] [ text "go" ]
                , text " and "
                , a [ href "https://kubernetes.io" ] [ text "kubernetes" ]
                , text " by "
                , a [ href "https://kradalby.no" ] [ text "kradalby" ]
                ]
            ]
        ]


navbarLink : Page -> Route -> List (Html msg) -> Html msg
navbarLink page route linkContent =
    li [ classList [ ( "nav-item", True ), ( "active", isActive page route ) ] ]
        [ a [ class "nav-link", Route.href route ] linkContent ]


isActive : Page -> Route -> Bool
isActive page route =
    case ( page, route ) of
        -- ( Home, Route.Home ) ->
        --     True
        --        ( Settings, Route.Settings ) ->
        --            True
        ( User id1, Route.User id2 ) ->
            id1 == id2

        --        ( UserList, Route.UserList ) ->
        --            True
        ( NamespaceNew, Route.NamespaceNew ) ->
            True

        ( NamespaceList, Route.NamespaceList ) ->
            True

        _ ->
            False


{-| Render dismissable errors. We use this all over the place!
-}
viewErrors : msg -> List String -> Html msg
viewErrors dismissErrors errors =
    if List.isEmpty errors then
        Html.text ""
    else
        Alert.view (Alert.error dismissErrors errors)
