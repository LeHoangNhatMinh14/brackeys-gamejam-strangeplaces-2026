extends Node2D

enum DogState { IDLE, EXTEND, RETRACT }

@export var max_length: float = 220.0
@export var extend_speed: float = 700.0

@export var base_scale: float = 0.5

# Distances from player side (positive numbers)
@export var idle_gap: float = 50.0       # behind when idle
@export var extend_gap: float = 50.0     # in front when extending/retracting
@export var dog_y_offset: float = 0.0

# Platform collision
@export var platform_height: float = 14.0
@export var extra_down: float = 2.0
@export var solid_after: float = 20.0

# Visual stretch between Tail and Head
@export var cap_y: float = 0.0
@export var body_y: float = -13.0
@export var body_height: float = 16.0
@export var tail_cap_width: float = 32.0
@export var head_cap_width: float = 32.0

var player: Node2D = null
var state: int = DogState.IDLE
var current_length: float = 0.0

# Used to keep the head anchored during retract
var head_anchor_x: float = 0.0

@onready var visuals: Node2D = $Visuals
@onready var head: Node2D = $Visuals/Head
@onready var tail: Node2D = $Visuals/Tail
@onready var body: NinePatchRect = $Visuals/Body

@onready var colshape: CollisionShape2D = $PlatformArea/CollisionShape2D
var rect: RectangleShape2D = null

func _ready() -> void:
	player = get_parent() as Node2D

	if colshape.shape == null:
		colshape.shape = RectangleShape2D.new()
	rect = colshape.shape as RectangleShape2D
	colshape.disabled = true

	body.position.y = body_y
	body.size.y = body_height

func _process(delta: float) -> void:
	if player == null or rect == null:
		return

	var pressed: bool = Input.is_action_pressed("dog_extend")
	var facing: int = _get_player_facing()

	# keep default scale 0.5, only flip X
	visuals.scale = Vector2(base_scale * float(facing), base_scale)

	# state transitions
	if state == DogState.IDLE:
		if pressed:
			state = DogState.EXTEND
	elif state == DogState.EXTEND:
		if not pressed:
			# start retract: anchor the head where it currently is
			state = DogState.RETRACT
			head_anchor_x = current_length
	elif state == DogState.RETRACT:
		if pressed:
			# allow re-hold to extend again
			state = DogState.EXTEND

	# update length
	var target_len: float = 0.0
	if state == DogState.EXTEND:
		target_len = max_length
	elif state == DogState.RETRACT:
		target_len = 0.0
	else:
		target_len = 0.0

	current_length = move_toward(current_length, target_len, extend_speed * delta)

	# place dog relative to player
	_place_dog(facing)

	# update collision + visuals (depends on anchor)
	_update_platform_and_visuals()

	# finish retract -> go idle only after fully collapsed
	if state == DogState.RETRACT and current_length <= 0.5:
		state = DogState.IDLE
		colshape.disabled = true

func _place_dog(facing: int) -> void:
	var side_x: float = _get_player_side_x(facing)

	if state == DogState.IDLE:
		# behind player
		var idle_x: float = side_x - idle_gap * float(facing)
		position = Vector2(idle_x, dog_y_offset)
	else:
		# in front during extend + retract
		var active_x: float = side_x + extend_gap * float(facing)
		position = Vector2(active_x, dog_y_offset)

func _update_platform_and_visuals() -> void:
	# collision enable rule (avoid overlap pushback)
	colshape.disabled = (current_length < solid_after)

	rect.size = Vector2(current_length, platform_height)

	# Y align to player's feet line
	var feet_y: float = 0.0
	var pcol := player.get_node_or_null("CollisionShape2D")
	if pcol is CollisionShape2D and (pcol.shape is RectangleShape2D):
		var s := pcol.shape as RectangleShape2D
		feet_y = (s.size.y * 0.5) + extra_down
	colshape.position.y = feet_y + (platform_height * 0.5)

	if state == DogState.EXTEND:
		# TAIL anchored at x=0, HEAD moves forward
		tail.position = Vector2(0.0, cap_y)
		head.position = Vector2(current_length, cap_y)

		# platform extends forward from tail
		colshape.position.x = current_length * 0.5

		# body between tail and head
		_stretch_body_between(tail_cap_width, current_length - head_cap_width)

	elif state == DogState.RETRACT:
		# HEAD anchored at head_anchor_x, TAIL moves toward it
		head.position = Vector2(head_anchor_x, cap_y)
		tail.position = Vector2(head_anchor_x - current_length, cap_y)

		# platform shrinks toward head (extends backward from head)
		colshape.position.x = head_anchor_x - current_length * 0.5

		# body between tail and head
		var start_x: float = (head_anchor_x - current_length) + tail_cap_width
		var end_x: float = head_anchor_x - head_cap_width
		_stretch_body_between(start_x, end_x)

	else:
		# IDLE: keep it compact
		current_length = 0.0
		tail.position = Vector2(0.0, cap_y)
		head.position = Vector2(0.0, cap_y)
		body.size.x = 0.0
		colshape.disabled = true

func _stretch_body_between(start_x: float, end_x: float) -> void:
	var mid_len: float = max(0.0, end_x - start_x)
	body.position.x = start_x
	body.size.x = mid_len

func _get_player_side_x(facing: int) -> float:
	var pcol := player.get_node_or_null("CollisionShape2D")
	if pcol is CollisionShape2D and (pcol.shape is RectangleShape2D):
		var s := pcol.shape as RectangleShape2D
		return (s.size.x * 0.5) * float(facing)
	return 0.0

func _get_player_facing() -> int:
	if player != null and player.has_method("get_facing_dir"):
		return int(player.call("get_facing_dir"))
	return 1
