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
		else:
			_unselect_tiles() # Unselect all tiles if clicked outside
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_P:
			_create_pyramid()
		if event.keycode == KEY_ESCAPE:
			_unselect_tiles()
			var t1 = Tile.MTileData.new(5, Tile.Operation.ADD)
			var t2 = Tile.MTileData.new(3, Tile.Operation.SUBTRACT)
			var t3 = Tile.MTileData.new(2, Tile.Operation.MULTIPLY)
			var triplet = _find_valid_triplet(10)
			if not triplet.is_empty():
				# print("%s %s %s" % [triplet[0], triplet[1], triplet[2]])
				pass
			else:
				print("No valid triplet found")


func _find_valid_triplet(target: int) -> Array[Tile.MTileData]:
	var attempts = 500
	while attempts > 0:
		var a = randi_range(1, 9)
		var b = randi_range(1, 9)
		var c = randi_range(1, 9)
		var op1 = randi_range(0, 3) as Tile.Operation
		var op2 = randi_range(0, 3) as Tile.Operation
		var tile1 = Tile.MTileData.new(a, op1)
		var tile2 = Tile.MTileData.new(b, op2)
		var tile3 = Tile.MTileData.new(c, Tile.Operation.ADD) # Always add the third tile
		var tiles = [tile1, tile2, tile3] as Array[Tile.MTileData]
		var result = _evaluate_tiles(tiles)
		if result == target:
			print("[%s] Found valid triplet: %s %s %s" % [attempts, tile1, tile2, tile3])
			return tiles

		attempts -= 1
	return []


func _validate_selection(tile: Tile) -> bool:
	if selected_tiles.is_empty():
		return true
	var last_tile = selected_tiles[selected_tiles.size() - 1]
	# ensure the new tile is a neighbor of the last selected tile
	for hex_dir in last_tile.neighbors.keys():
		if last_tile.neighbors[hex_dir] == tile:
			return true
	return false


func _select_tile(tile: Tile):
	print("Select Tile: %s" % tile.data)
	for hex_dir in tile.neighbors.keys():
		var neighbor = tile.neighbors[hex_dir]
		var hex_dir_str = Tile.HEX_DIR.keys()[hex_dir]
		print("Neighbor (%s): %s" % [hex_dir_str, neighbor.data])
	
	if not _validate_selection(tile):
		print("Invalid selection: %s is not a neighbor of the last selected tile." % tile.data)
		_unselect_tiles()
		_select_tile(tile) # Re-select the tile to reset selection
		return

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


func _unselect_tiles():
	for tile in selected_tiles:
		tile.is_selected = false
		tile.disabled = false
	selected_tiles.clear()


func _tiles_to_tile_data(_tiles: Array[Tile]) -> Array[Tile.MTileData]:
	var tile_data := [] as Array[Tile.MTileData]
	for tile in _tiles:
		tile_data.append(tile.data)
	return tile_data


func _create_tile(value: int, operation: Tile.Operation) -> Tile:
	var tile = tile_scene.instantiate() as Tile
	tile.data = Tile.MTileData.new(value, operation)
	tile.position = Vector2.ZERO # Default position, can be adjusted later
	add_child(tile)
	return tile


func _submit_equation():
	if selected_tiles.size() < 2:
		return # Not enough tiles selected

	for tile in tiles:
		tile.collider.disabled = true

	var tile_data = _tiles_to_tile_data(selected_tiles)
	var result = _evaluate_tiles(tile_data)
	var equation_str = _get_equation_string(tile_data)
	print("Equation: %s = %s" % [equation_str, result])

	await G.wait(0.5)

	for tile in tiles:
		tile.is_selected = false
		tile.disabled = false
	selected_tiles.clear() # Clear selection after submission


func _evaluate_tiles(tiles: Array[Tile.MTileData]) -> float:
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


func _get_equation_string(_tiles: Array[Tile.MTileData]) -> String:
	var first_value = _tiles[0].value
	if _tiles[0].operation == Tile.Operation.SUBTRACT:
		first_value = - first_value # Adjust first value for subtraction
	var s := str(first_value)
	for i in range(1, _tiles.size()):
		s += " %s %s" % [Tile.operation_str(_tiles[i].operation), str(_tiles[i].value)]
	return s


func _set_tile_values():
	for tile in tiles:
		var value = randi_range(1, 10)
		var operation = randi_range(0, Tile.Operation.size() - 1) as Tile.Operation
		var data = Tile.MTileData.new(value, operation)
		tile.data = data


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


	_build_neighbors()
	_set_tile_values()
	_animate_tiles_enter()


func _build_neighbors():
	for tile in tiles:
		tile.neighbors.clear() # Clear existing neighbors
		var pos = tile.position
		for other in tiles:
			if tile == other:
				continue
			var other_pos = other.position
			if pos.distance_to(other_pos) <= tile_size * 1.5: # Adjust distance threshold as needed
				var dir = pos.direction_to(other_pos)
				var hex_dir = Tile.get_closest_hex_dir(dir)
				if tile.neighbors.has(hex_dir):
					continue # Already has a neighbor in this direction
				else:
					tile.neighbors[hex_dir] = other
					other.neighbors[Tile.invert_hex_dir(hex_dir)] = tile # Ensure bidirectional relationship
