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
	if (
		GameState.day > 1
		and GameState.rent_is_due()
		and not GameState.visited_voss_today
	):
		if _handle_voss_collection():
			return

	if GameState.day == 1:
		dialogue = DAY_1_DIALOGUE
	else:
		dialogue = GENERIC_DIALOGUE

	_continue_setup()

func _continue_setup() -> void:
	continue_button.pressed.connect(
		_on_continue_pressed
	)

	sleep_button.pressed.connect(
		_on_sleep_pressed
	)

	catch_panel.hide()
	_show_dialogue()


func _handle_voss_collection() -> bool:
	GameState.add_collection_fee()

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
				"text": "You could have waited until morning."
			},
			{
				"speaker": "Voss",
				"text": "You could have come to my office."
			}
		]

		_continue_setup()
		return true

	if GameState.rent_delays >= 2:
		get_tree().change_scene_to_file(
			"res://Scenes/endings/poverty.tscn"
		)
		return true

	GameState.request_rent_extension()

	dialogue = [
		{
			"speaker": "Voss",
			"text": "You weren't at my office."
		},
		{
			"speaker": "Juhani",
			"text": "I don't have it."
		},
		{
			"speaker": "Voss",
			"text": "Tomorrow, then. This will cost you."
		}
	]

	_continue_setup()
	return true

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

	var fish_rows: Dictionary = {}

	for fish in GameState.catches:
		var fish_name: String = fish["name"]

		if not fish_rows.has(fish_name):
			fish_rows[fish_name] = {
				"count": 0,
				"value": 0
			}

		fish_rows[fish_name]["count"] += 1
		fish_rows[fish_name]["value"] += int(
			fish["value"]
		)

	if fish_rows.is_empty():
		catch_summary_label.text = "Nothing."
	else:
		var lines: Array[String] = []
		var fish_names := fish_rows.keys()
		fish_names.sort()

		for fish_name in fish_names:
			var row: Dictionary = fish_rows[fish_name]

			lines.append(
				"%s ×%d — %d mk" % [
					fish_name,
					row["count"],
					row["value"]
				]
			)

		catch_summary_label.text = "\n".join(lines)

	total_value_label.text = (
		"Stored value: %d mk"
		% GameState.get_total_catch_value()
	)


func _on_sleep_pressed() -> void:
	GameState.next_day()

	get_tree().change_scene_to_file(
		"res://Scenes/vn/morning.tscn"
	)
