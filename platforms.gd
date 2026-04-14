@tool
extends Node2D

func _process(_delta: float) -> void:
	for child in get_children():
		if child is StaticBody2D and child.name.begins_with("Platform2D"):
			var body := child.get_node_or_null("Body") as Polygon2D
			var col := child.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
			if not col:
				continue
			if not body:
				body = Polygon2D.new()
				body.name = "Body"
				body.texture = preload("res://sprites/4xGrayTexture.png")
				body.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
				child.add_child(body)
				body.owner = owner if owner else self
			if body.polygon != col.polygon:
				body.polygon = col.polygon
			if body.position != col.position:
				body.position = col.position
