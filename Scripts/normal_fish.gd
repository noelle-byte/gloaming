class_name NormalFish
extends Fish

@export var swim_speed: float = 90.0
@onready var visual: Node2D = $Visual

var swim_direction: float


func _ready() -> void:
	super._ready()

	if randf() < 0.5:
		swim_direction = -1.0
	else:
		swim_direction = 1.0

	_update_facing()


func _process(delta: float) -> void:
	var movement := Vector2(
		swim_speed * swim_direction * delta,
		0.0
	)

	var target_position := global_position + movement

	if would_hit_obstacle(target_position):
		swim_direction *= -1.0
		_update_facing()
	else:
		position += movement

	var screen_width := get_viewport_rect().size.x

	if global_position.x <= 30.0 and swim_direction < 0.0:
		swim_direction = 1.0
		_update_facing()

	elif (
		global_position.x >= screen_width - 30.0
		and swim_direction > 0.0
	):
		swim_direction = -1.0
		_update_facing()


func _update_facing() -> void:
	# Current placeholder artwork faces left by default.
	if swim_direction < 0.0:
		visual.scale.x = 1.0
	else:
		visual.scale.x = -1.0
