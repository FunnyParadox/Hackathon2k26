extends Camera2D

const CAMERA_SPEED := 3.0
const ZOOM_SPEED := 4./9.
const ZOOM_DEFAULT := Vector2(1.3, 1.3)
const ZOOM_MIN := Vector2(0.8, 0.8)  # zoomed out at max speed

var character: CharacterBody2D

func _ready() -> void:
	character = get_node("../Character")

func _process(delta: float) -> void:
	if (!character): return
	global_position = lerp(global_position, character.global_position, delta * CAMERA_SPEED)

	var speed_ratio: float = character.velocity.length() / character.MAX_SPEED
	var target_zoom := ZOOM_DEFAULT.lerp(ZOOM_MIN, clamp(speed_ratio, 0.0, 1.0))
	zoom = zoom.lerp(target_zoom, delta * ZOOM_SPEED)
	
	var visible_size = get_viewport_rect().size / zoom
	if (global_position.x - visible_size.x / 2 < 0):
		global_position.x -= global_position.x - visible_size.x / 2
	if (global_position.y + visible_size.y / 2 > 0):
		global_position.y -= global_position.y + visible_size.y / 2
