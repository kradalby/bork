module Page.User exposing (Model, Msg, init, subscriptions, toSession, update, view)

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
import User exposing (User)
import Username exposing (Username)
import Email


-- MODEL


type alias Model =
    { session : Session
    , timeZone : Time.Zone
    , errors : List String

    -- Loaded independently from server
    , user : Status User
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
      , user = Loading id
      }
    , Cmd.batch
        [ User.fetch id
            |> Http.toTask
            |> Task.mapError (Tuple.pair id)
            |> Task.attempt CompletedUserLoad
        , Task.perform GotTimeZone Time.here
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )


currentID : Model -> ID
currentID model =
    case model.user of
        Loading id ->
            id

        LoadingSlowly id ->
            id

        Loaded user ->
            User.id user

        Failed id ->
            id



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    let
        title =
            case model.user of
                Loading id ->
                    titleForMe (Session.user model.session) id

                LoadingSlowly id ->
                    titleForMe (Session.user model.session) id

                Failed id ->
                    titleForMe (Session.user model.session) id

                Loaded user ->
                    titleForMe (Session.user model.session) (User.id user)
    in
        { title = title
        , content =
            case model.user of
                Loaded user ->
                    div [ class "user-page" ]
                        [ Page.viewErrors ClickedDismissErrors model.errors
                        , text <| User.name user
                        , text <| Email.toString <| User.email user
                        , text <| Username.toString <| User.username user
                        ]

                Loading _ ->
                    text ""

                LoadingSlowly _ ->
                    Loading.icon

                Failed _ ->
                    Loading.error "user"
        }



-- PAGE TITLE


titleForOther : Username -> String
titleForOther otherUsername =
    "Profile — " ++ Username.toString otherUsername


titleForMe : Maybe User -> ID -> String
titleForMe maybeUser id =
    case maybeUser of
        Just user ->
            if id == User.id user then
                myProfileTitle
            else
                defaultTitle

        Nothing ->
            defaultTitle


myProfileTitle : String
myProfileTitle =
    "My Profile"


defaultTitle : String
defaultTitle =
    "Profile"



-- UPDATE


type Msg
    = ClickedDismissErrors
    | CompletedUserLoad (Result ( ID, Http.Error ) User)
    | GotTimeZone Time.Zone
    | GotSession Session
    | PassedSlowLoadThreshold


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedDismissErrors ->
            ( { model | errors = [] }, Cmd.none )

        CompletedUserLoad (Ok user) ->
            ( { model | user = Loaded user }, Cmd.none )

        CompletedUserLoad (Err ( id, err )) ->
            ( { model | user = Failed id }
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
