extends Control

var character: CharacterBody2D
var level: Node2D

var finish_timer := 0.0
var death_timer := 0.0

var font = ThemeDB.fallback_font

var enemies_count: int
var collectibles_count: int
var all_trash: int = 9999

func _ready() -> void:
	var audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.stream = preload("res://sounds/Ecodash_Music.wav")
	audio_player.play()

	character = get_node("../../Character")
	level = get_node("../../Level")

	enemies_count = get_tree().get_nodes_in_group("enemies").size()
	collectibles_count = get_tree().get_nodes_in_group("collectible").size()
	all_trash = enemies_count * 12 + collectibles_count

	print("Character object: ", character)

func _process(delta: float) -> void:
	if (character.collected >= all_trash):
		finish_timer += delta
	if (!character):
		death_timer += delta
	queue_redraw()  # triggers _draw() every frame
	if (death_timer > 3.0 or Input.is_action_just_pressed("ui_cancel")):
		get_tree().change_scene_to_file("res://main.tscn")
	if (finish_timer > 3.0 or Input.is_action_just_pressed("ui_graph_delete")):
		kd.player_time = character.timer
		get_tree().change_scene_to_file("res://end_screen.tscn")

func _draw() -> void:
	if (death_timer > 0.0):
		var text: String = " RESETTING THE LEVEL IN %01.2f " % [3.0 - death_timer]
		var rect: Rect2
		rect.position = (get_viewport_rect().size - font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 64)) / 2
		rect.position.y -= font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 64).y / 1.5
		rect.size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 64)
		draw_rect(rect, Color.DARK_BLUE, true)
		draw_string(font, (get_viewport_rect().size - font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 64)) / 2, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 64)
	
	draw_all_debug_data(32.0, Vector2(32, 32.0))

func draw_debug_data(title: String, data: String, font_size: float, text_position: Array[Vector2]) -> void:
	var rect: Rect2
	rect.position = text_position[0] - font.get_string_size(title, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size)
	rect.size = font.get_string_size(title, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size)
	rect.size.x += font.get_string_size(data, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size).x
	rect.size.y *= 1.1
	draw_rect(rect, Color.DARK_BLUE, true)
	draw_string(font, text_position[0] - Vector2(font.get_string_size(title, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size).x, 0), title, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size)
	draw_string(font, text_position[0], data, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	text_position[0].y += font_size * 1.5

func draw_all_debug_data(font_size: float, position: Vector2) -> void:
	if (!character): return
	var text_position: Array[Vector2] = [Vector2(font_size, font_size) + position]
	if 0 == 1:
		draw_debug_data("Position", str("%0.3f / %0.3f" % [character.position.x, character.position.y]), font_size, text_position)
		draw_debug_data("Velocity", str("%0.3f / %0.3f" % [character.velocity.x, character.velocity.y]), font_size, text_position)
		draw_debug_data("Gravity", str("%03d°" % [roundi(rad_to_deg(character.gravity_angle))]), font_size, text_position)
		draw_debug_data("Airtime", str("%0.3f / %0.3f (%s)" % [character.air_time, character.COYOTE_JUMP, "O" if (character.air_time < character.COYOTE_JUMP) else "X"]), font_size, text_position)
		draw_debug_data("Jump force", str("%03d%%" % [pow(character.jump_force, 0.25) * 100]), font_size, text_position)
		draw_debug_data("Last Acc", str("%0.3f / %0.3f (%03d%%)" % [character.last_acceleration, character.ACCELERATION_LIMIT, int(min(character.last_acceleration / character.ACCELERATION_LIMIT, 1.0) * 100.0)]), font_size, text_position)
		draw_debug_data("Throwing", str("%03d%%" % [character.throwing_frames * 100.0]), font_size, text_position)
		draw_debug_data("Invincible", str("%0.3f / %0.3f (%03d%%)" % [character.invincible_frames, character.INVINCIBILITY_TIME, int(min(character.invincible_frames / character.INVINCIBILITY_TIME, 1.0) * 100.0)]), font_size, text_position)
		draw_debug_data("", "", font_size, text_position)
	draw_debug_data(" ", str("%d lives left " % [character.lives]), font_size, text_position)
	draw_debug_data(" ", str("Time: %0.2f " % [character.timer]), font_size, text_position)
	draw_debug_data(" ", str("%d trash collected out of %d " % [character.collected, all_trash]), font_size, text_position)
