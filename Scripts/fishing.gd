extends Node2D

@onready var world: Node2D = $World
@onready var hook: CharacterBody2D = $Hook

@onready var catch_panel: Control = %CatchPanel
@onready var catch_name: Label = %CatchName
@onready var catch_value: Label = %CatchValue
@onready var keep_button: Button = %KeepButton
@onready var throw_back_button: Button = %ThrowBackButton

var current_fish: Fish


func _ready() -> void:
	hook.fish_caught.connect(_on_fish_caught)
	hook.cast_failed.connect(_on_cast_failed)

	keep_button.pressed.connect(_on_keep_pressed)
	throw_back_button.pressed.connect(_on_throw_back_pressed)

	catch_panel.hide()


func _on_fish_caught(fish: Area2D) -> void:
	world.stop_scrolling()

	current_fish = fish as Fish

	if current_fish != null:
		current_fish.on_caught()

	print("Caught ", fish.name)

	call_deferred("reel_in", fish)

func _on_cast_failed(reason: String) -> void:
	world.stop_scrolling()

	print(reason)

	await get_tree().create_timer(0.4).timeout

	start_new_cast()

func reel_in(fish: Fish) -> void:
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

	show_catch(fish)


func show_catch(fish: Fish) -> void:
	catch_name.text = fish.display_name
	catch_value.text = "Value: £" + str(fish.value)

	catch_panel.show()


func _on_keep_pressed() -> void:
	if current_fish == null:
		return

	GameState.add_catch(
		current_fish.display_name,
		current_fish.value,
		current_fish.corruption
	)

	print("Kept ", current_fish.display_name)
	print(GameState.catches)

	start_new_cast()


func _on_throw_back_pressed() -> void:
	if current_fish == null:
		return

	print("Threw back ", current_fish.display_name)

	start_new_cast()


func start_new_cast() -> void:
	get_tree().reload_current_scene()
