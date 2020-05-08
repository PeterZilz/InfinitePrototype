module Main exposing (Model, Msg, init, main, subscriptions, update, view)

import Browser
import Browser.Events as BE
import Duration
import Game exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, preventDefaultOn)
import Json.Decode as Decode exposing (Decoder, succeed)
import Labyrinth exposing (..)
import Length exposing (Meters)
import Math.Matrix4 exposing (Mat4)
import Pixels exposing (Pixels)
import Plate exposing (..)
import Playfield exposing (..)
import Point2d exposing (Point2d)
import Process
import Random
import Rectangle2d exposing (Rectangle2d)
import Task
import WebGL
import WebGLRendering exposing (ScreenPixels, World)


main : Program WindowSizeFlags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias WindowSizeFlags =
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
    , target : Maybe (Point2d Meters World)
    , maze : Maze
    , plates : List Plate
    , score : Int
    , totalScore : Int
    , isScoreAnimating : Bool
    , ghosting : GhostingStatus
    }


modelInitialValue size startPoint =
    { width = size.width
    , height = size.height
    , screen = getScreen size.width size.height
    , modelViewProjectionMatrix = getModelViewProjectionMatrix (toFloat size.width / toFloat size.height) startPoint
    , currentPosition = startPoint
    , translationMatrix = getTranslationMatrix startPoint
    , target = Nothing
    , maze = Maze gridWidth gridHeight Nothing
    , plates = []
    , score = 0
    , totalScore = 0
    , isScoreAnimating = False
    , ghosting = Available
    }


initGame : Model -> ( Model, Cmd Msg )
initGame model =
    ( { model
        | score = 0
        , totalScore = 0
        , modelViewProjectionMatrix = getModelViewProjectionMatrix (toFloat model.width / toFloat model.height) getStartingPoint
        , currentPosition = getStartingPoint
        , translationMatrix = getTranslationMatrix getStartingPoint
        , target = Nothing
        , ghosting = OnCooldown
      }
    , Cmd.batch
        [ Random.generate MazeGenerated (doorwayGenerator gridWidth gridHeight)
        , Random.generate PlatesPlaced (plateGenerator gridWidth gridHeight totalPlates)
        , setTimeout ghostCooldown GhostingCoolDownEnded
        ]
    )


init : WindowSizeFlags -> ( Model, Cmd Msg )
init size =
    modelInitialValue size getStartingPoint
        |> initGame


type Msg
    = DoNothing
    | Resized Int Int
    | TargetSelected Int Int
    | NewPosition (Point2d Meters World)
    | MazeGenerated (List ( Bool, Bool ))
    | PlatesPlaced (List Plate)
    | ScoreAnimationEnded ()
    | NewGame
    | StartGhosting
    | EndGhosting ()
    | GhostingCoolDownEnded ()


updateAspectRatio : Int -> Int -> Model -> Model
updateAspectRatio w h model =
    { model
        | width = w
        , height = h
        , screen = getScreen w h
        , modelViewProjectionMatrix = getModelViewProjectionMatrix (toFloat w / toFloat h) model.currentPosition
    }


updateCurrentPosition : Point2d Meters World -> Model -> Model
updateCurrentPosition newPosition model =
    { model
        | currentPosition = newPosition
        , modelViewProjectionMatrix = getModelViewProjectionMatrix (toFloat model.width / toFloat model.height) newPosition
        , translationMatrix = getTranslationMatrix newPosition
        , target = updateTarget model.target newPosition
    }


setTimeout : Float -> (() -> msg) -> Cmd msg
setTimeout pause m =
    Process.sleep pause
        |> Task.perform m


processPlateAreas : Point2d Meters World -> Model -> Model
processPlateAreas newPosition model =
    case getEnteredTriggerAreas newPosition model.plates of
        [] ->
            model

        triggered ->
            { model
                | score = model.score + List.length triggered
                , plates = List.filter (\p -> not (List.member p triggered)) model.plates
                , isScoreAnimating = True
            }


handleEndOfScoreAnimation : Bool -> Model -> Cmd Msg
handleEndOfScoreAnimation wasAnimating m =
    if not wasAnimating && m.isScoreAnimating then
        setTimeout scoreAnimationDuration ScoreAnimationEnded

    else
        Cmd.none


moveToNewPosition : Point2d Meters World -> Model -> ( Model, Cmd Msg )
moveToNewPosition newPosition model =
    if model.ghosting /= Ongoing && wouldCrossAnyWall model.maze model.currentPosition newPosition then
        ( { model | target = Nothing }, Cmd.none )

    else
        updateCurrentPosition newPosition model
            |> processPlateAreas newPosition
            |> (\m -> ( m, handleEndOfScoreAnimation model.isScoreAnimating m ))


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
            -- not sure, why the inversion of the y-coordinate is necessary
            ( { model | target = Just (toWorld model.screen model.currentPosition x (model.height - y)) }, Cmd.none )

        NewPosition pos ->
            moveToNewPosition pos model

        MazeGenerated bools ->
            ( { model | maze = generateMaze model.maze.width model.maze.height bools }
            , Cmd.none
            )

        PlatesPlaced plates ->
            ( { model | plates = plates, totalScore = List.length plates }
            , Cmd.none
            )

        ScoreAnimationEnded _ ->
            ( { model | isScoreAnimating = False }, Cmd.none )

        NewGame ->
            initGame model

        StartGhosting ->
            ( { model | ghosting = Ongoing }, setTimeout ghostDuration EndGhosting )

        EndGhosting _ ->
            ( { model | ghosting = OnCooldown }, setTimeout ghostCooldown GhostingCoolDownEnded )

        GhostingCoolDownEnded _ ->
            ( { model | ghosting = Available }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ BE.onResize Resized
        , case model.target of
            Nothing ->
                Sub.none

            Just t ->
                BE.onAnimationFrameDelta (Duration.milliseconds >> moveTowards t model.currentPosition >> NewPosition)
        ]


preventContextMenu : msg -> Attribute msg
preventContextMenu msg =
    preventDefaultOn "contextmenu" (Decode.map alwaysPreventDefault (succeed msg))


alwaysPreventDefault : msg -> ( msg, Bool )
alwaysPreventDefault msg =
    ( msg, True )


offsetDecoder : (Int -> Int -> msg) -> Decoder msg
offsetDecoder event =
    Decode.map2 event
        (Decode.field "offsetX" Decode.int)
        (Decode.field "offsetY" Decode.int)


isGameWon : Model -> Bool
isGameWon model =
    model.score == model.totalScore && model.totalScore > 0


view : Model -> Html Msg
view model =
    div []
        [ viewPlayfield model
        , span
            ([ id "score"
             , class "noselect"
             ]
                ++ (if model.isScoreAnimating then
                        [ class "animCounterIncrease" ]

                    else
                        []
                   )
            )
            [ text (String.fromInt model.score ++ "/" ++ String.fromInt model.totalScore) ]
        , input
            [ type_ "button"
            , class "gameButton"
            , id "btnGhost"
            , value "Geistern"
            , disabled (model.ghosting /= Available)
            , onClick StartGhosting
            ]
            []
        , div
            (class "disabler"
                :: (if isGameWon model then
                        [ style "display" "block" ]

                    else
                        []
                   )
            )
            []
        , div
            ([ class "splashScreen"
             , id "victoryScreen"
             ]
                ++ (if isGameWon model then
                        []

                    else
                        [ style "display" "none" ]
                   )
            )
            [ div [ class "splashTitle" ] [ text "Gewonnen" ]
            , div [ class "splashMessage" ] [ text "Du hast alle Quadrate gesammelt." ]
            , input
                [ type_ "button"
                , class "splashButton"
                , value "Neues Spiel"
                , id "btnNewGame"
                , onClick NewGame
                ]
                []
            ]
        ]


viewPlayfield : Model -> Html Msg
viewPlayfield model =
    WebGL.toHtmlWith
        [ WebGL.alpha False, WebGL.antialias, WebGL.depth 1 ]
        [ id "playfield"
        , preventContextMenu DoNothing
        , width model.width
        , height model.height
        , on "mouseup" (offsetDecoder TargetSelected)
        ]
        (case model.maze.data of
            Nothing ->
                []

            Just mazeData ->
                [ background model.modelViewProjectionMatrix model.translationMatrix
                , walls mazeData.wallMesh (getWallColor model.ghosting) model.modelViewProjectionMatrix
                ]
                    ++ List.map (plate model.modelViewProjectionMatrix) model.plates
                    ++ [ avatar model.modelViewProjectionMatrix model.translationMatrix
                       ]
        )
