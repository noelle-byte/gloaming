extends Node

### DAY / ECONOMY

var day: int = 1

var money: int = 5


### CAUGHT FISH

var catches: Array[Dictionary] = []


### INVENTORY

var inventory: Dictionary = {
	"worms": 8
}


### EQUIPMENT

const CONDITION_PERFECT := "perfect"
const CONDITION_DAMAGED := "damaged"

# Every physical piece of equipment gets its own UID.
# This lets us own duplicates with different conditions.
var equipment_instances: Array[Dictionary] = [
	{
		"uid": 1,
		"type": "rod",
		"gear_id": "old_ash",
		"condition": CONDITION_PERFECT
	},
	{
		"uid": 2,
		"type": "line",
		"gear_id": "hemp",
		"condition": CONDITION_PERFECT
	},
	{
		"uid": 3,
		"type": "hook",
		"gear_id": "standard",
		"condition": CONDITION_PERFECT
	}
]

var next_equipment_uid: int = 4

var tackle_equipment: Array[int] = [
	1,
	2,
	3
]

var tackle_capacity: int = 7

var active_rod_uid: int = 1
var active_line_uid: int = 2
var active_hook_uid: int = 3

var equipped_rod: String = "old_ash"
var equipped_line: String = "hemp"
var equipped_hook: String = "standard"

var equipped_lantern: String = "none"
var equipped_talisman: String = "none"

func add_equipment(
	type: String,
	gear_id: String,
	condition: String = CONDITION_PERFECT
) -> int:
	var uid := next_equipment_uid
	next_equipment_uid += 1

	equipment_instances.append({
		"uid": uid,
		"type": type,
		"gear_id": gear_id,
		"condition": condition
	})

	return uid


func get_equipment(uid: int) -> Dictionary:
	for item in equipment_instances:
		if item["uid"] == uid:
			return item

	return {}


func get_equipment_count(
	type: String,
	gear_id: String
) -> int:
	var total := 0

	for item in equipment_instances:
		if (
			item["type"] == type
			and item["gear_id"] == gear_id
		):
			total += 1

	return total


func get_equipment_of_type(
	type: String
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for item in equipment_instances:
		if item["type"] == type:
			result.append(item)

	return result


func is_equipment_loaded(uid: int) -> bool:
	return uid in tackle_equipment

func get_loaded_equipment_count(
	type: String = ""
) -> int:
	var total := 0

	for uid in tackle_equipment:
		var item := get_equipment(uid)

		if item.is_empty():
			continue

		if type == "" or item["type"] == type:
			total += 1

	return total


func get_tackle_slots_used() -> int:
	return (
		tackle_equipment.size()
		+ get_loaded_bait_count()
	)


func has_tackle_space() -> bool:
	return get_tackle_slots_used() < tackle_capacity

var bait_pouch: Dictionary = {}

func load_equipment(uid: int) -> bool:
	if get_equipment(uid).is_empty():
		return false

	if is_equipment_loaded(uid):
		return false

	if not has_tackle_space():
		return false

	tackle_equipment.append(uid)
	return true


func unload_equipment(uid: int) -> bool:
	if not is_equipment_loaded(uid):
		return false

	tackle_equipment.erase(uid)

	var item := get_equipment(uid)

	if not item.is_empty():
		_refresh_active_equipment(item["type"])

	return true

func _refresh_active_equipment(type: String) -> void:
	var current_uid := 0

	match type:
		"rod":
			current_uid = active_rod_uid
		"line":
			current_uid = active_line_uid
		"hook":
			current_uid = active_hook_uid

	if current_uid in tackle_equipment:
		return

	for uid in tackle_equipment:
		var item := get_equipment(uid)

		if item.get("type", "") == type:
			set_active_equipment(uid)
			return

	match type:
		"rod":
			active_rod_uid = 0
			equipped_rod = ""
		"line":
			active_line_uid = 0
			equipped_line = ""
		"hook":
			active_hook_uid = 0
			equipped_hook = ""

func set_active_equipment(uid: int) -> bool:
	if not is_equipment_loaded(uid):
		return false

	var item := get_equipment(uid)

	if item.is_empty():
		return false

	match item["type"]:
		"rod":
			active_rod_uid = uid
			equipped_rod = item["gear_id"]

		"line":
			active_line_uid = uid
			equipped_line = item["gear_id"]

		"hook":
			active_hook_uid = uid
			equipped_hook = item["gear_id"]

		_:
			return false

	return true

func get_fishing_loadout_problem() -> String:
	if get_loaded_equipment_count("rod") <= 0:
		return "No rod loaded."

	if get_loaded_equipment_count("line") <= 0:
		return "No line loaded."

	if get_loaded_equipment_count("hook") <= 0:
		return "No hook loaded."

	if get_loaded_bait_count() <= 0:
		return "No bait loaded."

	return ""


func has_valid_fishing_loadout() -> bool:
	return get_fishing_loadout_problem() == ""

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

var base_rent: int = 25
var current_rent: int = 25

var rent_due_day: int = 4
var rent_delays: int = 0

var next_rent_fees: int = 0
var rent_fee_rate: float = 0.15

var visited_voss_today: bool = false


func get_rent_fee() -> int:
	return ceili(base_rent * rent_fee_rate)


func days_until_rent() -> int:
	return max(rent_due_day - day, 0)


func rent_is_due() -> bool:
	return day >= rent_due_day


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

	base_rent = ceili(base_rent * 1.3)

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
	current_rent += get_rent_fee()
	rent_due_day += 1

	return true


func add_collection_fee() -> void:
	next_rent_fees += get_rent_fee()


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

func owns_rod(rod_id: String) -> bool:
	return get_equipment_count(
		"rod",
		rod_id
	) > 0


func add_rod(rod_id: String) -> bool:
	add_equipment(
		"rod",
		rod_id
	)

	return true


func owns_hook(hook_id: String) -> bool:
	return get_equipment_count(
		"hook",
		hook_id
	) > 0


func add_hook(hook_id: String) -> bool:
	add_equipment(
		"hook",
		hook_id
	)

	return true


func equip_hook(hook_id: String) -> bool:
	if not owns_hook(hook_id):
		return false

	equipped_hook = hook_id
	return true

### RESET RUN

func reset_run() -> void:
	day = 1
	money = 5

	catches.clear()

	inventory = {
		"worms": 8
	}

	equipment_instances = [
	{
		"uid": 1,
		"type": "rod",
		"gear_id": "old_ash",
		"condition": CONDITION_PERFECT
	},
	{
		"uid": 2,
		"type": "line",
		"gear_id": "hemp",
		"condition": CONDITION_PERFECT
	},
	{
		"uid": 3,
		"type": "hook",
		"gear_id": "standard",
		"condition": CONDITION_PERFECT
	}
]

	next_equipment_uid = 4

	tackle_equipment = [
		1,
		2,
		3
	]

	active_rod_uid = 1
	active_line_uid = 2
	active_hook_uid = 3

	equipped_rod = "old_ash"
	equipped_line = "hemp"
	equipped_hook = "standard"

	bait_pouch.clear()

	day_actions_remaining = max_day_actions

	base_rent = 25
	current_rent = 25
	rent_due_day = 4
	rent_delays = 0
	next_rent_fees = 0
	visited_voss_today = false

	fish_sold_totals.clear()

	day_1_visits = {
		"marek": false,
		"aarne": false,
		"ilari": false,
		"voss": false,
		"aino": false
	}

### BAIT POUCH

func get_loaded_bait_count() -> int:
	var total := 0

	for amount in bait_pouch.values():
		total += amount

	return total


func can_load_more_bait() -> bool:
	return has_tackle_space()


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
