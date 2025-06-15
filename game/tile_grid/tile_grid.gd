@tool
class_name TileGrid
extends Node2D

@export var bg_tile_scene: PackedScene
@export var rows: int = 5:
	set(value):
		rows = value
		_create_grid() # Recreate the grid when rows change
@export var columns: int = 5:
	set(value):
		columns = value
		_create_grid() # Recreate the grid when columns change
@export var tile_size: float = 100.0:
	set(value):
		tile_size = value
		_create_grid() # Recreate the grid when tile size changes
@export var row_y_offset: float = 0.0:
	set(value):
		row_y_offset = value
		_create_grid() # Recreate the grid when row_y_offset changes


var tiles: Array = []

func _ready():
	_create_grid()

func _create_grid():
	# Clear existing tiles
	for tile in tiles:
		tile.free()
	tiles.clear()

	# Determine actual grid dimensions
	var max_columns = columns
	if rows > 1:
		max_columns += 0.5 # account for staggered row
	var grid_width = max_columns * tile_size
	var grid_height = rows * tile_size + (row_y_offset * (rows - 1))

	var offset_x = grid_width / 2.0
	var offset_y = grid_height / 2.0

	# Create new grid of tiles
	for row in range(rows):
		for column in range(columns):
			var f_column = float(column)
			if row % 2 == 1:
				f_column += 0.5
			var pos_x = f_column * tile_size
			var pos_y = row * tile_size + (row_y_offset * row)
			var tile = bg_tile_scene.instantiate()
			tile.position = Vector2(pos_x - offset_x, pos_y - offset_y)
			add_child(tile)
			tiles.append(tile)
