module Page.Namespace.New exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Api
import Api.Endpoint as Endpoint
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
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
    , name : String

    -- Loaded independently from server
    , namespace : Status Namespace
    , prefix : Status String
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
      , name = ""
      , namespace = Loading
      , prefix = Loading
      }
    , Cmd.batch
        [ Namespace.prefix
            |> Http.toTask
            |> Task.attempt CompletedPrefixLoad
        , Task.perform GotTimeZone Time.here
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    let
        title =
            "New Namespace"
    in
        { title = title
        , content =
            div [ class "namespace-page" ] <|
                [ Page.viewErrors ClickedDismissErrors model.errors
                , div [ class "row" ]
                    [ h2 []
                        [ text <| "New namespace"
                        ]
                    ]
                ]
                    ++ case model.prefix of
                        Loaded prefix ->
                            [ div [ class "row" ]
                                [ div [ class "col-12 pt-3 px-0" ]
                                    [ div [ class "input-group input-group-lg" ]
                                        [ div [ class "input-group-prepend" ]
                                            [ span [ class "input-group-text", id "inputGroup-sizing-lg" ]
                                                [ text <| prefix ++ "-" ++ model.name ]
                                            ]
                                        , input [ onInput ChangeName, attribute "aria-describedby" "inputGroup-sizing-sm", attribute "aria-label" "Large", class "form-control", type_ "text" ]
                                            []
                                        , div [ class "input-group-append" ]
                                            [ span [ class "input-group-text", id "inputGroup-sizing-lg" ]
                                                [ text <|
                                                    String.fromInt <|
                                                        (-) 253 <|
                                                            String.length <|
                                                                prefix
                                                                    ++ "-"
                                                                    ++ model.name
                                                ]
                                            ]
                                        ]
                                    ]
                                ]
                            , div [ class "row" ]
                                [ div [ class "col-12 pt-3 px-0" ]
                                    [ button [ class "btn btn-large btn-success float-right", onClick CreateNamespace ] [ text "Create" ] ]
                                ]
                            ]

                        Loading ->
                            [ text "" ]

                        LoadingSlowly ->
                            [ Loading.icon ]

                        Failed ->
                            [ Loading.error "prefix" ]
        }



-- UPDATE


type Msg
    = ClickedDismissErrors
    | GotTimeZone Time.Zone
    | GotSession Session
    | PassedSlowLoadThreshold
    | ChangeName String
    | CreateNamespace
    | CompletedAddNamespace (Result Http.Error Namespace)
    | CompletedPrefixLoad (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedDismissErrors ->
            ( { model | errors = [] }, Cmd.none )

        GotTimeZone tz ->
            ( { model | timeZone = tz }, Cmd.none )

        GotSession session ->
            ( { model | session = session }
            , Route.replaceUrl (Session.navKey session) Route.Home
            )

        PassedSlowLoadThreshold ->
            ( model, Cmd.none )

        ChangeName content ->
            ( { model | name = content }, Cmd.none )

        CreateNamespace ->
            ( model
            , Cmd.batch
                [ Namespace.create model.name
                    |> Http.toTask
                    |> Task.attempt CompletedAddNamespace
                ]
            )

        CompletedAddNamespace (Ok namespace) ->
            ( model
            , Route.replaceUrl
                (Session.navKey model.session)
              <|
                Route.Namespace
                    (Namespace.id namespace)
            )

        CompletedAddNamespace (Err err) ->
            let
                _ =
                    Debug.log "error: " err
            in
                ( model
                , Log.error
                )

        CompletedPrefixLoad (Ok prefix) ->
            ( { model | prefix = Loaded prefix }
            , Cmd.none
            )

        CompletedPrefixLoad (Err err) ->
            ( { model | prefix = Failed }
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
