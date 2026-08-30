extends Control


const DAY_1_DIALOGUE := [
	{
		"speaker": "Elina",
		"text": "You're late."
	},
	{
		"speaker": "Juhani",
		"text": "I know."
	},
	{
		"speaker": "Elina",
		"text": "You said you'd be back before dark."
	},
	{
		"speaker": "Juhani",
		"text": "That was the plan."
	},
	{
		"speaker": "Elina",
		"text": "What happened?"
	},
	{
		"speaker": "Juhani",
		"text": "The village took longer than I thought. By the time I reached the lake, the light was already going."
	},
	{
		"speaker": "Elina",
		"text": "Then you should have come home."
	},
	{
		"speaker": "Juhani",
		"text": "And lose the whole day?"
	},
	{
		"speaker": "Elina",
		"text": "Juhani."
	},
	{
		"speaker": "Juhani",
		"text": "Voss comes in three days. We needed the catch."
	},
	{
		"speaker": "Elina",
		"text": "So you stayed."
	},
	{
		"speaker": "Juhani",
		"text": "One cast became another, and I.. I didn't realise how late it had gotten."
	},
	{
		"speaker": "Elina",
		"text": "You fished the gloaming."
	},
	{
		"speaker": "Juhani",
		"text": "I fished late. I didn't go out there for the gloaming."
	},
	{
		"speaker": "Elina",
		"text": "The lake won't care why."
	},
	{
		"speaker": "Juhani",
		"text": "Neither will Voss."
	},
	{
		"speaker": "Elina",
		"text": "...No. I suppose he won't."
	},
	{
		"speaker": "Elina",
		"text": "What did you bring home?"
	}
]


const GENERIC_DIALOGUE := [
	{
		"speaker": "Elina",
		"text": "You're back."
	},
	{
		"speaker": "Juhani",
		"text": "I'm back."
	},
	{
		"speaker": "Elina",
		"text": "What did you bring home?"
	}
]


@onready var speaker_label: Label = %SpeakerLabel
@onready var dialogue_label: Label = %DialogueLabel
@onready var continue_button: Button = %ContinueButton

@onready var catch_panel: Control = %CatchPanel
@onready var catch_summary_label: Label = %CatchSummaryLabel
@onready var total_value_label: Label = %TotalValueLabel
@onready var sleep_button: Button = %SleepButton


var dialogue: Array = []
var dialogue_index := 0


func _ready() -> void:
	if GameState.day == 1:
		dialogue = DAY_1_DIALOGUE
	else:
		dialogue = GENERIC_DIALOGUE

	continue_button.pressed.connect(
		_on_continue_pressed
	)


	sleep_button.pressed.connect(
		_on_sleep_pressed
	)

	catch_panel.hide()

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
	continue_button.hide()

	_show_catches()


func _show_catches() -> void:
	catch_panel.show()

	var fish_counts: Dictionary = {}

	for fish in GameState.catches:
		var fish_name: String = fish["name"]

		fish_counts[fish_name] = (
			fish_counts.get(fish_name, 0)
			+ 1
		)

	if fish_counts.is_empty():
		catch_summary_label.text = "Nothing."
	else:
		var lines: Array[String] = []

		var fish_names := fish_counts.keys()
		fish_names.sort()

		for fish_name in fish_names:
			lines.append(
				"%s ×%d" % [
					fish_name,
					fish_counts[fish_name]
				]
			)

		catch_summary_label.text = "\n".join(lines)

	total_value_label.text = (
		"%d fish brought home."
		% GameState.catches.size()
	)


func _on_sleep_pressed() -> void:
	GameState.next_day()

	get_tree().change_scene_to_file(
		"res://Scenes/vn/morning.tscn"
	)
