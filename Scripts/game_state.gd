extends Node

### DAY / ECONOMY

var day: int = 1

# Test money
var money: int = 20

var quota: int = 25


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


# We can add these properly once their systems exist.
var equipped_line: String = "hemp"
var equipped_hook: String = "standard"
var equipped_lantern: String = "none"
var equipped_talisman: String = "none"


### BAIT POUCH

# Bait in the house is inventory.
# Bait in this dictionary is what Juhani actually
# carries onto the lake tonight.
var bait_pouch: Dictionary = {}

var bait_pouch_capacity: int = 4


### DAY

func next_day() -> void:
	day += 1


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
