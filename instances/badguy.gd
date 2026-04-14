extends CharacterBody2D

var sprite: Sprite2D

const SPEED = 100.0
const JUMP_VELOCITY = -160.0

var flip := 0
var direction := -1
var change_dir := 0.0
var killed := false

const TrashScene = preload("res://instances/trash.tscn")

func _ready() -> void:
	sprite = get_node("Sprite2D")
	add_to_group("enemies")

func kill() -> void:
	killed = true
	set_collision_layer(0)
	set_collision_mask(0)
	remove_from_group("enemies")
	_spawn_trash()

func _spawn_trash() -> void:
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

func _process(delta: float) -> void:
	if killed:
		queue_free()
		return
	if is_on_floor():
		rotation_degrees = move_toward(rotation_degrees, 0.0, delta * 160.0)
	else:
		rotation_degrees += delta * 160.0 * direction
	
	if ((flip >> 1) & 1):
		sprite.texture = preload("res://sprites/BadGuy1.png") if (rotation > direction) else preload("res://sprites/BadGuy2.png")
	else:
		sprite.texture = preload("res://sprites/BadGuy3.png") if (rotation > direction) else preload("res://sprites/BadGuy4.png")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		direction = -direction
		flip += 1
		flip %= 3
	else:
		velocity += get_gravity() * delta

	move_and_slide()
