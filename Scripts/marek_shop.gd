extends Control


@onready var money_label: Label = %MoneyLabel
@onready var item_list: VBoxContainer = %ItemList

@onready var speaker_label: Label = %SpeakerLabel
@onready var dialogue_label: Label = %DialogueLabel

@onready var leave_button: Button = %LeaveButton


func _ready() -> void:
	leave_button.pressed.connect(_on_leave_pressed)

	speaker_label.text = "Marek"
	dialogue_label.text = "Anything you need?"

	_refresh_shop()


func _refresh_shop() -> void:
	for child in item_list.get_children():
		child.queue_free()

	money_label.text = "%d mk" % GameState.money

	_create_section("BAIT")

	for bait_id in GearDatabase.BAITS:
		_create_bait_row(bait_id)

	_create_section("RODS")

	for rod_id in GearDatabase.RODS:
		if rod_id == "old_ash":
			continue

		_create_rod_row(rod_id)


func _create_section(title: String) -> void:
	var label := Label.new()
	label.text = title

	item_list.add_child(label)

	var separator := HSeparator.new()
	item_list.add_child(separator)


func _create_bait_row(bait_id: String) -> void:
	var bait: Dictionary = GearDatabase.get_bait(bait_id)

	var price: int = bait.get("price", 0)
	var owned := GameState.get_item_count(bait_id)

	var row := HBoxContainer.new()
	item_list.add_child(row)

	var label := Label.new()

	label.text = "%s    %d mk    Owned: %d" % [
		bait.get("name", bait_id),
		price,
		owned
	]

	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	row.add_child(label)

	var buy_button := Button.new()
	buy_button.text = "Buy"

	buy_button.disabled = not GameState.can_afford(price)

	buy_button.pressed.connect(
		_buy_bait.bind(bait_id)
	)

	row.add_child(buy_button)


func _create_rod_row(rod_id: String) -> void:
	var rod: Dictionary = GearDatabase.get_rod(rod_id)

	var price: int = rod.get("price", 0)

	var row := HBoxContainer.new()
	item_list.add_child(row)

	var label := Label.new()

	label.text = "%s    %d mk" % [
		rod.get("name", rod_id),
		price
	]

	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	row.add_child(label)

	var buy_button := Button.new()

	if GameState.owns_rod(rod_id):
		buy_button.text = "Owned"
		buy_button.disabled = true

	else:
		buy_button.text = "Buy"
		buy_button.disabled = (
			not GameState.can_afford(price)
		)

		buy_button.pressed.connect(
			_buy_rod.bind(rod_id)
		)

	row.add_child(buy_button)


func _buy_bait(bait_id: String) -> void:
	var bait: Dictionary = GearDatabase.get_bait(bait_id)

	var price: int = bait.get("price", 0)

	if not GameState.spend_money(price):
		_set_dialogue(
			"You're short."
		)
		return

	GameState.add_item(bait_id)

	_set_dialogue(
		_get_bait_purchase_line(bait_id)
	)

	_refresh_shop()


func _buy_rod(rod_id: String) -> void:
	var rod: Dictionary = GearDatabase.get_rod(rod_id)

	var price: int = rod.get("price", 0)

	if GameState.owns_rod(rod_id):
		return

	if not GameState.spend_money(price):
		_set_dialogue(
			"Put it back, Juhani."
		)
		return

	GameState.add_rod(rod_id)

	_set_dialogue(
		_get_rod_purchase_line(rod_id)
	)

	_refresh_shop()


func _get_bait_purchase_line(
	bait_id: String
) -> String:

	match bait_id:
		"worms":
			return "Nothing clever about worms. That's why they work."

		"cut_bait":
			return "Keep it cold until you use it."

		"offal":
			return "You'll smell that before the fish do."

		_:
			return "There you are."


func _get_rod_purchase_line(
	rod_id: String
) -> String:

	match rod_id:
		"willow":
			return "Quick little thing. Don't blame me if your hands are quicker than your head."

		"braced_oak":
			return "Heavy. That's the point."

		"split_cane":
			return "Look after it. I don't keep many."

		_:
			return "Good rod."


func _set_dialogue(text: String) -> void:
	speaker_label.text = "Marek"
	dialogue_label.text = text


func _on_leave_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/vn/village.tscn"
	)
