module Alert exposing (Alert, AlertColor(..), alertToBootstrapCSS, view, error)

import Html exposing (..)
import Html.Attributes exposing (attribute, checked, class, disabled, for, href, id, name, pattern, property, selected, src, style, type_, value)
import Html.Events exposing (..)
import Json.Encode


type AlertColor
    = Primary
    | Secondary
    | Success
    | Danger
    | Warning
    | Info
    | Light
    | Dark


type alias Alert msg =
    { message : List String
    , color : AlertColor
    , onClick : Maybe msg
    , dismissable : Bool
    }


error : msg -> List String -> Alert msg
error click errors =
    { message = errors
    , color = Danger
    , onClick = Just click
    , dismissable = True
    }


alertToBootstrapCSS : AlertColor -> String
alertToBootstrapCSS alert =
    case alert of
        Primary ->
            "alert alert-primary"

        Secondary ->
            "alert alert-secondary"

        Success ->
            "alert alert-success"

        Danger ->
            "alert alert-danger"

        Warning ->
            "alert alert-warning"

        Info ->
            "alert alert-info"

        Light ->
            "alert alert-light"

        Dark ->
            "alert alert-dark"


view : Alert msg -> Html msg
view alert =
    let
        cssClasses =
            "ml-auto"
                ++ " "
                ++ alertToBootstrapCSS alert.color
                ++ " "
                ++ (case alert.dismissable of
                        True ->
                            "alert-dismissible fade show"

                        False ->
                            ""
                   )

        attr =
            case alert.onClick of
                Nothing ->
                    [ class cssClasses ]

                Just click ->
                    [ class cssClasses, onClick click ]

        dismiss =
            case alert.dismissable of
                True ->
                    button
                        [ type_ "button", class "close" ]
                        [ span
                            [ property
                                "innerHTML"
                                (Json.Encode.string "&times;")
                            ]
                            []
                        ]

                False ->
                    text ""
    in
        div
            attr
        <|
            List.map text alert.message
                ++ [ dismiss ]
