extends CharacterBody2D

var sprite: Sprite2D
var player: CharacterBody2D = null
var camera: Camera2D = null

const FLY_SPEED = 180.0
var killed := false
var flip := 0
var flip_timer := 0.0
var direction := -1
var activated := false

const TrashScene = preload("res://instances/trash.tscn")

func _ready() -> void:
	sprite = get_node("Sprite2D")
	add_to_group("enemies")
	# Disable gravity by setting motion mode to floating
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func _find_player() -> void:
	var root = get_tree().current_scene
	for child in root.get_children():
		if child is CharacterBody2D and child != self and not child.is_in_group("enemies"):
			player = child
		if child is Camera2D:
			camera = child

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
		var base_angle = (TAU / 10.0) * i + randf_range(-0.2, 0.2)
		var speed = randf_range(400.0, 1600.0)
		trash.velocity = Vector2(cos(base_angle) * speed * 0.3, sin(base_angle) * speed * 0.55 - 350.0)
		trash.only_down = false
		get_tree().current_scene.add_child(trash)

func _process(delta: float) -> void:
	if killed:
		queue_free()
		return

	# Animate sprite frames
	flip_timer += delta
	if flip_timer > 0.15:
		flip_timer = 0.0
		flip += 1
		flip %= 4

	# Wing flapping animation using the same BadGuy textures
	if ((flip >> 1) & 1):
		sprite.texture = preload("res://sprites/BadGuy1.png") if (flip & 1) else preload("res://sprites/BadGuy2.png")
	else:
		sprite.texture = preload("res://sprites/BadGuy3.png") if (flip & 1) else preload("res://sprites/BadGuy4.png")

	# Face the player
	if player and is_instance_valid(player):
		sprite.flip_h = player.global_position.x < global_position.x

func _is_in_camera_x_view() -> bool:
	if camera == null or not is_instance_valid(camera):
		return false
	var visible_width = camera.get_viewport_rect().size.x / camera.zoom.x
	var cam_left = camera.global_position.x - visible_width / 2
	var cam_right = camera.global_position.x + visible_width / 2
	return global_position.x >= cam_left and global_position.x <= cam_right

func _physics_process(delta: float) -> void:
	if killed:
		return

	# Find the player/camera if we don't have references yet
	if player == null or not is_instance_valid(player) or camera == null:
		_find_player()

	# Only fly when inside the camera's horizontal view
	if not activated:
		if _is_in_camera_x_view():
			activated = true
		else:
			return

	if player and is_instance_valid(player):
		# Fly toward the player
		var to_player = (player.global_position - global_position).normalized()
		velocity = to_player * FLY_SPEED
	else:
		velocity = Vector2(-FLY_SPEED, 0)

	move_and_slide()
