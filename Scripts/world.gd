extends Node2D


### DEPTH

@export_category("Depth")

@export var scroll_speed: float = 120.0

@export var pixels_per_meter: float = 50.0

var scroll_distance: float = 0.0

@onready var camera: Camera2D = $Camera2D

### CHUNKS

@export_category("Chunks")

# One chunk is currently roughly one viewport tall.
@export var chunk_height: float = 730.0

# Keep this many chunks prepared beyond the viewport.
@export var chunks_ahead: int = 2

# Put default_chunk.tscn and every special chunk here.
@export var chunk_scenes: Array[PackedScene] = []

@export var cleanup_buffer: float = 150.0


### DEFAULT SPAWN POOLS

@export_category("Default Spawn Pools")

@export var fish_scenes: Array[PackedScene] = []
@export var obstacle_scenes: Array[PackedScene] = []

@export var horizontal_margin: float = 60.0


### DENSITY

@export_category("Density")

@export var surface_fish_per_chunk: int = 7

@export var surface_obstacles_per_chunk: int = 3

@export var maximum_obstacles_per_chunk: int = 15

# Higher = terrain becomes denser faster.
@export var obstacle_density_per_meter: float = 0.03


### FISH DEPTH WEIGHTING

@export_category("Fish Depth Weighting")

@export var shallow_preferred_depth: float = 5.0

@export var corruption_depth_step: float = 10.0

@export var depth_spread: float = 12.0

# Future bait:
# 1.0 = neutral
# 0.8 = shallower bias
# 1.2 = deeper bias
@export var bait_depth_modifier: float = 1.0


### STATE

var scrolling := true

var next_chunk_index: int = 0

var rng := RandomNumberGenerator.new()

# PackedScene -> corruption
var fish_corruption_cache: Dictionary = {}

# Cached information about chunk scenes.
var chunk_metadata: Array[Dictionary] = []

# Used so guaranteed chunks don't repeat.
var used_guaranteed_chunks: Dictionary = {}


@onready var chunks: Node2D = $Chunks


func _ready() -> void:
	rng.randomize()

	_cache_chunk_metadata()

	_ensure_chunks()


func _physics_process(delta: float) -> void:
	if scrolling:
		var movement := scroll_speed * delta

		scroll_distance += movement
		camera.position.y += movement

		_ensure_chunks()

	_cleanup_chunks()


### DEPTH

func get_depth() -> float:
	return scroll_distance / pixels_per_meter


### CHUNK GENERATION

func _ensure_chunks() -> void:
	var screen_height := get_viewport_rect().size.y

	var viewport_bottom := (
		camera.position.y
		+ screen_height * 0.5
	)

	var generation_limit := (
		viewport_bottom
		+ chunk_height * chunks_ahead
	)

	while (
		next_chunk_index * chunk_height
		< generation_limit
	):
		_spawn_chunk(next_chunk_index)

		next_chunk_index += 1

func _spawn_chunk(chunk_index: int) -> void:
	if chunk_scenes.is_empty():
		push_warning("World has no chunk scenes.")
		return

	var chunk_y := chunk_index * chunk_height

	var start_depth := (
		chunk_y / pixels_per_meter
	)

	var end_depth := (
		(chunk_y + chunk_height)
		/ pixels_per_meter
	)

	var chunk_scene := _choose_chunk_scene(
		start_depth,
		end_depth
	)

	if chunk_scene == null:
		return

	var chunk := chunk_scene.instantiate() as LakeChunk

	if chunk == null:
		push_warning(
			"Chunk scene does not inherit LakeChunk."
		)
		return

	chunks.add_child(chunk)

	chunk.position = Vector2(
		0.0,
		chunk_y
	)

	print(
		"CHUNK: ",
		chunk.chunk_name,
		" ",
		start_depth,
		"m - ",
		end_depth,
		"m"
	)

	_populate_chunk(
		chunk,
		start_depth,
		end_depth
	)



### CHUNK SELECTION


func _choose_chunk_scene(
	start_depth: float,
	end_depth: float
) -> PackedScene:

	# Guaranteed chunks get first priority.

	for data in chunk_metadata:
		var guaranteed: float = data["guaranteed_depth"]

		if guaranteed < 0.0:
			continue

		var key: String = data["path"]

		if used_guaranteed_chunks.has(key):
			continue

		if (
			guaranteed >= start_depth
			and guaranteed < end_depth
		):
			used_guaranteed_chunks[key] = true

			return data["scene"]


	# Random eligible chunks

	var eligible: Array[PackedScene] = []
	var weights := PackedFloat32Array()

	var middle_depth := (
		start_depth + end_depth
	) * 0.5

	for data in chunk_metadata:

		if not data["can_spawn_randomly"]:
			continue

		var minimum: float = data["minimum_depth"]
		var maximum: float = data["maximum_depth"]

		if middle_depth < minimum:
			continue

		if (
			maximum >= 0.0
			and middle_depth > maximum
		):
			continue

		eligible.append(data["scene"])

		weights.append(
			max(
				0.001,
				data["selection_weight"]
			)
		)

	if eligible.is_empty():
		# First chunk scene should always be Default.
		return chunk_scenes[0]

	var chosen := rng.rand_weighted(weights)

	return eligible[chosen]


### POPULATING CHUNKS

func _populate_chunk(
	chunk: LakeChunk,
	start_depth: float,
	end_depth: float
) -> void:

	var spawn_parent := (
		chunk.get_generated_parent()
	)

	# Obstacles first.
	_generate_chunk_terrain(
		chunk,
		spawn_parent,
		start_depth,
		end_depth
	)

	# Then fish.
	_generate_chunk_fish(
		chunk,
		spawn_parent,
		start_depth,
		end_depth
	)


### TERRAIN

func _generate_chunk_terrain(
	chunk: LakeChunk,
	parent: Node2D,
	start_depth: float,
	end_depth: float
) -> void:

	if chunk.terrain_mode == LakeChunk.SpawnMode.NONE:
		return

	var pool: Array[PackedScene]

	if (
		chunk.terrain_mode
		== LakeChunk.SpawnMode.OVERRIDE
	):
		pool = chunk.terrain_override
	else:
		pool = obstacle_scenes

	if pool.is_empty():
		return

	var middle_depth := (
		start_depth + end_depth
	) * 0.5

	var density := (
		1.0
		+ middle_depth
		* obstacle_density_per_meter
	)

	var count := roundi(
		surface_obstacles_per_chunk
		* density
		* chunk.terrain_density_multiplier
	)

	count = clampi(
		count,
		0,
		maximum_obstacles_per_chunk
	)

	for i in range(count):
		var scene := pool[
			rng.randi_range(
				0,
				pool.size() - 1
			)
		]

		var obstacle := scene.instantiate()

		parent.add_child(obstacle)

		obstacle.position = (
			_random_chunk_position()
		)


### FISH

func _generate_chunk_fish(
	chunk: LakeChunk,
	parent: Node2D,
	start_depth: float,
	end_depth: float
) -> void:

	if chunk.fish_mode == LakeChunk.SpawnMode.NONE:
		return

	var count := roundi(
		surface_fish_per_chunk
		* chunk.fish_density_multiplier
		* rng.randf_range(0.85, 1.15)
	)

	for i in range(count):

		var spawn_depth := rng.randf_range(
			start_depth,
			end_depth
		)

		var fish_scene: PackedScene

		if (
			chunk.fish_mode
			== LakeChunk.SpawnMode.OVERRIDE
		):
			if chunk.fish_override.is_empty():
				continue

			fish_scene = chunk.fish_override[
				rng.randi_range(
					0,
					chunk.fish_override.size() - 1
				)
			]

		else:
			fish_scene = (
				_choose_fish_for_depth(
					fish_scenes,
					spawn_depth
				)
			)

		if fish_scene == null:
			continue

		var fish := fish_scene.instantiate()

		parent.add_child(fish)

		fish.position = (
			_random_chunk_position()
		)


func _choose_fish_for_depth(
	pool: Array[PackedScene],
	actual_depth: float
) -> PackedScene:

	if pool.is_empty():
		return null

	var effective_depth := (
		actual_depth
		* bait_depth_modifier
	)

	var weights := PackedFloat32Array()

	for fish_scene in pool:
		var corruption := (
			_get_fish_corruption(
				fish_scene
			)
		)

		var preferred_depth := (
			shallow_preferred_depth
			+ corruption
			* corruption_depth_step
		)

		var distance := (
			effective_depth
			- preferred_depth
		)

		var weight := exp(
			-0.5
			* pow(
				distance / depth_spread,
				2.0
			)
		)

		weights.append(
			max(weight, 0.001)
		)

	var chosen := rng.rand_weighted(weights)

	return pool[chosen]


### POSITIONS

func _random_chunk_position() -> Vector2:
	var screen_width := (
		get_viewport_rect().size.x
	)

	return Vector2(
		rng.randf_range(
			horizontal_margin,
			screen_width
				- horizontal_margin
		),

		rng.randf_range(
			30.0,
			chunk_height - 30.0
		)
	)


### FISH METADATA

func _get_fish_corruption(
	fish_scene: PackedScene
) -> int:

	if fish_corruption_cache.has(
		fish_scene
	):
		return fish_corruption_cache[
			fish_scene
		]

	var instance := (
		fish_scene.instantiate()
	)

	var corruption := 0

	if instance is Fish:
		corruption = instance.corruption
	else:
		push_warning(
			fish_scene.resource_path
			+ " is not a Fish."
		)

	instance.free()

	fish_corruption_cache[
		fish_scene
	] = corruption

	return corruption


### CHUNK METADATA CACHE

func _cache_chunk_metadata() -> void:
	chunk_metadata.clear()

	for scene in chunk_scenes:
		var instance := (
			scene.instantiate()
		)

		if instance is not LakeChunk:
			push_warning(
				scene.resource_path
				+ " is not a LakeChunk."
			)

			instance.free()
			continue

		var chunk := instance as LakeChunk

		chunk_metadata.append({
			"scene": scene,
			"path": scene.resource_path,

			"selection_weight":
				chunk.selection_weight,

			"can_spawn_randomly":
				chunk.can_spawn_randomly,

			"minimum_depth":
				chunk.minimum_depth,

			"maximum_depth":
				chunk.maximum_depth,

			"guaranteed_depth":
				chunk.guaranteed_depth
		})

		instance.free()


### CLEANUP

func _cleanup_chunks() -> void:
	var screen_height := get_viewport_rect().size.y

	var viewport_top := (
		camera.position.y
		- screen_height * 0.5
	)

	for child in chunks.get_children():

		if child is not Node2D:
			continue

		if (
			child.position.y
			+ chunk_height
			< viewport_top - cleanup_buffer
		):
			child.queue_free()
