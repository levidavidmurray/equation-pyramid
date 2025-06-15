@tool
class_name Pyramid
extends Node2D

@export var tile_scene: PackedScene
@export var tile_size: float = 100.0:
	set(value):
		tile_size = value
		_create_pyramid() # Recreate the pyramid when tile size changes

@export var base_size: int = 5

var tile_dict: Dictionary[String, Tile] = {}

var tiles: Array[Tile] = []
var selected_tiles: Array[Tile] = []
var hovered_tile: Tile

func _ready():
	_create_pyramid()


func _process(_delta):
	var has_hovered_tile = false
	for tile in tiles:
		if tile.is_hovered:
			hovered_tile = tile
			has_hovered_tile = true
			break
	if not has_hovered_tile:
		hovered_tile = null


func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if hovered_tile:
			if hovered_tile.is_selected:
				_unselect_tile(hovered_tile)
			else:
				_select_tile(hovered_tile)
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_P:
			_create_pyramid()


func _select_tile(tile: Tile):
	if not tile in selected_tiles:
		tile.is_selected = true
		selected_tiles.append(tile)
		AudioManager.play_stream(tile.sfx_hover, -10.0, 1.2)
		if selected_tiles.size() >= 3:
			_submit_equation() # Submit the equation if 3 or more tiles are selected


func _unselect_tile(tile: Tile):
	if tile in selected_tiles:
		tile.is_selected = false
		selected_tiles.erase(tile)
		AudioManager.play_stream(tile.sfx_hover, -10.0, 0.8)


func _submit_equation():
	if selected_tiles.size() < 2:
		return # Not enough tiles selected

	for tile in selected_tiles:
		tile.collider.disabled = true

	var equation_str = _get_equation_string(selected_tiles)
	var result = _evaluate_tiles_md_as(selected_tiles)
	print("Equation: %s = %s" % [equation_str, result])

	await G.wait(0.5)

	for tile in selected_tiles:
		tile.is_selected = false
		tile.disabled = false
	selected_tiles.clear() # Clear selection after submission


func _evaluate_tiles_md_as(tiles: Array[Tile]) -> float:
	var first_value = tiles[0].value
	if tiles[0].operation == Tile.Operation.SUBTRACT:
		first_value = - first_value # Adjust first value for subtraction
	var values := [first_value]
	var ops := []

	for i in range(1, tiles.size()):
		ops.append(tiles[i].operation)
		values.append(float(tiles[i].value))

	# First pass: handle * and /
	var i := 0
	while i < ops.size():
		if ops[i] == Tile.Operation.MULTIPLY:
			values[i] = values[i] * values[i + 1]
			values.remove_at(i + 1)
			ops.remove_at(i)
		elif ops[i] == Tile.Operation.DIVIDE:
			if values[i + 1] == 0:
				print("Divide by zero!")
				return 0
			values[i] = values[i] / values[i + 1]
			values.remove_at(i + 1)
			ops.remove_at(i)
		else:
			i += 1

	# Second pass: handle + and -
	i = 0
	while i < ops.size():
		if ops[i] == Tile.Operation.ADD:
			values[i] = values[i] + values[i + 1]
		elif ops[i] == Tile.Operation.SUBTRACT:
			values[i] = values[i] - values[i + 1]
		values.remove_at(i + 1)
		ops.remove_at(i)

	return values[0]


func _get_equation_string(tiles: Array[Tile]) -> String:
	var first_value = tiles[0].value
	if tiles[0].operation == Tile.Operation.SUBTRACT:
		first_value = - first_value # Adjust first value for subtraction
	var str := str(first_value)
	for i in range(1, tiles.size()):
		str += " %s %s" % [Tile.operation_str(tiles[i].operation), str(tiles[i].value)]
	return str


func _set_tile_values():
	for tile in tiles:
		var operation = randi_range(0, Tile.Operation.size() - 1) as Tile.Operation
		var value = randi_range(1, 10)
		tile.operation = operation
		tile.value = value


func _animate_tiles_enter():
	var tween = create_tween()
	tween.set_parallel()
	tween.set_trans(Tween.TRANS_SINE)

	for i in range(tiles.size()):
		var tile = tiles[i]
		tile.disabled = true
		tile.scale = Vector2.ONE * 1.5
		tile.modulate.a = 0.0
		var delay = 0.05 * i
		var time = 0.25
		var orig_pos = tile.get_meta("orig_pos", tile.position)
		tween.tween_property(tile, "scale", Vector2.ONE * 0.9, time).set_delay(delay)
		tween.tween_property(tile, "modulate:a", 1.0, time).set_delay(delay)
		tween.tween_property(tile, "scale", Vector2.ONE, time).set_delay(delay + time)
		# tween.tween_property(tile, "position", orig_pos + Vector2(0, 100.0), 0.15).set_delay(delay)
		# tween.tween_property(tile, "position", orig_pos, time).set_delay(delay + 0.15)

	await G.wait(1.0)

	for tile in tiles:
		tile.disabled = false


func _create_pyramid():
	if not is_inside_tree():
		return
	for tile in tiles:
		if is_instance_valid(tile):
			tile.queue_free()
	tiles.clear()

	var vertical_spacing = tile_size * 0.866
	var start_y = - (base_size - 1) * vertical_spacing / 2.0

	var letter_index := 0
	for y in range(base_size):
		var row_width = y + 1
		for x in range(row_width):
			var tile = tile_scene.instantiate() as Tile
			var offset = (row_width - 1) / 2.0
			var pos_x = (x - offset) * tile_size
			var pos_y = start_y + y * vertical_spacing
			tile.position = Vector2(pos_x, pos_y)
			add_child(tile)
			tile.is_selected = false
			tile.disabled = true
			tile.set_meta("orig_pos", tile.position)

			var badge_letter = G.ALPHABET[letter_index % G.ALPHABET.size()]
			tile.badge_label.text = badge_letter
			tile_dict[badge_letter] = tile
			letter_index += 1

			tiles.append(tile)


	_set_tile_values()
	_animate_tiles_enter()
