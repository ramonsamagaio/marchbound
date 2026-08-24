class_name UnitRoster
extends RefCounted

const ELITE_CHANCE := 1.0 / 96.0
const PREFIX_CHANCE := 0.42
const PREFIX_ORDER := ["swift","ironhide","blessed","vicious","ancient","stormtouched"]
const ASSIGN_FIELD:String = "field"
const ASSIGN_GARRISON:String = "garrison"
const ASSIGN_RESERVE:String = "reserve"

const PREFIXES := {
	"swift":{"name":"Swift","description":"Attacks faster and reaches targets more easily.","damage":1.0,"cooldown":0.82,"range":1.08},
	"ironhide":{"name":"Ironhide","description":"A hardened veteran with steadier frontline pressure.","damage":1.12,"cooldown":1.0,"range":1.0},
	"blessed":{"name":"Blessed","description":"Successful attacks restore a little Warden health.","damage":1.04,"cooldown":0.96,"range":1.0,"heal":1.5},
	"vicious":{"name":"Vicious","description":"Deals much more damage to wounded enemies.","damage":1.10,"cooldown":0.96,"range":1.0,"execute":1.35},
	"ancient":{"name":"Ancient","description":"Rare lineage with stronger damage and extended reach.","damage":1.18,"cooldown":1.02,"range":1.18},
	"stormtouched":{"name":"Stormtouched","description":"Attacks can arc a fraction of their damage to a nearby foe.","damage":1.08,"cooldown":0.94,"range":1.04,"chain":0.28}
}

const NAMES:Dictionary = {
	"militia":["Alden","Bram","Celia","Doran","Elowen","Faris","Garrick","Hessa","Ivo","Janna","Kellan","Mara"],
	"archer":["Nessa","Orrin","Perrin","Rhea","Soren","Tala","Vey","Willa","Yara","Corin","Maeve","Lio"],
	"wolf":["Ash","Briar","Cinder","Fang","Moss","Rook","Sable","Thorn","Vale","Wisp","Rime","Ember"],
	"mage":["Aster","Cyra","Eiran","Ilyra","Merek","Noa","Orla","Rune","Sera","Tovin","Vesper","Ysra"]
}
const GENERIC_NAMES:Array[String] = ["Ari","Bex","Caro","Dain","Eris","Fen","Gale","Hale","Iris","Jory","Kerr","Luma","Miro","Nia","Oren","Pax"]

static func ensure_schema() -> void:
	if not GameState.player.has("unit_roster") or typeof(GameState.player.get("unit_roster",[])) != TYPE_ARRAY:
		var migrated:Array = []
		var field_cost:int = 0
		for family:Variant in GameState.army.keys():
			for _i:int in range(int(GameState.army.get(family,0))):
				var family_id:String = String(family)
				var cost:int = GameState.unit_command_cost(family_id)
				var assignment:String = ASSIGN_FIELD if field_cost+cost <= GameState.command_capacity() else ASSIGN_GARRISON
				if assignment == ASSIGN_FIELD: field_cost += cost
				migrated.append(_make_record(family_id,"",false,assignment))
		GameState.player["unit_roster"] = migrated
		GameState.player["unit_roster_version"] = 2
		return
	var roster:Array = GameState.player["unit_roster"]
	for i:int in range(roster.size()):
		if not (roster[i] is Dictionary):
			continue
		var record:Dictionary = Dictionary(roster[i])
		var family:String = String(record.get("family","militia"))
		if not record.has("name") or String(record.get("name","")) == "": record["name"] = _roll_name(family,String(record.get("uid","")))
		if not record.has("level"): record["level"] = 1
		if not record.has("xp"): record["xp"] = 0
		if not record.has("hp_pct"): record["hp_pct"] = 1.0
		if not record.has("assignment"): record["assignment"] = ASSIGN_FIELD
		if not record.has("deeds") or not record["deeds"] is Array: record["deeds"] = []
		if not record.has("kills"): record["kills"] = 0
		if not record.has("downed"): record["downed"] = 0
		roster[i] = record
	for family:Variant in GameState.army.keys():
		var family_id:String = String(family)
		var need:int = int(GameState.army.get(family_id,0))-count_family(family_id,roster)
		for _i:int in range(maxi(0,need)):
			roster.append(roll_new(family_id))
	GameState.player["unit_roster"] = roster
	GameState.player["unit_roster_version"] = 2
	_repair_field_capacity()

static func _make_record(family:String,prefix:String,elite:bool,assignment:String=ASSIGN_FIELD) -> Dictionary:
	var uid:String = "%s_%s_%s"%[family,Time.get_ticks_msec(),randi_range(1000,9999)]
	return {
		"uid":uid,"family":family,"prefix":prefix,"elite":elite,
		"name":_roll_name(family,uid),"level":1,"xp":0,"hp_pct":1.0,
		"assignment":assignment,"deeds":[],"kills":0,"downed":0
	}

static func _roll_name(family:String,salt:String="") -> String:
	var pool:Array = Array(NAMES.get(family,GENERIC_NAMES))
	if pool.is_empty(): return "Wardenborn"
	var index:int = abs(hash("%s:%s:%s"%[family,salt,Time.get_ticks_msec()]))%pool.size()
	return String(pool[index])

static func roll_new(family:String,assignment:String="auto") -> Dictionary:
	var prefix := ""
	if randf() < PREFIX_CHANCE: prefix = String(PREFIX_ORDER[randi_range(0,PREFIX_ORDER.size()-1)])
	var elite := randf() < ELITE_CHANCE
	var final_assignment:String = assignment
	if final_assignment == "auto":
		final_assignment = ASSIGN_FIELD if field_command_used()+GameState.unit_command_cost(family) <= GameState.command_capacity() else ASSIGN_GARRISON
	return _make_record(family,prefix,elite,final_assignment)

static func recruit_individual(family:String) -> bool:
	if MonsterRoster.has(family) and not GameState.monster_unlocked(family):
		GameState.toast_requested.emit("That Wild Bond has not been discovered yet.")
		return false
	var required_barracks:int = int({"militia":1,"archer":1,"wolf":1,"mage":2}.get(family,1))
	if int(GameState.buildings.get("barracks",0)) < required_barracks:
		GameState.toast_requested.emit("Barracks level %d required."%required_barracks)
		return false
	if family == "mage" and int(GameState.buildings.get("arcane_lab",0)) < 1:
		GameState.toast_requested.emit("Build an Arcane Lab first.")
		return false
	if not GameState.spend(GameState.recruitment_cost(family)):
		GameState.toast_requested.emit("Not enough resources to recruit.")
		return false
	ensure_schema()
	var roster:Array = GameState.player["unit_roster"]
	var record:Dictionary = roll_new(family)
	roster.append(record)
	GameState.player["unit_roster"] = roster
	GameState.army[family] = int(GameState.army.get(family,0))+1
	GameState.toast_requested.emit("%s joined the Warband · assigned to %s."%[display_name(record),String(record["assignment"]).capitalize()])
	GameState.changed.emit()
	return true

static func roster() -> Array:
	ensure_schema()
	return Array(GameState.player["unit_roster"])

static func count_family(family:String,source:Array=[]) -> int:
	var use_source:Array = source if not source.is_empty() else Array(GameState.player.get("unit_roster",[]))
	var total := 0
	for raw:Variant in use_source:
		if raw is Dictionary and String(Dictionary(raw).get("family","")) == family: total += 1
	return total

static func units_for_family(family:String) -> Array:
	ensure_schema()
	var result:Array=[]
	for raw:Variant in GameState.player["unit_roster"]:
		if raw is Dictionary and String(Dictionary(raw).get("family",""))==family: result.append(Dictionary(raw))
	result.sort_custom(func(a:Dictionary,b:Dictionary):
		if String(a.get("assignment",ASSIGN_FIELD)) != String(b.get("assignment",ASSIGN_FIELD)):
			return String(a.get("assignment",ASSIGN_FIELD)) < String(b.get("assignment",ASSIGN_FIELD))
		var ae:bool=bool(a.get("elite",false)); var be:bool=bool(b.get("elite",false))
		if ae!=be:return ae
		return int(a.get("level",1)) > int(b.get("level",1)))
	return result

static func field_units() -> Array:
	ensure_schema()
	var out:Array = []
	for raw:Variant in GameState.player["unit_roster"]:
		if raw is Dictionary and String(Dictionary(raw).get("assignment",ASSIGN_FIELD)) == ASSIGN_FIELD:
			out.append(Dictionary(raw).duplicate(true))
	return out

static func garrison_units() -> Array:
	ensure_schema()
	var out:Array = []
	for raw:Variant in GameState.player["unit_roster"]:
		if raw is Dictionary and String(Dictionary(raw).get("assignment",ASSIGN_FIELD)) == ASSIGN_GARRISON:
			out.append(Dictionary(raw).duplicate(true))
	return out

static func reserve_units() -> Array:
	ensure_schema()
	var out:Array = []
	for raw:Variant in GameState.player["unit_roster"]:
		if raw is Dictionary and String(Dictionary(raw).get("assignment",ASSIGN_FIELD)) == ASSIGN_RESERVE:
			out.append(Dictionary(raw).duplicate(true))
	return out

static func field_command_used() -> int:
	var total:int = 0
	var source:Array = Array(GameState.player.get("unit_roster",[]))
	for raw:Variant in source:
		if not (raw is Dictionary): continue
		var record:Dictionary = Dictionary(raw)
		if String(record.get("assignment",ASSIGN_FIELD)) == ASSIGN_FIELD:
			total += GameState.unit_command_cost(String(record.get("family","militia")))
	return total

static func set_assignment(uid:String,assignment:String) -> bool:
	if assignment not in [ASSIGN_FIELD,ASSIGN_GARRISON,ASSIGN_RESERVE]: return false
	ensure_schema()
	var roster:Array = GameState.player["unit_roster"]
	for i:int in range(roster.size()):
		if not (roster[i] is Dictionary): continue
		var record:Dictionary = Dictionary(roster[i])
		if String(record.get("uid","")) != uid: continue
		if assignment == ASSIGN_FIELD and String(record.get("assignment","")) != ASSIGN_FIELD:
			var cost:int = GameState.unit_command_cost(String(record.get("family","militia")))
			if field_command_used()+cost > GameState.command_capacity():
				GameState.toast_requested.emit("Field command capacity reached. Leave someone in the garrison first.")
				return false
		record["assignment"] = assignment
		roster[i] = record
		GameState.player["unit_roster"] = roster
		GameState.toast_requested.emit("%s → %s"%[display_name(record),assignment.capitalize()])
		GameState.changed.emit()
		return true
	return false

static func _repair_field_capacity() -> void:
	var roster:Array = GameState.player.get("unit_roster",[])
	var used:int = 0
	for i:int in range(roster.size()):
		if not (roster[i] is Dictionary): continue
		var record:Dictionary = Dictionary(roster[i])
		if String(record.get("assignment",ASSIGN_FIELD)) != ASSIGN_FIELD: continue
		var cost:int = GameState.unit_command_cost(String(record.get("family","militia")))
		if used+cost <= GameState.command_capacity(): used += cost
		else:
			record["assignment"] = ASSIGN_GARRISON
			roster[i] = record
	GameState.player["unit_roster"] = roster

static func battle_instances(max_per_family:=3) -> Array:
	ensure_schema()
	var out:Array=[]
	var by_family:Dictionary = {}
	for raw:Variant in field_units():
		var record:Dictionary = Dictionary(raw)
		var family:String = String(record.get("family","militia"))
		var count:int = int(by_family.get(family,0))
		if count >= max_per_family: continue
		by_family[family] = count+1
		out.append(record.duplicate(true))
	return out

static func all_field_instances(max_total:int=24) -> Array:
	var source:Array = field_units()
	if source.size() <= max_total: return source
	return source.slice(0,max_total)

static func record_by_uid(uid:String) -> Dictionary:
	ensure_schema()
	for raw:Variant in GameState.player["unit_roster"]:
		if raw is Dictionary and String(Dictionary(raw).get("uid","")) == uid:
			return Dictionary(raw).duplicate(true)
	return {}

static func rename(uid:String,new_name:String) -> bool:
	var clean:String = new_name.strip_edges().substr(0,18)
	if clean == "": return false
	return _mutate(uid,func(record:Dictionary): record["name"] = clean)

static func add_xp(uid:String,amount:int) -> void:
	if amount <= 0: return
	_mutate(uid,func(record:Dictionary):
		record["xp"] = int(record.get("xp",0))+amount
		while int(record.get("xp",0)) >= xp_to_next(int(record.get("level",1))):
			record["xp"] = int(record.get("xp",0))-xp_to_next(int(record.get("level",1)))
			record["level"] = int(record.get("level",1))+1
	)

static func add_kill(uid:String,elite:bool=false,boss:bool=false) -> void:
	_mutate(uid,func(record:Dictionary):
		record["kills"] = int(record.get("kills",0))+1
		var deeds:Array = Array(record.get("deeds",[]))
		if boss:
			deeds.append("Bossbreaker")
		elif elite and int(record["kills"])%7 == 0:
			deeds.append("Elite Hunter")
		if deeds.size() > 5: deeds.pop_front()
		record["deeds"] = deeds
	)

static func persist_hp(uid:String,hp_pct:float) -> void:
	_mutate(uid,func(record:Dictionary): record["hp_pct"] = clampf(hp_pct,0.0,1.0))

static func xp_to_next(level:int) -> int:
	return 24 + level*18

static func _mutate(uid:String,callable:Callable) -> bool:
	ensure_schema()
	var roster:Array = GameState.player["unit_roster"]
	for i:int in range(roster.size()):
		if not (roster[i] is Dictionary): continue
		var record:Dictionary = Dictionary(roster[i])
		if String(record.get("uid","")) != uid: continue
		callable.call(record)
		roster[i] = record
		GameState.player["unit_roster"] = roster
		GameState.changed.emit()
		return true
	return false

static func prefix_data(prefix:String) -> Dictionary:
	return PREFIXES.get(prefix,{})

static func display_name(record:Dictionary) -> String:
	var family:String=String(record.get("family",""))
	var family_name:String=MonsterRoster.display_name(family) if MonsterRoster.has(family) else UnitProgression.display_name(family)
	var personal:String = String(record.get("name",""))
	var base:String = "%s · %s"%[personal,family_name] if personal != "" else family_name
	var prefix:String=String(record.get("prefix",""))
	if prefix!="": base="%s %s"%[String(prefix_data(prefix).get("name",prefix.capitalize())),base]
	if bool(record.get("elite",false)): base+=" · ELITE"
	return base

static func quality_line(record:Dictionary) -> String:
	var bits:Array[String]=[]
	bits.append("Lv.%d"%int(record.get("level",1)))
	var prefix:String=String(record.get("prefix",""))
	if prefix!="":bits.append(String(prefix_data(prefix).get("name",prefix.capitalize())))
	if bool(record.get("elite",false)):bits.append("✦ ELITE")
	bits.append(String(record.get("assignment",ASSIGN_FIELD)).capitalize())
	return " · ".join(bits)

static func damage_mult(record:Dictionary) -> float:
	var value:=float(prefix_data(String(record.get("prefix",""))).get("damage",1.0))
	value *= 1.0+float(maxi(0,int(record.get("level",1))-1))*0.035
	if bool(record.get("elite",false)):value*=1.16
	return value

static func cooldown_mult(record:Dictionary) -> float:
	var value:=float(prefix_data(String(record.get("prefix",""))).get("cooldown",1.0))
	if bool(record.get("elite",false)):value*=0.90
	return value

static func range_mult(record:Dictionary) -> float:
	var value:=float(prefix_data(String(record.get("prefix",""))).get("range",1.0))
	if bool(record.get("elite",false)):value*=1.05
	return value

static func heal_on_hit(record:Dictionary) -> float:
	return float(prefix_data(String(record.get("prefix",""))).get("heal",0.0))*(1.25 if bool(record.get("elite",false)) else 1.0)

static func execute_mult(record:Dictionary,target_hp_ratio:float) -> float:
	if target_hp_ratio>=0.45:return 1.0
	return float(prefix_data(String(record.get("prefix",""))).get("execute",1.0))

static func chain_ratio(record:Dictionary) -> float:
	return float(prefix_data(String(record.get("prefix",""))).get("chain",0.0))
