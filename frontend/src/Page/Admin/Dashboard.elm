module Page.Admin.Dashboard exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Admin.Dashboard as Dashboard exposing (Dashboard)
import Api
import Api.Endpoint as Endpoint
import Email
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import ID exposing (ID)
import Loading
import Log
import Namespace exposing (Namespace)
import Page
import Page.Misc as Misc
import Route
import Session exposing (Session)
import Task exposing (Task)
import Time
import Url.Builder
import User exposing (User)
import Username exposing (Username)



-- MODEL


type alias Model =
    { session : Session
    , timeZone : Time.Zone
    , errors : List String

    -- Loaded independently from server
    , dashboard : Status Dashboard
    }


type Status a
    = Loading
    | LoadingSlowly
    | Loaded a
    | Failed


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , timeZone = Time.utc
      , errors = []
      , dashboard = Loading
      }
    , Cmd.batch
        [ Dashboard.get
            |> Http.toTask
            |> Task.attempt CompletedDashboardLoad
        , Task.perform GotTimeZone Time.here
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Admin: Dashboard"
    , content =
        case model.dashboard of
            Loaded dashboard ->
                div [ class "admin-dashboard-page" ]
                    [ Page.viewErrors ClickedDismissErrors model.errors
                    , h2 [] [ text "Admin: Dashboard" ]
                    , div [ class "row pb-3" ]
                        [ viewCount "Users" (Dashboard.usersCount dashboard)
                        , viewCount "Namespaces" (Dashboard.namespacesCount dashboard)
                        ]
                    , div [ class "row pb-3" ]
                        [ viewUsers (Dashboard.usersNew dashboard)
                        , viewNamespaces (Dashboard.namespacesNew dashboard)
                        ]
                    ]

            Loading ->
                text ""

            LoadingSlowly ->
                Loading.icon

            Failed ->
                Loading.error "dashboard"
    }


viewCount : String -> Int -> Html Msg
viewCount title count =
    div [ class "col-6" ]
        [ div [ class "card" ]
            [ div [ class "card-header" ]
                [ text title ]
            , div [ class "card-body" ]
                [ h1 [ class "display-2" ]
                    [ text <| String.fromInt count ]
                ]
            ]
        ]


viewUsers : List User -> Html Msg
viewUsers users =
    div [ class "col-6" ]
        [ div [ class "card" ]
            [ div [ class "card-header" ]
                [ text "New users" ]
            , ul [ class "list-group list-group-flush" ] <|
                List.map viewUser users
            ]
        ]


viewUser : User -> Html Msg
viewUser user =
    li [ class "list-group-item" ]
        [ a
            [ Route.href <| Route.User <| User.id user ]
            [ text (User.name user) ]
        ]


viewNamespaces : List Namespace -> Html Msg
viewNamespaces users =
    div [ class "col-6" ]
        [ div [ class "card" ]
            [ div [ class "card-header" ]
                [ text "New namespaces" ]
            , ul [ class "list-group list-group-flush" ] <|
                List.map viewNamespace users
            ]
        ]


viewNamespace : Namespace -> Html Msg
viewNamespace user =
    li [ class "list-group-item" ]
        [ a
            [ Route.href <| Route.Namespace <| Namespace.id user ]
            [ text (Namespace.name user) ]
        ]


type Msg
    = ClickedDismissErrors
    | CompletedDashboardLoad (Result Http.Error Dashboard)
      --    | CompletedFeedLoad (Result ( Username, Http.Error ) Feed.Model)
    | GotTimeZone Time.Zone
    | GotSession Session
    | PassedSlowLoadThreshold


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedDismissErrors ->
            ( { model | errors = [] }, Cmd.none )

        CompletedDashboardLoad (Ok dashboard) ->
            ( { model | dashboard = Loaded dashboard }, Cmd.none )

        CompletedDashboardLoad (Err err) ->
            ( { model | errors = [ Misc.httpErrorToUserError err ], dashboard = Failed }
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Session.changes GotSession (Session.navKey model.session)



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
