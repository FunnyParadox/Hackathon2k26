extends CharacterBody2D

const ACCELERATION = 160.0
const DECELERATION = 1./3.
const MAX_SPEED = 372.0

const ACCELERATION_LIMIT = 0.60
const GRAVITY_FORCE = 1500.0

const JUMP_VELOCITY = 620.0
const JUMP_CHARGE_SPEED = 0.74 # in seconds
const COYOTE_JUMP = sqrt(2)/10

var air_time := 0.0
var jump_force := 0.0
var has_jumped := false
var last_acceleration := 0.0
var gravity_angle := 0.0
var direction := 1 # -1: left, 1: right

func _physics_process(delta: float) -> void:
	var gravity := Vector2(0, 1).rotated(gravity_angle)

	# Add the gravity.
	if not is_on_floor():
		air_time += delta
		velocity += gravity * GRAVITY_FORCE * delta
	else:
		air_time = 0
		has_jumped = false

	# Handle jump.
	if Input.is_action_just_released("Jump") and air_time < COYOTE_JUMP and not has_jumped:
		velocity -= gravity * (velocity.dot(gravity) + JUMP_VELOCITY) * jump_force
		has_jumped = true
	if Input.is_action_pressed("Jump"):
		jump_force = min(jump_force + delta / JUMP_CHARGE_SPEED, 1.0)
	else:
		jump_force = 0

	# Get the input direction and handle the movement/deceleration.
##	if Input.is_action_just_pressed("Left"):
##		direction = -1
##	if Input.is_action_just_pressed("Right"):
##		direction = not Input.is_action_just_pressed("Left")

	if air_time < COYOTE_JUMP and Input.is_action_just_pressed("Accelerate"):
		velocity.x += direction * ACCELERATION * pow(min(last_acceleration / ACCELERATION_LIMIT, 1.0), 2.0)
		last_acceleration = 0
	else:
		last_acceleration += delta
		velocity.x = move_toward(velocity.x, 0, DECELERATION)
	velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)

	move_and_slide()
