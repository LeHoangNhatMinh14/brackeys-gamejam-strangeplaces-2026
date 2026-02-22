extends Area2D

var nearby: Array[Area2D] = []
var current: Area2D = null

func _ready() -> void:
	monitoring = true
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(a: Area2D) -> void:
	if a.has_method("interact"):
		nearby.append(a)
	_pick_current()

func _on_area_exited(a: Area2D) -> void:
	if a in nearby:
		nearby.erase(a)
	_pick_current()

func _pick_current() -> void:
	current = nearby[0] if not nearby.is_empty() else null

func try_interact() -> void:
	if current == null:
		return
	current.interact()
