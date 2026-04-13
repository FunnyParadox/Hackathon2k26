extends Control

var character: CharacterBody2D

func _ready() -> void:
	character = get_node("../Character")
	print("Character object: ", character)

func _process(_delta: float) -> void:
	queue_redraw()  # triggers _draw() every frame

func _draw() -> void:
	var font = ThemeDB.fallback_font
	var font_size = 16
	var text_position = Vector2(font_size, font_size)
	draw_string(font, text_position, "  Position: " + str("%0.3f / %0.3f" % [character.position.x, character.position.y]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	text_position.y += font_size * 1.5
	draw_string(font, text_position, "  Velocity: " + str("%0.3f / %0.3f" % [character.velocity.x, character.velocity.y]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	text_position.y += font_size * 1.5
	draw_string(font, text_position, "   Airtime: " + str("%0.3f / %0.3f (%s)" % [character.air_time, character.COYOTE_JUMP, "O" if (character.air_time < character.COYOTE_JUMP) else "X"]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	text_position.y += font_size * 1.5
	draw_string(font, text_position, "Jump Force: " + str("%03d%%" % [int(character.jump_force * 100.0)]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	text_position.y += font_size * 1.5
	draw_string(font, text_position, " Last Acc.: " + str("%0.3f / %0.3f (%03d%%)" % [character.last_acceleration, character.ACCELERATION_LIMIT, int(min(character.last_acceleration / character.ACCELERATION_LIMIT, 1.0) * 100.0)]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
