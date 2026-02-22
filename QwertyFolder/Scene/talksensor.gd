extends Area2D

@export var player_group: StringName = &"player"
@export var talk_anim: StringName = &"Talk"
@export var idle_anim: StringName = &"Idle"
@export var sprite_path: NodePath = NodePath("../AnimatedSprite2D")

# How far above the sensor top the player must be (tune)
@export var min_above_pixels: float = 4.0

@onready var sprite: AnimatedSprite2D = get_node(sprite_path) as AnimatedSprite2D
@onready var shape_node: CollisionShape2D = $CollisionShape2D

var standing := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group(player_group):
		return
	if _is_from_above(body):
		standing = true
		sprite.play(talk_anim)

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group(player_group):
		return
	standing = false
	sprite.play(idle_anim)

func _is_from_above(body: Node) -> bool:
	# Compute top of sensor in global space (rectangle/capsule both approximate fine here)
	var top_y = shape_node.global_position.y
	# body must be above the sensor by at least min_above_pixels
	return body.global_position.y < (top_y - min_above_pixels)
