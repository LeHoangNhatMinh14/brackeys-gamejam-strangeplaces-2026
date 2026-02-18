extends Node2D

@export var dog_scene: PackedScene

var dog: Node = null
var dog_unlocked := true
var dog_left := false
var dog_can_reactivate := false

func _ready() -> void:
	if dog_unlocked and not dog_left:
		_spawn_dog()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dog_toggle"):
		_toggle()

func _physics_process(_delta: float) -> void:
	if dog == null:
		return
	dog.set_extending(Input.is_action_pressed("dog_extend"))

func _toggle() -> void:
	if dog_left and not dog_can_reactivate:
		return

	if dog == null:
		_spawn_dog()
	else:
		dog.queue_free()
		dog = null

func _spawn_dog() -> void:
	if dog_scene == null:
		return
	dog = dog_scene.instantiate()
	get_parent().add_child(dog)
	dog.player = get_parent()
