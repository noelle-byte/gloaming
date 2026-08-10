class_name LakeChunk
extends Node2D


enum SpawnMode {
	PROCEDURAL,
	OVERRIDE,
	NONE
}


### SELECTION

@export_category("Chunk")

@export var chunk_name: String = "Default"

# Relative chance of being selected.
# Default chunk might be 10.
# A rare special chunk might be 0.5.
@export var selection_weight: float = 10.0

# Can this chunk appear through normal random generation?
@export var can_spawn_randomly: bool = true

# Depth range where this chunk may randomly appear.
@export var minimum_depth: float = 0.0

# -1 means no maximum.
@export var maximum_depth: float = -1.0

# -1 means it is never forced.
# Otherwise the chunk will be guaranteed when the
# generated chunk band contains this depth.
@export var guaranteed_depth: float = -1.0


### FISH

@export_category("Fish")

@export var fish_mode: SpawnMode = SpawnMode.PROCEDURAL

# Used when Fish Mode = OVERRIDE.
@export var fish_override: Array[PackedScene] = []

@export var fish_density_multiplier: float = 1.0


### TERRAIN

@export_category("Terrain")

@export var terrain_mode: SpawnMode = SpawnMode.PROCEDURAL

# Used when Terrain Mode = OVERRIDE.
@export var terrain_override: Array[PackedScene] = []

@export var terrain_density_multiplier: float = 1.0


func get_generated_parent() -> Node2D:
	var generated := get_node_or_null("Generated") as Node2D

	if generated != null:
		return generated

	return self
