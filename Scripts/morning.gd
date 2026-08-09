extends Control

var dialogue_index := 0

var dialogue := [
	{
		"speaker": "Marta",
		"text": "You're awake."
	},
	{
		"speaker": "Marta",
		"text": "There's enough food left for today."
	},
	{
		"speaker": "Marta",
		"text": "But Tomas is getting worse."
	},
	{
		"speaker": "Marta",
		"text": "The doctor says the medicine will cost twelve pounds."
	}
]

@onready var speaker_label: Label = %Speaker
@onready var dialogue_label: Label = %Dialogue
@onready var continue_button: Button = %Continue


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
