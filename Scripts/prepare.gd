extends Control

func _on_go_fishing_pressed() -> void:
	GameState.forfeit_day_actions()

	get_tree().change_scene_to_file(
		"res://Scenes/fishing/fishing.tscn"
	)
