class_name MonsterRoster
extends RefCounted

const ORDER:Array[String] = [
	"ridgeback",
	"thornkin",
	"stone_golem",
	"mire_leech",
	"ember_imp",
	"frost_wisp"
]

const BY_BIOME:Dictionary = {
	"Greenlands":"ridgeback",
	"Ancient Forest":"thornkin",
	"Iron Hills":"stone_golem",
	"Mistfen":"mire_leech",
	"Ash Wastes":"ember_imp",
	"Frostwild":"frost_wisp"
}

const DATA:Dictionary = {
	"ridgeback":{
		"name":"Ridgeback",
		"biome":"Greenlands",
		"role":"Wounded-target hunter",
		"description":"A brutal frontier beast that surges into weakened prey. Deals bonus damage to targets below 45% health.",
		"command":3,
		"power":36,
		"damage":11.5,
		"cooldown":0.70,
		"range":205.0,
		"cost":{"gold":72,"food":58}
	},
	"thornkin":{
		"name":"Thornkin",
		"biome":"Ancient Forest",
		"role":"Living bulwark",
		"description":"A bark-armored forest guardian. Deploying Thornkin slightly reduces damage taken by the Warden.",
		"command":4,
		"power":42,
		"damage":9.0,
		"cooldown":0.92,
		"range":215.0,
		"cost":{"gold":78,"food":42,"wood":34}
	},
	"stone_golem":{
		"name":"Stone Golem",
		"biome":"Iron Hills",
		"role":"Heavy breaker",
		"description":"Slow, expensive and extremely heavy-hitting. Its attacks are especially effective against guardians and regional bosses.",
		"command":6,
		"power":68,
		"damage":20.0,
		"cooldown":1.45,
		"range":210.0,
		"cost":{"gold":118,"stone":55,"iron":24}
	},
	"mire_leech":{
		"name":"Mire Leech",
		"biome":"Mistfen",
		"role":"Sustain predator",
		"description":"A grotesquely useful companion. Successful attacks restore a small amount of Warden health.",
		"command":4,
		"power":46,
		"damage":10.5,
		"cooldown":0.78,
		"range":210.0,
		"cost":{"gold":84,"food":64,"mana":5}
	},
	"ember_imp":{
		"name":"Ember Imp",
		"biome":"Ash Wastes",
		"role":"Ranged splash pressure",
		"description":"A volatile ranged companion. Its attacks splash a fraction of their damage into a nearby enemy.",
		"command":4,
		"power":50,
		"damage":12.0,
		"cooldown":0.95,
		"range":300.0,
		"cost":{"gold":96,"food":30,"mana":10}
	},
	"frost_wisp":{
		"name":"Frost Wisp",
		"biome":"Frostwild",
		"role":"Fast ranged pressure",
		"description":"A fragile-looking spirit with exceptional reach and attack cadence. Excellent for constant pressure while repositioning.",
		"command":4,
		"power":48,
		"damage":9.5,
		"cooldown":0.65,
		"range":310.0,
		"cost":{"gold":92,"mana":13,"iron":8}
	}
}

static func has(id:String) -> bool:
	return DATA.has(id)

static func data(id:String) -> Dictionary:
	var raw:Variant = DATA.get(id,{})
	if raw is Dictionary:
		return Dictionary(raw).duplicate(true)
	return {}

static func id_for_biome(biome:String) -> String:
	return String(BY_BIOME.get(biome,""))

static func display_name(id:String) -> String:
	return String(data(id).get("name",id.replace("_"," ").capitalize()))

static func biome(id:String) -> String:
	return String(data(id).get("biome","Unknown"))

static func role(id:String) -> String:
	return String(data(id).get("role","Wild companion"))

static func description(id:String) -> String:
	return String(data(id).get("description","A creature bonded on the frontier."))

static func command_cost(id:String) -> int:
	return int(data(id).get("command",1))

static func power(id:String) -> int:
	return int(data(id).get("power",10))

static func damage(id:String) -> float:
	return float(data(id).get("damage",6.0))

static func cooldown(id:String) -> float:
	return float(data(id).get("cooldown",1.0))

static func attack_range(id:String) -> float:
	return float(data(id).get("range",220.0))

static func recruitment_cost(id:String,amount:int=1) -> Dictionary:
	var base:Dictionary = data(id).get("cost",{}).duplicate(true)
	var result:Dictionary = {}
	for key in base:
		result[key] = int(base[key])*amount
	return result
