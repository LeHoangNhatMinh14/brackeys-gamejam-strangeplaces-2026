extends Node2D

@export var max_length := 220.0
@export var extend_speed := 700.0
@export var platform_height := 18.0
@export var extra_down := 2.0

var player: Node2D
var extending := false
var was_extending := false
var current_length := 0.0
var placed_facing := 1

@onready var platform_area: StaticBody2D = $PlatformArea
@onready var colshape: CollisionShape2D = $PlatformArea/CollisionShape2D
@onready var rect: RectangleShape2D = colshape.shape as RectangleShape2D

var original_parent: Node = null

func _ready() -> void:
	original_parent = platform_area.get_parent()
	# start disabled
	colshape.disabled = true

func set_extending(v: bool) -> void:
	extending = v

func _process(delta: float) -> void:
	if player == null:
		return

	# Detect start of extend (button just pressed)
	if extending and not was_extending:
		placed_facing = _get_player_facing()
		_place_platform_once(placed_facing)

	# Detect end of extend (button released)
	if not extending and was_extending:
		# Optional: keep platform where it is and retract away in place
		# (If you want it to instantly disappear instead, call _unplace_platform())
		pass

	was_extending = extending

	# Extend/retract length (platform stays where it was placed)
	if extending:
		current_length = move_toward(current_length, max_length, extend_speed * delta)
	else:
		current_length = move_toward(current_length, 0.0, extend_speed * delta)

	_update_platform(placed_facing)

	# When fully retracted, disable collision and (optionally) return under the dog
	if current_length <= 0.5 and not extending:
		colshape.disabled = true
		# If you want it to “go back to the dog” when not used:
		_unplace_platform()

func _place_platform_once(facing: int) -> void:
	# Move PlatformArea OUT of the player tree so it stops following the player
	var scene_root := get_tree().current_scene
	if platform_area.get_parent() != scene_root:
		platform_area.get_parent().remove_child(platform_area)
		scene_root.add_child(platform_area)

	# Place at player's feet (RectangleShape2D assumed)
	var player_col := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if player_col != null and player_col.shape is RectangleShape2D:
		var s := player_col.shape as RectangleShape2D
		var bottom_y := player.global_position.y + (s.size.y * 0.5) + extra_down
		platform_area.global_position = Vector2(player.global_position.x, bottom_y)
	else:
		platform_area.global_position = player.global_position

	colshape.disabled = false

func _unplace_platform() -> void:
	# Put PlatformArea back under PDwag (optional)
	if original_parent == null:
		return
	if platform_area.get_parent() != original_parent:
		platform_area.get_parent().remove_child(platform_area)
		original_parent.add_child(platform_area)
	platform_area.position = Vector2.ZERO  # reset local position under PDwag

func _update_platform(facing: int) -> void:
	colshape.disabled = current_length <= 4.0
	rect.size = Vector2(current_length, platform_height)
	colshape.position = Vector2((current_length * 0.5) * facing, platform_height * 0.5)

func _get_player_facing() -> int:
	if player != null and player.has_method("get_facing_dir"):
		return int(player.call("get_facing_dir"))
	return -1 if player != null and player.scale.x < 0.0 else 1
