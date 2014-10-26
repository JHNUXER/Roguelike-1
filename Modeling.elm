module Modeling where

import Math.Vector3 (..)
import Math.Vector4 (..)
import Math.Matrix4 (..)
import Graphics.WebGL (..)

type Vertex = { position:Vec3, color:Vec3 }
type Point = (Float, Float)

quad : Point -> Point -> Point -> Point -> Vec3 -> [Triangle Vertex]
quad (x1, y1) (x2, y2) (x3, y3) (x4, y4) color =
    [ ( Vertex (vec3 x1 y1 0) color
      , Vertex (vec3 x2 y2 0) color
      , Vertex (vec3 x3 y3 0) color
      )
    , ( Vertex (vec3 x3 y3 0) color
      , Vertex (vec3 x2 y2 0) color
      , Vertex (vec3 x4 y4 0) color
      )
    ]

fromRGB : Color -> Vec3
fromRGB color =
    let {red, green, blue, alpha} = toRgb color
        div x = toFloat x / 255
    in  vec3 (div red) (div green) (div blue)

shape : Entity
shape =
    let black' = fromRGB black
        white' = fromRGB white
        triangles = quad (-0.1, 0.1) (0.1, 0.1) (-0.1, -0.1) (0.1, -0.1) white'
                 ++ quad (-1, 1) (1, 1) (-1, -1) (1, -1) black'
    in  entity basicVertexShader basicFragmentShader triangles {}

scene = flow right [webgl (400, 400) [shape], spacer 30 30, webgl (15, 20) [shape]]

main = scene

-- Shaders

basicVertexShader : Shader { attr | position:Vec3, color:Vec3 } {} { vcolor:Vec3 }
basicVertexShader = [glsl|

attribute vec3 position;
attribute vec3 color;
varying vec3 vcolor;

void main () {
    gl_Position = vec4(position, 1.0);
    vcolor = color;
}

|]

basicFragmentShader : Shader {} u { vcolor:Vec3 }
basicFragmentShader = [glsl|

precision mediump float;
varying vec3 vcolor;

void main () {
    gl_FragColor = vec4(vcolor, 1.0);
}

|]


circleVertexShader : Shader { attr | position:Vec3, color:Vec3 } {} { vcolor:Vec3, pos:Vec4 }
circleVertexShader = [glsl|

attribute vec3 position;
attribute vec3 color;
varying vec3 vcolor;
varying vec4 pos;

void main () {
    gl_Position = vec4(position, 1.0);
    vcolor = color;
    pos = gl_Position;
}

|]

circleFragmentShader : Shader {} u { vcolor:Vec3, pos:Vec4 }
circleFragmentShader = [glsl|

precision mediump float;
varying vec3 vcolor;
varying vec4 pos;

void main () {
    vec4 center = vec4(0.0, 0.0, 0.0, 1.0);
    float dis = distance(center, pos);

    if (dis < 0.5) {
        gl_FragColor = vec4(vcolor, 1.0);
    } else {
        discard;
    }
}

|]

-- Completed Tiles

wallTile : Entity
wallTile =
    let black' = fromRGB black
        grey' = fromRGB grey
        triangles = quad (-0.15, 0.5) (-0.05, 0.5) (-0.3, -0.5) (-0.2, -0.5) black'
                 ++ quad (0.2, 0.5) (0.3, 0.5) (0.05, -0.5) (0.15, -0.5) black'
                 ++ quad (-0.5, 0.2) (0.5, 0.2) (-0.5, 0.1) (0.5, 0.1) black'
                 ++ quad (-0.5, -0.1) (0.5, -0.1) (-0.5, -0.2) (0.5, -0.2) black'
                 ++ quad (-1, 1) (1, 1) (-1, -1) (1, -1) grey'
    in  entity basicVertexShader basicFragmentShader triangles {}

floorTile : Entity
floorTile =
    let black' = fromRGB black
        white' = fromRGB white
        triangles = quad (-0.1, 0.1) (0.1, 0.1) (-0.1, -0.1) (0.1, -0.1) white'
                 ++ quad (-1, 1) (1, 1) (-1, -1) (1, -1) black'
    in  entity basicVertexShader basicFragmentShader triangles {}
