class_name QualityCombatArena
extends VisualCombatArena

const FIELD_BUILD_LIMIT:int = 24
const BUILD_ORDER:Array[String] = ["watchtower","spike_trap","field_camp","arcane_pylon","palisade"]

var field_towers:Array = []
var selected_building_index:int = 0

func begin(data:Dictionary) -> void:
	UnitRoster.ensure_schema()
	field_towers.clear()
	selected_building_index = 0
	super.begin(data)

func _process(delta:float) -> void:
	super._process(delta)
	if ended or paused_for_upgrade:
		return
	if Input.is_action_just_pressed("build_cycle"):
		_cycle_field_building()
	if Input.is_action_just_pressed("build_outpost"):
		_try_build_selected()
	_update_field_structures(delta)
	queue_redraw()

func _cycle_field_building() -> void:
	selected_building_index = (selected_building_index+1)%BUILD_ORDER.size()
	var id:String = BUILD_ORDER[selected_building_index]
	var definition:Dictionary = ContentDB.building(id)
	_float_text(player_pos+Vector2(0,-56),"BUILD · %s"%String(definition.get("name",id)),Color("#efd896"),1.0)

func _selected_building_id() -> String:
	return BUILD_ORDER[clampi(selected_building_index,0,BUILD_ORDER.size()-1)]

func _try_build_field_watchtower() -> void:
	selected_building_index = 0
	_try_build_selected()

func _try_build_selected() -> void:
	if field_towers.size() >= FIELD_BUILD_LIMIT:
		_float_text(player_pos+Vector2(0,-52),"FIELD STRUCTURE LIMIT REACHED",Color("#d4b28d"),0.9)
		return
	var id:String = _selected_building_id()
	var definition:Dictionary = ContentDB.building(id)
	if definition.is_empty():
		_float_text(player_pos+Vector2(0,-52),"UNKNOWN BUILDING",Color("#d7a48b"),0.9)
		return
	var cost:Dictionary = Dictionary(definition.get("cost",{}))
	for resource:Variant in cost.keys():
		var key:String = String(resource)
		var required:float = float(cost[resource])
		if float(loot.get(key,0.0)) < required:
			_float_text(player_pos+Vector2(0,-52),"NEED %d %s"%[int(ceil(required)),key.to_upper()],Color("#d7a48b"),0.9)
			return
	var snapped:Vector2 = Vector2(
		round(player_pos.x/float(LOCAL_TILE_PX))*LOCAL_TILE_PX,
		round(player_pos.y/float(LOCAL_TILE_PX))*LOCAL_TILE_PX
	)
	for structure:Dictionary in field_towers:
		if Vector2(structure.get("pos",Vector2.ZERO)).distance_to(snapped) < 66.0:
			_float_text(player_pos+Vector2(0,-52),"BUILD SPACE OCCUPIED",Color("#d7a48b"),0.9)
			return
	for building:Dictionary in local_structures:
		if Vector2(building.get("pos",Vector2.ZERO)).distance_to(snapped) < 100.0:
			_float_text(player_pos+Vector2(0,-52),"BUILD SPACE BLOCKED",Color("#d7a48b"),0.9)
			return
	for resource:Variant in cost.keys():
		var key:String = String(resource)
		loot[key] = float(loot.get(key,0.0))-float(cost[resource])
	field_towers.append({"id":id,"pos":snapped,"cooldown":0.15,"pulse":0.0})
	_spawn_ring(snapped,Color("#e1c278"))
	_float_text(snapped+Vector2(0,-56),"%s BUILT"%String(definition.get("name",id)).to_upper(),Color("#f0d68d"),1.0)
	_shake(0.08,2.2)

func _update_field_structures(delta:float) -> void:
	for i:int in range(field_towers.size()):
		var structure:Dictionary = field_towers[i]
		var id:String = String(structure.get("id","watchtower"))
		var definition:Dictionary = ContentDB.building(id)
		var role:String = String(definition.get("role","turret"))
		structure["cooldown"] = maxf(0.0,float(structure.get("cooldown",0.0))-delta)
		structure["pulse"] = float(structure.get("pulse",0.0))+delta
		match role:
			"turret":
				_update_field_turret(structure,definition)
			"trap":
				_update_field_trap(structure,definition)
			"support":
				_update_field_support(structure,definition,delta)
			"barrier":
				_update_field_barrier(structure,definition,delta)
		field_towers[i] = structure

func _update_field_turret(structure:Dictionary,definition:Dictionary) -> void:
	if float(structure.get("cooldown",0.0)) > 0.0 or enemies.is_empty():
		return
	var origin:Vector2 = Vector2(structure.get("pos",Vector2.ZERO))
	var target:Dictionary = nearest_enemy(origin)
	var attack_range:float = float(definition.get("range",260.0))
	if target.is_empty() or origin.distance_to(Vector2(target.get("pos",Vector2.ZERO))) > attack_range:
		return
	var structure_damage:float = float(definition.get("damage",12.0))+float(GameState.player.level)*0.35+float(tile.get("threat",1))*0.45
	_damage_enemy(target,structure_damage,false)
	var push_dir:Vector2 = (Vector2(target.get("pos",Vector2.ZERO))-origin).normalized()
	target["pos"] = Vector2(target.get("pos",Vector2.ZERO))+push_dir*float(definition.get("knockback",0.25))*14.0
	particles.append({"pos":Vector2(target.get("pos",Vector2.ZERO)),"life":0.20,"max":0.20,"color":Color("#e5c578")})
	var chains:int = int(definition.get("chain",0))
	if chains > 0:
		var chained:int = 0
		for other:Dictionary in enemies:
			if other == target:
				continue
			if Vector2(other.get("pos",Vector2.ZERO)).distance_to(Vector2(target.get("pos",Vector2.ZERO))) <= 125.0:
				_damage_enemy(other,structure_damage*0.55,false)
				chained += 1
				if chained >= chains:
					break
	structure["cooldown"] = float(definition.get("cadence",0.72))

func _update_field_trap(structure:Dictionary,definition:Dictionary) -> void:
	if float(structure.get("cooldown",0.0)) > 0.0:
		return
	var origin:Vector2 = Vector2(structure.get("pos",Vector2.ZERO))
	var radius:float = float(definition.get("trigger_radius",42.0))
	for enemy:Dictionary in enemies:
		var enemy_pos:Vector2 = Vector2(enemy.get("pos",Vector2.ZERO))
		if enemy_pos.distance_to(origin) <= radius+float(enemy.get("radius",14.0)):
			var trap_damage:float = float(definition.get("damage",30.0))+float(tile.get("threat",1))*0.75
			_damage_enemy(enemy,trap_damage,false)
			var push:Vector2 = (enemy_pos-origin).normalized()
			if push.length_squared() < 0.1:
				push = Vector2.RIGHT
			enemy["pos"] = enemy_pos+push*float(definition.get("knockback",1.0))*22.0
			structure["cooldown"] = float(definition.get("cooldown",1.25))
			_spawn_ring(origin,Color("#d8a26f"))
			break

func _update_field_support(structure:Dictionary,definition:Dictionary,delta:float) -> void:
	var origin:Vector2 = Vector2(structure.get("pos",Vector2.ZERO))
	if player_pos.distance_to(origin) <= float(definition.get("radius",115.0)):
		player_hp = minf(player_hp_max,player_hp+float(definition.get("heal_per_second",3.0))*delta)

func _update_field_barrier(structure:Dictionary,definition:Dictionary,delta:float) -> void:
	var origin:Vector2 = Vector2(structure.get("pos",Vector2.ZERO))
	var radius:float = float(definition.get("slow_radius",54.0))
	var resistance:float = 1.0-float(definition.get("enemy_speed_mult",0.6))
	for enemy:Dictionary in enemies:
		var enemy_pos:Vector2 = Vector2(enemy.get("pos",Vector2.ZERO))
		if enemy_pos.distance_to(origin) <= radius+float(enemy.get("radius",14.0)):
			var push:Vector2 = (enemy_pos-origin).normalized()
			if push.length_squared() < 0.1:
				push = Vector2.RIGHT
			enemy["pos"] = enemy_pos+push*resistance*55.0*delta

func _spawn_allies() -> void:
	allies.clear()
	UnitRoster.ensure_schema()
	var offsets:Array[Vector2] = [Vector2(-45,20),Vector2(45,20),Vector2(-70,55),Vector2(70,55),Vector2(0,65),Vector2(-95,75),Vector2(95,75)]
	var idx:int = 0
	for record:Dictionary in UnitRoster.battle_instances(3):
		var family:String = String(record.get("family","militia"))
		allies.append({
			"type":family,
			"pos":player_pos+offsets[idx%offsets.size()],
			"cooldown":rng.randf_range(0.0,1.0),
			"uid":String(record.get("uid","")),
			"prefix":String(record.get("prefix","")),
			"elite":bool(record.get("elite",false))
		})
		idx += 1

func _update_allies(delta:float) -> void:
	var index:int = 0
	for ally:Dictionary in allies:
		var ally_type:String = String(ally.get("type","militia"))
		var angle:float = elapsed*0.45+float(index)*TAU/float(maxi(1,allies.size()))
		var desired:Vector2 = player_pos+Vector2(cos(angle),sin(angle))*float(68+(index%3)*20)
		ally["pos"] = Vector2(ally.get("pos",player_pos)).lerp(desired,minf(1.0,delta*4.0))
		ally["cooldown"] = float(ally.get("cooldown",0.0))-delta
		if float(ally.get("cooldown",0.0)) <= 0.0 and not enemies.is_empty():
			var target:Dictionary = nearest_enemy(Vector2(ally.get("pos",player_pos)))
			var record:Dictionary = {"family":ally_type,"prefix":String(ally.get("prefix","")),"elite":bool(ally.get("elite",false))}
			var effective_range:float = _unit_range(ally_type)*UnitRoster.range_mult(record)
			if not target.is_empty() and Vector2(ally.get("pos",player_pos)).distance_to(Vector2(target.get("pos",Vector2.ZERO))) < effective_range:
				var rally_mult:float = 1.45 if rally_time > 0.0 else 1.0
				var momentum:float = 1.0+float(mini(combo,30))*0.008
				var hit:float = unit_damage(ally_type)*army_damage_mult*rally_mult*momentum*UnitRoster.damage_mult(record)
				var branch:String = UnitProgression.evolution(ally_type)
				if ally_type == "militia" and branch == "vanguard" and bool(target.get("boss",false)):
					hit *= 1.55
				if ally_type == "wolf" and branch == "dire" and float(target.get("hp",1.0))/maxf(1.0,float(target.get("max_hp",1.0))) < 0.45:
					hit *= 1.50
				if ally_type == "ridgeback" and float(target.get("hp",1.0))/maxf(1.0,float(target.get("max_hp",1.0))) < 0.45:
					hit *= 1.30
				if ally_type == "stone_golem" and bool(target.get("boss",false)):
					hit *= 1.25
				hit *= UnitRoster.execute_mult(record,float(target.get("hp",1.0))/maxf(1.0,float(target.get("max_hp",1.0))))
				_damage_enemy(target,hit,false)
				var quality_heal:float = UnitRoster.heal_on_hit(record)
				if quality_heal > 0.0:
					player_hp = minf(player_hp_max,player_hp+quality_heal)
				var chain:float = UnitRoster.chain_ratio(record)
				if chain > 0.0:
					_quality_chain(target,hit*chain)
				if ally_type == "mage":
					if branch == "stormcaller":
						_storm_chain(target,hit)
					elif branch == "lifebinder":
						player_hp = minf(player_hp_max,player_hp+2.2+float(GameState.unit_levels.get("mage",1))*0.38)
				elif ally_type == "mire_leech":
					player_hp = minf(player_hp_max,player_hp+1.5+float(GameState.unit_levels.get(ally_type,1))*0.30)
				elif ally_type == "ember_imp":
					_wild_splash(target,hit*0.30)
				ally["cooldown"] = unit_cooldown(ally_type)*army_haste_mult*UnitRoster.cooldown_mult(record)
		index += 1

func _quality_chain(origin:Dictionary,amount:float) -> void:
	for enemy:Dictionary in enemies:
		if enemy == origin:
			continue
		if Vector2(origin.get("pos",Vector2.ZERO)).distance_to(Vector2(enemy.get("pos",Vector2.ZERO))) <= 125.0:
			_damage_enemy(enemy,amount,false)
			_spawn_ring(Vector2(enemy.get("pos",Vector2.ZERO)),Color("#8ebdff"))
			break

func _draw_ground() -> void:
	super._draw_ground()
	var visible:Rect2 = _visible_world_rect(140.0)
	for structure:Dictionary in field_towers:
		var pos:Vector2 = Vector2(structure.get("pos",Vector2.ZERO))
		if not visible.has_point(pos):
			continue
		var id:String = String(structure.get("id","watchtower"))
		var definition:Dictionary = ContentDB.building(id)
		var sprite_id:String = String(definition.get("sprite_id","building_watchtower"))
		if VisualAtlas.has(sprite_id):
			_draw_atlas(sprite_id,pos,Vector2(72,68),true)
		else:
			var role:String = String(definition.get("role","turret"))
			var color:Color = {"turret":Color("#c79f62"),"trap":Color("#b86f54"),"support":Color("#72a77d"),"barrier":Color("#8d765e")}.get(role,Color("#b8a06d"))
			draw_rect(Rect2(pos-Vector2(24,18),Vector2(48,36)),color)
		if String(definition.get("role","")) == "support":
			draw_circle(pos,float(definition.get("radius",115.0)),Color(0.3,0.8,0.48,0.08),false,2.0)

func _draw() -> void:
	super._draw()
	if ended:
		return
	var id:String = _selected_building_id()
	var definition:Dictionary = ContentDB.building(id)
	var cost:Dictionary = Dictionary(definition.get("cost",{}))
	var cost_parts:Array[String] = []
	for resource:Variant in cost.keys():
		cost_parts.append("%d %s"%[int(cost[resource]),String(resource).capitalize()])
	var label:String = "C: %s · B: Build (%s)"%[String(definition.get("name",id)),", ".join(cost_parts)]
	draw_string(ThemeDB.fallback_font,player_pos+Vector2(-92,-70),label,HORIZONTAL_ALIGNMENT_LEFT,240,12,Color("#ead9a7"))
