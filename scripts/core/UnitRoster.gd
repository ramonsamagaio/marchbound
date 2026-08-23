class_name UnitRoster
extends RefCounted

const ELITE_CHANCE := 1.0 / 96.0
const PREFIX_CHANCE := 0.42
const PREFIX_ORDER := ["swift","ironhide","blessed","vicious","ancient","stormtouched"]
const PREFIXES := {
	"swift":{"name":"Swift","description":"Attacks faster and reaches targets more easily.","damage":1.0,"cooldown":0.82,"range":1.08},
	"ironhide":{"name":"Ironhide","description":"A hardened veteran with steadier frontline pressure.","damage":1.12,"cooldown":1.0,"range":1.0},
	"blessed":{"name":"Blessed","description":"Successful attacks restore a little Warden health.","damage":1.04,"cooldown":0.96,"range":1.0,"heal":1.5},
	"vicious":{"name":"Vicious","description":"Deals much more damage to wounded enemies.","damage":1.10,"cooldown":0.96,"range":1.0,"execute":1.35},
	"ancient":{"name":"Ancient","description":"Rare lineage with stronger damage and extended reach.","damage":1.18,"cooldown":1.02,"range":1.18},
	"stormtouched":{"name":"Stormtouched","description":"Attacks can arc a fraction of their damage to a nearby foe.","damage":1.08,"cooldown":0.94,"range":1.04,"chain":0.28}
}

static func ensure_schema() -> void:
	if not GameState.player.has("unit_roster") or typeof(GameState.player.get("unit_roster",[])) != TYPE_ARRAY:
		var migrated:Array = []
		for family in GameState.army:
			for i in int(GameState.army.get(family,0)):
				migrated.append(_make_record(String(family),"",false))
		GameState.player["unit_roster"] = migrated
		GameState.player["unit_roster_version"] = 1
		return
	var roster:Array = GameState.player["unit_roster"]
	for family in GameState.army:
		var need := int(GameState.army.get(family,0)) - count_family(String(family),roster)
		for i in max(0,need):
			roster.append(roll_new(String(family)))
	GameState.player["unit_roster"] = roster
	GameState.player["unit_roster_version"] = 1

static func _make_record(family:String,prefix:String,elite:bool) -> Dictionary:
	return {
		"uid":"%s_%s_%s"%[family,Time.get_ticks_msec(),randi_range(1000,9999)],
		"family":family,
		"prefix":prefix,
		"elite":elite
	}

static func roll_new(family:String) -> Dictionary:
	var prefix := ""
	if randf() < PREFIX_CHANCE:
		prefix = String(PREFIX_ORDER[randi_range(0,PREFIX_ORDER.size()-1)])
	var elite := randf() < ELITE_CHANCE
	return _make_record(family,prefix,elite)

static func roster() -> Array:
	ensure_schema()
	return GameState.player["unit_roster"]

static func count_family(family:String,source:Array=[]) -> int:
	var use_source:Array = source if not source.is_empty() else GameState.player.get("unit_roster",[])
	var total := 0
	for unit in use_source:
		if String(unit.get("family","")) == family:
			total += 1
	return total

static func units_for_family(family:String) -> Array:
	ensure_schema()
	var result:Array=[]
	for unit in GameState.player["unit_roster"]:
		if String(unit.get("family",""))==family:
			result.append(unit)
	result.sort_custom(func(a,b):
		var ae:bool=bool(a.get("elite",false)); var be:bool=bool(b.get("elite",false))
		if ae!=be:return ae
		return String(a.get("prefix",""))!="" and String(b.get("prefix",""))=="")
	return result

static func battle_instances(max_per_family:=3) -> Array:
	ensure_schema()
	var out:Array=[]
	for family in GameState.army:
		var family_units=units_for_family(String(family))
		for i in min(max_per_family,family_units.size()):
			out.append(family_units[i].duplicate(true))
	return out

static func prefix_data(prefix:String) -> Dictionary:
	return PREFIXES.get(prefix,{})

static func display_name(record:Dictionary) -> String:
	var family:String=String(record.get("family",""))
	var base:=MonsterRoster.display_name(family) if MonsterRoster.has(family) else UnitProgression.display_name(family)
	var prefix:String=String(record.get("prefix",""))
	if prefix!="":
		base="%s %s"%[String(prefix_data(prefix).get("name",prefix.capitalize())),base]
	if bool(record.get("elite",false)):
		base+=" · ELITE"
	return base

static func quality_line(record:Dictionary) -> String:
	var bits:Array[String]=[]
	var prefix:String=String(record.get("prefix",""))
	if prefix!="":bits.append(String(prefix_data(prefix).get("name",prefix.capitalize())))
	if bool(record.get("elite",false)):bits.append("✦ ELITE")
	return " · ".join(bits) if not bits.is_empty() else "Standard"

static func damage_mult(record:Dictionary) -> float:
	var value:=float(prefix_data(String(record.get("prefix",""))).get("damage",1.0))
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
