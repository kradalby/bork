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
import Namespace exposing (Namespace)
import Page.View as View


-- MODEL


type alias Model =
    { session : Session
    , timeZone : Time.Zone
    , errors : List String

    -- Loaded independently from server
    , user : Status User
    , namespaces : Status (List Namespace)
    , namespacesCoOwner : Status (List Namespace)
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
      , user = Loading
      , namespaces = Loading
      , namespacesCoOwner = Loading
      }
    , Cmd.batch
        [ User.fetch id
            |> Http.toTask
            |> Task.mapError (Tuple.pair id)
            |> Task.attempt CompletedUserLoad
        , Namespace.list
            |> Http.toTask
            |> Task.attempt CompletedNamespacesLoad
        , Namespace.listCoOwner
            |> Http.toTask
            |> Task.attempt CompletedNamespacesCoOwnerLoad
        , Task.perform GotTimeZone Time.here
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    let
        title =
            case model.user of
                Loading ->
                    defaultTitle

                LoadingSlowly ->
                    defaultTitle

                Failed ->
                    defaultTitle

                Loaded user ->
                    titleForMe (Session.user model.session) (User.id user)
    in
        { title = title
        , content =
            div [ class "user-page" ]
                [ Page.viewErrors ClickedDismissErrors model.errors
                , case model.user of
                    Loaded user ->
                        viewUser model.session user

                    Loading ->
                        -- text ""
                        Loading.icon

                    LoadingSlowly ->
                        Loading.icon

                    Failed ->
                        Loading.error "user"
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


viewUser : Session -> User -> Html Msg
viewUser session user =
    div [ class "" ]
        [ div [ class "row" ]
            [ h2 []
                [ text <|
                    titleForMe (Session.user session) (User.id user)
                ]
            ]
        , div [ class "row" ]
            [ div [ class "col-4" ] [ text "Name" ]
            , div [ class "col-8" ]
                [ h5 []
                    [ text <| User.name user
                    ]
                ]
            ]
        , div [ class "row" ]
            [ div [ class "col-4" ] [ text "Username" ]
            , div [ class "col-8" ]
                [ h5 []
                    [ text <| Username.toString <| User.username user
                    ]
                ]
            ]
        , div [ class "row" ]
            [ div [ class "col-4" ] [ text "Email" ]
            , div [ class "col-8" ]
                [ h5 []
                    [ text <| Email.toString <| User.email user
                    ]
                ]
            ]
        ]


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
    | CompletedNamespacesLoad (Result Http.Error (List Namespace))
    | CompletedNamespacesCoOwnerLoad (Result Http.Error (List Namespace))
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
            ( { model | user = Failed }
            , Log.error
            )

        CompletedNamespacesLoad (Ok namespaces) ->
            ( { model | namespaces = Loaded namespaces }, Cmd.none )

        CompletedNamespacesLoad (Err err) ->
            ( { model | namespaces = Failed }
            , Log.error
            )

        CompletedNamespacesCoOwnerLoad (Ok namespaces) ->
            ( { model | namespacesCoOwner = Loaded namespaces }, Cmd.none )

        CompletedNamespacesCoOwnerLoad (Err err) ->
            ( { model | namespacesCoOwner = Failed }
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
