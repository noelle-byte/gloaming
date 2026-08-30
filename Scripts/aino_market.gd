extends Control


enum MarketMode {
	SELL,
	BUY
}


const MARKET_STOCK := {
	"Trout": {
		"buy_price": 5,
		"resale_value": 3,
		"corruption": 0,
		"stock": 3
	}
}


@onready var money_label: Label = %MoneyLabel
@onready var item_list: VBoxContainer = %ItemList

@onready var sell_mode_button: Button = %SellModeButton
@onready var buy_mode_button: Button = %BuyModeButton
@onready var leave_button: Button = %LeaveButton

@onready var speaker_label: Label = %SpeakerLabel
@onready var dialogue_label: Label = %DialogueLabel


var mode := MarketMode.SELL
var current_stock: Dictionary = {}


func _ready() -> void:
	sell_mode_button.pressed.connect(
		_set_mode.bind(MarketMode.SELL)
	)

	buy_mode_button.pressed.connect(
		_set_mode.bind(MarketMode.BUY)
	)

	leave_button.pressed.connect(_on_leave_pressed)

	for fish_name in MARKET_STOCK:
		current_stock[fish_name] = MARKET_STOCK[fish_name]["stock"]

	if GameState.day == 1:
		GameState.mark_day_1_visit("aino")

	_set_dialogue(
		"Juhani! I was beginning to think you'd decided to eat your own catch."
	)

	_refresh_market()


func _set_mode(new_mode: MarketMode) -> void:
	mode = new_mode
	_refresh_market()


func _refresh_market() -> void:
	for child in item_list.get_children():
		child.queue_free()

	money_label.text = "%d mk" % GameState.money

	sell_mode_button.disabled = mode == MarketMode.SELL
	buy_mode_button.disabled = mode == MarketMode.BUY

	if mode == MarketMode.SELL:
		_build_sell_list()
	else:
		_build_buy_list()


# ==================================================
# SELL
# ==================================================

func _build_sell_list() -> void:
	if GameState.catches.is_empty():
		var label := Label.new()
		label.text = "No fish to sell."
		item_list.add_child(label)
		return

	var fish_names: Array[String] = []

	for fish in GameState.catches:
		var fish_name: String = fish["name"]

		if fish_name not in fish_names:
			fish_names.append(fish_name)

	fish_names.sort()

	for fish_name in fish_names:
		_create_sell_row(fish_name)


func _create_sell_row(fish_name: String) -> void:
	var example := _find_catch(fish_name)

	if example.is_empty():
		return

	var count := GameState.get_catch_count(fish_name)
	var value: int = example["value"]

	var row := HBoxContainer.new()
	item_list.add_child(row)

	var name_label := Label.new()
	name_label.text = "%s ×%d" % [
		fish_name,
		count
	]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var value_label := Label.new()
	value_label.text = "%d mk" % value
	value_label.custom_minimum_size.x = 60
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	var sell_button := Button.new()
	sell_button.text = "Sell"
	sell_button.custom_minimum_size.x = 70

	sell_button.pressed.connect(
		_sell_fish.bind(
			fish_name,
			example["corruption"]
		)
	)

	row.add_child(sell_button)


func _find_catch(fish_name: String) -> Dictionary:
	for fish in GameState.catches:
		if fish["name"] == fish_name:
			return fish

	return {}


func _sell_fish(
	fish_name: String,
	corruption: int
) -> void:

	var previous_sales := GameState.get_fish_sold_total(
		fish_name
	)

	var earned := GameState.sell_one_catch(
		fish_name
	)

	if earned <= 0:
		return

	if corruption > 0:
		_react_to_odd_fish(
			fish_name,
			previous_sales
		)
	else:
		_set_dialogue(
			"%d markka. Fair enough." % earned
		)

	_refresh_market()


func _react_to_odd_fish(
	fish_name: String,
	previous_sales: int
) -> void:

	if fish_name == "Pale Char":
		if previous_sales == 0:
			_set_dialogue(
				"That's a char? Elina thinks so? Reassuring."
			)

		elif previous_sales < 3:
			_set_dialogue(
				"Another pale one. People seemed rather taken with the last."
			)

		else:
			_set_dialogue(
				"Keep bringing these. People have been asking."
			)

		return

	if previous_sales == 0:
		_set_dialogue(
			"I've sold fish for thirty years. I don't know what to call that."
		)
	else:
		_set_dialogue(
			"Another one? Fine. Someone will buy it."
		)


# ==================================================
# BUY
# ==================================================

func _build_buy_list() -> void:
	for fish_name in MARKET_STOCK:
		_create_buy_row(fish_name)


func _create_buy_row(fish_name: String) -> void:
	var data: Dictionary = MARKET_STOCK[fish_name]
	var amount: int = current_stock.get(fish_name, 0)
	var price: int = data["buy_price"]

	var row := HBoxContainer.new()
	item_list.add_child(row)

	var name_label := Label.new()
	name_label.text = "%s ×%d" % [
		fish_name,
		amount
	]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var price_label := Label.new()
	price_label.text = "%d mk" % price
	price_label.custom_minimum_size.x = 60
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(price_label)

	var buy_button := Button.new()
	buy_button.text = "Buy"
	buy_button.custom_minimum_size.x = 70

	buy_button.disabled = (
		amount <= 0
		or not GameState.can_afford(price)
	)

	buy_button.pressed.connect(
		_buy_fish.bind(fish_name)
	)

	row.add_child(buy_button)


func _buy_fish(fish_name: String) -> void:
	var amount: int = current_stock.get(
		fish_name,
		0
	)

	if amount <= 0:
		return

	var data: Dictionary = MARKET_STOCK[fish_name]

	var success := GameState.buy_market_fish(
		fish_name,
		data["buy_price"],
		data["resale_value"],
		data["corruption"]
	)

	if not success:
		_set_dialogue("You're short.")
		return

	current_stock[fish_name] = amount - 1

	_set_dialogue(
		"Against all natural law, the fisherman buys a fish."
	)

	_refresh_market()


func _set_dialogue(text: String) -> void:
	speaker_label.text = "Aino"
	dialogue_label.text = text


func _on_leave_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/vn/village.tscn"
	)
