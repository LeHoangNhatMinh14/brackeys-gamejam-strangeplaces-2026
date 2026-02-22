extends Panel

@onready var label: Label = $DialogueLabel

func _ready() -> void:
	visible = true

func show_text(t: String) -> void:
	label.text = t
	visible = true

func hide_text() -> void:
	visible = false

func is_open() -> bool:
	return visible
