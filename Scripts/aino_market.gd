extends Control


@onready var money_label: Label = %MoneyLabel
@onready var speaker_label: Label = %SpeakerLabel
@onready var dialogue_label: Label = %DialogueLabel
@onready var leave_button: Button = %LeaveButton


func _ready() -> void:
	money_label.text = "%d mk" % GameState.money

	speaker_label.text = "Aino"
	dialogue_label.text = (
		"Juhani! I was beginning to think "
		+ "you'd decided to eat your own catch."
	)

	leave_button.pressed.connect(_on_leave_pressed)

	if GameState.day == 1:
		GameState.mark_day_1_visit("aino")


func _on_leave_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/vn/village.tscn"
	)
