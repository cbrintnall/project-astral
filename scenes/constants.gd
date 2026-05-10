extends Node
class_name Constants

static var dawn_provided := preload("res://data/stats/stat_dawn_given.tres")
static var wrath := preload("res://data/stats/stat_wrath.tres")

const TURNS_PER_SCORE = 4
const DEFAULT_HAND_SIZE = 5
const MAX_HAND_SIZE = 10

static var START_DECK = [
  load("res://data/tiles/tile_basic_points.tres"),
  load("res://data/tiles/tile_basic_points.tres"),
  load("res://data/tiles/tile_basic_points.tres"),
  load("res://data/tiles/tile_basic_points.tres"),
  load("res://data/tiles/tile_basic_points.tres"),
  load("res://data/tiles/tile_basic_multiply_area.tres"),
  load("res://data/tiles/tile_basic_points_no_neighbors.tres"),
  load("res://data/tiles/tile_basic_points_no_neighbors.tres"),
  load("res://data/tiles/tile_basic_points_no_neighbors.tres"),
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

const REQUIRED_SCORES = [
  30,
  150,
  1000,
  7500,
  30000,
  100000,
  500000,
  1500000,
  3000000,
  10000000
]

static var ENEMY_TILES = [
  load("res://data/tiles/enemy/tile_enemy_chaotic_wrath.tres"),
  load("res://data/tiles/enemy/tile_basic_enemy.tres")
]
