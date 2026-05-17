extends Node
class_name Constants

static var dawn_provided := preload("res://data/stats/stat_dawn_given.tres")
static var wrath := preload("res://data/stats/stat_wrath.tres")
static var chip := preload("res://data/stats/stat_chip.tres")
static var defense := preload("res://data/stats/stat_defense.tres")

const TURNS_PER_SCORE = 3
const DEFAULT_HAND_SIZE = 5
const MAX_HAND_SIZE = 10

const EFFECT_COLOR_STRING = "#fbf5ef"

const MAX_RESOLUTIONS_BEFORE_GIVE_UP = 100

const TILE_OPTIONS_PER_TURN = 8
const TILE_OPTIONS_ALLOWED_SELECTIONS = 4
const CHOOSE_TILES_EACH_ROUND = false

static var START_DECK = [
  load("res://data/tiles/tile_basic_points.tres"),
  load("res://data/tiles/tile_basic_points.tres"),
  load("res://data/tiles/tile_basic_points.tres"),
  load("res://data/tiles/tile_basic_points.tres"),
  load("res://data/tiles/tile_basic_multiply_area.tres"),
  load("res://data/tiles/tile_lone_signal.tres"),
  load("res://data/tiles/destroy/tile_the_bomb.tres"),
  load("res://data/tiles/defense/tile_row_defense.tres"),
]

const START_MONEY = 6

const CARDINAL_DIRECTIONS = [
  Vector3i.LEFT,
  Vector3i.RIGHT,
  Vector3i.BACK,
  Vector3i.FORWARD,
]

const ALL_DIRECTIONS = [
  Vector3i.LEFT,
  Vector3i.RIGHT,
  Vector3i.BACK,
  Vector3i.FORWARD,
  Vector3i(1, 0, 1),
  Vector3i(-1, 0, 1),
  Vector3i(1, 0, -1),
  Vector3i(-1, 0, -1)
]

const EVENTS_PER_CYCLE = [
  1,
  2,
  4,
  4,
  6
]

const REQUIRED_SCORES = [
  60,
  300,
  1000,
  3000,
  5000
]

#const REQUIRED_SCORES = [
  #30,
  #150,
  #1000,
  #7500,
  #30000,
  #100000,
  #500000,
  #1500000,
  #3000000,
  #10000000
#]
