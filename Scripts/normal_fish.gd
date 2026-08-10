class_name NormalFish
extends Fish

@export var swim_speed: float = 90.0

var swim_direction: float


func _ready() -> void:
	super._ready()

	if randf() < 0.5:
		swim_direction = -1.0
	else:
		swim_direction = 1.0


func _process(delta: float) -> void:
	position.x += swim_speed * swim_direction * delta

	var screen_width := get_viewport_rect().size.x

	if global_position.x <= 30.0 and swim_direction < 0.0:
		swim_direction = 1.0

	elif global_position.x >= screen_width - 30.0 and swim_direction > 0.0:
		swim_direction = -1.0
