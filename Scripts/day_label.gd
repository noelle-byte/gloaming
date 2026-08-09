extends Label

@onready var day_label: Label = %DayLabel
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	day_label.text = "DAY " + str(GameState.day)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
