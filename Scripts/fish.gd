class_name Fish
extends Area2D

@export var display_name: String = "Trout"
@export var value: int = 3
@export var corruption: int = 0


func _ready() -> void:
	add_to_group("fish")
