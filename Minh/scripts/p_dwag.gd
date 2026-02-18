extends CharacterBody2D

@export var follow_distance := 32.0
@export var follow_height := 0.0
@export var follow_speed := 260.0
@export var follow_deadzone := 10.0

@export var max_length := 220.0
@export var extend_speed := 700.0
@export var platform_height := 18.0
@export var platform_y_offset := 0.0 # adjust to match ground line

var player: Node2D
var extending := false
var current_length := 0.0

@onready var visual: Node2D = $Visual
@onready var head: Sprite2D = $Visual/Head
@onready var body: NinePatchRect = $Visual/Body
@onready var butt: Sprite2D = $Visual/Butt

@onready var platform_body: StaticBody2D = $PlatformBody
@onready var colshape: CollisionShape2D = $PlatformBody/CollisionShape2D
@onready var rect: RectangleShape2D = colshape.shape

func set_extending(v: bool) -> void:
	extending = v

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var facing := _get_player_facing()

	if extending:
		# stick near player while extending
		global_position = player.global_position + Vector2(0, platform_y_offset)
		velocity = Vector2.ZERO

		current_length = move_toward(current_length, max_length, extend_speed * delta)
		_update_platform(facing)
		_update_visual(facing)
		return

	# Not extending: retract and follow
	current_length = move_toward(current_length, 0.0, extend_speed * delta)
	_update_platform(facing)
	_update_visual(facing)

	var target = player.global_position + Vector2(-facing * follow_distance, follow_height)
	var to_target = target - global_position

	if to_target.length() <= follow_deadzone:
		velocity = velocity.move_toward(Vector2.ZERO, follow_speed * delta)
	else:
		velocity = to_target.normalized() * follow_speed

	move_and_slide()

func _update_platform(facing: int) -> void:
	colshape.disabled = current_length <= 4.0
	rect.size = Vector2(current_length, platform_height)
	# center the rectangle halfway along its length
	colshape.position = Vector2((current_length * 0.5) * facing, 0)

func _update_visual(facing: int) -> void:
	# flip all visuals with container
	visual.scale.x = facing

	head.position = Vector2(0, 0)
	butt.position = Vector2(current_length, 0)

	# Body spans between head and butt
	var head_w = head.texture.get_width() if head.texture else 0
	var butt_w = butt.texture.get_width() if butt.texture else 0

	var start_x = head_w * 0.5
	var end_pad = butt_w * 0.5
	var mid_len = max(0.0, current_length - start_x - end_pad)

	body.position = Vector2(start_x, body.position.y)
	body.size.x = mid_len

func _get_player_facing() -> int:
	# Best: player has a variable facing_dir = -1/+1
	if player.has_method("get_facing_dir"):
		return player.call("get_facing_dir")
	# Fallback: use player scale.x
	return -1 if player.scale.x < 0.0 else 1
