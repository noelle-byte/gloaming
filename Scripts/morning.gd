extends Control

var dialogue_index := 0

var dialogue := [
	{
		"speaker": "Elina",
		"text": "You're up."
	},
	{
		"speaker": "Elina",
		"text": "Anni left your gloves by the stove. She says the left one was still wet."
	},
	{
		"speaker": "Juhani",
		"text": "She checks my gear now?"
	},
	{
		"speaker": "Elina",
		"text": "Apparently I have competition."
	},
	{
		"speaker": "Elina",
		"text": "There's enough in the cupboard for today. Voss comes in three days."
	},
	{
		"speaker": "Juhani",
		"text": "I'll bring something back."
	},
	{
		"speaker": "Elina",
		"text": "Before dark?"
	},
	{
		"speaker": "Juhani",
		"text": "That's the plan."
	},
	{
		"speaker": "Elina",
		"text": "See that it stays the plan. The... dark, it's not for us."
	},
	{
		"speaker": "Elina",
		"text": "See you soon Juhani."
	}
]

@onready var speaker_label: Label = %SpeakerLabel
@onready var dialogue_label: Label = %DialogueLabel
@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	show_dialogue()


func show_dialogue() -> void:
	var line = dialogue[dialogue_index]

	speaker_label.text = line["speaker"]
	dialogue_label.text = line["text"]


func _on_continue_pressed() -> void:
	dialogue_index += 1

	if dialogue_index >= dialogue.size():
		end_conversation()
		return

	show_dialogue()


func end_conversation() -> void:
	get_tree().change_scene_to_file("res://Scenes/vn/village.tscn")
