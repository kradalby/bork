module Page.Namespace exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Api
import Api.Endpoint as Endpoint
import Email
import File.Download as Download
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import ID exposing (ID)
import Loading
import Log
import Namespace exposing (Namespace)
import Page
import Page.Misc as Misc
import Page.View as View
import Route
import Session exposing (Session)
import Task exposing (Task)
import Time
import Url.Builder
import User exposing (User)
import Username



-- MODEL


type alias Model =
    { session : Session
    , timeZone : Time.Zone
    , errors : List String

    -- View related
    , addOwnerModal : Bool
    , deleteNamespaceModal : Bool
    , deleteNamespaceVerificationField : String
    , credentialView : Credentials
    , droneRepositoryField : String

    -- Loaded independently from server
    , namespace : Status Namespace
    , auth : Status Namespace.Auth
    , config : Status String
    , users : Status (List User)
    , deleteNamespace : Status String
    }


type Status a
    = Loading
    | LoadingSlowly
    | Loaded a
    | Failed


type Credentials
    = Configuration
    | GitLab
    | Drone


init : Session -> ID -> ( Model, Cmd Msg )
init session id =
    ( { session = session
      , timeZone = Time.utc
      , errors = []
      , addOwnerModal = False
      , deleteNamespaceModal = False
      , deleteNamespaceVerificationField = ""
      , credentialView = Configuration
      , droneRepositoryField = ""
      , namespace = Loading
      , auth = Loading
      , config = Loading
      , users = Loading
      , deleteNamespace = Loaded ""
      }
    , Cmd.batch
        [ Namespace.get id
            |> Http.toTask
            |> Task.mapError (Tuple.pair id)
            |> Task.attempt CompletedNamespaceLoad
        , Namespace.auth id
            |> Http.toTask
            |> Task.mapError (Tuple.pair id)
            |> Task.attempt CompletedAuthLoad
        , Namespace.config id
            |> Http.toTask
            |> Task.mapError (Tuple.pair id)
            |> Task.attempt CompletedConfigLoad
        , Task.perform GotTimeZone Time.here
        , Task.perform (\_ -> PassedSlowLoadThreshold) Loading.slowThreshold
        ]
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    let
        title =
            case model.namespace of
                Loaded namespace ->
                    defaultTitle (Namespace.name namespace)

                Failed ->
                    defaultTitle "Failed"

                _ ->
                    defaultTitle "Loading"
    in
    { title = title
    , content =
        div [ class "namespace-page" ]
            [ Page.viewErrors ClickedDismissErrors model.errors
            , case model.namespace of
                Loaded ns ->
                    let
                        user =
                            Namespace.owner ns

                        isOwner =
                            Misc.isOwner model.session (User.id user)
                    in
                    div []
                        [ div [ class "row" ]
                            [ h2 []
                                [ text <| Namespace.name ns
                                ]
                            ]
                        , View.iff model.addOwnerModal (addOwnerModal model.users ns)
                        , viewOwners model.session ns
                        , viewCredentials ns
                            model.credentialView
                            model.auth
                            model.config
                            model.droneRepositoryField
                        , View.iff model.deleteNamespaceModal
                            (deleteNamespaceModal model.deleteNamespaceVerificationField
                                ns
                                model.deleteNamespace
                            )

                        --, View.iff isOwner viewDangerZone
                        , viewDangerZone
                        ]

                Loading ->
                    text ""

                LoadingSlowly ->
                    Loading.icon

                Failed ->
                    Loading.error "namespace"
            ]
    }


viewOwners : Session -> Namespace -> Html Msg
viewOwners session ns =
    let
        user =
            Namespace.owner ns

        isOwner =
            Misc.isOwner session (User.id user)
    in
    div [ class "col-12 px-0" ]
        [ div [ class "row" ]
            [ h3 []
                [ text "Users"
                ]
            ]
        , div [ class "row" ]
            [ div [ class "col-6" ] [ text "Created " ]
            , div [ class "col-6" ]
                [ h5 []
                    [ text <| Namespace.created ns
                    ]
                ]
            ]
        , div [ class "row" ]
            [ userTable session ns ]
        , div [ class "row" ]
            [ div [ class "col-12 px-0" ]
                [ View.iff isOwner <|
                    button [ class "btn btn-success float-right", onClick ToggleAddOwnerModal ] [ text "Add" ]
                ]
            ]
        ]


viewDangerZone : Html Msg
viewDangerZone =
    div [ class "col-12 px-0 mt-5" ]
        [ div [ class "row" ]
            [ h3 []
                [ text "Danger Zone"
                ]
            ]
        , div [ class "row" ]
            [ div [ class "col-12 px-0 pb-3" ]
                [ button [ class "btn btn-large btn-danger", onClick ToggleDeleteNamespaceModal ] [ text "Delete Namespace" ]
                ]
            ]
        ]


userTable : Session -> Namespace -> Html Msg
userTable session ns =
    let
        user =
            Namespace.owner ns

        users =
            Namespace.coOwners ns

        primary =
            [ tr [ class "table-primary" ]
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
                , td [ colspan 2 ]
                    [ a
                        [ href <|
                            "mailto:"
                                ++ (Email.toString <| User.email user)
                        ]
                        [ text <| Email.toString <| User.email user ]
                    ]
                ]
            ]

        isOwner =
            Misc.isOwner session (User.id user)
    in
    table [ class "table table-striped" ]
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
        , tbody [] <| primary ++ List.map (userTableRowDelete isOwner ns) users
        ]


userTableRowDelete : Bool -> Namespace -> User -> Html Msg
userTableRowDelete isOwner ns user =
    let
        btn =
            View.iff isOwner <|
                button [ class "btn btn-danger btn-sm float-right", onClick (DeleteCoOwner ns user) ] [ text "Remove" ]
    in
    userTableRow btn user


userTableRowAdd : Bool -> Namespace -> User -> Html Msg
userTableRowAdd isOwner ns user =
    let
        btn =
            View.iff isOwner <|
                button [ class "btn btn-success", onClick (AddCoOwner ns user) ] [ text "+" ]
    in
    userTableRow btn user


userTableRow : Html Msg -> User -> Html Msg
userTableRow modifier user =
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
        , td [ class "pb-1 pt-2" ]
            [ modifier
            ]
        ]


addOwnerModal : Status (List User) -> Namespace -> Html Msg
addOwnerModal users ns =
    div [ style "display" "block", attribute "aria-hidden" "false", attribute "aria-labelledby" "helpModal", class "modal", id "helpModal", attribute "role" "dialog", attribute "tabindex" "-1" ]
        [ div [ class "modal-dialog modal-dialog-centered modal-lg", attribute "role" "document" ]
            [ div [ class "modal-content" ]
                [ div [ class "modal-header" ]
                    [ h5 [ class "modal-title", id "helpModalTitle" ]
                        [ text "Add Co Owner" ]
                    , button [ onClick ToggleAddOwnerModal, attribute "aria-label" "Close", class "close", attribute "data-dismiss" "modal", type_ "button" ]
                        [ span [ attribute "aria-hidden" "true" ]
                            [ text "×" ]
                        ]
                    ]
                , div [ class "modal-body" ]
                    [ case users of
                        Loaded u ->
                            table [ class "table table-striped" ]
                                [ thead []
                                    [ tr []
                                        [ th [ scope "col" ]
                                            [ text "Name" ]
                                        , th [ scope "col" ]
                                            [ text "Username" ]
                                        , th [ scope "col" ]
                                            [ text "Email" ]
                                        ]
                                    ]
                                , tbody [] <| List.map (userTableRowAdd True ns) u
                                ]

                        Loading ->
                            text ""

                        LoadingSlowly ->
                            Loading.icon

                        Failed ->
                            Loading.error "users"
                    ]
                , div [ class "modal-footer" ]
                    [ button [ onClick ToggleAddOwnerModal, class "btn btn-secondary", attribute "data-dismiss" "modal", type_ "button" ]
                        [ text "Close" ]
                    ]
                ]
            ]
        ]


deleteNamespaceModal : String -> Namespace -> Status String -> Html Msg
deleteNamespaceModal deleteNamespaceVerificationContent ns status =
    let
        disable =
            deleteNamespaceVerificationContent
                /= Namespace.name ns
    in
    div [ style "display" "block", attribute "aria-hidden" "false", attribute "aria-labelledby" "helpModal", class "modal", id "helpModal", attribute "role" "dialog", attribute "tabindex" "-1" ]
        [ div [ class "modal-dialog modal-dialog-centered modal-lg", attribute "role" "document" ]
            [ div [ class "modal-content" ]
                [ div [ class "modal-header" ]
                    [ h5 [ class "modal-title", id "helpModalTitle" ]
                        [ text <| "Delete: " ++ Namespace.name ns ]
                    , button [ onClick ToggleDeleteNamespaceModal, attribute "aria-label" "Close", class "close", attribute "data-dismiss" "modal", type_ "button" ]
                        [ span [ attribute "aria-hidden" "true" ]
                            [ text "×" ]
                        ]
                    ]
                , div [ class "modal-body" ]
                    [ p []
                        [ text "This action cannot be undone. This will permanently delete the "
                        , b [] [ text (Namespace.name ns) ]
                        , text " namespace, all resources, content and remove all collaborator associations."
                        ]
                    , p [] [ text "Please type in the name of the repository to confirm." ]
                    , div [ class "input-group input-group-lg" ]
                        [ input [ onInput OnChangeDeleteNamespaceVerificationField, attribute "aria-describedby" "inputGroup-sizing-sm", attribute "aria-label" "Large", class "form-control", type_ "text" ]
                            []
                        ]
                    ]
                , div [ class "modal-footer" ]
                    [ button [ onClick (DeleteNamespace ns), class "btn btn-danger btn-block", attribute "data-dismiss" "modal", type_ "button", disabled disable ]
                        [ text "Delete" ]
                    ]
                ]
            ]
        ]


viewCredentials : Namespace -> Credentials -> Status Namespace.Auth -> Status String -> String -> Html Msg
viewCredentials ns credentialView auth config repo =
    let
        tab name credential =
            let
                active =
                    if credentialView == credential then
                        "nav-link mb-0 active"

                    else
                        "nav-link mb-0"
            in
            li [ class "nav-item", onClick (SetCredentialView credential) ]
                [ p [ class active ]
                    [ text name ]
                ]
    in
    div [ class "col-12 px-0" ]
        [ div
            [ class "row" ]
            [ div [ class "col-12 px-0" ]
                [ ul [ class "nav nav-tabs" ]
                    [ tab "Configuration" Configuration
                    , tab "GitLab" GitLab
                    , tab "Drone" Drone
                    ]
                ]
            ]
        , div [ class "row" ]
            [ case credentialView of
                Configuration ->
                    viewConfig config

                GitLab ->
                    viewGitLab ns auth

                Drone ->
                    viewDrone auth repo
            ]
        ]


viewConfig : Status String -> Html Msg
viewConfig config =
    case config of
        Loaded content ->
            div [ class "col-12" ]
                [ div [ class "row" ]
                    [ textarea
                        [ class "form-control"
                        , attribute "rows" "15"
                        , value content
                        , readonly True
                        ]
                        []
                    ]
                , div [ class "row" ]
                    [ div [ class "col-12 px-0" ]
                        [ button
                            [ class "btn btn-primary mt-3 float-right"
                            , onClick <| SaveConfig content
                            ]
                            [ text "Download" ]
                        ]
                    ]
                ]

        Loading ->
            text ""

        LoadingSlowly ->
            Loading.icon

        Failed ->
            Loading.error "config"


viewGitLab : Namespace -> Status Namespace.Auth -> Html Msg
viewGitLab ns auth =
    case auth of
        Loaded content ->
            div [ class "col-12" ]
                [ div [ class "row mt-3" ]
                    [ p [] [ text "To add the credentials for your namespace to GitLab, do the following:" ]
                    , p []
                        [ text "In your repository, go to "
                        , b [] [ text "Operations" ]
                        , text " > "
                        , b [] [ text "Kubernetes" ]
                        , text " > "
                        , b [] [ text "Add Kubernetes cluster" ]
                        , text " > "
                        , b [] [ text "Add existing cluster" ]
                        , text " and fill in the information below."
                        ]
                    ]
                , div [ class "row mt-1" ]
                    [ h5
                        []
                        [ text "API URL" ]
                    ]
                , div [ class "row" ]
                    [ div [ class "input-group" ]
                        [ input [ readonly True, class "form-control", value content.endpoint ] []
                        ]
                    ]
                , div [ class "row mt-3" ]
                    [ h5
                        []
                        [ text "CA Certificate" ]
                    ]
                , div [ class "row" ]
                    [ textarea
                        [ class "form-control"
                        , attribute "rows" "15"
                        , value content.certificate
                        , readonly True
                        ]
                        []
                    ]
                , div [ class "row mt-3" ]
                    [ h5
                        []
                        [ text "Token" ]
                    ]
                , div [ class "row" ]
                    [ textarea
                        [ class "form-control"
                        , attribute "rows" "9"
                        , value content.token
                        , readonly True
                        ]
                        []
                    ]
                , div [ class "row mt-3" ]
                    [ h5
                        []
                        [ text "Project namespace (optional, unique)" ]
                    ]
                , div [ class "row" ]
                    [ div [ class "input-group" ]
                        [ input [ readonly True, class "form-control", value (Namespace.name ns) ] []
                        ]
                    ]
                ]

        Loading ->
            text ""

        LoadingSlowly ->
            Loading.icon

        Failed ->
            Loading.error "auth"


viewDrone : Status Namespace.Auth -> String -> Html Msg
viewDrone auth repo =
    case auth of
        Loaded content ->
            let
                endpoint =
                    String.join " "
                        [ "drone secret add"
                        , repo
                        , "--image=quay.io/honestbee/drone-kubernetes"
                        , "--name=kubernetes_server"
                        , "--value="
                            ++ content.endpoint
                        , "\n"
                        ]

                cert =
                    String.join " "
                        [ "drone secret add"
                        , repo
                        , "--image=quay.io/honestbee/drone-kubernetes"
                        , "--name=kubernetes_cert"
                        , "--value="
                            ++ content.certificateB64
                        , "\n"
                        ]

                token =
                    String.join " "
                        [ "drone secret add"
                        , repo
                        , "--image=quay.io/honestbee/drone-kubernetes"
                        , "--name=kubernetes_token"
                        , "--value="
                            ++ content.token
                        , "\n"
                        ]

                commands =
                    if repo == "" then
                        "Please enter a repository"

                    else
                        String.join "\n"
                            [ endpoint, cert, token ]
            in
            div [ class "col-12" ]
                [ div [ class "row mt-3" ]
                    [ p [] [ text "To add the credential to a Drone build server, enter the repository registered in Drone and execute the commands below." ]
                    , p []
                        [ text "Credentials can be added via the web interface by using the value after "
                        , span [ class "text-monospace" ] [ text "--name=" ]
                        , text " and "
                        , span [ class "text-monospace" ] [ text "--value=" ]
                        , text " in the form for adding secrets."
                        ]
                    ]
                , div [ class "row mt-1" ] [ h5 [] [ text "Drone repository" ] ]
                , div [ class "row" ]
                    [ div [ class "input-group" ] [ input [ class "form-control", value repo, onInput OnChangeDroneRepositoryField ] [] ]
                    ]
                , div [ class "row mt-3" ] [ h5 [] [ text "Commands" ] ]
                , div [ class "row" ]
                    [ textarea
                        [ class "form-control"
                        , attribute "rows" "25"
                        , value commands
                        , readonly True
                        ]
                        []
                    ]
                ]

        Loading ->
            text ""

        LoadingSlowly ->
            Loading.icon

        Failed ->
            Loading.error "auth"



-- PAGE TITLE


defaultTitle : String -> String
defaultTitle identifier =
    "Namespace - " ++ identifier



-- UPDATE


type Msg
    = ClickedDismissErrors
    | CompletedNamespaceLoad (Result ( ID, Http.Error ) Namespace)
    | CompletedAuthLoad (Result ( ID, Http.Error ) Namespace.Auth)
    | CompletedConfigLoad (Result ( ID, Http.Error ) String)
    | GotTimeZone Time.Zone
    | GotSession Session
    | PassedSlowLoadThreshold
    | SaveConfig String
    | AddCoOwner Namespace User
    | CompletedAddCoOwner (Result ( ID, Http.Error ) Namespace)
    | DeleteCoOwner Namespace User
    | CompletedDeleteCoOwner (Result ( ID, Http.Error ) Namespace)
    | ToggleAddOwnerModal
    | ToggleDeleteNamespaceModal
    | CompletedUsersLoad (Result Http.Error (List User))
    | OnChangeDeleteNamespaceVerificationField String
    | DeleteNamespace Namespace
    | CompletedDeleteNamespace (Result Http.Error Namespace)
    | SetCredentialView Credentials
    | OnChangeDroneRepositoryField String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedDismissErrors ->
            ( { model | errors = [] }, Cmd.none )

        CompletedNamespaceLoad (Ok namespace) ->
            ( { model | namespace = Loaded namespace }, Cmd.none )

        CompletedNamespaceLoad (Err ( id, err )) ->
            ( { model | errors = [ Misc.httpErrorToUserError err ], namespace = Failed }
            , Log.error
            )

        CompletedAuthLoad (Ok auth) ->
            ( { model | auth = Loaded auth }, Cmd.none )

        CompletedAuthLoad (Err ( id, err )) ->
            ( { model | errors = [ Misc.httpErrorToUserError err ], auth = Failed }
            , Log.error
            )

        CompletedConfigLoad (Ok config) ->
            ( { model | config = Loaded config }, Cmd.none )

        CompletedConfigLoad (Err ( id, err )) ->
            ( { model | errors = [ Misc.httpErrorToUserError err ], config = Failed }
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

        SaveConfig content ->
            ( model
            , Cmd.batch
                [ Download.string "config" "text/yaml" content
                ]
            )

        AddCoOwner ns user ->
            let
                id =
                    Namespace.id ns
            in
            ( model
            , Cmd.batch
                [ Namespace.addCoOwner id user
                    |> Http.toTask
                    |> Task.mapError (Tuple.pair id)
                    |> Task.attempt CompletedAddCoOwner
                ]
            )

        CompletedAddCoOwner (Ok ns) ->
            ( { model | namespace = Loaded ns }
            , Cmd.batch
                [ Namespace.availableUsers (Namespace.id ns)
                    |> Http.toTask
                    |> Task.attempt CompletedUsersLoad
                ]
            )

        CompletedAddCoOwner (Err ( id, err )) ->
            ( { model | errors = [ Misc.httpErrorToUserError err ], namespace = Failed }
            , Log.error
            )

        DeleteCoOwner ns user ->
            let
                id =
                    Namespace.id ns
            in
            ( model
            , Cmd.batch
                [ Namespace.deleteCoOwner id user
                    |> Http.toTask
                    |> Task.mapError (Tuple.pair id)
                    |> Task.attempt CompletedDeleteCoOwner
                ]
            )

        CompletedDeleteCoOwner (Ok ns) ->
            ( { model | namespace = Loaded ns }, Cmd.none )

        CompletedDeleteCoOwner (Err ( id, err )) ->
            ( { model | errors = [ Misc.httpErrorToUserError err ], namespace = Failed }
            , Log.error
            )

        ToggleAddOwnerModal ->
            ( { model | addOwnerModal = not model.addOwnerModal }
            , Cmd.batch
                [ case model.namespace of
                    Loaded ns ->
                        Namespace.availableUsers (Namespace.id ns)
                            |> Http.toTask
                            |> Task.attempt CompletedUsersLoad

                    _ ->
                        Cmd.none
                ]
            )

        ToggleDeleteNamespaceModal ->
            ( { model | deleteNamespaceModal = not model.deleteNamespaceModal }
            , Cmd.none
            )

        CompletedUsersLoad (Ok users) ->
            ( { model | users = Loaded users }, Cmd.none )

        CompletedUsersLoad (Err err) ->
            ( { model | errors = [ Misc.httpErrorToUserError err ], users = Failed }
            , Log.error
            )

        OnChangeDeleteNamespaceVerificationField content ->
            ( { model | deleteNamespaceVerificationField = content }, Cmd.none )

        DeleteNamespace ns ->
            ( { model | deleteNamespace = LoadingSlowly }
            , Namespace.delete (Namespace.id ns)
                |> Http.toTask
                |> Task.attempt CompletedDeleteNamespace
            )

        CompletedDeleteNamespace (Ok ns) ->
            ( model, Route.replaceUrl (Session.navKey model.session) Route.NamespaceList )

        CompletedDeleteNamespace (Err err) ->
            ( { model | errors = [ Misc.httpErrorToUserError err ], deleteNamespace = Failed }
            , Log.error
            )

        SetCredentialView credView ->
            ( { model | credentialView = credView }, Cmd.none )

        OnChangeDroneRepositoryField content ->
            ( { model | droneRepositoryField = content }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    -- Session.changes GotSession (Session.navKey model.session)
    Sub.none



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
