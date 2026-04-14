extends CharacterBody2D

var sprite: Sprite2D
var collision: CollisionShape2D
var skate_sprite: Sprite2D
var skate_position := Vector2(0, 0)

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
const THROW_RADIUS := 700.0
const KNOCKBACK_FORCE := 600.0

const DOWN_SLOPE_CHECK := 24

enum timer_enum { STOP, PLAY, PAUSE }
var timer_state: timer_enum = timer_enum.STOP
var timer: float = 0.0
var collected: int = 0
var killed: int = 0

var lives: int = BASE_LIVES
var invincible_frames := -1.0
var throwing_frames := 0.0

var air_time := 0.0
var jump_force := 0.0
enum jump_enum { NO_JUMP, JUMP, SUPER_JUMP }
var has_jumped: jump_enum = jump_enum.NO_JUMP
var is_knocked := false
var gravity_angle := 0.0
var last_acceleration := ACCELERATION_LIMIT
var direction := 1 # -1: left, 1: right
var previous_is_on_floor := is_on_floor()

var throw_target: CharacterBody2D = null
var raycast_check := RayCast2D.new()

var audio_player_trash = AudioStreamPlayer.new()
var audio_player_kill = AudioStreamPlayer.new()

func _ready() -> void:
	add_child(audio_player_trash)
	audio_player_trash.volume_db = -3.0
	audio_player_trash.stream = preload("res://sounds/Trash_Collect.mp3")
	add_child(audio_player_kill)
	audio_player_trash.volume_db = -1.0
	audio_player_kill.stream = preload("res://sounds/Hit_Enemy.mp3")

	timer_state = timer_enum.PLAY
	sprite = get_node("Sprite2D")
	skate_sprite = get_node("Sprite2DSkate")
	collision = get_node("CollisionShape2D")
	add_child(raycast_check)
	raycast_check.enabled = true
	raycast_check.collision_mask = 1 << 0
	get_node("CollectArea").body_entered.connect(_on_collect_body_entered)

func _on_collect_body_entered(body: Node2D) -> void:
	if body.is_in_group("collectibles"):
		if body.life_time >= 0.3:
			body.kill()
			collected += 1
			audio_player_trash.play()
	if body.is_in_group("enemies"):
		take_damage(body.position)

func get_correct_gravity(delta: float) -> float:
	if is_on_floor():
		return get_floor_normal().angle() + PI / 2
	else:
		while (gravity_angle > PI): gravity_angle -= TAU
		while (gravity_angle <-PI): gravity_angle += TAU
		return move_toward(gravity_angle, 0.0, delta * GRAVITY_SPEED * float(!previous_is_on_floor))

var bkp_has_super_jumped := 0.0
func handle_gravity(delta: float, gravity: Vector2) -> void:
	if is_knocked:  return
	# Add the gravity.
	if not is_on_floor():
		air_time += delta
		velocity += gravity * GRAVITY_FORCE * delta
		var gravity_speed := velocity.dot(gravity)
		if gravity_speed > GRAVITY_MAX:
			velocity -= gravity * (gravity_speed - MAX_SPEED)
	else:
		air_time = 0
		if (has_jumped == jump_enum.SUPER_JUMP):
			bkp_has_super_jumped = 1.0
		has_jumped = jump_enum.NO_JUMP

func handle_jump(delta: float, gravity: Vector2) -> void:
	# Handle jump.
	if Input.is_action_just_released("Jump") and air_time < COYOTE_JUMP and has_jumped == jump_enum.NO_JUMP:
		velocity -= gravity * (velocity.dot(gravity) + JUMP_VELOCITY) * pow(jump_force, 0.25)
		if (jump_force >= 0.95):
			has_jumped = jump_enum.SUPER_JUMP
		else:
			has_jumped = jump_enum.JUMP
	if Input.is_action_pressed("Jump"):
		jump_force = min(jump_force + delta / JUMP_CHARGE_SPEED, 1.0)
	else:
		jump_force = 0
	if (has_jumped == jump_enum.NO_JUMP and !is_knocked):
		raycast_check.target_position = Vector2(0, DOWN_SLOPE_CHECK)
		raycast_check.force_raycast_update()
		if raycast_check.is_colliding():
			var collision_point := raycast_check.get_collision_point()
			var collision_normal := raycast_check.get_collision_normal()
			# Snap to floor and align with slope
			global_position = collision_point
			gravity_angle = collision_normal.angle() + PI / 2
			# Remove downward velocity, keep movement along the slope
			var gravity_component := velocity.dot(gravity)
			if gravity_component > 0:
				velocity -= gravity * gravity_component
			air_time = 0
			return

func handle_acceleration(delta: float, floor_speed: float) -> float:
	if is_knocked:
		return floor_speed
	if is_on_floor():
		floor_speed += sin(gravity_angle) * GRAVITY_SLOPE_FORCE * delta
	if air_time < COYOTE_JUMP and (Input.is_action_just_pressed("AccelerateLeft") or Input.is_action_just_pressed("AccelerateRight")):
		direction = int(Input.is_action_just_pressed("AccelerateRight")) - int(Input.is_action_just_pressed("AccelerateLeft"))
		floor_speed += direction * ACCELERATION * pow(min(last_acceleration / ACCELERATION_LIMIT, 1.0), 2.0)
		last_acceleration = 0
	elif invincible_frames == -1:
		last_acceleration = clamp(last_acceleration + delta, 0, ACCELERATION_LIMIT)
		floor_speed = move_toward(floor_speed, 0, DECELERATION)
	elif is_on_floor():
		invincible_frames = -1
		floor_speed = 0
	return clamp(floor_speed, -MAX_SPEED, MAX_SPEED)

func get_closest_enemy_in_semicircle() -> CharacterBody2D:
	var forward := Vector2(direction, 0).rotated(gravity_angle)
	var closest: CharacterBody2D = null
	var closest_dist := THROW_RADIUS + 1.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var to_enemy: Vector2 = enemy.global_position - global_position
		var dist := to_enemy.length()
		if dist <= THROW_RADIUS and to_enemy.dot(forward) >= 0 and dist < closest_dist:
			closest = enemy
			closest_dist = dist
	return closest

func handle_throw(delta: float) -> void:
	if throw_target:
		skate_position = skate_position.move_toward(throw_target.global_position, delta * THROW_RADIUS)
		skate_sprite.rotation += delta * 20
		if skate_position.distance_to(throw_target.global_position) < 1.0:
			print("target killed: ", throw_target)
			throw_target.kill()
			throw_target = null
			audio_player_kill.play()
	else:
		skate_sprite.rotation = 0
		skate_position = skate_position.move_toward(global_position + Vector2(0, -54).rotated(gravity_angle), delta * THROW_RADIUS)
	if throwing_frames > 0.0:
		throwing_frames = move_toward(throwing_frames, 0, delta * 5)
		return
	elif Input.is_action_just_released("Throw") and !is_on_floor():
		var target := get_closest_enemy_in_semicircle()
		if target:
			throw_target = target
			print("target: ", throw_target)
		throwing_frames = 1.0

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

func take_damage(pos: Vector2) -> void:
	if invincible_frames >= 0: return
	lives -= 1
	is_knocked = true
	@warning_ignore("narrowing_conversion")
	var wall_side := signi(global_position.x - pos.x)
	velocity.y -= KNOCKBACK_FORCE
	velocity.x = KNOCKBACK_FORCE * (-1 if wall_side < 0 else 1)
	invincible_frames = INVINCIBILITY_TIME
	print(invincible_frames)
	if lives <= 0:
		# TODO: handle death (respawn, game over, etc.)
		pass

const TrashScene = preload("res://instances/trash.tscn")

func death() -> void:
	for i in 12:
		var trash = TrashScene.instantiate()
		trash.global_position = global_position
		trash.rotation = randf() * TAU
		# Ring burst like Sonic — evenly spaced angles with random speed variation
		var base_angle = (TAU / 10.0) * i + randf_range(-0.2, 0.2)
		var speed = randf_range(400.0, 1600.0)
		trash.velocity = Vector2(cos(base_angle) * speed * 0.3, sin(base_angle) * speed * 0.55 - 350.0)
		trash.only_down = false
		get_tree().current_scene.add_child(trash)
	queue_free()

func animation_acceleration() -> void:
	if (last_acceleration >= ACCELERATION_LIMIT): return
	if (last_acceleration < ACCELERATION_LIMIT * 1 / 5):
		sprite.texture = preload("res://sprites/SkateuseAccelerate1.png"); return
	if (last_acceleration < ACCELERATION_LIMIT * 2 / 4):
		sprite.texture = preload("res://sprites/SkateuseAccelerate2.png"); return
	if (last_acceleration < ACCELERATION_LIMIT * 3 / 3):
		sprite.texture = preload("res://sprites/SkateuseAccelerate3.png"); return

func animation_jump(delta: float) -> void:
	if jump_force >= 0.95:
		var blink = abs(sin(Time.get_ticks_msec() / 10.0))
		sprite.modulate = Color(1, blink, blink)
	else:
		sprite.modulate = Color(1, 1, 1)
	if (air_time < COYOTE_JUMP):
		if (bkp_jump_force < jump_force || jump_force >= 0.95):
			sprite.texture = preload("res://sprites/SkateuseChargeJump.png"); return
	elif has_jumped == jump_enum.NO_JUMP:
		sprite.texture = preload("res://sprites/SkateuseKickFlip1.png")
	match (has_jumped):
		jump_enum.NO_JUMP:
			if (bkp_has_super_jumped > 0.99):
				bkp_has_super_jumped = move_toward(bkp_has_super_jumped, 0.0, delta)
				sprite.texture = preload("res://sprites/SkateuseKickFlip1.png")
			return
		jump_enum.JUMP:
			sprite.texture = preload("res://sprites/SkateuseJump.png"); return
		jump_enum.SUPER_JUMP:
			sprite.texture = preload("res://sprites/SkateuseKickFlip1.png")
			if (air_time > 0.08):
				if (fmod(air_time, 0.4) > 0.2):
					sprite.texture = preload("res://sprites/SkateuseKickFlip2.png")
				else:
					sprite.texture = preload("res://sprites/SkateuseKickFlip3.png")
			return

func animation_throw() -> void:
	skate_sprite.global_position = skate_position
	if (throwing_frames <=0/6.0 and throw_target != null):
		sprite.texture = preload("res://sprites/SkateuseThrow7.png");
		skate_sprite.visible = true
	else:
		skate_sprite.visible = false
	if (throwing_frames > 0/6.0):
		sprite.texture = preload("res://sprites/SkateuseThrow6.png");
	if (throwing_frames > 1/6.0):
		sprite.texture = preload("res://sprites/SkateuseThrow5.png");
	if (throwing_frames > 2/6.0):
		sprite.texture = preload("res://sprites/SkateuseThrow4.png");
	if (throwing_frames > 3/6.0):
		sprite.texture = preload("res://sprites/SkateuseThrow3.png");
	if (throwing_frames > 4/6.0):
		sprite.texture = preload("res://sprites/SkateuseThrow2.png");
	if (throwing_frames > 5/6.0):
		sprite.texture = preload("res://sprites/SkateuseThrow1.png");
		

var bkp_sprite_flip_h := 0
var bkp_jump_force := jump_force
func _process(delta: float) -> void:
	match (timer_state):
		timer_enum.STOP: timer = 0
		timer_enum.PLAY: timer += delta
		timer_enum.PAUSE: timer += 0

	sprite.texture = preload("res://sprites/SkateuseBase.png")
	animation_jump(delta)
	animation_acceleration()
	animation_throw()
	sprite.flip_h = velocity.x < 0
	if (velocity.x == 0): sprite.flip_h = bkp_sprite_flip_h
	bkp_jump_force = jump_force
	bkp_sprite_flip_h = sprite.flip_h

func _physics_process(delta: float) -> void:
	if (invincible_frames > 0): invincible_frames = move_toward(invincible_frames, 0.0, delta)

	gravity_angle = get_correct_gravity(delta)
	
	var gravity := Vector2(0, 1).rotated(gravity_angle)
	var floor_dir := Vector2(1, 0).rotated(gravity_angle)
	rotation = lerp(rotation, gravity_angle, delta * 10)
	up_direction = -gravity

	handle_gravity(delta, gravity)
	handle_jump(delta, gravity)
	handle_throw(delta)

	if !is_knocked:
		var floor_speed := handle_acceleration(delta, velocity.dot(floor_dir))
		velocity = gravity * velocity.dot(gravity) + floor_dir * floor_speed
	else:
		# Apply only gravity, do NOT rebuild velocity
		velocity += gravity * GRAVITY_FORCE * delta

	var pre_velocity := velocity
	move_and_slide()
	if is_on_floor():
		is_knocked = false
		previous_is_on_floor = true
	else:
		previous_is_on_floor = false

	ground_corner_correction(delta, floor_dir, pre_velocity, gravity)
	
	if global_position.y > 0:
		lives = 0
	if (!lives):
		death()
	if global_position.x > 16500:
		kd.player_time = timer
		get_tree().change_scene_to_file("res://end_screen.tscn")
