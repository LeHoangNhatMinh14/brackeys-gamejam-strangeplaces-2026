extends Node2D

@export var dog_path: NodePath
@onready var dog = get_node(dog_path)

func _ready() -> void:
	dog.player = get_parent()

func _process(_delta: float) -> void:
	if not dog.visible:
		return
	dog.set_extending(Input.is_action_pressed("dog_extend"))

func activate_dog() -> void:
	dog.visible = true
	dog.set_process(true)

func deactivate_dog() -> void:
	dog.set_extending(false)
	dog.visible = false
	dog.set_process(false)

func dog_leaves() -> void:
	# use this for the quest moment
	deactivate_dog()
