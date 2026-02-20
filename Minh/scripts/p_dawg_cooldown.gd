extends Node2D

@export var dog_path: NodePath = NodePath("../../../Dog") # or set in Inspector
@export var charge_animation: StringName = &"Charge"
@export var idle_animation: StringName = &"Idle"
@export var frames_to_full: int = 24

@onready var sprite: AnimatedSprite2D = $CooldownSprite
var dog: Node = null

enum UIState { IDLE, CHARGING, DRAINING }
var state: int = UIState.IDLE
var last_ratio: float = 0.0

func _ready() -> void:
	dog = get_node_or_null(dog_path)
	visible = true

	# start in Idle
	sprite.animation = idle_animation
	sprite.play()

	sprite.animation_finished.connect(_on_anim_finished)

func _process(_delta: float) -> void:
	if dog == null or not dog.has_method("get_cooldown_ratio"):
		return

	var ratio: float = clamp(float(dog.call("get_cooldown_ratio")), 0.0, 1.0)

	# cooldown ended -> Idle stays visible
	if ratio <= 0.0:
		state = UIState.IDLE
		last_ratio = ratio

		if sprite.animation != idle_animation:
			sprite.animation = idle_animation
		if not sprite.is_playing():
			sprite.play()

		return

	# cooldown started (0 -> >0)
	var started: bool = (last_ratio <= 0.0 and ratio > 0.0)
	last_ratio = ratio

	if started:
		state = UIState.CHARGING
		sprite.animation = charge_animation
		sprite.frame = 0
		sprite.play()
		return

	if state == UIState.CHARGING:
		# let Charge play to completion; draining begins in _on_anim_finished
		return

	# DRAINING: show remaining cooldown by frame
	sprite.stop()

	var fmax: int = max(0, frames_to_full - 1)
	var frame_idx: int = int(round(ratio * float(fmax))) # 1.0 full -> 0.0 empty
	sprite.frame = clamp(frame_idx, 0, fmax)

func _on_anim_finished() -> void:
	# Only transition when Charge finishes
	if sprite.animation == charge_animation:
		state = UIState.DRAINING
		sprite.stop()
		sprite.frame = max(0, frames_to_full - 1)
