extends Panel

@onready var label: Label = $Label # change to your real label path

func _ready() -> void:
	print("DialoguePanel ready. label =", label)
	visible = false

func show_text(t: String) -> void:
	print("show_text called with:", t, " label =", label)
	if label == null:
		return
	label.text = t
	visible = true
