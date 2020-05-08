module WebGLRendering exposing (ScreenPixels, Varyings, Vertex, World, toVertex)

import Geometry.Interop.LinearAlgebra.Point2d as Point2d
import Length exposing (Meters)
import Math.Vector2 exposing (Vec2)
import Point2d exposing (Point2d)


type World
    = World


type ScreenPixels
    = ScreenPixels


type alias Vertex =
    { position : Vec2
    , textcoord : Vec2
    }


type alias Varyings =
    { vtextcoord : Vec2
    }


toVertex : Point2d Meters World -> Vertex
toVertex =
    Point2d.toVec2 >> (\v -> Vertex v v)
