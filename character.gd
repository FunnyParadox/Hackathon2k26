extends CharacterBody2D

const ACCELERATION = 160.0
const DECELERATION := 1./3.
const MAX_SPEED := 372.0

const WALL_TOLERANCE := 16.0

const ACCELERATION_LIMIT := 0.60
const GRAVITY_SPEED := 3.0
const GRAVITY_FORCE := 1400.0
const GRAVITY_SLOPE_FORCE := 720.0
const GRAVITY_MAX := 981.0

const JUMP_VELOCITY := 680.0
const JUMP_CHARGE_SPEED := 1.21 # in seconds
const COYOTE_JUMP := sqrt(2)/10

const BASE_LIVES := 3
const INVINCIBILITY_TIME := 3.0 # in seconds
const KNOCKBACK_FORCE := 300.0

var lives: int = BASE_LIVES
var invincible_frames := -1.0

var air_time := 0.0
var jump_force := 0.0
var has_jumped := false
var last_acceleration := 0.0
var gravity_angle := 0.0
var direction := 1 # -1: left, 1: right
var previous_is_on_floor := is_on_floor()

func get_correct_gravity(delta: float, previous_is_on_floor: bool) -> float:
	if is_on_floor():
		return get_floor_normal().angle() + PI / 2
	else:
		return move_toward(gravity_angle, 0.0, delta * GRAVITY_SPEED * float(!previous_is_on_floor))

func handle_gravity(delta: float, gravity: Vector2) -> void:
	# Add the gravity.
	if not is_on_floor():
		air_time += delta
		velocity += gravity * GRAVITY_FORCE * delta
		var gravity_speed := velocity.dot(gravity)
		if gravity_speed > GRAVITY_MAX:
			velocity -= gravity * (gravity_speed - MAX_SPEED)
	else:
		air_time = 0
		has_jumped = false

func handle_jump(delta: float, gravity: Vector2) -> void:
	# Handle jump.
	if Input.is_action_just_released("Jump") and air_time < COYOTE_JUMP and not has_jumped:
		velocity -= gravity * (velocity.dot(gravity) + JUMP_VELOCITY) * pow(jump_force, 0.25)
		has_jumped = true
	if Input.is_action_pressed("Jump"):
		jump_force = min(jump_force + delta / JUMP_CHARGE_SPEED, 1.0)
	else:
		jump_force = 0

func handle_acceleration(delta: float, floor_speed: float) -> float:
	if is_on_floor():
		floor_speed += sin(gravity_angle) * GRAVITY_SLOPE_FORCE * delta
	if air_time < COYOTE_JUMP and Input.is_action_just_pressed("Accelerate"):
		floor_speed += direction * ACCELERATION * pow(min(last_acceleration / ACCELERATION_LIMIT, 1.0), 2.0)
		last_acceleration = 0
	elif invincible_frames == -1:
		last_acceleration += delta
		floor_speed = move_toward(floor_speed, 0, DECELERATION)
	elif is_on_floor():
		invincible_frames = -1
		floor_speed = 0
	return clamp(floor_speed, -MAX_SPEED, MAX_SPEED)

func ground_corner_correction(delta: float, floor_dir: Vector2, pre_velocity: Vector2, gravity: Vector2) -> void:
	# Ground corner correction: step over ledges within WALL_TOLERANCE
	if is_on_wall():
		var horizontal_motion := floor_dir * pre_velocity.dot(floor_dir) * delta
		for i in range(1, int(WALL_TOLERANCE) + 1):
			var up := -gravity * float(i)
			if not test_move(global_transform.translated(up), horizontal_motion):
				global_position += up
				velocity = pre_velocity
				move_and_slide()
				break
	if is_on_wall():
		take_damage(pre_velocity)

func take_damage(pre_velocity: Vector2) -> void:
	if invincible_frames >= 0: return
	lives -= 1
	print(-pre_velocity.normalized().x * KNOCKBACK_FORCE)
	velocity.x = -pre_velocity.normalized().x * KNOCKBACK_FORCE
	invincible_frames = INVINCIBILITY_TIME
	print(invincible_frames      )
	if lives <= 0:
		# TODO: handle death (respawn, game over, etc.)
		pass

func _physics_process(delta: float) -> void:
	if (invincible_frames > 0): invincible_frames = move_toward(invincible_frames, 0.0, delta)

	gravity_angle = get_correct_gravity(delta, previous_is_on_floor)
	
	var gravity := Vector2(0, 1).rotated(gravity_angle)
	var floor_dir := Vector2(1, 0).rotated(gravity_angle)
	rotation = lerp(rotation, gravity_angle, delta * 10)
	up_direction = -gravity

	handle_gravity(delta, gravity)
	handle_jump(delta, gravity)

	# Get the input direction and handle the movement/deceleration.
	# direction = -1 if Input.is_action_pressed("Backward") else 1

	var floor_speed := handle_acceleration(delta, velocity.dot(floor_dir))
	velocity = gravity * velocity.dot(gravity) + floor_dir * floor_speed

	var pre_velocity := velocity
	move_and_slide()
	previous_is_on_floor = is_on_floor()
	
	ground_corner_correction(delta, floor_dir, pre_velocity, gravity)
