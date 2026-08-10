extends Area2D

signal fish_caught(fish: Area2D)
signal cast_failed(reason: String)

@export var speed := 350.0

# How violently normal rocks shove the hook.
@export var rock_push_distance := 110.0

var can_move := true


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if not can_move:
		return

	var direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	position += direction * speed * delta

	var screen_size := get_viewport_rect().size

	position.x = clamp(
		position.x,
		20.0,
		screen_size.x - 20.0
	)

	position.y = clamp(
		position.y,
		20.0,
		screen_size.y - 20.0
	)


func _on_area_entered(area: Area2D) -> void:
	if not can_move:
		return

	if area.is_in_group("fish"):
		_catch_fish(area)

	elif area.is_in_group("obstacle"):
		_hit_basic_obstacle(area)


func _catch_fish(fish: Area2D) -> void:
	can_move = false

	set_deferred("monitoring", false)

	print("HOOK HIT: ", fish.name)

	fish_caught.emit(fish)


func _hit_basic_obstacle(obstacle: Area2D) -> void:
	var obstacle_center := obstacle.global_position

	# Your current rocks have their origin at the
	# corner rather than the centre, so use the
	# collision shape's centre if possible.
	var obstacle_collision := obstacle.get_node_or_null(
		"CollisionShape2D"
	)

	if obstacle_collision is CollisionShape2D:
		obstacle_center = obstacle_collision.global_position

	var push_direction := (
		global_position - obstacle_center
	).normalized()

	# Extremely unlikely, but prevents a zero vector
	# if we're precisely in the middle of the rock.
	if push_direction == Vector2.ZERO:
		push_direction = Vector2.UP

	var target_position := (
		global_position
		+ push_direction * rock_push_distance
	)

	if _would_be_off_screen(target_position):
		global_position = target_position
		_fail_cast("Hook knocked off course")
		return

	global_position = target_position


func _would_be_off_screen(target: Vector2) -> bool:
	var screen_size := get_viewport_rect().size

	var margin := 20.0

	return (
		target.x < margin
		or target.x > screen_size.x - margin
		or target.y < margin
		or target.y > screen_size.y - margin
	)


func _fail_cast(reason: String) -> void:
	can_move = false
	set_deferred("monitoring", false)

	print("CAST FAILED: ", reason)

	cast_failed.emit(reason)
