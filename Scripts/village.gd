extends Control


@onready var visit_marek: Button = %VisitMarek
@onready var visit_aarne: Button = %VisitAarne
@onready var visit_ilari: Button = %VisitIlari
@onready var visit_voss: Button = %VisitVoss
@onready var prepare_button: Button = %PrepareForFishing
@onready var tutorial_status: Label = %TutorialStatus
@onready var visit_aino: Button = %VisitAino
@onready var time_label: Label = %TimeLabel

func _ready() -> void:
	visit_marek.pressed.connect(
		_visit_person.bind(
			"res://Scenes/vn/marek_shop.tscn"
		)
	)

	visit_aarne.pressed.connect(
		_visit_person.bind(
			"res://Scenes/vn/aarne.tscn"
		)
	)

	visit_ilari.pressed.connect(
		_visit_person.bind(
			"res://Scenes/vn/ilari.tscn"
		)
	)

	visit_voss.pressed.connect(
		_visit_voss
	)

	visit_aino.pressed.connect(
		_visit_person.bind(
			"res://Scenes/vn/aino_market.tscn"
		)
	)
	
	prepare_button.pressed.connect(
		_go_to_preparation
	)

	_refresh()

func _visit_voss() -> void:
	if not GameState.spend_day_action():
		return

	GameState.visited_voss_today = true

	get_tree().change_scene_to_file(
		"res://Scenes/vn/voss.tscn"
	)

func _go_to_preparation() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/vn/preparation.tscn"
	)

func _visit_person(scene_path: String) -> void:
	if not GameState.spend_day_action():
		return

	get_tree().change_scene_to_file(
		scene_path
	)

func _refresh_time() -> void:
	if GameState.day == 1:
		time_label.text = "Tutorial Day"
		return

	var filled := ""
	var empty := ""

	for i in range(GameState.max_day_actions):
		if i < GameState.day_actions_remaining:
			filled += "● "
		else:
			empty += "○ "

	time_label.text = "Time: " + filled + empty

func _refresh_action_buttons() -> void:
	var has_time := GameState.can_spend_day_action()

	visit_marek.disabled = not has_time
	visit_aarne.disabled = not has_time
	visit_ilari.disabled = not has_time
	visit_voss.disabled = not has_time
	visit_aino.disabled = not has_time

func _refresh() -> void:
	_refresh_time()

	if GameState.day != 1:
		_refresh_action_buttons()

		prepare_button.disabled = false
		tutorial_status.text = ""
		return

	# Existing Day 1 tutorial code below...

	_update_visit_button(
		visit_marek,
		"Marek's Fishing Supplies",
		"marek"
	)

	_update_visit_button(
		visit_aarne,
		"Doctor Vasko",
		"aarne"
	)

	_update_visit_button(
		visit_ilari,
		"Father Ilari",
		"ilari"
	)

	_update_visit_button(
		visit_voss,
		"Voss",
		"voss"
	)

	_update_visit_button(
	visit_aino,
	"Aino's Fish Market",
	"aino"
)


	var complete := GameState.day_1_visits_complete()

	prepare_button.disabled = not complete

	if complete:
		tutorial_status.text = (
			"The afternoon is nearly gone."
		)
	else:
		tutorial_status.text = (
			"You still have business in the village."
		)


func _update_visit_button(
	button: Button,
	display_name: String,
	person_id: String
) -> void:

	if GameState.has_visited_day_1(person_id):
		button.text = display_name + " ✓"
	else:
		button.text = display_name
