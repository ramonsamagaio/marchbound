class_name HybridAreaCombatArena
extends DiscoveryCombatArena

signal area_transition_requested(next_tile:Dictionary)
signal station_requested(station:String)

const HYBRID_BUILD_ORDER:Array[String] = [
	"palisade","wall_stone","gate","torch","watchtower","spike_trap","field_camp","arcane_pylon",
	"storage","farm","lumberyard","quarry","town_hall","barracks","forge","arcane_lab","market","stable","waystone"
]
const STANCES:Array[String] = ["aggressive","defensive","follow","hold"]

var safe_area:bool = false
var transition_locked:bool = false
var party_stance:String = "aggressive"
var hybrid_build_index:int = 0
var current_macro:Vector2i = Vector2i.ZERO

func begin(data:Dictionary) -> void:
	current_macro = Vector2i(int(data.get("x",0)),int(data.get("y",0)))
	WorldAreaManager.set_current_macro(current_macro,String(WorldAreaManager.current_area().get("entry_side","center")))
	safe_area = WorldAreaManager.is_safe(current_macro)
	transition_locked = false
	party_stance = "aggressive"
	hybrid_build_index = 0
	super.begin(data)
	# The old arena generated a decorative outpost around the center. In the hybrid
	# architecture the settlement is what the player actually built in this AREA.
	local_structures.clear()
	player_pos = WorldAreaManager.entry_local_position()
	_load_persistent_structures()
	_reposition_resource_nodes_near_player()
	discoveries.clear()
	if not safe_area:
		_spawn_discoveries()
	_update_camera()
	WorldAreaManager.mark_current_visited()

func _process(delta:float) -> void:
	_handle_stance_input()
	super._process(delta)
	if ended:
		return
	WorldAreaManager.store_player_local(player_pos)
	if not paused_for_upgrade:
		if Input.is_action_just_pressed("build_remove"):
			_try_remove_persistent_structure()
		if Input.is_action_just_pressed("interact"):
			_try_interact_station()
		_check_area_border()

func _draw_outpost_roads() -> void:
	# No fake prefab settlement. Roads/floors are player-built structures.
	pass

func _spawn_logic() -> void:
	if safe_area:
		return
	super._spawn_logic()

func _spawn_enemy(boss:bool) -> void:
	if safe_area:
		return
	var before:int = enemies.size()
	super._spawn_enemy(boss)
	if enemies.size() <= before:
		return
	var enemy:Dictionary = enemies[enemies.size()-1]
	if _inside_safe_source(Vector2(enemy.get("pos",Vector2.ZERO))):
		enemies.remove_at(enemies.size()-1)

func _inside_safe_source(pos:Vector2) -> bool:
	for structure:Dictionary in field_towers:
		var definition:Dictionary = ContentDB.building(String(structure.get("id","")))
		if String(definition.get("role","")) != "safe_source": continue
		if pos.distance_to(Vector2(structure.get("pos",Vector2.ZERO))) <= float(definition.get("safe_radius",0.0)):
			return true
	return false

# ================================================================ PHYSICAL MACRO TRAVEL
func _check_area_border() -> void:
	if transition_locked:
		return
	var direction:=Vector2i.ZERO
	if player_pos.x <= 30.0: direction = Vector2i.LEFT
	elif player_pos.x >= bounds.size.x-30.0: direction = Vector2i.RIGHT
	elif player_pos.y <= 30.0: direction = Vector2i.UP
	elif player_pos.y >= bounds.size.y-30.0: direction = Vector2i.DOWN
	if direction == Vector2i.ZERO:
		return
	transition_locked = true
	WorldAreaManager.store_player_local(player_pos)
	var next:Vector2i = WorldAreaManager.walk_transition(direction)
	var next_tile:Dictionary = WorldAreaManager.tile_data(next.x,next.y)
	GameState.world["selected_tile"] = next_tile.duplicate(true)
	GameState.toast_requested.emit("CROSSED AREA BORDER · [%d,%d] · no Food spent"%[next.x,next.y])
	area_transition_requested.emit(next_tile)

# ================================================================ PERSISTENT BUILDING
func _selected_building_id() -> String:
	return HYBRID_BUILD_ORDER[clampi(hybrid_build_index,0,HYBRID_BUILD_ORDER.size()-1)]

func _cycle_field_building() -> void:
	hybrid_build_index = (hybrid_build_index+1)%HYBRID_BUILD_ORDER.size()
	var id:String = _selected_building_id()
	var definition:Dictionary = ContentDB.building(id)
	_float_text(player_pos+Vector2(0,-58),"BUILD · %s"%String(definition.get("name",id)),Color("#efd896"),1.0)

func _load_persistent_structures() -> void:
	field_towers.clear()
	for raw:Variant in WorldAreaManager.structures(current_macro):
		if not (raw is Dictionary): continue
		var entry:Dictionary = Dictionary(raw)
		var tx:int = int(entry.get("tx",0))
		var ty:int = int(entry.get("ty",0))
		field_towers.append({
			"id":String(entry.get("id","palisade")),
			"pos":Vector2(float(tx)*LOCAL_TILE_PX,float(ty)*LOCAL_TILE_PX),
			"cooldown":0.15,"pulse":0.0,"persistent":true,"level":int(entry.get("level",1))
		})

func _try_build_selected() -> void:
	var id:String = _selected_building_id()
	var definition:Dictionary = ContentDB.building(id)
	if definition.is_empty():
		_float_text(player_pos+Vector2(0,-52),"UNKNOWN BUILDING",Color("#d7a48b"),0.9)
		return
	var snapped:Vector2 = Vector2(round(player_pos.x/float(LOCAL_TILE_PX))*LOCAL_TILE_PX,round(player_pos.y/float(LOCAL_TILE_PX))*LOCAL_TILE_PX)
	var tile_pos:=Vector2i(int(round(snapped.x/float(LOCAL_TILE_PX))),int(round(snapped.y/float(LOCAL_TILE_PX))))
	if not WorldAreaManager.structure_at(tile_pos).is_empty():
		_float_text(player_pos+Vector2(0,-52),"BUILD SPACE OCCUPIED",Color("#d7a48b"),0.9)
		return
	if bool(definition.get("unique",false)):
		for raw:Variant in WorldAreaManager.structures(current_macro):
			if raw is Dictionary and String(Dictionary(raw).get("id","")) == id:
				_float_text(player_pos+Vector2(0,-52),"ONLY ONE PER AREA",Color("#d7a48b"),0.9)
				return
	var cost:Dictionary = Dictionary(definition.get("cost",{}))
	if not _pay_persistent_build_cost(cost):
		_float_text(player_pos+Vector2(0,-52),"NEED · %s"%UIFactory.cost_text(cost),Color("#d7a48b"),0.9)
		return
	if not WorldAreaManager.place_structure(id,tile_pos,1):
		_refund_to_bank(cost,1.0)
		return
	field_towers.append({"id":id,"pos":snapped,"cooldown":0.15,"pulse":0.0,"persistent":true,"level":1})
	_spawn_ring(snapped,Color("#e1c278"))
	_float_text(snapped+Vector2(0,-58),"%s BUILT · PERSISTENT"%String(definition.get("name",id)).to_upper(),Color("#f0d68d"),1.1)
	_shake(0.08,2.2)

func _pay_persistent_build_cost(cost:Dictionary) -> bool:
	var bank_need:Dictionary = {}
	for raw_resource:Variant in cost.keys():
		var resource:String = String(raw_resource)
		var required:float = float(cost[raw_resource])
		var from_run:float = minf(required,float(loot.get(resource,0.0)))
		var remainder:float = required-from_run
		if remainder > 0.0: bank_need[resource] = remainder
	if not GameState.can_afford(bank_need): return false
	for raw_resource:Variant in cost.keys():
		var resource:String = String(raw_resource)
		var required:float = float(cost[raw_resource])
		var from_run:float = minf(required,float(loot.get(resource,0.0)))
		loot[resource] = float(loot.get(resource,0.0))-from_run
		var remainder:float = required-from_run
		if remainder > 0.0: GameState.resources[resource] = float(GameState.resources.get(resource,0.0))-remainder
	GameState.changed.emit()
	return true

func _try_remove_persistent_structure() -> void:
	var tile_pos:=Vector2i(int(round(player_pos.x/float(LOCAL_TILE_PX))),int(round(player_pos.y/float(LOCAL_TILE_PX))))
	var removed:Dictionary = WorldAreaManager.remove_structure(tile_pos)
	if removed.is_empty():
		_float_text(player_pos+Vector2(0,-52),"NO STRUCTURE HERE",Color("#8e9bb2"),0.7)
		return
	var id:String = String(removed.get("id",""))
	var definition:Dictionary = ContentDB.building(id)
	_refund_to_bank(Dictionary(definition.get("cost",{})),0.5)
	for i:int in range(field_towers.size()-1,-1,-1):
		if String(Dictionary(field_towers[i]).get("id","")) == id and Vector2(Dictionary(field_towers[i]).get("pos",Vector2.ZERO)).distance_to(Vector2(tile_pos)*LOCAL_TILE_PX) < 8.0:
			field_towers.remove_at(i)
			break
	_float_text(player_pos+Vector2(0,-52),"REMOVED · 50% REFUND",Color("#a8b8cb"),0.9)

func _refund_to_bank(cost:Dictionary,factor:float) -> void:
	var refund:Dictionary = {}
	for raw:Variant in cost.keys(): refund[String(raw)] = int(floor(float(cost[raw])*factor))
	GameState.add_resources(refund)

func _try_interact_station() -> void:
	var best:Dictionary = {}
	var best_distance:float = 92.0
	for structure:Dictionary in field_towers:
		var definition:Dictionary = ContentDB.building(String(structure.get("id","")))
		var station:String = String(definition.get("station",""))
		if station == "": continue
		var d:float = player_pos.distance_to(Vector2(structure.get("pos",Vector2.ZERO)))
		if d < best_distance:
			best_distance = d
			best = structure
	if best.is_empty(): return
	var definition:Dictionary = ContentDB.building(String(best.get("id","")))
	var station:String = String(definition.get("station",""))
	GameState.toast_requested.emit("%s · opening %s"%[String(definition.get("name","Station")),station.capitalize()])
	station_requested.emit(station)

# ================================================================ AUTONOMOUS WARBAND
func _spawn_allies() -> void:
	allies.clear()
	UnitRoster.ensure_schema()
	var source:Array = UnitRoster.all_field_instances(24)
	var total:int = source.size()
	for i:int in range(total):
		var record:Dictionary = Dictionary(source[i])
		var ring:int = int(floor(float(i)/8.0))
		var slot:int = i%8
		var radius:float = 64.0+float(ring)*38.0
		var angle:float = TAU*float(slot)/8.0+float(ring)*0.22
		var offset:=Vector2.RIGHT.rotated(angle)*radius
		allies.append({
			"type":String(record.get("family","militia")),"pos":player_pos+offset,"cooldown":rng.randf_range(0.0,0.8),
			"uid":String(record.get("uid","")),"prefix":String(record.get("prefix","")),"elite":bool(record.get("elite",false)),
			"record":record,"formation_offset":offset,"hold_pos":player_pos+offset,"speed":180.0+rng.randf_range(-8.0,8.0)
		})

func _handle_stance_input() -> void:
	for i:int in range(STANCES.size()):
		if Input.is_action_just_pressed("stance_%d"%(i+1)):
			_set_party_stance(STANCES[i])
			break

func _set_party_stance(value:String) -> void:
	party_stance = value
	if value == "hold":
		for i:int in range(allies.size()):
			var ally:Dictionary = allies[i]
			ally["hold_pos"] = Vector2(ally.get("pos",player_pos))
			allies[i] = ally
	_float_text(player_pos+Vector2(0,-66),"WAR-BAND · %s"%value.to_upper(),Color("#a9d8b9"),0.9)

func _update_allies(delta:float) -> void:
	for i:int in range(allies.size()):
		var ally:Dictionary = allies[i]
		var record:Dictionary = Dictionary(ally.get("record",{}))
		var ally_type:String = String(ally.get("type","militia"))
		var ally_pos:Vector2 = Vector2(ally.get("pos",player_pos))
		ally["cooldown"] = float(ally.get("cooldown",0.0))-delta
		var formation:Vector2 = player_pos+Vector2(ally.get("formation_offset",Vector2.ZERO))
		var target:Dictionary = {}
		match party_stance:
			"follow":
				pass
			"defensive":
				target = nearest_enemy(ally_pos)
				if not target.is_empty() and Vector2(target.get("pos",Vector2.ZERO)).distance_to(player_pos) > 280.0: target = {}
			"hold":
				target = nearest_enemy(ally_pos)
				if not target.is_empty() and Vector2(target.get("pos",Vector2.ZERO)).distance_to(Vector2(ally.get("hold_pos",ally_pos))) > 280.0: target = {}
			_:
				target = nearest_enemy(ally_pos)
				if not target.is_empty() and Vector2(target.get("pos",Vector2.ZERO)).distance_to(player_pos) > 620.0: target = {}
		var desired:Vector2 = Vector2(ally.get("hold_pos",ally_pos)) if party_stance == "hold" else formation
		var effective_range:float = _unit_range(ally_type)*UnitRoster.range_mult(record)
		if not target.is_empty():
			var target_pos:Vector2 = Vector2(target.get("pos",Vector2.ZERO))
			var target_distance:float = ally_pos.distance_to(target_pos)
			var ideal:float = minf(effective_range*0.72,190.0)
			if target_distance > ideal:
				desired = target_pos-(target_pos-ally_pos).normalized()*ideal
			if target_distance <= effective_range and float(ally.get("cooldown",0.0)) <= 0.0:
				_attack_from_ally(ally,target,record)
		var to_desired:Vector2 = desired-ally_pos
		if to_desired.length() > 12.0:
			ally_pos += to_desired.normalized()*float(ally.get("speed",180.0))*delta
		# lightweight separation keeps the formation readable instead of stacking sprites.
		for j:int in range(allies.size()):
			if j == i: continue
			var other_pos:Vector2 = Vector2(Dictionary(allies[j]).get("pos",ally_pos))
			var apart:Vector2 = ally_pos-other_pos
			if apart.length_squared() > 0.1 and apart.length() < 24.0: ally_pos += apart.normalized()*22.0*delta
		ally["pos"] = ally_pos
		allies[i] = ally

func _attack_from_ally(ally:Dictionary,target:Dictionary,record:Dictionary) -> void:
	var ally_type:String = String(ally.get("type","militia"))
	var target_hp_before:float = float(target.get("hp",1.0))
	var rally_mult:float = 1.45 if rally_time > 0.0 else 1.0
	var momentum:float = 1.0+float(mini(combo,30))*0.008
	var hit:float = unit_damage(ally_type)*army_damage_mult*rally_mult*momentum*UnitRoster.damage_mult(record)
	hit *= UnitRoster.execute_mult(record,target_hp_before/maxf(1.0,float(target.get("max_hp",1.0))))
	_damage_enemy(target,hit,false)
	var ally_pos:Vector2 = Vector2(ally.get("pos",player_pos))
	var target_pos:Vector2 = Vector2(target.get("pos",Vector2.ZERO))
	if _unit_range(ally_type) >= 245.0:
		particles.append({"pos":target_pos,"life":0.16,"max":0.16,"color":Color("#c9e4ff")})
		draw_offset += Vector2.ZERO
	else:
		_spawn_ring(target_pos,Color("#b7c8d8"))
	var quality_heal:float = UnitRoster.heal_on_hit(record)
	if quality_heal > 0.0: player_hp = minf(player_hp_max,player_hp+quality_heal)
	var chain:float = UnitRoster.chain_ratio(record)
	if chain > 0.0: _quality_chain(target,hit*chain)
	var branch:String = UnitProgression.evolution(ally_type)
	if ally_type == "mage" and branch == "stormcaller": _storm_chain(target,hit)
	elif ally_type == "mage" and branch == "lifebinder": player_hp = minf(player_hp_max,player_hp+2.2+float(GameState.unit_levels.get("mage",1))*0.38)
	elif ally_type == "mire_leech": player_hp = minf(player_hp_max,player_hp+1.5+float(GameState.unit_levels.get(ally_type,1))*0.30)
	elif ally_type == "ember_imp": _wild_splash(target,hit*0.30)
	ally["cooldown"] = unit_cooldown(ally_type)*army_haste_mult*UnitRoster.cooldown_mult(record)
	var uid:String = String(ally.get("uid",""))
	if uid != "": UnitRoster.add_xp(uid,1)
	if target_hp_before > 0.0 and float(target.get("hp",0.0)) <= 0.0 and uid != "":
		UnitRoster.add_kill(uid,bool(target.get("elite",false)),bool(target.get("boss",false)))
		UnitRoster.add_xp(uid,5+(8 if bool(target.get("elite",false)) else 0)+(20 if bool(target.get("boss",false)) else 0))

# ================================================================ EQUIPMENT-VISIBLE COMPACT PLAYER
func _draw_player() -> void:
	var cape:Dictionary = GameState.get_item(String(GameState.equipped.get("cape","")))
	if not cape.is_empty():
		var cc:Color = _gear_color(cape).darkened(0.20)
		draw_colored_polygon(PackedVector2Array([player_pos+Vector2(-15,-10),player_pos+Vector2(15,-10),player_pos+Vector2(20,28),player_pos+Vector2(-18,31)]),cc)
	# tiny, readable body scaffold. Final pixel sheets plug into the same slot logic.
	draw_rect(Rect2(player_pos+Vector2(-10,-28),Vector2(20,17)),Color("#d6aa83"))
	draw_rect(Rect2(player_pos+Vector2(-12,-10),Vector2(24,24)),Color("#403d43"))
	draw_rect(Rect2(player_pos+Vector2(-10,13),Vector2(8,20)),Color("#2f3036"))
	draw_rect(Rect2(player_pos+Vector2(2,13),Vector2(8,20)),Color("#2f3036"))
	_draw_equipped_piece("chest",Rect2(player_pos+Vector2(-13,-11),Vector2(26,22)))
	_draw_equipped_piece("belt",Rect2(player_pos+Vector2(-13,8),Vector2(26,5)))
	_draw_equipped_piece("helm",Rect2(player_pos+Vector2(-12,-31),Vector2(24,11)))
	_draw_equipped_piece("shoulders",Rect2(player_pos+Vector2(-17,-9),Vector2(34,7)))
	_draw_equipped_piece("gloves",Rect2(player_pos+Vector2(-18,0),Vector2(36,8)))
	_draw_equipped_piece("legs",Rect2(player_pos+Vector2(-11,13),Vector2(22,11)))
	_draw_equipped_piece("boots",Rect2(player_pos+Vector2(-11,24),Vector2(22,10)))
	if attack_visual_time > 0.0:
		var progress:float = 1.0-attack_visual_time/maxf(0.01,attack_visual_duration)
		_draw_weapon_motion(String(weapon_profile.get("weapon_class","sword")),progress)
	else:
		_draw_idle_weapon(String(weapon_profile.get("weapon_class","sword")))
	if dash_time>0.0: draw_arc(player_pos,31,0,TAU,28,Color("#d9efff"),3.0)
	if combo>=10: draw_arc(player_pos,35,0,TAU,28,Color("#f0d77a"),2.0)

func _draw_equipped_piece(slot:String,rect:Rect2) -> void:
	var item:Dictionary = GameState.get_item(String(GameState.equipped.get(slot,"")))
	if item.is_empty(): return
	var color:Color = _gear_color(item)
	if slot == "gloves":
		draw_rect(Rect2(rect.position,Vector2(6,rect.size.y)),color)
		draw_rect(Rect2(Vector2(rect.end.x-6,rect.position.y),Vector2(6,rect.size.y)),color)
	elif slot == "shoulders":
		draw_rect(Rect2(rect.position,Vector2(9,rect.size.y)),color.lightened(0.08))
		draw_rect(Rect2(Vector2(rect.end.x-9,rect.position.y),Vector2(9,rect.size.y)),color.lightened(0.08))
	else:
		draw_rect(rect,color)

func _gear_color(item:Dictionary) -> Color:
	var biome:String = String(item.get("origin_biome",""))
	if biome != "":
		return {
			"Greenlands":Color("#75835d"),"Ancient Forest":Color("#4f7659"),"Iron Hills":Color("#87919d"),
			"Mistfen":Color("#557d7b"),"Ash Wastes":Color("#995b4c"),"Frostwild":Color("#789eb8")
		}.get(biome,Color("#778ca8"))
	return {"common":Color("#727b88"),"uncommon":Color("#5f8a68"),"rare":Color("#587fb0"),"epic":Color("#765a9b"),"legendary":Color("#b38a43")}.get(String(item.get("rarity","common")),Color("#727b88"))

func _draw_idle_weapon(weapon_class:String) -> void:
	var origin:Vector2 = player_pos+Vector2(15,-2)
	match weapon_class:
		"spear":
			draw_line(origin+Vector2(0,22),origin+Vector2(22,-30),Color("#946c43"),4)
			draw_colored_polygon(PackedVector2Array([origin+Vector2(18,-31),origin+Vector2(27,-40),origin+Vector2(26,-27)]),Color("#d8e0ea"))
		"bow": draw_arc(origin+Vector2(8,3),20,-1.2,1.2,14,Color("#9a744a"),4)
		"staff","wand":
			draw_line(origin+Vector2(0,22),origin+Vector2(13,-28),Color("#725042"),5)
			draw_circle(origin+Vector2(14,-31),6,Color("#78c7ff"))
		"hammer":
			draw_line(origin+Vector2(0,20),origin+Vector2(15,-22),Color("#79533d"),5)
			draw_rect(Rect2(origin+Vector2(7,-28),Vector2(20,12)),Color("#89919b"))
		"axe":
			draw_line(origin+Vector2(0,20),origin+Vector2(15,-23),Color("#79533d"),5)
			draw_colored_polygon(PackedVector2Array([origin+Vector2(11,-26),origin+Vector2(30,-30),origin+Vector2(26,-13)]),Color("#aeb8c4"))
		"dagger": draw_line(origin+Vector2(0,7),origin+Vector2(20,-8),Color("#dce3ed"),5)
		_: draw_line(origin+Vector2(0,19),origin+Vector2(18,-25),Color("#dce3ed"),5)

func _draw_ground() -> void:
	super._draw_ground()
	var visible:Rect2 = _visible_world_rect(120.0)
	for structure:Dictionary in field_towers:
		var pos:Vector2 = Vector2(structure.get("pos",Vector2.ZERO))
		if not visible.has_point(pos): continue
		var definition:Dictionary = ContentDB.building(String(structure.get("id","")))
		if String(definition.get("role","")) == "safe_source":
			draw_arc(pos,float(definition.get("safe_radius",200.0)),0,TAU,48,Color(0.65,0.85,1.0,0.16),2.0)
		if player_pos.distance_to(pos) < 160.0 and String(definition.get("station","")) != "":
			draw_string(ThemeDB.fallback_font,pos+Vector2(-65,-48),"F · %s"%String(definition.get("name","Station")),HORIZONTAL_ALIGNMENT_CENTER,130,12,Color("#f0dfae"))
