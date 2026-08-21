extends Control


var dialogue_index := 0

var dialogue := [
	{
		"speaker": "Ilari",
		"text": "Going to the lake?"
	},
	{
		"speaker": "Juhani",
		"text": "Eventually."
	},
	{
		"speaker": "Ilari",
		"text": "Eventually is an unfortunate time to begin."
	},
	{
		"speaker": "Juhani",
		"text": "I've still got daylight."
	},
	{
		"speaker": "Ilari",
		"text": "Then use daylight."
	},
	{
		"speaker": "Juhani",
		"text": "You sound like Marek."
	},
	{
		"speaker": "Ilari",
		"text": " As Marek knows fish, I know fishermen."
	},
	{
		"speaker": "Ilari",
		"text": "When the light begins to fail, go home."
	},
	{
		"speaker": "Juhani",
		"text": "I know."
	},
	{
		"speaker": "Ilari",
		"text": "Ensure you follow through on that knowledge."
	}
]


@onready var speaker_label: Label = %SpeakerLabel
@onready var dialogue_label: Label = %DialogueLabel
@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	continue_button.pressed.connect(
		_on_continue_pressed
	)

	_show_dialogue()


func _show_dialogue() -> void:
	var line: Dictionary = dialogue[dialogue_index]

	speaker_label.text = line["speaker"]
	dialogue_label.text = line["text"]


func _on_continue_pressed() -> void:
	dialogue_index += 1

	if dialogue_index >= dialogue.size():
		_end_conversation()
		return

	_show_dialogue()


func _end_conversation() -> void:
	if GameState.day == 1:
		GameState.mark_day_1_visit("ilari")

	get_tree().change_scene_to_file(
		"res://Scenes/vn/village.tscn"
	)
