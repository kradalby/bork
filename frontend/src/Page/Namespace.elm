module Page.Namespace exposing (Model, Msg, init, subscriptions, toSession, update, view)

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
import Email


-- MODEL


type alias Model =
    { session : Session
    , timeZone : Time.Zone
    , errors : List String

    -- Loaded independently from server
    , namespace : Status Namespace
    }


type Status a
    = Loading ID
    | LoadingSlowly ID
    | Loaded a
    | Failed ID


init : Session -> ID -> ( Model, Cmd Msg )
init session id =
    ( { session = session
      , timeZone = Time.utc
      , errors = []
      , namespace = Loading id
      }
    , Cmd.batch
        [ Namespace.fetch id
            |> Http.toTask
            |> Task.mapError (Tuple.pair id)
            |> Task.attempt CompletedNamespaceLoad
        , Task.perform GotTimeZone Time.here
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )


currentID : Model -> ID
currentID model =
    case model.namespace of
        Loading id ->
            id

        LoadingSlowly id ->
            id

        Loaded namespace ->
            Namespace.id namespace

        Failed id ->
            id



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    let
        title =
            case model.namespace of
                Loading id ->
                    defaultTitle <| ID.toString id

                LoadingSlowly id ->
                    defaultTitle <| ID.toString id

                Failed id ->
                    defaultTitle <| ID.toString id

                Loaded namespace ->
                    defaultTitle (Namespace.name namespace)
    in
        { title = title
        , content =
            case model.namespace of
                Loaded namespace ->
                    div [ class "namespace-page" ]
                        [ Page.viewErrors ClickedDismissErrors model.errors
                        , text <| Namespace.name namespace
                        ]

                Loading _ ->
                    text ""

                LoadingSlowly _ ->
                    Loading.icon

                Failed _ ->
                    Loading.error "namespace"
        }



-- PAGE TITLE


defaultTitle : String -> String
defaultTitle identifier =
    "Namespace - " ++ identifier



-- UPDATE


type Msg
    = ClickedDismissErrors
    | CompletedNamespaceLoad (Result ( ID, Http.Error ) Namespace)
    | GotTimeZone Time.Zone
    | GotSession Session
    | PassedSlowLoadThreshold


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedDismissErrors ->
            ( { model | errors = [] }, Cmd.none )

        CompletedNamespaceLoad (Ok namespace) ->
            ( { model | namespace = Loaded namespace }, Cmd.none )

        CompletedNamespaceLoad (Err ( id, err )) ->
            ( { model | namespace = Failed id }
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
    -- Session.changes GotSession (Session.navKey model.session)
    Sub.none



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
