extends Node2D


### SCROLLING / DEPTH

@export_category("Depth")

@export var scroll_speed: float = 120.0

# How many pixels of scrolling equal one metre.
# Pure gameplay value - we'll tune this by feel.
@export var pixels_per_meter: float = 50.0


### SPAWN SCENES

@export_category("Spawn Scenes")

@export var fish_scenes: Array[PackedScene] = []
@export var obstacle_scenes: Array[PackedScene] = []


### SPAWN RATES

@export_category("Spawn Rates")

# Fish stay reasonably common regardless of depth.
@export var fish_spawn_interval: float = 0.75

# Rocks/debris start relatively sparse.
@export var surface_obstacle_interval: float = 1.8

# But never become denser than this.
@export var minimum_obstacle_interval: float = 0.35

# Higher = obstacles get dense faster as we descend.
@export var obstacle_density_per_meter: float = 0.03


### FISH DEPTH WEIGHTING

@export_category("Fish Depth Weighting")

# Preferred depth of a corruption 0 fish.
@export var shallow_preferred_depth: float = 5.0

# Every corruption point moves the preferred depth down by this many metres.
@export var corruption_depth_step: float = 10.0

# Higher values mean species can commonly appear farther away from their preferred depth.
@export var depth_spread: float = 12.0

# Future bait modifier
# 1.0 = neutral
# 0.8 = biases spawns shallower
# 1.2 = biases spawns deeper
@export var bait_depth_modifier: float = 1.0


### POSITIONING

@export_category("Positioning")

@export var horizontal_margin: float = 60.0
@export var spawn_buffer: float = 100.0
@export var cleanup_buffer: float = 150.0


### STATE

var scrolling := true

var fish_timer: float
var obstacle_timer: float

var fish_corruptions: Array[int] = []

var rng := RandomNumberGenerator.new()

@onready var generated: Node2D = $Generated


func _ready() -> void:
	rng.randomize()

	_cache_fish_corruptions()

	fish_timer = fish_spawn_interval
	obstacle_timer = surface_obstacle_interval


func _process(delta: float) -> void:
	if scrolling:
		position.y -= scroll_speed * delta

		fish_timer -= delta
		obstacle_timer -= delta

		if fish_timer <= 0.0:
			_spawn_fish()

			fish_timer = (
				fish_spawn_interval
				* rng.randf_range(0.75, 1.25)
			)

		if obstacle_timer <= 0.0:
			_spawn_obstacle()

			obstacle_timer = (
				_get_obstacle_interval()
				* rng.randf_range(0.75, 1.25)
			)

	_cleanup_generated()


### DEPTH

func get_depth() -> float:
	return max(
		0.0,
		-position.y / pixels_per_meter
	)


### FISH SPAWNING

func _spawn_fish() -> void:
	if fish_scenes.is_empty():
		return

	var fish_scene := _choose_fish_for_depth()

	if fish_scene == null:
		return

	var fish := fish_scene.instantiate()

	generated.add_child(fish)

	fish.position = _get_spawn_position()


func _choose_fish_for_depth() -> PackedScene:
	var actual_depth := get_depth()

	# Right now this does nothing because the
	# modifier is 1.0.
	#
	# Later bait can make the spawn table behave
	# as though we're slightly deeper or shallower.
	var effective_depth := (
		actual_depth * bait_depth_modifier
	)

	var weights := PackedFloat32Array()

	for i in range(fish_scenes.size()):
		var corruption := fish_corruptions[i]

		var preferred_depth := (
			shallow_preferred_depth
			+ corruption * corruption_depth_step
		)

		var distance := (
			effective_depth - preferred_depth
		)

		# Bell curve centred around preferred_depth.
		var weight := exp(
			-0.5
			* pow(
				distance / depth_spread,
				2.0
			)
		)

		# Extremely unlikely is fine.
		# Literally impossible is less interesting.
		weight = max(weight, 0.001)

		weights.append(weight)

	var chosen_index := rng.rand_weighted(weights)

	if chosen_index < 0:
		return null

	return fish_scenes[chosen_index]


### OBSTACLE SPAWNING

func _spawn_obstacle() -> void:
	if obstacle_scenes.is_empty():
		return

	var index := rng.randi_range(
		0,
		obstacle_scenes.size() - 1
	)

	var obstacle := (
		obstacle_scenes[index].instantiate()
	)

	generated.add_child(obstacle)

	obstacle.position = _get_spawn_position()


func _get_obstacle_interval() -> float:
	var depth := get_depth()

	var density_multiplier := (
		1.0
		+ depth * obstacle_density_per_meter
	)

	return max(
		minimum_obstacle_interval,
		surface_obstacle_interval
			/ density_multiplier
	)


### SPAWN POSITION

func _get_spawn_position() -> Vector2:
	var screen_size := get_viewport_rect().size

	var x := rng.randf_range(
		horizontal_margin,
		screen_size.x - horizontal_margin
	)

	# World moves upward, so convert the bottom of
	# the viewport back into World-local coordinates.
	var y := (
		-position.y
		+ screen_size.y
		+ spawn_buffer
	)

	return Vector2(x, y)


### FISH METADATA CACHE

func _cache_fish_corruptions() -> void:
	fish_corruptions.clear()

	for fish_scene in fish_scenes:
		var instance := fish_scene.instantiate()

		if instance is Fish:
			fish_corruptions.append(
				instance.corruption
			)
		else:
			push_warning(
				fish_scene.resource_path
				+ " is not a Fish scene."
			)

			fish_corruptions.append(0)

		instance.free()


### CLEANUP

func _cleanup_generated() -> void:
	for child in generated.get_children():
		if child is not Node2D:
			continue

		if child.global_position.y < -cleanup_buffer:
			child.queue_free()


### SCROLL CONTROL

func stop_scrolling() -> void:
	scrolling = false


func start_scrolling() -> void:
	scrolling = true
