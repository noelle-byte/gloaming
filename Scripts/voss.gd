extends Control


var dialogue_index := 0

var dialogue := [
	{
		"speaker": "Voss",
		"text": "Juhani Halme."
	},
	{
		"speaker": "Juhani",
		"text": "Mr Voss."
	},
	{
		"speaker": "Voss",
		"text": "Three days."
	},
	{
		"speaker": "Juhani",
		"text": "I remember."
	},
	{
		"speaker": "Voss",
		"text": "Of course. I find reminders most useful for things people already remember."
	},
	{
		"speaker": "Juhani",
		"text": "You'll have it."
	},
	{
		"speaker": "Voss",
		"text": "I expect I will."
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
		GameState.mark_day_1_visit("voss")

	get_tree().change_scene_to_file(
		"res://Scenes/vn/village.tscn"
	)
