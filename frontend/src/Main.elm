module Main exposing (main)

import Api
import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (..)
import Json.Decode as Decode exposing (Value)
import Page exposing (Page)
import Page.Blank as Blank
import Page.NotFound as NotFound
import Page.Home as Home
import Page.User as User
import User as U
import Http


-- import Page.UserList as UserList

import Page.Namespace as Namespace
import Page.Namespace.List as NamespaceList
import Page.Namespace.New as NamespaceNew


-- import Page.Settings as Settings

import Route exposing (Route)
import Session exposing (Session)
import Task
import Time
import Url exposing (Url)
import ID exposing (ID)


-- NOTE: Based on discussions around how asset management features
-- like code splitting and lazy loading have been shaping up, it's possible
-- that most of this file may become unnecessary in a future release of Elm.
-- Avoid putting things in this module unless there is no alternative!
-- See https://discourse.elm-lang.org/t/elm-spa-in-0-19/1800/2 for more.


type Model
    = Redirect Session
    | NotFound Session
    | Home Home.Model
      -- | Settings Settings.Model
    | User ID User.Model
      -- | UserList UserList.Model
    | Namespace ID Namespace.Model
    | NamespaceList NamespaceList.Model
    | NamespaceNew NamespaceNew.Model



-- MODEL


init : Url -> Nav.Key -> ( Model, Cmd Msg )
init url navKey =
    let
        ( model, cmds ) =
            changeRouteTo (Route.fromUrl url)
                -- Nothing represents that we have not checked the api for a user yet
                (Redirect (Session.fromUser navKey Nothing))

        session =
            U.session
                |> Http.toTask
                |> Task.attempt (GetSession navKey)
    in
        ( model, Cmd.batch [ session, cmds ] )



-- VIEW


view : Model -> Document Msg
view model =
    let
        viewPage page toMsg config =
            let
                { title, body } =
                    Page.view (Session.user (toSession model)) page config
            in
                { title = title
                , body = List.map (Html.map toMsg) body
                }
    in
        case model of
            Redirect _ ->
                viewPage Page.Other (\_ -> Ignored) Blank.view

            NotFound _ ->
                viewPage Page.Other (\_ -> Ignored) NotFound.view

            --       Settings settings ->
            --           viewPage Page.Other GotSettingsMsg (Settings.view settings)
            Home home ->
                viewPage Page.Home GotHomeMsg (Home.view home)

            User id user ->
                viewPage (Page.User id) GotUserMsg (User.view user)

            --            UserList id userList ->
            --                viewPage (Page.UserList) GotUserListMsg (UserList.view userList)
            Namespace id namespace ->
                viewPage (Page.Namespace id) GotNamespaceMsg (Namespace.view namespace)

            NamespaceList namespaceList ->
                viewPage (Page.NamespaceList) GotNamespaceListMsg (NamespaceList.view namespaceList)

            NamespaceNew namespaceNew ->
                viewPage (Page.NamespaceNew) GotNamespaceNewMsg (NamespaceNew.view namespaceNew)



-- UPDATE


type Msg
    = Ignored
    | ChangedRoute (Maybe Route)
    | ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotHomeMsg Home.Msg
      --| GotSettingsMsg Settings.Msg
    | GotUserMsg User.Msg
      -- | GotUserListMsg UserList.Msg
    | GotNamespaceMsg Namespace.Msg
    | GotNamespaceListMsg NamespaceList.Msg
    | GotNamespaceNewMsg NamespaceNew.Msg
    | GotSession Session
    | GetSession Nav.Key (Result Http.Error U.User)


toSession : Model -> Session
toSession page =
    case page of
        Redirect session ->
            session

        NotFound session ->
            session

        Home home ->
            Home.toSession home

        --  Settings settings ->
        --      Settings.toSession settings
        User _ user ->
            User.toSession user

        --         UserList _ user ->
        --             UserList.toSession user
        Namespace _ namespace ->
            Namespace.toSession namespace

        NamespaceList namespace ->
            NamespaceList.toSession namespace

        NamespaceNew namespace ->
            NamespaceNew.toSession namespace


changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    let
        session =
            toSession model
    in
        case maybeRoute of
            Nothing ->
                ( NotFound session, Cmd.none )

            Just Route.Root ->
                ( model, Route.replaceUrl (Session.navKey session) Route.Home )

            --            Just Route.Settings ->
            --                Settings.init session
            --                    |> updateWith Settings GotSettingsMsg model
            Just Route.Home ->
                Home.init session
                    |> updateWith Home GotHomeMsg model

            Just (Route.User id) ->
                User.init session id
                    |> updateWith (User id) GotUserMsg model

            --            Just Route.UserList ->
            --                UserList.init session id
            --                    |> updateWith UserList GotUserListMsg model
            Just (Route.Namespace id) ->
                Namespace.init session id
                    |> updateWith (Namespace id) GotNamespaceMsg model

            Just Route.NamespaceList ->
                NamespaceList.init session
                    |> updateWith NamespaceList GotNamespaceListMsg model

            Just Route.NamespaceNew ->
                NamespaceNew.init session
                    |> updateWith NamespaceNew GotNamespaceNewMsg model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( Ignored, _ ) ->
            ( model, Cmd.none )

        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    case url.fragment of
                        Nothing ->
                            -- If we got a link that didn't include a fragment,
                            -- it's from one of those (href "") attributes that
                            -- we have to include to make the RealWorld CSS work.
                            --
                            -- In an application doing path routing instead of
                            -- fragment-based routing, this entire
                            -- `case url.fragment of` expression this comment
                            -- i    s inside would be unnecessary.
                            --        ( model, Cmd.none )
                            -- TODO
                            -- For now, allow auth to get moved out of spa
                            case url.path of
                                "/auth/openid-connect" ->
                                    ( model
                                    , Nav.load url.path
                                    )

                                _ ->
                                    ( model, Cmd.none )

                        Just _ ->
                            ( model
                            , Nav.pushUrl (Session.navKey (toSession model)) (Url.toString url)
                            )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        ( ChangedUrl url, _ ) ->
            changeRouteTo (Route.fromUrl url) model

        ( ChangedRoute route, _ ) ->
            changeRouteTo route model

        --        ( GotSettingsMsg subMsg, Settings settings ) ->
        --           Settings.update subMsg settings
        --               |> updateWith Settings GotSettingsMsg model
        ( GotHomeMsg subMsg, Home home ) ->
            Home.update subMsg home
                |> updateWith Home GotHomeMsg model

        ( GotUserMsg subMsg, User id user ) ->
            User.update subMsg user
                |> updateWith (User id) GotUserMsg model

        --        ( GotUserListMsg subMsg, UserList user ) ->
        --            UserList.update subMsg user
        --                |> updateWith UserList GotUserListMsg model
        ( GotNamespaceMsg subMsg, Namespace id namespace ) ->
            Namespace.update subMsg namespace
                |> updateWith (Namespace id) GotNamespaceMsg model

        ( GotNamespaceListMsg subMsg, NamespaceList namespace ) ->
            NamespaceList.update subMsg namespace
                |> updateWith NamespaceList GotNamespaceListMsg model

        ( GotNamespaceNewMsg subMsg, NamespaceNew namespace ) ->
            NamespaceNew.update subMsg namespace
                |> updateWith NamespaceNew GotNamespaceNewMsg model

        ( GotSession session, _ ) ->
            ( Redirect session
            , Route.replaceUrl (Session.navKey session) Route.Home
            )

        ( GetSession navKey (Ok user), _ ) ->
            let
                session =
                    Session.fromUser navKey (Just user)
            in
                ( Redirect session
                , Route.replaceUrl (Session.navKey session) Route.Home
                )

        ( GetSession navKey (Err error), Redirect _ ) ->
            ( model, Cmd.none )

        ( a, b ) ->
            -- let
            --     _ =
            --         Debug.log "msg" a
            --     _ =
            --         Debug.log "model " b
            -- in
            -- Disregard messages that arrived for the wrong page.
            ( model, Cmd.none )


updateWith : (subModel -> Model) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg model ( subModel, subCmd ) =
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        NotFound _ ->
            Sub.none

        Redirect _ ->
            Session.changes GotSession (Session.navKey (toSession model))

        --        Settings settings ->
        --            Sub.map GotSettingsMsg (Settings.subscriptions settings)
        Home home ->
            Sub.map GotHomeMsg (Home.subscriptions home)

        User _ subMsg ->
            Sub.map GotUserMsg (User.subscriptions subMsg)

        --        UserList _ subMsg ->
        --            Sub.map GotUserListMsg (UserList.subscriptions subMsg)
        Namespace _ subMsg ->
            Sub.map GotNamespaceMsg (Namespace.subscriptions subMsg)

        NamespaceList subMsg ->
            Sub.map GotNamespaceListMsg (NamespaceList.subscriptions subMsg)

        NamespaceNew subMsg ->
            Sub.map GotNamespaceNewMsg (NamespaceNew.subscriptions subMsg)



-- MAIN


main : Program Value Model Msg
main =
    Api.application
        { init = init
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
