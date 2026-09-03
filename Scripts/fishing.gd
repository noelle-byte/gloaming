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
var catch_gear_message: String = ""

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

	_show_hook_selection()

func _show_hook_selection() -> void:
	for child in bait_buttons.get_children():
		child.queue_free()

	bait_panel.show()

	var hook_counts: Dictionary = (
		GameState.get_loaded_equipment_counts("hook")
	)

	if hook_counts.is_empty():
		_end_fishing_night()
		return

	var hook_ids: Array = hook_counts.keys()
	hook_ids.sort()

	for hook_id_value in hook_ids:
		var hook_id: String = str(hook_id_value)

		var hook_data: Dictionary = (
			GearDatabase.get_hook(hook_id)
		)

		var button := Button.new()

		button.text = "%s ×%d" % [
			hook_data.get("name", hook_id),
			int(hook_counts[hook_id])
		]

		button.pressed.connect(
			_on_hook_selected.bind(hook_id)
		)

		bait_buttons.add_child(button)

func _on_hook_selected(hook_id: String) -> void:
	var uid: int = (
		GameState.get_loaded_equipment_uid(
			"hook",
			hook_id
		)
	)

	if uid == 0:
		return

	GameState.set_active_equipment(uid)

	hook.apply_equipped_hook()

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
	var caught_fish := fish as Fish

	if caught_fish == null:
		return

	var hook_data: Dictionary = GearDatabase.get_hook(
		GameState.equipped_hook
	)

	var hook_power: int = int(
		hook_data.get("power", 1)
	)

	if hook_power < caught_fish.required_hook_power:
		world.stop_scrolling()

		print(
			caught_fish.display_name,
			" is too large for ",
			hook_data.get(
				"name",
				GameState.equipped_hook
			)
		)

		caught_fish.queue_free()

		await get_tree().create_timer(0.5).timeout
		start_new_cast()
		return
	
	var gear_result: Dictionary = (
		GameState.stress_active_fishing_gear(
			caught_fish.pull_strength
		)
	)

	var gear_result_type: String = gear_result.get(
		"result",
		"safe"
	)
	
	if gear_result_type == "damaged":
		catch_gear_message = (
			"%s was damaged."
			% gear_result.get(
				"name",
				"Equipment"
			)
		)

	if gear_result_type == "destroyed":
		world.stop_scrolling()

		var gear_name: String = gear_result.get(
			"name",
			"equipment"
		)

		print(
			gear_name,
			" broke under the pull of ",
			caught_fish.display_name,
			"."
		)

		caught_fish.queue_free()

		await get_tree().create_timer(0.6).timeout

		start_new_cast()
		return
	
	world.stop_scrolling()
	current_fish = caught_fish

	current_fish.on_caught()

	print("Caught ", fish.name)

	call_deferred(
		"reel_in",
		caught_fish
	)

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

	catch_value.text = (
		"Value: %d mk"
		% fish.value
	)

	if catch_gear_message != "":
		catch_value.text += (
			"\n\n"
			+ catch_gear_message
		)

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
	if not GameState.has_valid_fishing_loadout():
		_end_fishing_night()
		return

	get_tree().reload_current_scene()
