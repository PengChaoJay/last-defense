extends SceneTree

func _initialize() -> void:
	for path in [
		"res://assets/sprites/generated/player-robot-v1.png",
		"res://assets/sprites/generated/enemy-normal-v1.png",
		"res://assets/sprites/generated/enemy-heavy-v1.png",
		"res://assets/sprites/generated/boss-titan-v1.png",
		"res://assets/sprites/generated/energy-core-v1.png"
	]:
		var image := Image.load_from_file(path)
		print(path, " size=", image.get_size(), " alpha=", image.detect_alpha(), " used=", image.get_used_rect(), " corner_alpha=", image.get_pixel(0, 0).a)
	quit()
