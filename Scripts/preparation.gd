extends Control


@onready var money_label: Label = %MoneyLabel
@onready var capacity_label: Label = %CapacityLabel
@onready var bait_list: VBoxContainer = %BaitList

@onready var back_button: Button = %BackButton
@onready var go_fishing_button: Button = %GoFishingButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	go_fishing_button.pressed.connect(_on_go_fishing_pressed)

	_refresh()


func _refresh() -> void:
	# Clear old generated bait rows.
	for child in bait_list.get_children():
		child.queue_free()

	money_label.text = "Money: %d mk" % GameState.money

	var loaded := GameState.get_loaded_bait_count()

	capacity_label.text = (
		"Bait pouch: %d / %d"
		% [
			loaded,
			GameState.bait_pouch_capacity
		]
	)

	# Keeping this sorted makes the UI stable between runs.
	var bait_ids := GearDatabase.BAITS.keys()
	bait_ids.sort()

	for bait_id in bait_ids:
		_create_bait_row(bait_id)

	go_fishing_button.disabled = loaded <= 0


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
	get_tree().change_scene_to_file(
		"res://Scenes/fishing/fishing.tscn"
	)
