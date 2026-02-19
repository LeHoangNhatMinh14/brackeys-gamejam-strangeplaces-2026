extends CanvasLayer

@export var dog_path: NodePath = NodePath("../../Dog")
@onready var bar: Range = $CooldownBar

var dog: Node = null

func _ready() -> void:
	dog = get_node_or_null(dog_path)
	# Make sure bar is configured for 0..1
	bar.min_value = 0.0
	bar.max_value = 1.0

func _process(_delta: float) -> void:
	if dog == null:
		return
	var ratio: float = dog.get_cooldown_ratio()

	# show countdown (full -> empty). swap if you prefer the opposite.
	bar.value = 1.0 - ratio

	# optional: always visible for debugging
	# bar.visible = true
	bar.visible = ratio > 0.0
