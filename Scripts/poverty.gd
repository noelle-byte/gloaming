extends Control


@onready var title: Label = $Title
@onready var description: Label = $Description
@onready var days_survived: Label = $DaysSurvived
@onready var restart_button: Button = $RestartButton


func _ready() -> void:
	title.text = "POVERTY"
	description.text = "Voss found a more suitable tenant."
	days_survived.text = "You reached Day %d." % GameState.day

	restart_button.pressed.connect(_restart)


func _restart() -> void:
	GameState.reset_run()

	get_tree().change_scene_to_file(
		"res://Scenes/vn/morning.tscn"
	)
