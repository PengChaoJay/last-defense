extends SceneTree

const FILES := [
	"player-robot-v1.png",
	"enemy-normal-v1.png",
	"enemy-heavy-v1.png",
	"boss-titan-v1.png",
	"energy-core-v1.png"
]

func _initialize() -> void:
	for file_name in FILES:
		var asset_name: String = file_name
		var source_path: String = "res://assets/sprites/generated/" + asset_name
		var image: Image = Image.load_from_file(source_path)
		var side: int = min(image.get_width(), image.get_height())
		var offset := Vector2i((image.get_width() - side) / 2, (image.get_height() - side) / 2)
		var square: Image = image.get_region(Rect2i(offset, Vector2i(side, side)))
		square.resize(256, 256, Image.INTERPOLATE_LANCZOS)
		var output_path: String = "res://assets/sprites/generated/" + asset_name.replace("-v1.png", "-game-v1.png")
		var error: Error = square.save_png(output_path)
		if error != OK:
			push_error("Failed to save " + output_path)
		else:
			print("Prepared ", output_path)
	quit()
