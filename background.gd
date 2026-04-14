extends ParallaxBackground

func _ready() -> void:
	for layer in get_children():
		if layer is ParallaxLayer:
			for child in layer.get_children():
				if child is Sprite2D and child.texture:
					layer.motion_mirroring.x = child.texture.get_width() * abs(child.scale.x)
