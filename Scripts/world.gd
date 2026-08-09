extends Node2D

@export var scroll_speed: float = 120.0

var scrolling := true


func _process(delta: float) -> void:
	if scrolling:
		position.y -= scroll_speed * delta


func stop_scrolling() -> void:
	scrolling = false


func start_scrolling() -> void:
	scrolling = true
