module Labyrinth exposing (Maze, MazeData, createMaze, doorwayGenerator, walls)

import Angle
import Dict
import Geometry.Interop.LinearAlgebra.Point2d as Point2d
import Length exposing (Meters)
import Math.Matrix4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Math.Vector4 exposing (Vec4, vec4)
import Playfield exposing (World)
import Point2d exposing (Point2d)
import Random exposing (Generator)
import Rectangle2d exposing (Rectangle2d)
import Vector2d exposing (Vector2d)
import WebGL


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
    { cellList : List Cell -- not sure, if this is even needed
    , wallStructure : Dict.Dict ( Int, Int ) (List Wall)
    , wallMesh : WebGL.Mesh Vertex
    }


cell : ( Bool, Bool ) -> Cell
cell ( isSouthOpen, isEastOpen ) =
    { isNorthOpen = False
    , isWestOpen = False
    , isSouthOpen = isSouthOpen
    , isEastOpen = isEastOpen
    }


cells : List ( Bool, Bool ) -> List Cell
cells =
    List.map cell


type alias Vertex =
    { position : Vec2
    }


type alias Wall =
    Rectangle2d Meters World


toVertex : Point2d Meters World -> Vertex
toVertex =
    Point2d.toVec2 >> Vertex


thickness =
    0.25


closeEastModel =
    Rectangle2d.from (Point2d.meters 0.5 0.75) (Point2d.meters (0.5 + thickness) -0.75)


closeWestModel =
    Rectangle2d.translateBy (Vector2d.meters -1.25 0) closeEastModel


closeNorthModel =
    Rectangle2d.rotateAround Point2d.origin (Angle.degrees 90) closeEastModel


closeSouthModel =
    Rectangle2d.translateBy (Vector2d.meters 0 -1.25) closeNorthModel


openTopEast =
    Rectangle2d.from (Point2d.meters 0.5 0.5) (Point2d.meters 1.5 (0.5 + thickness))


openPairEast =
    [ openTopEast
    , Rectangle2d.translateBy (Vector2d.meters 0 -1.25) openTopEast
    ]


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


getIndex2d : Int -> Int -> Int -> ( Int, Int )
getIndex2d width height index =
    ( index // height, modBy height index )


intoDict : Int -> Int -> List Cell -> Dict.Dict ( Int, Int ) Cell
intoDict width height maze =
    List.indexedMap (\i tile -> ( getIndex2d width height i, tile )) maze
        |> Dict.fromList


cellCenter : ( Int, Int ) -> Vector2d Meters World
cellCenter index =
    index
        |> Tuple.mapBoth toFloat (toFloat >> negate)
        |> Vector2d.fromTuple Length.meters
        |> Vector2d.scaleBy 2


testMaze : Dict.Dict ( Int, Int ) Cell
testMaze =
    intoDict 2
        2
        [ cell ( False, True )
        , cell ( True, False )
        , cell ( True, False )
        , cell ( False, True )
        ]


sanitize width height maze index tile =
    tile
        |> sanitizeEastBorder width height index
        |> sanitizeSouthBorder width height index
        |> sanitizeNorthBorder maze index
        |> sanitizeWestBorder maze index


shouldEastBeClosed width height ( x, y ) =
    x == width - 1


sanitizeEastBorder width height index tile =
    if shouldEastBeClosed width height index && tile.isEastOpen then
        { tile | isEastOpen = False }

    else
        tile


shouldSouthBeClosed width height ( x, y ) =
    y == height - 1


sanitizeSouthBorder width height index tile =
    if shouldSouthBeClosed width height index && tile.isSouthOpen then
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


sanitizeNorthBorder maze index tile =
    if shouldNorthBeOpen maze index && not tile.isNorthOpen then
        { tile | isNorthOpen = True }

    else
        tile


shouldWestBeOpen maze ( x, y ) =
    x
        > 0
        && (Dict.get ( x - 1, y ) maze
                |> Maybe.map (\tile -> tile.isEastOpen)
                |> Maybe.withDefault False
           )


sanitizeWestBorder maze index tile =
    if shouldWestBeOpen maze index && not tile.isWestOpen then
        { tile | isWestOpen = True }

    else
        tile


createModel : ( Int, Int ) -> Cell -> List Wall
createModel index tile =
    List.map (Rectangle2d.translateBy (cellCenter index)) (cellToWalls tile)


{-| Mapping from tile index to surrounding walls.
Important for collision detection.
-}
wallDataStructure : Int -> Int -> List Cell -> Dict.Dict ( Int, Int ) (List Wall)
wallDataStructure width height maze =
    maze
        |> intoDict width height
        |> Dict.map (sanitize width height (intoDict width height maze))
        |> Dict.map createModel


createMaze : Int -> Int -> List ( Bool, Bool ) -> MazeData
createMaze width height randomValues =
    { cellList = cells randomValues
    , wallStructure = wallDataStructure width height (cells randomValues)
    , wallMesh = wallMesh (wallModel (wallDataStructure width height (cells randomValues)))
    }


wallModel : Dict.Dict ( Int, Int ) (List Wall) -> List Wall
wallModel wallData =
    wallData
        |> Dict.values
        |> List.concatMap identity


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


wallMesh : List Wall -> WebGL.Mesh Vertex
wallMesh model =
    List.concatMap triangulateRect model
        |> WebGL.triangles


type alias Uniforms =
    { perspective : Mat4
    , color : Vec4
    }


getUniforms : Mat4 -> Uniforms
getUniforms modelViewProjectionMatrix =
    { perspective = modelViewProjectionMatrix
    , color = vec4 0 0 0 0
    }


wallsVertexShader : WebGL.Shader Vertex Uniforms {}
wallsVertexShader =
    [glsl|
        attribute vec2 position;
        uniform mat4 perspective;

        void main () {
            gl_Position = perspective * vec4(position, 0., 1.0);
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


walls : WebGL.Mesh Vertex -> Mat4 -> WebGL.Entity
walls mesh modelViewProjectionMatrix =
    WebGL.entity wallsVertexShader wallsFragmentShader mesh (getUniforms modelViewProjectionMatrix)
