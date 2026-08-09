extends Node

var day: int = 1
var money: int = 0
var quota: int = 25

var catches: Array[Dictionary] = []


func next_day() -> void:
	day += 1


func add_catch(fish_name: String, value: int, corruption: int) -> void:
	catches.append({
		"name": fish_name,
		"value": value,
		"corruption": corruption
	})
