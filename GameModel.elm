module GameModel where

import Char (KeyCode)

import Grid
import Generator
import Generator.Standard

type State = { player : Player
             , enemies : [Enemy]
             , level : Grid.Grid Tile
             , explored : Grid.Grid Visibility
             , log : [String]
             , generator : Random
             }

type Player = { location : Location
              , avatar : Element
              , name : String
              , health : Int
              , energy : Int
              , hunger : Int
              , stealth : Int
              , armor : Int
              , protection : Int
              , coordination : Int
              , power : Int
              , initiative : Int
              , placed : Bool
              }

type Enemy = { location : Location
             , avatar : Element
             , name : String
             , health : Int
             , stealth : Int
             , armor : Int
             , protection : Int
             , coordination : Int
             , power : Int
             , initiative : Int
             , placed : Bool
             }

type Location = Grid.Coordinate
data Tile = Floor
          | Wall
          | Door
          | Acid
data Visibility = Visible
                | Unexplored
                | Explored

data Input = Up | Down | Left | Right | Nop

type Random = Generator.Generator Generator.Standard.Standard

player : Element -> String -> Random -> (Player, Random)
player elem name gen =
    let (initiative, gen') = Generator.int32Range (1, 100) gen
    in  (Player (Grid.Coordinate 2 2) elem name 10 10 10 20 1 50 100 2 initiative False, gen')

enemy : Element -> String -> Random -> (Enemy, Random)
enemy elem name gen = 
    let (initiative, gen') = Generator.int32Range (1, 100) gen
    in  (Enemy (Grid.Coordinate 14 4) elem name 10 20 1 50 100 2 initiative False, gen')

location : Int -> Int -> Location
location = Grid.Coordinate

handle : KeyCode -> Input
handle key =
    case key of
        37 -> Left
        38 -> Up
        39 -> Right
        40 -> Down
        _  -> Nop

validLocation : Location -> State -> Bool
validLocation location state = Grid.inGrid location state.level

pathable : Location -> State -> Bool
pathable location state =
    let level = state.level
        tile  = Grid.get location level
    in  case tile of
            Nothing -> False
            Just Floor  -> True
            Just _  -> False

getRandomPathable : State -> (Location, State)
getRandomPathable state = 
  let (x, gen') = Generator.int32Range (1, state.level.size.width) state.generator
      (y, gen'') = Generator.int32Range (1, state.level.size.height) gen'
      locn = location x y
      state' = {state | generator <- gen''}
  in  case pathable locn state' of
          True -> (locn, state')
          False -> getRandomPathable state'

placeEnemy : Enemy -> State -> State
placeEnemy a state = 
  let (loc, state') = getRandomPathable state
  in  {state'| enemies <- {a| location <- loc, placed <- True} :: tail state'.enemies}

placePlayer : State -> State
placePlayer state = 
  let (loc, state') = getRandomPathable state
      player' = state'.player
  in  {state'| player <- {player'| location <- loc, placed <- True}}

showTile : Tile -> Element
showTile tile =
    let c = case tile of
                Floor -> " "
                Wall  -> "#"
                Door  -> "+"
                Acid  -> "~"
    in  centered << monospace << toText <| c

visible : State -> [Location]
visible state = Grid.neighborhood2 state.player.location

visibility : State -> Location -> Visibility
visibility state location = Grid.getOrElse Unexplored location state.explored
