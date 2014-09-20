module Main where

import Keyboard
import String
import Text

import Grid
import Generator
import Generator.Standard

import GameModel
import GameUpdate
import GameView

port title : String
port title = "Chimera"

seed : Int
seed = 2014

gen : Generator.Generator Generator.Standard.Standard
gen = Generator.Standard.generator seed

initialLevel : Grid.Grid GameModel.Tile
initialLevel =
    let toTile c = case c of
                        ' ' -> GameModel.Floor
                        '#' -> GameModel.Wall
                        '+' -> GameModel.Door
                        '~' -> GameModel.Acid
        s = [ "####################"
            , "#        #         #"
            , "#        #         #"
            , "#                  #"
            , "#        #         #"
            , "#        #         #"
            , "####################"
            ]
    in  Grid.fromList <| map (\x -> map toTile <| String.toList x) s

initialExplored : Grid.Grid GameModel.Visibility
initialExplored =
    let grid = Grid.toList initialLevel
    in  map (\row -> map (\_ -> GameModel.Unexplored) row) grid |> Grid.fromList

initialPlayer : GameModel.Player
initialPlayer =
    "@"
        |> toText
        |> monospace
        |> Text.color white
        |> centered
        |> GameModel.player

initalEnemy : GameModel.Enemy
initalEnemy =
    "e"
        |> toText
        |> monospace
        |> Text.color white
        |> centered
        |> GameModel.enemy

initialState : GameModel.State
initialState = GameUpdate.reveal <| GameModel.State initialPlayer [initalEnemy] initialLevel initialExplored ["you enter the dungeon"] gen

inputs : Signal GameModel.Input
inputs = GameModel.handle <~ Keyboard.lastPressed

state : Signal GameModel.State
state = foldp GameUpdate.update initialState inputs

main : Signal Element
main = GameView.display <~ state
