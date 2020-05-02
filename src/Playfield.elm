module Playfield exposing (World, avatar, background, getModelViewProjectionMatrix, getTranslationMatrix)

-- Elm uses webgl 1 and with that GLES 2 :-(
-- For a good cheat sheet for the GLES 2 shader language, see
-- https://www.khronos.org/files/webgl/webgl-reference-card-1_0.pdf

import Arc2d
import Camera3d
import Circle2d
import Direction3d
import Frame3d exposing (Frame3d)
import Geometry.Interop.LinearAlgebra.Point2d as Point2d
import Geometry.Interop.LinearAlgebra.Point3d as Point3d
import Length exposing (Meters)
import Math.Matrix4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Point2d exposing (Point2d)
import Point3d
import Polyline2d
import Quantity exposing (Quantity)
import Rectangle2d
import SketchPlane3d exposing (SketchPlane3d)
import Viewpoint3d exposing (Viewpoint3d)
import WebGL
import WebGL.Matrices exposing (modelViewProjectionMatrix)


type World
    = World



-- cameraPosition : Point2d Meters World
-- cameraPosition =
--     Point2d.meters 0 0


backgroundPlane : SketchPlane3d Meters World defines
backgroundPlane =
    SketchPlane3d.xy


cameraPlane : SketchPlane3d Meters World defines
cameraPlane =
    SketchPlane3d.moveTo (Point3d.meters 0 0 5) SketchPlane3d.xy


cameraViewpoint : Point2d Meters World -> Viewpoint3d Meters World
cameraViewpoint cameraPosition =
    Viewpoint3d.lookAt
        { eyePoint = Point3d.on cameraPlane cameraPosition
        , focalPoint = Point3d.on backgroundPlane cameraPosition
        , upDirection = Direction3d.positiveY
        }


orthographicCamera : Point2d Meters World -> Camera3d.Camera3d Meters World
orthographicCamera cameraPosition =
    Camera3d.orthographic
        { viewpoint = cameraViewpoint cameraPosition
        , viewportHeight = Length.meters 5
        }


frame : Frame3d Meters World defines
frame =
    Frame3d.atPoint Point3d.origin


getModelViewProjectionMatrix : Float -> Point2d Meters World -> Mat4
getModelViewProjectionMatrix aspectRatio cameraPosition =
    modelViewProjectionMatrix
        frame
        (orthographicCamera cameraPosition)
        { aspectRatio = aspectRatio
        , farClipDepth = Quantity.Quantity 100
        , nearClipDepth = Quantity.Quantity 0
        }


getTranslationMatrix : Point2d Meters World -> Mat4
getTranslationMatrix position =
    Point3d.on backgroundPlane position
        |> Point3d.toVec3
        |> Math.Matrix4.makeTranslate


background : Mat4 -> Mat4 -> WebGL.Entity
background modelViewProjectionMatrix translationMatrix =
    WebGL.entity backgroundVertexShader backgroundFragmentShader backgroundMesh (getUniforms modelViewProjectionMatrix translationMatrix)


avatar : Mat4 -> Mat4 -> WebGL.Entity
avatar modelViewProjectionMatrix translationMatrix =
    WebGL.entity avatarVertexShader avatarFragmentShader avatarMesh (getUniforms modelViewProjectionMatrix translationMatrix)


type alias Vertex =
    { position : Vec2
    , textcoord : Vec2
    }


toVertex : Point2d Meters World -> Vertex
toVertex =
    Point2d.toVec2 >> (\v -> Vertex v v)


backgroundMesh : WebGL.Mesh Vertex
backgroundMesh =
    Rectangle2d.from (Point2d.meters -100 -100) (Point2d.meters 100 100)
        |> Rectangle2d.vertices
        |> List.map toVertex
        |> WebGL.triangleFan


avatarMesh : WebGL.Mesh Vertex
avatarMesh =
    Circle2d.atOrigin (Length.meters 0.15)
        |> Circle2d.toArc
        |> Arc2d.toPolyline { maxError = Length.meters 0.001 }
        |> Polyline2d.vertices
        |> (\vs -> Point2d.origin :: vs)
        |> List.map toVertex
        |> WebGL.triangleFan


type alias Uniforms =
    { perspective : Mat4
    , translation : Mat4
    }


getUniforms : Mat4 -> Mat4 -> Uniforms
getUniforms modelViewProjectionMatrix translationMatrix =
    { perspective = modelViewProjectionMatrix
    , translation = translationMatrix
    }


type alias Varyings =
    { vtextcoord : Vec2
    }


avatarVertexShader : WebGL.Shader Vertex Uniforms Varyings
avatarVertexShader =
    [glsl|
        attribute vec2 position;
        attribute vec2 textcoord;
        uniform mat4 perspective;
        uniform mat4 translation;

        varying vec2 vtextcoord;

        void main () {
            vtextcoord = textcoord;
            gl_Position = perspective * translation * vec4(position, 0., 1.0);
        }
    |]


backgroundVertexShader : WebGL.Shader Vertex Uniforms Varyings
backgroundVertexShader =
    [glsl|
        attribute vec2 position;
        attribute vec2 textcoord;
        uniform mat4 perspective;

        varying vec2 vtextcoord;

        void main () {
            vtextcoord = textcoord;
            gl_Position = perspective * vec4(position, 0., 1.0);
        }
    |]


avatarFragmentShader : WebGL.Shader {} Uniforms Varyings
avatarFragmentShader =
    [glsl|
        precision mediump float;
        varying vec2 vtextcoord;
        
        void main () {
            gl_FragColor = vec4(0., 1., 0., 0.);
        }
    |]


backgroundFragmentShader : WebGL.Shader {} Uniforms Varyings
backgroundFragmentShader =
    [glsl|
        precision mediump float;
        const vec4 color1 = vec4(0.,float(0x3f)/255.,float(0x72)/255., 0.);
        const vec4 color2 = vec4(0.,float(0x69)/255.,float(0xbe)/255., 0.);
        const float width = 2.;

        varying vec2 vtextcoord;

        // Note: ^^ does not compile by Elm, so I had to write my own xor.
        bool xor (bool a, bool b) {
            return (a && !b) || (!a && b);
        }

        void main () {
            if (xor(mod(vtextcoord.x, width) < width/2., mod(vtextcoord.y, width) < width/2.))
            {
                gl_FragColor = color1;
            }
            else 
            {
                gl_FragColor = color2;
            }
        }
    |]
