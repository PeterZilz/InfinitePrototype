module Game exposing
    ( GhostingStatus(..)
    , generateMaze
    , getEnteredTriggerAreas
    , getStartingPoint
    , getWallColor
    , ghostCooldown
    , ghostDuration
    , gridHeight
    , gridWidth
    , moveTowards
    , scoreAnimationDuration
    , totalPlates
    , updateTarget
    )

import Direction2d
import Duration
import Labyrinth exposing (Maze, cellCenter, createMaze)
import Length exposing (Meters)
import Math.Vector4 exposing (Vec4, vec4)
import Plate exposing (Plate)
import Point2d exposing (Point2d)
import Quantity exposing (lessThanOrEqualTo)
import Rectangle2d
import Speed
import Vector2d
import WebGLRendering exposing (World)



-- ### CONSTANTS ###


gridWidth : Int
gridWidth =
    17


gridHeight : Int
gridHeight =
    17


totalPlates : Int
totalPlates =
    20


{-| The time the score animation takes in ms.
Has to be consistent with the css class "animCounterIncrease".
-}
scoreAnimationDuration : Float
scoreAnimationDuration =
    400


ghostDuration : Float
ghostDuration =
    2000


ghostCooldown : Float
ghostCooldown =
    10000


speed : Speed.Speed
speed =
    Speed.metersPerSecond 10



-- ### TYPES ###


type GhostingStatus
    = OnCooldown
    | Available
    | Ongoing



-- ### FUNCTIONS ###


getStartingPoint =
    Point2d.translateBy (cellCenter ( gridWidth // 2, gridHeight // 2 )) Point2d.origin


enteredTriggerArea : Point2d Meters World -> Plate -> Maybe Plate
enteredTriggerArea position area =
    if Rectangle2d.contains position area.triggerArea then
        Just area

    else
        Nothing


getEnteredTriggerAreas : Point2d Meters World -> List Plate -> List Plate
getEnteredTriggerAreas position plates =
    List.filterMap (enteredTriggerArea position) plates


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


getWallColor : GhostingStatus -> Vec4
getWallColor ghosting =
    case ghosting of
        Ongoing ->
            vec4 (0xEE / 0xFF) (0xEE / 0xFF) (0xEE / 0xFF) (0x30 / 0xFF)

        _ ->
            vec4 (0x10 / 0xFF) (0x10 / 0xFF) (0x10 / 0xFF) 1
