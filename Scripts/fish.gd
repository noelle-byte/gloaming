class_name Fish
extends Area2D

@export var display_name: String = "Trout"
@export var value: int = 3
@export var corruption: int = 0


func _ready() -> void:
	add_to_group("fish")


func on_caught() -> void:
	# Stop all fish behaviour once it has been hooked.
	set_process(false)
	set_physics_process(false)

	# Don't let it trigger any more collisions.
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
