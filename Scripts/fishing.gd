extends Node2D

@onready var world: Node2D = $World
@onready var hook: Area2D = $Hook

var scrolling := true

func _ready() -> void:
	hook.fish_caught.connect(_on_fish_caught)


func _process(delta: float) -> void:
	if scrolling:
		world.position.y -= 120.0 * delta

func reel_in(fish: Area2D) -> void:
	var fish_global_position := fish.global_position

	fish.reparent(hook)
	fish.global_position = fish_global_position

	var tween := create_tween()

	tween.tween_property(
		hook,
		"position:y",
		-100.0,
		1.0
	)

	await tween.finished

	catch_complete(fish)

func catch_complete(fish: Area2D) -> void:
	print("LANDED: ", fish.name)

func _on_fish_caught(fish: Area2D) -> void:
	scrolling = false

	print("Caught ", fish.name)

	reel_in(fish)
