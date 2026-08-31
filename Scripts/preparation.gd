extends Control


@onready var money_label: Label = %MoneyLabel
@onready var capacity_label: Label = %CapacityLabel
@onready var bait_list: VBoxContainer = %BaitList
@onready var hint_label: Label = %HintLabel

@onready var back_button: Button = %BackButton
@onready var go_fishing_button: Button = %GoFishingButton
@onready var skip_button: Button = %SkipGloamingButton

var skip_confirmation: ConfirmationDialog

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	go_fishing_button.pressed.connect(_on_go_fishing_pressed)

	skip_button.pressed.connect(
	_on_skip_pressed
)

	skip_confirmation = ConfirmationDialog.new()
	skip_confirmation.title = "Skip the Gloaming?"
	skip_confirmation.dialog_text = (
		"Return home without fishing?\n"
		+ "Any remaining daytime will be lost."
	)
	skip_confirmation.ok_button_text = "Go Home"

	skip_confirmation.confirmed.connect(
		_on_skip_confirmed
	)

	add_child(skip_confirmation)

	_refresh()

func _on_skip_pressed() -> void:
	skip_confirmation.popup_centered()


func _on_skip_confirmed() -> void:
	GameState.forfeit_day_actions()

	get_tree().change_scene_to_file(
		"res://Scenes/vn/night.tscn"
	)


func _refresh() -> void:
	for child in bait_list.get_children():
		child.queue_free()

	money_label.text = "Money: %d mk" % GameState.money

	var loaded := GameState.get_loaded_bait_count()

	capacity_label.text = (
		"Tackle box: %d / %d"
		% [
			GameState.get_tackle_slots_used(),
			GameState.tackle_capacity
		]
	)

	var bait_ids := GearDatabase.BAITS.keys()
	bait_ids.sort()

	for bait_id in bait_ids:
		_create_bait_row(bait_id)

	var problem := GameState.get_fishing_loadout_problem()

	go_fishing_button.disabled = problem != ""

	if problem == "":
		hint_label.text = "Ready for the gloaming."
	else:
		hint_label.text = "Cannot fish: " + problem

func _create_bait_row(bait_id: String) -> void:
	var bait: Dictionary = GearDatabase.get_bait(bait_id)

	var house_amount := GameState.get_item_count(bait_id)
	var pouch_amount: int = GameState.bait_pouch.get(
		bait_id,
		0
	)

	var row := HBoxContainer.new()
	bait_list.add_child(row)

	# ------------------------------
	# Name
	# ------------------------------

	var name_label := Label.new()
	name_label.text = bait.get("name", bait_id)
	name_label.custom_minimum_size.x = 180.0
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	row.add_child(name_label)

	# ------------------------------
	# House inventory
	# ------------------------------

	var house_label := Label.new()
	house_label.text = "Home: %d" % house_amount
	house_label.custom_minimum_size.x = 100.0

	row.add_child(house_label)

	# ------------------------------
	# Load button
	# ------------------------------

	var load_button := Button.new()
	load_button.text = "→"

	load_button.disabled = (
		house_amount <= 0
		or not GameState.can_load_more_bait()
	)

	load_button.pressed.connect(
		_on_load_bait.bind(bait_id)
	)

	row.add_child(load_button)

	# ------------------------------
	# Pouch amount
	# ------------------------------

	var pouch_label := Label.new()
	pouch_label.text = "Pouch: %d" % pouch_amount
	pouch_label.custom_minimum_size.x = 100.0

	row.add_child(pouch_label)

	# ------------------------------
	# Unload button
	# ------------------------------

	var unload_button := Button.new()
	unload_button.text = "←"
	unload_button.disabled = pouch_amount <= 0

	unload_button.pressed.connect(
		_on_unload_bait.bind(bait_id)
	)

	row.add_child(unload_button)


func _on_load_bait(bait_id: String) -> void:
	GameState.load_bait(bait_id)
	_refresh()


func _on_unload_bait(bait_id: String) -> void:
	GameState.unload_bait(bait_id)
	_refresh()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/vn/village.tscn"
	)


func _on_go_fishing_pressed() -> void:
	GameState.forfeit_day_actions()

	get_tree().change_scene_to_file(
		"res://Scenes/fishing/fishing.tscn"
	)
