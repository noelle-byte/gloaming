class_name GearDatabase
extends RefCounted


const BAITS := {
	"worms": {
		"name": "Worms",
		"description": "Cheap ordinary bait for cheap ordinary fish",
		"price": 1,
		"depth_modifier": 0.85
	},

	"cut_bait": {
		"name": "Cut Bait",
		"description": "Fish flesh cut into strips. Favoured by larger predators.",
		"price": 2,
		"depth_modifier": 1.0
	},

	"offal": {
		"name": "Offal",
		"description": "Strong-smelling scraps. Things in deeper water seem to favour it.",
		"price": 2,
		"depth_modifier": 1.2
	}
}


const RODS := {
	"old_ash": {
		"name": "Old Ash Rod",
		"description": "Old, familiar and dependable.",
		"price": 0,
		"move_multiplier": 1.0,
		"tremor_multiplier": 1.0
	},

	"willow": {
		"name": "Willow Rod",
		"description": "Light and responsive. Every movement of the hand reaches the hook.",
		"price": 9,
		"move_multiplier": 1.2,
		"tremor_multiplier": 1.25
	},

	"braced_oak": {
		"name": "Braced Oak Rod",
		"description": "Heavy and steady.",
		"price": 11,
		"move_multiplier": 0.85,
		"tremor_multiplier": 0.55
	},

	"split_cane": {
		"name": "Split-Cane Rod",
		"description": "Expensive, light and exceptionally precise.",
		"price": 24,
		"move_multiplier": 1.1,
		"tremor_multiplier": 0.8
	}
}


static func get_bait(id: String) -> Dictionary:
	return BAITS.get(id, {})


static func get_rod(id: String) -> Dictionary:
	return RODS.get(id, {})
