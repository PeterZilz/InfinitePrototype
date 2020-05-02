module Main exposing (Model, Msg, init, main, subscriptions, update, view)

import Browser
import Browser.Events as BE
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, preventDefaultOn)
import Json.Decode as Decode exposing (Decoder, succeed)
import Length exposing (Meters)
import Math.Matrix4 exposing (Mat4)
import Pixels exposing (Pixels)
import Playfield exposing (..)
import Point2d exposing (Point2d)
import Rectangle2d exposing (Rectangle2d)
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
    , screen : Rectangle2d Pixels ScreenPixels
    , modelViewProjectionMatrix : Mat4
    , currentPosition : Point2d Meters World
    , translationMatrix : Mat4
    }


modelInitialValue size startPoint =
    { width = size.width
    , height = size.height
    , screen = getScreen size.width size.height
    , modelViewProjectionMatrix = getModelViewProjectionMatrix (toFloat size.width / toFloat size.height) startPoint
    , currentPosition = startPoint
    , translationMatrix = getTranslationMatrix startPoint
    }


init : WindowSize -> ( Model, Cmd Msg )
init size =
    ( modelInitialValue size Point2d.origin, Cmd.none )


type Msg
    = DoNothing
    | Resized Int Int
    | TargetSelected Int Int


updateAspectRatio : Int -> Int -> Model -> Model
updateAspectRatio w h model =
    { model
        | width = w
        , height = h
        , screen = getScreen w h
        , modelViewProjectionMatrix = getModelViewProjectionMatrix (toFloat w / toFloat h) model.currentPosition
    }


pixelToWorld : Model -> Int -> Int -> Point2d Meters World
pixelToWorld model x y =
    -- not sure, why the inversion of the y-coordinate is necessary
    toWorld model.screen model.currentPosition x (model.height - y)


updateCurrentPosition : Int -> Int -> Model -> Model
updateCurrentPosition x y model =
    let
        newPosition =
            pixelToWorld model x y
    in
    { model
        | currentPosition = newPosition
        , modelViewProjectionMatrix = getModelViewProjectionMatrix (toFloat model.width / toFloat model.height) newPosition
        , translationMatrix = getTranslationMatrix newPosition
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DoNothing ->
            ( model, Cmd.none )

        Resized w h ->
            ( updateAspectRatio w h model
            , Cmd.none
            )

        TargetSelected x y ->
            ( updateCurrentPosition x y model, Cmd.none )


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
        , onPlayfieldMouseUp
        ]
        [ avatar model.modelViewProjectionMatrix model.translationMatrix
        , background model.modelViewProjectionMatrix model.translationMatrix
        ]


offsetDecoder : (Int -> Int -> msg) -> Decoder msg
offsetDecoder event =
    Decode.map2 event
        (Decode.field "offsetX" Decode.int)
        (Decode.field "offsetY" Decode.int)


onPlayfieldMouseUp : Attribute Msg
onPlayfieldMouseUp =
    on "mouseup" (offsetDecoder TargetSelected)
