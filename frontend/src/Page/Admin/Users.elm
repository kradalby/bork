module Page.Admin.Users exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Api
import Api.Endpoint as Endpoint
import Email
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import ID exposing (ID)
import Loading
import Log
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
    , users : Status (List User)
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
      , users = Loading
      }
    , Cmd.batch
        [ User.list
            |> Http.toTask
            |> Task.attempt CompletedUsersLoad
        , Task.perform GotTimeZone Time.here
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Admin: Users"
    , content =
        case model.users of
            Loaded users ->
                div [ class "profile-page" ]
                    [ Page.viewErrors ClickedDismissErrors model.errors
                    , h2 [] [ text "Admin: Users" ]
                    , table [ class "table table-striped" ]
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
                        , tbody [] <| List.map userTableRow users
                        ]
                    ]

            Loading ->
                text ""

            LoadingSlowly ->
                Loading.icon

            Failed ->
                Loading.error "profile"
    }


userTableRow : User -> Html Msg
userTableRow user =
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
        ]


type Msg
    = ClickedDismissErrors
    | CompletedUsersLoad (Result Http.Error (List User))
      --    | CompletedFeedLoad (Result ( Username, Http.Error ) Feed.Model)
    | GotTimeZone Time.Zone
    | GotSession Session
    | PassedSlowLoadThreshold


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedDismissErrors ->
            ( { model | errors = [] }, Cmd.none )

        CompletedUsersLoad (Ok users) ->
            ( { model | users = Loaded users }, Cmd.none )

        CompletedUsersLoad (Err err) ->
            ( { model | errors = [ Misc.httpErrorToUserError err ], users = Failed }
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
