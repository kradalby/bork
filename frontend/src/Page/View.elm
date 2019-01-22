module Page.View
    exposing
        ( namespaceTable
        , userTable
        , userTableWithPrimary
        , iff
        , namespaceNameInput
        )

import Route
import ID exposing (ID)
import Namespace exposing (Namespace)
import User exposing (User)
import Username
import Email
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


iff : Bool -> Html msg -> Html msg
iff condition content =
    if condition then
        content
    else
        Html.text ""


namespaceTable : List Namespace -> Html msg
namespaceTable namespaces =
    table [ class "table table-striped" ]
        [ thead []
            [ tr []
                [ th [ scope "col" ]
                    [ text "Namespace" ]
                , th [ scope "col" ]
                    [ text "ID" ]
                , th [ scope "col" ]
                    [ text "Owner" ]
                ]
            ]
        , tbody [] <| List.map namespaceTableRow namespaces
        ]


namespaceTableRow : Namespace -> Html msg
namespaceTableRow ns =
    tr []
        [ th [ scope "row" ]
            [ a [ Route.href <| Route.Namespace (Namespace.id ns) ] [ text <| Namespace.name ns ] ]
        , td []
            [ a [ Route.href <| Route.Namespace (Namespace.id ns) ] [ text <| ID.toString <| Namespace.id ns ] ]
        , td []
            [ a [ Route.href <| Route.User <| User.id <| Namespace.owner ns ] [ text <| User.name <| Namespace.owner ns ] ]
        ]


userTable : List User -> Html msg
userTable users =
    userTableInternal Nothing users


userTableWithPrimary : User -> List User -> Html msg
userTableWithPrimary user users =
    userTableInternal (Just user) users


userTableInternal : Maybe User -> List User -> Html msg
userTableInternal user users =
    let
        primary =
            case user of
                Nothing ->
                    []

                Just u ->
                    [ userTableRowWithClasses "table-primary" u ]
    in
        table [ class "table table-striped" ]
            [ thead []
                [ tr []
                    [ th [ scope "col" ]
                        [ text "Name" ]
                    , th [ scope "col" ]
                        [ text "Username" ]
                    , th [ scope "col" ]
                        [ text "Email" ]
                    ]
                ]
            , tbody [] <| primary ++ List.map userTableRow users
            ]


userTableRow : User -> Html msg
userTableRow user =
    userTableRowWithClasses "" user


userTableRowWithClasses : String -> User -> Html msg
userTableRowWithClasses class_ user =
    tr [ class class_ ]
        [ th [ scope "row" ]
            [ a [ Route.href <| Route.User (User.id user) ] [ text <| User.name user ] ]
        , td []
            [ a [ Route.href <| Route.User (User.id user) ] [ text <| Username.toString <| User.username user ] ]
        , td []
            [ a [ href <| "mailto:" ++ (Email.toString <| User.email user) ] [ text <| Email.toString <| User.email user ] ]
        ]


namespaceNameInput : String -> String -> (String -> msg) -> Html msg
namespaceNameInput prefix name onMsg =
    div [ class "input-group input-group-lg" ]
        [ div [ class "input-group-prepend" ]
            [ span [ class "input-group-text", id "inputGroup-sizing-lg" ]
                [ text <| prefix ++ "-" ]
            ]
        , input [ onInput onMsg, attribute "aria-describedby" "inputGroup-sizing-sm", attribute "aria-label" "Large", class "form-control", type_ "text" ]
            []
        , div [ class "input-group-append" ]
            [ span [ class "input-group-text", id "inputGroup-sizing-lg" ]
                [ text <|
                    String.fromInt <|
                        (-) 253 <|
                            String.length <|
                                prefix
                                    ++ "-"
                                    ++ name
                ]
            ]
        ]
