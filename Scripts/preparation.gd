extends Control


@onready var money_label: Label = %MoneyLabel
@onready var capacity_label: Label = %CapacityLabel
@onready var bait_list: VBoxContainer = %BaitList
@onready var hint_label: Label = %HintLabel

@onready var back_button: Button = %BackButton
@onready var go_fishing_button: Button = %GoFishingButton
@onready var skip_button: Button = %SkipGloamingButton
@onready var skip_confirmation: ConfirmationDialog = %SkipConfirmation

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

	go_fishing_button.pressed.connect(
		_on_go_fishing_pressed
	)

	skip_button.pressed.connect(
		_on_skip_pressed
	)

	skip_confirmation.confirmed.connect(
		_on_skip_confirmed
	)

	_refresh()

func _create_section(title: String) -> void:
	var label := Label.new()
	label.text = title
	bait_list.add_child(label)

	var separator := HSeparator.new()
	bait_list.add_child(separator)

func _create_equipment_row(
	type: String,
	gear_id: String,
	data: Dictionary
) -> void:
	var home_amount: int = GameState.get_home_equipment_count(
		type,
		gear_id
	)

	var tackle_amount: int = (
		GameState.get_loaded_equipment_count_by_id(
			type,
			gear_id
		)
	)

	# Preparation is inventory management, not a catalogue.
	if home_amount <= 0 and tackle_amount <= 0:
		return

	var row := HBoxContainer.new()
	bait_list.add_child(row)

	var name_label := Label.new()
	name_label.text = data.get("name", gear_id)
	name_label.custom_minimum_size.x = 180
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var home_label := Label.new()
	home_label.text = "Home: %d" % home_amount
	home_label.custom_minimum_size.x = 100
	row.add_child(home_label)

	var load_button := Button.new()
	load_button.text = "→"
	load_button.disabled = (
		home_amount <= 0
		or not GameState.has_tackle_space()
	)
	load_button.pressed.connect(
		_on_load_equipment.bind(type, gear_id)
	)
	row.add_child(load_button)

	var tackle_label := Label.new()
	tackle_label.text = "Tackle: %d" % tackle_amount
	tackle_label.custom_minimum_size.x = 100
	row.add_child(tackle_label)

	var unload_button := Button.new()
	unload_button.text = "←"
	unload_button.disabled = tackle_amount <= 0
	unload_button.pressed.connect(
		_on_unload_equipment.bind(type, gear_id)
	)
	row.add_child(unload_button)


func _on_load_equipment(
	type: String,
	gear_id: String
) -> void:
	GameState.load_equipment_by_id(
		type,
		gear_id
	)
	_refresh()


func _on_unload_equipment(
	type: String,
	gear_id: String
) -> void:
	GameState.unload_equipment_by_id(
		type,
		gear_id
	)
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

	money_label.text = (
		"Money: %d mk"
		% GameState.money
	)

	capacity_label.text = (
		"Tackle box: %d / %d"
		% [
			GameState.get_tackle_slots_used(),
			GameState.tackle_capacity
		]
	)

	_create_section("BAIT")

	var bait_ids: Array = GearDatabase.BAITS.keys()
	bait_ids.sort()

	for bait_id_value in bait_ids:
		var bait_id: String = str(bait_id_value)

		var home_amount: int = GameState.get_item_count(
			bait_id
		)

		var pouch_amount: int = GameState.bait_pouch.get(
			bait_id,
			0
		)

		if home_amount <= 0 and pouch_amount <= 0:
			continue

		_create_bait_row(bait_id)


	_create_section("RODS")

	var rod_ids: Array = GearDatabase.RODS.keys()
	rod_ids.sort()

	for rod_id_value in rod_ids:
		var rod_id: String = str(rod_id_value)

		_create_equipment_row(
			"rod",
			rod_id,
			GearDatabase.get_rod(rod_id)
		)


	_create_section("HOOKS")

	var hook_ids: Array = GearDatabase.HOOKS.keys()
	hook_ids.sort()

	for hook_id_value in hook_ids:
		var hook_id: String = str(hook_id_value)

		_create_equipment_row(
			"hook",
			hook_id,
			GearDatabase.get_hook(hook_id)
		)

	_create_section("LINES")

	for line_id_value in GearDatabase.LINES.keys():
		var line_id: String = str(line_id_value)

		_create_equipment_row(
			"line",
			line_id,
			GearDatabase.get_line(line_id)
		)

	var problem: String = (
		GameState.get_fishing_loadout_problem()
	)

	go_fishing_button.disabled = problem != ""

	if problem == "":
		hint_label.text = "Ready for the gloaming."
	else:
		hint_label.text = (
			"Cannot fish: "
			+ problem
		)



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
