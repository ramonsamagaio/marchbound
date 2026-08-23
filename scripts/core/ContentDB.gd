extends Node

signal content_changed(category:String,id:String)

const FILES:Dictionary = {
	"attacks":"res://data/content/attacks.json",
	"projectiles":"res://data/content/projectiles.json",
	"items":"res://data/content/items.json",
	"monsters":"res://data/content/monsters.json",
	"tiles":"res://data/content/tiles.json",
	"statuses":"res://data/content/statuses.json",
	"buildings":"res://data/content/buildings.json"
}
const OVERRIDE_PATH:String = "user://marchbound_content_overrides.json"

var catalogs:Dictionary = {}
var overrides:Dictionary = {}

func _ready() -> void:
	reload_all()

func reload_all() -> void:
	catalogs.clear()
	for category:Variant in FILES.keys():
		catalogs[String(category)] = _load_json(String(FILES[category]))
	overrides = _load_json(OVERRIDE_PATH) if FileAccess.file_exists(OVERRIDE_PATH) else {}
	_apply_overrides()

func _load_json(path:String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("ContentDB missing %s"%path)
		return {}
	var file:FileAccess = FileAccess.open(path,FileAccess.READ)
	if file == null:
		return {}
	var parsed:Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return Dictionary(parsed)
	push_error("ContentDB invalid JSON: %s"%path)
	return {}

func _apply_overrides() -> void:
	for category:Variant in overrides.keys():
		var category_name:String = String(category)
		if not catalogs.has(category_name) or not overrides[category] is Dictionary:
			continue
		var category_overrides:Dictionary = Dictionary(overrides[category])
		for id:Variant in category_overrides.keys():
			catalogs[category_name][String(id)] = Dictionary(category_overrides[id]).duplicate(true)

func get_entry(category:String,id:String) -> Dictionary:
	if not catalogs.has(category):
		return {}
	var raw:Variant = Dictionary(catalogs[category]).get(id,{})
	return Dictionary(raw).duplicate(true) if raw is Dictionary else {}

func all(category:String) -> Dictionary:
	var raw:Variant = catalogs.get(category,{})
	return Dictionary(raw).duplicate(true) if raw is Dictionary else {}

func ids(category:String) -> Array[String]:
	var result:Array[String] = []
	if not catalogs.has(category):
		return result
	for id:Variant in Dictionary(catalogs[category]).keys():
		result.append(String(id))
	result.sort()
	return result

func update_entry(category:String,id:String,data:Dictionary,persist:bool=true) -> void:
	if not catalogs.has(category):
		catalogs[category] = {}
	catalogs[category][id] = data.duplicate(true)
	if persist:
		if not overrides.has(category):
			overrides[category] = {}
		overrides[category][id] = data.duplicate(true)
		_save_overrides()
	content_changed.emit(category,id)

func delete_override(category:String,id:String) -> void:
	if overrides.has(category) and overrides[category] is Dictionary:
		Dictionary(overrides[category]).erase(id)
	_save_overrides()
	reload_all()
	content_changed.emit(category,id)

func reset_all_overrides() -> void:
	overrides.clear()
	if FileAccess.file_exists(OVERRIDE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(OVERRIDE_PATH))
	reload_all()
	content_changed.emit("*","*")

func _save_overrides() -> void:
	var file:FileAccess = FileAccess.open(OVERRIDE_PATH,FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(overrides,"  "))

func weapon(id:String) -> Dictionary:
	var definition:Dictionary = get_entry("items",id)
	return definition if String(definition.get("kind","")) == "weapon" else {}

func attack(id:String) -> Dictionary:
	return get_entry("attacks",id)

func projectile(id:String) -> Dictionary:
	return get_entry("projectiles",id)

func monster(id:String) -> Dictionary:
	return get_entry("monsters",id)

func tile_def(id:String) -> Dictionary:
	return get_entry("tiles",id)

func status(id:String) -> Dictionary:
	return get_entry("statuses",id)

func building(id:String) -> Dictionary:
	return get_entry("buildings",id)

func monsters_for_biome(biome:String) -> Array[String]:
	var result:Array[String] = []
	for id:String in ids("monsters"):
		var definition:Dictionary = monster(id)
		if biome in Array(definition.get("biomes",[])):
			result.append(id)
	return result

func drops_for_monster(id:String) -> Array:
	return Array(monster(id).get("drops",[])).duplicate(true)

func validate_references() -> Array[String]:
	var errors:Array[String] = []
	for id:String in ids("items"):
		var item:Dictionary = get_entry("items",id)
		if String(item.get("kind","")) != "weapon":
			continue
		var attack_id:String = String(item.get("attack_id",""))
		if attack_id != "" and attack(attack_id).is_empty():
			errors.append("item %s -> missing attack %s"%[id,attack_id])
		var projectile_id:String = String(item.get("projectile_id",""))
		if projectile_id != "" and projectile(projectile_id).is_empty():
			errors.append("item %s -> missing projectile %s"%[id,projectile_id])
	for id:String in ids("monsters"):
		var monster_data:Dictionary = monster(id)
		var attack_id:String = String(monster_data.get("attack_id",""))
		if attack_id != "" and attack(attack_id).is_empty():
			errors.append("monster %s -> missing attack %s"%[id,attack_id])
		var projectile_id:String = String(monster_data.get("projectile_id",""))
		if projectile_id != "" and projectile(projectile_id).is_empty():
			errors.append("monster %s -> missing projectile %s"%[id,projectile_id])
	for id:String in ids("projectiles"):
		var projectile_data:Dictionary = projectile(id)
		var status_id:String = String(projectile_data.get("status_id",""))
		if status_id != "" and status(status_id).is_empty():
			errors.append("projectile %s -> missing status %s"%[id,status_id])
	return errors
