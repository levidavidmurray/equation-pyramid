@tool
class_name Tile
extends Area2D

enum Operation {
	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE
}

class MTileData:
	var value: int
	var operation: Operation

	func _init(_value: int, _operation: Operation):
		value = _value
		operation = _operation

	func _to_string():
		return "%s%s" % [Tile.operation_str(operation), str(value)]


@export var value: int = 0:
	set(_value):
		value = _value
		_update_label()

@export var operation: Operation = Operation.ADD:
	set(_value):
		operation = _value
		_update_label()


@export var sfx_hover: AudioStream

@export_category("Colors")
@export_category("Sprite")
@export var base_sprite_color: Color = Color.WHITE
@export var hover_sprite_color: Color = Color.BLACK
@export var selected_sprite_color: Color = Color.WHITE
@export_category("Frame")
@export var base_frame_color: Color = Color.WHITE
@export var hovered_frame_color: Color = Color.WHITE
@export var selected_frame_color: Color = Color.WHITE
@export_category("Label")
@export var base_label_color: Color = Color.BLACK
@export var hover_label_color: Color = Color.WHITE
@export var selected_label_color: Color = Color.BLACK
@export_category("Badge")
@export var base_badge_color: Color = Color.BLACK
@export var hovered_badge_color: Color = Color.WHITE
@export var selected_badge_color: Color = Color.WHITE

@onready var sprite_tile: Sprite2D = $SpriteTile
@onready var frame: Node2D = $Frame
@onready var sprite_frame: Sprite2D = %SpriteFrame
@onready var sprite_badge: Sprite2D = %SpriteBadge
@onready var value_label: Label = $ValueLabel
@onready var badge_label: Label = $BadgeLabel
@onready var collider: CollisionPolygon2D = $CollisionPolygon2D

@export var is_selected: bool = false:
	set(value):
		is_selected = value

@export var is_hovered: bool = false:
	set(value):
		is_hovered = value

var data: MTileData:
	set(value):
		data = value
		_update_label()

var disabled = false:
	set(value):
		disabled = value
		if collider:
			collider.disabled = value

var tween: Tween

var target_scale: Vector2
var target_sprite_color: Color
var target_label_color: Color
var target_frame_color: Color
var target_badge_color: Color

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_update_label()
	collider.disabled = disabled


func _process(delta):
	if not disabled:
		_set_visual_targets()
		sprite_tile.modulate = lerp(sprite_tile.modulate, target_sprite_color, delta * 10.0)
		value_label.modulate = lerp(value_label.modulate, target_label_color, delta * 10.0)
		frame.modulate = lerp(frame.modulate, target_frame_color, delta * 10.0)
		badge_label.modulate = lerp(badge_label.modulate, target_badge_color, delta * 10.0)
		scale = lerp(scale, target_scale, delta * 10.0)


func _set_visual_targets():
	if is_selected:
		target_sprite_color = selected_sprite_color
		target_label_color = selected_label_color
		target_scale = Vector2.ONE * 0.96
		target_frame_color = selected_frame_color
		target_badge_color = selected_badge_color
	elif is_hovered:
		target_sprite_color = hover_sprite_color
		target_label_color = hover_label_color
		target_scale = Vector2.ONE * 0.98
		target_frame_color = hovered_frame_color
		target_badge_color = hovered_badge_color
	else:
		target_sprite_color = base_sprite_color
		target_label_color = base_label_color
		target_scale = Vector2.ONE
		target_frame_color = base_frame_color
		target_badge_color = base_badge_color


func _update_label():
	if not is_inside_tree():
		return
	if not data:
		value_label.hide()
	else:
		value_label.show()
		value_label.text = str(data)


static func operation_str(_operation) -> String:
	match _operation:
		Operation.ADD:
			return "+"
		Operation.SUBTRACT:
			return "−"
		Operation.MULTIPLY:
			return "×"
		Operation.DIVIDE:
			return "÷"
		_:
			return "?"


func _on_mouse_entered():
	is_hovered = true
	if not is_selected:
		AudioManager.play_stream(sfx_hover, -20.0, 0.9)


func _on_mouse_exited():
	is_hovered = false
