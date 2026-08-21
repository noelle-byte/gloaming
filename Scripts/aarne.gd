extends Control


var dialogue_index := 0

var dialogue := [
	{
		"speaker": "Aarne",
		"text": "Juhani! Come in. Please tell me you're here to talk and not to bleed on anything."
	},
	{
		"speaker": "Juhani",
		"text": "Just passing through."
	},
	{
		"speaker": "Aarne",
		"text": "Excellent. Conversation is cheaper than bandages."
	},
	{
		"speaker": "Juhani",
		"text": "Business slow?"
	},
	{
		"speaker": "Aarne",
		"text": "For a doctor in winter? Never. People spend nine months pretending they're indestructible, then suddenly its cold reminds and my office is filled."
	},
	{
		"speaker": "Juhani",
		"text": "Cheerful."
	},
	{
		"speaker": "Aarne",
		"text": "I considered putting the worst cases in the window. Good advertising."
	},
	{
		"speaker": "Aarne",
		"text": "But seriously, if Elina or either of the children falls ill, bring them to me early."
	},
	{
		"speaker": "Aarne",
		"text": "Most things are easier to treat before somebody decides they'll sleep it off."
	},
	{
		"speaker": "Juhani",
		"text": "I'll remember."
	},
	{
		"speaker": "Aarne",
		"text": "Good. And if you insist on spending winter standing over a hole in the ice, try not to give me additional work."
	},
	{
		"speaker": "Juhani",
		"text": "No promises."
	},
	{
		"speaker": "Aarne",
		"text": "Your more honest than most Mr Halme."
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
		GameState.mark_day_1_visit("aarne")

	get_tree().change_scene_to_file(
		"res://Scenes/vn/village.tscn"
	)
