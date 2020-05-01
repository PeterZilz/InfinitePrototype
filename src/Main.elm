module Main exposing (Model, Msg, init, main, subscriptions, update, view)

import Browser
import Browser.Events as BE
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (preventDefaultOn)
import Json.Decode as Decode exposing (succeed)
import Math.Matrix4 exposing (Mat4)
import Playfield exposing (..)
import WebGL


main : Program WindowSize Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias WindowSize =
    { width : Int
    , height : Int
    }


type alias Model =
    { width : Int
    , height : Int
    , modelViewProjectionMatrix : Mat4
    }


modelInitialValue size =
    { width = size.width
    , height = size.height
    , modelViewProjectionMatrix = getModelViewProjectionMatrix (toFloat size.width / toFloat size.height)
    }


init : WindowSize -> ( Model, Cmd Msg )
init size =
    ( modelInitialValue size, Cmd.none )


type Msg
    = DoNothing
    | Resized Int Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DoNothing ->
            ( model, Cmd.none )

        Resized w h ->
            ( { model
                | width = w
                , height = h
                , modelViewProjectionMatrix = getModelViewProjectionMatrix (toFloat w / toFloat h)
              }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    BE.onResize Resized


preventContextMenu : msg -> Attribute msg
preventContextMenu msg =
    preventDefaultOn "contextmenu" (Decode.map alwaysPreventDefault (succeed msg))


alwaysPreventDefault : msg -> ( msg, Bool )
alwaysPreventDefault msg =
    ( msg, True )


view : Model -> Html Msg
view model =
    div []
        [ viewPlayfield model
        , span [ id "score", class "noselect" ] [ text "0" ]
        , input
            [ type_ "button"
            , class "gameButton"
            , id "btnGhost"
            , value "Geistern"
            , disabled True
            ]
            []
        , div [ class "disabler" ] []
        , div [ class "splashScreen", id "victoryScreen", style "display" "none" ]
            [ div [ class "splashTitle" ] [ text "Gewonnen" ]
            , div [ class "splashMessage" ] [ text "Du hast alle Quadrate gesammelt." ]
            , input
                [ type_ "button"
                , class "splashButton"
                , value "Neues Spiel"
                , id "btnNewGame"
                ]
                []
            ]
        ]


viewPlayfield : Model -> Html Msg
viewPlayfield model =
    WebGL.toHtml
        [ id "playfield"
        , preventContextMenu DoNothing
        , width model.width
        , height model.height
        ]
        [ background model.modelViewProjectionMatrix ]
