module Plate exposing (plate)

import Geometry.Interop.LinearAlgebra.Point2d as Point2d
import Labyrinth exposing (triangulateRect)
import Length exposing (Meters)
import Math.Matrix4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Math.Vector4 exposing (Vec4, vec4)
import Playfield exposing (World)
import Point2d
import Rectangle2d exposing (Rectangle2d)
import WebGL
import WebGL.Settings.Blend as Blend


plateModel : Rectangle2d Meters World
plateModel =
    Rectangle2d.from
        (Point2d.meters 0.25 0.25)
        (Point2d.meters -0.25 -0.25)


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


plate : Mat4 -> Mat4 -> WebGL.Entity
plate modelViewProjectionMatrix translationMatrix =
    WebGL.entityWith
        [ Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha ]
        -- makes transparency work
        plateVertexShader
        plateFragmentShader
        plateMesh
        (getUniforms modelViewProjectionMatrix translationMatrix)
