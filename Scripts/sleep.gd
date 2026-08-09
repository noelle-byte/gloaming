extends Control

func _on_pressed() -> void:
	GameState.next_day()
	get_tree().change_scene_to_file("res://Scenes/vn/morning.tscn")
