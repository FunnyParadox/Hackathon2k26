extends Control

var character: CharacterBody2D

func _ready() -> void:
	character = get_node("../../Character")
	print("Character object: ", character)

func _process(_delta: float) -> void:
	queue_redraw()  # triggers _draw() every frame

func _draw() -> void:
	draw_all_debug_data(16.0, Vector2(148, 16.0))

func draw_debug_data(title: String, data: String, font_size: float, text_position: Array[Vector2]) -> void:
	var font = ThemeDB.fallback_font
	title += " : "
	draw_string(font, text_position[0] - Vector2(font.get_string_size(title).x, 0), title, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size)
	draw_string(font, text_position[0], data, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	text_position[0].y += font_size * 1.5

func draw_all_debug_data(font_size: float, position: Vector2) -> void:
	var text_position: Array[Vector2] = [Vector2(font_size, font_size) + position]
	draw_debug_data("Position", str("%0.3f / %0.3f" % [character.position.x, character.position.y]), font_size, text_position)
	draw_debug_data("Velocity", str("%0.3f / %0.3f" % [character.velocity.x, character.velocity.y]), font_size, text_position)
	draw_debug_data("Gravity", str("%03d°" % [roundi(rad_to_deg(character.gravity_angle))]), font_size, text_position)
	draw_debug_data("Airtime", str("%0.3f / %0.3f (%s)" % [character.air_time, character.COYOTE_JUMP, "O" if (character.air_time < character.COYOTE_JUMP) else "X"]), font_size, text_position)
	draw_debug_data("Jump force", str("%03d%%" % [pow(character.jump_force, 0.25) * 100]), font_size, text_position)
	draw_debug_data("Last Acc", str("%0.3f / %0.3f (%03d%%)" % [character.last_acceleration, character.ACCELERATION_LIMIT, int(min(character.last_acceleration / character.ACCELERATION_LIMIT, 1.0) * 100.0)]), font_size, text_position)
	draw_debug_data("Throwing", str("%03d%%" % [character.throwing_frames * 100.0]), font_size, text_position)
	draw_debug_data("Invincible", str("%0.3f / %0.3f (%03d%%)" % [character.invincible_frames, character.INVINCIBILITY_TIME, int(min(character.invincible_frames / character.INVINCIBILITY_TIME, 1.0) * 100.0)]), font_size, text_position)
	draw_debug_data("", "", font_size, text_position)
	draw_debug_data("Lives", str(character.lives), font_size, text_position)
	draw_debug_data("Timer", str("%0.2f" % [character.timer]), font_size, text_position)
	draw_debug_data("Collected", str("%d" % [character.collected]), font_size, text_position)
