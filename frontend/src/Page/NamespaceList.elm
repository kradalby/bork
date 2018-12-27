module Page.NamespaceList exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Api
import Api.Endpoint as Endpoint
import Html exposing (..)
import Html.Attributes exposing (..)
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
import User
import Email


-- MODEL


type alias Model =
    { session : Session
    , timeZone : Time.Zone
    , errors : List String

    -- Loaded independently from server
    , namespaces : Status (List Namespace)
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
      , namespaces = Loading
      }
    , Cmd.batch
        [ Namespace.list
            |> Http.toTask
            |> Task.attempt CompletedNamespaceListLoad
        , Task.perform GotTimeZone Time.here
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    let
        title =
            "Namespaces"
    in
        { title = title
        , content =
            case model.namespaces of
                Loaded namespaces ->
                    div [ class "namespaceList-page" ]
                        [ Page.viewErrors ClickedDismissErrors model.errors
                        , viewTable namespaces
                        ]

                Loading ->
                    text ""

                LoadingSlowly ->
                    Loading.icon

                Failed ->
                    Loading.error "namespace list"
        }


viewTable : List Namespace -> Html Msg
viewTable namespaces =
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
        , tbody [] <| List.map viewTableRow namespaces
        ]


viewTableRow : Namespace -> Html Msg
viewTableRow ns =
    tr []
        [ th [ scope "row" ]
            [ a [ Route.href <| Route.Namespace (Namespace.id ns) ] [ text <| Namespace.name ns ] ]
        , td []
            [ a [ Route.href <| Route.Namespace (Namespace.id ns) ] [ text <| ID.toString <| Namespace.id ns ] ]
        , td []
            [ a [ Route.href <| Route.User <| User.id <| Namespace.owner ns ] [ text <| User.name <| Namespace.owner ns ] ]
        ]



-- UPDATE


type Msg
    = ClickedDismissErrors
    | CompletedNamespaceListLoad (Result Http.Error (List Namespace))
    | GotTimeZone Time.Zone
    | GotSession Session
    | PassedSlowLoadThreshold


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedDismissErrors ->
            ( { model | errors = [] }, Cmd.none )

        CompletedNamespaceListLoad (Ok namespaces) ->
            ( { model | namespaces = Loaded namespaces }, Cmd.none )

        CompletedNamespaceListLoad (Err err) ->
            ( { model | namespaces = Failed }
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



-- Sub.none
-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
