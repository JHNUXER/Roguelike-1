module WebGLView where

import String
import Text
import Http (..)
import Maybe (isJust)

import GameModel
import GameUpdate
import GameView
import MapGen
import Grid

import Math.Vector2 (Vec2, vec2)
import Math.Vector3 (..)
import Math.Vector4 (Vec4, vec4)
import Math.Matrix4 (..)
import Graphics.WebGL (..)

import Generator
import Generator.Standard

type Vertex = { position:Vec2, offset:Vec2, color:Vec4, coord:Vec2 }
type Point = (Float, Float)

even : Int -> Bool
even n = n % 2 == 0

responseToMaybe : Response a -> Maybe a
responseToMaybe response =
    case response of
        Success a -> Just a
        _         -> Nothing

justs : [Maybe a] -> [a]
justs ms =
    let js = filter isJust ms
        just m = case m of
                    Just x -> x
    in  map just js

-- Higher level API

texture : Signal (Maybe Texture)
texture = responseToMaybe <~ loadTexture "/sprite_sheet1.png"

xScale : Float
xScale = 32

yScale : Float
yScale = 32

tile : (Int, Int) -> Mat4 -> Texture -> GameModel.Tile -> Entity
tile (x, y) perspective texture t =
    case t of
        GameModel.Floor -> floorTile texture perspective <| vec2 (toFloat x) (toFloat y)
        GameModel.Wall  -> wallTile texture perspective <| vec2 (toFloat x) (toFloat y)

fogTiles : (Int, Int) -> Mat4 -> GameModel.Visibility -> Maybe Entity
fogTiles (x, y) perspective t =
    case t of
        GameModel.Unexplored -> Just <| fogTile perspective <| vec2 (toFloat x) (toFloat y)
        GameModel.Explored   -> Nothing --Just <| exploredTile perspective <| vec2 (toFloat x) (toFloat y)
        GameModel.Visible    -> Nothing

texturedTile : Int -> Int -> Texture -> Mat4 -> Vec2 -> Entity
texturedTile x y texture perspective offset =
    let (x', y') = (toFloat x, toFloat y)
        black' = fromRGB black
        triangles = quad (-1, 1) (1, 1) (-1, -1) (1, -1) offset black'
    in  entity vertexShaderTex fragmentShaderTex triangles {perspective = perspective, texture = texture, sprite = vec3 x' y' 0}

coloredTile : Color -> Mat4 -> Vec2 -> Entity
coloredTile color perspective offset =
    let color' = fromRGB color
        triangles = quad (-1, 1) (1, 1) (-1, -1) (1, -1) offset color'
    in  entity vertexShader fragmentShader triangles {perspective = perspective}

wallTile : Texture -> Mat4 -> Vec2 -> Entity
wallTile = texturedTile 3 2

floorTile : Texture -> Mat4 -> Vec2 -> Entity
floorTile = texturedTile 14 2

fogTile : Mat4 -> Vec2 -> Entity
fogTile = coloredTile black

exploredTile : Mat4 -> Vec2 -> Entity
exploredTile = coloredTile (rgba 0 0 0 0.7)

fogger : Grid.Grid GameModel.Visibility -> [Entity]
fogger level =
    let grid = Grid.toList level
        (w, h) = (level.size.width, level.size.height)
        (w' , h')= (w // 2, h // 2)
        (left, right) = case even w of
                            True  -> (toFloat (-w - 1), toFloat w - 1)
                            False -> (toFloat (-w), toFloat w)
        (top, bottom) = case even h of
                            True  -> (toFloat (-h - 1), toFloat h - 1)
                            False -> (toFloat (-h), toFloat h)
        perspective = makeOrtho2D left right top bottom

        row : Int -> [GameModel.Visibility] -> [Entity]
        row y ts = justs <| map (\(t, x) -> fogTiles (x, y) perspective t) <| zip ts [-w'..w' + 1]

        tiles : [Entity]
        tiles = concatMap (\(r, y) -> row y r) <| zip grid (reverse [-h' - 1..h'])
    in  tiles

background : Grid.Grid GameModel.Tile -> Maybe Texture -> ((Int, Int), [Entity])
background level texture =
    let grid = Grid.toList level
        (w, h) = (level.size.width, level.size.height)
        (w' , h')= (w // 2, h // 2)
        (left, right) = case even w of
                            True  -> (toFloat (-w - 1), toFloat w - 1)
                            False -> (toFloat (-w), toFloat w)
        (top, bottom) = case even h of
                            True  -> (toFloat (-h - 1), toFloat h - 1)
                            False -> (toFloat (-h), toFloat h)
        perspective = makeOrtho2D left right top bottom

        row : Texture -> Int -> [GameModel.Tile] -> [Entity]
        row texture y ts = map (\(t, x) -> tile (x, y) perspective texture t) <| zip ts [-w'..w' + 1]

        tiles : Maybe Texture -> [Entity]
        tiles texture = case texture of
            Just tex -> concatMap (\(r, y) -> row tex y r) <| zip grid (reverse [-h' - 1..h'])
            Nothing  -> []

        w'' = (toFloat w) * xScale |> round
        h'' = (toFloat h) * yScale |> round

    in  ((w'', h''), (tiles texture))

display : Signal GameModel.State -> Signal Element
display state = display' <~ state ~ texture

display' : GameModel.State -> Maybe Texture -> Element
display' state texture =
    let (dimensions, bg) = background state.level texture
        fog = fogger state.explored
    in  color black <| webgl dimensions (fog ++ bg)

-- Shaders

vertexShader : Shader { attr | position:Vec2, offset:Vec2, color:Vec4 } {unif | perspective:Mat4} { vcolor:Vec4 }
vertexShader = [glsl|

attribute vec2 position;
attribute vec2 offset;
attribute vec4 color;
uniform mat4 perspective;
varying vec4 vcolor;

void main () {
    vec2 stuff = (2.0 * offset) + position;
    gl_Position = perspective * vec4(stuff, 0.0, 1.0);
    vcolor = color;
}

|]

fragmentShader : Shader {} u { vcolor:Vec4 }
fragmentShader = [glsl|

precision mediump float;
varying vec4 vcolor;

void main () {
    gl_FragColor = vcolor;
}

|]

vertexShaderTex : Shader { attr | position:Vec2, offset:Vec2, color:Vec4, coord:Vec2 } {unif | perspective:Mat4} { vcolor:Vec4, vcoord:Vec2 }
vertexShaderTex = [glsl|

attribute vec2 position;
attribute vec2 offset;
attribute vec4 color;
attribute vec2 coord;
uniform mat4 perspective;
varying vec4 vcolor;
varying vec2 vcoord;

void main () {
    vec2 stuff = (2.0 * offset) + position;
    gl_Position = perspective * vec4(stuff, 0.0, 1.0);
    vcolor = color;
    vcoord = coord;
}

|]

fragmentShaderTex : Shader {} {unif | texture:Texture, sprite:Vec3} { vcolor:Vec4, vcoord:Vec2 }
fragmentShaderTex = [glsl|

precision mediump float;
uniform sampler2D texture;
uniform vec3 sprite;
varying vec4 vcolor;
varying vec2 vcoord;

void main () {
    vec2 spritecoord = vcoord + sprite.xy;
    vec2 coord = vec2(spritecoord.x, 16.0 - spritecoord.y) / 16.0;
    gl_FragColor = texture2D(texture, coord);
}

|]

-- Shape constructors

quad : Point -> Point -> Point -> Point -> Vec2 -> Vec4 -> [Triangle Vertex]
quad (x1, y1) (x2, y2) (x3, y3) (x4, y4) offset color =
    let topLeft     = Vertex (vec2 x1 y1) offset color (vec2 0 0)
        topRight    = Vertex (vec2 x2 y2) offset color (vec2 1 0)
        bottomLeft  = Vertex (vec2 x3 y3) offset color (vec2 0 1)
        bottomRight = Vertex (vec2 x4 y4) offset color (vec2 1 1)
    in  [ ( topLeft, topRight, bottomLeft)
        , ( bottomLeft, topRight, bottomRight)
        ]

fromRGB : Color -> Vec4
fromRGB color =
    let {red, green, blue, alpha} = toRgb color
        div x = toFloat x / 255
    in  vec4 (div red) (div green) (div blue) alpha
