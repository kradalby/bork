module Page.Namespace exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Api
import Api.Endpoint as Endpoint
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Loading
import Log
import Page
import Route
import Session exposing (Session)
import Task exposing (Task)
import Time
import Url.Builder
import ID exposing (ID)
import Namespace exposing (Namespace)
import Email
import User exposing (User)
import Username
import Page.View as View
import File.Download as Download
import Page.Misc as Misc


-- MODEL


type alias Model =
    { session : Session
    , timeZone : Time.Zone
    , errors : List String

    -- View related
    , addOwnerModal : Bool

    -- Loaded independently from server
    , namespace : Status Namespace
    , auth : Status Namespace.Auth
    , config : Status String
    , users : Status (List User)
    }


type Status a
    = Loading
    | LoadingSlowly
    | Loaded a
    | Failed


init : Session -> ID -> ( Model, Cmd Msg )
init session id =
    ( { session = session
      , timeZone = Time.utc
      , errors = []
      , addOwnerModal = False
      , namespace = Loading
      , auth = Loading
      , config = Loading
      , users = Loading
      }
    , Cmd.batch
        [ Namespace.get id
            |> Http.toTask
            |> Task.mapError (Tuple.pair id)
            |> Task.attempt CompletedNamespaceLoad
        , Namespace.auth id
            |> Http.toTask
            |> Task.mapError (Tuple.pair id)
            |> Task.attempt CompletedAuthLoad
        , Namespace.config id
            |> Http.toTask
            |> Task.mapError (Tuple.pair id)
            |> Task.attempt CompletedConfigLoad
        , Task.perform GotTimeZone Time.here
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    let
        title =
            case model.namespace of
                Loaded namespace ->
                    defaultTitle (Namespace.name namespace)

                Failed ->
                    defaultTitle "Failed"

                _ ->
                    defaultTitle "Loading"
    in
        { title = title
        , content =
            div [ class "namespace-page" ]
                [ Page.viewErrors ClickedDismissErrors model.errors
                , div [ class "row" ]
                    [ h2 []
                        [ text <| "Namespace"
                        ]
                    ]
                , case model.namespace of
                    Loaded ns ->
                        div []
                            [ View.iff model.addOwnerModal (addOwnerModal model.users ns)
                            , viewOwners model.session ns
                            ]

                    Loading ->
                        text ""

                    LoadingSlowly ->
                        Loading.icon

                    Failed ->
                        Loading.error "namespace"
                , case model.auth of
                    Loaded auth ->
                        text ""

                    Loading ->
                        text ""

                    LoadingSlowly ->
                        Loading.icon

                    Failed ->
                        Loading.error "auth"
                , case model.config of
                    Loaded config ->
                        viewConfig config

                    Loading ->
                        text ""

                    LoadingSlowly ->
                        Loading.icon

                    Failed ->
                        Loading.error "config"
                ]
        }


viewConfig : String -> Html Msg
viewConfig config =
    div [ class "col-12 px-0" ]
        [ div [ class "row" ]
            [ h3 []
                [ text "Configuration"
                ]
            ]
        , div [ class "row" ]
            [ textarea
                [ class "form-control"
                , attribute "rows" "15"
                , value config
                , readonly True
                ]
                []
            ]
        , div [ class "row" ]
            [ div [ class "col-12 px-0" ]
                [ button
                    [ class "btn btn-primary mt-3 mb-3 float-right"
                    , onClick <| SaveConfig config
                    ]
                    [ text "Download" ]
                ]
            ]
        ]


viewOwners : Session -> Namespace -> Html Msg
viewOwners session ns =
    let
        user =
            Namespace.owner ns

        isOwner =
            Misc.isOwner session (User.id user)
    in
        div [ class "col-12 px-0" ]
            [ div [ class "row" ]
                [ h3 []
                    [ text "Users"
                    ]
                ]
            , div [ class "row" ]
                [ div [ class "col-6" ] [ text "Created " ]
                , div [ class "col-6" ]
                    [ h5 []
                        [ text <| Namespace.created ns
                        ]
                    ]
                ]
            , div [ class "row" ]
                [ userTable session ns ]
            , div [ class "row" ]
                [ div [ class "col-12 px-0" ]
                    [ View.iff isOwner <|
                        button [ class "btn btn-success float-right", onClick ToggleAddOwnerModal ] [ text "Add" ]
                    ]
                ]
            ]


userTable : Session -> Namespace -> Html Msg
userTable session ns =
    let
        user =
            Namespace.owner ns

        users =
            Namespace.coOwners ns

        primary =
            [ tr [ class "table-primary" ]
                [ th [ scope "row" ]
                    [ a
                        [ Route.href <|
                            Route.User (User.id user)
                        ]
                        [ text <| User.name user ]
                    ]
                , td []
                    [ a
                        [ Route.href <|
                            Route.User (User.id user)
                        ]
                        [ text <| Username.toString <| User.username user ]
                    ]
                , td [ colspan 2 ]
                    [ a
                        [ href <|
                            "mailto:"
                                ++ (Email.toString <| User.email user)
                        ]
                        [ text <| Email.toString <| User.email user ]
                    ]
                ]
            ]

        isOwner =
            Misc.isOwner session (User.id user)
    in
        table [ class "table table-striped" ]
            [ thead []
                [ tr []
                    [ th [ scope "col" ]
                        [ text "Name" ]
                    , th [ scope "col" ]
                        [ text "Username" ]
                    , th [ scope "col", colspan 2 ]
                        [ text "Email" ]
                    ]
                ]
            , tbody [] <| primary ++ List.map (userTableRowDelete isOwner ns) users
            ]


userTableRowDelete : Bool -> Namespace -> User -> Html Msg
userTableRowDelete isOwner ns user =
    let
        btn =
            View.iff isOwner <|
                button [ class "btn btn-danger btn-sm float-right", onClick (DeleteCoOwner ns user) ] [ text "Remove" ]
    in
        userTableRow btn user


userTableRowAdd : Bool -> Namespace -> User -> Html Msg
userTableRowAdd isOwner ns user =
    let
        btn =
            View.iff isOwner <|
                button [ class "btn btn-success", onClick (AddCoOwner ns user) ] [ text "+" ]
    in
        userTableRow btn user


userTableRow : Html Msg -> User -> Html Msg
userTableRow modifier user =
    tr []
        [ th [ scope "row" ]
            [ a
                [ Route.href <|
                    Route.User (User.id user)
                ]
                [ text <| User.name user ]
            ]
        , td []
            [ a
                [ Route.href <|
                    Route.User (User.id user)
                ]
                [ text <| Username.toString <| User.username user ]
            ]
        , td []
            [ a
                [ href <|
                    "mailto:"
                        ++ (Email.toString <| User.email user)
                ]
                [ text <| Email.toString <| User.email user ]
            ]
        , td [ class "pb-1 pt-2" ]
            [ modifier
            ]
        ]


addOwnerModal : Status (List User) -> Namespace -> Html Msg
addOwnerModal users ns =
    div [ style "display" "block", attribute "aria-hidden" "false", attribute "aria-labelledby" "helpModal", class "modal", id "helpModal", attribute "role" "dialog", attribute "tabindex" "-1" ]
        [ div [ class "modal-dialog modal-dialog-centered", attribute "role" "document" ]
            [ div [ class "modal-content" ]
                [ div [ class "modal-header" ]
                    [ h5 [ class "modal-title", id "helpModalTitle" ]
                        [ text "Add Co Owner" ]
                    , button [ onClick ToggleAddOwnerModal, attribute "aria-label" "Close", class "close", attribute "data-dismiss" "modal", type_ "button" ]
                        [ span [ attribute "aria-hidden" "true" ]
                            [ text "×" ]
                        ]
                    ]
                , div [ class "modal-body" ]
                    [ case users of
                        Loaded u ->
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
                                , tbody [] <| List.map (userTableRowAdd True ns) u
                                ]

                        Loading ->
                            text ""

                        LoadingSlowly ->
                            Loading.icon

                        Failed ->
                            Loading.error "users"
                    ]
                , div [ class "modal-footer" ]
                    [ button [ onClick ToggleAddOwnerModal, class "btn btn-secondary", attribute "data-dismiss" "modal", type_ "button" ]
                        [ text "Close" ]
                    ]
                ]
            ]
        ]



-- PAGE TITLE


defaultTitle : String -> String
defaultTitle identifier =
    "Namespace - " ++ identifier



-- UPDATE


type Msg
    = ClickedDismissErrors
    | CompletedNamespaceLoad (Result ( ID, Http.Error ) Namespace)
    | CompletedAuthLoad (Result ( ID, Http.Error ) Namespace.Auth)
    | CompletedConfigLoad (Result ( ID, Http.Error ) String)
    | GotTimeZone Time.Zone
    | GotSession Session
    | PassedSlowLoadThreshold
    | SaveConfig String
    | AddCoOwner Namespace User
    | CompletedAddCoOwner (Result ( ID, Http.Error ) Namespace)
    | DeleteCoOwner Namespace User
    | CompletedDeleteCoOwner (Result ( ID, Http.Error ) Namespace)
    | ToggleAddOwnerModal
    | CompletedUsersLoad (Result Http.Error (List User))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedDismissErrors ->
            ( { model | errors = [] }, Cmd.none )

        CompletedNamespaceLoad (Ok namespace) ->
            ( { model | namespace = Loaded namespace }, Cmd.none )

        CompletedNamespaceLoad (Err ( id, err )) ->
            ( { model | namespace = Failed }
            , Log.error
            )

        CompletedAuthLoad (Ok auth) ->
            ( { model | auth = Loaded auth }, Cmd.none )

        CompletedAuthLoad (Err ( id, err )) ->
            ( { model | auth = Failed }
            , Log.error
            )

        CompletedConfigLoad (Ok config) ->
            ( { model | config = Loaded config }, Cmd.none )

        CompletedConfigLoad (Err ( id, err )) ->
            ( { model | config = Failed }
            , Log.error
            )

        GotTimeZone tz ->
            ( { model | timeZone = tz }, Cmd.none )

        GotSession session ->
            ( { model | session = session }
            , Route.replaceUrl (Session.navKey session) Route.Home
            )

        PassedSlowLoadThreshold ->
            ( model, Cmd.none )

        SaveConfig content ->
            ( model
            , Cmd.batch
                [ Download.string "config" "text/yaml" content
                ]
            )

        AddCoOwner ns user ->
            let
                id =
                    Namespace.id ns
            in
                ( model
                , Cmd.batch
                    [ Namespace.addCoOwner id user
                        |> Http.toTask
                        |> Task.mapError (Tuple.pair id)
                        |> Task.attempt CompletedAddCoOwner
                    ]
                )

        CompletedAddCoOwner (Ok ns) ->
            ( { model | namespace = Loaded ns }
            , Cmd.batch
                [ Namespace.availableUsers (Namespace.id ns)
                    |> Http.toTask
                    |> Task.attempt CompletedUsersLoad
                ]
            )

        CompletedAddCoOwner (Err ( id, err )) ->
            ( { model | namespace = Failed }
            , Log.error
            )

        DeleteCoOwner ns user ->
            let
                id =
                    Namespace.id ns
            in
                ( model
                , Cmd.batch
                    [ Namespace.deleteCoOwner id user
                        |> Http.toTask
                        |> Task.mapError (Tuple.pair id)
                        |> Task.attempt CompletedDeleteCoOwner
                    ]
                )

        CompletedDeleteCoOwner (Ok ns) ->
            ( { model | namespace = Loaded ns }, Cmd.none )

        CompletedDeleteCoOwner (Err ( id, err )) ->
            ( { model | namespace = Failed }
            , Log.error
            )

        ToggleAddOwnerModal ->
            ( { model | addOwnerModal = not model.addOwnerModal }
            , Cmd.batch
                [ case model.namespace of
                    Loaded ns ->
                        Namespace.availableUsers (Namespace.id ns)
                            |> Http.toTask
                            |> Task.attempt CompletedUsersLoad

                    _ ->
                        Cmd.none
                ]
            )

        CompletedUsersLoad (Ok users) ->
            ( { model | users = Loaded users }, Cmd.none )

        CompletedUsersLoad (Err err) ->
            ( { model | users = Failed }
            , Log.error
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    -- Session.changes GotSession (Session.navKey model.session)
    Sub.none



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
