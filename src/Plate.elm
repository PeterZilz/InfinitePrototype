module Plate exposing (Plate, placePlateInCell, plate, plateGenerator)

import Geometry.Interop.LinearAlgebra.Point2d as Point2d
import Geometry.Interop.LinearAlgebra.Vector2d as Vector2d
import Labyrinth exposing (cellCenter, triangulateRect)
import Length exposing (Meters)
import Math.Matrix4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Math.Vector3 exposing (vec3)
import Math.Vector4 exposing (Vec4, vec4)
import Playfield exposing (World, avatarRadius)
import Point2d
import Random exposing (Generator)
import Rectangle2d exposing (Rectangle2d)
import Vector2d exposing (Vector2d)
import WebGL
import WebGL.Settings.Blend as Blend


plateGenerator : Int -> Int -> Int -> Generator (List Plate)
plateGenerator width height amount =
    Random.list amount (Random.map placePlateInCell (Random.pair (Random.int 0 (width - 1)) (Random.int 0 (height - 1))))


type alias Plate =
    { translation : Mat4
    , triggerArea : Rectangle2d Meters World
    }


plateTopRightCorner =
    Point2d.meters 0.25 0.25


plateBottomLeftCorner =
    Point2d.meters -0.25 -0.25


plateModel : Rectangle2d Meters World
plateModel =
    Rectangle2d.from
        plateTopRightCorner
        plateBottomLeftCorner


triggerArea : Rectangle2d Meters World
triggerArea =
    Rectangle2d.from
        (plateTopRightCorner |> Point2d.translateBy (Vector2d.meters avatarRadius avatarRadius))
        (plateBottomLeftCorner |> Point2d.translateBy (Vector2d.meters -avatarRadius -avatarRadius))


addZ { x, y } =
    vec3 x y 0


placePlateInCell : ( Int, Int ) -> Plate
placePlateInCell index =
    cellCenter index |> createPlateAt


createPlateAt : Vector2d Meters World -> Plate
createPlateAt center =
    { translation = center |> Vector2d.toRecord Length.inMeters |> addZ |> Math.Matrix4.makeTranslate
    , triggerArea = Rectangle2d.translateBy center triggerArea
    }


plateMesh : WebGL.Mesh Vertex
plateMesh =
    triangulateRect plateModel
        |> WebGL.triangles


type alias Vertex =
    { position : Vec2
    }


type alias Uniforms =
    { perspective : Mat4
    , translation : Mat4
    , color : Vec4
    }


getUniforms : Mat4 -> Mat4 -> Uniforms
getUniforms modelViewProjectionMatrix translationMatrix =
    { perspective = modelViewProjectionMatrix
    , translation = translationMatrix
    , color = vec4 0.921 0.137 0.955 0.633
    }


plateVertexShader : WebGL.Shader Vertex Uniforms {}
plateVertexShader =
    [glsl|
        attribute vec2 position;
        uniform mat4 perspective;
        uniform mat4 translation;

        void main () {
            gl_Position = perspective * translation * vec4(position, 0.1, 1.0);
        }
    |]


plateFragmentShader : WebGL.Shader {} Uniforms {}
plateFragmentShader =
    [glsl|
        precision mediump float;
        uniform vec4 color;

        void main () {
            gl_FragColor = color;
        }
    |]


plate : Mat4 -> Plate -> WebGL.Entity
plate modelViewProjectionMatrix { translation } =
    WebGL.entityWith
        [ Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha ]
        -- Blend makes transparency work
        plateVertexShader
        plateFragmentShader
        plateMesh
        (getUniforms modelViewProjectionMatrix translation)
