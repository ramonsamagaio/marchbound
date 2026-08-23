class_name DepthCombatArena
extends QualityCombatArena

var weapon_profile:Dictionary={}
var attack_profile:Dictionary={}
var attack_visual_time:=0.0
var attack_visual_duration:=0.0
var attack_visual_dir:=Vector2.RIGHT
var attack_visual_mode:=""
var drop_candidates:Array[String]=[]
var last_killed_type:=""

func begin(data:Dictionary)->void:
	drop_candidates.clear()
	last_killed_type=""
	_resolve_equipped_weapon()
	super.begin(data)

func _process(delta:float)->void:
	attack_visual_time=maxf(0.0,attack_visual_time-delta)
	super._process(delta)

func _resolve_equipped_weapon()->void:
	var equipped_item:Dictionary=GameState.get_item(String(GameState.equipped.get("weapon","")))
	var content_id:=String(equipped_item.get("content_id",""))
	if content_id=="":
		var lower:=String(equipped_item.get("name","")).to_lower()
		if "bow" in lower: content_id="hunter_bow"
		elif "staff" in lower: content_id="apprentice_staff"
		elif "spear" in lower or "pike" in lower: content_id="militia_spear"
		elif "axe" in lower: content_id="woodsman_axe"
		elif "dagger" in lower: content_id="mire_dagger"
		elif "maul" in lower or "hammer" in lower: content_id="quarry_maul"
		else: content_id="training_sword"
	weapon_profile=ContentDB.weapon(content_id)
	if weapon_profile.is_empty():
		weapon_profile=ContentDB.weapon("training_sword")
	attack_profile=ContentDB.attack(String(weapon_profile.get("attack_id","slash_quick")))

func _biome_roster()->Array:
	var roster:Array[String]=ContentDB.monsters_for_biome(String(tile.get("biome","Greenlands")))
	return roster if not roster.is_empty() else super._biome_roster()

func _enemy_behavior(type:String)->String:
	var d:=ContentDB.monster(type)
	return String(d.get("behavior",super._enemy_behavior(type))) if not d.is_empty() else super._enemy_behavior(type)

func _spawn_enemy(boss:bool)->void:
	var before:=enemies.size()
	super._spawn_enemy(boss)
	if boss or enemies.size()<=before:
		return
	var e:Dictionary=enemies[enemies.size()-1]
	var d:=ContentDB.monster(String(e.get("type","")))
	if d.is_empty():
		return
	e.hp=float(e.hp)*float(d.get("hp_mult",1.0))
	e.max_hp=e.hp
	e.speed=float(e.speed)*float(d.get("speed_mult",1.0))
	e.damage_mult=float(e.get("damage_mult",1.0))*float(d.get("damage_mult",1.0))
	e.behavior=String(d.get("behavior",e.behavior))
	e["attack_id"]=String(d.get("attack_id","enemy_claw"))
	e["projectile_id"]=String(d.get("projectile_id",""))
	e["sprite_id"]=String(d.get("sprite_id",""))
	enemies[enemies.size()-1]=e

func _update_enemies(delta:float)->void:
	for i in range(enemies.size()-1,-1,-1):
		var e:Dictionary=enemies[i]
		e.flash=maxf(0.0,float(e.flash)-delta)
		e.attack_cd=maxf(0.0,float(e.attack_cd)-delta)
		e.shoot_cd=maxf(0.0,float(e.shoot_cd)-delta)
		e.special_cd=maxf(0.0,float(e.get("special_cd",0.0))-delta)
		e.charge_time=maxf(0.0,float(e.get("charge_time",0.0))-delta)
		if float(e.hp)<=0.0:
			_kill_enemy(e)
			enemies.remove_at(i)
			continue
		var distance:=Vector2(e.pos).distance_to(player_pos)
		var dir:=(player_pos-Vector2(e.pos)).normalized()
		var behavior:=String(e.behavior)
		if behavior.begins_with("boss_"):
			match behavior:
				"boss_beast": _update_beast_boss(e,dir,delta)
				"boss_oracle": _update_oracle_boss(e,dir,distance,delta)
				"boss_colossus": _update_colossus_boss(e,dir,delta)
				_: 
					e.pos+=dir*float(e.speed)*delta
					if float(e.shoot_cd)<=0.0:
						_spawn_boss_volley(Vector2(e.pos)); e.shoot_cd=2.8
		else:
			match behavior:
				"ranged":
					if distance>250.0: e.pos+=dir*float(e.speed)*delta
					elif distance<145.0: e.pos-=dir*float(e.speed)*0.65*delta
					else: e.pos+=dir.rotated(PI/2.0)*float(e.speed)*0.32*delta
					if float(e.shoot_cd)<=0.0 and distance<390.0:
						_spawn_data_enemy_projectile(e,dir)
						e.shoot_cd=_enemy_attack_cooldown(e)
				"tank": e.pos+=dir*float(e.speed)*delta
				"rush": e.pos+=dir*float(e.speed)*1.08*delta
				_: e.pos+=dir*float(e.speed)*delta
			if distance<float(e.radius)+17.0 and float(e.attack_cd)<=0.0:
				var attack:=ContentDB.attack(String(e.get("attack_id","enemy_claw")))
				var hit:=(7.0+int(tile.get("threat",1))*1.7)*float(e.get("damage_mult",1.0))*float(attack.get("damage_mult",1.0))
				_damage_player(hit)
				e.attack_cd=maxf(0.36,float(attack.get("duration",0.75)))
		enemies[i]=e

func _enemy_attack_cooldown(e:Dictionary)->float:
	var attack:=ContentDB.attack(String(e.get("attack_id","enemy_bolt")))
	return maxf(0.55,float(attack.get("duration",1.1))+0.45)

func _spawn_data_enemy_projectile(e:Dictionary,dir:Vector2)->void:
	var projectile_id:=String(e.get("projectile_id",""))
	if projectile_id=="":
		var attack:=ContentDB.attack(String(e.get("attack_id","enemy_bolt")))
		projectile_id=String(attack.get("default_projectile","enemy_hex"))
	var p:=ContentDB.projectile(projectile_id)
	var color:=Color(String(p.get("color","#e89975")))
	var shot_damage:=(7.0+int(tile.get("threat",1))*1.25)*float(e.get("damage_mult",1.0))*float(p.get("damage_mult",1.0))
	_spawn_enemy_shot(Vector2(e.pos),dir,shot_damage,bool(e.get("elite",false)),color,float(p.get("speed",270.0)))

func _auto_attack()->void:
	if attack_timer>0.0 or enemies.is_empty() or projectiles.size()>240:
		return
	if weapon_profile.is_empty() or attack_profile.is_empty():
		_resolve_equipped_weapon()
	var target:=nearest_enemy(player_pos)
	if target.is_empty(): return
	var dir:Vector2=(Vector2(target.pos)-player_pos).normalized()
	attack_visual_dir=dir
	attack_visual_mode=String(attack_profile.get("motion","slash"))
	attack_visual_duration=float(attack_profile.get("duration",0.28))
	attack_visual_time=attack_visual_duration
	var speed_mult:=maxf(0.15,float(weapon_profile.get("attack_speed",1.0)))
	attack_timer=maxf(0.10,attack_interval/speed_mult)
	var momentum:=1.0+min(combo,30)*0.012
	var crit:=rng.randf()<crit_chance
	var hit_damage:=damage*momentum*float(weapon_profile.get("damage_mult",1.0))*float(attack_profile.get("damage_mult",1.0))*(crit_mult if crit else 1.0)
	var knockback:=float(weapon_profile.get("knockback",0.6))*float(attack_profile.get("knockback_mult",1.0))
	match String(attack_profile.get("mode","melee_arc")):
		"melee_arc": _perform_arc_attack(dir,hit_damage,knockback,crit)
		"melee_thrust": _perform_thrust_attack(dir,hit_damage,knockback,crit)
		"melee_slam": _perform_slam_attack(dir,hit_damage,knockback,crit)
		_: _perform_ranged_attack(dir,hit_damage,knockback,crit)

func _perform_arc_attack(dir:Vector2,hit_damage:float,knockback:float,crit:bool)->void:
	var reach:=float(attack_profile.get("reach",72.0))
	var half_arc:=deg_to_rad(float(attack_profile.get("arc_degrees",100.0))*0.5)
	for e in enemies:
		var delta:=Vector2(e.pos)-player_pos
		if delta.length()>reach+float(e.radius): continue
		if absf(dir.angle_to(delta.normalized()))>half_arc: continue
		_hit_with_knockback(e,hit_damage,dir,knockback,crit)

func _perform_thrust_attack(dir:Vector2,hit_damage:float,knockback:float,crit:bool)->void:
	var reach:=float(attack_profile.get("reach",105.0))
	var width:=float(attack_profile.get("width",20.0))
	for e in enemies:
		var delta:=Vector2(e.pos)-player_pos
		var forward:=delta.dot(dir)
		if forward<0.0 or forward>reach+float(e.radius): continue
		var perpendicular:=absf(delta.cross(dir))
		if perpendicular>width+float(e.radius): continue
		_hit_with_knockback(e,hit_damage,dir,knockback,crit)

func _perform_slam_attack(dir:Vector2,hit_damage:float,knockback:float,crit:bool)->void:
	var center:=player_pos+dir*float(attack_profile.get("reach",58.0))*0.55
	var radius:=float(attack_profile.get("radius",52.0))
	_spawn_ring(center,Color("#e8c387"))
	for e in enemies:
		if Vector2(e.pos).distance_to(center)<=radius+float(e.radius):
			_hit_with_knockback(e,hit_damage,(Vector2(e.pos)-center).normalized(),knockback,crit)
	_shake(0.12,4.0)

func _hit_with_knockback(e:Dictionary,hit_damage:float,dir:Vector2,knockback:float,crit:bool)->void:
	_damage_enemy(e,hit_damage,crit)
	_arc_from(e,hit_damage)
	e.pos=Vector2(e.pos)+dir.normalized()*knockback*18.0

func _perform_ranged_attack(dir:Vector2,hit_damage:float,knockback:float,crit:bool)->void:
	var projectile_id:=String(weapon_profile.get("projectile_id",""))
	if projectile_id=="": projectile_id=String(attack_profile.get("default_projectile","arcane_bolt"))
	var pdef:=ContentDB.projectile(projectile_id)
	for i in projectile_count:
		var spread:=(i-(projectile_count-1)/2.0)*0.13
		var shot_dir:=dir.rotated(spread)
		projectiles.append({
			"pos":player_pos+shot_dir*18.0,
			"vel":shot_dir*float(pdef.get("speed",430.0)),
			"damage":hit_damage*float(pdef.get("damage_mult",1.0)),
			"life":float(pdef.get("life",1.8)),
			"crit":crit,
			"radius":float(pdef.get("radius",5.0)),
			"pierce":int(pdef.get("pierce",0)),
			"splash_radius":float(pdef.get("splash_radius",0.0)),
			"slow":float(pdef.get("slow",0.0)),
			"knockback":knockback*float(pdef.get("knockback_mult",1.0)),
			"visual_id":String(pdef.get("visual_id","fx_arrow")),
			"color":String(pdef.get("color","#bfe4ff"))
		})

func _update_projectiles(delta:float)->void:
	for i in range(projectiles.size()-1,-1,-1):
		var p:Dictionary=projectiles[i]
		p.pos=Vector2(p.pos)+Vector2(p.vel)*delta
		p.life=float(p.life)-delta
		var remove:=false
		for e in enemies:
			if Vector2(p.pos).distance_to(Vector2(e.pos))<float(e.radius)+float(p.get("radius",5.0)):
				var dir:=Vector2(p.vel).normalized()
				_hit_with_knockback(e,float(p.damage),dir,float(p.get("knockback",0.4)),bool(p.get("crit",false)))
				var splash:=float(p.get("splash_radius",0.0))
				if splash>0.0:
					for other in enemies:
						if other==e: continue
						if Vector2(other.pos).distance_to(Vector2(e.pos))<=splash:
							_damage_enemy(other,float(p.damage)*0.45,false)
				var pierce:=int(p.get("pierce",0))
				if pierce>0:
					p.pierce=pierce-1
					p.pos=Vector2(p.pos)+dir*12.0
				else:
					remove=true
				break
		if remove or float(p.life)<=0.0 or not bounds.grow(30).has_point(Vector2(p.pos)):
			projectiles.remove_at(i)
		else:
			projectiles[i]=p

func _kill_enemy(e:Dictionary)->void:
	last_killed_type=String(e.get("type",""))
	if not bool(e.get("boss",false)):
		var drops:Array=ContentDB.drops_for_monster(last_killed_type)
		if not drops.is_empty() and rng.randf()<0.13:
			var id:=String(drops[rng.randi_range(0,drops.size()-1)])
			if id not in drop_candidates: drop_candidates.append(id)
	super._kill_enemy(e)

func generate_loot_item(threat:int)->Dictionary:
	var candidates:Array[String]=drop_candidates.duplicate()
	if candidates.is_empty():
		for id in ContentDB.ids("items"):
			var d:=ContentDB.get_entry("items",id)
			if String(tile.get("biome","Greenlands")) in Array(d.get("biomes",[])):
				candidates.append(id)
	if candidates.is_empty():
		return super.generate_loot_item(threat)
	var content_id:=candidates[rng.randi_range(0,candidates.size()-1)]
	var d:=ContentDB.get_entry("items",content_id)
	var slot:=String(d.get("slot","weapon"))
	var tier:=int(d.get("tier",1))
	var rarity:=String(["common","uncommon","rare","epic","legendary"][clampi(tier-1,0,4)])
	var power:=int(d.get("power",5))+threat*2
	var item:=GameState.make_item(String(d.get("name",content_id)),slot,rarity,power,{})
	item["content_id"]=content_id
	for key in ["weapon_class","attack_id","projectile_id","attack_speed","damage_mult","knockback","inventory_sprite","equipped_sheet","attack_sprite"]:
		if d.has(key): item[key]=d[key]
	var pool:=_affix_pool(slot).duplicate()
	var count:=mini(_affix_count(rarity),pool.size())
	var bonuses:Dictionary={}
	var affixes:Array=[]
	for n in count:
		var pick:=rng.randi_range(0,pool.size()-1)
		var key:=String(pool[pick]); pool.remove_at(pick)
		var affix:=_roll_affix(key,threat,rarity)
		affixes.append(affix); bonuses[key]=float(bonuses.get(key,0.0))+float(affix.value)
	item["affixes"]=affixes
	item["bonuses"]=bonuses
	return item

func _draw_ground()->void:
	var biome:=String(tile.get("biome","Greenlands"))
	var defs:Array[Dictionary]=[]
	for id in ContentDB.ids("tiles"):
		var d:=ContentDB.tile_def(id)
		if String(d.get("biome",""))==biome: defs.append(d)
	if defs.is_empty():
		super._draw_ground(); return
	var visible:=_visible_world_rect(180.0)
	var x0:=int(floor(visible.position.x/LOCAL_TILE_PX))*LOCAL_TILE_PX
	var x1:=int(ceil(visible.end.x/LOCAL_TILE_PX))*LOCAL_TILE_PX
	var y0:=int(floor(visible.position.y/LOCAL_TILE_PX))*LOCAL_TILE_PX
	var y1:=int(ceil(visible.end.y/LOCAL_TILE_PX))*LOCAL_TILE_PX
	for x in range(x0,x1+1,LOCAL_TILE_PX):
		for y in range(y0,y1+1,LOCAL_TILE_PX):
			var h:=abs(hash("%s:%d:%d"%[tile.get("seed",1),x/LOCAL_TILE_PX,y/LOCAL_TILE_PX]))
			var d:Dictionary=defs[h%defs.size()]
			var c:=Color(String(d.get("color","#456c3b")))
			draw_rect(Rect2(Vector2(x,y),Vector2(LOCAL_TILE_PX,LOCAL_TILE_PX)),c)
			if h%5==0:
				var accent:=Color(String(d.get("accent","#ffffff")))
				draw_circle(Vector2(x+16+(h%29),y+18+((h/7)%27)),3.0,Color(accent,0.45))
	_draw_outpost_roads()
	for s in local_structures:
		if visible.grow(220).has_point(Vector2(s.pos)): _draw_atlas(String(s.id),Vector2(s.pos),Vector2(s.size),true)
	for prop in local_props:
		if not visible.grow(120).has_point(Vector2(prop.pos)): continue
		if String(prop.kind)=="tree":
			draw_circle(Vector2(prop.pos),22,Color("#315a3d")); draw_circle(Vector2(prop.pos)+Vector2(-8,-6),15,Color("#3c7049"))
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(prop.pos)+Vector2(-18,12),Vector2(prop.pos)+Vector2(-10,-12),Vector2(prop.pos)+Vector2(10,-16),Vector2(prop.pos)+Vector2(20,8)]),Color("#777c80"))
	for tower in field_towers:
		var p:=Vector2(tower.get("pos",Vector2.ZERO))
		if visible.grow(140).has_point(p): _draw_atlas("building_watchtower",p,Vector2(78,72),true)

func _draw_player()->void:
	super._draw_player()
	if attack_visual_time<=0.0: return
	var progress:=1.0-attack_visual_time/maxf(0.01,attack_visual_duration)
	var visual_id:=String(attack_profile.get("visual_id","fx_slash"))
	var angle:=attack_visual_dir.angle()
	match attack_visual_mode:
		"slash": angle+=lerpf(-1.05,1.05,progress)
		"thrust": pass
		"slam": angle+=lerpf(-0.8,0.5,progress)
		"draw","recoil","cast","flick": pass
	draw_set_transform(player_pos,angle,Vector2.ONE)
	if VisualAtlas.has(visual_id):
		draw_texture_rect_region(VisualAtlas.ATLAS,Rect2(Vector2(18,-22),Vector2(74,44)),VisualAtlas.region(visual_id))
	else:
		draw_line(Vector2(18,0),Vector2(82,0),Color("#e7dfc9"),5.0)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

func _draw()->void:
	super._draw()
	for p in projectiles:
		var visual_id:=String(p.get("visual_id",""))
		if visual_id=="" or not VisualAtlas.has(visual_id): continue
		var angle:=Vector2(p.vel).angle()
		draw_set_transform(Vector2(p.pos),angle,Vector2.ONE)
		draw_texture_rect_region(VisualAtlas.ATLAS,Rect2(Vector2(-15,-7),Vector2(30,14)),VisualAtlas.region(visual_id))
		draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
