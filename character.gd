extends CharacterBody2D

const ACCELERATION = 160.0
const DECELERATION = 0.395
const MAX_SPEED = 372.0

const ACCELERATION_LIMIT = 0.60
const GRAVITY_FORCE = 1500.0

const JUMP_VELOCITY = 500.0
const COYOTE_JUMP = sqrt(2)/10

var air_time := 0.0
var has_jumped := false
var last_acceleration := 0.0
var gravity_angle := 0.0
var direction := 1 # -1: left, 1: right

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		air_time += delta
		velocity += Vector2(0, 1).rotated(gravity_angle) * GRAVITY_FORCE * delta
	else:
		air_time = 0
		has_jumped = false

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and air_time < COYOTE_JUMP and not has_jumped:
		velocity.y = -JUMP_VELOCITY
		has_jumped = true

	# Get the input direction and handle the movement/deceleration.
	if Input.is_action_just_pressed("Left"):
		direction = -1
	if Input.is_action_just_pressed("Right"):
		direction = not Input.is_action_just_pressed("Left")

	if air_time < COYOTE_JUMP and Input.is_action_just_pressed("Accelerate"):
		velocity.x += direction * ACCELERATION * pow(min(last_acceleration / ACCELERATION_LIMIT, 1.0), 2.0)
		last_acceleration = 0
	else:
		last_acceleration += delta
		velocity.x = move_toward(velocity.x, 0, DECELERATION)
	velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)

	move_and_slide()
