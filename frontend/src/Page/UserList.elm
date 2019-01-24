module Page.UserList exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Api
import Api.Endpoint as Endpoint
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Loading
import Log
import Page
import PaginatedList exposing (PaginatedList)
import Route
import Session exposing (Session)
import Task exposing (Task)
import Time
import Url.Builder
import ID exposing (ID)
import User exposing (User)
import Username exposing (Username)
import Page.Misc as Misc


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
                    titleForMe (Session.cred model.session) id

                LoadingSlowly id ->
                    titleForMe (Session.cred model.session) id

                Failed id ->
                    titleForMe (Session.cred model.session) id
    in
        { title = title
        , content =
            case model.user of
                Loaded user ->
                    div [ class "profile-page" ]
                        [ Page.viewErrors ClickedDismissErrors model.errors
                        , text <| ID.toString user.id
                        ]

                Loading _ ->
                    text ""

                LoadingSlowly _ ->
                    Loading.icon

                Failed _ ->
                    Loading.error "profile"
        }



-- PAGE TITLE


titleForOther : Username -> String
titleForOther otherUsername =
    "Profile — " ++ Username.toString otherUsername


titleForMe : Maybe Cred -> Username -> String
titleForMe maybeCred username =
    case maybeCred of
        Just cred ->
            if username == Api.username cred then
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
    | CompletedUserLoad (Result ( Username, Http.Error ) User)
      --    | CompletedFeedLoad (Result ( Username, Http.Error ) Feed.Model)
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

        CompletedUserLoad (Err ( username, err )) ->
            ( { model | errors = [ Misc.httpErrorToUserError err ], user = Failed username }
            , Log.error
            )

        GotTimeZone tz ->
            ( { model | timeZone = tz }, Cmd.none )

        GotSession session ->
            ( { model | session = session }
            , Route.replaceUrl (Session.navKey session) Route.Home
            )

        PassedSlowLoadThreshold ->
            let
                -- If any data is still Loading, change it to LoadingSlowly
                -- so `view` knows to render a spinner.
                feed =
                    case model.feed of
                        Loading username ->
                            LoadingSlowly username

                        other ->
                            other
            in
                ( { model | feed = feed }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Session.changes GotSession (Session.navKey model.session)



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
