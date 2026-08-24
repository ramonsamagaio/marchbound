class_name AreaEcology
extends RefCounted

# Persistent ecology for one macro AREA.
# Terrain is deterministic; living packs are saved as compact records so leaving
# and returning does not magically replace or erase the battle that was here.

const CLAIM_SETTLEMENT:String = "settlement"
const CLAIM_OUTPOST:String = "outpost"
const DEFAULT_SETTLEMENT_RADIUS:float = 620.0
const DEFAULT_OUTPOST_RADIUS:float = 360.0
const MIN_CLAIM_SPACING:float = 900.0
const ECOLOGY_VERSION:int = 1

static func _area_key(position:Vector2i) -> String:
	return "%d:%d"%[position.x,position.y]

static func _areas() -> Dictionary:
	if not GameState.world.has("areas") or not GameState.world["areas"] is Dictionary:
		GameState.world["areas"] = {}
	return Dictionary(GameState.world["areas"])

static func _load_area(position:Vector2i) -> Dictionary:
	WorldAreaManager.ensure_schema()
	var area:Dictionary = WorldAreaManager.area_state(position.x,position.y)
	if not area.has("claims") or not area["claims"] is Array:
		area["claims"] = []
	if not area.has("ecology") or not area["ecology"] is Dictionary:
		area["ecology"] = {}
	return area

static func _store_area(position:Vector2i,area:Dictionary,emit:bool=true) -> void:
	var areas:Dictionary = _areas()
	areas[_area_key(position)] = area.duplicate(true)
	GameState.world["areas"] = areas
	if emit:
		GameState.changed.emit()

static func ensure_area(position:Vector2i,tile:Dictionary) -> Dictionary:
	var area:Dictionary = _load_area(position)
	var ecology:Dictionary = Dictionary(area.get("ecology",{}))
	if int(ecology.get("version",0)) != ECOLOGY_VERSION or not ecology.has("packs"):
		ecology = _generate(position,tile)
		area["ecology"] = ecology
		# The initial home is a local settlement bubble, not an invulnerable macro tile.
		if bool(tile.get("home",false)) and Array(area.get("claims",[])).is_empty():
			area["claims"] = [{
				"id":"founding_keep","owner":"local","kind":CLAIM_SETTLEMENT,
				"x":float(WorldAreaManager.LOCAL_MAP_PX)*0.5,
				"y":float(WorldAreaManager.LOCAL_MAP_PX)*0.5,
				"radius":DEFAULT_SETTLEMENT_RADIUS,"capital":true,"created":0
			}]
		_store_area(position,area,false)
	return ecology.duplicate(true)

static func _generate(position:Vector2i,tile:Dictionary) -> Dictionary:
	var rng:=RandomNumberGenerator.new()
	rng.seed = int(tile.get("seed",absi(hash("%d:%d"%[position.x,position.y])))) ^ 0x5EED71
	var threat:int = int(tile.get("threat",1))
	var biome:String = String(tile.get("biome","Greenlands"))
	var roster:Array[String] = ContentDB.monsters_for_biome(biome)
	if roster.is_empty():
		roster = ["raider","wolf","slime"]
	var packs:Array = []
	var pack_count:int = 7 + mini(9,threat*2)
	var world_size:float = float(WorldAreaManager.LOCAL_MAP_PX)
	var center:=Vector2(world_size*0.5,world_size*0.5)
	for p:int in range(pack_count):
		var anchor:=Vector2.ZERO
		var guard:int = 0
		while guard < 80:
			guard += 1
			anchor = Vector2(rng.randf_range(180.0,world_size-180.0),rng.randf_range(180.0,world_size-180.0))
			if anchor.distance_to(center) >= (850.0 if bool(tile.get("home",false)) else 420.0):
				break
		var species:String = roster[rng.randi_range(0,roster.size()-1)]
		var members:Array = []
		var amount:int = rng.randi_range(2,4+mini(3,int(ceil(float(threat)/3.0))))
		for m:int in range(amount):
			var angle:float = rng.randf_range(0.0,TAU)
			var radius:float = rng.randf_range(24.0,125.0)
			var pos:Vector2 = anchor+Vector2.RIGHT.rotated(angle)*radius
			members.append({
				"uid":"%d_%d_%d_%d"%[position.x,position.y,p,m],
				"type":species,"x":pos.x,"y":pos.y,"hp_pct":1.0,"dead":false,
				"elite":rng.randf() < minf(0.14,0.025+float(threat)*0.008)
			})
		packs.append({"id":"pack_%d"%p,"x":anchor.x,"y":anchor.y,"members":members,"cleared_at":0,"kind":"patrol"})
	return {"version":ECOLOGY_VERSION,"packs":packs,"generated_at":int(Time.get_unix_time_from_system()),"revision":1}

static func live_members(position:Vector2i,tile:Dictionary) -> Array:
	var ecology:Dictionary = ensure_area(position,tile)
	var out:Array = []
	for raw_pack:Variant in Array(ecology.get("packs",[])):
		if not (raw_pack is Dictionary): continue
		for raw_member:Variant in Array(Dictionary(raw_pack).get("members",[])):
			if not (raw_member is Dictionary): continue
			var member:Dictionary = Dictionary(raw_member)
			if not bool(member.get("dead",false)):
				out.append(member.duplicate(true))
	return out

static func update_member(position:Vector2i,uid:String,hp_pct:float,world_pos:Vector2,dead:bool=false) -> void:
	var area:Dictionary = _load_area(position)
	var ecology:Dictionary = Dictionary(area.get("ecology",{}))
	var packs:Array = Array(ecology.get("packs",[]))
	for pi:int in range(packs.size()):
		if not (packs[pi] is Dictionary): continue
		var pack:Dictionary = Dictionary(packs[pi])
		var members:Array = Array(pack.get("members",[]))
		var alive:int = 0
		for mi:int in range(members.size()):
			if not (members[mi] is Dictionary): continue
			var member:Dictionary = Dictionary(members[mi])
			if String(member.get("uid","")) == uid:
				member["hp_pct"] = clampf(hp_pct,0.0,1.0)
				member["x"] = world_pos.x
				member["y"] = world_pos.y
				member["dead"] = dead or hp_pct <= 0.0
				members[mi] = member
			if not bool(Dictionary(members[mi]).get("dead",false)):
				alive += 1
		pack["members"] = members
		if alive == 0 and int(pack.get("cleared_at",0)) == 0:
			pack["cleared_at"] = int(Time.get_unix_time_from_system())
		packs[pi] = pack
		if uid.begins_with("%d_%d_%d_"%[position.x,position.y,pi]):
			break
	ecology["packs"] = packs
	ecology["revision"] = int(ecology.get("revision",1))+1
	area["ecology"] = ecology
	_store_area(position,area,false)

static func alive_count(position:Vector2i,tile:Dictionary) -> int:
	return live_members(position,tile).size()

static func hostile_count_near(position:Vector2i,tile:Dictionary,world_pos:Vector2,radius:float) -> int:
	var count:int = 0
	for raw:Variant in live_members(position,tile):
		var member:Dictionary = Dictionary(raw)
		if world_pos.distance_to(Vector2(float(member.get("x",0.0)),float(member.get("y",0.0)))) <= radius:
			count += 1
	return count

static func claims(position:Vector2i) -> Array:
	return Array(_load_area(position).get("claims",[])).duplicate(true)

static func point_in_friendly_claim(position:Vector2i,world_pos:Vector2) -> bool:
	for raw:Variant in claims(position):
		if not (raw is Dictionary): continue
		var claim:Dictionary = Dictionary(raw)
		if String(claim.get("owner","local")) != "local": continue
		var center:=Vector2(float(claim.get("x",0.0)),float(claim.get("y",0.0)))
		if world_pos.distance_to(center) <= float(claim.get("radius",0.0)):
			return true
	return false

static func can_found(position:Vector2i,tile:Dictionary,world_pos:Vector2,kind:String=CLAIM_SETTLEMENT) -> Dictionary:
	var radius:float = DEFAULT_SETTLEMENT_RADIUS if kind == CLAIM_SETTLEMENT else DEFAULT_OUTPOST_RADIUS
	var hostiles:int = hostile_count_near(position,tile,world_pos,radius+220.0)
	if hostiles > 0:
		return {"ok":false,"reason":"Clear %d hostile%s around the proposed claim first."%[hostiles,"s" if hostiles!=1 else ""]}
	for raw:Variant in claims(position):
		if not (raw is Dictionary): continue
		var claim:Dictionary = Dictionary(raw)
		var center:=Vector2(float(claim.get("x",0.0)),float(claim.get("y",0.0)))
		var required:float = radius+float(claim.get("radius",0.0))+MIN_CLAIM_SPACING*0.25
		if world_pos.distance_to(center) < required:
			return {"ok":false,"reason":"Another settlement claim is too close."}
	return {"ok":true,"reason":"Area is locally secure.","radius":radius}

static func found(position:Vector2i,tile:Dictionary,world_pos:Vector2,kind:String=CLAIM_SETTLEMENT) -> Dictionary:
	var check:Dictionary = can_found(position,tile,world_pos,kind)
	if not bool(check.get("ok",false)):
		return check
	var area:Dictionary = _load_area(position)
	var list:Array = Array(area.get("claims",[]))
	var id:String = "%s_%d_%d_%d"%[kind,position.x,position.y,list.size()+1]
	var capital_exists:bool = false
	for raw:Variant in list:
		if raw is Dictionary and bool(Dictionary(raw).get("capital",false)):
			capital_exists = true
			break
	list.append({
		"id":id,"owner":"local","kind":kind,"x":world_pos.x,"y":world_pos.y,
		"radius":float(check.get("radius",DEFAULT_SETTLEMENT_RADIUS)),
		"capital":not capital_exists,"created":int(Time.get_unix_time_from_system())
	})
	area["claims"] = list
	_store_area(position,area)
	return {"ok":true,"id":id}

static func designate_capital(position:Vector2i,claim_id:String) -> bool:
	# Capital is a designation, not a prison. The old capital remains a settlement.
	var areas:Dictionary = _areas()
	var found_target:bool = false
	for key:Variant in areas.keys():
		if not (areas[key] is Dictionary): continue
		var area:Dictionary = Dictionary(areas[key])
		var list:Array = Array(area.get("claims",[]))
		for i:int in range(list.size()):
			if not (list[i] is Dictionary): continue
			var claim:Dictionary = Dictionary(list[i])
			var is_target:bool = String(key) == _area_key(position) and String(claim.get("id","")) == claim_id
			claim["capital"] = is_target
			if is_target: found_target = true
			list[i] = claim
		area["claims"] = list
		areas[key] = area
	if found_target:
		GameState.world["areas"] = areas
		GameState.world["capital_macro"] = {"x":position.x,"y":position.y,"claim_id":claim_id}
		GameState.changed.emit()
	return found_target

static func capital() -> Dictionary:
	var raw:Dictionary = Dictionary(GameState.world.get("capital_macro",{}))
	if not raw.is_empty(): return raw.duplicate(true)
	return {"x":0,"y":0,"claim_id":"founding_keep"}
