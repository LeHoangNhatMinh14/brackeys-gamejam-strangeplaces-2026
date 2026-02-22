extends Control
class_name DialogueUI

@export var typewriter_time: float = 1.2
@export var auto_hide_time: float = 3.0

@onready var indicator: Control = $Indicator
@onready var panel: Panel = $DialoguePanel
@onready var label: Label = $DialoguePanel/DialogueLabel

var _active_target: Node = null
var _typing := false
var _auto_hide_timer := 0.0
var _tween: Tween = null

#func _ready() -> void:
	#indicator.visible = false
	#panel.visible = false
	#label.visible_ratio = 0.0
	#label.text = ""

func _process(delta: float) -> void:
	# Auto hide after finished typing
	if panel.visible and (not _typing) and _auto_hide_timer > 0.0:
		_auto_hide_timer -= delta
		if _auto_hide_timer <= 0.0:
			close_dialogue(true)

func can_show_indicator_for(target: Node) -> bool:
	if target == null:
		return false
	if panel.visible or _typing:
		return false
	if target.has_method("can_interact") and not target.can_interact():
		return false
	return true

func show_indicator_for(target: Node) -> void:
	_active_target = target
	indicator.visible = can_show_indicator_for(target)

func hide_indicator() -> void:
	indicator.visible = false

func start_dialogue(target: Node, text: String) -> void:
	if target == null:
		return
	if panel.visible or _typing:
		return

	_active_target = target
	hide_indicator()

	# show panel
	panel.visible = true
	label.text = text
	label.visible_ratio = 0.0
	_typing = true
	_auto_hide_timer = 0.0

	# start talk anim on target
	if target.has_method("start_talk"):
		target.start_talk()

	# typewriter tween
	if _tween != null and _tween.is_running():
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(label, "visible_ratio", 1.0, typewriter_time)
	_tween.finished.connect(_on_typewriter_finished)

func _on_typewriter_finished() -> void:
	_typing = false

	# stop talk anim on target
	if _active_target != null and _active_target.has_method("stop_talk"):
		_active_target.stop_talk()

	# begin cooldown on target
	if _active_target != null and _active_target.has_method("begin_cooldown"):
		_active_target.begin_cooldown()

	_auto_hide_timer = auto_hide_time

func close_dialogue(show_indicator_if_possible: bool) -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()

	panel.visible = false
	label.text = ""
	label.visible_ratio = 0.0
	_typing = false
	_auto_hide_timer = 0.0

	if show_indicator_if_possible:
		indicator.visible = can_show_indicator_for(_active_target)
	else:
		indicator.visible = false

func is_open() -> bool:
	return panel.visible or _typing
