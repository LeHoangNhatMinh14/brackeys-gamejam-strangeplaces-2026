extends Area2D

@export var ending_scene: String = "res://QwertyFolder/Scene/Ending.tscn"
@export var cooldown_time: float = 0.5

var _cooldown := 0.0

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = max(0.0, _cooldown - delta)

func can_interact() -> bool:
	return _cooldown <= 0.0

func interact() -> void:
	if not can_interact():
		return

	_cooldown = cooldown_time

	var err := get_tree().change_scene_to_file(ending_scene)
	if err != OK:
		push_error("change_scene_to_file failed with code: %d" % err)
