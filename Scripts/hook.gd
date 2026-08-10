extends CharacterBody2D

signal fish_caught(fish: Area2D)

@export var speed: float = 350.0

# Tiny bump away from rocks.
# This should feel like resistance, not knockback.
@export var rock_bump_strength: float = 25.0

@export var bump_decay: float = 150.0

var can_move := true
var bump_velocity := Vector2.ZERO

@onready var catch_area: Area2D = $CatchArea


func _ready() -> void:
	catch_area.area_entered.connect(_on_catch_area_entered)


func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		return

	var input_direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	velocity = input_direction * speed + bump_velocity

	move_and_slide()

	# If we touched terrain, give the hook a very small
	# shove away from the surface.
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()

		if collider != null and collider.is_in_group("obstacle"):
			bump_velocity = (
				collision.get_normal()
				* rock_bump_strength
			)

	# Quickly fade the bump back to zero.
	bump_velocity = bump_velocity.move_toward(
		Vector2.ZERO,
		bump_decay * delta
	)

	_keep_on_screen()


func _keep_on_screen() -> void:
	var screen_size := get_viewport_rect().size

	global_position.x = clamp(
		global_position.x,
		20.0,
		screen_size.x - 20.0
	)

	global_position.y = clamp(
		global_position.y,
		20.0,
		screen_size.y - 20.0
	)


func _on_catch_area_entered(area: Area2D) -> void:
	if not can_move:
		return

	if not area.is_in_group("fish"):
		return

	can_move = false

	catch_area.set_deferred("monitoring", false)

	print("HOOK HIT: ", area.name)

	fish_caught.emit(area)
