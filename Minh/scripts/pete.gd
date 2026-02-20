extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var visuals: Node2D = $Visuals
@onready var bodySprite: AnimatedSprite2D = $Visuals/Body
@onready var faceSprite: AnimatedSprite2D = $Visuals/Face
@onready var dogFace: AnimatedSprite2D = $Dog/Visuals/Head/Face
@onready var interaction_area: Area2D = $InteractionArea

var facing_dir: int = 1
var talk_timer: float = 0.0
@export var talk_flash_time: float = 0.2

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# press-to-interact (W/Up mapped to "interact")
	if Input.is_action_just_pressed("interact"):
		interaction_area.try_interact()
		talk_timer = talk_flash_time

	var direction := Input.get_axis("ui_left", "ui_right")

	# update facing when player presses left/right
	if direction != 0:
		facing_dir = -1 if direction < 0 else 1
		visuals.scale.x = facing_dir

	# movement
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# animations
	if is_on_floor():
		bodySprite.play("Idle" if direction == 0 else "Run")

	talk_timer = max(0.0, talk_timer - delta)
	var talking := talk_timer > 0.0
	faceSprite.play("FaceTalk" if talking else "FaceIdle")
	dogFace.play("Talk" if talking else "Idle")

	move_and_slide()

func get_facing_dir() -> int:
	return facing_dir
