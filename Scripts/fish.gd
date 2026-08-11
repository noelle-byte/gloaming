class_name Fish
extends Area2D

@export var display_name: String = "Trout"
@export var value: int = 3
@export var corruption: int = 0


func _ready() -> void:
	add_to_group("fish")


func on_caught() -> void:
	set_process(false)
	set_physics_process(false)

	set_deferred("monitoring", false)
	set_deferred("monitorable", false)


func would_hit_obstacle(
	target_global_position: Vector2
) -> bool:

	var collision_shape := (
		get_node_or_null("CollisionShape2D")
		as CollisionShape2D
	)

	if collision_shape == null:
		return false

	if collision_shape.shape == null:
		return false

	var query := PhysicsShapeQueryParameters2D.new()

	query.shape = collision_shape.shape

	# Start with the fish collider where it currently is.
	query.transform = collision_shape.global_transform

	# Move our hypothetical collider to where the fish
	# is trying to swim.
	var movement := (
		target_global_position
		- global_position
	)

	query.transform.origin += movement

	# Layer 2 = Terrain.
	query.collision_mask = 2

	query.collide_with_bodies = true
	query.collide_with_areas = false

	var hits := (
		get_world_2d()
		.direct_space_state
		.intersect_shape(query, 1)
	)

	return not hits.is_empty()
