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
		"tremor_multiplier": 1.0,
		"strength": 2
	},

	"willow": {
		"name": "Willow Rod",
		"description": "Light and responsive. Every movement of the hand reaches the hook.",
		"price": 9,
		"move_multiplier": 1.5,
		"tremor_multiplier": 1.25,
		"strength": 1
	},

	"braced_oak": {
		"name": "Braced Oak Rod",
		"description": "Heavy and steady.",
		"price": 11,
		"move_multiplier": 0.85,
		"tremor_multiplier": 0.55,
		"strength": 3
	},

	"split_cane": {
		"name": "Split Cane Rod",
		"description": "Expensive, light and exceptionally precise.",
		"price": 24,
		"move_multiplier": 1.1,
		"tremor_multiplier": 0.8,
		"strength": 2
	},

	"reinforced_six_strip": {
		"name": "Reinforced tonkin Six Strip Rod",
		"description": "tonkin bamboo reinforced with thin metal plates, durable, light and precise.",
		"price": 52,
		"move_multiplier": 1.2,
		"tremor_multiplier": 1.1,
		"strength": 3
	}
}

const HOOKS := {
	"standard": {
		"name": "Standard Hook",
		"description": "Small and dependable.",
		"price": 0,
		"radius": 22.0,
		"power": 1
	},

	"bigboy": {
		"name": "Heavy Gaff",
		"description": "Made for fish that should probably be left alone.",
		"price": 20,
		"radius": 34.0,
		"power": 2
	}
}

const LINES := {
	"hemp": {
		"name": "Hemp Line",
		"description": "Cheap line. Fine for ordinary fishing.",
		"price": 0,
		"strength": 1
	},

	"reinforced_depth": {
		"name": "Reinforced Depth Line",
		"description": "Heavy line made for deep water and heavy fish.",
		"price": 12,
		"strength": 3
	}
}

static func get_equipment(
	type: String,
	id: String
) -> Dictionary:
	match type:
		"rod":
			return get_rod(id)

		"line":
			return get_line(id)

		"hook":
			return get_hook(id)

	return {}

static func get_line(id: String) -> Dictionary:
	return LINES.get(id, {})


static func get_hook(id: String) -> Dictionary:
	return HOOKS.get(id, {})

static func get_bait(id: String) -> Dictionary:
	return BAITS.get(id, {})


static func get_rod(id: String) -> Dictionary:
	return RODS.get(id, {})
