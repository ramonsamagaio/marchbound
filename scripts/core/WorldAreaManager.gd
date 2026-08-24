extends Node

signal changed
signal macro_position_changed(position:Vector2i)

const LOCAL_MAP_TILES:int = 192
const LOCAL_TILE_PX:int = 64
const LOCAL_MAP_PX:int = LOCAL_MAP_TILES * LOCAL_TILE_PX
const HOME:Vector2i = Vector2i.ZERO

const BIOMES:Array[String] = ["Greenlands","Ancient Forest","Iron Hills","Mistfen","Ash Wastes","Frostwild"]
const OBJECTIVES:Array[String] = ["Frontier Claim","Monster Hunt","Resource Sweep"]

const HOME_LEGACY_POSITIONS:Dictionary = {
	"town_hall":[96,93],
	"barracks":[90,98],
	"farm":[102,99],
	"lumberyard":[88,91],
	"quarry":[104,91],
	"forge":[100,88],
	"arcane_lab":[92,88],
	"market":[98,103]
}

func _ready() -> void:
	ensure_schema()

func ensure_schema() -> void:
	GameState.ensure_schema()
	if not GameState.world.has("hero_macro") or not GameState.world["hero_macro"] is Dictionary:
		GameState.world["hero_macro"] = {"x":0,"y":0}
	if not GameState.world.has("areas") or not GameState.world["areas"] is Dictionary:
		GameState.world["areas"] = {}
	if not GameState.world.has("world_discovered") or not GameState.world["world_discovered"] is Dictionary:
		GameState.world["world_discovered"] = {}
	ensure_area(0,0)
	var hero:Dictionary = Dictionary(GameState.world["hero_macro"])
	_mark_discovered_radius(Vector2i(int(hero.get("x",0)),int(hero.get("y",0))),2)

func area_key(x:int,y:int) -> String:
	return "%d:%d"%[x,y]

func current_macro() -> Vector2i:
	if not GameState.world.has("hero_macro") or not GameState.world["hero_macro"] is Dictionary:
		ensure_schema()
	var raw:Dictionary = Dictionary(GameState.world.get("hero_macro",{}))
	return Vector2i(int(raw.get("x",0)),int(raw.get("y",0)))

func set_current_macro(position:Vector2i,entry_side:String="center") -> void:
	ensure_schema()
	GameState.world["hero_macro"] = {"x":position.x,"y":position.y}
	var area:Dictionary = ensure_area(position.x,position.y)
	area["visited"] = true
	area["entry_side"] = entry_side
	_store_area(position,area,false)
	_mark_discovered_radius(position,2)
	GameState.world["focus_x"] = position.x
	GameState.world["focus_y"] = position.y
	changed.emit()
	macro_position_changed.emit(position)
	GameState.changed.emit()

func walk_transition(direction:Vector2i) -> Vector2i:
	var current:Vector2i = current_macro()
	var next:Vector2i = current + direction
	var entry_side:String = "center"
	if direction == Vector2i.RIGHT: entry_side = "left"
	elif direction == Vector2i.LEFT: entry_side = "right"
	elif direction == Vector2i.DOWN: entry_side = "top"
	elif direction == Vector2i.UP: entry_side = "bottom"
	set_current_macro(next,entry_side)
	return next

func fast_travel_cost(target:Vector2i) -> int:
	var distance:float = Vector2(target-current_macro()).length()
	return maxi(0,int(ceil(distance*9.0)))

func can_fast_travel(target:Vector2i) -> bool:
	if target == current_macro(): return true
	var area:Dictionary = peek_area(target.x,target.y)
	return bool(area.get("visited",false)) or GameState.is_conquered(target.x,target.y)

func fast_travel(target:Vector2i) -> bool:
	if target == current_macro(): return true
	if not can_fast_travel(target):
		GameState.toast_requested.emit("Fast travel only reaches places your Warden has physically visited or secured.")
		return false
	var cost:int = fast_travel_cost(target)
	if cost > 0 and not GameState.spend({"food":cost}):
		GameState.toast_requested.emit("Fast travel needs %d Food."%cost)
		return false
	set_current_macro(target,"center")
	GameState.toast_requested.emit("FAST TRAVEL · %d Food · [%d,%d]"%[cost,target.x,target.y])
	return true

func ensure_area(x:int,y:int) -> Dictionary:
	if not GameState.world.has("areas") or not GameState.world["areas"] is Dictionary:
		GameState.world["areas"] = {}
	var areas:Dictionary = Dictionary(GameState.world["areas"])
	var key:String = area_key(x,y)
	var is_home:bool = x == 0 and y == 0
	var area:Dictionary = Dictionary(areas.get(key,{}))
	if area.is_empty():
		area = {
			"x":x,"y":y,"visited":is_home,"safe":is_home,"home":is_home,"entry_side":"center",
			"player_local":[LOCAL_MAP_PX/2,LOCAL_MAP_PX/2],"structures":[],"removed_nodes":[],"discovered_pois":[],"revision":1
		}
	if not area.has("structures") or not area["structures"] is Array: area["structures"] = []
	if not area.has("removed_nodes") or not area["removed_nodes"] is Array: area["removed_nodes"] = []
	if not area.has("discovered_pois") or not area["discovered_pois"] is Array: area["discovered_pois"] = []
	if not area.has("player_local") or not area["player_local"] is Array: area["player_local"] = [LOCAL_MAP_PX/2,LOCAL_MAP_PX/2]
	if not area.has("entry_side"): area["entry_side"] = "center"
	if is_home and Array(area["structures"]).is_empty(): area["structures"] = _legacy_home_structures()
	areas[key] = area
	GameState.world["areas"] = areas
	return area.duplicate(true)

func peek_area(x:int,y:int) -> Dictionary:
	if not GameState.world.has("areas") or not GameState.world["areas"] is Dictionary: return {}
	var raw:Variant = Dictionary(GameState.world["areas"]).get(area_key(x,y),{})
	return Dictionary(raw).duplicate(true) if raw is Dictionary else {}

func area_state(x:int,y:int) -> Dictionary:
	ensure_schema()
	return ensure_area(x,y)

func current_area() -> Dictionary:
	var p:Vector2i = current_macro()
	return area_state(p.x,p.y)

func is_home(position:Vector2i) -> bool:
	return position == HOME

func current_is_home() -> bool:
	return current_macro() == HOME

func is_safe(position:Vector2i) -> bool:
	var area:Dictionary = peek_area(position.x,position.y)
	return bool(area.get("safe",position==HOME))

func current_is_safe() -> bool:
	return is_safe(current_macro())

func structures(position:Vector2i) -> Array:
	return Array(area_state(position.x,position.y).get("structures",[])).duplicate(true)

func current_structures() -> Array:
	return structures(current_macro())

func place_structure(id:String,tile_pos:Vector2i,level:int=1) -> bool:
	var macro:Vector2i = current_macro()
	var area:Dictionary = area_state(macro.x,macro.y)
	var list:Array = Array(area.get("structures",[]))
	for raw:Variant in list:
		if raw is Dictionary:
			var existing:Dictionary = Dictionary(raw)
			if int(existing.get("tx",-999)) == tile_pos.x and int(existing.get("ty",-999)) == tile_pos.y: return false
	list.append({"id":id,"tx":tile_pos.x,"ty":tile_pos.y,"level":maxi(1,level)})
	area["structures"] = list
	_store_area(macro,area)
	_sync_home_buildings()
	return true

func remove_structure(tile_pos:Vector2i) -> Dictionary:
	var macro:Vector2i = current_macro()
	var area:Dictionary = area_state(macro.x,macro.y)
	var list:Array = Array(area.get("structures",[]))
	for i:int in range(list.size()-1,-1,-1):
		if not (list[i] is Dictionary): continue
		var existing:Dictionary = Dictionary(list[i])
		if int(existing.get("tx",-999)) == tile_pos.x and int(existing.get("ty",-999)) == tile_pos.y:
			list.remove_at(i)
			area["structures"] = list
			_store_area(macro,area)
			_sync_home_buildings()
			return existing
	return {}

func structure_at(tile_pos:Vector2i) -> Dictionary:
	for raw:Variant in current_structures():
		if not (raw is Dictionary): continue
		var entry:Dictionary = Dictionary(raw)
		if int(entry.get("tx",-999)) == tile_pos.x and int(entry.get("ty",-999)) == tile_pos.y: return entry
	return {}

func store_player_local(world_pos:Vector2) -> void:
	var macro:Vector2i = current_macro()
	var area:Dictionary = area_state(macro.x,macro.y)
	area["player_local"] = [clampf(world_pos.x,32.0,LOCAL_MAP_PX-32.0),clampf(world_pos.y,32.0,LOCAL_MAP_PX-32.0)]
	_store_area(macro,area,false)

func entry_local_position() -> Vector2:
	var area:Dictionary = current_area()
	var side:String = String(area.get("entry_side","center"))
	var margin:float = float(LOCAL_TILE_PX)*2.4
	match side:
		"left": return Vector2(margin,LOCAL_MAP_PX*0.5)
		"right": return Vector2(LOCAL_MAP_PX-margin,LOCAL_MAP_PX*0.5)
		"top": return Vector2(LOCAL_MAP_PX*0.5,margin)
		"bottom": return Vector2(LOCAL_MAP_PX*0.5,LOCAL_MAP_PX-margin)
	var saved:Array = Array(area.get("player_local",[LOCAL_MAP_PX/2,LOCAL_MAP_PX/2]))
	if saved.size() >= 2: return Vector2(float(saved[0]),float(saved[1]))
	return Vector2(LOCAL_MAP_PX/2,LOCAL_MAP_PX/2)

func mark_current_visited() -> void:
	var p:Vector2i = current_macro()
	var area:Dictionary = area_state(p.x,p.y)
	area["visited"] = true
	_store_area(p,area)
	_mark_discovered_radius(p,2)

func is_discovered(x:int,y:int) -> bool:
	if not GameState.world.has("world_discovered") or not GameState.world["world_discovered"] is Dictionary: ensure_schema()
	return bool(Dictionary(GameState.world.get("world_discovered",{})).get(area_key(x,y),false))

func _mark_discovered_radius(center:Vector2i,radius:int) -> void:
	var discovered:Dictionary = Dictionary(GameState.world.get("world_discovered",{}))
	for y:int in range(center.y-radius,center.y+radius+1):
		for x:int in range(center.x-radius,center.x+radius+1):
			if Vector2i(x,y).distance_to(center) <= float(radius)+0.35: discovered[area_key(x,y)] = true
	GameState.world["world_discovered"] = discovered

func _store_area(position:Vector2i,area:Dictionary,emit:bool=true) -> void:
	var areas:Dictionary = Dictionary(GameState.world.get("areas",{}))
	areas[area_key(position.x,position.y)] = area.duplicate(true)
	GameState.world["areas"] = areas
	if emit:
		changed.emit()
		GameState.changed.emit()

func _legacy_home_structures() -> Array:
	var result:Array = []
	for raw_id:Variant in HOME_LEGACY_POSITIONS.keys():
		var id:String = String(raw_id)
		var level:int = int(GameState.buildings.get(id,0))
		if level <= 0: continue
		var point:Array = Array(HOME_LEGACY_POSITIONS[id])
		result.append({"id":id,"tx":int(point[0]),"ty":int(point[1]),"level":level,"legacy":true})
	return result

func _sync_home_buildings() -> void:
	if current_macro() != HOME: return
	var counts:Dictionary = {}
	for raw:Variant in structures(HOME):
		if not (raw is Dictionary): continue
		var entry:Dictionary = Dictionary(raw)
		var id:String = String(entry.get("id",""))
		if GameState.buildings.has(id): counts[id] = maxi(int(counts.get(id,0)),int(entry.get("level",1)))
	for raw_id:Variant in GameState.buildings.keys():
		var id:String = String(raw_id)
		if HOME_LEGACY_POSITIONS.has(id): GameState.buildings[id] = int(counts.get(id,0))

func _boss_identity(biome:String) -> Dictionary:
	return {
		"Greenlands":{"name":"Redfang Matriarch","archetype":"beast","tell":"Relentless charges and close-range pressure."},
		"Ancient Forest":{"name":"Thorn Regent","archetype":"oracle","tell":"Controls space with rotating thorn volleys."},
		"Iron Hills":{"name":"Iron Colossus","archetype":"colossus","tell":"Slow, armored and capable of crushing radial eruptions."},
		"Mistfen":{"name":"Mire Oracle","archetype":"oracle","tell":"Keeps distance and floods lanes with cursed bolts."},
		"Ash Wastes":{"name":"Cinder Titan","archetype":"colossus","tell":"Heavy impact patterns with faster burning volleys."},
		"Frostwild":{"name":"White Maw","archetype":"beast","tell":"Fast charge windows punish mistimed evasions."}
	}.get(biome,{"name":"Frontier Guardian","archetype":"colossus","tell":"A dangerous territorial guardian."})

func tile_data(x:int,y:int) -> Dictionary:
	ensure_schema()
	var hashv:int = absi(hash("%s:%s:%s:%s"%[GameState.world.get("seed",947213),GameState.world.get("season",1),x,y]))
	var biome_index:int = hashv%BIOMES.size()
	var dist:float = Vector2(float(x),float(y)).length()
	var home:bool = x == 0 and y == 0
	var threat:int = 0 if home else maxi(1,int(dist*0.72)+int(GameState.world.get("frontier_depth",1))+int((hashv/13)%3))
	var boss:bool = not home and threat>=3 and hashv%9==0
	var pvp:bool = not home and threat>=7 and hashv%5==0
	var richness:int = 1+(hashv%4)
	var biome:String = "Greenlands" if home else BIOMES[biome_index]
	var objective:String = "Home" if home else ("Ruin Siege" if boss else OBJECTIVES[int((hashv/29)%OBJECTIVES.size())])
	var identity:Dictionary = _boss_identity(biome)
	var mutations:Array = [] if home else FrontierMutations.roll(hashv,threat,boss)
	var wild_bond:String = "" if home else MonsterRoster.id_for_biome(biome)
	var current:Vector2i = current_macro()
	var area:Dictionary = peek_area(x,y)
	return {
		"x":x,"y":y,"biome":biome,"biome_index":0 if home else biome_index,"threat":threat,
		"boss":boss,"pvp":pvp,"richness":richness,"seed":hashv,"home":home,"safe":home,
		"conquered":GameState.is_conquered(x,y),"accessible":GameState.is_accessible(x,y),
		"visited":bool(area.get("visited",home)),"discovered":is_discovered(x,y),"current":current==Vector2i(x,y),
		"objective":objective,"boss_name":String(identity.get("name","Frontier Guardian")) if boss else "Frontier Guardian",
		"boss_archetype":String(identity.get("archetype","guardian")) if boss else "guardian",
		"boss_tell":String(identity.get("tell","A standard territorial guardian.")) if boss else "A standard territorial guardian.",
		"mutations":mutations,"wild_bond":wild_bond,
		"wild_bond_unlocked":true if home or wild_bond=="" else GameState.monster_unlocked(wild_bond),
		"local_map_tiles":LOCAL_MAP_TILES,"local_player_capacity":3
	}

func expected_monsters(tile:Dictionary) -> Array[String]:
	return ContentDB.monsters_for_biome(String(tile.get("biome","Greenlands")))

func expected_drop_ids(tile:Dictionary) -> Array[String]:
	var seen:Dictionary = {}
	for monster_id:String in expected_monsters(tile):
		for raw_drop:Variant in ContentDB.drops_for_monster(monster_id):
			var id:String = String(raw_drop)
			if id != "": seen[id] = true
	var result:Array[String] = []
	for raw_id:Variant in seen.keys(): result.append(String(raw_id))
	result.sort()
	return result

func rarity_forecast(tile:Dictionary) -> Dictionary:
	var threat:int = int(tile.get("threat",1))
	var richness:int = int(tile.get("richness",1))
	return {
		"rare":clampi(14+threat*3+richness*2,0,72),
		"epic":clampi(4+threat*2+richness,0,42),
		"legendary":clampi(1+int(floor(float(threat)/2.0)),0,18)
	}
