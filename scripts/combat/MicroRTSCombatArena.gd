class_name MicroRTSCombatArena
extends HybridAreaCombatArena

# Player input is deliberate. The Warden never auto-attacks and natural resources
# never auto-gather. Enemy pressure comes from persistent AREA ecology, not a timer.

var claude_layout:ClaudeAreaLayout
var ecology_stream_timer:float = 0.0
var ecology_runtime:Dictionary = {}
var gather_target:=Vector2i(-999,-999)
var gather_hits:int = 0
var gather_tick:float = 0.0
var leave_direction:=Vector2i.ZERO
var leave_hint_time:float = 0.0

func begin(data:Dictionary) -> void:
	# Hybrid/Discovery/Retention still supply equipment, status, loot and unit systems;
	# their arcade pressure hooks are overridden below.
	super.begin(data)
	safe_area = false
	bounds = Rect2(0,0,ClaudeAreaLayout.WORLD_PX,ClaudeAreaLayout.WORLD_PX)
	current_macro = Vector2i(int(data.get("x",0)),int(data.get("y",0)))
	claude_layout = ClaudeAreaLayout.new()
	claude_layout.generate(current_macro,String(data.get("biome","Greenlands")),int(data.get("threat",1)),bool(data.get("home",false)))
	var area_state:Dictionary = WorldAreaManager.area_state(current_macro.x,current_macro.y)
	claude_layout.apply_removed(Array(area_state.get("removed_nodes",[])))
	AreaEcology.ensure_area(current_macro,data)
	# Preserve the saved/edge entry point, but use Claude's center clearing on a first visit.
	var saved:Array = Array(area_state.get("player_local",[]))
	if saved.size()<2:
		player_pos = claude_layout.tile_to_world(claude_layout.spawn_tile)
	else:
		player_pos = WorldAreaManager.entry_local_position()
	player_pos.x=clampf(player_pos.x,24.0,bounds.end.x-24.0)
	player_pos.y=clampf(player_pos.y,24.0,bounds.end.y-24.0)
	# Base class may have created temporary arena content. None survives this pivot.
	enemies.clear()
	enemy_projectiles.clear()
	resource_nodes.clear()
	discoveries.clear()
	active_discovery_index=-1
	ecology_runtime.clear()
	leave_direction=Vector2i.ZERO
	_rebuild_ally_positions()
	_update_camera()
	queue_redraw()

# ================================================================ NO ARCADE AUTOPILOT
func _auto_attack() -> void:
	pass

func _spawn_logic() -> void:
	# No time-based horde escalation. AreaEcology streams persistent groups instead.
	pass

func _offer_gambit() -> void:
	gambit_offered=true
	gambit_active=false

func _spawn_nemesis() -> void:
	# Nemesis will return later as a physical world encounter, never a stopwatch pop-in.
	nemesis_spawned=true

func _spawn_hunter_pack() -> void:
	# Pursuit becomes a strategic world-state encounter in the micro-RTS pass.
	hunter_pack_spawned=true

func _spawn_discoveries() -> void:
	# Discovery content remains in the project, but random multi-choice interruptions are disabled.
	discoveries.clear()

func _update_discoveries(_delta:float) -> void:
	pass

func _check_level() -> void:
	# Run levels are now quiet battlefield veterancy, not choose-one-of-three interruptions.
	while kills >= next_level_kills:
		run_level += 1
		next_level_kills += 12+run_level*5
		army_damage_mult *= 1.025
		player_hp=minf(player_hp_max,player_hp+player_hp_max*0.05)

func _spawn_resource_nodes() -> void:
	resource_nodes.clear()

func _reposition_resource_nodes_near_player() -> void:
	pass

# ================================================================ MANUAL WARDEN COMBAT
func _handle_input(delta:float) -> void:
	super._handle_input(delta)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_manual_attack_toward(get_local_mouse_position())

func _manual_attack_toward(world_target:Vector2) -> void:
	if attack_timer>0.0:
		return
	if weapon_profile.is_empty() or attack_profile.is_empty():
		_resolve_equipped_weapon()
	var direction:Vector2=(world_target-player_pos).normalized()
	if direction.length_squared()<0.01:
		return
	attack_visual_dir=direction
	attack_visual_motion=String(attack_profile.get("motion","slash"))
	attack_visual_duration=float(attack_profile.get("duration",0.28))
	attack_visual_time=attack_visual_duration
	var speed_mult:float=maxf(0.15,float(weapon_profile.get("attack_speed",1.0)))
	attack_timer=maxf(0.10,attack_interval/speed_mult)
	var is_crit:bool=rng.randf()<crit_chance
	var crit_factor:float=crit_mult if is_crit else 1.0
	var hit_damage:float=damage*float(weapon_profile.get("damage_mult",1.0))*float(attack_profile.get("damage_mult",1.0))*crit_factor
	var knockback_amount:float=float(weapon_profile.get("knockback",0.6))*float(attack_profile.get("knockback_mult",1.0))
	match String(attack_profile.get("mode","melee_arc")):
		"melee_arc": _perform_arc_attack(direction,hit_damage,knockback_amount,is_crit)
		"melee_thrust": _perform_thrust_attack(direction,hit_damage,knockback_amount,is_crit)
		"melee_slam": _perform_slam_attack(direction,hit_damage,knockback_amount,is_crit)
		_: _perform_ranged_attack(direction,hit_damage,knockback_amount,is_crit)

# ================================================================ MANUAL CLAUDE GATHERING
func _update_resource_nodes(delta:float) -> void:
	if claude_layout==null:
		return
	gather_tick=maxf(0.0,gather_tick-delta)
	var candidate:Vector2i=_nearest_gatherable_tile()
	if candidate!=gather_target:
		gather_target=candidate
		gather_hits=0
	if candidate.x<0:
		return
	if not Input.is_action_pressed("gather"):
		return
	if gather_tick>0.0:
		return
	gather_tick=0.22
	var obj:Dictionary=claude_layout.object_at(candidate.x,candidate.y)
	if obj.is_empty() or int(obj.get("hits",0))<=0:
		return
	gather_hits+=1
	var p:Vector2=claude_layout.tile_to_world(candidate)
	_float_text(p+Vector2(0,-24),"%d/%d"%[gather_hits,int(obj.get("hits",1))],Color(String(obj.get("color","#ffffff"))),0.35)
	if gather_hits<int(obj.get("hits",1)):
		return
	for raw_resource:Variant in Dictionary(obj.get("drops",{})).keys():
		var resource:String=String(raw_resource)
		var amount:float=float(Dictionary(obj["drops"])[raw_resource])*(1.0+float(GameState.talent_rank("scavenger"))*0.12+float(gear_bonuses.get("harvest",0.0)))
		loot[resource]=float(loot.get(resource,0.0))+amount
		_float_text(p+Vector2(0,-38),"+%d %s"%[int(round(amount)),resource.to_upper()],_resource_color(resource),0.8)
	xp+=int(obj.get("xp",1))*4
	claude_layout.remove_object(candidate)
	_persist_removed_natural(candidate)
	gather_target=Vector2i(-999,-999)
	gather_hits=0
	_spawn_ring(p,Color(String(obj.get("color","#ffffff"))))

func _nearest_gatherable_tile() -> Vector2i:
	if claude_layout==null: return Vector2i(-999,-999)
	var center:Vector2i=claude_layout.world_to_tile(player_pos)
	var best:=Vector2i(-999,-999)
	var best_d:float=82.0
	for y:int in range(center.y-2,center.y+3):
		for x:int in range(center.x-2,center.x+3):
			if not claude_layout.in_bounds(x,y): continue
			var obj:Dictionary=claude_layout.object_at(x,y)
			if obj.is_empty() or int(obj.get("hits",0))<=0: continue
			var d:float=player_pos.distance_to(claude_layout.tile_to_world(Vector2i(x,y)))
			if d<best_d:
				best_d=d; best=Vector2i(x,y)
	return best

func _persist_removed_natural(tile_pos:Vector2i) -> void:
	var areas:Dictionary=Dictionary(GameState.world.get("areas",{}))
	var key:String=WorldAreaManager.area_key(current_macro.x,current_macro.y)
	var state:Dictionary=Dictionary(areas.get(key,WorldAreaManager.area_state(current_macro.x,current_macro.y)))
	var removed:Array=Array(state.get("removed_nodes",[]))
	var encoded:Array=[tile_pos.x,tile_pos.y]
	if encoded not in removed: removed.append(encoded)
	state["removed_nodes"]=removed
	areas[key]=state
	GameState.world["areas"]=areas

# ================================================================ PERSISTENT ECOLOGY STREAM
func _process(delta:float) -> void:
	ecology_stream_timer-=delta
	leave_hint_time=maxf(0.0,leave_hint_time-delta)
	super._process(delta)
	if ended or paused_for_upgrade:
		return
	if ecology_stream_timer<=0.0:
		ecology_stream_timer=0.35
		_stream_ecology()

func _stream_ecology() -> void:
	var members:Array=AreaEcology.live_members(current_macro,tile)
	var known:Dictionary={}
	for raw:Variant in members:
		var member:Dictionary=Dictionary(raw)
		var uid:String=String(member.get("uid",""))
		known[uid]=true
		if ecology_runtime.has(uid): continue
		var p:=Vector2(float(member.get("x",0.0)),float(member.get("y",0.0)))
		if p.distance_to(player_pos)<=1050.0 and not AreaEcology.point_in_friendly_claim(current_macro,p):
			_spawn_ecology_member(member)
	# De-stream far enemies, writing their wounds back into the AREA.
	for i:int in range(enemies.size()-1,-1,-1):
		var enemy:Dictionary=enemies[i]
		var uid:String=String(enemy.get("ecology_uid",""))
		if uid=="": continue
		var p:Vector2=Vector2(enemy.get("pos",Vector2.ZERO))
		if p.distance_to(player_pos)>1700.0:
			AreaEcology.update_member(current_macro,uid,float(enemy.get("hp",1.0))/maxf(1.0,float(enemy.get("max_hp",1.0))),p,false)
			ecology_runtime.erase(uid)
			enemies.remove_at(i)

func _spawn_ecology_member(member:Dictionary) -> void:
	var type:String=String(member.get("type","raider"))
	var definition:Dictionary=ContentDB.monster(type)
	var threat:int=int(tile.get("threat",1))
	var hp:float=(30.0+float(threat)*9.0)*float(definition.get("hp_mult",1.0))*float(member.get("hp_pct",1.0))
	var max_hp:float=(30.0+float(threat)*9.0)*float(definition.get("hp_mult",1.0))
	var speed:float=(62.0+float(threat)*1.6)*float(definition.get("speed_mult",1.0))
	var enemy:Dictionary={
		"pos":Vector2(float(member.get("x",0.0)),float(member.get("y",0.0))),
		"hp":hp,"max_hp":max_hp,"speed":speed,"base_speed":speed,
		"type":type,"behavior":String(definition.get("behavior","melee")),"radius":14.0,
		"boss":false,"elite":bool(member.get("elite",false)),"flash":0.0,"attack_cd":0.0,
		"shoot_cd":rng.randf_range(0.3,1.1),"special_cd":0.0,"damage_mult":float(definition.get("damage_mult",1.0)),
		"charge_time":0.0,"charge_dir":Vector2.ZERO,"archetype":"","name":"",
		"attack_id":String(definition.get("attack_id","enemy_claw")),"projectile_id":String(definition.get("projectile_id","")),
		"sprite_id":String(definition.get("sprite_id","")),"statuses":{},"ecology_uid":String(member.get("uid",""))
	}
	if bool(enemy["elite"]):
		enemy["hp"]=float(enemy["hp"])*1.65; enemy["max_hp"]=float(enemy["max_hp"])*1.65
		enemy["damage_mult"]=float(enemy["damage_mult"])*1.25; enemy["radius"]=16.0
	enemies.append(enemy)
	ecology_runtime[String(member.get("uid",""))]=true

func _kill_enemy(enemy:Dictionary) -> void:
	var uid:String=String(enemy.get("ecology_uid",""))
	if uid!="":
		AreaEcology.update_member(current_macro,uid,0.0,Vector2(enemy.get("pos",Vector2.ZERO)),true)
		ecology_runtime.erase(uid)
	super._kill_enemy(enemy)

func _flush_ecology() -> void:
	for enemy:Dictionary in enemies:
		var uid:String=String(enemy.get("ecology_uid",""))
		if uid=="": continue
		AreaEcology.update_member(current_macro,uid,float(enemy.get("hp",1.0))/maxf(1.0,float(enemy.get("max_hp",1.0))),Vector2(enemy.get("pos",Vector2.ZERO)),false)

# ================================================================ MICRO RTS TARGETING
func _spawn_allies() -> void:
	allies.clear()
	UnitRoster.ensure_schema()
	var source:Array=UnitRoster.all_field_instances(24)
	for i:int in range(source.size()):
		var record:Dictionary=Dictionary(source[i])
		var row:int=int(floor(float(i)/6.0))
		var col:int=i%6
		var offset:=Vector2((float(col)-2.5)*42.0,65.0+float(row)*42.0)
		var family:String=String(record.get("family","militia"))
		var level:int=int(record.get("level",1))
		var max_hp:float=55.0+float(level)*13.0
		if family=="stone_golem": max_hp*=1.8
		allies.append({
			"type":family,"pos":player_pos+offset,"cooldown":rng.randf_range(0.0,0.7),
			"uid":String(record.get("uid","")),"prefix":String(record.get("prefix","")),"elite":bool(record.get("elite",false)),
			"record":record,"formation_offset":offset,"hold_pos":player_pos+offset,
			"speed":180.0+rng.randf_range(-8.0,8.0),"hp_max":max_hp,"hp":max_hp*float(record.get("hp_pct",1.0)),"walk":0.0,"facing":Vector2.RIGHT
		})

func _rebuild_ally_positions() -> void:
	for i:int in range(allies.size()):
		var ally:Dictionary=allies[i]
		ally["pos"]=player_pos+Vector2(ally.get("formation_offset",Vector2.ZERO))
		ally["hold_pos"]=ally["pos"]
		allies[i]=ally

func _nearest_enemy_in_range(origin:Vector2,max_range:float) -> Dictionary:
	var best:Dictionary={}; var best_d:float=max_range
	for enemy:Dictionary in enemies:
		var d:float=origin.distance_to(Vector2(enemy.get("pos",Vector2.ZERO)))
		if d<best_d:
			best_d=d; best=enemy
	return best

func _update_allies(delta:float) -> void:
	for i:int in range(allies.size()-1,-1,-1):
		var ally:Dictionary=allies[i]
		if float(ally.get("hp",1.0))<=0.0:
			UnitRoster.persist_hp(String(ally.get("uid","")),0.15)
			allies.remove_at(i)
			continue
		var record:Dictionary=Dictionary(ally.get("record",{}))
		var ally_type:String=String(ally.get("type","militia"))
		var ally_pos:Vector2=Vector2(ally.get("pos",player_pos))
		ally["cooldown"]=float(ally.get("cooldown",0.0))-delta
		var formation:Vector2=player_pos+Vector2(ally.get("formation_offset",Vector2.ZERO))
		var target:Dictionary={}
		match party_stance:
			"follow": pass
			"defensive": target=_nearest_enemy_in_range(player_pos,260.0)
			"hold": target=_nearest_enemy_in_range(Vector2(ally.get("hold_pos",ally_pos)),280.0)
			_: target=_nearest_enemy_in_range(ally_pos,560.0)
		var desired:Vector2=Vector2(ally.get("hold_pos",ally_pos)) if party_stance=="hold" else formation
		var effective_range:float=_unit_range(ally_type)*UnitRoster.range_mult(record)
		if not target.is_empty():
			var target_pos:Vector2=Vector2(target.get("pos",Vector2.ZERO))
			var distance:float=ally_pos.distance_to(target_pos)
			var ranged:bool=ally_type in ["archer","mage","frost_wisp","ember_imp"]
			var ideal:float=minf(effective_range*0.72,185.0) if ranged else 34.0
			if distance>ideal:
				desired=target_pos-(target_pos-ally_pos).normalized()*ideal
			if distance<=effective_range and float(ally.get("cooldown",0.0))<=0.0:
				_attack_from_ally(ally,target,record)
			ally["facing"]=(target_pos-ally_pos).normalized()
		var to_desired:Vector2=desired-ally_pos
		if to_desired.length()>10.0:
			var velocity:Vector2=to_desired.normalized()*float(ally.get("speed",180.0))
			ally_pos+=velocity*delta
			ally["walk"]=float(ally.get("walk",0.0))+delta*velocity.length()/95.0
			ally["facing"]=velocity.normalized()
		for j:int in range(allies.size()):
			if j==i: continue
			var apart:Vector2=ally_pos-Vector2(Dictionary(allies[j]).get("pos",ally_pos))
			if apart.length_squared()>0.1 and apart.length()<24.0:
				ally_pos+=apart.normalized()*28.0*delta
		ally["pos"]=ally_pos
		allies[i]=ally

func _nearest_friendly(origin:Vector2) -> Dictionary:
	var result:Dictionary={"kind":"player","index":-1,"pos":player_pos}
	var best:float=origin.distance_to(player_pos)
	for i:int in range(allies.size()):
		var ally:Dictionary=allies[i]
		if float(ally.get("hp",0.0))<=0.0: continue
		var p:Vector2=Vector2(ally.get("pos",player_pos))
		var d:float=origin.distance_to(p)
		if d<best:
			best=d; result={"kind":"ally","index":i,"pos":p}
	return result

func _update_enemies(delta:float) -> void:
	for i:int in range(enemies.size()-1,-1,-1):
		var enemy:Dictionary=enemies[i]
		_prepare_enemy_statuses(enemy,delta)
		enemy["flash"]=maxf(0.0,float(enemy.get("flash",0.0))-delta)
		enemy["attack_cd"]=maxf(0.0,float(enemy.get("attack_cd",0.0))-delta)
		enemy["shoot_cd"]=maxf(0.0,float(enemy.get("shoot_cd",0.0))-delta)
		if float(enemy.get("hp",0.0))<=0.0:
			_kill_enemy(enemy); enemies.remove_at(i); continue
		var enemy_pos:Vector2=Vector2(enemy.get("pos",Vector2.ZERO))
		var target:Dictionary=_nearest_friendly(enemy_pos)
		var target_pos:Vector2=Vector2(target.get("pos",player_pos))
		var direction:Vector2=(target_pos-enemy_pos).normalized()
		var distance:float=enemy_pos.distance_to(target_pos)
		var behavior:String=String(enemy.get("behavior","melee"))
		if behavior=="ranged":
			if distance>250.0: enemy_pos+=direction*float(enemy.get("speed",60.0))*delta
			elif distance<145.0: enemy_pos-=direction*float(enemy.get("speed",60.0))*0.60*delta
			if float(enemy.get("shoot_cd",0.0))<=0.0 and distance<390.0:
				_spawn_data_enemy_projectile(enemy,direction)
				enemy["shoot_cd"]=_enemy_attack_cooldown(enemy)
		else:
			enemy_pos+=direction*float(enemy.get("speed",60.0))*delta
			if distance<float(enemy.get("radius",14.0))+17.0 and float(enemy.get("attack_cd",0.0))<=0.0:
				var attack:Dictionary=ContentDB.attack(String(enemy.get("attack_id","enemy_claw")))
				var amount:float=(7.0+float(int(tile.get("threat",1)))*1.4)*float(enemy.get("damage_mult",1.0))*float(attack.get("damage_mult",1.0))
				_damage_friendly_target(target,amount)
				enemy["attack_cd"]=maxf(0.45,float(attack.get("duration",0.75)))
		enemy["pos"]=enemy_pos
		enemies[i]=enemy

func _damage_friendly_target(target:Dictionary,amount:float) -> void:
	if String(target.get("kind","player"))=="player":
		_damage_player(amount); return
	var index:int=int(target.get("index",-1))
	if index<0 or index>=allies.size(): return
	var ally:Dictionary=allies[index]
	ally["hp"]=maxf(0.0,float(ally.get("hp",1.0))-amount)
	allies[index]=ally
	_float_text(Vector2(ally.get("pos",player_pos))+Vector2(0,-28),"-%d"%int(round(amount)),Color("#e99a8f"),0.45)

func _update_enemy_projectiles(delta:float) -> void:
	for i:int in range(enemy_projectiles.size()-1,-1,-1):
		var shot:Dictionary=enemy_projectiles[i]
		shot["pos"]=Vector2(shot.get("pos",Vector2.ZERO))+Vector2(shot.get("vel",Vector2.ZERO))*delta
		shot["life"]=float(shot.get("life",0.0))-delta
		var hit:bool=false
		var p:Vector2=Vector2(shot.get("pos",Vector2.ZERO))
		if p.distance_to(player_pos)<17.0+float(shot.get("radius",5.0)):
			_damage_player(float(shot.get("damage",1.0))); hit=true
		else:
			for ai:int in range(allies.size()):
				var ally:Dictionary=allies[ai]
				if p.distance_to(Vector2(ally.get("pos",Vector2.ZERO)))<14.0+float(shot.get("radius",5.0)):
					_damage_friendly_target({"kind":"ally","index":ai,"pos":ally.get("pos",Vector2.ZERO)},float(shot.get("damage",1.0)))
					hit=true; break
		if hit or float(shot.get("life",0.0))<=0.0 or not bounds.has_point(p): enemy_projectiles.remove_at(i)
		else: enemy_projectiles[i]=shot

# ================================================================ RIMWORLD-LIKE MACRO EXIT
func _check_area_border() -> void:
	var dir:=Vector2i.ZERO
	if player_pos.x<=28.0: dir=Vector2i.LEFT
	elif player_pos.x>=bounds.end.x-28.0: dir=Vector2i.RIGHT
	elif player_pos.y<=28.0: dir=Vector2i.UP
	elif player_pos.y>=bounds.end.y-28.0: dir=Vector2i.DOWN
	leave_direction=dir
	if dir==Vector2i.ZERO:
		return
	leave_hint_time=0.25
	if not Input.is_action_just_pressed("interact"):
		return
	_flush_ecology()
	WorldAreaManager.store_player_local(player_pos)
	var next:Vector2i=WorldAreaManager.walk_transition(dir)
	var next_tile:Dictionary=WorldAreaManager.tile_data(next.x,next.y)
	GameState.world["selected_tile"]=next_tile.duplicate(true)
	GameState.toast_requested.emit("LEFT AREA ON FOOT · [%d,%d] · 0 Food"%[next.x,next.y])
	area_transition_requested.emit(next_tile)

# ================================================================ CLAUDE TERRAIN DRAW
func _draw_ground() -> void:
	if claude_layout==null:
		return
	var visible:Rect2=_visible_world_rect(64.0)
	var cells:Rect2i=claude_layout.visible_tiles(visible,1)
	for y:int in range(cells.position.y,cells.end.y):
		for x:int in range(cells.position.x,cells.end.x):
			var g:Dictionary=claude_layout.ground_at(x,y)
			var rect:=Rect2(Vector2(x,y)*ClaudeAreaLayout.TILE,Vector2(ClaudeAreaLayout.TILE,ClaudeAreaLayout.TILE))
			draw_rect(rect,Color(String(g.get("color","#4a6b3c"))))
	# Natural objects draw after ground, using the same generated object layer.
	for y:int in range(cells.position.y,cells.end.y):
		for x:int in range(cells.position.x,cells.end.x):
			var id:String=claude_layout.object_type_at(x,y)
			if id=="": continue
			_draw_claude_object(id,Rect2(Vector2(x,y)*ClaudeAreaLayout.TILE,Vector2(ClaudeAreaLayout.TILE,ClaudeAreaLayout.TILE)))
	# Persistent player structures are still functional while Claude building art is ported.
	for structure:Dictionary in field_towers:
		var pos:Vector2=Vector2(structure.get("pos",Vector2.ZERO))
		if not visible.grow(96.0).has_point(pos): continue
		var definition:Dictionary=ContentDB.building(String(structure.get("id","")))
		var sprite_id:String=String(definition.get("sprite_id","building_house"))
		if VisualAtlas.has(sprite_id): _draw_atlas(sprite_id,pos,Vector2(58,54),true)

func _ellipse(center:Vector2,rx:float,ry:float,segments:int=12) -> PackedVector2Array:
	var out:=PackedVector2Array()
	for i:int in range(segments):
		var a:float=TAU*float(i)/float(segments)
		out.append(center+Vector2(cos(a)*rx,sin(a)*ry))
	return out

func _draw_claude_object(id:String,r:Rect2) -> void:
	var c:Vector2=r.position+r.size*0.5
	var u:float=r.size.x
	var wobble:float=sin(elapsed*1.4+r.position.x*0.05+r.position.y*0.07)*0.9
	match id:
		"tree":
			draw_colored_polygon(_ellipse(c+Vector2(0,u*0.42),u*0.34,u*0.13),Color(0,0,0,0.30))
			draw_rect(Rect2(c+Vector2(-u*0.09,u*0.02),Vector2(u*0.18,u*0.44)),Color("#46331f"))
			draw_colored_polygon(_ellipse(c+Vector2(wobble,-u*0.18),u*0.48,u*0.44,14),Color("#2c4a2c"))
			draw_colored_polygon(_ellipse(c+Vector2(wobble-u*0.14,-u*0.32),u*0.22,u*0.20,10),Color("#3d6339"))
		"dead_tree":
			draw_colored_polygon(_ellipse(c+Vector2(0,u*0.42),u*0.28,u*0.11),Color(0,0,0,0.28))
			draw_line(c+Vector2(0,u*0.4),c+Vector2(0,-u*0.14),Color("#4a3f33"),u*0.16)
			draw_line(c+Vector2(0,-u*0.1),c+Vector2(u*0.34+wobble,-u*0.34),Color("#4a3f33"),u*0.06)
			draw_line(c+Vector2(0,-u*0.02),c+Vector2(-u*0.3+wobble,-u*0.26),Color("#3f362b"),u*0.06)
		"rock","iron_vein","gold_vein","mana_crystal":
			draw_colored_polygon(_ellipse(c+Vector2(0,u*0.30),u*0.36,u*0.12),Color(0,0,0,0.28))
			var rock:=PackedVector2Array([c+Vector2(-u*0.4,u*0.24),c+Vector2(-u*0.24,-u*0.28),c+Vector2(u*0.16,-u*0.34),c+Vector2(u*0.4,0),c+Vector2(u*0.28,u*0.26)])
			draw_colored_polygon(rock,Color("#5c6068") if id!="rock" else Color("#6a6f77"))
			if id=="rock":
				draw_colored_polygon(PackedVector2Array([c+Vector2(-u*0.26,-u*0.26),c+Vector2(u*0.12,-u*0.36),c+Vector2(-u*0.04,-u*0.06)]),Color("#878d96"))
			else:
				var ore:Color={"iron_vein":Color("#8b97a8"),"gold_vein":Color("#d9a441"),"mana_crystal":Color("#7b5fc4")}[id]
				for k:int in range(3):
					var o:=Vector2((k-1)*u*0.2,(k%2)*u*0.16-u*0.08)
					draw_colored_polygon(_ellipse(c+o,u*0.11,u*0.10,8),ore.lightened(0.15))
		"bush":
			draw_colored_polygon(_ellipse(c+Vector2(0,u*0.28),u*0.26,u*0.09,10),Color(0,0,0,0.24))
			draw_colored_polygon(_ellipse(c+Vector2(wobble*0.5,u*0.02),u*0.34,u*0.28),Color("#5d7a3a"))
			for k:int in range(3): draw_colored_polygon(_ellipse(c+Vector2((k-1)*u*0.18,-u*0.06),u*0.07,u*0.07,8),Color("#b8433a"))
		"ruin":
			draw_colored_polygon(_ellipse(c+Vector2(0,u*0.34),u*0.30,u*0.10),Color(0,0,0,0.26))
			draw_rect(Rect2(c+Vector2(-u*0.17,-u*0.35),Vector2(u*0.34,u*0.62)),Color("#8b8578"))
			draw_rect(Rect2(c+Vector2(-u*0.23,-u*0.37),Vector2(u*0.46,u*0.10)),Color("#a09a8c"))
		"lair":
			var pulse:float=0.5+sin(elapsed*2.6)*0.3
			draw_colored_polygon(_ellipse(c,u*0.62,u*0.62,16),Color(0.7,0.12,0.15,0.16+pulse*0.14))
			draw_colored_polygon(_ellipse(c+Vector2(0,u*0.06),u*0.42,u*0.34,14),Color("#241014"))
			draw_colored_polygon(_ellipse(c+Vector2(-u*0.12,0),u*0.07,u*0.09,8),Color(1,0.4,0.3,pulse))
			draw_colored_polygon(_ellipse(c+Vector2(u*0.12,0),u*0.07,u*0.09,8),Color(1,0.4,0.3,pulse))
	if gather_target==claude_layout.world_to_tile(c) and Input.is_action_pressed("gather"):
		var obj:Dictionary=claude_layout.object_at(gather_target.x,gather_target.y)
		if not obj.is_empty():
			var ratio:float=clampf(float(gather_hits)/maxf(1.0,float(obj.get("hits",1))),0.0,1.0)
			draw_rect(Rect2(c+Vector2(-14,20),Vector2(28,4)),Color("#151b23"))
			draw_rect(Rect2(c+Vector2(-14,20),Vector2(28*ratio,4)),Color(String(obj.get("color","#ffffff"))))

func _draw_ally(ally:Dictionary) -> void:
	super._draw_ally(ally)
	var hp_ratio:float=clampf(float(ally.get("hp",1.0))/maxf(1.0,float(ally.get("hp_max",1.0))),0.0,1.0)
	var p:Vector2=Vector2(ally.get("pos",Vector2.ZERO))
	draw_rect(Rect2(p+Vector2(-16,-35),Vector2(32,3)),Color("#192129"))
	draw_rect(Rect2(p+Vector2(-16,-35),Vector2(32*hp_ratio,3)),Color("#78b87d"))

func _draw() -> void:
	super._draw()
	if leave_direction!=Vector2i.ZERO:
		var text:String="F · LEAVE AREA ON FOOT → WORLD MAP · 0 FOOD"
		draw_string(ThemeDB.fallback_font,player_pos+Vector2(-190,-58),text,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#f0dfae"))
	if gather_target.x>=0 and not Input.is_action_pressed("gather"):
		draw_string(ThemeDB.fallback_font,claude_layout.tile_to_world(gather_target)+Vector2(-28,-30),"E · GATHER",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#e8dcc0"))
