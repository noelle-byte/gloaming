extends Node

### DAY / ECONOMY

var day: int = 1

# starting money
var money: int = 5

### RENT

var base_rent: int = 25
var current_rent: int = 25

var rent_due_day: int = 4

var rent_delays: int = 0

var next_rent_fees: int = 0

var rent_fee_rate: float = 0.15

var rent_paid_this_cycle: bool = false


### CAUGHT FISH

var catches: Array[Dictionary] = []


### INVENTORY

# Consumables / stackable items.
# item_id : quantity
var inventory: Dictionary = {
	"worms": 8
}


### EQUIPMENT

var owned_rods: Array[String] = [
	"old_ash"
]

var equipped_rod: String = "old_ash"


var equipped_line: String = "hemp"
var equipped_hook: String = "standard"
var equipped_lantern: String = "none"
var equipped_talisman: String = "none"


### BAIT POUCH

var bait_pouch: Dictionary = {}

var bait_pouch_capacity: int = 4


### DAY

var max_day_actions: int = 3
var day_actions_remaining: int = 3


func next_day() -> void:
	day += 1
	day_actions_remaining = max_day_actions
	visited_voss_today = false


func can_spend_day_action() -> bool:
	# Day 1 tutorial visits are free.
	if day == 1:
		return true

	return day_actions_remaining > 0


func spend_day_action() -> bool:
	# Day 1 deliberately ignores AP.
	if day == 1:
		return true

	if day_actions_remaining <= 0:
		return false

	day_actions_remaining -= 1
	return true


func forfeit_day_actions() -> void:
	day_actions_remaining = 0

### MONEY

func can_afford(amount: int) -> bool:
	return money >= amount


func spend_money(amount: int) -> bool:
	if not can_afford(amount):
		return false

	money -= amount
	return true


func add_money(amount: int) -> void:
	money += amount

### RENT

func get_rent_fee() -> int:
	return ceili(base_rent * rent_fee_rate)


func days_until_rent() -> int:
	return max(rent_due_day - day, 0)


func rent_is_due() -> bool:
	return day >= rent_due_day and not rent_paid_this_cycle


func can_pay_rent() -> bool:
	return money >= current_rent


func pay_rent() -> bool:
	if not rent_is_due():
		return false

	if not spend_money(current_rent):
		return false

	_finish_rent_cycle()
	return true

func _finish_rent_cycle() -> void:
	rent_delays = 0
	rent_paid_this_cycle = true

	# Endless winter scaling.
	base_rent += 5

	current_rent = (
		base_rent
		+ next_rent_fees
	)

	next_rent_fees = 0

	rent_due_day += 3

func request_rent_extension() -> bool:
	if not rent_is_due():
		return false

	if rent_delays >= 2:
		return false

	rent_delays += 1

	# Extension fee applies to what Juhani needs
	# to settle THIS rent cycle.
	current_rent += get_rent_fee()

	rent_due_day += 1

	return true

func add_collection_fee() -> void:
	next_rent_fees += get_rent_fee()

var visited_voss_today: bool = false

func _visit_voss() -> void:
	if not GameState.spend_day_action():
		return

	GameState.visited_voss_today = true

	get_tree().change_scene_to_file(
		"res://Scenes/vn/voss.tscn"
	)

### INVENTORY

func get_item_count(item_id: String) -> int:
	return inventory.get(item_id, 0)


func add_item(
	item_id: String,
	amount: int = 1
) -> void:

	inventory[item_id] = (
		get_item_count(item_id)
		+ amount
	)


func remove_item(
	item_id: String,
	amount: int = 1
) -> bool:

	var current := get_item_count(item_id)

	if current < amount:
		return false

	current -= amount

	if current <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = current

	return true


### BAIT POUCH

func get_loaded_bait_count() -> int:
	var total := 0

	for amount in bait_pouch.values():
		total += amount

	return total


func can_load_more_bait() -> bool:
	return (
		get_loaded_bait_count()
		< bait_pouch_capacity
	)


func load_bait(
	bait_id: String
) -> bool:

	if not can_load_more_bait():
		return false

	if not remove_item(bait_id, 1):
		return false

	bait_pouch[bait_id] = (
		bait_pouch.get(bait_id, 0)
		+ 1
	)

	return true


func unload_bait(
	bait_id: String
) -> bool:

	var amount: int = bait_pouch.get(
		bait_id,
		0
	)

	if amount <= 0:
		return false

	amount -= 1

	if amount <= 0:
		bait_pouch.erase(bait_id)
	else:
		bait_pouch[bait_id] = amount

	add_item(bait_id)

	return true


func consume_bait(
	bait_id: String
) -> bool:

	var amount: int = bait_pouch.get(
		bait_id,
		0
	)

	if amount <= 0:
		return false

	amount -= 1

	if amount <= 0:
		bait_pouch.erase(bait_id)
	else:
		bait_pouch[bait_id] = amount

	return true



### FISH


func add_catch(
	fish_name: String,
	value: int,
	corruption: int
) -> void:

	catches.append({
		"name": fish_name,
		"value": value,
		"corruption": corruption
	})


func get_total_catch_value() -> int:
	var total := 0

	for fish in catches:
		total += fish["value"]

	return total


func sell_all_catches() -> int:
	var total := get_total_catch_value()

	add_money(total)
	catches.clear()

	return total

func owns_rod(rod_id: String) -> bool:
	return rod_id in owned_rods


func add_rod(rod_id: String) -> bool:
	if owns_rod(rod_id):
		return false

	owned_rods.append(rod_id)
	return true


func equip_rod(rod_id: String) -> bool:
	if not owns_rod(rod_id):
		return false

	equipped_rod = rod_id
	return true

### FISH MARKET

var fish_sold_totals: Dictionary = {}


func get_catch_count(fish_name: String) -> int:
	var total := 0

	for fish in catches:
		if fish["name"] == fish_name:
			total += 1

	return total


func sell_one_catch(fish_name: String) -> int:
	for i in range(catches.size()):
		var fish: Dictionary = catches[i]

		if fish["name"] != fish_name:
			continue

		var value: int = fish["value"]

		catches.remove_at(i)
		add_money(value)

		fish_sold_totals[fish_name] = (
			fish_sold_totals.get(fish_name, 0)
			+ 1
		)

		return value

	return 0


func get_fish_sold_total(fish_name: String) -> int:
	return fish_sold_totals.get(fish_name, 0)


func buy_market_fish(
	fish_name: String,
	purchase_price: int,
	resale_value: int,
	corruption: int = 0
) -> bool:

	if not spend_money(purchase_price):
		return false

	add_catch(
		fish_name,
		resale_value,
		corruption
	)

	return true

### DAY // TUTORIAL

var day_1_visits := {
	"marek": false,
	"aarne": false,
	"ilari": false,
	"voss": false,
	"aino": false
}


func mark_day_1_visit(person_id: String) -> void:
	if person_id in day_1_visits:
		day_1_visits[person_id] = true


func has_visited_day_1(person_id: String) -> bool:
	return day_1_visits.get(person_id, false)


func day_1_visits_complete() -> bool:
	for visited in day_1_visits.values():
		if not visited:
			return false

	return true


func get_missing_day_1_visits() -> Array[String]:
	var missing: Array[String] = []

	for person_id in day_1_visits:
		if not day_1_visits[person_id]:
			missing.append(person_id)

	return missing
