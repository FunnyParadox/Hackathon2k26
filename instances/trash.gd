extends CharacterBody2D

var sprite: Sprite2D

var only_down := true

const SPEED = 100.0
const JUMP_VELOCITY = -160.0

var life_time := 0.0

var direction := -1
var change_dir := 0.0
var killed := false
var slowdown := 1.0

func _ready() -> void:
	sprite = get_node("Sprite2D")
	var randspr := randi() % 3
	match (randspr):
		0: sprite.texture = preload("res://sprites/trash_bottle.png")
		1: sprite.texture = preload("res://sprites/trash_cola.png")
		2: sprite.texture = preload("res://sprites/trash_paper.png")
	add_to_group("collectibles")

func kill() -> void:
	killed = true
	set_collision_layer(0)
	set_collision_mask(0)
	remove_from_group("collectibles")

func _process(delta: float) -> void:
	if killed:
		queue_free()
		return
	if slowdown > 0.0:
		if is_on_floor():
			rotation_degrees = move_toward(rotation_degrees, 0.0, delta * 160.0)
		else:
			rotation_degrees += delta * 160.0 * direction
	sprite.flip_h = true if (direction == -1) else false

const WRAP_MARGIN := 32.0

func _wrap_around_camera() -> void:
	var camera := get_viewport().get_camera_2d()
	if not camera: return
	var visible_size := get_viewport_rect().size / camera.zoom
	var cam_pos := camera.global_position
	var top := cam_pos.y - visible_size.y / 2
	var bottom := cam_pos.y + visible_size.y / 2

	while global_position.y > bottom + WRAP_MARGIN:
		global_position.y = top - WRAP_MARGIN

func _physics_process(delta: float) -> void:
	life_time += delta
	# Add the gravity.
	if !only_down:
		if is_on_floor():
			if (slowdown > 0.1):
				if (slowdown > PI / 12.0):
					velocity.y = JUMP_VELOCITY
					direction = -direction
			else:
				slowdown = 0
		else:
			velocity += get_gravity() * delta
		slowdown = move_toward(slowdown, 0.0, delta / 1.5)
		velocity.x = move_toward(velocity.x, 0.0, abs(velocity.x) * delta * 2.0)
	else:
		velocity += get_gravity() * delta
	velocity.x = clamp(velocity.x, -randf_range(1800, 2300), randf_range(1800, 2300))
	velocity.y = clamp(velocity.y, -randf_range(1800, 2300), randf_range(1800, 2300))

	move_and_slide()
	_wrap_around_camera()
