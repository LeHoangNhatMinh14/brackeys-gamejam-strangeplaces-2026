extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

const faceOffset = 13

@onready var bodySprite: AnimatedSprite2D = $Body
@onready var faceSprite: AnimatedSprite2D = $Face

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	# to get the input direction, either -1 or 1
	var direction := Input.get_axis("move_left", "move_right")

	# flip the sprite
	if direction > 0:
		bodySprite.flip_h = false
		faceSprite.position.x = faceOffset
	elif direction < 0:
		bodySprite.flip_h = true
		faceSprite.position.x = -faceOffset
	
	# play animations
	if is_on_floor():
		if direction == 0:
			bodySprite.play("Idle")
		else:
			bodySprite.play("Run")

	# only for showcasing talking
	if Input.is_action_pressed("interact"):
		faceSprite.play("FaceTalk")
	else: 
		faceSprite.play("FaceIdle")

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
