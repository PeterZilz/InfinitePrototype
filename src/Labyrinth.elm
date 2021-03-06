module Labyrinth exposing (Maze, MazeData, cellCenter, createMaze, doorwayGenerator, triangulateRect, walls, wouldCrossAnyWall)

import Angle
import Dict
import Geometry.Interop.LinearAlgebra.Point2d as Point2d
import Length exposing (Meters)
import LineSegment2d exposing (LineSegment2d)
import Math.Matrix4 exposing (Mat4)
import Math.Vector4 exposing (Vec4)
import Point2d exposing (Point2d)
import Random exposing (Generator)
import Rectangle2d exposing (Rectangle2d)
import Vector2d exposing (Vector2d)
import WebGL
import WebGL.Settings.Blend as Blend
import WebGLRendering exposing (Vertex, World, toVertex)


connectionGenerator : Generator Bool
connectionGenerator =
    Random.uniform False [ True ]


doorwayGenerator : Int -> Int -> Generator (List ( Bool, Bool ))
doorwayGenerator width height =
    Random.list (width * height) (Random.pair connectionGenerator connectionGenerator)


type alias Cell =
    { isNorthOpen : Bool
    , isWestOpen : Bool
    , isSouthOpen : Bool
    , isEastOpen : Bool
    }


type alias Maze =
    { width : Int
    , height : Int
    , data : Maybe MazeData
    }


type alias MazeData =
    { wallStructure : Dict.Dict ( Int, Int ) (List Wall)
    , wallMesh : WebGL.Mesh Vertex
    }


cell : ( Bool, Bool ) -> Cell
cell ( isSouthOpen, isEastOpen ) =
    { isNorthOpen = False
    , isWestOpen = False
    , isSouthOpen = isSouthOpen
    , isEastOpen = isEastOpen
    }


toCells : List ( Bool, Bool ) -> List Cell
toCells =
    List.map cell


type alias Wall =
    Rectangle2d Meters World


thickness : Float
thickness =
    0.25


closeEastModel : Wall
closeEastModel =
    Rectangle2d.from (Point2d.meters 0.5 0.75) (Point2d.meters (0.5 + thickness) -0.75)


closeWestModel : Wall
closeWestModel =
    Rectangle2d.translateBy (Vector2d.meters -1.25 0) closeEastModel


closeNorthModel : Wall
closeNorthModel =
    Rectangle2d.rotateAround Point2d.origin (Angle.degrees 90) closeEastModel


closeSouthModel : Wall
closeSouthModel =
    Rectangle2d.translateBy (Vector2d.meters 0 -1.25) closeNorthModel


openTopEast : Wall
openTopEast =
    Rectangle2d.from (Point2d.meters 0.5 0.5) (Point2d.meters 1.5 (0.5 + thickness))


openPairEast : List Wall
openPairEast =
    [ openTopEast
    , Rectangle2d.translateBy (Vector2d.meters 0 -1.25) openTopEast
    ]


openPairSouth : List Wall
openPairSouth =
    List.map
        (Rectangle2d.rotateAround Point2d.origin (Angle.degrees -90))
        openPairEast


cellToWalls : Cell -> List Wall
cellToWalls tile =
    (if tile.isEastOpen then
        openPairEast

     else
        [ closeEastModel ]
    )
        ++ (if tile.isSouthOpen then
                openPairSouth

            else
                [ closeSouthModel ]
           )
        ++ (if tile.isNorthOpen then
                []

            else
                [ closeNorthModel ]
           )
        ++ (if tile.isWestOpen then
                []

            else
                [ closeWestModel ]
           )


getIndex2d : Int -> Int -> ( Int, Int )
getIndex2d height index =
    ( index // height, modBy height index )


{-| This is the inverse of "cellCenter".
-}
toGridIndex : Point2d Meters World -> ( Int, Int )
toGridIndex point =
    Point2d.toTuple Length.inMeters point
        |> Tuple.mapBoth (\x -> round (x / 2)) (\x -> round (-x / 2))


getCellWalls : MazeData -> ( Int, Int ) -> List Wall
getCellWalls maze index =
    Maybe.withDefault [] (Dict.get index maze.wallStructure)


getNeighborhood : ( Int, Int ) -> List ( Int, Int )
getNeighborhood ( x, y ) =
    [ ( x - 1, y )
    , ( x, y - 1 )
    , ( x, y )
    , ( x + 1, y )
    , ( x, y + 1 )
    ]


getLocalWalls : MazeData -> Point2d Meters World -> List Wall
getLocalWalls maze position =
    List.concatMap (getCellWalls maze) (getNeighborhood (toGridIndex position))


wouldCrossWall : LineSegment2d Meters World -> Wall -> Bool
wouldCrossWall travelPath wall =
    Rectangle2d.edges wall
        |> List.any (\edge -> LineSegment2d.intersectionPoint travelPath edge /= Nothing)


wouldCrossAnyWall : Maze -> Point2d Meters World -> Point2d Meters World -> Bool
wouldCrossAnyWall maze current target =
    case maze.data of
        Nothing ->
            False

        Just labyrinth ->
            List.any (wouldCrossWall (LineSegment2d.from current target)) (getLocalWalls labyrinth current)


intoDict : Int -> List a -> Dict.Dict ( Int, Int ) a
intoDict height items =
    List.indexedMap (\index item -> ( getIndex2d height index, item )) items
        |> Dict.fromList


cellCenter : ( Int, Int ) -> Vector2d Meters World
cellCenter index =
    index
        |> Tuple.mapBoth toFloat (toFloat >> negate)
        |> Vector2d.fromTuple Length.meters
        |> Vector2d.scaleBy 2


sanitize : Int -> Int -> Dict.Dict ( Int, Int ) Cell -> ( Int, Int ) -> Cell -> Cell
sanitize width height maze index tile =
    tile
        |> sanitizeEastBorder width index
        |> sanitizeSouthBorder height index
        |> sanitizeNorthBorder maze index
        |> sanitizeWestBorder maze index


shouldEastBeClosed : Int -> ( Int, Int ) -> Bool
shouldEastBeClosed width ( x, _ ) =
    x == width - 1


sanitizeEastBorder : Int -> ( Int, Int ) -> Cell -> Cell
sanitizeEastBorder width index tile =
    if shouldEastBeClosed width index && tile.isEastOpen then
        { tile | isEastOpen = False }

    else
        tile


shouldSouthBeClosed : Int -> ( Int, Int ) -> Bool
shouldSouthBeClosed height ( _, y ) =
    y == height - 1


sanitizeSouthBorder : Int -> ( Int, Int ) -> Cell -> Cell
sanitizeSouthBorder height index tile =
    if shouldSouthBeClosed height index && tile.isSouthOpen then
        { tile | isSouthOpen = False }

    else
        tile


shouldNorthBeOpen : Dict.Dict ( Int, Int ) Cell -> ( Int, Int ) -> Bool
shouldNorthBeOpen maze ( x, y ) =
    y
        > 0
        && (Dict.get ( x, y - 1 ) maze
                |> Maybe.map (\tile -> tile.isSouthOpen)
                |> Maybe.withDefault False
           )


sanitizeNorthBorder : Dict.Dict ( Int, Int ) Cell -> ( Int, Int ) -> Cell -> Cell
sanitizeNorthBorder maze index tile =
    if shouldNorthBeOpen maze index && not tile.isNorthOpen then
        { tile | isNorthOpen = True }

    else
        tile


shouldWestBeOpen : Dict.Dict ( Int, Int ) Cell -> ( Int, Int ) -> Bool
shouldWestBeOpen maze ( x, y ) =
    x
        > 0
        && (Dict.get ( x - 1, y ) maze
                |> Maybe.map (\tile -> tile.isEastOpen)
                |> Maybe.withDefault False
           )


sanitizeWestBorder : Dict.Dict ( Int, Int ) Cell -> ( Int, Int ) -> Cell -> Cell
sanitizeWestBorder maze index tile =
    if shouldWestBeOpen maze index && not tile.isWestOpen then
        { tile | isWestOpen = True }

    else
        tile


createModel : ( Int, Int ) -> Cell -> List Wall
createModel index =
    cellToWalls
        >> List.map (Rectangle2d.translateBy (cellCenter index))


toWallModel : Dict.Dict ( Int, Int ) Cell -> Dict.Dict ( Int, Int ) (List Wall)
toWallModel =
    Dict.map createModel


sanitizeCells : Int -> Int -> Dict.Dict ( Int, Int ) Cell -> Dict.Dict ( Int, Int ) Cell
sanitizeCells width height cellDict =
    Dict.map (sanitize width height cellDict) cellDict


getMazeData : Dict.Dict ( Int, Int ) (List Wall) -> MazeData
getMazeData wallDict =
    { wallStructure = wallDict
    , wallMesh = wallDict |> flattenWallStructure |> toMesh
    }


createMaze : Int -> Int -> List ( Bool, Bool ) -> MazeData
createMaze width height randomConnections =
    randomConnections
        |> toCells
        |> intoDict height
        |> sanitizeCells width height
        |> toWallModel
        |> getMazeData


flattenWallStructure : Dict.Dict ( Int, Int ) (List Wall) -> List Wall
flattenWallStructure =
    Dict.values
        >> List.concatMap identity


toTriples : List a -> List ( a, a, a )
toTriples list =
    case list of
        w :: x :: y :: z :: _ ->
            [ ( w, x, y ), ( y, z, w ) ]

        _ ->
            []


triangulateRect : Rectangle2d Meters World -> List ( Vertex, Vertex, Vertex )
triangulateRect =
    Rectangle2d.vertices
        >> List.map toVertex
        >> toTriples


toMesh : List Wall -> WebGL.Mesh Vertex
toMesh =
    List.concatMap triangulateRect
        >> WebGL.triangles


type alias Uniforms =
    { perspective : Mat4
    , color : Vec4
    }


getUniforms : Vec4 -> Mat4 -> Uniforms
getUniforms color modelViewProjectionMatrix =
    { perspective = modelViewProjectionMatrix
    , color = color
    }


wallsVertexShader : WebGL.Shader Vertex Uniforms {}
wallsVertexShader =
    [glsl|
        attribute vec2 position;
        uniform mat4 perspective;

        void main () {
            gl_Position = perspective * vec4(position, 0.1, 1.0);
        }
    |]


wallsFragmentShader : WebGL.Shader {} Uniforms {}
wallsFragmentShader =
    [glsl|
        precision mediump float;
        uniform vec4 color;

        void main () {
            gl_FragColor = color;
        }
    |]


walls : WebGL.Mesh Vertex -> Vec4 -> Mat4 -> WebGL.Entity
walls mesh color modelViewProjectionMatrix =
    WebGL.entityWith
        [ Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha ]
        wallsVertexShader
        wallsFragmentShader
        mesh
        (getUniforms color modelViewProjectionMatrix)
