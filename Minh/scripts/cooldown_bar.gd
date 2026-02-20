extends CanvasLayer

@export var dog_path: NodePath = NodePath("../../Dog")

@export var charge_anim: StringName = &"Charge"
@export var idle_anim: StringName = &"Idle"

# If Idle has the same number of frames as Charge, keep 24.
# Otherwise set this to Idle's frame count.
@export var idle_frames: int = 24

@onready var bar: AnimatedSprite2D = $CooldownBar
var dog: Node = null

enum UIState { HIDDEN, CHARGING, DRAINING }
var state: int = UIState.HIDDEN
var last_ratio: float = 0.0

func _ready() -> void:
	dog = get_node_or_null(dog_path)
	visible = false

	bar.animation_finished.connect(_on_charge_finished)

func _process(_delta: float) -> void:
	if dog == null or not dog.has_method("get_cooldown_ratio"):
		return

	var ratio: float = clamp(float(dog.call("get_cooldown_ratio")), 0.0, 1.0)

	# cooldown ended
	if ratio <= 0.0:
		state = UIState.HIDDEN
		visible = false
		last_ratio = ratio
		return

	visible = true

	# cooldown started (0 -> >0)
	var started: bool = (last_ratio <= 0.0 and ratio > 0.0)
	last_ratio = ratio

	if started:
		state = UIState.CHARGING
		bar.animation = charge_anim
		bar.frame = 0
		bar.play()
		return

	if state == UIState.CHARGING:
		# let Charge play to completion
		return

	# DRAINING using Idle frames
	bar.animation = idle_anim
	bar.stop()

	var fmax: int = max(0, idle_frames - 1)
	var frame_idx: int = int(round((1.0 - ratio) * float(fmax)))
	frame_idx = clamp(frame_idx, 0, fmax)

	bar.frame = frame_idx

func _on_charge_finished() -> void:
	# after Charge finishes, start draining
	state = UIState.DRAINING
	bar.animation = idle_anim
	bar.stop()
	bar.frame = max(0, idle_frames - 1)
