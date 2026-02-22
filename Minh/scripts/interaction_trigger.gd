extends Area2D

@export var dialogue_path: NodePath = NodePath("../Dialogue") # this node IS a Label
@export var sprite_path: NodePath = NodePath("../AnimatedSprite2D")

@export var talk_anim: StringName = &"Talk"
@export var idle_anim: StringName = &"Idle"

@export var auto_hide_time: float = 3.0
@export var cooldown_time: float = 0.5
@export var typing_time: float = 1.2

@onready var dialogue: Label = get_node_or_null(dialogue_path) as Label
@onready var sprite: AnimatedSprite2D = get_node_or_null(sprite_path) as AnimatedSprite2D

var _hide_timer := 0.0
var _cooldown := 0.0
var _open := false
var _typing := false
var _tween: Tween = null

func _ready() -> void:
	if dialogue != null:
		dialogue.visible = false
		dialogue.visible_ratio = 1.0

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = max(0.0, _cooldown - delta)

	if _open and not _typing:
		_hide_timer -= delta
		if _hide_timer <= 0.0:
			_close()

func interact() -> void:
	if _cooldown > 0.0:
		return
	_cooldown = cooldown_time

	if _open:
		_close()
	else:
		_open_dialogue()

func _open_dialogue() -> void:
	_open = true
	_typing = true
	_hide_timer = 0.0

	if dialogue != null:
		dialogue.visible = true
		dialogue.visible_ratio = 0.0

	if sprite != null:
		sprite.play(talk_anim)

	if _tween != null and _tween.is_running():
		_tween.kill()

	if dialogue == null:
		_on_typing_finished()
		return

	_tween = create_tween()
	_tween.tween_property(dialogue, "visible_ratio", 1.0, typing_time)
	_tween.finished.connect(_on_typing_finished)

func _on_typing_finished() -> void:
	_typing = false

	if sprite != null:
		sprite.play(idle_anim)

	_hide_timer = auto_hide_time

func _close() -> void:
	_open = false
	_typing = false
	_hide_timer = 0.0

	if _tween != null and _tween.is_running():
		_tween.kill()

	if dialogue != null:
		dialogue.visible = false
		dialogue.visible_ratio = 1.0

	if sprite != null:
		sprite.play(idle_anim)
