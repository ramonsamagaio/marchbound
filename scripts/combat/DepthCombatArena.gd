class_name DepthCombatArena
extends QualityCombatArena

var weapon_profile:Dictionary = {}
var attack_profile:Dictionary = {}
var attack_visual_time:float = 0.0
var attack_visual_duration:float = 0.0
var attack_visual_dir:Vector2 = Vector2.RIGHT
var attack_visual_motion:String = ""
var drop_candidates:Array[String] = []

func begin(data:Dictionary) -> void:
	drop_candidates.clear()
	_resolve_equipped_weapon()
	super.begin(data)

func _process(delta:float) -> void:
	attack_visual_time = maxf(0.0, attack_visual_time-delta)
	super._process(delta)

func _resolve_equipped_weapon() -> void:
	var equipped_item:Dictionary = GameState.get_item(String(GameState.equipped.get("weapon","")))
	var content_id:String = String(equipped_item.get("content_id",""))
	if content_id == "":
		var lower:String = String(equipped_item.get("name","")).to_lower()
		if "bow" in lower:
			content_id = "hunter_bow"
		elif "staff" in lower:
			content_id = "apprentice_staff"
		elif "spear" in lower or "pike" in lower:
			content_id = "militia_spear"
		elif "axe" in lower:
			content_id = "woodsman_axe"
		elif "dagger" in lower:
			content_id = "mire_dagger"
		elif "maul" in lower or "hammer" in lower:
			content_id = "quarry_maul"
		else:
			content_id = "training_sword"
	weapon_profile = ContentDB.weapon(content_id)
	if weapon_profile.is_empty():
		weapon_profile = ContentDB.weapon("training_sword")
	attack_profile = ContentDB.attack(String(weapon_profile.get("attack_id","slash_quick")))

func _biome_roster() -> Array:
	var roster:Array[String] = ContentDB.monsters_for_biome(String(tile.get("biome","Greenlands")))
	if roster.is_empty():
		return super._biome_roster()
	return roster

func _enemy_behavior(type:String) -> String:
	var definition:Dictionary = ContentDB.monster(type)
	if definition.is_empty():
		return super._enemy_behavior(type)
	return String(definition.get("behavior","melee"))

func _spawn_enemy(boss:bool) -> void:
	var before:int = enemies.size()
	super._spawn_enemy(boss)
	if boss or enemies.size() <= before:
		return
	var index:int = enemies.size()-1
	var enemy:Dictionary = enemies[index]
	var definition:Dictionary = ContentDB.monster(String(enemy.get("type","")))
	if definition.is_empty():
		return
	var new_hp:float = float(enemy.get("hp",25.0))*float(definition.get("hp_mult",1.0))
	enemy["hp"] = new_hp
	enemy["max_hp"] = new_hp
	enemy["speed"] = float(enemy.get("speed",60.0))*float(definition.get("speed_mult",1.0))
	enemy["damage_mult"] = float(enemy.get("damage_mult",1.0))*float(definition.get("damage_mult",1.0))
	enemy["behavior"] = String(definition.get("behavior",enemy.get("behavior","melee")))
	enemy["attack_id"] = String(definition.get("attack_id","enemy_claw"))
	enemy["projectile_id"] = String(definition.get("projectile_id",""))
	enemy["sprite_id"] = String(definition.get("sprite_id",""))
	enemies[index] = enemy

func _update_enemies(delta:float) -> void:
	for i:int in range(enemies.size()-1,-1,-1):
		var enemy:Dictionary = enemies[i]
		enemy["flash"] = maxf(0.0,float(enemy.get("flash",0.0))-delta)
		enemy["attack_cd"] = maxf(0.0,float(enemy.get("attack_cd",0.0))-delta)
		enemy["shoot_cd"] = maxf(0.0,float(enemy.get("shoot_cd",0.0))-delta)
		enemy["special_cd"] = maxf(0.0,float(enemy.get("special_cd",0.0))-delta)
		enemy["charge_time"] = maxf(0.0,float(enemy.get("charge_time",0.0))-delta)
		if float(enemy.get("hp",0.0)) <= 0.0:
			_kill_enemy(enemy)
			enemies.remove_at(i)
			continue

		var enemy_pos:Vector2 = Vector2(enemy.get("pos",Vector2.ZERO))
		var distance:float = enemy_pos.distance_to(player_pos)
		var direction:Vector2 = (player_pos-enemy_pos).normalized()
		var behavior:String = String(enemy.get("behavior","melee"))
		if behavior.begins_with("boss_"):
			match behavior:
				"boss_beast":
					_update_beast_boss(enemy,direction,delta)
				"boss_oracle":
					_update_oracle_boss(enemy,direction,distance,delta)
				"boss_colossus":
					_update_colossus_boss(enemy,direction,delta)
				_:
					enemy["pos"] = enemy_pos + direction*float(enemy.get("speed",42.0))*delta
					if float(enemy.get("shoot_cd",0.0)) <= 0.0:
						_spawn_boss_volley(Vector2(enemy.get("pos",enemy_pos)))
						enemy["shoot_cd"] = 2.8
		else:
			match behavior:
				"ranged":
					if distance > 250.0:
						enemy["pos"] = enemy_pos + direction*float(enemy.get("speed",60.0))*delta
					elif distance < 145.0:
						enemy["pos"] = enemy_pos - direction*float(enemy.get("speed",60.0))*0.65*delta
					else:
						enemy["pos"] = enemy_pos + direction.rotated(PI/2.0)*float(enemy.get("speed",60.0))*0.32*delta
					if float(enemy.get("shoot_cd",0.0)) <= 0.0 and distance < 390.0:
						_spawn_data_enemy_projectile(enemy,direction)
						enemy["shoot_cd"] = _enemy_attack_cooldown(enemy)
				"tank":
					enemy["pos"] = enemy_pos + direction*float(enemy.get("speed",50.0))*delta
				"rush":
					enemy["pos"] = enemy_pos + direction*float(enemy.get("speed",70.0))*1.08*delta
				_:
					enemy["pos"] = enemy_pos + direction*float(enemy.get("speed",60.0))*delta

			if distance < float(enemy.get("radius",14.0))+17.0 and float(enemy.get("attack_cd",0.0)) <= 0.0:
				var attack:Dictionary = ContentDB.attack(String(enemy.get("attack_id","enemy_claw")))
				var contact_damage:float = (7.0+float(int(tile.get("threat",1)))*1.7)*float(enemy.get("damage_mult",1.0))*float(attack.get("damage_mult",1.0))
				_damage_player(contact_damage)
				enemy["attack_cd"] = maxf(0.36,float(attack.get("duration",0.75)))
		enemies[i] = enemy

func _enemy_attack_cooldown(enemy:Dictionary) -> float:
	var attack:Dictionary = ContentDB.attack(String(enemy.get("attack_id","enemy_bolt")))
	return maxf(0.55,float(attack.get("duration",1.1))+0.45)

func _spawn_data_enemy_projectile(enemy:Dictionary,direction:Vector2) -> void:
	var projectile_id:String = String(enemy.get("projectile_id",""))
	if projectile_id == "":
		var attack:Dictionary = ContentDB.attack(String(enemy.get("attack_id","enemy_bolt")))
		projectile_id = String(attack.get("default_projectile","enemy_hex"))
	var definition:Dictionary = ContentDB.projectile(projectile_id)
	var projectile_color:Color = Color(String(definition.get("color","#e89975")))
	var shot_damage:float = (7.0+float(int(tile.get("threat",1)))*1.25)*float(enemy.get("damage_mult",1.0))*float(definition.get("damage_mult",1.0))
	_spawn_enemy_shot(Vector2(enemy.get("pos",Vector2.ZERO)),direction,shot_damage,bool(enemy.get("elite",false)),projectile_color,float(definition.get("speed",270.0)))

func _auto_attack() -> void:
	if attack_timer > 0.0 or enemies.is_empty() or projectiles.size() > 240:
		return
	if weapon_profile.is_empty() or attack_profile.is_empty():
		_resolve_equipped_weapon()
	var target:Dictionary = nearest_enemy(player_pos)
	if target.is_empty():
		return
	var direction:Vector2 = (Vector2(target.get("pos",player_pos))-player_pos).normalized()
	attack_visual_dir = direction
	attack_visual_motion = String(attack_profile.get("motion","slash"))
	attack_visual_duration = float(attack_profile.get("duration",0.28))
	attack_visual_time = attack_visual_duration
	var speed_mult:float = maxf(0.15,float(weapon_profile.get("attack_speed",1.0)))
	attack_timer = maxf(0.10,attack_interval/speed_mult)
	var momentum:float = 1.0+float(mini(combo,30))*0.012
	var is_crit:bool = rng.randf() < crit_chance
	var crit_factor:float = crit_mult if is_crit else 1.0
	var hit_damage:float = damage*momentum*float(weapon_profile.get("damage_mult",1.0))*float(attack_profile.get("damage_mult",1.0))*crit_factor
	var knockback_amount:float = float(weapon_profile.get("knockback",0.6))*float(attack_profile.get("knockback_mult",1.0))
	match String(attack_profile.get("mode","melee_arc")):
		"melee_arc":
			_perform_arc_attack(direction,hit_damage,knockback_amount,is_crit)
		"melee_thrust":
			_perform_thrust_attack(direction,hit_damage,knockback_amount,is_crit)
		"melee_slam":
			_perform_slam_attack(direction,hit_damage,knockback_amount,is_crit)
		_:
			_perform_ranged_attack(direction,hit_damage,knockback_amount,is_crit)

func _perform_arc_attack(direction:Vector2,hit_damage:float,knockback_amount:float,is_crit:bool) -> void:
	var reach:float = float(attack_profile.get("reach",72.0))
	var half_arc:float = deg_to_rad(float(attack_profile.get("arc_degrees",100.0))*0.5)
	for enemy:Dictionary in enemies:
		var delta_pos:Vector2 = Vector2(enemy.get("pos",Vector2.ZERO))-player_pos
		if delta_pos.length() > reach+float(enemy.get("radius",14.0)):
			continue
		if delta_pos.length_squared() > 0.1 and absf(direction.angle_to(delta_pos.normalized())) > half_arc:
			continue
		_hit_with_knockback(enemy,hit_damage,direction,knockback_amount,is_crit)

func _perform_thrust_attack(direction:Vector2,hit_damage:float,knockback_amount:float,is_crit:bool) -> void:
	var reach:float = float(attack_profile.get("reach",105.0))
	var width:float = float(attack_profile.get("width",20.0))
	for enemy:Dictionary in enemies:
		var delta_pos:Vector2 = Vector2(enemy.get("pos",Vector2.ZERO))-player_pos
		var forward:float = delta_pos.dot(direction)
		if forward < 0.0 or forward > reach+float(enemy.get("radius",14.0)):
			continue
		var perpendicular:float = absf(delta_pos.cross(direction))
		if perpendicular > width+float(enemy.get("radius",14.0)):
			continue
		_hit_with_knockback(enemy,hit_damage,direction,knockback_amount,is_crit)

func _perform_slam_attack(direction:Vector2,hit_damage:float,knockback_amount:float,is_crit:bool) -> void:
	var center:Vector2 = player_pos+direction*float(attack_profile.get("reach",58.0))*0.55
	var radius:float = float(attack_profile.get("radius",52.0))
	_spawn_ring(center,Color("#e8c387"))
	for enemy:Dictionary in enemies:
		var enemy_pos:Vector2 = Vector2(enemy.get("pos",Vector2.ZERO))
		if enemy_pos.distance_to(center) <= radius+float(enemy.get("radius",14.0)):
			var push_dir:Vector2 = (enemy_pos-center).normalized()
			if push_dir.length_squared() < 0.1:
				push_dir = direction
			_hit_with_knockback(enemy,hit_damage,push_dir,knockback_amount,is_crit)
	_shake(0.12,4.0)

func _hit_with_knockback(enemy:Dictionary,hit_damage:float,direction:Vector2,knockback_amount:float,is_crit:bool) -> void:
	_damage_enemy(enemy,hit_damage,is_crit)
	_arc_from(enemy,hit_damage)
	enemy["pos"] = Vector2(enemy.get("pos",Vector2.ZERO))+direction.normalized()*knockback_amount*18.0

func _perform_ranged_attack(direction:Vector2,hit_damage:float,knockback_amount:float,is_crit:bool) -> void:
	var projectile_id:String = String(weapon_profile.get("projectile_id",""))
	if projectile_id == "":
		projectile_id = String(attack_profile.get("default_projectile","arcane_bolt"))
	var definition:Dictionary = ContentDB.projectile(projectile_id)
	for i:int in range(projectile_count):
		var spread:float = (float(i)-float(projectile_count-1)/2.0)*0.13
		var shot_dir:Vector2 = direction.rotated(spread)
		projectiles.append({
			"pos":player_pos+shot_dir*18.0,
			"vel":shot_dir*float(definition.get("speed",430.0)),
			"damage":hit_damage*float(definition.get("damage_mult",1.0)),
			"life":float(definition.get("life",1.8)),
			"crit":is_crit,
			"radius":float(definition.get("radius",5.0)),
			"pierce":int(definition.get("pierce",0)),
			"splash_radius":float(definition.get("splash_radius",0.0)),
			"slow":float(definition.get("slow",0.0)),
			"knockback":knockback_amount*float(definition.get("knockback_mult",1.0)),
			"visual_id":String(definition.get("visual_id","fx_arrow")),
			"color":String(definition.get("color","#bfe4ff"))
		})

func _update_projectiles(delta:float) -> void:
	for i:int in range(projectiles.size()-1,-1,-1):
		var projectile:Dictionary = projectiles[i]
		projectile["pos"] = Vector2(projectile.get("pos",Vector2.ZERO))+Vector2(projectile.get("vel",Vector2.ZERO))*delta
		projectile["life"] = float(projectile.get("life",0.0))-delta
		var remove_projectile:bool = false
		for enemy:Dictionary in enemies:
			if Vector2(projectile.get("pos",Vector2.ZERO)).distance_to(Vector2(enemy.get("pos",Vector2.ZERO))) < float(enemy.get("radius",14.0))+float(projectile.get("radius",5.0)):
				var direction:Vector2 = Vector2(projectile.get("vel",Vector2.RIGHT)).normalized()
				_hit_with_knockback(enemy,float(projectile.get("damage",0.0)),direction,float(projectile.get("knockback",0.4)),bool(projectile.get("crit",false)))
				var splash:float = float(projectile.get("splash_radius",0.0))
				if splash > 0.0:
					for other:Dictionary in enemies:
						if other == enemy:
							continue
						if Vector2(other.get("pos",Vector2.ZERO)).distance_to(Vector2(enemy.get("pos",Vector2.ZERO))) <= splash:
							_damage_enemy(other,float(projectile.get("damage",0.0))*0.45,false)
				var pierce:int = int(projectile.get("pierce",0))
				if pierce > 0:
					projectile["pierce"] = pierce-1
					projectile["pos"] = Vector2(projectile.get("pos",Vector2.ZERO))+direction*12.0
				else:
					remove_projectile = true
				break
		if remove_projectile or float(projectile.get("life",0.0)) <= 0.0 or not bounds.grow(30.0).has_point(Vector2(projectile.get("pos",Vector2.ZERO))):
			projectiles.remove_at(i)
		else:
			projectiles[i] = projectile

func _kill_enemy(enemy:Dictionary) -> void:
	var enemy_type:String = String(enemy.get("type",""))
	if not bool(enemy.get("boss",false)):
		var drops:Array = ContentDB.drops_for_monster(enemy_type)
		if not drops.is_empty() and rng.randf() < 0.13:
			var drop_id:String = String(drops[rng.randi_range(0,drops.size()-1)])
			if drop_id not in drop_candidates:
				drop_candidates.append(drop_id)
	super._kill_enemy(enemy)

func generate_loot_item(threat:int) -> Dictionary:
	var candidates:Array[String] = drop_candidates.duplicate()
	if candidates.is_empty():
		var biome:String = String(tile.get("biome","Greenlands"))
		for id:String in ContentDB.ids("items"):
			var definition:Dictionary = ContentDB.get_entry("items",id)
			if biome in Array(definition.get("biomes",[])):
				candidates.append(id)
	if candidates.is_empty():
		return super.generate_loot_item(threat)
	var content_id:String = candidates[rng.randi_range(0,candidates.size()-1)]
	var definition:Dictionary = ContentDB.get_entry("items",content_id)
	var slot:String = String(definition.get("slot","weapon"))
	var tier:int = int(definition.get("tier",1))
	var rarity_names:Array[String] = ["common","uncommon","rare","epic","legendary"]
	var rarity:String = rarity_names[clampi(tier-1,0,4)]
	var power:int = int(definition.get("power",5))+threat*2
	var item:Dictionary = GameState.make_item(String(definition.get("name",content_id)),slot,rarity,power,{})
	item["content_id"] = content_id
	for key:String in ["weapon_class","attack_id","projectile_id","attack_speed","damage_mult","knockback","inventory_sprite","equipped_sheet","attack_sprite"]:
		if definition.has(key):
			item[key] = definition[key]
	var pool:Array = _affix_pool(slot).duplicate()
	var affix_count:int = mini(_affix_count(rarity),pool.size())
	var bonuses:Dictionary = {}
	var affixes:Array = []
	for _n:int in range(affix_count):
		var pick:int = rng.randi_range(0,pool.size()-1)
		var affix_key:String = String(pool[pick])
		pool.remove_at(pick)
		var affix:Dictionary = _roll_affix(affix_key,threat,rarity)
		affixes.append(affix)
		bonuses[affix_key] = float(bonuses.get(affix_key,0.0))+float(affix.get("value",0.0))
	item["affixes"] = affixes
	item["bonuses"] = bonuses
	return item

func _draw_ground() -> void:
	super._draw_ground()
	var biome:String = String(tile.get("biome","Greenlands"))
	var variants:Array[Dictionary] = []
	for id:String in ContentDB.ids("tiles"):
		var definition:Dictionary = ContentDB.tile_def(id)
		if String(definition.get("biome","")) == biome:
			variants.append(definition)
	if variants.is_empty():
		return
	var visible:Rect2 = _visible_world_rect(80.0)
	var x0:int = int(floor(visible.position.x/float(LOCAL_TILE_PX)))*LOCAL_TILE_PX
	var x1:int = int(ceil(visible.end.x/float(LOCAL_TILE_PX)))*LOCAL_TILE_PX
	var y0:int = int(floor(visible.position.y/float(LOCAL_TILE_PX)))*LOCAL_TILE_PX
	var y1:int = int(ceil(visible.end.y/float(LOCAL_TILE_PX)))*LOCAL_TILE_PX
	for x:int in range(x0,x1+1,LOCAL_TILE_PX):
		for y:int in range(y0,y1+1,LOCAL_TILE_PX):
			var cell_x:int = x/LOCAL_TILE_PX
			var cell_y:int = y/LOCAL_TILE_PX
			var hashed:int = absi(hash("%s:%d:%d"%[String(tile.get("seed",1)),cell_x,cell_y]))
			var definition:Dictionary = variants[hashed%variants.size()]
			var accent:Color = Color(String(definition.get("accent","#ffffff")))
			if hashed%4 == 0:
				var px:float = float(x+12+(hashed%37))
				var py:float = float(y+13+((hashed/7)%35))
				draw_circle(Vector2(px,py),2.5,Color(accent,0.34))

func _draw_enemy(enemy:Dictionary) -> void:
	var sprite_id:String = String(enemy.get("sprite_id",""))
	if sprite_id == "" or not VisualAtlas.has(sprite_id):
		super._draw_enemy(enemy)
		return
	var size:Vector2 = Vector2(54,60)
	if bool(enemy.get("elite",false)):
		size *= 1.16
	_draw_atlas(sprite_id,Vector2(enemy.get("pos",Vector2.ZERO)),size,true)
	if bool(enemy.get("elite",false)):
		draw_arc(Vector2(enemy.get("pos",Vector2.ZERO)),float(enemy.get("radius",14.0))+12.0,0.0,TAU,24,Color("#d9a3ff"),3.0)
	var hp_ratio:float = clampf(float(enemy.get("hp",1.0))/maxf(1.0,float(enemy.get("max_hp",1.0))),0.0,1.0)
	if bool(enemy.get("elite",false)):
		var pos:Vector2 = Vector2(enemy.get("pos",Vector2.ZERO))
		draw_rect(Rect2(pos+Vector2(-32,-48),Vector2(64,5)),Color("#241d28"))
		draw_rect(Rect2(pos+Vector2(-32,-48),Vector2(64*hp_ratio,5)),Color("#d85c6c"))

func _draw_player() -> void:
	super._draw_player()
	if attack_visual_time <= 0.0:
		return
	var progress:float = 1.0-attack_visual_time/maxf(0.01,attack_visual_duration)
	var weapon_class:String = String(weapon_profile.get("weapon_class","sword"))
	_draw_weapon_motion(weapon_class,progress)

func _draw_weapon_motion(weapon_class:String,progress:float) -> void:
	var base_angle:float = attack_visual_dir.angle()
	var motion:String = attack_visual_motion
	var angle:float = base_angle
	var reach:float = 56.0
	if motion == "slash":
		angle += lerpf(-1.05,1.05,progress)
	elif motion == "slam":
		angle += lerpf(-1.15,0.35,progress)
	elif motion == "thrust":
		reach = 45.0+sin(progress*PI)*36.0
	elif motion in ["draw","recoil","cast","flick"]:
		reach = 44.0
	draw_set_transform(player_pos,angle,Vector2.ONE)
	match weapon_class:
		"spear":
			draw_line(Vector2(14,0),Vector2(reach+40.0,0),Color("#9a7648"),5.0)
			draw_colored_polygon(PackedVector2Array([Vector2(reach+40,-7),Vector2(reach+55,0),Vector2(reach+40,7)]),Color("#d8e0ea"))
		"staff","wand":
			draw_line(Vector2(10,0),Vector2(reach+38.0,0),Color("#725042"),6.0)
			draw_circle(Vector2(reach+42.0,0),8.0,Color("#78c7ff"))
		"bow":
			draw_arc(Vector2(40,0),24.0,-1.25,1.25,16,Color("#9a744a"),5.0)
			draw_line(Vector2(47,-23),Vector2(47,23),Color("#e6d8bd"),2.0)
		"crossbow":
			draw_line(Vector2(14,0),Vector2(68,0),Color("#8a6949"),6.0)
			draw_arc(Vector2(50,0),20.0,-1.1,1.1,12,Color("#a07850"),4.0)
		"hammer":
			draw_line(Vector2(12,0),Vector2(reach+24,0),Color("#79533d"),7.0)
			draw_rect(Rect2(Vector2(reach+18,-14),Vector2(28,28)),Color("#89919b"))
		"axe":
			draw_line(Vector2(12,0),Vector2(reach+22,0),Color("#79533d"),6.0)
			draw_colored_polygon(PackedVector2Array([Vector2(reach+14,-20),Vector2(reach+42,-12),Vector2(reach+42,12),Vector2(reach+14,20)]),Color("#aeb8c4"))
		"dagger":
			draw_line(Vector2(12,0),Vector2(reach+12,0),Color("#dce3ed"),6.0)
		_:
			draw_line(Vector2(12,0),Vector2(reach+28,0),Color("#dce3ed"),7.0)
			draw_line(Vector2(reach+8,-9),Vector2(reach+8,9),Color("#b08a55"),4.0)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

func _draw() -> void:
	super._draw()
	for projectile:Dictionary in projectiles:
		var visual_id:String = String(projectile.get("visual_id",""))
		if visual_id == "" or not VisualAtlas.has(visual_id):
			continue
		var angle:float = Vector2(projectile.get("vel",Vector2.RIGHT)).angle()
		draw_set_transform(Vector2(projectile.get("pos",Vector2.ZERO)),angle,Vector2.ONE)
		draw_texture_rect_region(VisualAtlas.ATLAS,Rect2(Vector2(-15,-7),Vector2(30,14)),VisualAtlas.region(visual_id))
		draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
