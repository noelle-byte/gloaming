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

	if GameState.day == 1:
		_show_dialogue()
		return

	if GameState.rent_is_due():
		_show_rent_dialogue()
	else:
		dialogue = [
			{
				"speaker": "Voss",
				"text": "Halme."
			},
			{
				"speaker": "Juhani",
				"text": "Mr Voss."
			}
		]

		_show_dialogue()

func _show_rent_dialogue() -> void:
	if GameState.can_pay_rent():
		var amount := GameState.current_rent

		GameState.pay_rent()

		dialogue = [
			{
				"speaker": "Voss",
				"text": "%d markka." % amount
			},
			{
				"speaker": "Juhani",
				"text": "There."
			},
			{
				"speaker": "Voss",
				"text": "As agreed."
			}
		]

	else:
		var missing := (
			GameState.current_rent
			- GameState.money
		)

		if GameState.rent_delays == 0:
			GameState.request_rent_extension()

			dialogue = [
				{
					"speaker": "Voss",
					"text": "You're %d markka short." % missing
				},
				{
					"speaker": "Juhani",
					"text": "Tomorrow."
				},
				{
					"speaker": "Voss",
					"text": "Tomorrow, then. I expect extra for the extension."
				}
			]

		elif GameState.rent_delays == 1:
			GameState.request_rent_extension()

			dialogue = [
				{
					"speaker": "Voss",
					"text": "Still short."
				},
				{
					"speaker": "Juhani",
					"text": "One more day."
				},
				{
					"speaker": "Voss",
					"text": "This is the last time I will give you this kindness."
				},
				{
					"speaker": "Voss",
					"text": "Pay tomorrow. If this happens again, I will find a more suitable tenant."
				}
			]

		else:
			_trigger_poverty()
			return

	_show_dialogue()

func _trigger_poverty() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/endings/poverty.tscn"
	)

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
