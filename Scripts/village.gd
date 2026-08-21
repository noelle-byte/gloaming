extends Control


@onready var visit_marek: Button = %VisitMarek
@onready var visit_aarne: Button = %VisitAarne
@onready var visit_ilari: Button = %VisitIlari
@onready var visit_voss: Button = %VisitVoss
@onready var prepare_button: Button = %PrepareForFishing
@onready var tutorial_status: Label = %TutorialStatus
@onready var visit_aino: Button = %VisitAino


func _ready() -> void:
	visit_aarne.pressed.connect(_visit_aarne)
	visit_ilari.pressed.connect(_visit_ilari)
	visit_voss.pressed.connect(_visit_voss)
	visit_aino.pressed.connect(_visit_aino)

	_refresh()


func _refresh() -> void:
	if GameState.day != 1:
		prepare_button.disabled = false
		tutorial_status.text = ""
		return

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


func _visit_aarne() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/vn/aarne.tscn"
	)


func _visit_ilari() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/vn/ilari.tscn"
	)


func _visit_voss() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/vn/voss.tscn"
	)

func _visit_aino() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/vn/aino_market.tscn"
	)
