class_name FrontierMutations
extends RefCounted

const ORDER = ["swarming","frenzied","ironhide","elite_hunt","rich_veins","arcane_storm"]

const DEFINITIONS = {
	"swarming": {
		"name":"Swarming Brood",
		"description":"Extra enemies enter every wave. Individual bodies are slightly softer, but the battlefield fills much faster.",
		"reward":"+15% Gold from combat",
		"effects":{"spawn_bonus":1,"enemy_hp":0.92,"gold":1.15}
	},
	"frenzied": {
		"name":"Frenzied Hunt",
		"description":"Enemies move faster and hit harder. Momentum becomes easier to build, but mistakes are punished quickly.",
		"reward":"+20% expedition XP",
		"effects":{"enemy_speed":1.18,"enemy_damage":1.12,"xp":1.20}
	},
	"ironhide": {
		"name":"Ironhide Territory",
		"description":"Everything here is harder to kill. Guardians and ordinary enemies both carry thickened armor.",
		"reward":"+10% gear-drop chance",
		"effects":{"enemy_hp":1.30,"rarity":0.10}
	},
	"elite_hunt": {
		"name":"Marked by Elites",
		"description":"Elite champions appear far more often, turning normal packs into sudden priority targets.",
		"reward":"+15% combat Gold · +6% gear-drop chance",
		"effects":{"elite":0.10,"gold":1.15,"rarity":0.06}
	},
	"rich_veins": {
		"name":"Rich Veins",
		"description":"The territory is unusually dense with harvest sites. Fighting around them is the opportunity and the trap.",
		"reward":"+2 resource sites · +25% harvested yield",
		"effects":{"resource_nodes":2,"harvest":1.25}
	},
	"arcane_storm": {
		"name":"Arcane Storm",
		"description":"Hostile projectiles travel faster and enemy attacks bite harder while unstable Mana saturates the region.",
		"reward":"Bonus Mana on victory · +4% gear-drop chance",
		"effects":{"projectile_speed":1.25,"enemy_damage":1.08,"rarity":0.04,"victory_mana":3}
	}
}

static func roll(hashv:int,threat:int,boss:bool=false) -> Array:
	if threat < 2:
		return []
	var count := 1
	if threat >= 7:
		count = 2
	if boss and threat >= 9:
		count = 2
	var result := []
	var start = abs(int(hashv / 97)) % ORDER.size()
	var step = 1 + (abs(int(hashv / 193)) % (ORDER.size()-1))
	var cursor = start
	while result.size() < count:
		var id=String(ORDER[cursor%ORDER.size()])
		if id not in result:
			result.append(id)
		cursor += step
	return result

static func definition(id:String) -> Dictionary:
	return DEFINITIONS.get(id,{})

static func name(id:String) -> String:
	return String(definition(id).get("name",id.capitalize()))

static func description(id:String) -> String:
	return String(definition(id).get("description",""))

static func reward_text(id:String) -> String:
	return String(definition(id).get("reward",""))

static func combined_effects(ids:Array) -> Dictionary:
	var result={
		"spawn_bonus":0,
		"enemy_hp":1.0,
		"enemy_speed":1.0,
		"enemy_damage":1.0,
		"elite":0.0,
		"gold":1.0,
		"xp":1.0,
		"rarity":0.0,
		"resource_nodes":0,
		"harvest":1.0,
		"projectile_speed":1.0,
		"victory_mana":0
	}
	for id in ids:
		var effects:Dictionary = definition(String(id)).get("effects",{})
		result.spawn_bonus += int(effects.get("spawn_bonus",0))
		result.enemy_hp *= float(effects.get("enemy_hp",1.0))
		result.enemy_speed *= float(effects.get("enemy_speed",1.0))
		result.enemy_damage *= float(effects.get("enemy_damage",1.0))
		result.elite += float(effects.get("elite",0.0))
		result.gold *= float(effects.get("gold",1.0))
		result.xp *= float(effects.get("xp",1.0))
		result.rarity += float(effects.get("rarity",0.0))
		result.resource_nodes += int(effects.get("resource_nodes",0))
		result.harvest *= float(effects.get("harvest",1.0))
		result.projectile_speed *= float(effects.get("projectile_speed",1.0))
		result.victory_mana += int(effects.get("victory_mana",0))
	return result

static func names(ids:Array) -> String:
	var labels := []
	for id in ids:
		labels.append(name(String(id)))
	return " · ".join(labels)
