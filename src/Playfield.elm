module Playfield exposing (background, getModelViewProjectionMatrix, World)

-- Elm uses webgl 1 and with that GLES 2 :-(
-- For a good cheat sheet for the GLES 2 shader language, see
-- https://www.khronos.org/files/webgl/webgl-reference-card-1_0.pdf

import Camera3d
import Direction3d
import Frame3d exposing (Frame3d)
import Geometry.Interop.LinearAlgebra.Point2d as Point2d
import Length exposing (Meters)
import Math.Matrix4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Plane3d
import Point2d
import Point3d exposing (Point3d)
import Quantity exposing (Quantity)
import Rectangle2d
import Viewpoint3d exposing (Viewpoint3d)
import WebGL
import WebGL.Matrices exposing (modelViewProjectionMatrix)


type World
    = World


cameraPosition : Point3d Meters World
cameraPosition =
    Point3d.meters 0 0 5


cameraViewpoint : Viewpoint3d Meters World
cameraViewpoint =
    Viewpoint3d.lookAt
        { eyePoint = cameraPosition
        , focalPoint = Point3d.projectOnto Plane3d.xy cameraPosition
        , upDirection = Direction3d.positiveY
        }


orthographicCamera : Camera3d.Camera3d Meters World
orthographicCamera =
    Camera3d.orthographic
        { viewpoint = cameraViewpoint
        , viewportHeight = Length.meters 5
        }


frame : Frame3d Meters World {}
frame =
    Frame3d.atPoint Point3d.origin


getModelViewProjectionMatrix : Float -> Mat4
getModelViewProjectionMatrix aspectRatio =
    modelViewProjectionMatrix
        frame
        orthographicCamera
        { aspectRatio = aspectRatio
        , farClipDepth = Quantity.Quantity 100
        , nearClipDepth = Quantity.Quantity 0
        }


background : Mat4 -> WebGL.Entity
background modelViewProjectionMatrix =
    WebGL.entity vertexShader fragmentShader backgroundMesh (getUniforms modelViewProjectionMatrix)


type alias Vertex =
    { position : Vec2
    , textcoord : Vec2
    }


backgroundModel : Rectangle2d.Rectangle2d Meters World
backgroundModel =
    Rectangle2d.from (Point2d.meters 1 1) (Point2d.meters -1 -1)


backgroundMesh : WebGL.Mesh Vertex
backgroundMesh =
    backgroundModel
        |> Rectangle2d.vertices
        |> List.map (Point2d.toVec2 >> (\v -> Vertex v v))
        |> WebGL.triangleFan


type alias Uniforms =
    { perspective : Mat4
    }


getUniforms : Mat4 -> Uniforms
getUniforms modelViewProjectionMatrix =
    { perspective = modelViewProjectionMatrix
    }


type alias Varyings =
    { vtextcoord : Vec2
    }


vertexShader : WebGL.Shader Vertex Uniforms Varyings
vertexShader =
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


fragmentShader : WebGL.Shader {} Uniforms Varyings
fragmentShader =
    [glsl|
        precision mediump float;
        const vec4 color1 = vec4(0.,float(0x3f)/255.,float(0x72)/255., 0.);
        const vec4 color2 = vec4(0.,float(0x69)/255.,float(0xbe)/255., 0.);
        const float width = 1.;

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
