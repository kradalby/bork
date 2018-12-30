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

    -- Loaded independently from server
    , namespace : Status Namespace
    , auth : Status Namespace.Auth
    , config : Status String
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
      , namespace = Loading
      , auth = Loading
      , config = Loading
      }
    , Cmd.batch
        [ Namespace.fetch id
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
                        viewOwners model.session ns

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
    div []
        [ div [ class "row" ]
            [ h3 []
                [ text "Configuration"
                ]
            ]
        , textarea
            [ class "form-control"
            , attribute "rows" "15"
            , value config
            , readonly True
            ]
            []
        , button [ class "btn btn-primary", onClick <| SaveConfig config ] [ text "Download" ]
        ]


viewOwners : Session -> Namespace -> Html Msg
viewOwners session ns =
    div []
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
            [ div [ class "container" ]
                []
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
                , td []
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
            , tbody [] <| primary ++ List.map (userTableRow isOwner ns) users
            ]


userTableRow : Bool -> Namespace -> User -> Html Msg
userTableRow isOwner ns user =
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
        , td []
            [ View.iff isOwner (button [ class "btn btn-danger", onClick (DeleteCoOwner ns user) ] [ text "-" ])
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
            ( { model | namespace = Loaded ns }, Cmd.none )

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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    -- Session.changes GotSession (Session.navKey model.session)
    Sub.none



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
