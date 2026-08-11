extends CharacterBody2D

signal fish_caught(fish: Area2D)
signal cast_failed(reason: String)

@export var speed: float = 350.0

@export var screen_margin: float = 20.0

var can_move := true
var failed := false

@onready var catch_area: Area2D = $CatchArea

@export var descent_speed: float = 100.0

@onready var camera: Camera2D = $"../World/Camera2D"

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	# Allow sliding even at very shallow contact angles.
	wall_min_slide_angle = 0.0

	catch_area.area_entered.connect(_on_catch_area_entered)


func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		return

	var direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	velocity = (
		direction * speed
		+ Vector2.DOWN * descent_speed
	)

	move_and_slide()

	_check_rock_collisions()

	if failed:
		return

	_keep_on_screen()


func _check_rock_collisions() -> void:
	var screen_height := get_viewport_rect().size.y

	var top_edge := (
		camera.get_screen_center_position().y
		- screen_height * 0.5
		+ screen_margin
	)

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()

		if collider == null:
			continue

		if not collider.is_in_group("obstacle"):
			continue

		if (
			global_position.y <= top_edge + 2.0
			and collision.get_normal().y < -0.5
		):
			_fail_cast("Hook caught on a rock")
			return


func _keep_on_screen() -> void:
	var screen_size := get_viewport_rect().size
	var half_screen := screen_size * 0.5

	var camera_center := camera.get_screen_center_position()

	var left := (
		camera_center.x
		- half_screen.x
		+ screen_margin
	)

	var right := (
		camera_center.x
		+ half_screen.x
		- screen_margin
	)

	var top := (
		camera_center.y
		- half_screen.y
		+ screen_margin
	)

	var bottom := (
		camera_center.y
		+ half_screen.y
		- screen_margin
	)

	global_position.x = clamp(
		global_position.x,
		left,
		right
	)

	global_position.y = clamp(
		global_position.y,
		top,
		bottom
	)


func _on_catch_area_entered(area: Area2D) -> void:
	if not can_move:
		return

	if not area.is_in_group("fish"):
		return

	can_move = false
	velocity = Vector2.ZERO

	catch_area.set_deferred("monitoring", false)

	print("HOOK HIT: ", area.name)

	fish_caught.emit(area)


func _fail_cast(reason: String) -> void:
	if failed:
		return

	failed = true
	can_move = false
	velocity = Vector2.ZERO

	catch_area.set_deferred("monitoring", false)

	print("CAST FAILED: ", reason)

	cast_failed.emit(reason)
