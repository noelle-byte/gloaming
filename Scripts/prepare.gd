extends Control


func _on_go_fishing_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/vn/preparation.tscn"
	)
