class_name StatusCombatArena
extends DepthCombatArena

func _spawn_enemy(boss:bool) -> void:
	super._spawn_enemy(boss)
	if enemies.is_empty():
		return
	var index:int = enemies.size()-1
	var enemy:Dictionary = enemies[index]
	if not enemy.has("base_speed"):
		enemy["base_speed"] = float(enemy.get("speed",60.0))
	if not enemy.has("statuses"):
		enemy["statuses"] = {}
	enemies[index] = enemy

func _update_enemies(delta:float) -> void:
	for enemy:Dictionary in enemies:
		_prepare_enemy_statuses(enemy,delta)
	super._update_enemies(delta)

func _prepare_enemy_statuses(enemy:Dictionary,delta:float) -> void:
	if not enemy.has("base_speed"):
		enemy["base_speed"] = float(enemy.get("speed",60.0))
	var status_map:Dictionary = Dictionary(enemy.get("statuses",{}))
	var speed_mult:float = 1.0
	var stunned:bool = false
	var remove_ids:Array[String] = []
	for raw_id:Variant in status_map.keys():
		var status_id:String = String(raw_id)
		var active:Dictionary = Dictionary(status_map[raw_id])
		var definition:Dictionary = ContentDB.status(status_id)
		active["time"] = float(active.get("time",0.0))-delta
		var kind:String = String(definition.get("kind",""))
		if definition.has("speed_mult"):
			speed_mult *= float(definition.get("speed_mult",1.0))
		if kind == "stun":
			stunned = true
		if kind == "dot":
			active["tick"] = float(active.get("tick",0.0))-delta
			if float(active.get("tick",0.0)) <= 0.0:
				var stacks:int = maxi(1,int(active.get("stacks",1)))
				var dot_damage:float = float(active.get("power",4.0))*float(definition.get("damage_per_tick_mult",0.1))*float(stacks)
				enemy["hp"] = float(enemy.get("hp",0.0))-dot_damage
				active["tick"] = float(definition.get("tick_rate",0.75))
				particles.append({"pos":Vector2(enemy.get("pos",Vector2.ZERO)),"life":0.18,"max":0.18,"color":Color(String(definition.get("color","#ffffff")))})
		if float(active.get("time",0.0)) <= 0.0:
			remove_ids.append(status_id)
		else:
			status_map[status_id] = active
	for status_id:String in remove_ids:
		status_map.erase(status_id)
	enemy["statuses"] = status_map
	enemy["speed"] = 0.0 if stunned else float(enemy.get("base_speed",60.0))*speed_mult

func _damage_enemy(enemy:Dictionary,amount:float,is_crit:bool) -> void:
	var multiplier:float = 1.0
	var status_map:Dictionary = Dictionary(enemy.get("statuses",{}))
	for raw_id:Variant in status_map.keys():
		var definition:Dictionary = ContentDB.status(String(raw_id))
		if definition.has("damage_taken_mult"):
			multiplier *= float(definition.get("damage_taken_mult",1.0))
	super._damage_enemy(enemy,amount*multiplier,is_crit)

func _apply_status(enemy:Dictionary,status_id:String,source_power:float) -> void:
	if status_id == "":
		return
	var definition:Dictionary = ContentDB.status(status_id)
	if definition.is_empty():
		return
	var status_map:Dictionary = Dictionary(enemy.get("statuses",{}))
	var active:Dictionary = Dictionary(status_map.get(status_id,{}))
	var max_stacks:int = maxi(1,int(definition.get("max_stacks",1)))
	active["stacks"] = mini(max_stacks,int(active.get("stacks",0))+1)
	active["time"] = float(definition.get("duration",2.0))
	active["tick"] = minf(float(active.get("tick",999.0)),float(definition.get("tick_rate",0.75)))
	active["power"] = maxf(float(active.get("power",0.0)),source_power)
	status_map[status_id] = active
	enemy["statuses"] = status_map
	_float_text(Vector2(enemy.get("pos",Vector2.ZERO))+Vector2(0,-36),String(definition.get("name",status_id)).to_upper(),Color(String(definition.get("color","#ffffff"))),0.7)

func _update_projectiles(delta:float) -> void:
	for i:int in range(projectiles.size()-1,-1,-1):
		var projectile:Dictionary = projectiles[i]
		projectile["pos"] = Vector2(projectile.get("pos",Vector2.ZERO))+Vector2(projectile.get("vel",Vector2.ZERO))*delta
		projectile["life"] = float(projectile.get("life",0.0))-delta
		var remove_projectile:bool = false
		for enemy:Dictionary in enemies:
			if Vector2(projectile.get("pos",Vector2.ZERO)).distance_to(Vector2(enemy.get("pos",Vector2.ZERO))) >= float(enemy.get("radius",14.0))+float(projectile.get("radius",5.0)):
				continue
			var direction:Vector2 = Vector2(projectile.get("vel",Vector2.RIGHT)).normalized()
			var projectile_damage:float = float(projectile.get("damage",0.0))
			_hit_with_knockback(enemy,projectile_damage,direction,float(projectile.get("knockback",0.4)),bool(projectile.get("crit",false)))
			var status_id:String = String(projectile.get("status_id",""))
			if status_id != "" and rng.randf() <= float(projectile.get("status_chance",1.0)):
				_apply_status(enemy,status_id,projectile_damage)
			var splash:float = float(projectile.get("splash_radius",0.0))
			if splash > 0.0:
				for other:Dictionary in enemies:
					if other == enemy:
						continue
					if Vector2(other.get("pos",Vector2.ZERO)).distance_to(Vector2(enemy.get("pos",Vector2.ZERO))) <= splash:
						_damage_enemy(other,projectile_damage*0.45,false)
						if status_id != "" and rng.randf() <= float(projectile.get("status_chance",1.0))*0.55:
							_apply_status(other,status_id,projectile_damage*0.65)
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
			"knockback":knockback_amount*float(definition.get("knockback_mult",1.0)),
			"status_id":String(definition.get("status_id","")),
			"status_chance":float(definition.get("status_chance",0.0)),
			"visual_id":String(definition.get("visual_id","fx_arrow")),
			"color":String(definition.get("color","#bfe4ff"))
		})

func _draw_enemy(enemy:Dictionary) -> void:
	super._draw_enemy(enemy)
	var status_map:Dictionary = Dictionary(enemy.get("statuses",{}))
	if status_map.is_empty():
		return
	var start:Vector2 = Vector2(enemy.get("pos",Vector2.ZERO))+Vector2(-float(status_map.size()-1)*6.0,-54)
	var index:int = 0
	for raw_id:Variant in status_map.keys():
		var definition:Dictionary = ContentDB.status(String(raw_id))
		draw_circle(start+Vector2(index*12,0),4.0,Color(String(definition.get("color","#ffffff"))))
		index += 1
