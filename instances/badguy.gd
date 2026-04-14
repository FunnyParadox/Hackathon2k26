extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -160.0

var direction := 0
var change_dir := 0.0

func _process(delta: float) -> void:
	if is_on_floor():
		rotation_degrees = 0
	else:
		rotation_degrees += delta * 160.0 * direction

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		direction = (randi() % 2) * 2 - 1
	else:
		velocity += get_gravity() * delta
	velocity.x = direction * SPEED

	move_and_slide()
