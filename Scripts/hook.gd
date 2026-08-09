extends Area2D

signal fish_caught(fish: Area2D)

@export var speed := 350.0

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

	position.x = clamp(position.x, 20.0, screen_size.x - 20.0)
	position.y = clamp(position.y, 20.0, screen_size.y - 20.0)


func _on_area_entered(area: Area2D) -> void:
	if not can_move:
		return

	if area.is_in_group("fish"):
		can_move = false

		set_deferred("monitoring", false)

		print("HOOK HIT: ", area.name)
		fish_caught.emit(area)
