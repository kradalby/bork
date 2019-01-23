module Page.Home exposing (Model, Msg, init, subscriptions, toSession, update, view)

{-| The homepage. You can get here via either the / or /#/ routes.
-}

import Api
import Api.Endpoint as Endpoint
import Browser.Dom as Dom
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, href, id, placeholder)
import Html.Events exposing (onClick)
import Http
import Loading
import Log
import Page
import Session exposing (Session)
import Task exposing (Task)
import Time
import Url.Builder
import Username exposing (Username)


-- MODEL


type alias Model =
    { session : Session
    , timeZone : Time.Zone
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
      }
    , Cmd.batch
        [ Task.perform GotTimeZone Time.here
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "bork"
    , content =
        div [ class "home-page" ]
            [ div [ class "row" ] [ h2 [] [ text "Welcome to bork!" ] ]
            , div [ class "row" ]
                [ p [] [ text "Create namespaces on demand on a shared cluster for your kubernetes needs!" ]
                , p [] [ text "bork allowes you to manage your own namespaces on a shared namespace and add colaborators too your namespace." ]
                , p [] [ b [] [ text "bork is currently in early development (beta) and you might running into problems and errors. " ] ]
                ]
            ]
    }



-- UPDATE


type Msg
    = GotTimeZone Time.Zone
    | GotSession Session
    | PassedSlowLoadThreshold


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTimeZone tz ->
            ( { model | timeZone = tz }, Cmd.none )

        GotSession session ->
            ( { model | session = session }, Cmd.none )

        PassedSlowLoadThreshold ->
            -- let
            --     -- If any data is still Loading, change it to LoadingSlowly
            --     -- so `view` knows to render a spinner.
            --     feed =
            --         case model.feed of
            --             Loading ->
            --                 LoadingSlowly
            --             other ->
            --                 other
            --     tags =
            --         case model.tags of
            --             Loading ->
            --                 LoadingSlowly
            --             other ->
            --                 other
            -- in
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
