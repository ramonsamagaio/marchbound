extends Node

signal changed

const META_KEY:String = "frontier_meta"
const DISCOVERY_PATH:String = "res://data/content/discoveries.json"

var discovery_catalog:Dictionary = {}

const MARK_NAMES:Dictionary = {
	"blood_tempered":"Blood-Tempered",
	"moon_mark":"Moon Mark",
	"hunger_debt":"Hunger Debt",
	"time_debt":"Time Debt",
	"grave_oath":"Grave Oath"
}

const ECHO_NAMES:Dictionary = {
	"storm_echo":"Storm Echo",
	"moonlit":"Moonlit Echo",
	"voidglass":"Voidglass Echo",
	"gravebound":"Gravebound Echo",
	"wildheart":"Wildheart Echo"
}

const LEGACY_NAMES:Dictionary = {
	"oathkeeper":"Oathkeeper",
	"beastfriend":"Beastfriend",
	"roadborn":"Roadborn",
	"last_stand":"Last Stand",
	"storm_banner":"Storm Banner"
}

const RARITY_INSIGHT:Dictionary = {
	"common":1,
	"uncommon":2,
	"rare":4,
	"epic":7,
	"legendary":10
}

func _ready() -> void:
	reload_discoveries()
	ensure_schema()

func reload_discoveries() -> void:
	discovery_catalog = {}
	if not FileAccess.file_exists(DISCOVERY_PATH):
		push_error("FrontierManager missing discovery catalog")
		return
	var file:FileAccess = FileAccess.open(DISCOVERY_PATH,FileAccess.READ)
	if file == null:
		return
	var parsed:Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		discovery_catalog = Dictionary(parsed)
	else:
		push_error("FrontierManager invalid discoveries.json")

func discovery(id:String) -> Dictionary:
	var raw:Variant = discovery_catalog.get(id,{})
	return Dictionary(raw).duplicate(true) if raw is Dictionary else {}

func discovery_ids() -> Array[String]:
	var result:Array[String] = []
	for raw_id:Variant in discovery_catalog.keys():
		result.append(String(raw_id))
	result.sort()
	return result

func validate_discoveries() -> Array[String]:
	var errors:Array[String] = []
	for id:String in discovery_ids():
		var definition:Dictionary = discovery(id)
		var choices:Array = Array(definition.get("choices",[]))
		if choices.size() < 2:
			errors.append("%s has fewer than two choices"%id)
		for raw_choice:Variant in choices:
			if not (raw_choice is Dictionary):
				errors.append("%s contains a non-dictionary choice"%id)
				continue
			var choice:Dictionary = Dictionary(raw_choice)
			if String(choice.get("id","")) == "":
				errors.append("%s contains a choice without id"%id)
	return errors

func _default_meta() -> Dictionary:
	return {
		"rumor":{"active":false,"x":0,"y":0,"discovery_id":"","name":"","clue":"","reward_renown":0},
		"rumors_resolved":0,
		"rumor_streak":0,
		"discoveries":{},
		"codex":[],
		"insight":0,
		"wonder":0,
		"last_discovery":"",
		"marks":{},
		"warband_legacies":{},
		"last_run":[]
	}

func ensure_schema() -> void:
	GameState.ensure_schema()
	var meta:Dictionary = Dictionary(GameState.world.get(META_KEY,{}))
	var defaults:Dictionary = _default_meta()
	for raw_key:Variant in defaults.keys():
		var key:String = String(raw_key)
		if not meta.has(key):
			meta[key] = defaults[key]
	if not (meta["rumor"] is Dictionary):
		meta["rumor"] = defaults["rumor"]
	if not (meta["discoveries"] is Dictionary):
		meta["discoveries"] = {}
	if not (meta["codex"] is Array):
		meta["codex"] = []
	if not (meta["marks"] is Dictionary):
		meta["marks"] = {}
	if not (meta["warband_legacies"] is Dictionary):
		meta["warband_legacies"] = {}
	if not (meta["last_run"] is Array):
		meta["last_run"] = []
	GameState.world[META_KEY] = meta

func reset(emit_signal:bool=true) -> void:
	GameState.world[META_KEY] = _default_meta()
	if emit_signal:
		changed.emit()

func _meta() -> Dictionary:
	ensure_schema()
	return Dictionary(GameState.world[META_KEY])

func _store(meta:Dictionary,emit_signal:bool=true) -> void:
	GameState.world[META_KEY] = meta
	if emit_signal:
		changed.emit()

func begin_expedition(_tile:Dictionary) -> void:
	var meta:Dictionary = _meta()
	meta["last_run"] = []
	_store(meta,false)

func rumor() -> Dictionary:
	return Dictionary(_meta().get("rumor",{})).duplicate(true)

func rumor_for(x:int,y:int) -> bool:
	var data:Dictionary = rumor()
	return bool(data.get("active",false)) and int(data.get("x",0)) == x and int(data.get("y",0)) == y

func ensure_rumor(force:bool=false) -> Dictionary:
	var meta:Dictionary = _meta()
	var current:Dictionary = Dictionary(meta.get("rumor",{}))
	if bool(current.get("active",false)) and not force:
		return current.duplicate(true)
	var candidates:Array[Vector2i] = _frontier_candidates()
	var ids:Array[String] = discovery_ids()
	if candidates.is_empty() or ids.is_empty():
		return {}
	var local_rng:=RandomNumberGenerator.new()
	local_rng.seed = int(GameState.world.get("seed",947213)) + int(meta.get("rumors_resolved",0))*7919 + int(meta.get("insight",0))*131 + int(meta.get("wonder",0))*17
	var coordinate:Vector2i = candidates[local_rng.randi_range(0,candidates.size()-1)]
	var discovery_id:String = _pick_rumor_discovery(ids,local_rng)
	var definition:Dictionary = discovery(discovery_id)
	var reward_renown:int = 4 + atlas_level()*2 + int(meta.get("rumor_streak",0))
	var next_rumor:Dictionary = {
		"active":true,
		"x":coordinate.x,
		"y":coordinate.y,
		"discovery_id":discovery_id,
		"name":String(definition.get("name",discovery_id.capitalize())),
		"clue":_rumor_clue(definition,coordinate),
		"reward_renown":reward_renown
	}
	meta["rumor"] = next_rumor
	_store(meta)
	return next_rumor.duplicate(true)

func _pick_rumor_discovery(ids:Array[String],local_rng:RandomNumberGenerator) -> String:
	var weighted:Array[String] = []
	for id:String in ids:
		var definition:Dictionary = discovery(id)
		if bool(definition.get("rumor_enabled",true)) == false:
			continue
		var rarity:String = String(definition.get("rarity","common"))
		var copies:int = {"common":1,"uncommon":3,"rare":5,"epic":3,"legendary":1}.get(rarity,1)
		for _i:int in range(copies):
			weighted.append(id)
	if weighted.is_empty():
		return ids[local_rng.randi_range(0,ids.size()-1)]
	return weighted[local_rng.randi_range(0,weighted.size()-1)]

func _rumor_clue(definition:Dictionary,coordinate:Vector2i) -> String:
	var rarity:String = String(definition.get("rarity","common")).capitalize()
	return "%s anomaly reported near territory [%d,%d]. The report specifically mentions %s."%[rarity,coordinate.x,coordinate.y,String(definition.get("name","something impossible"))]

func _frontier_candidates() -> Array[Vector2i]:
	var result:Array[Vector2i] = []
	var seen:Dictionary = {}
	var conquered:Dictionary = Dictionary(GameState.world.get("conquered",{}))
	for raw_key:Variant in conquered.keys():
		var parts:PackedStringArray = String(raw_key).split(":")
		if parts.size() != 2:
			continue
		var origin:=Vector2i(int(parts[0]),int(parts[1]))
		for direction:Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var point:Vector2i = origin + direction
			if GameState.is_conquered(point.x,point.y):
				continue
			var key:String = "%d:%d"%[point.x,point.y]
			if seen.has(key):
				continue
			seen[key] = true
			result.append(point)
	return result

func record_discovery(discovery_id:String,choice_id:String,tile:Dictionary) -> void:
	var definition:Dictionary = discovery(discovery_id)
	if definition.is_empty():
		return
	var meta:Dictionary = _meta()
	var counts:Dictionary = Dictionary(meta.get("discoveries",{}))
	counts[discovery_id] = int(counts.get(discovery_id,0))+1
	meta["discoveries"] = counts
	var codex:Array = Array(meta.get("codex",[]))
	var first_time:bool = discovery_id not in codex
	if first_time:
		codex.append(discovery_id)
	meta["codex"] = codex
	var rarity:String = String(definition.get("rarity","common"))
	var insight_gain:int = int(RARITY_INSIGHT.get(rarity,1)) + (2 if first_time else 0)
	meta["insight"] = int(meta.get("insight",0))+insight_gain
	var previous:String = String(meta.get("last_discovery",""))
	if first_time:
		meta["wonder"] = mini(12,int(meta.get("wonder",0))+2)
	elif previous != discovery_id:
		meta["wonder"] = mini(12,int(meta.get("wonder",0))+1)
	meta["last_discovery"] = discovery_id
	var last_run:Array = Array(meta.get("last_run",[]))
	last_run.append({"id":discovery_id,"name":String(definition.get("name",discovery_id)),"choice":choice_id,"rarity":rarity})
	meta["last_run"] = last_run
	var active_rumor:Dictionary = Dictionary(meta.get("rumor",{}))
	if bool(active_rumor.get("active",false)) and int(active_rumor.get("x",0)) == int(tile.get("x",0)) and int(active_rumor.get("y",0)) == int(tile.get("y",0)) and String(active_rumor.get("discovery_id","")) == discovery_id:
		active_rumor["active"] = false
		meta["rumor"] = active_rumor
		meta["rumors_resolved"] = int(meta.get("rumors_resolved",0))+1
		meta["rumor_streak"] = int(meta.get("rumor_streak",0))+1
		var reward:int = int(active_rumor.get("reward_renown",4))
		GameState.player["renown"] = int(GameState.player.get("renown",0))+reward
		GameState.add_resources({"mana":maxi(1,1+int(floor(float(meta.get("rumor_streak",0))/2.0)))})
		GameState.toast_requested.emit("RUMOR PROVEN · %s · +%d Renown"%[String(active_rumor.get("name","Anomaly")),reward])
	_store(meta)

func last_run_discoveries() -> Array:
	return Array(_meta().get("last_run",[])).duplicate(true)

func discovery_count(discovery_id:String) -> int:
	return int(Dictionary(_meta().get("discoveries",{})).get(discovery_id,0))

func codex_count() -> int:
	return Array(_meta().get("codex",[])).size()

func insight() -> int:
	return int(_meta().get("insight",0))

func add_insight(amount:int) -> void:
	if amount <= 0:
		return
	var meta:Dictionary = _meta()
	meta["insight"] = int(meta.get("insight",0))+amount
	_store(meta)

func wonder() -> int:
	return int(_meta().get("wonder",0))

func atlas_level() -> int:
	return int(floor(float(codex_count())/3.0))

func rarity_multiplier() -> float:
	return 1.0 + float(wonder())*0.08 + float(atlas_level())*0.12

func add_mark(mark_id:String) -> void:
	if mark_id == "":
		return
	var meta:Dictionary = _meta()
	var marks:Dictionary = Dictionary(meta.get("marks",{}))
	marks[mark_id] = mini(3,int(marks.get(mark_id,0))+1)
	meta["marks"] = marks
	_store(meta)
	GameState.toast_requested.emit("CAMPAIGN MARK · %s"%mark_name(mark_id))

func remove_mark(mark_id:String="oldest") -> bool:
	var meta:Dictionary = _meta()
	var marks:Dictionary = Dictionary(meta.get("marks",{}))
	if marks.is_empty():
		return false
	var target:String = mark_id
	if target == "oldest" or not marks.has(target):
		target = String(marks.keys()[0])
	var count:int = int(marks.get(target,0))
	if count <= 1:
		marks.erase(target)
	else:
		marks[target] = count-1
	meta["marks"] = marks
	_store(meta)
	GameState.toast_requested.emit("MARK ERASED · %s"%mark_name(target))
	return true

func mark_name(mark_id:String) -> String:
	return String(MARK_NAMES.get(mark_id,mark_id.replace("_"," ").capitalize()))

func echo_name(echo_id:String) -> String:
	return String(ECHO_NAMES.get(echo_id,echo_id.replace("_"," ").capitalize()))

func legacy_name(legacy_id:String) -> String:
	return String(LEGACY_NAMES.get(legacy_id,legacy_id.replace("_"," ").capitalize()))

func mark_summary() -> String:
	var marks:Dictionary = Dictionary(_meta().get("marks",{}))
	var parts:Array[String] = []
	for raw_id:Variant in marks.keys():
		var id:String = String(raw_id)
		parts.append("%s ×%d"%[mark_name(id),int(marks[id])])
	return " · ".join(parts)

func awaken_weapon_echo(echo_id:String) -> bool:
	if echo_id == "":
		return false
	var uid:String = String(GameState.equipped.get("weapon",""))
	if uid == "":
		return false
	for i:int in range(GameState.inventory.size()):
		var item:Dictionary = GameState.inventory[i]
		if String(item.get("uid","")) != uid:
			continue
		var echoes:Array = Array(item.get("echo_traits",[]))
		if echo_id in echoes:
			add_weapon_memory(35,"Echo resonance")
			return false
		if echoes.size() >= 4:
			echoes.pop_front()
		echoes.append(echo_id)
		item["echo_traits"] = echoes
		GameState.inventory[i] = item
		GameState.changed.emit()
		GameState.toast_requested.emit("WEAPON ECHO AWAKENED · %s"%echo_name(echo_id))
		changed.emit()
		return true
	return false

func add_weapon_memory(amount:int,memory_label:String="") -> void:
	if amount <= 0:
		return
	var uid:String = String(GameState.equipped.get("weapon",""))
	if uid == "":
		return
	for i:int in range(GameState.inventory.size()):
		var item:Dictionary = GameState.inventory[i]
		if String(item.get("uid","")) != uid:
			continue
		var old_rank:int = int(item.get("memory_rank",0))
		item["memory_xp"] = int(item.get("memory_xp",0))+amount
		var new_rank:int = 0
		for rank_index:int in range(RetentionManager.MEMORY_THRESHOLDS.size()):
			if int(item["memory_xp"]) >= RetentionManager.MEMORY_THRESHOLDS[rank_index]:
				new_rank = rank_index
		item["memory_rank"] = new_rank
		if memory_label != "":
			var memories:Array = Array(item.get("memories",[]))
			if memory_label not in memories:
				memories.append(memory_label)
				if memories.size() > 6:
					memories.pop_front()
			item["memories"] = memories
		GameState.inventory[i] = item
		GameState.changed.emit()
		if new_rank > old_rank:
			GameState.toast_requested.emit("WEAPON MEMORY AWAKENED · %s reached Memory %d"%[String(item.get("name","Weapon")),new_rank])
		changed.emit()
		return

func grant_warband_legacy(legacy_id:String,preferred_unit:String="") -> bool:
	if legacy_id == "":
		return false
	var unit:String = preferred_unit if preferred_unit != "" and int(GameState.army.get(preferred_unit,0)) > 0 else _preferred_army_unit()
	if unit == "":
		return false
	var meta:Dictionary = _meta()
	var legacies:Dictionary = Dictionary(meta.get("warband_legacies",{}))
	var unit_legacies:Array = Array(legacies.get(unit,[]))
	if legacy_id in unit_legacies:
		meta["insight"] = int(meta.get("insight",0))+1
		_store(meta)
		return false
	if unit_legacies.size() >= 3:
		unit_legacies.pop_front()
	unit_legacies.append(legacy_id)
	legacies[unit] = unit_legacies
	meta["warband_legacies"] = legacies
	_store(meta)
	GameState.toast_requested.emit("WARBAND LEGACY · %s learned %s"%[GameState.pretty(unit),legacy_name(legacy_id)])
	return true

func _preferred_army_unit() -> String:
	var best_unit:String = ""
	var best_count:int = 0
	for raw_unit:Variant in GameState.army.keys():
		var unit:String = String(raw_unit)
		var count:int = int(GameState.army.get(unit,0))
		if count > best_count:
			best_count = count
			best_unit = unit
	return best_unit

func legacy_summary() -> String:
	var legacies:Dictionary = Dictionary(_meta().get("warband_legacies",{}))
	var parts:Array[String] = []
	for raw_unit:Variant in legacies.keys():
		var unit:String = String(raw_unit)
		var names:Array[String] = []
		for raw_legacy:Variant in Array(legacies[unit]):
			names.append(legacy_name(String(raw_legacy)))
		parts.append("%s: %s"%[GameState.pretty(unit),", ".join(names)])
	return " · ".join(parts)

func combat_bonuses() -> Dictionary:
	var result:Dictionary = {
		"damage_mult":1.0,
		"hp_mult":1.0,
		"move_speed_mult":1.0,
		"attack_speed_mult":1.0,
		"crit_add":0.0,
		"arc_chance_add":0.0,
		"lifesteal_add":0.0,
		"fortune_add":0.0,
		"army_damage_mult":1.0,
		"army_haste_mult":1.0,
		"projectile_bonus":0,
		"enemy_hp_mult":1.0,
		"enemy_speed_mult":1.0,
		"enemy_damage_mult":1.0
	}
	var meta:Dictionary = _meta()
	var marks:Dictionary = Dictionary(meta.get("marks",{}))
	for raw_mark:Variant in marks.keys():
		var mark_id:String = String(raw_mark)
		var count:int = int(marks[mark_id])
		match mark_id:
			"blood_tempered":
				result["damage_mult"] = float(result["damage_mult"])*pow(1.05,count)
				result["hp_mult"] = float(result["hp_mult"])*pow(0.97,count)
			"moon_mark":
				result["crit_add"] = float(result["crit_add"])+0.02*count
				result["arc_chance_add"] = float(result["arc_chance_add"])+0.05*count
			"hunger_debt":
				result["fortune_add"] = float(result["fortune_add"])+0.035*count
				result["enemy_hp_mult"] = float(result["enemy_hp_mult"])*pow(1.035,count)
			"time_debt":
				result["attack_speed_mult"] = float(result["attack_speed_mult"])*pow(1.035,count)
				result["enemy_speed_mult"] = float(result["enemy_speed_mult"])*pow(1.025,count)
			"grave_oath":
				result["army_damage_mult"] = float(result["army_damage_mult"])*pow(1.04,count)
	var legacies:Dictionary = Dictionary(meta.get("warband_legacies",{}))
	for raw_unit:Variant in legacies.keys():
		for raw_legacy:Variant in Array(legacies[raw_unit]):
			match String(raw_legacy):
				"oathkeeper": result["army_damage_mult"] = float(result["army_damage_mult"])*1.055
				"beastfriend": result["army_haste_mult"] = float(result["army_haste_mult"])*0.95
				"roadborn": result["move_speed_mult"] = float(result["move_speed_mult"])*1.035
				"last_stand": result["hp_mult"] = float(result["hp_mult"])*1.04
				"storm_banner": result["arc_chance_add"] = float(result["arc_chance_add"])+0.04
	var weapon:Dictionary = GameState.get_item(String(GameState.equipped.get("weapon","")))
	for raw_echo:Variant in Array(weapon.get("echo_traits",[])):
		match String(raw_echo):
			"storm_echo":
				result["attack_speed_mult"] = float(result["attack_speed_mult"])*1.08
				result["arc_chance_add"] = float(result["arc_chance_add"])+0.10
			"moonlit":
				result["crit_add"] = float(result["crit_add"])+0.045
			"voidglass":
				result["projectile_bonus"] = int(result["projectile_bonus"])+1
				result["hp_mult"] = float(result["hp_mult"])*0.94
			"gravebound":
				result["lifesteal_add"] = float(result["lifesteal_add"])+0.015
				result["army_damage_mult"] = float(result["army_damage_mult"])*1.04
			"wildheart":
				result["move_speed_mult"] = float(result["move_speed_mult"])*1.06
				result["damage_mult"] = float(result["damage_mult"])*1.04
	return result
