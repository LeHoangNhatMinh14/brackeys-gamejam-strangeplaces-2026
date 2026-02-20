extends Area2D

var nearby: Array = []

func _ready() -> void:
	monitoring = true
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(a: Area2D) -> void:
	if a.has_method("interact"):
		nearby.append(a)

func _on_area_exited(a: Area2D) -> void:
	if a in nearby:
		nearby.erase(a)

func try_interact() -> void:
	if nearby.is_empty():
		return
	nearby[0].interact()
