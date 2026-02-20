extends Node2D

enum DogState { IDLE, MOVE_FRONT, EXTEND, RETRACT, MOVE_BACK }

@export var max_length: float = 220.0
@export var extend_speed: float = 700.0
@export var reposition_speed: float = 900.0
@export var base_scale: float = 0.5

@export var cooldown_time: float = 2.0 # seconds before it can extend again
var cooldown_timer: float = 0.0

# Max time the player can keep the platform out (0 or less = unlimited)
@export var max_hold_time: float = 5.0
var hold_timer: float = 0.0

# Placement relative to player (positive numbers)
@export var idle_gap: float = 50.0
@export var extend_gap: float = 50.0
@export var dog_y_offset: float = 0.0
@export var snap_epsilon: float = 1.0

# Bridge feel
@export var bridge_drop_y: float = 6.0
@export var platform_height: float = 14.0
@export var platform_width_pad: float = 8.0
@export var extra_down: float = 2.0
@export var solid_after: float = 20.0

# Visual alignment
@export var cap_y: float = 0.0
@export var body_y: float = -13.0
@export var body_height: float = 16.0

# Align endpoints to art (small numbers)
@export var butt_offset: float = 0.0
@export var snout_offset: float = 0.0

# Visual trims
@export var body_trim_start: float = 0.0
@export var body_trim_end: float = 0.0

var player: Node2D
var state: int = DogState.IDLE

var current_length: float = 10.0
var end_anchor_x: float = 0.0
var facing_dir: int = 1
var retract_start_len: float = 0.0

# Detaching
var detached: bool = false
var original_parent: Node = null
var detach_parent: Node = null
var saved_global_pos: Vector2 = Vector2.ZERO

@onready var visuals: Node2D = $Visuals
@onready var head: Node2D = $Visuals/Head
@onready var tail: Node2D = $Visuals/Tail
@onready var body: Sprite2D = $Visuals/Body

@onready var platform_area: StaticBody2D = $PlatformArea
@onready var colshape: CollisionShape2D = $PlatformArea/CollisionShape2D
var rect: RectangleShape2D

# Authored idle pose
var idle_head_pos: Vector2
var idle_tail_pos: Vector2
var idle_body_pos: Vector2
var idle_body_visible: bool = true
var idle_body_region: Rect2

func _ready() -> void:
	player = get_parent() as Node2D

	idle_head_pos = head.position
	idle_tail_pos = tail.position
	idle_body_pos = body.position
	idle_body_visible = body.visible

	body.region_enabled = true
	idle_body_region = body.region_rect

	if not (colshape.shape is RectangleShape2D):
		colshape.shape = RectangleShape2D.new()
	rect = colshape.shape as RectangleShape2D
	colshape.disabled = true

func _process(delta: float) -> void:
	if player == null:
		return

	_tick_cooldown(delta)

	var pressed: bool = Input.is_action_pressed("dog_extend")

	# Only refresh facing when attached (so detached bridge keeps orientation)
	if not detached and state in [DogState.IDLE, DogState.MOVE_FRONT, DogState.MOVE_BACK]:
		var f: int = _get_player_facing()
		facing_dir = -1 if f < 0 else 1

	# Flip + scale visuals
	visuals.scale = Vector2(base_scale * float(facing_dir), base_scale)

	# Flip + scale platform too (so local +X is always "forward")
	platform_area.scale = Vector2(base_scale * float(facing_dir), base_scale)

	# Player-local positions (only valid while attached)
	var side_x: float = _get_player_side_x(facing_dir)
	var x_idle: float = side_x - idle_gap * float(facing_dir)
	var x_front: float = side_x + extend_gap * float(facing_dir)

	match state:
		DogState.IDLE:
			_state_idle(pressed, x_idle)
		DogState.MOVE_FRONT:
			_state_move_front(delta, pressed, x_front)
		DogState.EXTEND:
			_state_extend(delta, pressed)
		DogState.RETRACT:
			_state_retract(delta)
		DogState.MOVE_BACK:
			_state_move_back(delta, pressed, x_idle)

# ---------------- State handlers ----------------

func _state_idle(pressed: bool, x_idle: float) -> void:
	_restore_idle_pose()
	colshape.disabled = true
	current_length = 0.0

	# Ensure attached in idle
	if detached:
		_reattach_to_player()

	position = Vector2(x_idle, dog_y_offset)

	# COOLDOWN GATE
	if pressed and cooldown_timer <= 0.0:
		state = DogState.MOVE_FRONT

func _state_move_front(delta: float, pressed: bool, x_front: float) -> void:
	_restore_idle_pose()
	colshape.disabled = true

	position.x = move_toward(position.x, x_front, reposition_speed * delta)
	position.y = dog_y_offset

	if not pressed:
		state = DogState.MOVE_BACK
		return

	if abs(position.x - x_front) <= snap_epsilon:
		position.x = x_front
		position.y = dog_y_offset + bridge_drop_y

		_detach_to_world()

		# Start hold limit as soon as we enter EXTEND
		hold_timer = max_hold_time

		state = DogState.EXTEND

func _state_extend(delta: float, pressed: bool) -> void:
	# Enforce hold limit (0 or less = unlimited)
	if max_hold_time > 0.0:
		hold_timer -= delta
		if hold_timer <= 0.0:
			hold_timer = 0.0
			pressed = false # force retract

	# Detached: do not move position.
	var target_len: float = max_length if pressed else 0.0
	current_length = move_toward(current_length, target_len, extend_speed * delta)
	_apply_extend()

	# Retract either on release OR when hold expires
	if not pressed:
		retract_start_len = clamp(current_length, 0.0, max_length)
		current_length = retract_start_len
		end_anchor_x = (_start_x() + retract_start_len) - snout_offset

		state = DogState.RETRACT
		_apply_retract()

func _state_retract(delta: float) -> void:
	current_length = move_toward(current_length, 0.0, extend_speed * delta)
	_apply_retract()

	if current_length <= 0.5:
		current_length = 0.0
		colshape.disabled = true
		body.visible = false

		_reattach_to_player()

		# START COOLDOWN AFTER RETRACT FINISHES
		cooldown_timer = cooldown_time

		state = DogState.MOVE_BACK

func _state_move_back(delta: float, pressed: bool, x_idle: float) -> void:
	_restore_idle_pose()
	colshape.disabled = true

	position.x = move_toward(position.x, x_idle, reposition_speed * delta)
	position.y = dog_y_offset

	# COOLDOWN GATE
	if pressed and cooldown_timer <= 0.0:
		state = DogState.MOVE_FRONT
		return

	if abs(position.x - x_idle) <= snap_epsilon:
		position.x = x_idle
		state = DogState.IDLE

# ---------------- Timers ----------------

func _tick_cooldown(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		if cooldown_timer < 0.0:
			cooldown_timer = 0.0

func get_cooldown_ratio() -> float:
	if cooldown_time <= 0.0:
		return 0.0
	return clamp(cooldown_timer / cooldown_time, 0.0, 1.0)

# ---------------- Detach / Reattach ----------------

func _detach_to_world() -> void:
	if detached:
		return

	original_parent = get_parent()

	# Prefer player's parent (level/world) as stable detach target
	detach_parent = player.get_parent()
	if detach_parent == null:
		# fallback: original_parent's parent
		detach_parent = original_parent.get_parent()

	# If still null, cannot detach safely
	if detach_parent == null:
		return

	saved_global_pos = global_position

	(original_parent as Node).remove_child(self)
	(detach_parent as Node).add_child(self)

	global_position = saved_global_pos
	detached = true

func _reattach_to_player() -> void:
	if not detached:
		return

	var gpos: Vector2 = global_position

	get_parent().remove_child(self)
	player.add_child(self)

	global_position = gpos
	detached = false

# ---------------- Idle pose ----------------

func _restore_idle_pose() -> void:
	head.position = idle_head_pos
	tail.position = idle_tail_pos
	body.position = idle_body_pos
	body.visible = idle_body_visible
	body.region_rect = idle_body_region

# ---------------- Endpoints & application ----------------

func _start_x() -> float:
	return idle_tail_pos.x + butt_offset

func _apply_extend() -> void:
	var start_x: float = _start_x()
	var len: float = clamp(current_length, 0.0, max_length)
	var end_x: float = start_x + len
	var end_trim: float = end_x - snout_offset

	tail.position = Vector2(idle_tail_pos.x, cap_y)
	head.position = Vector2(end_x, cap_y)

	body.visible = true
	body.position.y = body_y
	_stretch_body_between(start_x + body_trim_start, end_trim - body_trim_end)

	_update_platform_from_endpoints(start_x, end_trim)

func _apply_retract() -> void:
	# Kept same behavior as your original (min clamp at 100)
	var len: float = clamp(current_length, 100.0, max_length)
	var end_trim: float = end_anchor_x
	var start_x: float = end_trim - len

	head.position = Vector2(end_trim + snout_offset, cap_y)
	tail.position = Vector2((start_x - butt_offset), cap_y)

	body.visible = true
	body.position.y = body_y
	_stretch_body_between(start_x + body_trim_start, end_trim - body_trim_end)

	_update_platform_from_endpoints(start_x, end_trim)

func _stretch_body_between(start_x: float, end_x: float) -> void:
	var width: float = max(0.0, end_x - start_x)

	body.position.x = start_x

	var rr: Rect2 = body.region_rect
	rr.size.x = width
	rr.size.y = body_height
	body.region_rect = rr

func _update_platform_from_endpoints(start_x: float, end_x: float) -> void:
	var feet_y: float = 0.0
	var pcol_node: Node = player.get_node_or_null("CollisionShape2D")
	var pcol: CollisionShape2D = pcol_node as CollisionShape2D
	if pcol != null and (pcol.shape is RectangleShape2D):
		var s: RectangleShape2D = pcol.shape as RectangleShape2D
		feet_y = (s.size.y * 0.5) + extra_down

	var bridge_len: float = max(0.0, end_x - start_x)
	var padded_len: float = max(0.0, bridge_len + platform_width_pad)

	colshape.disabled = (bridge_len < solid_after)

	rect.size = Vector2(padded_len, platform_height)
	colshape.position.x = (start_x + end_x) * 0.5
	colshape.position.y = feet_y + (platform_height * 0.5)

# ---------------- Player helpers ----------------

func _get_player_side_x(facing: int) -> float:
	var pcol_node: Node = player.get_node_or_null("CollisionShape2D")
	var pcol: CollisionShape2D = pcol_node as CollisionShape2D
	if pcol != null and (pcol.shape is RectangleShape2D):
		var s: RectangleShape2D = pcol.shape as RectangleShape2D
		return (s.size.x * 0.5) * float(facing)
	return 0.0

func _get_player_facing() -> int:
	if player != null and player.has_method("get_facing_dir"):
		var v: Variant = player.call("get_facing_dir")
		return int(v)
	return 1
