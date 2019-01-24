module Page.Namespace.List exposing (Model, Msg, init, subscriptions, toSession, update, view)

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
import Page.View as View
import Page.Misc as Misc


-- MODEL


type alias Model =
    { session : Session
    , timeZone : Time.Zone
    , errors : List String

    -- Loaded independently from server
    , namespaces : Status (List Namespace)
    , namespacesCoOwner : Status (List Namespace)
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
      , namespacesCoOwner = Loading
      }
    , Cmd.batch
        [ Namespace.list
            |> Http.toTask
            |> Task.attempt CompletedNamespaceListLoad
        , Task.perform GotTimeZone Time.here
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        , case Session.id session of
            Nothing ->
                Cmd.none

            Just id ->
                Namespace.coowned id
                    |> Http.toTask
                    |> Task.attempt CompletedNamespacesCoOwnerLoad
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
            div [ class "namespaces-page" ]
                [ Page.viewErrors ClickedDismissErrors model.errors
                , case model.namespaces of
                    Loaded namespaces ->
                        viewNamespaces "Namespaces" namespaces

                    Loading ->
                        -- text ""
                        Loading.icon

                    LoadingSlowly ->
                        Loading.icon

                    Failed ->
                        Loading.error "namespaces"
                , div [ class "row" ]
                    [ div [ class "col-12 pb-5 px-0" ]
                        [ a [ Route.href Route.NamespaceNew ]
                            [ button
                                [ class "btn btn-success btn-large float-right"
                                ]
                                [ text "New" ]
                            ]
                        ]
                    ]
                , case model.namespacesCoOwner of
                    Loaded namespaces ->
                        viewNamespaces "Co-Owner Namespaces" namespaces

                    Loading ->
                        -- text ""
                        Loading.icon

                    LoadingSlowly ->
                        Loading.icon

                    Failed ->
                        Loading.error "namespaces coowner"
                ]
        }


viewNamespaces : String -> List Namespace -> Html Msg
viewNamespaces title namespaces =
    div [ class "" ]
        [ div [ class "row" ]
            [ h2 []
                [ text title
                ]
            , View.namespaceTable namespaces
            ]
        ]



-- UPDATE


type Msg
    = ClickedDismissErrors
    | CompletedNamespaceListLoad (Result Http.Error (List Namespace))
    | CompletedNamespacesCoOwnerLoad (Result Http.Error (List Namespace))
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
            ( { model | errors = [ Misc.httpErrorToUserError err ], namespaces = Failed }
            , Log.error
            )

        CompletedNamespacesCoOwnerLoad (Ok namespaces) ->
            ( { model | namespacesCoOwner = Loaded namespaces }, Cmd.none )

        CompletedNamespacesCoOwnerLoad (Err err) ->
            ( { model | errors = [ Misc.httpErrorToUserError err ], namespacesCoOwner = Failed }
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
