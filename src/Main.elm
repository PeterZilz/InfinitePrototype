module Main exposing (Model, Msg, init, main, subscriptions, update, view)

import Browser
import Browser.Events as BE
import Direction2d
import Duration
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, preventDefaultOn)
import Json.Decode as Decode exposing (Decoder, succeed)
import Labyrinth exposing (..)
import Length exposing (Meters)
import Math.Matrix4 exposing (Mat4)
import Pixels exposing (Pixels)
import Plate exposing (..)
import Playfield exposing (..)
import Point2d exposing (Point2d)
import Process
import Quantity exposing (lessThanOrEqualTo)
import Random
import Rectangle2d exposing (Rectangle2d)
import Speed
import Task
import Vector2d
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
    , target : Maybe (Point2d Meters World)
    , maze : Maze
    , plates : List Plate
    , score : Int
    , totalScore : Int
    , isScoreAnimating : Bool
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
    }


gridWidth : Int
gridWidth =
    3



-- 17


gridHeight : Int
gridHeight =
    3



-- 17


getStartingPoint =
    Point2d.translateBy (cellCenter ( gridWidth // 2, gridHeight // 2 )) Point2d.origin


init : WindowSize -> ( Model, Cmd Msg )
init size =
    ( modelInitialValue size getStartingPoint
    , Random.generate MazeGenerated (doorwayGenerator gridWidth gridHeight)
    )


type Msg
    = DoNothing
    | Resized Int Int
    | TargetSelected Int Int
    | NewPosition (Point2d Meters World)
    | MazeGenerated (List ( Bool, Bool ))
    | PlatesPlaced (List Plate)
    | ScoreAnimationEnded ()


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


updateCurrentPosition : Point2d Meters World -> Model -> Model
updateCurrentPosition newPosition model =
    { model
        | currentPosition = newPosition
        , modelViewProjectionMatrix = getModelViewProjectionMatrix (toFloat model.width / toFloat model.height) newPosition
        , translationMatrix = getTranslationMatrix newPosition
        , target = updateTarget model.target newPosition
    }


enteredTriggerArea : Point2d Meters World -> Plate -> Maybe Plate
enteredTriggerArea position area =
    if Rectangle2d.contains position area.triggerArea then
        Just area

    else
        Nothing


getEnteredTriggerAreas : Point2d Meters World -> List Plate -> List Plate
getEnteredTriggerAreas position plates =
    List.filterMap (enteredTriggerArea position) plates


{-| The time the score animation takes in ms.
Has to be consistent with the css class "animCounterIncrease".
-}
scoreAnimationDuration : Float
scoreAnimationDuration =
    400


delayedEndScoreAnimation : Cmd Msg
delayedEndScoreAnimation =
    Process.sleep scoreAnimationDuration
        |> Task.perform ScoreAnimationEnded


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


moveToNewPosition : Point2d Meters World -> Model -> ( Model, Cmd Msg )
moveToNewPosition newPosition model =
    if wouldCrossAnyWall model.maze model.currentPosition newPosition then
        ( { model | target = Nothing }, Cmd.none )

    else
        updateCurrentPosition newPosition model
            |> processPlateAreas newPosition
            |> (\m ->
                    if not model.isScoreAnimating && m.isScoreAnimating then
                        ( m, delayedEndScoreAnimation )

                    else
                        ( m, Cmd.none )
               )


updateTarget : Maybe (Point2d Meters World) -> Point2d Meters World -> Maybe (Point2d Meters World)
updateTarget target newPosition =
    case target of
        Nothing ->
            target

        Just t ->
            if t == newPosition then
                Nothing

            else
                target


generateMaze : Int -> Int -> List ( Bool, Bool ) -> Maze
generateMaze width height randomValues =
    { width = width
    , height = height
    , data = Just (createMaze width height randomValues)
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
            ( { model | target = Just (pixelToWorld model x y) }, Cmd.none )

        NewPosition pos ->
            moveToNewPosition pos model

        MazeGenerated bools ->
            ( { model | maze = generateMaze model.maze.width model.maze.height bools }
            , Random.generate PlatesPlaced (plateGenerator gridWidth gridHeight 1)
            )

        PlatesPlaced plates ->
            ( { model | plates = plates, totalScore = List.length plates }
            , Cmd.none
            )

        ScoreAnimationEnded _ ->
            ( { model | isScoreAnimating = False }, Cmd.none )


speed : Speed.Speed
speed =
    Speed.metersPerSecond 10


moveTowards : Point2d Meters World -> Point2d Meters World -> Duration.Duration -> Point2d Meters World
moveTowards target current tDelta =
    let
        dist =
            Point2d.distanceFrom target current

        stepSize =
            Quantity.at speed tDelta
    in
    if lessThanOrEqualTo stepSize dist then
        target

    else
        Point2d.translateBy
            (Direction2d.from current target
                |> Maybe.map (Vector2d.withLength stepSize)
                |> Maybe.withDefault Vector2d.zero
            )
            current


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
    WebGL.toHtmlWith
        [ WebGL.alpha False, WebGL.antialias, WebGL.depth 1 ]
        [ id "playfield"
        , preventContextMenu DoNothing
        , width model.width
        , height model.height
        , onPlayfieldMouseUp
        ]
        (case model.maze.data of
            Nothing ->
                []

            Just mazeData ->
                [ walls mazeData.wallMesh model.modelViewProjectionMatrix
                , background model.modelViewProjectionMatrix model.translationMatrix
                ]
                    ++ List.map (plate model.modelViewProjectionMatrix) model.plates
                    ++ [ avatar model.modelViewProjectionMatrix model.translationMatrix
                       ]
        )


offsetDecoder : (Int -> Int -> msg) -> Decoder msg
offsetDecoder event =
    Decode.map2 event
        (Decode.field "offsetX" Decode.int)
        (Decode.field "offsetY" Decode.int)


onPlayfieldMouseUp : Attribute Msg
onPlayfieldMouseUp =
    on "mouseup" (offsetDecoder TargetSelected)
