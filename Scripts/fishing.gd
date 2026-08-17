extends Node2D

@onready var world: Node2D = $World
@onready var hook: CharacterBody2D = $Hook

@onready var catch_panel: Control = %CatchPanel
@onready var catch_name: Label = %CatchName
@onready var catch_value: Label = %CatchValue
@onready var keep_button: Button = %KeepButton
@onready var throw_back_button: Button = %ThrowBackButton
@onready var bait_panel: Control = %BaitPanel
@onready var bait_buttons: VBoxContainer = %BaitButtons
@onready var leave_lake_button: Button = %LeaveLakeButton

var cast_started := false
var current_fish: Fish


func _ready() -> void:
	hook.fish_caught.connect(_on_fish_caught)
	hook.cast_failed.connect(_on_cast_failed)

	keep_button.pressed.connect(_on_keep_pressed)
	throw_back_button.pressed.connect(_on_throw_back_pressed)

	leave_lake_button.pressed.connect(_end_fishing_night)

	catch_panel.hide()

	# Don't descend until the player chooses bait.
	world.stop_scrolling()
	hook.can_move = false

	_show_bait_selection()

func _show_bait_selection() -> void:
	for child in bait_buttons.get_children():
		child.queue_free()

	var total_bait := GameState.get_loaded_bait_count()

	if total_bait <= 0:
		_end_fishing_night()
		return

	bait_panel.show()

	var bait_ids := GameState.bait_pouch.keys()
	bait_ids.sort()

	for bait_id in bait_ids:
		var amount: int = GameState.bait_pouch.get(
			bait_id,
			0
		)

		if amount <= 0:
			continue

		var bait: Dictionary = GearDatabase.get_bait(
			bait_id
		)

		var button := Button.new()

		button.text = "%s ×%d" % [
			bait.get("name", bait_id),
			amount
		]

		button.tooltip_text = bait.get(
			"description",
			""
		)

		button.pressed.connect(
			_on_bait_selected.bind(bait_id)
		)

		bait_buttons.add_child(button)

func _on_bait_selected(bait_id: String) -> void:
	if not GameState.consume_bait(bait_id):
		return

	var bait: Dictionary = GearDatabase.get_bait(
		bait_id
	)

	world.bait_depth_modifier = bait.get(
		"depth_modifier",
		1.0
	)

	print(
		"CAST BAIT: ",
		bait.get("name", bait_id),
		" | depth modifier: ",
		world.bait_depth_modifier
	)

	bait_panel.hide()

	cast_started = true
	hook.can_move = true
	world.start_scrolling()

func _end_fishing_night() -> void:
	print("Fishing night finished.")
	print("Catches: ", GameState.catches)

	call_deferred("_go_to_night")


func _go_to_night() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/vn/night.tscn"
	)

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
	catch_value.text = "Value: " + str(fish.value) + " mk"

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
	if GameState.get_loaded_bait_count() <= 0:
		_end_fishing_night()
	else:
		get_tree().reload_current_scene()
