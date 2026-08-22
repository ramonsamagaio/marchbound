class_name UnitProgression
extends RefCounted

const REQUIRED_RANK := 3
const UNIT_ORDER = ["militia", "archer", "wolf", "mage"]
const BASE_NAMES = {
	"militia":"Militia",
	"archer":"Archer",
	"wolf":"War Wolf",
	"mage":"Mage"
}

const BRANCHES = {
	"militia": {
		"vanguard": {
			"name":"Vanguard",
			"role":"Boss breaker",
			"description":"Heavy frontline killers. +35% damage and a further +55% against guardians and regional bosses.",
			"cost":{"gold":280,"food":160,"iron":25}
		},
		"shieldwall": {
			"name":"Shieldwall",
			"role":"Warden guard",
			"description":"Defensive escort. While Militia are deployed, incoming Warden damage is reduced by 15%. Shieldwall attacks deal +10% damage.",
			"cost":{"gold":260,"food":180,"iron":30}
		}
	},
	"archer": {
		"ranger": {
			"name":"Ranger",
			"role":"Mobile pressure",
			"description":"Fast skirmish volleys. 38% faster attacks, longer range and only a small damage tradeoff.",
			"cost":{"gold":320,"wood":120,"iron":20}
		},
		"longbow": {
			"name":"Longbow",
			"role":"Heavy ranged damage",
			"description":"Slow deliberate shots with extreme reach. +65% damage, but attacks 18% slower.",
			"cost":{"gold":340,"wood":150,"iron":28}
		}
	},
	"wolf": {
		"dire": {
			"name":"Dire Wolf",
			"role":"Executioner",
			"description":"Predatory burst damage. +45% damage, faster attacks and +50% damage against enemies below 45% health.",
			"cost":{"gold":340,"food":220,"mana":10}
		},
		"pack_alpha": {
			"name":"Pack Alpha",
			"role":"Army amplifier",
			"description":"A battlefield leader. +15% personal damage; if any War Wolves deploy, the entire army gains +12% damage.",
			"cost":{"gold":360,"food":240,"mana":14}
		}
	},
	"mage": {
		"stormcaller": {
			"name":"Stormcaller",
			"role":"Chain damage",
			"description":"Offensive caster. +20% damage and each attack chains into up to two nearby enemies for 35% of the hit.",
			"cost":{"gold":420,"mana":40,"iron":25}
		},
		"lifebinder": {
			"name":"Lifebinder",
			"role":"Sustain support",
			"description":"Support caster. Slightly lower damage, faster casts and every successful attack restores Warden health.",
			"cost":{"gold":400,"mana":45,"food":120}
		}
	}
}

static func ensure_schema() -> void:
	if not GameState.player.has("unit_evolutions") or typeof(GameState.player.get("unit_evolutions",{})) != TYPE_DICTIONARY:
		GameState.player["unit_evolutions"] = {}
	var evolutions:Dictionary = GameState.player["unit_evolutions"]
	for unit in UNIT_ORDER:
		if not evolutions.has(unit):
			evolutions[unit] = ""
	GameState.player["unit_evolutions"] = evolutions

static func evolution(unit:String) -> String:
	ensure_schema()
	return String(GameState.player["unit_evolutions"].get(unit,""))

static func is_evolved(unit:String) -> bool:
	return evolution(unit) != ""

static func branches_for(unit:String) -> Dictionary:
	return BRANCHES.get(unit,{})

static func branch_data(unit:String, branch:String) -> Dictionary:
	return branches_for(unit).get(branch,{})

static func display_name(unit:String) -> String:
	var branch = evolution(unit)
	if branch == "":
		return String(BASE_NAMES.get(unit,GameState.pretty(unit)))
	return String(branch_data(unit,branch).get("name",BASE_NAMES.get(unit,unit)))

static func evolution_cost(unit:String, branch:String) -> Dictionary:
	return branch_data(unit,branch).get("cost",{}).duplicate(true)

static func evolve(unit:String, branch:String) -> bool:
	ensure_schema()
	if unit not in UNIT_ORDER or not branches_for(unit).has(branch):
		return false
	if is_evolved(unit):
		GameState.toast_requested.emit("That unit family already chose an evolution path.")
		return false
	if int(GameState.unit_levels.get(unit,1)) < REQUIRED_RANK:
		GameState.toast_requested.emit("Train %s to Rank %d before evolving it." % [BASE_NAMES.get(unit,unit),REQUIRED_RANK])
		return false
	var cost = evolution_cost(unit,branch)
	if not GameState.spend(cost):
		GameState.toast_requested.emit("Evolution requires more frontier resources.")
		return false
	GameState.player["unit_evolutions"][unit] = branch
	var data = branch_data(unit,branch)
	GameState.toast_requested.emit("%s evolved into %s." % [BASE_NAMES.get(unit,unit),data.get("name",branch)])
	GameState.changed.emit()
	SaveManager.save_game()
	return true

static func evolution_summary(unit:String) -> String:
	var branch = evolution(unit)
	if branch == "":
		return "Unevolved"
	var data = branch_data(unit,branch)
	return "%s · %s" % [data.get("name",branch),data.get("role","")]
